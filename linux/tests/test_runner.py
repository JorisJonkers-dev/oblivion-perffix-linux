"""A whole run against a fake game: Steam launch, process lookup and liveness are patched; a fake mod plays the
main menu, the new game, the scene commands and the heartbeat; on `quit` it writes a MangoHud CSV whose frames
include the sync markers' stalls. Checks the measured window, the log alignment and that everything is put back."""
import hashlib
import json
import math
import os
import shutil
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fakemod import FakeMod  # noqa: E402
from oblvbench import dllvariant, envfile, fixini, game, runner  # noqa: E402
from oblvbench.paths import Paths  # noqa: E402
from test_fixini import SAMPLE  # noqa: E402

SCENARIO = {
    "name": "mini", "startCell": "TestCell",
    "defaults": {"hour": 12, "weather": "Clear", "settle": 0.5, "measure": 2, "hold": 1},
    "weathers": {"Clear": "00038EEE"},
    "places": {"spot": {"world": "TestWorld", "pos": [1000, 2000, 300], "heading": 90, "pitch": 0}},
    "scenes": [{"id": "spot-noon", "type": "static", "at": "spot"}],
}


class FakeGame:
    """State of the pretend game process and its mod."""

    def __init__(self, paths, mh_dir):
        self.paths, self.mh_dir = paths, mh_dir
        self.running = False
        self.phase = "menu"
        self.pos = (0.0, 0.0, 0.0)
        self.level = "L_PersistentDungeon"
        self.stalls = []          # wall time each sync stall ended
        self.log_start = None
        self.ini_at_launch = None
        self.env_at_launch = None
        self.mod = None
        self.frames = 0
        self._beat = None

    # Steam
    def launch(self, steam="steam", args=()):
        self.env_at_launch = envfile.parse_env(self.paths.env_file)
        self.ini_at_launch = self.paths.fix_ini.read_bytes().decode()
        self.dll_at_launch = (self.paths.win64 / "version.dll").read_bytes()
        Path(self.env_at_launch["OBLV_BENCH_MARKER"]).write_text("time=1\nWINEDLLOVERRIDES=x\n")
        self.running = True
        self.log_start = time.time() + 0.3
        self.mod = FakeMod(self.paths.cmd_file, self.paths.log_file, self.handlers())
        self.mod.start()
        self.mod.log("LOADED bench.lua (driver frame)")
        self._beat = threading.Thread(target=self.heartbeat, daemon=True)
        self._beat.start()

    def heartbeat(self):
        while self.running:
            self.frames += 50
            self.paths.heartbeat_file.write_text(f"{self.mod.clock():.3f} {self.frames} frame ")
            time.sleep(0.3)

    def state(self, light=False):
        if self.phase == "world":
            s = (f"pc=1 level={self.level} pawn=1 x={self.pos[0]} y={self.pos[1]} z={self.pos[2]} heading=90 "
                 f"pitch=0 travel=0 subloaded=1")
        elif self.phase == "cell":
            s = "pc=1 level=L_PersistentDungeon pawn=1 x=0 y=0 z=0 sub=L_TestCell travel=0 subloaded=1"
        else:
            s = "pc=1 level=L_PersistentDungeon pawn=0 travel=0"
        if not light:
            s += " menu=0 loadscreen=0 frozen=" + ("0" if self.phase == "world" else "1") + " mainmenu=1 cont=0"
        return s

    def handlers(self):
        def obv(m, rest):
            if rest.startswith("coc "):
                self.phase = "cell"
            return "sent"

        def closemenu(m, rest):
            self.phase = "world"
            return "sent"

        def tp(m, rest):
            p = rest.split()
            self.level, self.pos = f"L_{p[1]}", (float(p[2]), float(p[3]), float(p[4]))
            return "teleported"

        def lua(m, rest):
            if "os.clock()-t<" in rest:
                time.sleep(0.35)
                self.stalls.append(time.time())
                return "sync"
            return "nil"

        def quit_(m, rest):
            threading.Timer(0.5, self.exit).start()
            return "quitting"

        return {
            "menu": lambda m, r: "ready",
            "ping": lambda m, r: f"pong clock={m.clock():.3f} driver=frame frames={self.frames} loops_per_s=100.0",
            "state": lambda m, r: self.state(),
            "where": lambda m, r: self.state(light=True),
            "obv": obv, "closemenu": closemenu, "tp": tp, "lua": lua, "quit": quit_,
            "god": lambda m, r: "god=true",
            "get": lambda m, r: f"{r}=nil",
            "cond": lambda m, r: "hour=12.000 wx=Clear:1.00",
            "pin": lambda m, r: "pins=none" if not r else "pinned",
            **{v: (lambda m, r: "ok") for v in ("prep", "look", "cvar", "exec", "spectate", "watch", "fade",
                                                 "flystop", "walkstop", "freeze")},
        }

    def exit(self):
        """The game ends: MangoHud writes its log (10 ms frames, a 350 ms frame ending at each stall)."""
        end = time.time()
        rows, el, t = [], 0.0, self.log_start
        stalls = sorted(self.stalls)
        while t < end:
            ft = 0.010
            if stalls and t + 0.350 >= stalls[0] + 0.004 and t < stalls[0]:
                ft = stalls.pop(0) + 0.004 - t
            el += ft
            t += ft
            rows.append(f"{1 / ft:.1f},{ft * 1000:.3f},30,0,95,0,0,0,0,0,0,0,0,0,{int(el * 1e9)}")
        stamp = time.strftime("%Y-%m-%d_%H-%M-%S", time.localtime(math.floor(self.log_start)))
        # the real name has the second the log started; this fake's log starts at log_start exactly
        (self.mh_dir / f"OblivionRemastered-Win64-Shipping_{stamp}.csv").write_text(
            "os,cpu\nx,y\nfps,frametime,cpu_load,cpu_power,gpu_load,cpu_temp,gpu_temp,gpu_core_clock,gpu_mem_clock,"
            "gpu_vram_used,gpu_power,ram_used,swap_used,process_rss,elapsed\n" + "\n".join(rows) + "\n")
        self.running = False
        self.mod.stop()


class RunnerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        gd = self.tmp / "Oblivion Remastered"
        win64 = gd / "OblivionRemastered/Binaries/Win64"
        win64.mkdir(parents=True)
        (win64 / "OblivionRemastered-Win64-Shipping.exe").write_bytes(b"exe")
        (win64 / "version.dll").write_bytes(b"fix")
        (win64 / "OblivionPerfFix.ini").write_text(SAMPLE)
        src = self.tmp / "ue4ss-src"
        (src / "ue4ss/Mods").mkdir(parents=True)
        (src / "dwmapi.dll").write_bytes(b"proxy")
        (src / "ue4ss/UE4SS.dll").write_bytes(b"ue4ss")
        (src / "ue4ss/Mods/mods.txt").write_text("; Built-in keybinds, do not move up!\nKeybinds : 1\n")
        self.env = mock.patch.dict(os.environ, {"OBLIVION_UE4SS_DIR": str(src)})
        self.env.start()
        self.paths = Paths(game_dir=gd, runtime=self.tmp / "run", prefix=self.tmp / "pfx",
                           env_file=self.tmp / "cfg/env", results=self.tmp / "results")
        saves = self.paths.saved / "SaveGames"
        saves.mkdir(parents=True)
        (saves / "autosave 1 - me.sav").write_bytes(b"old save")
        cfg = self.paths.saved / "Config/Windows"
        cfg.mkdir(parents=True)
        (cfg / "GameUserSettings.ini").write_text("[/Script/Altar.AltarGameUserSetting]\nResolutionSizeX=3840\n")
        (self.tmp / "scen").mkdir()
        (self.tmp / "scen/mini.json").write_text(json.dumps(SCENARIO))
        self.before = {p: p.read_bytes() for p in self.tmp.rglob("*") if p.is_file()}

    def tearDown(self):
        self.env.stop()
        shutil.rmtree(self.tmp)

    def make_game(self, run_dir):
        return FakeGame(self.paths, run_dir / "mangohud")

    def make_run(self, run_dir, out, fix, **extra):
        opts = runner.Options(scenario="mini", scenario_dir=self.tmp / "scen", fix=fix, label="t", warmup=0,
                              steam="true", run_dir=run_dir, profile="small", launch_timeout=20, **extra)
        return runner.Runner(self.paths, opts, say=out.append).run()

    def run_fake(self, fix, **extra):
        run_dir = self.tmp / "results/run1"
        fake = self.make_game(run_dir)
        pid = 4242
        patches = [
            mock.patch.object(game, "launch_via_steam", fake.launch),
            mock.patch.object(game, "find_game_pid", lambda: pid if fake.running else None),
            mock.patch.object(game, "find_game_pids", lambda pattern=None: [pid] if fake.running else []),
            mock.patch.object(game, "pid_alive", lambda p: fake.running),
            mock.patch.object(game, "process_start_wall", lambda p: fake.log_start - 1),
            mock.patch.object(game, "cmdline", lambda p: "S:\\x\\OblivionRemastered-Win64-Shipping.exe -FixedSeed"),
        ]
        for p in patches:
            p.start()
        try:
            out = []
            result = self.make_run(run_dir, out, fix, **extra)
        finally:
            for p in patches:
                p.stop()
        return result, fake, out

    def test_stock_run(self):
        result, fake, out = self.run_fake("stock")
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        # during the run: stock ini, bench env with UE4SS and MangoHud
        self.assertIn("BoneUploadStores=0", fake.ini_at_launch)
        self.assertIn("FrameRateLimitAtStart=1", fake.ini_at_launch)
        self.assertEqual(fake.env_at_launch["WINEDLLOVERRIDES"], "version=n,b;dwmapi=n,b")
        self.assertEqual(fake.env_at_launch["MANGOHUD"], "1")
        scene = result["scenes"][0]
        self.assertEqual(scene["id"], "spot-noon")
        self.assertAlmostEqual(scene["seconds"], 2.0, delta=0.3)
        self.assertAlmostEqual(scene["frames"], 100 * scene["seconds"], delta=5)
        self.assertAlmostEqual(scene["fps"], 100, delta=1)
        self.assertEqual(scene["hitches"], 0)                   # the sync stalls lie outside the window
        fl = result["frameLog"]
        self.assertEqual(fl["method"], "sync marker")
        self.assertAlmostEqual(fl["startUsed"], fake.log_start, delta=0.06)
        self.assertEqual(len([m for m in fl["syncMarkers"] if m["frameMs"]]), 2)
        # everything put back
        after = {p: p.read_bytes() for p in self.tmp.rglob("*") if p.is_file()}
        for p, data in self.before.items():
            self.assertEqual(after.get(p), data, p)
        win64 = self.paths.win64
        self.assertFalse((win64 / "dwmapi.dll").exists())
        self.assertFalse((win64 / "ue4ss").exists())
        self.assertFalse(self.paths.env_file.exists())
        self.assertTrue((self.tmp / "results/run1/report.md").exists())
        sent = [v for v, _ in fake.mod.received]
        for verb in ("menu", "obv", "closemenu", "spectate", "tp", "lua", "quit"):
            self.assertIn(verb, sent)
        coc = [r for v, r in fake.mod.received if v == "obv" and r.startswith("coc")]
        self.assertEqual(coc, ["coc TestCell"])

    def test_off_run_env(self):
        result, fake, out = self.run_fake("off")
        self.assertEqual(fake.env_at_launch["WINEDLLOVERRIDES"], "version=b;dwmapi=n,b")
        self.assertEqual(fake.ini_at_launch, SAMPLE)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))

    def assert_all_restored(self):
        after = {p: p.read_bytes() for p in self.tmp.rglob("*") if p.is_file()}
        for p, data in self.before.items():
            self.assertEqual(after.get(p), data, p)

    def test_dll_installed_and_restored(self):
        dll = self.tmp / "built/OblivionPerfFix.dll"
        dll.parent.mkdir()
        dll.write_bytes(b"MZ new build \x00\xff")
        result, fake, out = self.run_fake("on", dll=dll)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(fake.dll_at_launch, dll.read_bytes())
        self.assertEqual(fake.ini_at_launch, SAMPLE)                 # the user's ini stays
        self.assertEqual(result["dll"]["sha256"], hashlib.sha256(dll.read_bytes()).hexdigest())
        self.assertEqual(json.loads((self.tmp / "results/run1/result.json").read_text())["dll"]["sha256"],
                         result["dll"]["sha256"])
        self.assert_all_restored()

    def test_dll_and_ini_installed_and_restored(self):
        dll, ini = self.tmp / "b.dll", self.tmp / "b.ini"
        dll.write_bytes(b"dll2")
        ini.write_bytes(SAMPLE.replace("BoneUploadStores=1", "BoneUploadStores=0").encode())
        result, fake, out = self.run_fake("on", dll=dll, dll_ini=ini)
        self.assertEqual(result["outcome"], "ok", "\n".join(out))
        self.assertEqual(fake.dll_at_launch, b"dll2")
        self.assertEqual(fake.ini_at_launch, ini.read_bytes().decode())
        self.assertEqual(result["dll"]["iniSha256"], hashlib.sha256(ini.read_bytes()).hexdigest())
        self.assert_all_restored()

    def test_installed_dll_sha_recorded_without_dll_option(self):
        result, fake, out = self.run_fake("on")
        self.assertEqual(result["dll"]["sha256"], hashlib.sha256(b"fix").hexdigest())
        self.assertTrue(result["dll"]["installed"])

    def test_dll_missing_or_with_fix_off_refused_before_touching_anything(self):
        for kw, fix in (({"dll": self.tmp / "nope.dll"}, "on"), ({"dll": self.tmp / "x.dll"}, "off"),
                        ({"dll_ini": self.tmp / "x.ini"}, "on")):
            (self.tmp / "x.dll").write_bytes(b"x")
            result, fake, out = self.run_fake_expect_error(fix, **kw)
        self.assert_all_restored()

    def run_fake_expect_error(self, fix, **kw):
        with self.assertRaises(RuntimeError):
            self.run_fake(fix, **kw)
        return None, None, None

    def test_dll_restored_when_run_is_killed_half_way(self):
        dll = self.tmp / "k.dll"
        dll.write_bytes(b"killed build")
        guard = fixini.FileGuard(self.paths.runtime)
        dllvariant.install(self.paths, guard, dll, dll)             # as a run killed after installing
        self.assertEqual((self.paths.win64 / "version.dll").read_bytes(), b"killed build")
        self.assertTrue(guard.has_pending())
        guard.restore()                                              # bench.py restore
        self.assert_all_restored()


class SideParseTest(unittest.TestCase):
    def test_simple(self):
        for s in ("on", "stock", "off"):
            self.assertEqual(dllvariant.parse_side(s), (s, None, s))

    def test_dll_variants(self):
        d = Path(tempfile.mkdtemp())
        try:
            f = d / "a.dll"
            f.write_bytes(b"abc")
            sha8 = hashlib.sha256(b"abc").hexdigest()[:8]
            self.assertEqual(dllvariant.parse_side(f"dll:{f}"), ("on", str(f), f"dll-{sha8}"))
            self.assertEqual(dllvariant.parse_side(f"dll:{f}@stock"), ("stock", str(f), f"dll-{sha8}-stock"))
            self.assertEqual(dllvariant.parse_side(f"dll:{f}@on")[:2], ("on", str(f)))
            for bad in ("dll:", f"dll:{d}/missing.dll", "fix", "dll"):
                with self.assertRaises(ValueError):
                    dllvariant.parse_side(bad)
        finally:
            shutil.rmtree(d)


if __name__ == "__main__":
    unittest.main()
