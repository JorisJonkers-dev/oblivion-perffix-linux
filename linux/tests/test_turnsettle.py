"""turnsettle.py on synthetic frame series: a detail appearing, a brightness ramp, noise only, masks."""
import random
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import imgcmp, spin, turnsettle  # noqa: E402
from oblvbench.imgcmp import Pic  # noqa: E402

W, H = 80, 45


def pic(base=60, rect=None, val=200, noise=0, rnd=None, bump=None):
    pix = bytearray([base]) * (W * H)
    if rect:
        x0, y0, x1, y1 = rect
        for y in range(y0, y1):
            for x in range(x0, x1):
                pix[y * W + x] = val
    if noise:
        rnd = rnd or random.Random(1)
        for i in range(len(pix)):
            pix[i] = max(0, min(255, pix[i] + rnd.randint(-noise, noise)))
    return Pic(W, H, bytes(pix))


def series(fn, dt=0.1, secs=3.0):
    k = int(round(secs / dt)) + 1
    return [(round(i * dt, 3), fn(i * dt)) for i in range(k)]


class AnalyseTest(unittest.TestCase):
    def test_object_appears(self):
        rnd = random.Random(3)
        r = turnsettle.analyse_turn(series(lambda t: pic(rect=(10, 10, 40, 30) if t >= 0.7 else None, noise=2, rnd=rnd)))
        self.assertAlmostEqual(r["settleS"], 0.7, delta=0.11)
        self.assertEqual(r["pops"], 1)
        self.assertGreater(r["auc"], 5)
        self.assertEqual(r["frames"], 31)

    def test_noise_only(self):
        rnd = random.Random(5)
        r = turnsettle.analyse_turn(series(lambda t: pic(noise=2, rnd=rnd)))
        self.assertEqual(r["settleS"], 0.0)
        self.assertEqual(r["pops"], 0)
        self.assertLess(r["auc"], 0.2)

    def test_brightness_ramp(self):
        r = turnsettle.analyse_turn(series(lambda t: pic(base=int(40 + 60 * min(t, 1.0) / 1.0))))
        self.assertAlmostEqual(r["lumaSettleS"], 1.0, delta=0.15)
        self.assertGreater(r["settleS"], 0.6)
        self.assertLess(r["settleS"], 1.1)
        self.assertEqual(r["luma"][0], 40.0)
        self.assertAlmostEqual(r["lumaDelta"], 60.0, delta=0.5)
        self.assertGreater(r["auc"], 5)

    def test_several_pops_counted(self):
        def f(t):
            n = sum(1 for a in (0.5, 1.0, 1.5) if t >= a)
            return pic(rect=(0, 0, 12 * n, 20) if n else None)
        r = turnsettle.analyse_turn(series(f))
        self.assertEqual(r["pops"], 3)
        self.assertAlmostEqual(r["settleS"], 1.5, delta=0.11)

    def test_change_before_popfrom_is_not_a_pop(self):
        r = turnsettle.analyse_turn(series(lambda t: pic(rect=(0, 0, 40, 30) if t >= 0.1 else None)))
        self.assertEqual(r["pops"], 0)
        self.assertAlmostEqual(r["settleS"], 0.1, delta=0.01)

    def test_mask_hides_hud_changes(self):
        mask = (0.0, 0.0, 0.5, 0.5)               # top left quarter
        f = lambda t: pic(rect=(0, 0, 30, 15) if t < 1.0 else None)       # the 'fps counter' changes
        masked = turnsettle.analyse_turn(series(f), [mask])
        self.assertEqual(masked["settleS"], 0.0)
        self.assertEqual(masked["pops"], 0)
        self.assertGreater(turnsettle.analyse_turn(series(f))["settleS"], 0.5)

    def test_too_few_frames(self):
        self.assertIn("error", turnsettle.analyse_turn(series(lambda t: pic(), dt=1.0, secs=2.0)))

    def test_strip(self):
        fr = series(lambda t: pic(base=int(50 + t * 10)))
        idx = turnsettle.strip_indices([t for t, _ in fr])
        self.assertEqual([round(fr[i][0], 1) for i in idx], [0.0, 0.2, 0.5, 1.0, 2.0, 3.0])
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "a" / "b.png"
            turnsettle.write_strip(p, fr)
            g = imgcmp.read_gray_png(p)
            self.assertEqual((g.w, g.h), (6 * W + 5 * 4, H))

    def test_from_heading(self):
        self.assertEqual(turnsettle.from_heading(0, "back"), 180.0)
        self.assertEqual(turnsettle.from_heading(0, "side"), 270.0)
        self.assertEqual(turnsettle.from_heading(270, "back"), 90.0)


class SplitTest(unittest.TestCase):
    """Lighting (low-pass) and pop-in (edges) settle times are separate."""

    def textured(self, base, rect=None, val=None):
        pix = bytearray(W * H)
        for y in range(H):
            for x in range(W):
                pix[y * W + x] = base + (40 if (x // 4 + y // 4) % 2 else 0)
        if rect:
            for y in range(rect[1], rect[3]):
                for x in range(rect[0], rect[2]):
                    pix[y * W + x] = val
        return Pic(W, H, bytes(pix))

    def test_lighting_only(self):
        # same texture, global brightness fills in until 1.2 s: no edges are missing
        r = turnsettle.analyse_turn(series(lambda t: self.textured(40 + (60 if t >= 1.2 else 0))))
        self.assertAlmostEqual(r["lightSettleS"], 1.2, delta=0.11)
        self.assertEqual(r["popSettleS"], 0.0)
        self.assertEqual(r["blobsFirst"], 0)
        self.assertIn(r["lumaKind"], ("monotone", "stepwise", "exponential"))

    def test_popin_only(self):
        # a high contrast object appears at 0.9 s in a flat area: edge regions missing before
        def f(t):
            return pic(rect=(30, 10, 38, 34), val=250) if t >= 0.9 else pic()
        r = turnsettle.analyse_turn(series(f))
        self.assertAlmostEqual(r["popSettleS"], 0.9, delta=0.11)
        self.assertGreaterEqual(r["blobsFirst"], 1)

    def test_luma_exponential_and_stepwise(self):
        import math
        r = turnsettle.analyse_turn(series(lambda t: pic(base=int(round(100 - 60 * math.exp(-t / 0.6)))), dt=0.1, secs=4.0))
        self.assertEqual(r["lumaKind"], "exponential")
        self.assertAlmostEqual(r["lumaTauS"], 0.6, delta=0.2)
        r = turnsettle.analyse_turn(series(lambda t: pic(base=40 + 15 * sum(1 for a in (0.5, 1.0, 1.5) if t >= a))))
        self.assertEqual(r["lumaKind"], "stepwise")
        r = turnsettle.analyse_turn(series(lambda t: pic(base=70)))
        self.assertEqual(r["lumaKind"], "flat")
        ov = lambda t: 20 + 80 * t if t < 1 else (100 - 40 * (t - 1) if t < 2 else 60)       # overshoot, then back
        r = turnsettle.analyse_turn(series(lambda t: pic(base=int(ov(t)))))
        self.assertEqual(r["lumaKind"], "non-monotone")
        self.assertIn(r["lumaKind"], ("non-monotone", "monotone"))


class SummariseTest(unittest.TestCase):
    def turns(self, settles):
        return [{"settleS": s, "auc": s * 10, "pops": 1, "lumaSettleS": s, "lumaDelta": 1.0, "noiseMad": 0.5,
                 "noiseBig": 0.0, "lightSettleS": s, "popSettleS": s,
                 "blobsFirst": 2, "lumaKind": "exponential", "lumaTauS": 0.5, "noiseLow": 0.1, "noiseEdge": 0.1} for s in settles]

    def test_median_delta_and_quiet(self):
        slots = [{"variant": "base", "turns": self.turns([1.0, 1.2])}, {"variant": "base", "turns": self.turns([1.1, 1.3])},
                 {"variant": "v", "turns": self.turns([0.4, 0.5])}, {"variant": "v", "turns": self.turns([0.5, 0.6]) + [{"error": "x"}]}]
        r = turnsettle.summarise(slots, spin.parse_variants(["v:cvar:r.A=1"]), 0.1)
        base, v = r["variants"]
        self.assertAlmostEqual(base["settleS"], 1.15)
        self.assertAlmostEqual(v["settleS"], 0.5)
        self.assertEqual(v["failed"], 1)
        self.assertAlmostEqual(v["delta"]["settleS"], -0.65)
        self.assertFalse(v["quiet"]["settleS"])
        md = "\n".join(turnsettle.report_lines(r, {"turns": 2, "headings": [0, 90], "hold": 4, "from": "back", "interval": 0.1,
                                                   "secs": 3, "achievedInterval": 0.11, "grabMs": 40}))
        self.assertIn("| v | 4 (1 failed) |", md)
        self.assertIn("(-0.65)", md)


if __name__ == "__main__":
    unittest.main()
