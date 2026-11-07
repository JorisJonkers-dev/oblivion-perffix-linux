"""One benchmark run in one game session (port of tools/Run-Benchmark.ps1's perf pass for Steam + Proton).

Steps as upstream: start the game, skip to the main menu, enter a fresh world (`obv coc <cell>`) or the latest
save, apply the profile, spectator mode, then per scene: teleport, pin weather/hour/timescale, settle, measure
(static, door legs, walk, flight); quit. Frame times come from MangoHud's per-frame CSV instead of PresentMon, sliced
by the wall-clock windows recorded here."""
import contextlib
import json
import math
import re
import shutil
import signal
import subprocess
import threading
import time
from pathlib import Path

from . import detail, diagwin, dllvariant, envfile, fixini, game, mangohud, scenario, warmup
from .protocol import BenchError, Bridge, Deadline, GameDown, NeedsUser
from .saves import SaveGuard
from .ue4ss import Installer

SYNC_STALL_MS = 350
DEFAULT_WEATHERS = {"Clear": "00038EEE", "SEClear": "00078801"}


def in_world(s):
    return (s.get("pawn") == "1" and s.get("frozen") == "0" and s.get("loadscreen") == "0" and s.get("travel") != "1"
            and s.get("level") != "L_SeamlessTransition" and (s.get("level") != "L_PersistentDungeon" or s.get("sub")))


def at_menu(s):
    return s.get("level") == "L_PersistentDungeon" and not s.get("sub") and s.get("frozen") == "1" and s.get("travel") != "1"


def dist(a, b):
    try:
        return math.dist([float(a["x"]), float(a["y"]), float(a["z"])], [float(b["x"]), float(b["y"]), float(b["z"])])
    except (KeyError, TypeError, ValueError):
        return float("inf")


class Options:
    def __init__(self, **kw):
        self.scenario = kw.get("scenario") or "cheydinhal"
        self.scenes = kw.get("scenes") or None
        self.tags = kw.get("tags") or None
        self.start = kw.get("start")                     # fresh | continue (default: the scenario's, else fresh)
        self.label = kw.get("label") or "run"
        self.fix = kw.get("fix") or "on"
        self.profile = kw.get("profile")
        w = warmup.parse_warmup(kw.get("warmup", "auto"))
        self.warmup_auto = w == "auto"
        self.warmup = warmup.CAP_S if self.warmup_auto else w     # the cap bounds the run's time limit
        self.keep_ue4ss = bool(kw.get("keep_ue4ss"))
        self.show_hud = bool(kw.get("show_hud"))
        self.pin = kw.get("pin", True)
        self.fixed_seed = kw.get("fixed_seed", True)
        self.native_res = kw.get("native_res") or "2560x1440"
        self.stall_sec = float(kw.get("stall_sec", 30))
        self.max_minutes = float(kw.get("max_minutes", 0))
        self.launch_timeout = float(kw.get("launch_timeout", 240))
        self.steam = kw.get("steam") or "steam"
        self.run_dir = kw.get("run_dir")
        self.fix_ini = kw.get("fix_ini")                 # ["KEY=VAL,KEY=VAL", ...] for [Fixes], this run only
        self.dll = kw.get("dll")                         # PE DLL installed as version.dll for this run only
        self.dll_ini = kw.get("dll_ini")                 # ini installed with it (else the installed ini stays)
        self.env = kw.get("env")                         # ["KEY=VAL", ...] added to the launch environment
        self.detail = bool(kw.get("detail"))             # grab the window after door arrivals: time-to-sharp
        self.detail_secs = float(kw.get("detail_secs", 12))
        self.detail_interval = float(kw.get("detail_interval", 0.5))
        self.diag = bool(kw.get("diag"))                 # HitchLedger + HitchLedgerTickSplit, copied into the run
        self.scenario_dir = kw.get("scenario_dir") or scenario.SCENARIO_DIR


class CsvWatcher(threading.Thread):
    """Notes the wall time each MangoHud CSV first appears (cross-check of the log start, if MangoHud writes the
    file while it logs)."""

    def __init__(self, folder, poll=0.25):
        super().__init__(daemon=True)
        self.folder = Path(folder)
        self.poll = poll
        self.seen = {}
        self._stop = threading.Event()

    def run(self):
        while not self._stop.wait(self.poll):
            try:
                for p in self.folder.glob("*.csv"):
                    self.seen.setdefault(p.name, time.time())
            except OSError:
                pass

    def stop(self):
        self._stop.set()


class Runner:
    def __init__(self, paths, opts, say=print):
        self.paths = paths
        self.o = opts
        self.say_raw = say
        self.warnings = []
        self.segments = []
        self.result = {}
        self.pid = None
        self.watchdog = None
        self.bridge = Bridge(paths)
        self.st = {"detect_off": False, "ai_off": False, "wx_override": False, "spawned": []}
        self.place = None
        self.timescale_set = False
        self.sync_markers = []
        self.pin_counts = {}
        self.effective = {}
        self.cond = None
        self.capturer = None
        self.capture_fails = 0

    # ------------------------------------------------------------ output

    def say(self, msg):
        self.say_raw(f"[{time.strftime('%H:%M:%S')}] {msg}")

    def warn(self, msg):
        self.warnings.append(msg)
        self.say(f"WARNING: {msg}")

    def wait(self, sec):
        """Sleep that gives up at once when the game goes down."""
        end = time.monotonic() + sec
        while True:
            self.bridge.check()
            left = end - time.monotonic()
            if left <= 0:
                return
            time.sleep(min(0.25, left))

    def capture_series(self, origin, secs):
        """Grabs the game window every --detail-interval s until `secs` after `origin` (wall time); returns
        [(t since origin, sharpness, mean luminance)] (samples that failed are left out)."""
        if self.capturer is None:
            self.capturer = detail.Capturer()
        masks = self.scn.get("masks") or []
        series, fails, nxt = [], 0, time.time()
        while True:
            now = time.time()
            if now - origin >= secs:
                break
            if now < nxt:
                self.wait(nxt - now)
                continue
            nxt = now + self.o.detail_interval
            try:
                frame = self.capturer.grab()
                t = time.time() - origin
                series.append((round(t, 3), detail.sharpness(frame, masks), detail.mean_luma(frame)))
            except (detail.CaptureError, OSError, ValueError, subprocess.SubprocessError) as e:
                fails += 1
                if fails in (1, 5):
                    self.warn(f"window capture failed ({fails}x): {e}")
                if fails >= 5 and not series:
                    break                                   # nothing works: stop trying in this window
        self.capture_fails += fails
        return series

    def detail_result(self, seg_id, series):
        d = detail.analyse(series)
        d["detailSeries"] = [[t, None if s is None else round(s, 2), round(m, 1)] for t, s, m in series]
        if d.get("detailBlack"):
            self.warn(f"{seg_id}: the captured window was black (XWayland not drawing it?): no detail numbers")
        elif "detailSettleS" not in d:
            self.warn(f"{seg_id}: no detail result ({d.get('detailSamples', 0)} sample(s), "
                      f"{len(series)} captured): the picture never settled or the capture failed")
        return d

    def send(self, cmd, timeout=8.0, nothrow=False):
        return self.bridge.send(cmd, timeout=timeout, nothrow=nothrow)

    # ------------------------------------------------------------ the run

    def run(self):
        o, p = self.o, self.paths
        scn = scenario.load_scenario(o.scenario, o.scenario_dir)
        self.scn = scn
        self.start_mode = o.start or scn.get("start", "fresh")
        if self.start_mode not in ("fresh", "continue"):
            raise RuntimeError(f"start {self.start_mode!r}: only fresh and continue are supported on Linux")
        profiles = scenario.load_profiles()
        self.profile_name = o.profile or scn.get("profile", "small")
        if self.profile_name not in profiles:
            raise RuntimeError(f"unknown profile '{self.profile_name}' ({', '.join(profiles)})")
        self.prof = profiles[self.profile_name]
        self.pin_on = o.pin and scn.get("pin", True)
        scenes = self.plan(scn)
        if o.fix not in envfile.FIX_MODES:
            raise RuntimeError(f"--fix must be one of {', '.join(envfile.FIX_MODES)}")
        fix_mode = "on" if o.fix == "fix" else o.fix

        run_dir = Path(o.run_dir) if o.run_dir else p.results / f"{time.strftime('%Y%m%d-%H%M%S')}-{o.label}"
        run_dir.mkdir(parents=True, exist_ok=True)
        self.run_dir = run_dir
        mh_dir = run_dir / "mangohud"
        mh_dir.mkdir(exist_ok=True)

        estimate = self.estimate_seconds(scn, scenes)
        limit_min = o.max_minutes or math.ceil(1.6 * estimate / 60 + 7 + 5 + o.warmup / 60)
        deadline = time.time() + 60 * limit_min

        # preflight
        if not p.exe.exists():
            raise RuntimeError(f"game exe not found: {p.exe} (set OBLIVION_GAME_DIR)")
        if game.find_game_pid():
            raise RuntimeError("the game is running: close it first (the benchmark starts its own game)")
        dllvariant.check(o.dll, o.dll_ini)
        if o.dll and fix_mode == "off":
            raise RuntimeError("--dll with --fix off: the DLL would not be loaded")
        if fix_mode in ("on", "stock") and not p.fix_ini.exists() and not o.dll_ini:
            raise RuntimeError(f"OblivionPerfFix.ini not found in {p.win64}: install the fix first (linux/README.md)")
        if not shutil.which(o.steam):
            raise RuntimeError(f"'{o.steam}' not on PATH")

        self.result = {
            "label": o.label, "time": time.strftime("%Y-%m-%d %H:%M:%S"), "scenario": scn["name"],
            "start": self.start_mode, "fix": fix_mode, "profile": dict(self.prof, name=self.profile_name),
            "pinned": bool(self.pin_on), "platform": "linux-proton", "frameSource": "mangohud",
            "scenesSelected": [s["id"] for s in scenes], "timeLimitMin": limit_min,
        }
        self.announce(scenes, estimate, fix_mode, limit_min)

        guard = fixini.FileGuard(p.runtime)
        self.guard = guard
        saves = SaveGuard(p.saved / "SaveGames", p.runtime)
        inst = Installer(p.win64, p.runtime, p.ue4ss_src, game_running=lambda: bool(game.find_game_pid()),
                         say=lambda m: self.say(f"ue4ss: {m}"))
        watcher = CsvWatcher(mh_dir)
        installed_here = False
        interrupted = False
        outcome = "failed"
        try:
            if guard.has_pending():
                self.say(f"restoring files left by an earlier run: {guard.restore()}")
            saves.protect()
            if not inst.manifest():
                installed_here = True
            inst.install()
            if o.dll:
                self.result["dll"] = dllvariant.install(p, guard, o.dll, o.dll_ini)
                self.say(f"dll for this run: {o.dll} sha256 {self.result['dll']['sha256'][:12]}")
            elif (p.win64 / "version.dll").exists():
                self.result["dll"] = {"path": str(p.win64 / "version.dll"), "installed": True,
                                      "sha256": fixini.sha256(p.win64 / "version.dll")}
            if p.fix_ini.exists():
                self.result["fixIniInstalled"] = fixini.fix_values(p.fix_ini.read_text(errors="replace"))
            if fix_mode == "stock":
                off = fixini.write_stock_ini(p.fix_ini, guard)
                self.say(f"stock: {len(off)} switches at 0 in OblivionPerfFix.ini (kept: {', '.join(fixini.STOCK_KEEP)})")
            overrides = fixini.parse_overrides(o.fix_ini)
            if o.diag:
                overrides = {**fixini.DIAG_KEYS, **overrides}
            if overrides and fix_mode != "off" and p.fix_ini.exists():
                fixini.override_ini(p.fix_ini, guard, overrides)
                self.result["fixIniOverrides"] = overrides
                self.say(f"OblivionPerfFix.ini for this run: {', '.join(f'{k}={v}' for k, v in overrides.items())}")
            diag_since = time.time()
            self.set_window_config(guard)

            self.bridge.reset_files()
            p.heartbeat_file.unlink(missing_ok=True)
            mh_conf = run_dir / "mangohud.conf"
            mh_conf.write_text(mangohud.config_text(mh_dir, show_hud=o.show_hud))
            marker = p.runtime / "launch-marker.txt"
            marker.unlink(missing_ok=True)
            env = envfile.build_env(fix_mode, mh_conf, ue4ss=True,
                                    game_args=("-FixedSeed",) if o.fixed_seed else (), marker=marker,
                                    extra=envfile.parse_env_args(o.env))
            envfile.write_env(p.env_file, env, ttl=o.launch_timeout + 60)
            self.result["env"] = env
            watcher.start()

            self.launch(marker)
            self.watchdog = game.Watchdog(self.pid, p.heartbeat_file, o.stall_sec, deadline)
            self.watchdog.start()
            self.bridge.check = self.watchdog.check
            self.wait_mod_loaded()
            self.wait_main_menu()
            self.wait_frame_loop()
            s = self.enter_world()
            self.result["loadSec"] = round(time.time() - self.launch_wall, 1)
            self.say(f"in the world: {s.get('level')} ({self.result['loadSec']} s after launch)")
            self.drive(scenes)
            outcome = "ok"
        except (GameDown, Deadline, NeedsUser, BenchError, RuntimeError, OSError) as e:
            self.warn(f"run stopped: {type(e).__name__}: {e}")
            self.result["error"] = f"{type(e).__name__}: {e}"
        except KeyboardInterrupt:
            self.warn("run interrupted (Ctrl+C or a stop signal)")
            self.result["error"] = "interrupted"
            interrupted = True
        finally:
            self.cleanup(guard, saves, inst, installed_here)
            watcher.stop()
        self.analyse(mh_dir, watcher)
        if o.diag and fix_mode != "off":
            self.collect_diag(run_dir, p.win64, diag_since if "diag_since" in locals() else 0)
        self.result["outcome"] = self.outcome_of(outcome)
        self.result["warnings"] = self.warnings
        self.write_outputs(run_dir)
        self.say(f"BENCH-RESULT {self.result['outcome']} {o.label} dir={run_dir} warnings={len(self.warnings)}")
        if interrupted:
            raise KeyboardInterrupt
        return self.result

    # ------------------------------------------------------------ what a run does (overridden by the live session)

    def plan(self, scn):
        """The scenes to measure (raises before anything is touched when there is nothing to do)."""
        o = self.o
        scenes = [s for s in scenario.select_scenes(scn, o.scenes, o.tags) if s.get("perf", True)]
        if not scenes:
            raise RuntimeError(f"no scenes selected in scenario '{o.scenario}'")
        return scenes

    def estimate_seconds(self, scn, scenes):
        extra = 0.0
        if self.o.detail:
            for s in scenes:
                if s.get("type") == "door":
                    extra += 2 * max(0.0, self.o.detail_secs - float(s.get("hold", scn["defaults"].get("hold", 12))))
                elif s.get("detail"):
                    extra += max(0.0, self.o.detail_secs - float(s.get("measure", scn["defaults"].get("measure", 20))))
        return sum(scenario.scene_seconds(scn, s) for s in scenes) + extra

    def announce(self, scenes, estimate, fix_mode, limit_min):
        self.say(f"{len(scenes)} scene(s), about {estimate / 60:.0f} min of scenes, profile {self.profile_name}, "
                 f"fix {fix_mode}, time limit {limit_min} min: {', '.join(s['id'] for s in scenes)}")

    def drive(self, scenes):
        """Everything between 'in the world' and 'quit'."""
        self.apply_settings()
        self.sync_marker()
        self.warm_up(scenes)
        for i, scene in enumerate(scenes, 1):
            try:
                self.run_scene(i, len(scenes), scene)
            except (GameDown, Deadline, NeedsUser):
                raise
            except Exception as e:      # one failed scene must not cost the whole run
                self.warn(f"scene {scene['id']} failed: {e}")
                self.place = None
                for c in ("freeze 0", "watch 0", "walkstop", "flystop"):
                    self.send(c, nothrow=True)
        self.end_of_pass()
        self.sync_marker()

    def outcome_of(self, outcome):
        measured = sum(1 for s in self.result.get("scenes", []) if s.get("frames"))
        failed = any(w.startswith("scene ") and " failed" in w for w in self.warnings)
        return "failed" if not measured else ("ok" if outcome == "ok" and not failed else "partial")

    def write_outputs(self, run_dir):
        (run_dir / "result.json").write_text(json.dumps(self.result, indent=1))
        from .report import run_report
        (run_dir / "report.md").write_text(run_report(self.result))

    # ------------------------------------------------------------ start-up

    def set_window_config(self, guard):
        """The game opens its window at the profile's size (GameUserSettings.ini / AltarGameUserSetting.ini; both
        are rewritten by the game on exit, so they are backed up for every profile). Save_Settings.sav's window
        entries (upstream edits that binary save) are left alone: the profile's r.SetRes fixes the size in game."""
        cfg = self.paths.saved / "Config" / "Windows"
        res = scenario.profile_res(self.prof, self.o.native_res)
        for name in ("GameUserSettings.ini", "AltarGameUserSetting.ini"):
            f = cfg / name
            if not f.exists():
                continue
            guard.backup(f)
            if res:
                w, h = res.split("x")
                mode = 1 if self.prof.get("mode") == "borderless" else 2
                vals = {"ResolutionSizeX": w, "ResolutionSizeY": h, "LastUserConfirmedResolutionSizeX": w,
                        "LastUserConfirmedResolutionSizeY": h, "DesiredScreenWidth": w, "DesiredScreenHeight": h,
                        "LastUserConfirmedDesiredScreenWidth": w, "LastUserConfirmedDesiredScreenHeight": h,
                        "FullscreenMode": mode, "LastConfirmedFullscreenMode": mode}
                text = f.read_text(errors="surrogateescape")
                f.write_text(fixini.set_values(text, "/Script/Altar.AltarGameUserSetting", vals), errors="surrogateescape")

    def launch(self, marker):
        self.say("starting the game through Steam (steam://rungameid)")
        self.launch_wall = time.time()
        game.launch_via_steam(self.o.steam)
        asked = 1
        end = time.monotonic() + self.o.launch_timeout
        while True:
            pid = game.find_game_pid()
            if pid:
                break
            if time.monotonic() > end:
                raise RuntimeError(f"the game process did not appear within {self.o.launch_timeout:.0f} s "
                                   "(is Steam running? did it show a dialog?)")
            if asked < 2 and time.monotonic() - (end - self.o.launch_timeout) > 60:
                game.launch_via_steam(self.o.steam)     # Steam sometimes drops the first request
                asked += 1
            time.sleep(0.5)
        envfile.clear_env(self.paths.env_file)          # from here on a game started by the player is a normal one
        self.pid = pid
        self.result["gamePid"] = pid
        self.result["processStart"] = game.process_start_wall(pid)
        cl = game.cmdline(pid)
        self.result["gameCmdline"] = cl
        self.say(f"game process {pid} is up ({time.time() - self.launch_wall:.0f} s)")
        time.sleep(1.0)
        if not marker.exists():
            raise RuntimeError("the game was not started through linux/oblivion-launch.sh (no launch marker): set "
                               "Steam's launch option to '<repo>/linux/oblivion-launch.sh %command%' (UE4SS and "
                               "MangoHud need it)")
        self.result["launchMarker"] = marker.read_text()
        if self.o.fixed_seed and "-FixedSeed" not in cl:
            self.warn(f"-FixedSeed is not on the game's command line ({cl})")

    def wait_mod_loaded(self):
        self.say("waiting for the OblvBench mod (UE4SS) to load")
        end = time.monotonic() + self.o.launch_timeout
        while "LOADED bench.lua" not in self.bridge.read_log_from(0):
            self.bridge.check()
            if time.monotonic() > end:
                raise GameDown(f"no OblvBench mod within {self.o.launch_timeout:.0f} s: is UE4SS loading "
                               f"(WINEDLLOVERRIDES dwmapi=n,b; {self.paths.win64 / 'ue4ss' / 'UE4SS.log'})?")
            time.sleep(0.5)
        self.result["firstHeartbeat"] = self.watchdog.first_heartbeat

    def wait_main_menu(self, timeout=180):
        self.say("waiting for the main menu (skipping the start-up videos and the title screen)")
        end = time.monotonic() + timeout
        menu = ""
        while menu != "ready":
            if time.monotonic() > end:
                raise GameDown(f"stuck: the main menu did not come up within {timeout} s (last answer: {menu})")
            menu = self.send("menu", timeout=5, nothrow=True) or ""
            if menu in ("eula=0", "setup=0"):
                raise NeedsUser("the game waits for its first-start steps (licence, display/sound settings): start it "
                                "once by hand, go through them to the main menu, close it, then run again")
            if menu != "ready":
                self.wait(0.4)
        if not self.bridge.wait_state(at_menu, timeout=60, stable=2, poll=0.3):
            raise GameDown("stuck: the main menu reports ready but the game is not at it")

    def wait_frame_loop(self):
        ping = self.send("ping", timeout=5, nothrow=True) or ""
        end = time.monotonic() + 90
        if "driver=frame" not in ping:
            self.say(f"waiting for the mod's frame loop ({ping})")
        while "driver=frame" not in ping and time.monotonic() < end:
            self.wait(1)
            ping = self.send("ping", timeout=5, nothrow=True) or ""
        if "driver=frame" not in ping:
            self.warn(f"the mod's frame loop did not start within 90 s ({ping}): flights and walks will not work")

    def enter_world(self):
        if self.start_mode == "continue":
            s = self.bridge.state() or {}
            if s.get("cont") != "1":
                raise RuntimeError("no saved game to continue: use --start fresh")
            self.say("main menu: Continue (latest save)")
            self.send("continue", timeout=60)
            end = time.monotonic() + 20
            msg = ""
            while time.monotonic() < end and "Continue" not in msg:
                self.wait(0.3)
                msg = self.send("msg", timeout=3, nothrow=True) or ""
            if "Continue" not in msg:
                raise RuntimeError(f"expected the 'Continue from your last saved game?' box, got: {msg}")
            self.send("msg 0", timeout=60)
            self.wait(2)
            s = self.bridge.wait_state(in_world, timeout=300, stable=6, poll=0.5)
            if not s:
                raise RuntimeError("the save did not load")
            return s
        # no save needed: the old engine's `coc` from the main menu starts a game with the default character there
        cell = self.scn.get("startCell", "CheydinhalChapelOfArkay")
        self.say(f"main menu: new game in {cell} (no save used)")
        self.send(f"obv coc {cell}")
        if not self.bridge.wait_state(lambda s: s.get("sub") == f"L_{cell}" and s.get("subloaded") == "1",
                                      timeout=300, stable=4, poll=0.5):
            raise RuntimeError(f"the start cell {cell} did not load")
        self.send("closemenu")
        s = self.bridge.wait_state(lambda s: s.get("pawn") == "1" and s.get("frozen") == "0" and s.get("travel") != "1",
                                   timeout=60, stable=4, poll=0.5)
        if not s:
            raise RuntimeError("the game did not leave the main menu")
        return s

    # ------------------------------------------------------------ settings

    def apply_profile(self, parts=("all",)):
        for part in parts:
            for c in scenario.profile_commands(self.prof, part, self.o.native_res):
                # the ray-tracing switches rebuild render state: the first enable once took 11 s
                self.send(c, timeout=60 if "Raytracing" in c else 8)

    def profile_drift(self):
        out = []
        for k, want in scenario.profile_expect(self.prof).items():
            v = self.bridge.get(k)
            if not v or v == "nil":
                continue
            try:
                ok = abs(float(v) - float(want)) <= 0.5
            except ValueError:
                ok = False
            if not ok:
                out.append((scenario.drift_part(k), f"{k}={v}, profile {want}"))
        return out

    def apply_settings(self):
        self.send("prep")
        if "true" not in (self.send("god") or ""):
            self.send("god toggle")
            self.wait(1.5)
            if "true" not in (self.send("god") or ""):
                self.warn("god mode could not be confirmed")
        if self.send("obv tmm 1", nothrow=True) is None:
            self.warn("could not mark the map markers known (tmm 1): places may be discovered during scenes")
        for c in self.scn.get("exec", []):
            self.send(f"exec {c}")
        if self.scn.get("exec"):
            self.wait(3)
        self.send("obv tdetect")                        # a new game: nobody notices the player (a toggle)
        self.st["detect_off"] = True
        for k, v in self.scn["settings"].items():
            self.send(f"cvar {k} {v}")
        self.say(f"profile {self.profile_name}: {self.prof.get('description', '')}")
        self.apply_profile()
        self.wait(2)
        for _, text in self.profile_drift():
            self.warn(f"profile {self.profile_name} not in effect after applying it: {text}")
        self.say("spectator mode: " + (self.send("spectate on") or ""))
        # the mod keeps these as the profile has them (the game turns FSR off when its window loses the focus)
        self.send("pin clear")
        for k, v in scenario.profile_expect(self.prof).items():
            if k != "r.ScreenPercentage" and not k.startswith("sg."):
                self.send(f"pin {k} {v}")
        names = list(dict.fromkeys(list(self.scn["record"]) + list(scenario.profile_expect(self.prof))
                                   + ["Altar.GraphicsOptions.EnableHardwareRaytracing", "Altar.FSR3.FI.Enabled"]))
        self.effective = {n: self.bridge.get(n) for n in names}
        self.result["settings"] = self.effective
        cap = self.bridge.get("t.MaxFPS")
        prof_cap = float((self.prof.get("cvars") or {}).get("t.MaxFPS", 0))
        try:
            capv = float(cap)
        except (TypeError, ValueError):
            capv = 0.0
        if not scenario.is_own(self.prof) and capv > 0 and abs(capv - prof_cap) > 0.5:
            # after a launch the game re-applies the player's Frame Rate Limit a little after the profile cleared it
            self.send("cvar Altar.GraphicsOptions.FrameRateLimit 0", nothrow=True)
            self.send(f"cvar t.MaxFPS {prof_cap:g}", nothrow=True)
            time.sleep(0.5)
            self.say(f"frame cap {capv:g} re-applied by the game after the profile; set back to {prof_cap:g}")
            cap = self.bridge.get("t.MaxFPS")
            try:
                capv = float(cap)
            except (TypeError, ValueError):
                capv = 0.0
        if capv > 0:
            self.result["frameCap"] = capv
            self.say(f"fps capped at {capv:g}")

    def repair_settings(self, before):
        drift = self.profile_drift()
        if not drift:
            return
        self.warn(f"before {before} the game had changed the profile's settings "
                  f"({'; '.join(t for _, t in drift)}): applied again")
        self.apply_profile(list(dict.fromkeys(part for part, _ in drift)))
        self.wait(1.5)

    def sync_marker(self):
        """A known game-thread stall (busy loop in the mod) that shows up as one long frame in MangoHud's log;
        its answer's arrival time pins the log's wall-clock start (mangohud.find_sync)."""
        chunk = f"local t=os.clock() while os.clock()-t<{SYNC_STALL_MS / 1000} do end return 'sync'"
        a = self.send(f"lua {chunk}", timeout=8, nothrow=True)
        if a == "sync":
            self.sync_markers.append((time.time(), SYNC_STALL_MS))
            self.result.setdefault("syncStalls", []).append({"wall": round(self.sync_markers[-1][0], 3),
                                                             "ms": SYNC_STALL_MS})
        else:
            self.warn("sync marker not answered: the frame log's start comes from its file name only (+-0.5 s)")
        self.send("ping", nothrow=True)                 # one more mod-clock sample

    def warm_up(self, scenes):
        first = scenes[0]
        if first.get("type") == "fly" and re.search(r"\bfadein=", str(first.get("flyopt", ""))):
            self.say(f"going to the start of {first['id']} before the warm-up")
            self.move_to_flight_start(first)
            self.place = None
            self.send("prep")
        if self.o.warmup_auto:
            self.say(f"warm-up: auto (until the PSO precompile is done; min {warmup.MIN_S:g} s, cap {warmup.CAP_S:g} s)")
            res = warmup.wait_auto(self.read_fix_log, self.read_live_frames, self.launch_wall - 1.0, self.wait,
                                   say=self.say)
            self.result["warmup"] = res
            self.say(f"warm-up ended after {res['seconds']:.0f} s: {res['reason']}")
            if res["reason"].startswith("cap"):
                self.warn(f"warm-up hit its cap: {res['reason']}")
        elif self.o.warmup > 0:
            self.result["warmup"] = {"mode": "fixed", "seconds": self.o.warmup, "reason": "--warmup seconds"}
            self.say(f"warm-up: {self.o.warmup:.0f} s in the world (shader and PSO compilation)")
            self.wait(self.o.warmup)

    def read_fix_log(self):
        try:
            return (self.paths.win64 / "OblivionPerfFix.log").read_text(errors="replace")
        except OSError:
            return None

    def read_live_frames(self):
        """(elapsed s, frametime ms) of the MangoHud log written so far, or None."""
        try:
            path = mangohud.pick_log(mangohud.find_logs(self.run_dir / "mangohud"))
            if not path:
                return None
            log = mangohud.parse_csv(path)
            return (log.elapsed, log.frametime) if len(log) else None
        except (OSError, ValueError):
            return None

    def end_of_pass(self):
        if self.pin_on and self.st["wx_override"]:
            if self.send("obv ReleaseWeatherOverride", nothrow=True) is not None:
                self.st["wx_override"] = False
        for name, was in self.effective.items():
            now = self.bridge.get(name)
            if now != was:
                self.warn(f"{name} changed during the pass: {was} -> {now}")
        self.result["clockRate"] = self.bridge.clock_rate()

    # ------------------------------------------------------------ moving about

    def wait_arrival(self, before, timeout=90, maybe_in_place=False):
        """Waits until the player left the old spot (or level/interior changed) and stands still again.
        {'state', 'arrive'} or None."""
        start = time.monotonic()
        last, still, moved, arrive = None, 0, False, None
        while time.monotonic() - start < timeout:
            self.bridge.check()
            s = self.bridge.state(light=True, timeout=3)
            jump = (before and s and s.get("level") == before.get("level") and s.get("level") != "L_SeamlessTransition"
                    and dist(s, before) > 400)
            if s and s.get("pawn") == "1" and (s.get("travel") != "1" or jump):
                if not moved:
                    moved = (not before or before.get("pawn") != "1" or s.get("level") != before.get("level")
                             or s.get("sub") != before.get("sub") or dist(s, before) > 150
                             or (maybe_in_place and time.monotonic() - start > 6))
                    if moved:
                        arrive = time.time()
                if moved:
                    still = still + 1 if last and dist(s, last) < 30 else 0
                    if still >= 2:
                        return {"state": s, "arrive": arrive}
                last = s
            else:
                still, last = 0, None
            time.sleep(0.1)
        return None

    def move_to(self, name):
        p = self.scn["places"].get(name)
        if not p:
            raise RuntimeError(f"unknown place '{name}'")
        if p.get("here"):
            self.place = name
            self.send("prep")
            if "heading" in p:
                self.send(f"look {p['heading']} {p.get('pitch', 0)}")
            return
        if self.place != name:
            before = self.bridge.state()
            where = f"cell {p['cell']}" if "cell" in p else f"world {p['world']}"
            pos = p["pos"]
            self.send(f"tp {where} {pos[0]} {pos[1]} {pos[2]} {p['heading']}", timeout=120)
            arr = self.wait_arrival(before, 120, maybe_in_place=True)
            if not arr:
                raise RuntimeError(f"did not arrive at '{name}'")
            if p.get("hover"):
                r = math.radians(float(p["heading"]))
                self.send("fly default 600 {0} 0 hold=100000 {1},{2},{3} {4:.0f},{5:.0f},{3}".format(
                    p.get("pitch", 0), pos[0], pos[1], pos[2], pos[0] + 1000 * math.sin(r), pos[1] + 1000 * math.cos(r)))
                self.wait(3)
                self.place = name
                return
            # a long teleport within a loaded world can drop the player before the terrain there has streamed in
            if "world" in p and arr["state"] and abs(float(arr["state"].get("z", pos[2])) - float(pos[2])) > 400:
                self.warn(f"teleport to '{name}' left the player at z={arr['state'].get('z')}: teleporting again")
                self.wait(2)
                again = self.bridge.state()
                self.send(f"tp {where} {pos[0]} {pos[1]} {pos[2]} {p['heading']}", timeout=120)
                if not self.wait_arrival(again, 60, maybe_in_place=True):
                    raise RuntimeError(f"did not arrive at '{name}' (second try)")
            self.place = name
        self.send("prep")
        self.send(f"look {p['heading']} {p.get('pitch', 0)}")

    def move_to_flight_start(self, scene):
        path = scene["path"]
        heading = (math.degrees(math.atan2(path[1][0] - path[0][0], path[1][1] - path[0][1])) + 360) % 360
        before = self.bridge.state() or {}
        cell = scene.get("cell")
        start = {"x": path[0][0], "y": path[0][1], "z": before.get("z", path[0][2])}
        if (not cell and before.get("level") == f"L_{scene.get('world')}" and before.get("travel") != "1"
                and dist(before, start) < 1500):
            return heading
        airhold = f"airhold {path[0][0]} {path[0][1]} {path[0][2]} {heading:.1f} {scene.get('pitch', 0)}"
        self.send(airhold, nothrow=True)
        where = f"cell {cell}" if cell else f"world {scene.get('world')}"
        for attempt in (1, 2):
            if attempt == 2 and cell:
                self.send(f"obv coc {cell}")
            else:
                self.send(f"tp {where} {path[0][0]} {path[0][1]} {path[0][2]} {heading:.1f}", timeout=120)
            arr = self.wait_arrival(before, 120, maybe_in_place=True)
            if not arr:
                raise RuntimeError("did not arrive at the start of the path")
            s = arr["state"]
            there = s.get("sub") == f"L_{cell}" if cell else s.get("level") == f"L_{scene.get('world')}"
            if there and dist(s, {"x": path[0][0], "y": path[0][1], "z": s.get("z")}) < 3000:
                return heading
            self.warn(f"{scene['id']}: the teleport left the player at {s.get('level')}/{s.get('sub')} "
                      f"{s.get('x')},{s.get('y')} (try {attempt})")
            if attempt == 1:
                self.wait(2)
                self.send(airhold, nothrow=True)
                before = self.bridge.state() or {}
        raise RuntimeError("did not arrive at the start of the path")

    # ------------------------------------------------------------ conditions

    def pin_value(self, scene, key, fallback):
        v = scene.get(key)
        if v is None:
            v = self.scn["defaults"].get(key)
        if v is None:
            v = "keep" if self.start_mode != "fresh" else fallback
        return v

    def weather_id(self, name):
        wid = self.scn["weathers"].get(name) or DEFAULT_WEATHERS.get(name)
        if not wid:
            raise RuntimeError(f"unknown weather '{name}'")
        return wid

    def set_conditions(self, scene):
        self.cond = None
        if not self.pin_on:
            hour = scene.get("hour", self.scn["defaults"].get("hour"))
            if hour is not None:
                self.send(f"obv set gamehour to {hour}")
            ts = scene.get("timescale")
            if ts is not None or self.timescale_set:
                self.send(f"obv set timescale to {ts if ts is not None else 30}")
                self.timescale_set = ts is not None
            if scene.get("weather"):
                self.send(f"obv fw {self.weather_id(scene['weather'])}")
            return
        c = {"pinned": True}
        hour = self.pin_value(scene, "hour", 12)
        if str(hour) != "keep":
            self.send(f"obv set gamehour to {hour}")
        c["hour"] = str(hour)
        ts = self.pin_value(scene, "timescale", 1)
        if str(ts) != "keep":
            self.send(f"obv set timescale to {ts}")
            self.timescale_set = True
        elif self.timescale_set:
            self.send("obv set timescale to 30")
            self.timescale_set = False
        c["timescale"] = str(ts)
        world = str(scene.get("world") or (self.scn["places"].get(str(scene.get("at"))) or {}).get("world", ""))
        w = self.pin_value(scene, "weather", "SEClear" if world.startswith("SE") else "Clear")
        if str(w) == "keep":
            if self.st["wx_override"]:
                self.send("obv ReleaseWeatherOverride")
                self.st["wx_override"] = False
        else:
            wid = self.weather_id(w)
            self.send(f"obv fw {wid} 1")             # 1 = override: the climate cannot change it
            self.st["wx_override"] = True
            # the atmosphere blends into a forced weather over game minutes; flipping through another one switches at once
            self.wait(0.3)
            for attempt in range(2):
                now = self.send("cond 0", nothrow=True) or ""
                if re.search(r"(?:^|\s)wx=([^\s,]+):(1\.00)(?:\s|$)", now):
                    break
                other = "00038EF0" if wid == "00038EEE" else "00038EEE"
                self.send(f"obv fw {other} 1")
                self.wait(0.3)
                self.send(f"obv fw {wid} 1")
                self.wait(0.3)
                c["flipped"] = attempt + 1
        c["weather"] = str(w)
        self.wait(0.3)
        c["atSet"] = self.send("cond 0", nothrow=True)
        self.cond = c

    def add_segment(self, seg):
        if self.cond:
            c = dict(self.cond)
            c["atEnd"] = self.send("cond", nothrow=True)
            seg["cond"] = c
            a = re.search(r"wx=(\S+)", str(c.get("atSet")))
            b = re.search(r"wx=(\S+)", str(c.get("atEnd")))
            if c.get("weather") != "keep" and a and b and a.group(1) != b.group(1):
                self.warn(f"{seg['id']}: the weather changed during the scene ({a.group(1)} -> {b.group(1)}) although pinned")
        self.segments.append(seg)

    def check_pins(self, scene_id):
        a = self.send("pin", nothrow=True) or ""
        m = re.match(r"^pins=(.+)$", a)
        if not m or m.group(1) == "none":
            return
        for e in m.group(1).split(","):
            em = re.match(r"^(.+)=(.+):(\d+)$", e)
            if not em:
                continue
            n, cnt = em.group(1), int(em.group(3))
            if cnt > self.pin_counts.get(n, 0):
                self.warn(f"{scene_id}: the game changed {n} during the scene ({cnt - self.pin_counts.get(n, 0)} "
                          "time(s)); the mod set it back within half a second each time")
            self.pin_counts[n] = cnt

    # ------------------------------------------------------------ scenes

    def run_scene(self, index, count, scene):
        self.repair_settings(scene["id"])
        for c in scene.get("obv", []):
            self.send(f"obv {c}")
            self.wait(0.3)
        settle = float(scene.get("settle", self.scn["defaults"].get("settle", 8)))
        t = scene.get("type")
        self.say(f"scene {index}/{count}: {scene['id']} ({t})")
        if t == "static":
            self.scene_static(scene, settle)
        elif t == "door":
            self.scene_door(scene, settle)
        elif t == "walk":
            self.scene_walk(scene, settle)
        elif t == "fly":
            self.scene_fly(scene, settle)
        else:
            self.warn(f"scene {scene['id']}: unknown type {t}")
        self.check_pins(scene["id"])

    @contextlib.contextmanager
    def static_setup(self, scene):
        """Goes to the scene's place, pins its conditions and does what a static scene needs (detection, AI hold,
        spawned actors, aim); yields whether the AI is held; undoes the toggles on the way out."""
        self.move_to(scene["at"])
        self.set_conditions(scene)
        spawn = scene.get("spawn", [])
        detect = bool(scene.get("detect", False))
        ai_held = False
        try:
            if detect and self.st["detect_off"]:
                self.send("obv tdetect")
                self.st["detect_off"] = False
            if scene.get("aiHold", self.scn["defaults"].get("aiHold", False)) and not self.st["ai_off"]:
                self.send("obv tai")
                self.st["ai_off"] = ai_held = True
            if spawn:
                if scene["id"] in self.st["spawned"]:
                    self.warn(f"{scene['id']}: its actors were already spawned in this game session")
                for sp in spawn:
                    side = {"front": 0, "back": 1, "left": 2, "right": 3}[sp.get("side", "front")]
                    self.send(f"obv player.placeatme {sp['id']} {sp['count']} {sp['distance']} {side}")
                self.st["spawned"].append(scene["id"])
            aim = scene.get("aim")
            if aim:
                self.wait(2)
                self.send(f"aim {aim} front", nothrow=True)
                self.wait(1.5)
                self.send(f"aim {aim}", nothrow=True)
            yield ai_held
        finally:
            if detect and not self.st["detect_off"]:
                if self.send("obv tdetect", nothrow=True) is not None:
                    self.st["detect_off"] = True
            if spawn:
                self.place = None
            if ai_held and self.st["ai_off"]:
                if self.send("obv tai", nothrow=True) is not None:
                    self.st["ai_off"] = False

    def scene_static(self, scene, settle):
        with self.static_setup(scene) as ai_held:
            self.wait(settle)
            t0 = time.time()
            measure = float(scene.get("measure", self.scn["defaults"].get("measure", 20)))
            det = None
            if self.o.detail and scene.get("detail"):
                series = self.capture_series(t0, max(measure, self.o.detail_secs))
                det = self.detail_result(scene["id"], series)
            self.wait(max(0.0, measure - (time.time() - t0)))
            t1 = time.time()
            end = self.bridge.state()
            self.add_segment({"id": scene["id"], "type": "static", "t0": t0, "t1": t1, "state": end, "aiHeld": ai_held,
                              "detail": det})
            if end and (end.get("menu") == "1" or end.get("frozen") == "1"):
                self.warn(f"{scene['id']}: a menu or conversation was open at the end of the scene "
                          f"(menu={end.get('menu')} frozen={end.get('frozen')}): its numbers measure the paused world")

    def scene_door(self, scene, settle):
        self.move_to(scene["at"])
        self.set_conditions(scene)
        self.wait(settle)
        scene_hold = float(scene.get("hold", self.scn["defaults"].get("hold", 12)))
        legs = scene.get("legs") or [{"name": "enter", "door": scene.get("enter")}, {"name": "exit", "door": scene.get("exit")}]
        for leg_def in legs:
            leg = leg_def["name"]
            hold = float(leg_def.get("hold", scene_hold))
            if leg_def.get("at"):
                self.move_to(leg_def["at"])
                self.wait(settle)
            before = self.bridge.state() or {}
            ft = leg_def.get("fasttravel")
            if not ft:
                # a door leaves the player in front of it facing away: turn round so the door is under the crosshair
                self.send("look {:.1f} 0".format((float(before.get("heading", 0)) + 180) % 360))
            self.wait(1.5)
            pos = self.bridge.log_length()
            if ft:
                self.send("ft open")
                self.wait(1.5)
                for _ in range(10):
                    if re.match(r"^icons=[1-9]", self.send(f"ft list {ft}", nothrow=True) or ""):
                        break
                    self.wait(0.5)
                self.wait(1)
                click = self.send(f"ft go {ft}", nothrow=True) or ""
                question = ""
                for _ in range(10):
                    if ft in question:
                        break
                    self.wait(0.5)
                    question = self.send("msg", nothrow=True) or ""
                self.say(f"  fast travel to {ft}: {click}; {question}")
                if not click.startswith("clicked") or ft not in question:
                    self.warn(f"{scene['id']}/{leg}: fast travel to {ft} not offered ({click}; {question})")
                    self.send("ft open", nothrow=True)
                    break
            self.send("watch 1")
            t0 = time.time()
            self.send("msg 0" if ft else "activate")    # the game's Activate input action, injected in-engine
            retries = 0
            arr = None if ft else self.wait_arrival(before, 8)
            if not arr and not ft:
                now = self.bridge.state(timeout=3)
                if (now and now.get("travel") != "1" and now.get("frozen") != "1" and now.get("loadscreen") != "1"
                        and now.get("menu") != "1" and now.get("level") == before.get("level")
                        and now.get("sub") == before.get("sub") and dist(now, before) < 50):
                    self.say(f"  {scene['id']}/{leg}: nothing started 8 s after the activation: activating again")
                    retries, t0 = 1, time.time()
                    self.send("activate")
            if not arr:
                arr = self.wait_arrival(before, 90)
            if arr:
                ta = arr["arrive"]
            else:
                self.warn(f"{scene['id']}/{leg}: no arrival detected")
                ta = time.time()
            det = None
            if self.o.detail and arr:
                series = self.capture_series(ta, max(hold, self.o.detail_secs))
                det = self.detail_result(f"{scene['id']}/{leg}", series)
            self.wait(max(0.0, hold - (time.time() - ta)) if det is not None else hold)
            t1 = time.time()
            self.send("watch 0", nothrow=True)
            events = [f"{c:.2f} {txt}" for c, txt in self.bridge.events(pos)]
            self.add_segment({"id": f"{scene['id']}/{leg}", "type": "door", "t0": t0, "t1": t1, "tA": ta,
                              "arrived": bool(arr), "activationRetries": retries, "state": self.bridge.state(),
                              "events": events, "detail": det})
            if ft and arr:
                for _ in range(3):
                    if (self.bridge.state() or {}).get("menu") != "1":
                        break
                    self.send("ft close", nothrow=True)
                    self.wait(1)
            self.place = None
            if not arr:
                break

    def clock_to_wall(self, clock, ack_wall, ack_clock):
        return ack_wall + (clock - ack_clock) if ack_clock is not None else time.time()

    def scene_walk(self, scene, settle):
        self.move_to(scene["at"])
        self.set_conditions(scene)
        self.wait(settle)
        measure = float(scene.get("measure", self.scn["defaults"].get("measure", 20)))
        pts = " ".join(f"{w[0]},{w[1]}" for w in scene["waypoints"])
        pos = self.bridge.log_length()
        try:
            self.send("watch 1")
            t0 = time.time()
            answer = self.send(f"walk {scene.get('mode', 'inject')} {measure:g} {pts}")
            ack_wall = time.time()
            m = re.search(r"clock=([\d.]+)", answer or "")
            clock0 = float(m.group(1)) if m else None
            done = self.bridge.wait_event(pos, r"^walk=done", measure + 5)
            t1 = self.clock_to_wall(done[0], ack_wall, clock0) if done and clock0 is not None else time.time()
            if clock0 is not None:
                t0 = ack_wall                           # the walk starts as the mod answers
            if not done:
                self.warn(f"{scene['id']}: the walk did not report its end")
            elif "reason=arrived" not in done[1]:
                self.warn(f"{scene['id']}: {done[1]}")
            events = [f"{(c - clock0) if clock0 is not None else c:.2f} {txt}" for c, txt in self.bridge.events(pos)]
            self.add_segment({"id": scene["id"], "type": "walk", "t0": t0, "t1": t1, "state": self.bridge.state(),
                              "events": events})
        finally:
            self.send("walkstop", nothrow=True)
            self.send("watch 0", nothrow=True)
            self.place = None

    def scene_fly(self, scene, settle):
        path = scene["path"]
        pitch = scene.get("pitch", -5)
        tcl = bool(scene.get("tcl", False))
        flyopt = str(scene.get("flyopt", ""))
        if tcl:
            self.send("obv tcl")
        if re.search(r"\bfadein=", flyopt):
            self.send("fade 1", nothrow=True)
        try:
            heading = self.move_to_flight_start(scene)
            self.place = None
            self.send("prep")
            self.send(f"look {heading:.1f} {pitch}")
            self.set_conditions(scene)
            pts = " ".join(",".join(str(v) for v in w) for w in path)
            pos = self.bridge.log_length()
            self.send("watch 1")
            look = scene.get("look") or []
            look_opt = f"holdyaw={look[0]} holdpitch={look[1]}" if len(look) >= 2 else ""
            if len(look) >= 2:
                self.send(f"look {look[0]} {look[1]}")
                self.wait(3)
            cmd = (f"fly {scene.get('method', 'default')} {scene['speed']} {pitch} {scene.get('lookOffset', 0)} "
                   f"hold={settle:g} {look_opt} {flyopt} {pts}")
            answer = self.send(re.sub(r"\s+", " ", cmd))
            ack_wall = time.time()
            m = re.search(r"clock=([\d.]+)", answer or "")
            ack_clock = float(m.group(1)) if m else None
            m = re.search(r"secs=([\d.]+)", answer or "")
            expect = float(m.group(1)) if m else 60
            start = self.bridge.wait_event(pos, r"^fly=(start|done)", 40 + settle)
            if not start or not start[1].startswith("fly=start"):
                raise RuntimeError(f"the flight did not start: {start[1] if start else 'no answer'}")
            done = self.bridge.wait_event(pos, r"^fly=done", expect + 15)
            t0 = self.clock_to_wall(start[0], ack_wall, ack_clock)
            t1 = self.clock_to_wall(done[0], ack_wall, ack_clock) if done else time.time()
            if not done:
                self.warn(f"{scene['id']}: the flight did not report its end")
            elif "reason=arrived" not in done[1]:
                self.warn(f"{scene['id']}: {done[1]}")
            evs = self.bridge.events(pos)
            events = [f"{c - start[0]:.2f} {txt}" for c, txt in evs]
            clips = [txt for _, txt in evs if txt.startswith("fly=clip")]
            if clips:
                self.warn(f"{scene['id']}: the camera went through something {len(clips)} time(s)")
            self.add_segment({"id": scene["id"], "type": "fly", "t0": t0, "t1": t1, "state": self.bridge.state(),
                              "events": events, "expectSec": expect})
        finally:
            self.send("watch 0", nothrow=True)
            if not (re.search(r"\bstay=1\b", flyopt) and re.search(r"\bfadeout=", flyopt)):
                self.send("flystop", nothrow=True)
            if tcl:
                self.send("obv tcl", nothrow=True)
            self.place = None

    # ------------------------------------------------------------ the end

    def cleanup(self, guard, saves, inst, installed_here):
        """Quit the game, then put everything back. Each step on its own, so one failure does not skip the rest."""
        def step(name, fn):
            try:
                fn()
            except Exception as e:
                self.warn(f"clean-up ({name}): {e}")

        def quit_game():
            pid = self.pid or game.find_game_pid()
            if not pid or not game.pid_alive(pid):
                return
            self.say("closing the game")
            if self.watchdog:
                self.watchdog.stop()
            self.bridge.check = lambda: None
            # a clean exit lets MangoHud finish its log; killed games may lose the end of it
            self.send("quit", timeout=3, nothrow=True)
            if not game.wait_gone(pid, 30):
                self.warn("the game did not quit by itself within 30 s: ending it (SIGTERM, then SIGKILL)")
                for other in game.find_game_pids():
                    game.stop_pid(other)
            # the launcher stub exits with the game; give it a moment so the next start is clean
            end = time.monotonic() + 20
            while game.find_game_pids(r"^[A-Z]:.*OblivionRemastered(-Win64-Shipping)?\.exe") and time.monotonic() < end:
                time.sleep(0.5)

        # no second Ctrl+C half-way through putting things back: signals wait until the end of the clean-up
        stop_signals = {signal.SIGINT, signal.SIGTERM, signal.SIGHUP}
        signal.pthread_sigmask(signal.SIG_BLOCK, stop_signals)
        try:
            self._cleanup(step, quit_game, guard, saves, inst)
        finally:
            signal.pthread_sigmask(signal.SIG_UNBLOCK, stop_signals)

    def _cleanup(self, step, quit_game, guard, saves, inst):
        step("env file", lambda: envfile.clear_env(self.paths.env_file))
        step("game", quit_game)
        if self.watchdog:
            self.watchdog.stop()
        step("ini and config", lambda: self.say(f"restored: {guard.restore()}"))
        step("saves", lambda: saves.restore(say=self.say))
        if not self.o.keep_ue4ss:
            if game.find_game_pid():
                self.warn("the game is still running: UE4SS left in place (bench.py remove-ue4ss once it is closed)")
            else:
                step("ue4ss", inst.remove)
        step("env file", lambda: envfile.clear_env(self.paths.env_file))

    def measured_windows(self):
        """Wall-clock (t0, t1) of what the run measures (the diag tools rank only these)."""
        return [(s["t0"], s["t1"]) for s in self.segments]

    def collect_diag(self, run_dir, win64, since):
        """Copies the fix's diagnostic files written during this run and ranks them with upstream's tools."""
        import shutil
        import subprocess
        import sys
        out = run_dir / "diag"
        out.mkdir(exist_ok=True)
        tools = Path(__file__).resolve().parents[2] / "tools"
        copied = []
        for name in fixini.DIAG_FILES:
            src = win64 / name
            if src.exists() and src.stat().st_mtime >= since:
                shutil.copy2(src, out / name)
                copied.append(name)
        self.result["diagFiles"] = copied
        jobs = [("OblivionPerfFix-ledger.csv", "stutter_ledger.py", ["--ignore-focus"]),
                ("OblivionPerfFix-ticksplit.csv", "tick_split.py", [])]
        rng = None
        if "OblivionPerfFix-ledger.csv" in copied:
            rng = diagwin.ledger_range((out / "OblivionPerfFix-ledger.csv").read_text(errors="replace"),
                                       self.sync_markers, self.measured_windows())
            self.result["diagRange"] = rng
            for st, ms in zip(self.result.get("syncStalls", []), rng.get("stallsLedgerMs", [])):
                st["ledgerMs"] = ms
            if rng["fromMs"] is None:
                self.warn("diagnostics: " + rng.get("note", "no range"))
        for csv_name, tool, extra in jobs:
            if csv_name in copied and (tools / tool).exists():
                path = str(out / csv_name)
                runs = [(Path(tool).stem + "-unfiltered.txt", [])] if rng and rng["fromMs"] is not None else []
                runs.append((Path(tool).stem + ".txt", ["--from-ms", str(rng["fromMs"]), "--to-ms", str(rng["toMs"])]
                             if rng and rng["fromMs"] is not None else []))
                for fname, rargs in runs:
                    r = subprocess.run([sys.executable, "-I", str(tools / tool), path, *extra, *rargs],
                                       capture_output=True, text=True, timeout=300)
                    (out / fname).write_text(r.stdout + (("\n" + r.stderr) if r.returncode else ""))
        self.say(f"diagnostics: {', '.join(copied) or 'none written'} -> {out}")

    def analyse(self, mh_dir, watcher):
        """Slices the MangoHud log for each measured window."""
        logs = []
        end = time.monotonic() + 20                   # MangoHud may write the file as the game exits
        last = None
        while time.monotonic() < end:
            logs = mangohud.find_logs(mh_dir)
            sizes = [l.stat().st_size for l in logs]
            if logs and sizes == last:
                break
            last = sizes
            time.sleep(1)
        path = mangohud.pick_log(logs)
        if not path:
            if self.segments:
                self.warn(f"no MangoHud log in {mh_dir}: {len(self.segments)} window(s) could not be analysed "
                          "(is MANGOHUD reaching the game? see launchMarker in result.json)")
            self.result["scenes"] = [self.segment_row(s, None) for s in self.segments]
            return
        log = mangohud.parse_csv(path)
        name_ts = mangohud.name_time(path)
        seen = watcher.seen.get(path.name)
        guess, err = mangohud.estimate_start(name_ts, seen)
        sync, detail = mangohud.find_sync(log, guess, self.sync_markers)
        start = sync if sync is not None else guess
        timing = {"log": path.name, "frames": len(log), "nameTime": name_ts, "firstSeen": seen,
                  "startFromName": round(guess, 3), "nameErrorS": round(err, 3), "syncMarkers": detail,
                  "startUsed": round(start, 3), "method": "sync marker" if sync is not None else "file name"}
        if seen and seen - name_ts > 5:
            timing["note"] = "the file appeared well after logging began (MangoHud writes it at the end)"
        off, spread = self.bridge.clock_offset()
        if off is not None:
            timing["modClockOffset"] = round(off, 3)
            timing["modClockOffsetSpread"] = round(spread, 3)
            if self.result.get("processStart"):
                timing["modClockVsProcessStart"] = round(off - self.result["processStart"], 3)
        if sync is not None:
            self.say(f"frame log {path.name}: start from sync marker, {start - guess:+.3f} s from the file-name estimate")
        else:
            self.say(f"frame log {path.name}: start from its file name (+-{err:.2f} s)")
        self.result["frameLog"] = timing
        self.log, self.log_start = log, start
        self.result["scenes"] = [self.segment_row(s, (log, start)) for s in self.segments]

    def segment_row(self, seg, logstart):
        r = {"id": seg["id"], "type": seg["type"], "t0": round(seg["t0"], 3), "t1": round(seg["t1"], 3),
             "seconds": round(seg["t1"] - seg["t0"], 2)}
        if logstart:
            log, start = logstart
            r.update(mangohud.stats(log, start, seg["t0"], seg["t1"]))
            if not r.get("frames"):
                self.warn(f"{seg['id']}: no frames in the measured time: the numbers of this scene are void")
            if seg["type"] == "door":
                after = mangohud.stats(log, start, seg["tA"], seg["t1"])
                r.update({"arrived": seg["arrived"], "arriveSec": round(seg["tA"] - seg["t0"], 2),
                          "afterFps": after.get("fps"), "afterLow1": after.get("low1"),
                          "afterHitches": after.get("hitches"), "afterWorstMs": after.get("worstMs")})
        if seg.get("detail"):
            r.update(seg["detail"])
        for k in ("events", "cond", "activationRetries", "aiHeld"):
            if seg.get(k):
                r[k] = seg[k]
        st = seg.get("state")
        if st:
            r.update({"level": st.get("level"), "sub": st.get("sub"), "hour": st.get("hour"),
                      "pos": f"{st.get('x')},{st.get('y')},{st.get('z')}"})
        return r
