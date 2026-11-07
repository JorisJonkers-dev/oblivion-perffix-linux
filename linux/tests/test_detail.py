import random
import struct
import sys
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import detail  # noqa: E402


def make_xwd(w, h, pixel, byte_order=0, name=b"Oblivion Remastered\0", ncolors=0):
    """A 32 bpp ZPixmap XWD (little endian pixel words, BGRX in memory); pixel(x, y) -> (r, g, b)."""
    hsize = 100 + len(name)
    hdr = struct.pack(">25I", hsize, 7, 2, 24, w, h, 0, byte_order, 32, byte_order, 32, 32, w * 4, 4,
                      0xFF0000, 0xFF00, 0xFF, 8, 256, ncolors, w, h, 0, 0, 0)
    rows = []
    for y in range(h):
        row = bytearray(w * 4)
        for x in range(w):
            r, g, b = pixel(x, y)
            if byte_order == 0:
                row[x * 4:x * 4 + 4] = bytes((b, g, r, 0))
            else:
                row[x * 4:x * 4 + 4] = bytes((0, r, g, b))
        rows.append(bytes(row))
    return hdr + name + b"\0" * (12 * ncolors) + b"".join(rows)


def noise_image(w, h, seed=1):
    rnd = random.Random(seed)
    return [[rnd.randrange(40, 215) for _ in range(w)] for _ in range(h)]


def blur(img, passes):
    for _ in range(passes):
        h, w = len(img), len(img[0])
        img = [[(img[y][x] + img[y][min(w - 1, x + 1)] + img[y][max(0, x - 1)] + img[min(h - 1, y + 1)][x]
                 + img[max(0, y - 1)][x]) // 5 for x in range(w)] for y in range(h)]
    return img


def frame_of(img):
    return detail.Frame(len(img[0]), len(img), bytes(v for row in img for v in row))


class XwdTest(unittest.TestCase):
    def test_parse_downscales_and_reads_green(self):
        data = make_xwd(64, 32, lambda x, y: (255, 10 + x, 0))
        f = detail.parse_xwd(data, target_w=16)               # factor 4
        self.assertEqual((f.w, f.h), (16, 8))
        self.assertEqual(f.pix[0], 10 + 1)                    # mean of green 10..13 = 11.5 -> 11
        self.assertEqual(f.pix[15], 10 + 61)                  # 70..73 -> 71.5 -> 71

    def test_row_average_block(self):
        data = make_xwd(8, 8, lambda x, y: (0, 0 if y % 2 else 100, 0))
        f = detail.parse_xwd(data, target_w=4)
        self.assertEqual(set(f.pix), {50})

    def test_msb_first_and_colormap(self):
        data = make_xwd(8, 8, lambda x, y: (1, 77, 3), byte_order=1, ncolors=3)
        f = detail.parse_xwd(data, target_w=8)
        self.assertEqual(set(f.pix), {77})

    def test_bad_input(self):
        with self.assertRaises(detail.CaptureError):
            detail.parse_xwd(b"short")
        data = make_xwd(8, 8, lambda x, y: (0, 0, 0))
        with self.assertRaises(detail.CaptureError):
            detail.parse_xwd(data[:-10])

    def test_full_frame_under_150ms(self):
        data = make_xwd(2560, 1440, lambda x, y: (0, 0, 0))     # slow to build, only the parse is timed
        best = 1e9
        for _ in range(3):
            t = time.perf_counter()
            f = detail.parse_xwd(data)
            best = min(best, time.perf_counter() - t)
        self.assertEqual((f.w, f.h), (640, 360))
        print(f"\n  parse 2560x1440: {best * 1000:.0f} ms")
        self.assertLess(best, 0.150)

    def test_capturer_uses_tools(self):
        data = make_xwd(16, 16, lambda x, y: (0, 90, 0))
        calls = []

        class R:
            def __init__(s, out, rc=0):
                s.stdout, s.returncode, s.stderr = out, rc, b""

        def run(cmd, **kw):
            calls.append(cmd)
            return R("111 222\n") if "search" in cmd else R(data)

        c = detail.Capturer(run=run)
        c.xdotool, c.xwd = "/x/xdotool", "/x/xwd"
        f = c.grab()
        self.assertEqual(f.pix[0], 90)
        self.assertEqual(calls[0], ["/x/xdotool", "search", "--name", "Oblivion Remastered"])
        self.assertEqual(calls[1], ["/x/xwd", "-id", "222", "-silent"])


class SharpnessTest(unittest.TestCase):
    def test_blur_lowers_sharpness(self):
        img = noise_image(160, 90)
        s0 = detail.sharpness(frame_of(img))
        s1 = detail.sharpness(frame_of(blur(img, 1)))
        s3 = detail.sharpness(frame_of(blur(img, 3)))
        self.assertGreater(s0, s1 * 2)
        self.assertGreater(s1, s3 * 1.5)

    def test_flat_is_zero_and_speed(self):
        f = detail.Frame(640, 360, bytes([100]) * (640 * 360))
        t = time.perf_counter()
        self.assertEqual(detail.sharpness(f), 0)
        dt = time.perf_counter() - t
        print(f"\n  sharpness 640x360: {dt * 1000:.0f} ms")
        self.assertLess(dt, 0.4)

    def test_masks(self):
        img = [[100] * 160 for _ in range(90)]
        for y in range(10, 30):                              # busy patch in the top right (HUD)
            for x in range(110, 150):
                img[y][x] = 0 if (x + y) % 2 else 255
        f = frame_of(img)
        self.assertGreater(detail.sharpness(f), 100)
        self.assertEqual(detail.sharpness(f, [[0.65, 0.05, 0.35, 0.4]]), 0)

    def test_overlay_mask_top_left(self):
        img = [[100] * 160 for _ in range(90)]
        for y in range(10, 13):
            for x in range(17, 35):
                img[y][x] = 0 if (x + y) % 2 else 255
        self.assertEqual(detail.sharpness(frame_of(img)), 0)

    def test_everything_masked(self):
        f = frame_of(noise_image(160, 90))
        self.assertIsNone(detail.sharpness(f, [[0, 0, 1, 1]]))


def series_of(fn, secs=12.0, step=0.5, mean=lambda t: 120.0):
    out, t = [], 0.0
    while t <= secs + 1e-9:
        out.append((t, fn(t), mean(t)))
        t += step
    return out


class AnalyseTest(unittest.TestCase):
    def test_settle_and_ratios(self):
        # blurry until 3 s, then ramps to sharp at 5 s
        def sharp(t):
            return 20 if t < 3 else (20 + 80 * (t - 3) / 2 if t < 5 else 100)
        a = detail.analyse(series_of(sharp))
        self.assertAlmostEqual(a["detailSettleS"], 4.5, delta=0.5)   # 97 % of final reached at 4.95 -> 5.0
        self.assertEqual(a["detailAt1s"], 0.2)
        self.assertEqual(a["detailAt2s"], 0.2)
        self.assertEqual(a["detailAt4s"], 0.6)
        self.assertEqual(a["detailFinal"], 100)

    def test_faster_detail_settles_sooner(self):
        slow = detail.analyse(series_of(lambda t: 100 if t >= 8 else 30))
        fast = detail.analyse(series_of(lambda t: 100 if t >= 2 else 30))
        self.assertLess(fast["detailSettleS"], slow["detailSettleS"])
        self.assertEqual(fast["detailSettleS"], 2.0)
        self.assertEqual(slow["detailSettleS"], 8.0)

    def test_blur_raises_settle_time(self):
        img = noise_image(160, 90, 5)
        levels = [frame_of(blur(img, n)) for n in (6, 3, 1, 0)]
        sharp = [detail.sharpness(f) for f in levels]
        def at(t):
            return sharp[0] if t < 2 else sharp[1] if t < 4 else sharp[2] if t < 6 else sharp[3]
        late = detail.analyse(series_of(at))
        early = detail.analyse(series_of(lambda t: sharp[3] if t >= 1 else sharp[0]))
        self.assertLess(early["detailSettleS"], late["detailSettleS"])

    def test_within_tolerance_noise_counts_as_settled(self):
        a = detail.analyse(series_of(lambda t: 100 + (1 if int(t * 2) % 2 else -1) if t >= 3 else 10))
        self.assertEqual(a["detailSettleS"], 3.0)

    def test_fade_in_is_taken_off(self):
        # black for 2 s (sharpness 0), sharp from the end of the fade; the mean rises 0 -> 120 over 1 s
        mean = lambda t: 0.0 if t < 2 else min(120.0, 120 * (t - 2))
        a = detail.analyse(series_of(lambda t: 0 if t < 2.5 else 100, mean=mean))
        self.assertEqual(a["detailFadeS"], 3.0)      # 108 of 120 reached at 2.9 s
        self.assertEqual(a["detailSettleS"], 0.0)
        self.assertEqual(a["detailAt1s"], 1.0)

    def test_black_and_short(self):
        self.assertTrue(detail.analyse(series_of(lambda t: 0, mean=lambda t: 0.0))["detailBlack"])
        self.assertNotIn("detailSettleS", detail.analyse([(0, 5, 100)]))
        self.assertEqual(detail.analyse([])["detailSamples"], 0)


if __name__ == "__main__":
    unittest.main()
