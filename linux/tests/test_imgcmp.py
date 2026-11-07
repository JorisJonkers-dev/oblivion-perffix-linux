"""PNG round trip, SSIM / PSNR properties, masks, side-by-side pictures, the gallery and the GAIN/COST verdicts."""
import random
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import imgcmp, spin, spinshots  # noqa: E402

W, H = 96, 64


def scene(seed=1):
    rnd = random.Random(seed)
    pix = bytes(max(0, min(255, int(100 + 60 * ((x // 8 + y // 8) % 2) + x + rnd.randint(-3, 3)))) for y in range(H) for x in range(W))
    return imgcmp.Pic(W, H, pix)


def noisy(p, amp, seed=2):
    rnd = random.Random(seed)
    return imgcmp.Pic(p.w, p.h, bytes(max(0, min(255, v + rnd.randint(-amp, amp))) for v in p.pix))


class PngTest(unittest.TestCase):
    def test_roundtrip_gray_and_rgb(self):
        p = scene()
        w, h, ch, pix = imgcmp.decode_png(imgcmp.encode_png(p.w, p.h, p.pix))
        self.assertEqual((w, h, ch, pix), (W, H, 1, p.pix))
        rgb = bytes(range(256)) * 3
        w, h, ch, pix = imgcmp.decode_png(imgcmp.encode_png(16, 16, rgb, 3))
        self.assertEqual((w, h, ch, pix), (16, 16, 3, rgb))

    def test_valid_png_structure(self):
        data = imgcmp.encode_png(4, 2, bytes(range(8)))
        self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
        self.assertEqual(data[12:16], b"IHDR")
        self.assertEqual(data[-12:-8], b"\x00\x00\x00\x00")
        self.assertEqual(data[-8:-4], b"IEND")
        idat = data[data.index(b"IDAT") + 4:data.index(b"IEND") - 8]
        self.assertEqual(len(zlib.decompress(idat)), 2 * (4 + 1))

    def test_other_filters_and_bad_input(self):
        # a hand-made PNG with Sub / Up / Average / Paeth rows
        rows = [bytes([10, 20, 30, 40]), bytes([11, 22, 33, 44]), bytes([5, 6, 7, 8]), bytes([50, 40, 30, 20])]
        raw = bytearray()
        prev = bytes(4)
        for ft, row in enumerate(rows, 1):
            raw.append(ft)
            for i, v in enumerate(row):
                a = row[i - 1] if i else 0
                b = prev[i]
                c = prev[i - 1] if i else 0
                if ft == 1:
                    p = a
                elif ft == 2:
                    p = b
                elif ft == 3:
                    p = (a + b) >> 1
                else:
                    pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                    p = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                raw.append((v - p) & 255)
            prev = row
        import struct
        ch = imgcmp._chunk
        data = (imgcmp.PNG_SIG + ch(b"IHDR", struct.pack(">IIBBBBB", 4, 4, 8, 0, 0, 0, 0))
                + ch(b"IDAT", zlib.compress(bytes(raw))) + ch(b"IEND", b""))
        self.assertEqual(imgcmp.decode_png(data)[3], b"".join(rows))
        with self.assertRaises(imgcmp.ImageError):
            imgcmp.decode_png(b"nope")
        bad = bytearray(imgcmp.encode_png(4, 2, bytes(8)))
        bad[20] ^= 1
        with self.assertRaises(imgcmp.ImageError):
            imgcmp.decode_png(bytes(bad))


class MetricTest(unittest.TestCase):
    def test_identical_is_one(self):
        p = scene()
        r = imgcmp.compare(p, p)
        self.assertEqual(r["ssim"], 1.0)
        self.assertEqual(r["psnr"], 99.0)
        self.assertEqual(r["bigPct"], 0.0)

    def test_noise_lowers_ssim_monotonically(self):
        p = scene()
        a, b = imgcmp.ssim(p, noisy(p, 8)), imgcmp.ssim(p, noisy(p, 40))
        self.assertLess(a, 0.99)
        self.assertLess(b, a)
        self.assertLess(imgcmp.compare(p, noisy(p, 40))["psnr"], imgcmp.compare(p, noisy(p, 8))["psnr"])
        self.assertGreater(imgcmp.compare(p, noisy(p, 80))["bigPct"], 5)

    def test_brightness_shift_is_mild_and_reported(self):
        p = scene()
        q = imgcmp.Pic(W, H, bytes(min(255, v + 12) for v in p.pix))
        r = imgcmp.compare(p, q)
        self.assertGreater(r["ssim"], 0.97)                        # the luminance term barely cares about a small gain
        self.assertLess(r["ssim"], 1.0)
        self.assertAlmostEqual(r["dLuma"], 12, delta=1.5)
        self.assertGreater(imgcmp.ssim(p, noisy(p, 40)), 0) 
        self.assertLess(imgcmp.ssim(p, noisy(p, 40)), r["ssim"])   # noise hurts more than a brightness offset

    def test_masked_region_is_ignored(self):
        p = scene()
        pix = bytearray(p.pix)
        for y in range(0, 16):                                      # wreck the top-left quarter-ish
            for x in range(0, 24):
                pix[y * W + x] = 255 - pix[y * W + x]
        q = imgcmp.Pic(W, H, bytes(pix))
        self.assertLess(imgcmp.ssim(p, q), 0.99)
        mask = [(0.0, 0.0, 0.3, 0.3)]                               # covers x < 29, y < 20
        self.assertEqual(imgcmp.ssim(p, q, mask), 1.0)
        st = imgcmp.diff_stats(p, q, mask)
        self.assertEqual(st["bigPct"], 0.0)
        self.assertGreater(imgcmp.diff_stats(p, q)["bigPct"], 1)
        self.assertIsNone(imgcmp.ssim(p, q, [(0, 0, 1, 1)]))

    def test_size_mismatch(self):
        with self.assertRaises(imgcmp.ImageError):
            imgcmp.ssim(scene(), imgcmp.Pic(32, 32, bytes(1024)))

    def test_side_by_side_and_median(self):
        p, q = scene(), noisy(scene(), 30)
        w, h, rgb = imgcmp.side_by_side(p, q, [(0, 0, 0.2, 0.2)], gain=4, gap=4)
        self.assertEqual((w, h, len(rgb)), (W * 3 + 8, H, (W * 3 + 8) * H * 3))
        ident = imgcmp.side_by_side(p, p)[2]
        x0 = (W + 4 + W + 4) * 3 + 3 * 40                           # heat map of identical pictures is black
        self.assertEqual(ident[x0:x0 + 3], b"\0\0\0")
        m = imgcmp.median_pic([imgcmp.Pic(2, 1, bytes([1, 9])), imgcmp.Pic(2, 1, bytes([5, 5])), imgcmp.Pic(2, 1, bytes([9, 1]))])
        self.assertEqual(m.pix, bytes([5, 5]))


class GalleryTest(unittest.TestCase):
    def make_run(self, lod_amp):
        d = Path(tempfile.mkdtemp())
        slots = []
        base = scene()
        for i, (name, amp) in enumerate([("base", 2), ("lod", lod_amp), ("lod", lod_amp), ("base", 3)], 1):
            shots = {}
            for h in (0, 90):
                p = noisy(base, amp, seed=i * 10 + h) if amp else base
                rel = spinshots.shot_rel(name, i, h)
                (d / rel).parent.mkdir(parents=True, exist_ok=True)
                imgcmp.write_png(d / rel, p.w, p.h, p.pix)
                shots[spinshots.heading_name(h)] = rel
            slots.append({"variant": name, "shots": shots})
        return d, slots

    def test_gallery_and_noise_floor(self):
        d, slots = self.make_run(30)
        variants = spin.parse_variants(["lod:cvar:r.A=1"])
        im = spinshots.analyse(d, slots, variants, [], [0, 90], pairs=1)
        self.assertEqual(im["headings"], ["000", "090"])
        lod = im["variants"]["lod"]
        self.assertLess(lod["ssim"], im["variants"]["base"]["noiseFloor"])
        self.assertGreater(lod["drop"], 0.01)
        self.assertEqual(lod["worst"] in ("000", "090"), True)
        for hn in ("000", "090"):
            self.assertTrue((d / "shots/sbs/lod" / f"{hn}.png").exists())
        md = (d / "images.md").read_text()
        self.assertIn("![lod 000](shots/sbs/lod/000.png)", md)
        self.assertIn("Noise floor", md)
        w, h, ch, _ = imgcmp.decode_png((d / "shots/sbs/lod/000.png").read_bytes())
        self.assertEqual((w, ch), (W * 3 + 8, 3))

    def test_headings(self):
        self.assertEqual(spinshots.parse_headings("0, 45,359.5"), [0.0, 45.0, 359.5])
        self.assertEqual(spinshots.heading_name(45), "045")
        self.assertEqual(spinshots.heading_name(112.5), "112_5")
        with self.assertRaises(ValueError):
            spinshots.parse_headings("0,x")
        with self.assertRaises(ValueError):
            spinshots.parse_headings("90,450")


class VerdictTest(unittest.TestCase):
    def row(self, fps=0.0, low1=0.0, hitches=None, drop=0.005, spread=1.0):
        return {"name": "v", "deltaPct": {"fps": fps, "low1": low1, "low01": 0.0}, "spreadPct": spread,
                "hitches": hitches, "ssim": {"ssim": 0.98, "noiseFloor": 0.985, "drop": drop}}

    base = {"spreadPct": 1.0, "hitches": 10}

    def test_codes(self):
        self.assertEqual(spin.verdict(self.row(fps=8), self.base)[0], "ACCEPT")
        self.assertEqual(spin.verdict(self.row(fps=8, drop=0.04), self.base)[0], "TRADE-OFF")
        self.assertEqual(spin.verdict(self.row(fps=2, drop=0.04), self.base)[0], "REJECT")
        self.assertEqual(spin.verdict(self.row(fps=2), self.base)[0], "NEUTRAL")

    def test_lows_hitches_spread_and_thresholds(self):
        self.assertEqual(spin.verdict(self.row(low1=15), self.base)[0], "ACCEPT")
        self.assertEqual(spin.verdict(self.row(hitches=5), self.base)[0], "ACCEPT")
        self.assertEqual(spin.verdict(self.row(hitches=9), self.base)[0], "NEUTRAL")
        self.assertEqual(spin.verdict(self.row(fps=8, spread=12), self.base)[0], "NEUTRAL")      # inside the spread
        self.assertEqual(spin.verdict(self.row(fps=8), self.base, {"gainFpsPct": 10})[0], "NEUTRAL")
        self.assertEqual(spin.verdict(self.row(fps=8, drop=0.04), self.base, {"ssimMaxDrop": 0.05})[0], "ACCEPT")

    def test_no_images(self):
        r = self.row(fps=8)
        r["ssim"] = None
        self.assertEqual(spin.verdict(r, self.base)[0], "NO-IMAGES")


if __name__ == "__main__":
    unittest.main()
