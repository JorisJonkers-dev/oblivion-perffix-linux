import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import envfile  # noqa: E402
from oblvbench.paths import LINUX_DIR, to_wine_path  # noqa: E402

SCRIPT = LINUX_DIR / "oblivion-launch.sh"


class EnvTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env_file = Path(self.tmp.name) / "cfg" / "oblivion-bench" / "env"

    def tearDown(self):
        self.tmp.cleanup()

    def test_overrides(self):
        self.assertEqual(envfile.dll_overrides("on"), "version=n,b;dwmapi=n,b")
        self.assertEqual(envfile.dll_overrides("stock"), "version=n,b;dwmapi=n,b")
        self.assertEqual(envfile.dll_overrides("off"), "version=b;dwmapi=n,b")
        self.assertEqual(envfile.dll_overrides("on", ue4ss=False), "version=n,b")
        with self.assertRaises(ValueError):
            envfile.dll_overrides("maybe")

    def test_write_parse_clear(self):
        env = envfile.build_env("stock", "/x/my config.conf", marker="/x/m")
        envfile.write_env(self.env_file, env)
        got = envfile.parse_env(self.env_file)
        self.assertEqual(got["MANGOHUD_CONFIGFILE"], "/x/my config.conf")
        self.assertEqual(got["WINEDLLOVERRIDES"], "version=n,b;dwmapi=n,b")
        self.assertEqual(got["MANGOHUD"], "1")
        self.assertEqual(got["OBLV_GAME_ARGS"], "-FixedSeed")
        self.assertGreater(int(got["OBLV_BENCH_EXPIRES"]), time.time())
        envfile.clear_env(self.env_file)
        self.assertFalse(self.env_file.exists())
        envfile.clear_env(self.env_file)              # no error when absent

    def test_wine_path(self):
        self.assertEqual(to_wine_path("/home/u/repo"), "Z:/home/u/repo/")
        self.assertEqual(to_wine_path("/home/u/repo/", trailing_slash=False), "Z:/home/u/repo")


class LaunchScriptTest(unittest.TestCase):
    """Runs linux/oblivion-launch.sh with a fake %command% that prints its environment and arguments."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env_file = Path(self.tmp.name) / "env"
        self.marker = Path(self.tmp.name) / "marker"

    def tearDown(self):
        self.tmp.cleanup()

    def launch(self, inherit=None):
        e = {k: v for k, v in os.environ.items() if k not in ("WINEDLLOVERRIDES", "MANGOHUD", "MANGOHUD_CONFIGFILE")}
        e["OBLIVION_BENCH_ENV"] = str(self.env_file)
        e.update(inherit or {})
        cmd = ["bash", str(SCRIPT), "bash", "-c",
               'echo "W=$WINEDLLOVERRIDES"; echo "M=${MANGOHUD:-}"; echo "C=${MANGOHUD_CONFIGFILE:-}"; echo "A=$*"',
               "game.exe", "-own"]
        r = subprocess.run(cmd, env=e, capture_output=True, text=True, timeout=20)
        self.assertEqual(r.returncode, 0, r.stderr)
        return dict(l.split("=", 1) for l in r.stdout.splitlines())

    def test_no_env_file_is_the_normal_game(self):
        out = self.launch()
        self.assertEqual(out["W"], "version=n,b")
        self.assertEqual(out["M"], "")
        self.assertEqual(out["A"], "-own")

    def test_empty_env_file(self):
        self.env_file.write_text("")
        self.assertEqual(self.launch()["W"], "version=n,b")

    def test_player_override_kept_without_env_file(self):
        self.assertEqual(self.launch({"WINEDLLOVERRIDES": "version=n,b;foo=n"})["W"], "version=n,b;foo=n")

    def test_bench_env(self):
        envfile.write_env(self.env_file, envfile.build_env("off", "/cfg/mh.conf", marker=self.marker))
        out = self.launch()
        self.assertEqual(out["W"], "version=b;dwmapi=n,b")
        self.assertEqual(out["M"], "1")
        self.assertEqual(out["C"], "/cfg/mh.conf")
        self.assertEqual(out["A"], "-own -FixedSeed")
        self.assertIn("WINEDLLOVERRIDES=version=b;dwmapi=n,b", self.marker.read_text())

    def test_expired_env_ignored(self):
        envfile.write_env(self.env_file, envfile.build_env("off", "/cfg/mh.conf", marker=self.marker), ttl=-5)
        out = self.launch()
        self.assertEqual(out["W"], "version=n,b")
        self.assertEqual(out["M"], "")
        self.assertFalse(self.marker.exists())


if __name__ == "__main__":
    unittest.main()


class ExtraEnvTest(unittest.TestCase):
    def test_extra_added_and_guarded(self):
        from oblvbench import envfile as ef
        env = ef.build_env("on", extra={"VKD3D_CONFIG": "no_upload_hvv"})
        self.assertEqual(env["VKD3D_CONFIG"], "no_upload_hvv")
        with self.assertRaises(ValueError):
            ef.build_env("on", extra={"WINEDLLOVERRIDES": "x"})
        with self.assertRaises(ValueError):
            ef.build_env("on", extra={"BAD NAME": "1"})

    def test_parse_env_keeps_commas(self):
        from oblvbench import envfile as ef
        self.assertEqual(ef.parse_env_args(["VKD3D_CONFIG=no_upload_hvv,nodxr", "A=1"]),
                         {"VKD3D_CONFIG": "no_upload_hvv,nodxr", "A": "1"})
        with self.assertRaises(ValueError):
            ef.parse_env_args(["novalue"])
