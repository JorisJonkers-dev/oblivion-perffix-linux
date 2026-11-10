"""bench.py spin through the command line: every option reaches SpinOptions (a missing attribute once crashed it)."""
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import bench  # noqa: E402


class SpinCliTest(unittest.TestCase):
    def test_spin_builds_options(self):
        seen = {}

        class FakeRunner:
            def __init__(self, paths, opts, say=None):
                seen["opts"] = opts

            def run(self):
                return {"outcome": "ok"}

        with mock.patch.object(bench, "SpinRunner", FakeRunner), mock.patch.object(bench, "Paths", lambda **k: object()):
            rc = bench.main(["spin", "--scene", "cheydinhal-canal", "--profile", "own", "--label", "t",
                             "--variant", "vt64:ini:VtStreamingUploads=64", "--diag"])
        self.assertEqual(rc, 0)
        o = seen["opts"]
        self.assertEqual(o.fix, "on")
        self.assertTrue(o.diag)
        self.assertEqual(o.scenes, ["cheydinhal-canal"])
        self.assertEqual([v.name for v in o.variants], ["base", "vt64"])  # base = as installed


if __name__ == "__main__":
    unittest.main()
