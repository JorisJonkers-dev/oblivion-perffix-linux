import sys
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import diagwin, spin, warmup  # noqa: E402

LEDGER = ("# OblivionPerfFix-ledger v1, OblivionPerfFix 1.2.4, qpc_freq=10000000, pid=1, threshold_ms=25.0\n"
          "#F,frame,end_ms,period_ms,sleep_ms,pre_ms\n#S,frame,end_ms,frames\n")


class DiagRangeTest(unittest.TestCase):
    def test_sync_stalls_cut_from_range(self):
        # wall = end_ms/1000 + 5000: stalls at end_ms 100000 and 400000, scenes measured 130 s .. 370 s after
        rows = [(100000, 360, 351), (131000, 40, 1), (250000, 30, 1), (399000, 45, 1), (400000, 360, 351)]
        text = LEDGER + "".join(f"F,{i},{e},{p},0,{pre}\n" for i, (e, p, pre) in enumerate(rows))
        markers = [(5100.02, 350), (5400.02, 350)]
        r = diagwin.ledger_range(text, markers, [(5130.0, 5200.0), (5210.0, 5399.5)])
        self.assertAlmostEqual(r["offsetS"], 5000.02, delta=0.05)
        self.assertAlmostEqual(r["fromMs"], 130000 - 20, delta=60)      # window starts after the first stall + 1 s
        self.assertLess(r["toMs"], 399500)                               # the last stall (400000) is cut with 1 s margin
        self.assertAlmostEqual(r["toMs"], 399000 - 20, delta=60)
        self.assertEqual(len(r["stallsLedgerMs"]), 2)
        for stall in r["stallsLedgerMs"]:
            self.assertFalse(r["fromMs"] - 1000 < stall < r["toMs"] + 1000 and r["fromMs"] <= stall <= r["toMs"])

    def test_margin_clips_window_touching_a_stall(self):
        rows = [(100000, 360, 351), (400000, 360, 351)]
        text = LEDGER + "".join(f"F,{i},{e},{p},0,{pre}\n" for i, (e, p, pre) in enumerate(rows))
        markers = [(5100.0, 350), (5400.0, 350)]
        r = diagwin.ledger_range(text, markers, [(5100.5, 5399.5)])
        self.assertAlmostEqual(r["fromMs"], (5101.0 - 5000.0) * 1000, delta=10)
        self.assertAlmostEqual(r["toMs"], (5399.0 - 5000.0) * 1000, delta=10)

    def test_unanchored_gives_no_range(self):
        text = LEDGER + "F,0,100000,360,0,351\n"
        r = diagwin.ledger_range(text, [(5100.0, 350)], [(5130.0, 5200.0)])
        self.assertIsNone(r["fromMs"])
        self.assertIn("whole session", r["note"])

    def test_spin_split_excludes_stall_margin(self):
        rows = [(100000, 360, 351), (100500, 30, 1), (103000, 30, 1)]
        text = LEDGER + "".join(f"F,{i},{e},{p},0,{pre}\n" for i, (e, p, pre) in enumerate(rows))
        texts, summ = spin.split_ledger(text, {"a": [(5099.0, 5104.0)]}, 5000.0,
                                        exclude=diagwin.exclusions([(5100.0, 350)]))
        self.assertEqual(summ["a"]["frames"], 1)
        self.assertIn("F,2,103000", texts["a"])
        self.assertNotIn("F,0,", texts["a"])
        self.assertNotIn("F,1,", texts["a"])


def stamp(epoch):
    return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(epoch)) + f".{int(epoch % 1 * 1000):03d}"


def logline(epoch, body):
    return f"{stamp(epoch)} {body}\n"


HOOK = "[pso] SetBatchMode exe+0x2702390 detoured (precompile flag +0x140, batch size/time exe+0x921A238/+0x921A23C): x"
DONE = "[pso] +54.2 s: shader precompile finished (seen from +9.7 s; 10.7 s at the Fast pace, 33.8 s at the game's)"
SUMMARY = "[pso] precompile seen from +9.7 s, finished at +54.2 s; 10.7 s at the Fast pace"


class LogTest(unittest.TestCase):
    def test_done_after_session_start(self):
        t = 1_800_000_000
        text = logline(t, HOOK) + logline(t + 50, DONE) + logline(t + 60, SUMMARY)
        hooked, done, line = warmup.log_state(text, t - 1)
        self.assertTrue(hooked)
        self.assertAlmostEqual(done, t + 50, delta=0.01)
        self.assertIn("shader precompile finished", line)

    def test_summary_line_is_not_done(self):
        t = 1_800_000_000
        hooked, done, _ = warmup.log_state(logline(t, HOOK) + logline(t + 60, SUMMARY), t - 1)
        self.assertTrue(hooked)
        self.assertIsNone(done)

    def test_older_session_ignored(self):
        t = 1_800_000_000
        old = logline(t - 3600, HOOK) + logline(t - 3550, DONE)
        hooked, done, _ = warmup.log_state(old, t)
        self.assertFalse(hooked)
        self.assertIsNone(done)
        hooked, done, _ = warmup.log_state(old + logline(t + 1, HOOK), t)
        self.assertTrue(hooked)
        self.assertIsNone(done)

    def test_wait_ends_when_log_says_done(self):
        t0 = 1_800_000_000
        clock = {"t": t0}
        log = {"text": logline(t0 - 5, HOOK)}

        def wait(sec):
            clock["t"] += sec
            if clock["t"] >= t0 + 33:
                log["text"] = logline(t0 - 5, HOOK) + logline(t0 + 32.5, DONE)
        r = warmup.wait_auto(lambda: log["text"], lambda: None, t0 - 10, wait, now=lambda: clock["t"])
        self.assertEqual(r["method"], "pso log")
        self.assertAlmostEqual(r["seconds"], 33, delta=1.5)
        self.assertIn("precompile finished", r["reason"])

    def test_minimum_holds_when_already_done(self):
        t0 = 1_800_000_000
        clock = {"t": t0}
        text = logline(t0 - 20, HOOK) + logline(t0 - 5, DONE)

        def wait(sec):
            clock["t"] += sec
        r = warmup.wait_auto(lambda: text, lambda: None, t0 - 60, wait, now=lambda: clock["t"])
        self.assertAlmostEqual(r["seconds"], warmup.MIN_S, delta=1.5)

    def test_cap_when_never_done(self):
        t0 = 1_800_000_000
        clock = {"t": t0}

        def wait(sec):
            clock["t"] += sec
        r = warmup.wait_auto(lambda: logline(t0, HOOK), lambda: None, t0 - 1, wait, now=lambda: clock["t"])
        self.assertAlmostEqual(r["seconds"], warmup.CAP_S, delta=1.5)
        self.assertIn("cap", r["reason"])


class FallbackTest(unittest.TestCase):
    def frames(self, secs, spike_until=0.0):
        el = [i * 0.01 for i in range(int(secs * 100))]
        ft = [30.0 if e < spike_until and int(e * 100) % 5 == 0 else 10.0 for e in el]
        return el, ft

    def test_stability(self):
        self.assertTrue(warmup.frames_stable(*self.frames(30)))
        self.assertFalse(warmup.frames_stable(*self.frames(8)))                  # too short
        self.assertFalse(warmup.frames_stable(*self.frames(30, spike_until=25)))  # p95 still high, then drops

    def test_no_hook_uses_frames_then_fixed(self):
        t0 = 1_800_000_000
        for frames, method, want in ((self.frames(40), "frame times", 20), (None, "fixed", warmup.FALLBACK_S)):
            clock = {"t": t0}

            def wait(sec):
                clock["t"] += sec
            r = warmup.wait_auto(lambda: None, lambda: frames, t0 - 1, wait, now=lambda: clock["t"])
            self.assertEqual(r["method"], method)
            self.assertAlmostEqual(r["seconds"], want, delta=1.5)

    def test_numeric_unchanged(self):
        from oblvbench.runner import Options
        o = Options(warmup="45")
        self.assertFalse(o.warmup_auto)
        self.assertEqual(o.warmup, 45.0)
        self.assertEqual(Options(warmup=0).warmup, 0.0)
        self.assertTrue(Options().warmup_auto)
        self.assertEqual(warmup.parse_warmup("AUTO"), "auto")
        with self.assertRaises(ValueError):
            warmup.parse_warmup("-1")


if __name__ == "__main__":
    unittest.main()
