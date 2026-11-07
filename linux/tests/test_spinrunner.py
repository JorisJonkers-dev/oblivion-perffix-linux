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
        self.cams = []        # (wall time, argument) of every `cam` verb
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

        def cam(m, rest):
            self.cams.append((time.time(), rest))
            return rest

        h.update(look=look, cvar=cvar, cam=cam, get=lambda m, r: f"{r}={self.cvars.get(r, 'nil')}")
        return h


class SpinTest(test_runner.RunnerTest):
    test_stock_run = None
    test_off_run_env = None
    test_dll_installed_and_restored = None            # the installed ini differs here (INI): see the spin versions below
    test_dll_and_ini_installed_and_restored = None
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
        opts = SpinOptions(scenario="mini", scenario_dir=self.tmp / "scen", scenes=["spot-noon"], fix=fix, label="spin-t",
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

    def test_dll_installed_and_restored_spin(self):
        dll = self.tmp / "built.dll"
        dll.write_bytes(b"MZ new build")
        result, fake, out = self.run_fake("on", dll=dll)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(fake.dll_at_launch, b"MZ new build")
        self.assertEqual(fake.ini_at_launch, INI)                    # the installed ini stays
        self.assertEqual(result["dll"]["sha256"], hashlib.sha256(dll.read_bytes()).hexdigest())
        self.assert_all_put_back()

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

    def test_shot_laps(self):
        game = self
        W, H = 160, 90

        class Cap:
            def grab(self):
                g = game.game
                with g.lock:
                    h = g.looks[-1][2]
                lod = g.cvars["r.Foo"] == "2"
                pix = bytearray()
                for y in range(H):
                    for x in range(W):
                        v = (x * 2 + y + int(h)) % 180 + 40
                        if lod:
                            v = min(255, v + ((x * 7 + y * 13) % 31))      # a visible change in the lod slots
                        pix.append(v)
                return spin_frame(W, H, bytes(pix))

        from oblvbench.imgcmp import Pic as spin_frame
        result, fake, out = self.run_fake("on", shots=True, shot_headings=[0, 90, 200], shot_settle=0.3,
                                          capturer_factory=Cap)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        d = self.tmp / "results/run1"
        for i, s in enumerate(result["slots"], 1):
            self.assertEqual(sorted(s["shots"]), ["000", "090", "200"])
            self.assertEqual(s["shots"]["090"], f"shots/{s['variant']}/s{i}/090.png")
            self.assertTrue((d / s["shots"]["090"]).exists())
        # the shot lap comes after the measured laps, holds each heading for the settle time and sends exactly it
        log = result["spin"]["shots"]["log"]
        self.assertEqual(len(log), 3 * len(result["slots"]))
        s1 = result["slots"][0]
        first = [e for e in log if e["slot"] == 1]
        self.assertEqual([e["heading"] for e in first], [0, 90, 200])
        self.assertGreaterEqual(first[0]["t"], s1["t1"] + 0.3 - 0.05)
        for e in first:
            near = [lk for lk in fake.looks if e["t"] - 0.3 <= lk[0] <= e["t"]]
            self.assertGreaterEqual(len(near), 3)
            self.assertTrue(all(abs(lk[2] - e["heading"]) < 0.01 for lk in near), (e, near[:2]))
        self.assertGreaterEqual(first[1]["t"] - first[0]["t"], 0.3)
        # fps windows were not disturbed: the lap stayed whole
        for s in result["slots"]:
            self.assertAlmostEqual(s["seconds"], 1.0, delta=0.01)
        # comparison: lod differs from base beyond the floor, off (ini only) does not
        im = result["images"]
        self.assertAlmostEqual(im["variants"]["base"]["noiseFloor"], 1.0, places=3)
        self.assertLess(im["variants"]["lod"]["ssim"], 0.97)
        self.assertGreater(im["variants"]["off"]["ssim"], 0.999)
        rows = {v["name"]: v for v in result["variants"]}
        self.assertIn(rows["lod"]["verdict"]["code"], ("REJECT", "TRADE-OFF"))
        self.assertIn(rows["off"]["verdict"]["code"], ("NEUTRAL", "ACCEPT"))             # no image cost
        md = (d / "report.md").read_text()
        self.assertIn("SSIM vs base (noise floor)", md)
        self.assertIn("## Gain vs image cost", md)
        gal = (d / "images.md").read_text()
        self.assertIn("![lod 090](shots/sbs/lod/090.png)", gal)
        self.assertTrue((d / "shots/sbs/lod/090.png").exists())
        self.assert_all_put_back()

    def test_turn_settle(self):
        game = self
        W, H = 160, 90
        grabs = []

        class Cap:
            """A picture that is facing away (flat) until the snap, then a detail appears 0.7 s after it."""
            def grab(self):
                g = game.game
                now = time.time()
                time.sleep(0.02)
                snaps = [c[0] for c in g.cams if c[1] == "snap"]
                t = now - snaps[-1] if snaps else -1
                grabs.append(now)
                pix = bytearray(60 for _ in range(W * H))
                if t >= 0.7:
                    for y in range(40, 60):
                        for x in range(60, 100):
                            pix[y * W + x] = 200
                return Pic(W, H, bytes(pix))

        from oblvbench.imgcmp import Pic
        result, fake, out = self.run_fake("on", turn_settle=True, turn_headings=[0, 90], turn_hold=0.3, turn_secs=1.6,
                                          turn_interval=0.1, turn_capturer_factory=Cap)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        d = self.tmp / "results/run1"
        n = len(result["slots"])
        for s in result["slots"]:
            self.assertEqual(len(s["turns"]), 2)
            for t in s["turns"]:
                self.assertAlmostEqual(t["settleS"], 0.7, delta=0.2)
                self.assertGreater(t["auc"], 0)
                self.assertTrue((d / t["strip"]).exists())
            self.assertAlmostEqual(s["seconds"], 1.0, delta=0.01)          # the fps laps are untouched
        # schedule: hold looking away (heading + 180), then look H + cam snap, then captures every ~0.1 s
        snaps = [c[0] for c in fake.cams if c[1] == "snap"]
        self.assertEqual(len(snaps), 2 * n)
        s0 = result["slots"][0]
        self.assertGreaterEqual(snaps[0], s0["t1"] + 0.3 - 0.05)
        before = [lk for lk in fake.looks if snaps[0] - 0.25 <= lk[0] < snaps[0] - 0.08]
        self.assertTrue(before and all(abs(lk[2] - 180) < 0.01 for lk in before), before)
        at = [lk for lk in fake.looks if abs(lk[0] - snaps[0]) < 0.05 and abs(lk[2] - 0) < 0.01]
        self.assertTrue(at)
        mine = [g for g in grabs if snaps[0] <= g < snaps[0] + 1.7]
        self.assertGreaterEqual(len(mine), 14)
        gaps = [b - a for a, b in zip(mine, mine[1:])]
        self.assertAlmostEqual(sorted(gaps)[len(gaps) // 2], 0.1, delta=0.03)
        ts = result["turnSettle"]
        self.assertEqual({v["name"] for v in ts["variants"]}, {"base", "off", "lod"})
        self.assertAlmostEqual(ts["variants"][0]["settleS"], 0.7, delta=0.2)
        cfg = result["spin"]["turnSettle"]
        self.assertEqual(cfg["headings"], [0.0, 90.0])
        md = (d / "report.md").read_text()
        self.assertIn("## Turn settle", md)
        self.assertIn("### base slot 1 @ 0", (d / "images.md").read_text())
        self.assert_all_put_back()

    def test_no_turn_settle_by_default(self):
        result, fake, out = self.run_fake("on")
        self.assertNotIn("turnSettle", result)
        self.assertEqual([c for c in fake.cams], [])
        self.assertFalse((self.tmp / "results/run1/turn").exists())
        self.assertNotIn("Turn settle", (self.tmp / "results/run1/report.md").read_text())

    def test_no_shots_by_default(self):
        result, fake, out = self.run_fake("on")
        self.assertNotIn("images", result)
        self.assertFalse((self.tmp / "results/run1/shots").exists())
        self.assertNotIn("SSIM", (self.tmp / "results/run1/report.md").read_text())

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
