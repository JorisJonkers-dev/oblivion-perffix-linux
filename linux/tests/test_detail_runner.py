"""Detail arrival wired into the runner (fake game, mocked window capture) and per-side ini in `bench.py ab`."""
import json
import sys
import time
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import bench  # noqa: E402
import test_runner  # noqa: E402
from oblvbench import detail, game, report, runner  # noqa: E402
from test_detail import blur, frame_of, noise_image  # noqa: E402

SCENARIO = {
    "name": "mini", "startCell": "TestCell",
    "defaults": {"hour": 12, "weather": "Clear", "settle": 0.3, "measure": 0.5, "hold": 0.5},
    "weathers": {"Clear": "00038EEE"},
    "places": {"spot": {"world": "TestWorld", "pos": [1000, 2000, 300], "heading": 90, "pitch": 0}},
    "masks": [[0.94, 0.0, 0.06, 0.035]],
    "scenes": [{"id": "inn-door", "type": "door", "at": "spot"},
               {"id": "still", "type": "static", "at": "spot", "detail": True},
               {"id": "plain", "type": "static", "at": "spot"}],
}


class DoorGame(test_runner.FakeGame):
    def handlers(self):
        h = super().handlers()
        flip = [0]

        def activate(m, rest):
            flip[0] += 1
            self.pos = (self.pos[0] + 2000 * (1 if flip[0] % 2 else -1), self.pos[1], self.pos[2])
            return "activated"

        h["activate"] = activate
        return h


class FakeCapturer:
    """Blurry for the first `blurry` grabs after each reset (a new window), then sharp."""
    instances = []

    def __init__(self, *a, **k):
        FakeCapturer.instances.append(self)
        self.calls, self.last = 0, 0.0
        self.img = noise_image(160, 90)
        self.frames = [frame_of(blur(self.img, 4)), frame_of(self.img)]

    def grab(self):
        if time.time() - self.last > 0.5:               # a new window of captures: blurry again
            self.calls = 0
        self.last = time.time()
        self.calls += 1
        return self.frames[0 if self.calls <= 4 else 1]


class DetailRunnerTest(test_runner.RunnerTest):
    def setUp(self):
        super().setUp()
        (self.tmp / "scen/mini.json").write_text(json.dumps(SCENARIO))
        FakeCapturer.instances = []
        self.before = {p: p.read_bytes() for p in self.tmp.rglob("*") if p.is_file()}

    def make_game(self, run_dir):
        return DoorGame(self.paths, run_dir / "mangohud")

    def make_run(self, run_dir, out, fix, **kw):
        opts = runner.Options(scenario="mini", scenario_dir=self.tmp / "scen", fix=fix, label="t", warmup=0,
                              steam="true", run_dir=run_dir, profile="small", launch_timeout=20,
                              detail_secs=1.6, detail_interval=0.1, **{**self.detail_kw, **kw})
        return runner.Runner(self.paths, opts, say=out.append).run()

    detail_kw = {"detail": True}

    def test_stock_run(self):                       # the inherited test is for the plain scenario
        pass

    def test_off_run_env(self):
        pass

    def test_detail_in_door_legs_and_flagged_static(self):
        with mock.patch.object(runner.detail, "Capturer", FakeCapturer):
            result, fake, out = self.run_fake("on")
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        rows = {s["id"]: s for s in result["scenes"]}
        for leg in ("inn-door/enter", "inn-door/exit", "still"):
            r = rows[leg]
            self.assertIn("detailSettleS", r, (leg, r))
            self.assertGreaterEqual(r["detailSamples"], 8)
            self.assertGreater(r["detailSettleS"], 0.2)
            self.assertLess(r["detailSettleS"], 1.2)
            self.assertEqual(r["detailAt1s"], 1.0)
            self.assertEqual(r["detailSeries"][0][1] < r["detailSeries"][-1][1], True)
        self.assertNotIn("detailSamples", rows["plain"])           # no flag, no capture
        self.assertGreaterEqual(rows["inn-door/enter"]["seconds"], 1.6)
        md = (self.tmp / "results/run1/report.md").read_text()
        self.assertIn("Detail arrival", md)
        self.assertIn("| inn-door/enter |", md)

    def test_off_by_default(self):
        FakeCapturer.instances = []
        type(self).detail_kw = {}
        try:
            with mock.patch.object(runner.detail, "Capturer", FakeCapturer):
                result, fake, out = self.run_fake("on")
        finally:
            type(self).detail_kw = {"detail": True}
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(FakeCapturer.instances, [])
        self.assertTrue(all("detailSamples" not in s for s in result["scenes"]))

    def test_capture_failures_warn_not_fail(self):
        class Broken(FakeCapturer):
            def grab(self):
                raise detail.CaptureError("no window")

        with mock.patch.object(runner.detail, "Capturer", Broken):
            result, fake, out = self.run_fake("on")
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertTrue(any("window capture failed" in w for w in result["warnings"]))
        self.assertTrue(any("no detail result" in w for w in result["warnings"]))


class AbIniTest(unittest.TestCase):
    def parse(self, argv):
        import argparse
        seen = {}
        with mock.patch.object(bench, "cmd_ab", lambda a, p: seen.setdefault("a", a) and 0), \
                mock.patch.object(bench, "Paths", lambda **k: object()):
            bench.main(argv)
        return seen["a"]

    def test_side_ini_and_names(self):
        a = self.parse(["ab", "--scenario", "cheydinhal", "--a", "on", "--b", "on", "--fix-ini", "Common=1,X=2",
                        "--b-ini", "VtStreamingUploads=64,FadeVtFlushSkip=1", "--detail", "--detail-secs", "8"])
        self.assertEqual(bench.side_ini(a, "a"), ["Common=1,X=2"])
        self.assertEqual(bench.side_ini(a, "b"), ["Common=1,X=2", "VtStreamingUploads=64,FadeVtFlushSkip=1"])
        self.assertEqual(bench.side_name(a, "a"), "on")
        self.assertEqual(bench.side_name(a, "b"), "on+VtStreamingUploads=64,FadeVtFlushSkip=1")
        kw = bench.run_kwargs(a, fix_ini=bench.side_ini(a, "b"))
        self.assertTrue(kw["detail"])
        self.assertEqual(kw["detail_secs"], 8)
        self.assertEqual(kw["detail_interval"], 0.5)
        o = runner.Options(**kw)
        from oblvbench import fixini
        self.assertEqual(fixini.parse_overrides(o.fix_ini)["VtStreamingUploads"], "64")

    def test_no_side_ini(self):
        a = self.parse(["ab", "--a", "stock", "--b", "on"])
        self.assertIsNone(bench.side_ini(a, "a"))
        self.assertEqual(bench.side_name(a, "b"), "on")

    def test_ab_runs_each_side_with_its_ini(self):
        a = self.parse(["ab", "--a", "on", "--b", "on", "--rounds", "1", "--fix-ini", "K=1", "--b-ini", "VtStreamingUploads=64"])
        seen = []

        class R:
            def __init__(self, paths, opts, say=None):
                seen.append((opts.fix, opts.fix_ini, opts.label))

            def run(self):
                return {"outcome": "ok"}

        class Inst:
            def install(self): pass
            def remove(self): pass

        class P:
            results = Path("/nonexistent")

        with mock.patch.object(bench, "Runner", R), mock.patch.object(bench, "installer", lambda p: Inst()), \
                mock.patch.object(bench, "load_runs", lambda n, d: n), \
                mock.patch.object(bench, "write_comparison", mock.Mock(return_value=Path("/tmp/x"))) as wc, \
                mock.patch.object(bench.time, "sleep"), mock.patch.object(Path, "read_text", lambda s: ""):
            bench.cmd_ab(a, P())
        self.assertEqual([s[1] for s in seen], [["K=1"], ["K=1", "VtStreamingUploads=64"]])
        self.assertNotEqual(seen[0][2], seen[1][2])
        self.assertEqual(wc.call_args[0][2:4], ("on", "on+VtStreamingUploads=64"))


    def test_ab_dll_side_with_ini(self):
        import hashlib
        import shutil
        import tempfile
        d = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, d)
        dll = d / "new.dll"
        dll.write_bytes(b"abc")
        sha8 = hashlib.sha256(b"abc").hexdigest()[:8]
        a = self.parse(["ab", "--a", "on", "--b", f"dll:{dll}", "--rounds", "1", "--b-ini", "VtStreamingUploads=64"])
        seen = []

        class R:
            def __init__(self, paths, opts, say=None):
                seen.append((opts.fix, opts.dll, opts.fix_ini, opts.label))

            def run(self):
                return {"outcome": "ok"}

        class Inst:
            def install(self): pass
            def remove(self): pass

        class P:
            results = Path("/nonexistent")

        with mock.patch.object(bench, "Runner", R), mock.patch.object(bench, "installer", lambda p: Inst()), \
                mock.patch.object(bench, "load_runs", lambda n, d: n), \
                mock.patch.object(bench, "write_comparison", mock.Mock(return_value=Path("/tmp/x"))) as wc, \
                mock.patch.object(bench.time, "sleep"), mock.patch.object(Path, "read_text", lambda s: ""):
            bench.cmd_ab(a, P())
        self.assertEqual([s[:3] for s in seen], [("on", None, None), ("on", str(dll), ["VtStreamingUploads=64"])])
        self.assertIn("-Aon-r1", seen[0][3])
        self.assertIn(f"-Bdll-{sha8}-r1", seen[1][3])
        self.assertEqual(wc.call_args[0][2:4], ("on", f"dll-{sha8}+VtStreamingUploads=64"))

    def test_identical_sides_refused(self):
        a = self.parse(["ab", "--a", "on", "--b", "on"])
        with self.assertRaises(SystemExit):
            bench.cmd_ab(a, object())


class ReportDetailTest(unittest.TestCase):
    def run_of(self, label, settle, at1):
        return {"label": label, "scenario": "x", "profile": {"name": "small"}, "outcome": "ok", "fix": "on",
                "scenes": [{"id": "inn-door/enter", "type": "door", "seconds": 12, "frames": 500, "fps": 60,
                            "arriveSec": 1.0, "detailSamples": 24, "detailSettleS": settle, "detailAt1s": at1,
                            "detailAt2s": 0.9, "detailAt4s": 1.0}]}

    def test_compare_detail(self):
        a = [(Path("a1"), self.run_of("a1", 8.0, 0.2)), (Path("a2"), self.run_of("a2", 10.0, 0.3)),
             (Path("a3"), self.run_of("a3", 9.0, 0.25))]
        b = [(Path("b1"), self.run_of("b1", 2.5, 0.8)), (Path("b2"), self.run_of("b2", 2.3, 0.9))]
        c = report.compare(a, b, "base", "vt64")
        d = c["scenes"]["inn-door/enter"]["detail"]
        self.assertEqual(d["detailSettleS"]["a"], 9.0)
        self.assertEqual(d["detailSettleS"]["b"], 2.4)
        self.assertAlmostEqual(d["detailSettleS"]["delta"], -6.6)
        md = report.compare_markdown(c, a, b)
        self.assertIn("Detail arrival", md)
        self.assertIn("9.0 -> 2.4 s (-6.6 s)", md)
        self.assertIn("0.25 -> 0.85", md)


if __name__ == "__main__":
    unittest.main()
