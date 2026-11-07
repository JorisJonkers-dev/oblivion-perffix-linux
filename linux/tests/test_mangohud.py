import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import mangohud  # noqa: E402

HEADER = ("os,cpu,gpu,ram,kernel,driver,cpuscheduler\n"
          "NixOS,AMD Ryzen,AMD Radeon RX 7900 XTX,64GB,7.3.1,Mesa,\n"
          "fps,frametime,cpu_load,cpu_power,gpu_load,cpu_temp,gpu_temp,gpu_core_clock,gpu_mem_clock,gpu_vram_used,"
          "gpu_power,ram_used,swap_used,process_rss,elapsed\n")


def make_csv(frametimes, cpu=50, gpu=90, start_ns=0):
    rows, el = [], start_ns
    for ft in frametimes:
        el += int(ft * 1e6)
        rows.append(f"{1000 / ft:.1f},{ft:.3f},{cpu},0,{gpu},0,0,0,0,0,0,0,0,0,{el}")
    return HEADER + "\n".join(rows) + "\n"


class ParseTest(unittest.TestCase):
    def test_parse(self):
        log = mangohud.parse_text(make_csv([10, 20, 30]))
        self.assertEqual(len(log), 3)
        self.assertEqual(log.frametime, [10, 20, 30])
        self.assertAlmostEqual(log.elapsed[-1], 0.060)
        self.assertEqual(log.cpu_load[0], 50)

    def test_skips_bad_rows(self):
        text = make_csv([10, 10]) + "garbage\n1,,2\n100,0,1,1,1,1,1,1,1,1,1,1,1,1,999\n"
        self.assertEqual(len(mangohud.parse_text(text)), 2)

    def test_no_header(self):
        with self.assertRaises(ValueError):
            mangohud.parse_text("a,b\n1,2\n")

    def test_name_time(self):
        t = mangohud.name_time("OblivionRemastered-Win64-Shipping_2026-11-07_14-03-22.csv")
        self.assertEqual(time.localtime(t)[:6], (2026, 11, 7, 14, 3, 22))
        self.assertIsNone(mangohud.name_time("x.csv"))

    def test_find_and_pick_logs(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / "OblivionRemastered-Win64-Shipping_2026-11-07_14-03-22.csv").write_text(make_csv([10] * 100))
            (d / "OblivionRemastered-Win64-Shipping_2026-11-07_14-03-22_summary.csv").write_text("x")
            (d / "steam_2026-11-07_14-03-20.csv").write_text(make_csv([10] * 500))
            (d / "notes.csv").write_text("x")
            logs = mangohud.find_logs(d)
            self.assertEqual(len(logs), 2)
            self.assertIn("OblivionRemastered", mangohud.pick_log(logs).name)
            since = mangohud.name_time(logs[-1]) + 10
            self.assertEqual(mangohud.find_logs(d, since=since), [])


class TimingTest(unittest.TestCase):
    def test_estimate_from_name(self):
        self.assertEqual(mangohud.estimate_start(1000.0), (1000.5, 0.5))

    def test_estimate_capped_by_first_sighting(self):
        start, err = mangohud.estimate_start(1000.0, first_seen=1000.3)
        self.assertAlmostEqual(start, 1000.15)
        self.assertAlmostEqual(err, 0.15)
        # a file seen long after (written at the end) does not count
        self.assertEqual(mangohud.estimate_start(1000.0, first_seen=1100.0), (1000.5, 0.5))

    def test_sync_marker(self):
        # 10 s at 10 ms, one 350 ms stall ending at elapsed 5.35 s; true start 1000.7, guess 1000.5
        fts = [10] * 500 + [350] + [10] * 500
        log = mangohud.parse_text(make_csv(fts))
        true_start = 1000.7
        stall_end = true_start + log.elapsed[500]
        start, detail = mangohud.find_sync(log, 1000.5, [(stall_end + 0.02, 350)])
        self.assertAlmostEqual(start, true_start + 0.02, places=3)
        self.assertEqual(detail[0]["frameMs"], 350)
        # no long frame near the marker
        none, detail = mangohud.find_sync(log, 1000.5, [(1020.0, 350)])
        self.assertIsNone(none)
        self.assertIsNone(detail[0]["frameMs"])


class StatsTest(unittest.TestCase):
    def test_window_and_stats(self):
        # 1000 frames: 990 x 10 ms, 9 x 25 ms, 1 x 100 ms (a hitch: > max(2 x 10, 40))
        fts = [10] * 500 + [25] * 9 + [100] + [10] * 490
        log = mangohud.parse_text(make_csv(fts, cpu=40, gpu=80))
        start = 5000.0
        s = mangohud.stats(log, start, start, start + 100)
        self.assertEqual(s["frames"], 1000)
        avg = sum(fts) / len(fts)
        self.assertAlmostEqual(s["fps"], round(1000 / avg, 1))
        self.assertEqual(s["p50Ms"], 10)
        self.assertEqual(s["p99Ms"], 25)            # sorted[990]
        self.assertEqual(s["p999Ms"], 100)          # sorted[999]
        self.assertEqual(s["low1"], 40.0)
        self.assertEqual(s["low01"], 10.0)
        self.assertEqual(s["worstMs"], 100)
        self.assertEqual(s["hitches"], 1)
        self.assertEqual(s["hitchMs"], 90)
        self.assertEqual(s["over50"], 1)
        self.assertEqual((s["cpuLoad"], s["gpuLoad"]), (40, 80))

    def test_slicing(self):
        log = mangohud.parse_text(make_csv([10] * 1000))      # frames end at 0.01 .. 10.00 s
        s = mangohud.stats(log, 100.0, 102.0, 104.0)
        self.assertIn(s["frames"], (200, 201))
        self.assertLess(s["longestGapMs"], 11)
        empty = mangohud.stats(log, 100.0, 200.0, 201.0)
        self.assertEqual(empty["frames"], 0)
        self.assertNotIn("fps", empty)
        self.assertEqual(empty["longestGapMs"], 1000.0)

    def test_hitch_threshold_uses_median(self):
        # at 30 ms median the limit is 60 ms: a 50 ms frame is no hitch, a 70 ms one is
        log = mangohud.parse_text(make_csv([30] * 98 + [50, 70]))
        s = mangohud.stats(log, 0, 0, 10)
        self.assertEqual(s["hitches"], 1)

    def test_config(self):
        c = mangohud.config_text("/tmp/x")
        self.assertIn("output_folder=/tmp/x", c)
        self.assertIn("log_interval=0", c)
        self.assertIn("autostart_log=1", c)
        self.assertIn("no_display", c)
        self.assertNotIn("no_display", mangohud.config_text("/tmp/x", show_hud=True))


if __name__ == "__main__":
    unittest.main()
