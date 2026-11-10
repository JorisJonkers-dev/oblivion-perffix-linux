"""Seeded random spots: determinism, filters, dedupe, scenario validity, identical spots on both ab sides."""
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import bench  # noqa: E402
from oblvbench import randspots, scenario  # noqa: E402


def write(d, name, places, scenes, weathers=None):
    (Path(d) / f"{name}.json").write_text(json.dumps({
        "defaults": {"settle": 3, "measure": 5}, "weathers": weathers or {"Clear": "1", "Rain": "2", "SEFog": "3"},
        "places": places, "scenes": scenes}))


class PoolTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        write(self.tmp, "a", {
            "p1": {"world": "Tamriel", "pos": [0, 0, 0], "heading": 1},
            "p1near": {"world": "Tamriel", "pos": [100, 100, 0], "heading": 2},
            "p1otherworld": {"world": "SEWorld", "pos": [0, 0, 0], "heading": 3},
            "inn": {"cell": "SomeInn", "pos": [0, 0, 0], "heading": 4},
            "wet": {"world": "Tamriel", "pos": [9000, 0, 0], "heading": 5, "unsafe": True},
            "air": {"world": "Tamriel", "pos": [9000, 9000, 0], "heading": 5, "hover": True},
            "noheading": {"world": "Tamriel", "pos": [5000, 5000, 0]},
            "far": {"world": "Tamriel", "pos": [50000, 0, 0], "heading": 6},
        }, [
            {"id": "s1", "type": "static", "at": "p1", "tags": ["city"]},
            {"id": "s2", "type": "static", "at": "p1near", "tags": ["outdoor"]},
            {"id": "s3", "type": "static", "at": "far", "tags": ["outdoor", "water"]},
            {"id": "f", "type": "fly", "path": [[0, 0, 0], [1, 1, 1]], "tags": ["flyonly"]},
        ])
        self.pool = randspots.build_pool(self.tmp)

    def ids(self, pool):
        return sorted(e["place"] for e in pool)

    def test_dedupe_merges_tags_and_keeps_other_worlds(self):
        self.assertEqual(self.ids(self.pool), ["far", "inn", "p1", "p1otherworld"])
        p1 = next(e for e in self.pool if e["place"] == "p1")
        self.assertTrue({"city", "outdoor"} <= set(p1["tags"]))

    def test_unsafe_hover_and_headingless_excluded(self):
        self.assertFalse({"wet", "air", "noheading"} & set(self.ids(self.pool)))

    def test_filters(self):
        self.assertEqual(self.ids(randspots.filter_pool(self.pool, "outdoor")), ["far", "p1"])
        self.assertEqual(self.ids(randspots.filter_pool(self.pool, ["city,water"])), ["far", "p1"])
        self.assertEqual(self.ids(randspots.filter_pool(self.pool, worlds="Interior")), ["inn"])
        self.assertEqual(self.ids(randspots.filter_pool(self.pool, worlds="shiveringisles")), ["p1otherworld"])
        self.assertEqual(self.ids(randspots.filter_pool(self.pool, "outdoor", "Tamriel")), ["far", "p1"])
        self.assertEqual(randspots.filter_pool(self.pool, "nosuchtag"), [])
        with self.assertRaises(ValueError):
            randspots.draw_spots(self.pool, 2, 1, tags="nosuchtag")

    def test_weather_any_respects_world(self):
        for seed in range(20):
            for s in randspots.draw_spots(self.pool, 4, seed, weather="any"):
                self.assertEqual(s["weather"].startswith("SE"), s["group"] == "ShiveringIsles")


class DrawTest(unittest.TestCase):
    def test_deterministic_and_seeds_differ(self):
        pool = randspots.build_pool()
        a = randspots.draw_spots(pool, 8, 1)
        b = randspots.draw_spots(pool, 8, 1)
        key = lambda s: [(x["id"], x["hour"], x["weather"]) for x in s]  # noqa: E731
        self.assertEqual(key(a), key(b))
        self.assertEqual(len({x["id"] for x in a}), 8)
        self.assertNotEqual(key(a), key(randspots.draw_spots(pool, 8, 2)))

    def test_hours_and_default_weather(self):
        pool = randspots.build_pool()
        day = randspots.draw_spots(pool, 30, 3)
        self.assertTrue(all(7 <= s["hour"] <= 17 and s["weather"] == "Clear" for s in day))
        anyh = randspots.draw_spots(pool, 30, 3, hours="any")
        self.assertTrue(any(s["hour"] < 7 or s["hour"] > 17 for s in anyh))

    def test_scenario_loads_through_normal_loader(self):
        base = scenario.load_scenario("cheydinhal")
        spots = randspots.draw_spots(randspots.build_pool(), 6, 5, weather="any", hours="any")
        scn = randspots.build_scenario(spots, base, 5)
        tmp = Path(tempfile.mkdtemp())
        try:
            randspots.write_scenario(scn, tmp)
            loaded = scenario.load_scenario("scenario", tmp)
            self.assertEqual(len(loaded["scenes"]), 6)
            self.assertEqual(loaded["defaults"], base["defaults"])
            for s, spot in zip(loaded["scenes"], spots):
                self.assertEqual(s["type"], "static")
                self.assertIn(s["at"], loaded["places"])
                self.assertIn(s["weather"], loaded["weathers"])
                self.assertEqual(loaded["places"][s["at"]]["pos"], spot["pos"])
                self.assertGreater(scenario.scene_seconds(loaded, s), 0)
        finally:
            shutil.rmtree(tmp)


class CliTest(unittest.TestCase):
    def test_list_and_ab_identical_spots(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        out = []
        with mock.patch("builtins.print", lambda *a, **k: out.append(" ".join(map(str, a)))):
            bench.main(["list", "--random", "5", "--seed", "4"])
            bench.main(["list", "--random", "5", "--seed", "4"])
        n = len(out) // 2
        self.assertEqual(out[:n], out[n:])
        self.assertEqual(n, 2)

        seen = []

        class FakeRunner:
            def __init__(self, paths, opts, say=print):
                self.opts = opts

            def run(self):
                o = self.opts
                scn = scenario.load_scenario(o.scenario, o.scenario_dir)
                seen.append((o.fix, [s["id"] for s in scn["scenes"]], [(s["hour"], s["weather"]) for s in scn["scenes"]],
                             Path(o.run_dir)))
                return {"outcome": "ok"}

        paths = mock.Mock(results=tmp / "results")
        with mock.patch.object(bench, "Runner", FakeRunner), mock.patch.object(bench, "write_comparison") as wc, \
                mock.patch.object(bench, "load_runs", lambda names, d: names), mock.patch.object(bench, "installer"), \
                mock.patch.object(bench.time, "sleep"), mock.patch.object(bench, "Paths", return_value=paths), \
                mock.patch("builtins.print"):
            (tmp / "rep").mkdir()
            (tmp / "rep" / "report.md").write_text("r")
            wc.return_value = tmp / "rep"
            bench.main(["ab", "--random", "4", "--seed", "9", "--rounds", "2", "--a", "stock", "--b", "on"])
        self.assertEqual(len(seen), 4)
        self.assertEqual({tuple(map(str, s[1:3])) for s in seen}.__len__(), 1)
        self.assertEqual([s[0] for s in seen], ["stock", "on", "stock", "on"])
        self.assertEqual(len({s[3] for s in seen}), 4)
        self.assertTrue((seen[0][3] / "scenario.json").exists() and (seen[0][3] / "spots.md").exists())
        self.assertTrue((tmp / "rep" / "spots.md").exists())

    def test_spin_random_spot(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        got = []

        class FakeSpin:
            def __init__(self, paths, opts, say=print):
                got.append(opts)

            def run(self):
                return {"outcome": "ok"}

        paths = mock.Mock(results=tmp)
        for _ in range(2):
            with mock.patch.object(bench, "SpinRunner", FakeSpin), mock.patch.object(bench, "Paths", return_value=paths), \
                    mock.patch("builtins.print"):
                bench.main(["spin", "--random-spot", "3", "--random-worlds", "Tamriel"])
        self.assertEqual(got[0].scenes, got[1].scenes)
        o = got[0]
        scn = scenario.load_scenario(o.scenario, o.scenario_dir)
        self.assertEqual([s["id"] for s in scn["scenes"]], o.scenes)


if __name__ == "__main__":
    unittest.main()
