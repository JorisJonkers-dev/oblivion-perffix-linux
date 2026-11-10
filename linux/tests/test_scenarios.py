import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import scenario  # noqa: E402

TYPES = {"static", "door", "walk", "fly"}


class ScenarioTest(unittest.TestCase):
    def test_every_scenario_loads(self):
        names = scenario.list_scenarios()
        self.assertGreater(len(names), 20)
        for name in names:
            with self.subTest(scenario=name):
                scn = scenario.load_scenario(name)
                self.assertTrue(scn["scenes"], "no scenes")
                for s in scn["scenes"]:
                    self.assertIn(s["type"], TYPES, s["id"])
                    self.assertGreater(scenario.scene_seconds(scn, s), 0)
                    self.check_scene(scn, s)

    def check_scene(self, scn, s):
        """What the runner needs from a scene: its places, weathers, paths."""
        places = scn["places"]
        if s["type"] in ("static", "door", "walk"):
            self.assertIn(s["at"], places, s["id"])
        if s["type"] == "door":
            for leg in s.get("legs", []):
                if leg.get("at"):
                    self.assertIn(leg["at"], places, f"{s['id']}/{leg['name']}")
        if s["type"] == "walk":
            self.assertTrue(all(len(w) >= 2 for w in s["waypoints"]))
        if s["type"] == "fly":
            self.assertGreaterEqual(len(s["path"]), 2)
            self.assertTrue(all(len(w) >= 3 for w in s["path"]))
            self.assertGreater(float(s["speed"]), 0)
            self.assertTrue(s.get("world") or s.get("cell"), s["id"])
        w = s.get("weather")
        if w and w != "keep":
            self.assertTrue(w in scn["weathers"] or w in ("Clear", "SEClear"), f"{s['id']}: weather {w}")
        for name, p in places.items():
            if not p.get("here"):
                self.assertEqual(len(p["pos"]), 3, name)
                self.assertTrue("cell" in p or "world" in p, name)

    def test_include_merges(self):
        full = scenario.load_scenario("full")
        ids = {s["id"] for s in full["scenes"]}
        for inc in ("cheydinhal", "world", "actors"):
            self.assertTrue({s["id"] for s in scenario.load_scenario(inc)["scenes"]} <= ids)
        self.assertIn("canal", full["places"])

    def test_select(self):
        scn = scenario.load_scenario("cheydinhal")
        self.assertEqual([s["id"] for s in scenario.select_scenes(scn, ["canal-*"])][:2], ["canal-noon", "canal-rain"])
        doors = scenario.select_scenes(scn, tags=["door"])
        self.assertTrue(doors and all(s["type"] == "door" for s in doors))
        self.assertEqual(len(scenario.select_scenes(scn)), len(scn["scenes"]))

    def test_unknown(self):
        with self.assertRaises(FileNotFoundError):
            scenario.load_scenario("no-such-scenario")


class ProfileTest(unittest.TestCase):
    def test_all_profiles(self):
        for name, p in scenario.load_profiles().items():
            with self.subTest(profile=name):
                cmds = scenario.profile_commands(p, native="2560x1440")
                exp = scenario.profile_expect(p)
                if scenario.is_own(p):
                    self.assertEqual((cmds, exp), ([], {}))
                    continue
                self.assertTrue(cmds[0].startswith("exec r.SetRes "))
                self.assertNotIn("native", cmds[0])
                self.assertIn("r.FidelityFX.FI.Enabled", exp)

    def test_small(self):
        p = scenario.load_profiles()["small"]
        cmds = scenario.profile_commands(p)
        self.assertEqual(cmds[0], "exec r.SetRes 854x480w")
        self.assertIn("cvar r.ScreenPercentage 100", cmds)
        self.assertEqual(scenario.profile_expect(p)["r.FidelityFX.FSR3.Enabled"], 0)

    def test_native_fsr(self):
        p = scenario.load_profiles()["native"]
        self.assertEqual(scenario.profile_commands(p, "res", native="2560x1440"), ["exec r.SetRes 2560x1440wf"])
        e = scenario.profile_expect(p)
        self.assertEqual((e["r.ScreenPercentage"], e["r.FidelityFX.FI.Enabled"]), (50.0, 1))


if __name__ == "__main__":
    unittest.main()
