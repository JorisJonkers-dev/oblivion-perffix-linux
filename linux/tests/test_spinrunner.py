"""A live session against the fake game of test_runner: ini and cvar variants in ABBA order, the heading timeline,
slots sliced from the frame log, and everything put back (also after an error)."""
import hashlib
import json
import re
import sys
import threading
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from oblvbench import spin  # noqa: E402
from oblvbench.spinrunner import SpinOptions, SpinRunner  # noqa: E402
from test_fixini import SAMPLE  # noqa: E402
import test_runner  # noqa: E402
from test_runner import FakeGame  # noqa: E402

INI = SAMPLE.replace("BoneUploadStores=1", "BoneUploadStores=1\r\nGpuSceneParallelUpload=1")


class SpinGame(FakeGame):
    fail_mode = None          # "ini" / "cvar": the 5th look after that variant was applied is answered with an error

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.looks = []       # (wall time, GpuSceneParallelUpload as in the ini file at that moment, heading, pitch)
        self.cvars = {"r.Foo": "1.0"}
        self.cvar_calls = []
        self.lock = threading.Lock()

    def handlers(self):
        h = super().handlers()

        def look(m, rest):
            ini = self.paths.fix_ini.read_text()
            v = re.search(r"GpuSceneParallelUpload=(\d)", ini).group(1)
            with self.lock:
                self.looks.append((time.time(), v, *[float(x) for x in rest.split()]))
            if self.fail_mode == "ini":
                self.hits = getattr(self, "hits", 0) + (v == "0")
            elif self.fail_mode == "cvar":
                self.hits = getattr(self, "hits", 0) + (self.cvars["r.Foo"] == "2")
            if self.fail_mode and getattr(self, "hits", 0) == 5:
                self.hits += 1
                return False, "boom"
            return "ok"

        def cvar(m, rest):
            k, v = rest.split(None, 1)
            self.cvars[k] = v
            self.cvar_calls.append((time.time(), k, v))
            return f"{k}={v}"

        h.update(look=look, cvar=cvar, get=lambda m, r: f"{r}={self.cvars.get(r, 'nil')}")
        return h


class SpinTest(test_runner.RunnerTest):
    test_stock_run = None
    test_off_run_env = None
    fail_mode = None

    def setUp(self):
        super().setUp()
        self.paths.fix_ini.write_text(INI)
        self.before[self.paths.fix_ini] = self.paths.fix_ini.read_bytes()

    def make_game(self, run_dir):
        g = SpinGame(self.paths, run_dir / "mangohud")
        g.fail_mode = self.fail_mode
        self.game = g
        return g

    def make_run(self, run_dir, out, fix, **extra):
        opts = SpinOptions(scenario="mini", scenario_dir=self.tmp / "scen", scenes=["spot-noon"], label="spin-t",
                           warmup=0, steam="true", run_dir=run_dir, profile="small", launch_timeout=20,
                           variants=spin.parse_variants(self.variants), rounds=1, laps=1, settle=0.2,
                           deg_per_sec=360, cam_lag=0.0, look_interval=0.05, **extra)
        return SpinRunner(self.paths, opts, say=out.append).run()

    variants = ["off:ini:GpuSceneParallelUpload=0", "lod:cvar:r.Foo=2"]

    def assert_all_put_back(self):
        after = {p: p.read_bytes() for p in self.tmp.rglob("*") if p.is_file()}
        for p, data in self.before.items():
            self.assertEqual(after.get(p), data, p)
        self.assertFalse(self.paths.env_file.exists())
        self.assertFalse((self.paths.win64 / "ue4ss").exists())

    def test_dll_and_dll_ini_installed_and_restored(self):
        # the installed ini lacks the key the ini variant flips; the --dll-ini one has it
        self.paths.fix_ini.write_text(SAMPLE)
        self.before[self.paths.fix_ini] = self.paths.fix_ini.read_bytes()
        dll, ini = self.tmp / "b.dll", self.tmp / "b.ini"
        dll.write_bytes(b"MZ spin build")
        ini.write_text(INI)
        result, fake, out = self.run_fake("on", dll=dll, dll_ini=ini)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(fake.dll_at_launch, b"MZ spin build")
        self.assertEqual(fake.ini_at_launch, INI)
        self.assertEqual(result["dll"]["iniSha256"], hashlib.sha256(INI.encode()).hexdigest())
        self.assert_all_put_back()

    def test_abba_session(self):
        result, fake, out = self.run_fake("on")
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(result["spin"]["order"], "base off lod lod off base".split())
        self.assertEqual([s["variant"] for s in result["slots"]], result["spin"]["order"])
        for s in result["slots"]:
            self.assertAlmostEqual(s["seconds"], 1.0, delta=0.01)           # one full lap at 360 deg/s
            self.assertAlmostEqual(s["frames"], 100, delta=6)
            self.assertAlmostEqual(s["fps"], 100, delta=2)
            self.assertEqual(len(s["lapsFps"]), 1)
            self.assertEqual(len(s["sectorFps"]), 8)
            for f in s["sectorFps"]:
                self.assertAlmostEqual(f, 100, delta=15)
        self.assertEqual([v["name"] for v in result["variants"]], ["base", "off", "lod"])
        self.assertEqual([v["slots"] for v in result["variants"]], [2, 2, 2])
        # each slot's laps began at the start heading
        for s in result["slots"]:
            near = min(fake.looks, key=lambda lk: abs(lk[0] - s["t0"]))
            self.assertAlmostEqual(abs((near[2] - 90 + 180) % 360 - 180), 0.0, delta=360 * 0.08)   # the place's heading
        # the ini had the variant's value while its slot was measured, and the base value otherwise
        for s in result["slots"]:
            seen = {v for t, v, *_ in fake.looks if s["t0"] <= t <= s["t1"]}
            self.assertEqual(seen, {"0"} if s["variant"] == "off" else {"1"}, s["variant"])
        # cvars: set for the lod slots, read back, and put back at the end
        self.assertEqual([v for _, k, v in fake.cvar_calls if k == "r.Foo"], ["2", "1.0"])
        self.assertEqual(fake.cvars["r.Foo"], "1.0")
        self.assertTrue(any(s["variant"] == "lod" and s["applied"].get("cvar") for s in result["slots"]))
        # headings sent: 0..360 wrapping, pitch 0
        hs = [h for _, _, h, p in fake.looks]
        self.assertTrue(all(0 <= h < 360 for h in hs) and max(hs) > 330 and min(hs) < 30)
        # outputs
        d = self.tmp / "results/run1"
        md = (d / "report.md").read_text()
        self.assertIn("| lod | cvar |", md)
        self.assertIn("Avg fps by heading sector", md)
        self.assertEqual(json.loads((d / "result.json").read_text())["outcome"], "ok")
        self.assertGreater(len(json.loads((d / "heading-timeline.json").read_text())), 50)
        self.assert_all_put_back()

    def test_error_in_a_cvar_slot_puts_cvar_back(self):
        SpinTest.fail_mode = "cvar"
        try:
            result, fake, out = self.run_fake("on")
        finally:
            SpinTest.fail_mode = None
        self.assertIn("boom", result["error"])
        self.assertEqual(fake.cvars["r.Foo"], "1.0")
        self.assertEqual([c for c in fake.cvar_calls if c[1] == "r.Foo"][-1][2], "1.0")
        self.assert_all_put_back()

    def test_error_in_an_ini_slot_restores_ini(self):
        SpinTest.fail_mode = "ini"
        try:
            result, fake, out = self.run_fake("on")
        finally:
            SpinTest.fail_mode = None
        self.assertIn("boom", result["error"])
        self.assertIn("1", {v for _, v, *_ in fake.looks})
        self.assertIn("0", {v for _, v, *_ in fake.looks})      # the off slot had started
        self.assert_all_put_back()

    def test_startup_key_refused_before_anything_is_touched(self):
        SpinTest.variants = ["bad:ini:BoneUploadStores=0"]
        try:
            with self.assertRaises(spin.SpinError) as cm:
                self.run_fake("on")
        finally:
            SpinTest.variants = ["off:ini:GpuSceneParallelUpload=0", "lod:cvar:r.Foo=2"]
        self.assertIn("Start-up only", str(cm.exception))
        self.assertFalse(self.game.running)
        self.assert_all_put_back()


if __name__ == "__main__":
    unittest.main()
