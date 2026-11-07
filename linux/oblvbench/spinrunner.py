"""bench.py spin: one game session at one spot, the camera turning in full laps, settings flipped live in ABBA
order (see spin.py for the logic that needs no game). Reuses Runner for the start, the scene set-up and the
clean-up; only the part between 'in the world' and 'quit' is its own."""
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

from . import diagwin, fixini, scenario, spin
from .paths import REPO
from .runner import Options, Runner

SHIPPED_INI = REPO / "src" / "OblivionPerfFix" / "OblivionPerfFix.ini"
INI_WAIT = 1.5              # the DLL re-reads its ini every second


class SpinOptions(Options):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.variants = kw.get("variants") or [spin.Variant("base")]
        self.rounds = int(kw.get("rounds", 2))
        self.laps = int(kw.get("laps", 2))
        self.settle = float(kw.get("settle", 4))
        self.deg_per_sec = float(kw.get("deg_per_sec", 30))
        self.pitch = float(kw.get("pitch", 0))
        self.look_interval = float(kw.get("look_interval", 0.075))
        self.cam_lag = float(kw.get("cam_lag", 0.3))
        self.pos = kw.get("pos")                      # (x, y, z) or None
        self.heading = kw.get("heading")
        self.world = kw.get("world")
        self.cell = kw.get("cell")
        self.hour = kw.get("hour")
        self.weather = kw.get("weather")


class SpinRunner(Runner):
    def __init__(self, paths, opts, say=print):
        super().__init__(paths, opts, say)
        self.timeline = spin.Timeline()
        self.slots = []
        self.spot = ""
        self.t_spin0 = None
        self.h0 = 0.0
        self.ini_now = {}
        self.cvar_now = {}
        self.order = []

    # ------------------------------------------------------------ planning

    def plan(self, scn):
        o = self.o
        if o.deg_per_sec <= 0:
            raise spin.SpinError("--deg-per-sec must be positive")
        if o.laps < 1:
            raise spin.SpinError("--laps must be at least 1")
        if o.pos:
            if bool(o.world) == bool(o.cell):
                raise spin.SpinError("--pos needs exactly one of --world NAME or --cell NAME")
            place = {"pos": list(o.pos), "heading": o.heading or 0.0}
            place["cell" if o.cell else "world"] = o.cell or o.world
            scn["places"]["spin-spot"] = place
            scene = {"id": "spin-spot", "type": "static", "at": "spin-spot"}
            self.spot = f"{place.get('cell') or place.get('world')} {','.join(f'{c:g}' for c in o.pos)}"
        else:
            sel = [s for s in scenario.select_scenes(scn, o.scenes, None) if s.get("perf", True)]
            if len(sel) != 1:
                raise spin.SpinError(f"--scene must name exactly one scene of '{o.scenario}' (got {len(sel)}: "
                                     f"{', '.join(s['id'] for s in sel[:6])})")
            scene = dict(sel[0])
            if scene.get("type") != "static" or scene.get("at") not in scn["places"]:
                raise spin.SpinError(f"scene {scene['id']} is a {scene.get('type')} scene: spin needs a static one")
            self.spot = f"{o.scenario}/{scene['id']}"
            if o.heading is not None:
                scn["places"][scene["at"]] = dict(scn["places"][scene["at"]], heading=o.heading)
        for k in ("hour", "weather"):
            if getattr(o, k) is not None:
                scene[k] = getattr(o, k)
        self.check_variants(scn)
        self.order = spin.balanced_order([v.name for v in o.variants], o.rounds)
        return [scene]

    def check_variants(self, scn):
        o = self.o
        if o.fix == "off" and any(v.kind == "ini" for v in o.variants):
            raise spin.SpinError("ini variants need the fix DLL loaded")
        if any(v.kind == "ini" for v in o.variants):
            if not self.paths.fix_ini.exists():
                raise spin.SpinError(f"OblivionPerfFix.ini not found in {self.paths.win64}")
            modes = spin.ini_modes(SHIPPED_INI.read_text(encoding="utf-8-sig", errors="replace"))
            installed = fixini.fix_values(self.paths.fix_ini.read_text(encoding="utf-8-sig", errors="replace"))
            installed.update(fixini.parse_overrides(o.fix_ini))
            if o.diag:
                installed.update(fixini.DIAG_KEYS)
            problems = spin.check_ini_variants(o.variants, modes, installed)
            if problems:
                raise spin.SpinError("cannot flip these in a live session:\n  " + "\n  ".join(problems))
        pinned = set(scenario.profile_expect(self.prof))
        bad = sorted(pinned & set(spin.cvar_keys(o.variants)))
        if bad:
            raise spin.SpinError(f"cvar(s) pinned by profile '{self.profile_name}' (the mod would put them back): "
                                 f"{', '.join(bad)}; use another profile")

    def measured_windows(self):
        return [(s["t0"], s["t1"]) for s in self.slots]

    def estimate_seconds(self, scn, scenes):
        o = self.o
        lap = spin.lap_seconds(o.deg_per_sec)
        return len(self.order) * (o.settle + lap * (o.laps + 1) + 2) + 30

    def announce(self, scenes, estimate, fix_mode, limit_min):
        o = self.o
        self.say(f"spin at {self.spot}: {o.deg_per_sec:g} deg/s ({spin.lap_seconds(o.deg_per_sec):.1f} s/lap), "
                 f"{len(self.order)} slots of {o.laps} lap(s): {' '.join(self.order)}; about {estimate / 60:.0f} min, "
                 f"profile {self.profile_name}, time limit {limit_min} min")

    # ------------------------------------------------------------ the session

    def tick_until(self, t_end):
        """Waits until wall time t_end, sending the spin's heading every look_interval and noting it."""
        o = self.o
        while True:
            now = time.time()
            if now >= t_end:
                return
            h = spin.spin_heading(self.h0, o.deg_per_sec, self.t_spin0, now)
            self.send(f"look {h % 360:.2f} {o.pitch:g}", timeout=5)
            self.timeline.add(now, h)
            left = min(o.look_interval, t_end - time.time())
            if left > 0:
                self.bridge.check()
                time.sleep(left)

    def drive(self, scenes):
        self.apply_settings()
        self.sync_marker()
        self.warm_up(scenes)
        scene = scenes[0]
        self.repair_settings(scene["id"])
        with self.static_setup(scene):
            self.spin_session(scene)
        self.end_of_pass()
        self.sync_marker()

    def spin_session(self, scene):
        o, p = self.o, self.paths
        place = self.scn["places"][scene["at"]]
        self.h0 = float(place.get("heading", 0))
        ini_t = cvar_t = None
        by_name = {v.name: v for v in o.variants}
        if any(v.kind == "ini" for v in o.variants):
            cur = fixini.fix_values(p.fix_ini.read_text(encoding="utf-8-sig", errors="replace"))
            ini_t = spin.ini_targets(o.variants, cur)
            self.ini_now = dict(ini_t["base"])
        base_cvars = {}
        for k in spin.cvar_keys(o.variants):
            v = self.bridge.get(k)
            if v is None or v == "nil":
                raise RuntimeError(f"cvar {k} does not exist in this game (get answered {v!r})")
            base_cvars[k] = v
        if base_cvars:
            cvar_t = spin.cvar_targets(o.variants, base_cvars)
            self.cvar_now = dict(base_cvars)
            self.result["cvarsBase"] = base_cvars
        self.t_spin0 = time.time()
        self.say(f"spinning at {o.deg_per_sec:g} deg/s from heading {self.h0:g}; first {o.settle:g} s settle")
        try:
            current = None
            lap = spin.lap_seconds(o.deg_per_sec)
            for i, name in enumerate(self.order, 1):
                v = by_name[name]
                applied = {}
                if name != current:
                    applied = self.apply_variant(v, ini_t, cvar_t)
                    current = name
                self.tick_until(time.time() + o.settle)
                t0 = spin.next_lap_start(time.time(), self.t_spin0, o.deg_per_sec)
                self.tick_until(t0)
                t1 = t0 + o.laps * lap
                self.say(f"slot {i}/{len(self.order)}: {name} ({o.laps} lap(s), {t1 - t0:.0f} s)")
                self.tick_until(t1)
                self.slots.append({"variant": name, "t0": t0, "t1": t1, "applied": applied})
                self.check_pins(scene["id"])
        finally:
            self.put_back(ini_t, cvar_t)

    def apply_variant(self, v, ini_t, cvar_t):
        applied = {}
        if ini_t is not None and ini_t[v.name] != self.ini_now:
            fixini.override_ini(self.paths.fix_ini, self.guard, ini_t[v.name])
            self.ini_now = dict(ini_t[v.name])
            applied["ini"] = {k: val for k, val in ini_t[v.name].items() if k in v.values} or dict(ini_t[v.name])
            self.say(f"variant {v.name}: ini {applied['ini']}")
            self.tick_until(time.time() + INI_WAIT)
        if cvar_t is not None:
            back = {}
            for k, val in cvar_t[v.name].items():
                if spin.same_value(self.cvar_now.get(k), val):
                    continue
                ans = self.send(f"cvar {k} {val}", timeout=8, nothrow=True) or ""
                got = ans.partition("=")[2]
                back[k] = got
                if not spin.same_value(got, val):
                    self.warn(f"variant {v.name}: {k} set to {val} but reads back {got or ans!r}")
                self.cvar_now[k] = val
            if back:
                applied["cvar"] = back
                self.say(f"variant {v.name}: cvar read back {back}")
                self.tick_until(time.time() + 0.5)
        return applied

    def put_back(self, ini_t, cvar_t):
        """As installed again, live (the file itself is also restored by the FileGuard at the end)."""
        try:
            if ini_t is not None and ini_t["base"] != self.ini_now:
                fixini.override_ini(self.paths.fix_ini, self.guard, ini_t["base"])
                self.ini_now = dict(ini_t["base"])
            if cvar_t is not None:
                for k, val in cvar_t["base"].items():
                    if not spin.same_value(self.cvar_now.get(k), val):
                        self.send(f"cvar {k} {val}", timeout=5, nothrow=True)
                        self.cvar_now[k] = val
        except Exception as e:
            self.warn(f"put back (live): {e}")

    # ------------------------------------------------------------ results

    def analyse(self, mh_dir, watcher):
        super().analyse(mh_dir, watcher)
        log = getattr(self, "log", None)
        rows = []
        for s in self.slots:
            if log is not None:
                st = spin.slot_stats(log, self.log_start, s["t0"], s["t1"], self.timeline, self.o.cam_lag, self.o.laps)
                if not st.get("frames"):
                    self.warn(f"slot {s['variant']}: no frames in the measured time")
            else:
                st = {}
            rows.append({**s, "t0": round(s["t0"], 3), "t1": round(s["t1"], 3), "seconds": round(s["t1"] - s["t0"], 2), **st})
        self.result["slots"] = rows
        self.result["variants"] = spin.summarise(rows, self.o.variants)

    def outcome_of(self, outcome):
        got = {s["variant"] for s in self.result.get("slots", []) if s.get("frames")}
        if not got:
            return "failed"
        return "ok" if outcome == "ok" and got == {v.name for v in self.o.variants} else "partial"

    def write_outputs(self, run_dir):
        o = self.o
        self.result["spin"] = {
            "spot": self.spot, "degPerSec": o.deg_per_sec, "lapSec": spin.lap_seconds(o.deg_per_sec), "pitch": o.pitch,
            "laps": o.laps, "settle": o.settle, "rounds": o.rounds, "camLag": o.cam_lag, "startHeading": self.h0,
            "order": self.order, "lookInterval": o.look_interval, "variantSpecs": [v.spec() for v in o.variants]}
        (run_dir / "heading-timeline.json").write_text(json.dumps(self.timeline.to_json()))
        try:
            self.split_ledger(run_dir)
        except Exception as e:
            self.warn(f"ledger split by variant failed: {e}")
        self.result["warnings"] = self.warnings
        spin.write_result(run_dir, self.result)

    def split_ledger(self, run_dir):
        src = run_dir / "diag" / "OblivionPerfFix-ledger.csv"
        if not self.o.diag or not src.exists():
            return
        text = src.read_text(errors="replace")
        frames = spin.ledger_frames(text)
        offset = spin.anchor_ledger(frames, self.sync_markers)
        led = {"variants": {}}
        self.result["ledger"] = led
        if offset is None:
            led["note"] = ("The ledger's clock could not be matched to the sync stalls (needs both markers and a "
                           "unique pair of ~350 ms frames), so it is not split by variant: see diag/stutter_ledger.txt.")
            return
        windows = {}
        for s in self.slots:
            windows.setdefault(s["variant"], []).append((s["t0"], s["t1"]))
        texts, summary = spin.split_ledger(text, windows, offset, exclude=diagwin.exclusions(self.sync_markers))
        led["offsetS"] = round(offset, 3)
        led["note"] = (f"ledger clock anchored on the two sync stalls (wall = end_ms/1000 + {offset:.3f}); per-variant "
                       f"files hold only the slots' frames, without +-{diagwin.MARGIN_S:g} s around a sync stall")
        tool = REPO / "tools" / "stutter_ledger.py"
        for name, t in texts.items():
            f = run_dir / "diag" / f"ledger-{name}.csv"
            f.write_text(t)
            summary[name]["file"] = f"diag/ledger-{name}.txt"
            if tool.exists():
                r = subprocess.run([sys.executable, "-I", str(tool), str(f), "--ignore-focus"], capture_output=True,
                                   text=True, timeout=300)
                (run_dir / "diag" / f"ledger-{name}.txt").write_text(r.stdout + (("\n" + r.stderr) if r.returncode else ""))
        led["variants"] = summary
