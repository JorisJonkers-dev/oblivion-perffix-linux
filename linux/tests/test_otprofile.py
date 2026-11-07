"""tools/ot_profile.py on a small synthetic csv, and the runner's --diag collection of it (collect_diag copies the file
and writes diag/ot_profile.txt)."""
import os
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "linux"))
sys.path.insert(0, str(ROOT / "tools"))

import ot_profile  # noqa: E402
from oblvbench import fixini, runner  # noqa: E402

STAGES = ["pl_pre", "pl_update", "lvl_low", "lvl_midlow", "lvl_midhigh", "lvl_high", "pl_pass2", "pl_pass3", "grid_player",
          "grid_own", "door", "pl_timed", "water", "save"]
F_COLS = ("F,seq,end_ms,cycle_ms,busy_ms,idle_ms,body_ms,other_ms,gtwait_ms,gtwait_n,marker,marker_pct,"
          + ",".join(s + "_ms" for s in STAGES))
S_COLS = ("S,seq,end_ms,window_s,frames,slow,cycle_ms,busy_ms,idle_ms,body_ms,gtwait_ms,gtwait_n,max_busy_ms,slow_busy_ms,"
          + ",".join(s + "_ms" for s in STAGES) + "," + ",".join("slow_" + s + "_ms" for s in STAGES) + ","
          + ",".join(s + "_n" for s in STAGES))


def s_row(end, frames, slow, stage_ms, slow_stage_ms, gt=-1.0):
    n = {k: frames for k in stage_ms}
    vals = [frames * 10.0, frames * 6.0, frames * 4.0, frames * 5.5, gt, 0 if gt < 0 else frames, 40.0, slow * 40.0]
    row = ["S", 1, end, 2.0, frames, slow] + [("%.3f" % v) for v in vals]
    row += ["%.3f" % stage_ms.get(s, 0) for s in STAGES] + ["%.3f" % slow_stage_ms.get(s, 0) for s in STAGES]
    row += [str(n.get(s, 0)) for s in STAGES]
    return ",".join(str(x) for x in row)


def make_csv(path, gt=0.0):
    lines = ["# OblivionPerfFix-otprofile v1, OblivionPerfFix 1.2.4, qpc_freq=10000000, pid=1, threshold_ms=10, sample_hz=1000, gt_wait=1, signals=x",
             "#" + F_COLS, "#" + S_COLS, "#M,end_ms,samples,marker=count;..."]
    lines.append(s_row(2000.0, 100, 2, {"pl_update": 300.0, "lvl_high": 200.0, "grid_player": 50.0, "door": 10.0},
                       {"pl_update": 70.0, "lvl_high": 60.0, "grid_player": 40.0}, gt))
    lines.append(s_row(4000.0, 100, 0, {"pl_update": 310.0, "lvl_high": 210.0}, {}, gt))
    f = ["F", 7, 3000.0, 52.0, 45.0, 7.0, 44.0, 5.0, 0.0, 0, "0xB4", 80] + ["%.3f" % v for v in
         (1, 30, 0, 0, 0, 28, 0, 0, 0, 0, 0, 0, 0, 0)]
    lines.append(",".join(str(x) for x in f))
    lines.append("M,3000.000,100,0x64=30;0xB4=60;0x190=10")
    path.write_text("\n".join(lines) + "\n")


class ToolTest(unittest.TestCase):
    def test_report(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "OblivionPerfFix-otprofile.csv"
            make_csv(p)
            head, f, s, m = ot_profile.parse(str(p))
            self.assertEqual((len(f), len(s), len(m)), (1, 2, 1))
            text = ot_profile.report(str(p))
        self.assertIn("200 cycles", text)
        self.assertIn("busy       6.00 ms avg", text)
        self.assertIn("idle       4.00 ms avg", text)
        self.assertIn("GT wait", text)
        # ranked by total: pl_update first; the level pass is marked as nested
        lines = [l for l in text.splitlines() if l.startswith(("pl_update", "lvl_high"))]
        self.assertTrue(lines[0].startswith("pl_update"))
        self.assertTrue(any(l.startswith("lvl_high") and l.endswith("in") for l in lines))
        self.assertIn("0xB4 (Update: level pass 4)", text)
        self.assertIn("slow cycles", text)

    def test_range_and_unmeasured_gt(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "x.csv"
            make_csv(p, gt=-1.0)
            text = ot_profile.report(str(p))
            self.assertIn("GT wait  not measured", text)
            text = ot_profile.report(str(p), lo=3000.0, hi=5000.0)
            self.assertIn("100 cycles", text)
            self.assertIn("no 2 s aggregates", ot_profile.report(str(p), lo=9000.0))


class CollectDiagTest(unittest.TestCase):
    def test_collects_and_ranks(self):
        self.assertIn("OblivionPerfFix-otprofile.csv", fixini.DIAG_FILES)
        with tempfile.TemporaryDirectory() as d:
            win64, run_dir = Path(d) / "win64", Path(d) / "run"
            win64.mkdir()
            run_dir.mkdir()
            make_csv(win64 / "OblivionPerfFix-otprofile.csv")
            fake = SimpleNamespace(result={}, say=lambda *_: None)
            runner.Runner.collect_diag(fake, run_dir, win64, 0)
            self.assertIn("OblivionPerfFix-otprofile.csv", fake.result["diagFiles"])
            self.assertTrue((run_dir / "diag" / "OblivionPerfFix-otprofile.csv").exists())
            txt = (run_dir / "diag" / "ot_profile.txt").read_text()
            self.assertIn("== The OT's cycle", txt)
            self.assertIn("pl_update", txt)


if __name__ == "__main__":
    unittest.main()
