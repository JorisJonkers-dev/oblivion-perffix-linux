import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools" / "gpuprof"))

import utrace_report as ur  # noqa: E402

CSV = """frame,batch,time_ns,event,
0,0,1000,radv_begin_cmd_buffer,
0,0,1000,radv_begin_rendering,width=1506, height=847, colors=2,
0,0,1100,radv_begin_Draw,vertex_count=3, instance_count=1, pipeline=0xaa,
0,0,1500,radv_end_Draw,
0,0,1600,radv_end_rendering,
0,0,1600,radv_begin_Dispatch,pipeline=0xbb,
0,0,2600,radv_end_Dispatch,
0,0,2600,radv_end_cmd_buffer,
"""


class ReportTest(unittest.TestCase):
    def test_nesting_and_exclusive(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "t.csv"
            p.write_text(CSV)
            frames = ur.load(str(p))
        root = frames[0][0]
        self.assertEqual(root.dur, 1600)
        rend = root.children[0]
        self.assertEqual((rend.kind, rend.dur, rend.excl), ("rendering", 600, 200))
        self.assertEqual(rend.children[0].params["pipeline"], "0xaa")
        self.assertEqual(root.excl, 0)

    def test_hints(self):
        self.assertEqual(ur.extent_hint(1506, 847, (1506, 847), (2560, 1440)), "internal")
        self.assertEqual(ur.extent_hint(753, 424, (1506, 847), None), "internal/2")
        self.assertIn("internal", ur.grid_hint(189, 106, 1, (1506, 847), None))


if __name__ == "__main__":
    unittest.main()
