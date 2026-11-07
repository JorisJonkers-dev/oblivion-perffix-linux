import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import mangohud, spin  # noqa: E402
from oblvbench.paths import REPO  # noqa: E402

SHIPPED = (REPO / "src/OblivionPerfFix/OblivionPerfFix.ini").read_text(encoding="utf-8-sig")


class VariantTest(unittest.TestCase):
    def test_parse(self):
        v = spin.parse_variant("nopar:ini:RdgParallelTranslate=0, GpuSceneParallelUpload=0")
        self.assertEqual((v.name, v.kind, v.values), ("nopar", "ini", {"RdgParallelTranslate": "0", "GpuSceneParallelUpload": "0"}))
        v = spin.parse_variant("lod:cvar:r.ViewDistanceScale=0.5,r.Foo=1")
        self.assertEqual((v.kind, v.values), ("cvar", {"r.ViewDistanceScale": "0.5", "r.Foo": "1"}))

    def test_parse_errors(self):
        for bad in ("x", "x:ini", "x:env:A=1", "x:ini:", "x:ini:A", "x y:ini:A=1", "x:ini:A="):
            with self.assertRaises(spin.SpinError, msg=bad):
                spin.parse_variant(bad)

    def test_base_first_and_duplicates(self):
        vs = spin.parse_variants(["a:ini:K=1", "b:cvar:r.X=2"])
        self.assertEqual([v.name for v in vs], ["base", "a", "b"])
        with self.assertRaises(spin.SpinError):
            spin.parse_variants(["base:ini:K=1"])
        with self.assertRaises(spin.SpinError):
            spin.parse_variants(["a:ini:K=1", "a:ini:K=2"])

    def test_balanced_order(self):
        self.assertEqual(" ".join(spin.balanced_order(["A", "B"], 2)), "A B B A A B B A")
        self.assertEqual(" ".join(spin.balanced_order(["A", "B", "C"], 1)), "A B C C B A")
        self.assertEqual(len(spin.balanced_order(["A"], 3)), 6)
        with self.assertRaises(spin.SpinError):
            spin.balanced_order(["A"], 0)


class IniModeTest(unittest.TestCase):
    def test_shipped_ini_classes(self):
        m = spin.ini_modes(SHIPPED)
        self.assertGreater(len(m), 60)
        self.assertEqual(m["BoneUploadStores"], "startup")             # "Start-up only."
        self.assertEqual(m["AtmosphereDirtyFilter"], "install")        # "Start-up, then live."
        self.assertEqual(m["AtmosphereLightFastPath"], "live")
        self.assertEqual(m["RdgParallelTranslate"], "live")
        self.assertEqual(m["FadeVtFlushSkip"], "install")              # "Takes a restart to switch on, then live."
        self.assertEqual(m["MonitorNativeFromWindows"], "startup")     # "Takes a restart."
        self.assertEqual(m["SaveBytesBulk"], "install")                # "Installed when the game starts, then live."

    def test_refuses_startup_only_keys(self):
        modes = spin.ini_modes(SHIPPED)
        vs = spin.parse_variants(["bad:ini:BoneUploadStores=0"])
        problems = spin.check_ini_variants(vs, modes, {"BoneUploadStores": "1"})
        self.assertEqual(len(problems), 1)
        self.assertIn("Start-up only", problems[0])
        # the same value as installed changes nothing: fine
        self.assertEqual(spin.check_ini_variants(vs, modes, {"BoneUploadStores": "0"}), [])

    def test_install_keys_need_to_be_on_at_start(self):
        modes = spin.ini_modes(SHIPPED)
        on = spin.parse_variants(["on:ini:AtmosphereDirtyFilter=1"])
        self.assertEqual(len(spin.check_ini_variants(on, modes, {"AtmosphereDirtyFilter": "0"})), 1)
        off = spin.parse_variants(["off:ini:AtmosphereDirtyFilter=0"])
        self.assertEqual(spin.check_ini_variants(off, modes, {"AtmosphereDirtyFilter": "1"}), [])

    def test_live_and_unknown_keys(self):
        modes = spin.ini_modes(SHIPPED)
        self.assertEqual(spin.check_ini_variants(spin.parse_variants(["x:ini:RdgParallelTranslate=0"]), modes,
                                                 {"RdgParallelTranslate": "2"}), [])
        self.assertEqual(len(spin.check_ini_variants(spin.parse_variants(["x:ini:NoSuchKey=1"]), modes, {})), 1)
        self.assertEqual(spin.check_ini_variants(spin.parse_variants(["c:cvar:r.X=1"]), modes, {}), [])

    def test_targets_put_other_variants_keys_back(self):
        vs = spin.parse_variants(["a:ini:K1=0", "b:ini:K2=0", "c:cvar:r.X=2"])
        t = spin.ini_targets(vs, {"K1": "1", "K2": "5", "Other": "9"})
        self.assertEqual(t["base"], {"K1": "1", "K2": "5"})
        self.assertEqual(t["a"], {"K1": "0", "K2": "5"})
        self.assertEqual(t["b"], {"K1": "1", "K2": "0"})
        self.assertEqual(t["c"], t["base"])
        c = spin.cvar_targets(vs, {"r.X": "1.0"})
        self.assertEqual((c["base"], c["c"], c["a"]), ({"r.X": "1.0"}, {"r.X": "2"}, {"r.X": "1.0"}))
        with self.assertRaises(spin.SpinError):
            spin.ini_targets(vs, {"K1": "1"})                      # K2 not in the ini: cannot be put back

    def test_same_value(self):
        self.assertTrue(spin.same_value("1.0", "1"))
        self.assertFalse(spin.same_value("0.5", "1"))
        self.assertTrue(spin.same_value("True", "true"))


def make_log(rate, laps, ft_of_sector, start=1000.0, t_spin0=1000.0, h0=0.0, lag=0.0):
    """Frames over `laps` laps; each frame's duration depends on the sector of the heading at its wall time."""
    log = mangohud.FrameLog()
    t, el = 0.0, 0.0
    dur = laps * 360.0 / rate
    while el < dur:
        h = spin.spin_heading(h0, rate, t_spin0, start + el - lag)
        ft = ft_of_sector(spin.sector_of(h))
        el += ft / 1000.0
        log.elapsed.append(el)
        log.frametime.append(ft)
        log.cpu_load.append(None)
        log.gpu_load.append(80.0)
    return log


class SlicingTest(unittest.TestCase):
    def test_sector_and_lap_math(self):
        self.assertEqual(spin.sector_of(0), 0)
        self.assertEqual(spin.sector_of(22.4), 0)
        self.assertEqual(spin.sector_of(22.6), 1)
        self.assertEqual(spin.sector_of(359), 0)
        self.assertEqual(spin.sector_of(-30), 7)
        self.assertEqual(spin.sector_of(725), 0)
        self.assertEqual(spin.lap_seconds(30), 12.0)
        self.assertAlmostEqual(spin.next_lap_start(105.0, 100.0, 30), 112.0)
        self.assertAlmostEqual(spin.next_lap_start(112.0, 100.0, 30), 112.0)
        self.assertAlmostEqual(spin.next_lap_start(90.0, 100.0, 30), 100.0)

    def test_timeline_interpolates(self):
        tl = spin.Timeline([(10.0, 0.0), (10.1, 3.0), (10.2, 6.0)])
        self.assertAlmostEqual(tl.at(10.05), 1.5)
        self.assertAlmostEqual(tl.at(10.2), 6.0)
        self.assertIsNone(tl.at(50.0))
        with self.assertRaises(ValueError):
            tl.add(9.0, 1.0)

    def timeline(self, rate=30.0, t_spin0=1000.0, seconds=60, step=0.075):
        return spin.Timeline([(t_spin0 + i * step, spin.spin_heading(0, rate, t_spin0, t_spin0 + i * step))
                              for i in range(int(seconds / step))])

    def test_two_laps_and_sectors(self):
        ft = lambda sec: 20.0 if sec == 2 else 10.0              # east is slow
        log = make_log(30.0, 2, ft)
        s = spin.slot_stats(log, 1000.0, 1000.0, 1024.0, self.timeline(), lag=0.0, laps=2)
        self.assertEqual(len(s["lapsFps"]), 2)
        for f in s["lapsFps"]:
            self.assertAlmostEqual(f, 93.75, delta=1.5)
        fps = s["sectorFps"]
        self.assertAlmostEqual(fps[2], 50.0, delta=1.5)
        for i in (0, 1, 3, 4, 5, 6, 7):
            self.assertAlmostEqual(fps[i], 100.0, delta=1.5, msg=f"sector {i}")
        self.assertEqual(min(range(8), key=lambda i: fps[i]), 2)
        # the sectors share the frames: each lap-pair covers every sector
        self.assertTrue(all(n > 100 for n in s["sectorFrames"]))

    def test_partial_lap_start_still_covers_all_sectors(self):
        log = make_log(30.0, 3, lambda sec: 10.0)
        s = spin.slot_stats(log, 1000.0, 1000.0 + 5.0, 1000.0 + 29.0, self.timeline(), lag=0.0, laps=2)
        self.assertTrue(all(n > 100 for n in s["sectorFrames"]))

    def test_camera_lag_moves_frames_between_sectors(self):
        ft = lambda sec: 20.0 if sec == 2 else 10.0
        log = make_log(30.0, 2, ft, lag=0.3)                     # the picture shows the heading 0.3 s earlier
        right = spin.slot_stats(log, 1000.0, 1000.0, 1024.0, self.timeline(), lag=0.3, laps=2)["sectorFps"]
        wrong = spin.slot_stats(log, 1000.0, 1000.0, 1024.0, self.timeline(), lag=0.0, laps=2)["sectorFps"]
        self.assertAlmostEqual(right[2], 50.0, delta=1.0)
        self.assertGreater(abs(wrong[2] - 50.0), abs(right[2] - 50.0))

    def test_hitch_counts_in_slot(self):
        log = make_log(30.0, 2, lambda sec: 10.0)
        log.frametime[500] = 90.0
        s = spin.slot_stats(log, 1000.0, 1000.0, 1024.0, self.timeline(), laps=2)
        self.assertEqual(s["hitches"], 1)
        self.assertEqual(s["worstMs"], 90.0)


class SummaryTest(unittest.TestCase):
    def slot(self, v, fps, sectors=None, **kw):
        return {"variant": v, "frames": 100, "fps": fps, "low1": fps - 10, "low01": fps - 20, "p99Ms": 1000 / (fps - 10),
                "worstMs": 30.0, "hitches": 1, "gpuLoad": 90.0, "cpuLoad": 40.0,
                "sectorFps": sectors or [fps] * 8, **kw}

    def test_medians_deltas_and_spread(self):
        vs = spin.parse_variants(["x:cvar:r.A=1"])
        slots = [self.slot("base", 100), self.slot("x", 120), self.slot("x", 124), self.slot("base", 104),
                 self.slot("base", 96), self.slot("x", 110)]
        rows = spin.summarise(slots, vs)
        base, x = rows
        self.assertEqual(base["fps"], 100)
        self.assertEqual(x["fps"], 120)
        self.assertEqual(x["deltaPct"]["fps"], 20.0)
        self.assertEqual(base["slots"], 3)
        self.assertEqual((base["fpsMin"], base["fpsMax"]), (96, 104))
        self.assertAlmostEqual(base["spreadPct"], 8.0)
        self.assertEqual(x["noiseFloorPct"], max(spin.NOISE_PCT, 8.0, x["spreadPct"]))
        self.assertEqual(x["sectorDeltaPct"][0], 20.0)

    def test_report_names_worst_sector(self):
        vs = spin.parse_variants([])
        sec = [100, 100, 60, 100, 100, 100, 100, 100]
        rows = spin.summarise([self.slot("base", 90, sec)], vs)
        result = {"label": "t", "time": "now", "profile": {"name": "small"}, "pinned": True, "outcome": "ok",
                  "spin": {"spot": "s", "degPerSec": 30, "lapSec": 12, "pitch": 0, "laps": 2, "settle": 4, "camLag": 0.3,
                           "order": ["base", "base"]}, "variants": rows,
                  "slots": [dict(self.slot("base", 90, sec), seconds=24, lapsFps=[90, 90])], "warnings": ["w1"]}
        md = spin.report_markdown(result)
        self.assertIn("| base | base | 1 |", md)
        self.assertIn("E 90°", md)
        self.assertIn("| E 90° |", md)       # the 'worst' column
        self.assertIn("w1", md)


LEDGER = ("# OblivionPerfFix-ledger v1, OblivionPerfFix 1.2.3, qpc_freq=10000000, pid=1, threshold_ms=20.0\n"
          "#F,frame,end_ms,period_ms,sleep_ms\n#S,frame,end_ms,frames\n")


class LedgerTest(unittest.TestCase):
    def text(self, rows):
        return LEDGER + "".join(f"F,{i},{e},{p},0\n" for i, (e, p) in enumerate(rows)) + "S,1,5000,10\n"

    def test_anchor_and_split(self):
        # wall = end_ms/1000 + 5000: stalls at wall 5100 and 5160 (end_ms 100000 and 160000)
        rows = [(50000, 400), (100000, 360), (130000, 700), (160000, 355), (170000, 30), (200000, 25)]
        frames = spin.ledger_frames(self.text(rows))
        self.assertEqual(len(frames), 6)
        off = spin.anchor_ledger(frames, [(5100.02, 350), (5160.02, 350)])
        # candidates 100000/160000 pair match the 60 s distance: the offset is 5000 (+ the answer's latency)
        self.assertAlmostEqual(off, 5000 - 100.0 + 100.0 + 0.02 - 0.0, delta=0.05)
        texts, summ = spin.split_ledger(self.text(rows), {"a": [(5160.0, 5165.0)], "b": [(5169.0, 5171.0)]}, off)
        self.assertEqual(summ["a"]["frames"], 1)           # the 160000 row (wall 5160.02)
        self.assertEqual(summ["b"]["frames"], 1)           # the 170000 row
        self.assertIn("F,3,160000,355,0", texts["a"])
        self.assertNotIn("F,4", texts["a"])
        self.assertTrue(texts["a"].startswith("# OblivionPerfFix-ledger"))

    def test_anchor_needs_two_markers(self):
        frames = spin.ledger_frames(self.text([(100000, 360)]))
        self.assertIsNone(spin.anchor_ledger(frames, [(5100.0, 350)]))
        self.assertIsNone(spin.anchor_ledger(frames, [(5100.0, 350), (5300.0, 350)]))


if __name__ == "__main__":
    unittest.main()
