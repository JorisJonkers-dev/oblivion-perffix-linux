import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import report  # noqa: E402


def run(label, fps, hitches=0):
    return {"label": label, "scenario": "showcase", "profile": {"name": "small"}, "outcome": "ok", "fix": "x",
            "scenes": [{"id": "flight", "type": "fly", "seconds": 100, "frames": 1000, "fps": fps, "low1": fps / 2,
                        "low01": fps / 3, "worstMs": 80.0, "hitches": hitches, "over50": 1, "p99Ms": 20.0,
                        "cpuLoad": 50.0, "gpuLoad": 90.0},
                       {"id": "only-here", "type": "static", "seconds": 20, "frames": 0}]}


class ReportTest(unittest.TestCase):
    def test_compare_medians(self):
        a = [(Path("a1"), run("a1", 100, 4)), (Path("a2"), run("a2", 110, 2)), (Path("a3"), run("a3", 90, 3))]
        b = [(Path("b1"), run("b1", 120, 1)), (Path("b2"), run("b2", 130, 1))]
        c = report.compare(a, b, "stock", "fix")
        row = c["scenes"]["flight"]
        self.assertEqual(row["fps"]["a"], 100)
        self.assertEqual(row["fps"]["b"], 125)
        self.assertEqual(row["fps"]["deltaPct"], 25.0)
        self.assertFalse(row["fps"]["noise"])
        self.assertTrue(row["gpuLoad"]["noise"])
        self.assertEqual(row["hitches"]["a"], 3)
        self.assertNotIn("only-here", c["scenes"])          # no frames: not compared
        md = report.compare_markdown(c, a, b)
        self.assertIn("| flight | 3+2 |", md)
        self.assertIn("100.0 -> 125.0 (+25%)", md)

    def test_write_and_resolve(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            for name, fps in (("x-stock-r1", 100), ("x-on-r1", 110)):
                rd = d / f"20261107-120000-{name}"
                rd.mkdir()
                (rd / "result.json").write_text(json.dumps(run(name, fps)))
            ra = report.load_runs(["x-stock-r1"], d)
            rb = report.load_runs(["x-on-r1"], d)
            out = report.write_comparison(ra, rb, "stock", "on", d, "cmp")
            md = (out / "report.md").read_text()
            self.assertIn("100.0 -> 110.0 (+10%)", md)              # over 5 %: no noise mark
            self.assertIn("(+0% ~)", md)
            data = json.loads((out / "report.json").read_text())
            self.assertEqual(data["scenes"]["flight"]["fps"]["deltaPct"], 10.0)
            with self.assertRaises(FileNotFoundError):
                report.resolve_run("nope", d)

    def test_run_report(self):
        md = report.run_report(dict(run("r", 100), frameLog={"method": "sync marker", "frames": 5, "log": "x.csv"},
                                    warnings=["w1"]))
        self.assertIn("| flight | fly |", md)
        self.assertIn("- w1", md)


if __name__ == "__main__":
    unittest.main()
