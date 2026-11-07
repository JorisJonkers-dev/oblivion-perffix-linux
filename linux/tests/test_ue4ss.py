import json
import shutil
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import ue4ss  # noqa: E402
from oblvbench.paths import REPO, to_wine_path  # noqa: E402

MODS_TXT = "CheatManagerEnablerMod : 1\r\nBPML_GenericFunctions : 1\r\n\r\n; Built-in keybinds, do not move up!\r\nKeybinds : 1\r\n"


def listing(d):
    return sorted((str(p.relative_to(d)), p.read_bytes() if p.is_file() else None) for p in Path(d).rglob("*"))


class InstallTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.src = self.tmp / "third_party" / "ue4ss"
        (self.src / "ue4ss" / "Mods" / "Keybinds" / "Scripts").mkdir(parents=True)
        (self.src / "dwmapi.dll").write_bytes(b"proxy")
        (self.src / "ue4ss" / "UE4SS.dll").write_bytes(b"ue4ss")
        (self.src / "ue4ss" / "UE4SS-settings.ini").write_text("[General]\n")
        (self.src / "ue4ss" / "Mods" / "mods.txt").write_bytes(MODS_TXT.encode())
        (self.src / "ue4ss" / "Mods" / "Keybinds" / "Scripts" / "main.lua").write_text("--")
        (self.src / "oblvbench-build.txt").write_text("UE4SS_v3.0.1-1181-g83330635\nsha256=x\n")
        self.win64 = self.tmp / "Win64"
        self.win64.mkdir()
        (self.win64 / "OblivionRemastered-Win64-Shipping.exe").write_bytes(b"exe")
        (self.win64 / "version.dll").write_bytes(b"fix")
        self.runtime = self.tmp / "run"
        self.inst = ue4ss.Installer(self.win64, self.runtime, self.src, say=lambda m: None)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def test_install_and_remove_exactly(self):
        before = listing(self.win64)
        self.inst.install()
        self.assertEqual((self.win64 / "dwmapi.dll").read_bytes(), b"proxy")
        boot = (self.win64 / "ue4ss/Mods/OblvBench/Scripts/main.lua").read_text()
        self.assertIn(f'local PROJECT = "{to_wine_path(REPO)}"', boot)
        self.assertIn(f'local RUNTIME = "{to_wine_path(self.runtime)}"', boot)
        self.assertNotIn("@PROJECT@", boot)
        self.assertTrue(to_wine_path(REPO).startswith("Z:/") and to_wine_path(REPO).endswith("/"))
        self.assertTrue((self.win64 / "ue4ss/Mods/OblvBench/enabled.txt").exists())
        mods = (self.win64 / "ue4ss/Mods/mods.txt").read_text()
        lines = mods.splitlines()
        self.assertLess(lines.index("OblvBench : 1"), lines.index("Keybinds : 1"))
        self.assertIn("\r\n", (self.win64 / "ue4ss/Mods/mods.txt").read_bytes().decode())
        m = json.loads((self.runtime / ue4ss.MANIFEST).read_text())
        self.assertIn("dwmapi.dll", m["files"])
        self.assertIn("ue4ss", m["dirs"])
        # a second install refreshes the mod without duplicating the mods.txt line
        self.inst.install()
        self.assertEqual((self.win64 / "ue4ss/Mods/mods.txt").read_text().count("OblvBench"), 1)
        # UE4SS writes its own files at run time
        (self.win64 / "ue4ss" / "UE4SS.log").write_text("log")
        (self.win64 / "ue4ss" / "Mods" / "shared").mkdir()
        self.inst.remove()
        self.assertEqual(listing(self.win64), before)
        self.assertTrue(list((self.runtime / "ue4ss-logs").glob("*-UE4SS.log")))
        self.assertFalse((self.runtime / ue4ss.MANIFEST).exists())

    def test_keeps_and_restores_foreign_files(self):
        (self.win64 / "dwmapi.dll").write_bytes(b"other loader")
        (self.win64 / "ue4ss").mkdir()
        (self.win64 / "ue4ss" / "players-own.txt").write_text("mine")
        before = listing(self.win64)
        self.inst.install()
        self.assertEqual((self.win64 / "dwmapi.dll.pre-ue4ss").read_bytes(), b"other loader")
        self.assertTrue((self.win64 / "ue4ss.pre-oblvbench" / "players-own.txt").exists())
        self.inst.remove()
        self.assertEqual(listing(self.win64), before)

    def test_refuses_while_game_runs(self):
        inst = ue4ss.Installer(self.win64, self.runtime, self.src, game_running=lambda: True, say=lambda m: None)
        with self.assertRaises(RuntimeError):
            inst.install()

    def test_missing_source(self):
        inst = ue4ss.Installer(self.win64, self.runtime, self.tmp / "nothing", say=lambda m: None)
        with self.assertRaises(RuntimeError):
            inst.install()


class SetupTest(unittest.TestCase):
    def test_pick_asset(self):
        assets = [{"name": "zDEV-UE4SS_v3.0.1-1200-gabc.zip"}, {"name": "UE4SS_v3.0.1-1180-gaaaa.zip"},
                  {"name": "UE4SS_v3.0.1-1190-gbbbb.zip", "digest": "sha256:" + "a" * 64},
                  {"name": "UE4SS_v3.0.1-1185-gcccc.zip"}]
        a = ue4ss.pick_asset(assets)
        self.assertEqual(a["name"], "UE4SS_v3.0.1-1190-gbbbb.zip")
        self.assertEqual(ue4ss.expected_sha(a), ("a" * 64, "GitHub's asset digest"))
        self.assertEqual(ue4ss.expected_sha({"name": ue4ss.TESTED["file"]})[0], ue4ss.TESTED["sha256"])
        self.assertEqual(ue4ss.expected_sha({"name": "UE4SS_v3.0.1-1185-gcccc.zip"}), (None, None))
        self.assertIsNone(ue4ss.pick_asset([{"name": "UE4SS_v3.0.1-1000-gaaaa.zip"}]))

    def test_setup_from_local_zip_and_unsafe_zip(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            z = d / "UE4SS_v3.0.1-1181-g83330635.zip"
            with zipfile.ZipFile(z, "w") as f:
                f.writestr("dwmapi.dll", b"p")
                f.writestr("ue4ss/UE4SS.dll", b"u")
            out = ue4ss.setup(d / "tp", zip_path=z, say=lambda m: None)
            self.assertTrue((out / "ue4ss" / "UE4SS.dll").exists())
            mark = (out / "oblvbench-build.txt").read_text()
            self.assertTrue(mark.startswith("UE4SS_v3.0.1-1181-g83330635\nsha256="))
            self.assertIn("tested=newer than tested", mark)        # not the real tested zip's bytes
            bad = d / "UE4SS_v3.0.1-1182-gdeadbeef.zip"
            with zipfile.ZipFile(bad, "w") as f:
                f.writestr("../evil.dll", b"x")
            with self.assertRaises(ValueError):
                ue4ss.setup(d / "tp2", zip_path=bad, say=lambda m: None)
            with self.assertRaises(RuntimeError):
                ue4ss.setup(d / "tp3", zip_path=d / "UE4SS_v3.0.1-1000-gaaaa.zip", say=lambda m: None)


if __name__ == "__main__":
    unittest.main()
