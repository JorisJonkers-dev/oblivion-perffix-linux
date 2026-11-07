import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import fixini  # noqa: E402
from oblvbench.paths import REPO  # noqa: E402

SAMPLE = ("; OblivionPerfFix\r\n[Fixes]\r\n; a comment = not a key\r\nBoneUploadStores=1\r\n"
          "RdgParallelTranslate = 2   ; automatic\r\nFrameRateLimitAtStart=1\r\nChaosMaxPayloadSize=10000000\r\n"
          "\r\n[General]\r\nLogFile=1\r\nStatsIntervalSeconds=60\r\n")


class StockTest(unittest.TestCase):
    def test_fix_values(self):
        self.assertEqual(fixini.fix_values(SAMPLE), {"BoneUploadStores": "1", "RdgParallelTranslate": "2",
                                                     "FrameRateLimitAtStart": "1", "ChaosMaxPayloadSize": "10000000"})

    def test_stock(self):
        out = fixini.stock_text(SAMPLE)
        v = fixini.fix_values(out)
        self.assertEqual(v["BoneUploadStores"], "0")
        self.assertEqual(v["RdgParallelTranslate"], "0")
        self.assertEqual(v["ChaosMaxPayloadSize"], "0")
        self.assertEqual(v["FrameRateLimitAtStart"], "1")
        self.assertIn("RdgParallelTranslate = 0   ; automatic\r\n", out)     # comment and CRLF kept
        self.assertIn("LogFile=1\r\nStatsIntervalSeconds=60", out)           # other sections untouched
        self.assertEqual(out.count("\r\n"), SAMPLE.count("\r\n"))

    def test_stock_of_shipped_ini(self):
        text = (REPO / "src/OblivionPerfFix/OblivionPerfFix.ini").read_text()
        before = fixini.fix_values(text)
        after = fixini.fix_values(fixini.stock_text(text))
        self.assertEqual(set(before), set(after))
        self.assertGreater(len(before), 50)
        for k, v in after.items():
            self.assertEqual(v, before[k] if k in fixini.STOCK_KEEP else "0", k)

    def test_set_values_adds_missing(self):
        out = fixini.set_values("[A]\nx=1\n[B]\ny=2\n", "B", {"y": 3, "z": 4})
        self.assertEqual(out, "[A]\nx=1\n[B]\nz=4\ny=3\n")
        out = fixini.set_values("[A]\nx=1", "C", {"k": "v"})
        self.assertEqual(out, "[A]\nx=1\n\n[C]\nk=v\n")

    def test_no_switches(self):
        with self.assertRaises(ValueError):
            fixini.stock_text("[General]\nLogFile=1\n")


class GuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.ini = self.tmp / "game" / "OblivionPerfFix.ini"
        self.ini.parent.mkdir()
        self.ini.write_bytes(SAMPLE.encode())
        self.guard = fixini.FileGuard(self.tmp / "run")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_stock_then_restore(self):
        original = self.ini.read_bytes()
        keys = fixini.write_stock_ini(self.ini, self.guard)
        self.assertIn("BoneUploadStores", keys)
        self.assertNotIn("FrameRateLimitAtStart", keys)
        self.assertNotEqual(self.ini.read_bytes(), original)
        self.assertTrue(self.guard.has_pending())
        # a second backup of the same file keeps the first (original) copy
        self.guard.backup(self.ini)
        self.assertEqual(self.guard.restore(), [str(self.ini)])
        self.assertEqual(self.ini.read_bytes(), original)
        self.assertFalse(self.guard.has_pending())
        self.assertEqual(self.guard.restore(), [])

    def test_override_then_restore(self):
        original = self.ini.read_bytes()
        fixini.override_ini(self.ini, self.guard, {"BoneUploadStores": "0", "HitchLedger": "1"})
        vals = fixini.fix_values(self.ini.read_bytes().decode())
        self.assertEqual(vals["BoneUploadStores"], "0")
        self.assertEqual(vals["HitchLedger"], "1")          # missing key added under [Fixes]
        self.assertEqual(vals["RdgParallelTranslate"], "2")
        self.assertIn(b"\r\n", self.ini.read_bytes())     # line endings kept
        self.assertIn(b"LogFile=1", self.ini.read_bytes())   # [General] untouched
        self.guard.restore()
        self.assertEqual(self.ini.read_bytes(), original)

    def test_parse_overrides(self):
        self.assertEqual(fixini.parse_overrides(["A=1", "B=0, C=2"]), {"A": "1", "B": "0", "C": "2"})
        self.assertEqual(fixini.parse_overrides(None), {})
        with self.assertRaises(ValueError):
            fixini.parse_overrides(["A"])

    def test_restore_after_crash_new_guard_object(self):
        original = self.ini.read_bytes()
        fixini.write_stock_ini(self.ini, self.guard)
        again = fixini.FileGuard(self.tmp / "run")         # the next run, after this one was killed
        self.assertTrue(again.has_pending())
        again.restore()
        self.assertEqual(self.ini.read_bytes(), original)

    def test_created_file_removed(self):
        new = self.tmp / "game" / "Engine.ini"
        self.guard.backup(new)
        new.write_text("x")
        self.guard.restore()
        self.assertFalse(new.exists())

    def test_bom_kept(self):
        self.ini.write_bytes(b"\xef\xbb\xbf" + SAMPLE.encode())
        fixini.write_stock_ini(self.ini, self.guard)
        self.assertTrue(self.ini.read_bytes().startswith(b"\xef\xbb\xbf"))
        self.assertEqual(fixini.fix_values(self.ini.read_bytes()[3:].decode())["BoneUploadStores"], "0")


if __name__ == "__main__":
    unittest.main()
