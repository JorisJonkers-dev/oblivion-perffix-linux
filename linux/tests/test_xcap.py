import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import xcap  # noqa: E402


class CropTest(unittest.TestCase):
    def test_centre_half(self):
        self.assertEqual(xcap.crop_rect(2560, 1440, 0.5), (640, 360, 1280, 720))

    def test_whole_and_clamped(self):
        self.assertEqual(xcap.crop_rect(2560, 1440, 1.0), (0, 0, 2560, 1440))
        self.assertEqual(xcap.crop_rect(2560, 1440, 7), (0, 0, 2560, 1440))

    def test_downscale_buffer(self):
        w, h = 8, 4
        buf = bytes([0, 100, 0, 0]) * (w * h)                 # green = 100 in byte 1
        f = xcap.downscale_buffer(buf, w, h, w * 4, 1, 4)
        self.assertEqual((f.w, f.h), (4, 2))
        self.assertTrue(all(v == 100 for v in f.pix))


if __name__ == "__main__":
    unittest.main()
