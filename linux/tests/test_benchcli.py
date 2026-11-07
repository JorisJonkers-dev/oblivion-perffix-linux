"""bench.py ab with a dll: side: the runs get the right fix mode / DLL and the sides are named by the DLL's hash."""
import hashlib
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import bench  # noqa: E402


class AbVariantTest(unittest.TestCase):
    def test_ab_dll_side(self):
        tmp = Path(tempfile.mkdtemp())
        try:
            dll, ini = tmp / "x.dll", tmp / "x.ini"
            dll.write_bytes(b"abc")
            ini.write_text("[Fixes]\n")
            calls = []

            class FakeRunner:
                def __init__(self, paths, opts, say=print):
                    calls.append(opts)
                    self.opts = opts

                def run(self):
                    return {"outcome": "ok"}

            sha8 = hashlib.sha256(b"abc").hexdigest()[:8]
            with mock.patch.object(bench, "Runner", FakeRunner), mock.patch.object(bench, "write_comparison") as wc, \
                    mock.patch.object(bench, "load_runs", lambda names, d: names), \
                    mock.patch.object(bench, "installer"), mock.patch.object(bench.time, "sleep"), \
                    mock.patch("pathlib.Path.read_text", return_value="r"), mock.patch("builtins.print"):
                wc.return_value = tmp
                bench.main(["--game-dir", str(tmp), "ab", "--scenario", "s", "--rounds", "1", "--a", "on",
                            "--b", f"dll:{dll}", "--dll-ini", str(ini)])
            self.assertEqual([(o.fix, o.dll, o.dll_ini) for o in calls],
                             [("on", None, None), ("on", str(dll), str(ini))])
            self.assertEqual(wc.call_args[0][2:4], ("on", f"dll-{sha8}"))
        finally:
            shutil.rmtree(tmp)

    def test_same_variant_and_bad_side_refused(self):
        with self.assertRaises(SystemExit):
            bench.main(["ab", "--a", "on", "--b", "on"])
        with self.assertRaises(SystemExit):
            bench.main(["ab", "--a", "on", "--b", "dll:/nonexistent/x.dll"])


if __name__ == "__main__":
    unittest.main()
