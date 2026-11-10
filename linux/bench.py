#!/usr/bin/env python3
"""OblivionPerfFix benchmark on Linux (Steam + Proton): the Linux replacement for tools/Run-Benchmark.ps1 and
tools/Bench-Report.ps1. Standard library only. See linux/README.md.

  bench.py setup                         download + check UE4SS into linux/third_party/
  bench.py install-ue4ss | remove-ue4ss  put UE4SS + the OblvBench mod into the game folder / take them out
  bench.py status | restore              what is in place / put back files a killed run left changed
  bench.py list [--scenario S]           scenarios, scenes, profiles
  bench.py run --scenario showcase --fix stock --label s1
  bench.py ab --scenario showcase --rounds 2 --a stock --b on
  bench.py ab --scenario showcase --a on --b dll:build-linux/OblivionPerfFix.dll   # installed vs a built DLL
  bench.py run --random 8 --seed 1 [--random-tags outdoor,city] [--random-worlds Tamriel]   # seeded random spots
  bench.py list --random 8 --seed 1                      # show the drawn spots without running
  bench.py report --a s1,s2 --b f1,f2
  bench.py spin --scenario linux-hotspots --scene cheydinhal-canal --variant off:ini:RdgParallelTranslate=0
"""
import argparse
import signal
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from oblvbench import dllvariant, envfile, fixini, game, randspots, scenario, spin, spinshots, ue4ss  # noqa: E402
from oblvbench.paths import Paths  # noqa: E402
from oblvbench.report import load_runs, redetail_runs, write_comparison, write_redetail  # noqa: E402
from oblvbench.runner import Options, Runner  # noqa: E402
from oblvbench.saves import SaveGuard  # noqa: E402
from oblvbench.spinrunner import SpinOptions, SpinRunner  # noqa: E402
from oblvbench.warmup import parse_warmup as warmup_arg  # noqa: E402


def say(msg):
    print(msg, flush=True)


def installer(paths):
    return ue4ss.Installer(paths.win64, paths.runtime, paths.ue4ss_src, game_running=lambda: bool(game.find_game_pid()),
                           say=say)


def split_list(values):
    out = []
    for v in values or []:
        out += [x for x in v.split(",") if x]
    return out or None


def run_kwargs(a, **over):
    kw = dict(scenario=a.scenario, scenes=split_list(a.scenes), tags=split_list(a.tags), start=a.start,
              label=a.label, fix=getattr(a, "fix", "on"), profile=a.profile, warmup=a.warmup, keep_ue4ss=a.keep_ue4ss,
              show_hud=a.show_hud, pin=not a.no_pin, fixed_seed=not a.no_fixed_seed, native_res=a.native_res,
              stall_sec=a.stall_sec, max_minutes=a.max_minutes, launch_timeout=a.launch_timeout, steam=a.steam,
              fix_ini=a.fix_ini, env=a.env, diag=a.diag, dll=a.dll, dll_ini=a.dll_ini, detail=a.detail,
              detail_secs=a.detail_secs, detail_interval=a.detail_interval)
    kw.update(over)
    return kw


def run_options(a, **over):
    return Options(**run_kwargs(a, **over))


def cmd_setup(a, paths):
    ue4ss.setup(paths.third_party, zip_path=a.zip, update=a.update, allow_unverified=a.allow_unverified,
                say=lambda m: say(f"  {m}"))
    say("SETUP-RESULT ok. Next: set the launch option (linux/README.md), then bench.py run")


def cmd_status(a, paths):
    say(f"game:      {paths.game_dir} ({'found' if paths.exe.exists() else 'NOT FOUND'})")
    say(f"prefix:    {paths.prefix}  saved: {paths.saved} ({'found' if paths.saved.exists() else 'not found'})")
    say(f"fix:       version.dll {'present' if (paths.win64 / 'version.dll').exists() else 'absent'}, "
        f"ini {'present' if paths.fix_ini.exists() else 'absent'}")
    say(f"ue4ss:     {installer(paths).status()}")
    say(f"env file:  {paths.env_file} " + (f"PRESENT {envfile.parse_env(paths.env_file)}" if paths.env_file.exists() else "(absent: normal game)"))
    pending = fixini.FileGuard(paths.runtime).has_pending()
    say(f"restore:   {'files waiting to be put back (bench.py restore)' if pending else 'nothing pending'}")
    pid = game.find_game_pid()
    say(f"game proc: {pid or 'not running'}")


def cmd_restore(a, paths):
    if game.find_game_pid():
        raise SystemExit("the game is running: close it first")
    envfile.clear_env(paths.env_file)
    say(f"restored: {fixini.FileGuard(paths.runtime).restore()}")
    SaveGuard(paths.saved / "SaveGames", paths.runtime).restore(say=say)
    if a.ue4ss:
        installer(paths).remove()


def draw_random(a, n, seed):
    """(spots, scenario dict) for --random N --seed S: static scenes on top of --scenario's defaults/settings."""
    base = scenario.load_scenario(a.scenario or "cheydinhal")
    try:
        pool = randspots.build_pool()
        spots = randspots.draw_spots(pool, n, seed, a.random_tags, a.random_worlds, a.random_hours, a.random_weather)
    except ValueError as e:
        raise SystemExit(f"random: {e}")
    return spots, randspots.build_scenario(spots, base, seed)


def write_random(scn, spots, run_dir, header):
    """scenario.json (loadable with scenario_dir=run_dir) and spots.md into the run folder."""
    randspots.write_scenario(scn, run_dir)
    (Path(run_dir) / "spots.md").write_text(f"# {header}\n\n```\n{randspots.describe(spots)}\n```\n")


def random_run_dir(paths, label):
    return paths.results / f"{time.strftime('%Y%m%d-%H%M%S')}-{label}"


def cmd_list(a, paths):
    if a.random:
        spots, scn = draw_random(a, a.random, a.seed)
        by_group, _ = randspots.pool_summary(randspots.filter_pool(randspots.build_pool(), a.random_tags, a.random_worlds))
        say(f"{len(spots)} random spots, seed {a.seed} (pool after filters: {sum(by_group.values())}; "
            f"{', '.join(f'{k} {v}' for k, v in by_group.items())})")
        say(randspots.describe(spots))
        return
    if a.scenario:
        scn = scenario.load_scenario(a.scenario)
        for s in scenario.select_scenes(scn, split_list(a.scenes), split_list(a.tags)):
            say(f"  {s['id']:<34} {s['type']:<7} {int(scenario.scene_seconds(scn, s)):>4} s  "
                f"{','.join(s.get('tags', []))}{'' if s.get('perf', True) else '  (visual only: skipped)'}")
        return
    for n in scenario.list_scenarios():
        try:
            d = scenario.load_scenario(n).get("description", "")
        except Exception as e:
            d = f"(unreadable: {e})"
        say(f"  {n:<20} {d[:110]}")
    say("profiles:")
    for n, p in scenario.load_profiles().items():
        say(f"  {n:<24} {p.get('description', '')[:100]}")


def cmd_run(a, paths):
    over = {}
    if a.random:
        spots, scn = draw_random(a, a.random, a.seed)
        run_dir = random_run_dir(paths, a.label)
        write_random(scn, spots, run_dir, f"{len(spots)} random spots, seed {a.seed}")
        say(f"random spots (seed {a.seed}):\n{randspots.describe(spots)}")
        over = dict(scenario="scenario", scenario_dir=run_dir, run_dir=run_dir, scenes=None, tags=None)
    r = Runner(paths, run_options(a, **over), say=say).run()
    return 0 if r["outcome"] == "ok" else (1 if r["outcome"] == "partial" else 2)


def parse_pos(text):
    try:
        x, y, z = (float(v) for v in text.split(","))
    except ValueError:
        raise SystemExit(f"--pos expects x,y,z (numbers), got {text!r}")
    return (x, y, z)


def cmd_spin(a, paths):
    over = {}
    if a.random_spot is not None:
        if a.scene or a.pos:
            raise SystemExit("--random-spot replaces --scene / --pos")
        spots, scn = draw_random(a, 1, a.random_spot)
        run_dir = random_run_dir(paths, f"spin-{a.label}")
        write_random(scn, spots, run_dir, f"random spot, seed {a.random_spot}")
        say(f"random spot (seed {a.random_spot}):\n{randspots.describe(spots)}")
        a.scene = scn["scenes"][0]["id"]
        over = dict(scenario="scenario", scenario_dir=run_dir, run_dir=run_dir)
    if bool(a.scene) == bool(a.pos):
        raise SystemExit("give either --scene ID (of --scenario) or --pos x,y,z --heading H --world/--cell NAME")
    try:
        variants = spin.parse_variants(a.variant)
        shot_headings = spinshots.parse_headings(a.shot_headings) if a.shot_headings else None
        opts = SpinOptions(**{**run_kwargs(a, label=f"spin-{a.label}", scenes=[a.scene] if a.scene else None, tags=None, **over),
                              "variants": variants, "rounds": a.rounds, "laps": a.laps, "settle": a.settle,
                              "deg_per_sec": a.deg_per_sec, "pitch": a.pitch, "cam_lag": a.cam_lag,
                              "look_interval": a.look_ms / 1000.0, "pos": parse_pos(a.pos) if a.pos else None,
                              "heading": a.heading, "world": a.world, "cell": a.cell, "hour": a.hour,
                              "weather": a.weather, "shots": a.shots, "shot_headings": shot_headings,
                              "shot_settle": a.shot_settle, "shot_width": a.shot_width, "shot_pairs": a.shot_pairs,
                              "diff_thresh": a.diff_thresh, "turn_settle": a.turn_settle,
                              "turn_headings": spinshots.parse_headings(a.turn_headings) if a.turn_headings else None,
                              "turn_hold": a.turn_hold, "turn_from": a.turn_from, "turn_interval": a.turn_interval,
                              "turn_secs": a.turn_secs, "turn_width": a.turn_width, "shot_still": a.shot_still,
                              "shot_register": not a.no_register, "shot_search": a.reg_search,
                              "thresholds": {"ssimMaxDrop": a.ssim_max_drop, "gainFpsPct": a.gain_fps,
                                             "gainLowsPct": a.gain_lows, "gainHitchesPct": a.gain_hitches}})
        r = SpinRunner(paths, opts, say=say).run()
    except (spin.SpinError, ValueError) as e:
        raise SystemExit(f"spin: {e}")
    return 0 if r["outcome"] == "ok" else (1 if r["outcome"] == "partial" else 2)


def side_ini(a, side):
    """--fix-ini (both sides) followed by this side's --a-ini / --b-ini, which win where they overlap."""
    return (a.fix_ini or []) + (getattr(a, f"{side}_ini", None) or []) or None


def side_spec(a, side):
    """One A/B side: its mode (on/stock/off or dll:PATH[@stock]), the DLL it runs, its own ini keys and its names.
    `tag` goes into run labels, `name` into the report (--name-a/--name-b, else mode/dll sha8 plus the ini keys)."""
    fix, dll, tag = dllvariant.parse_side(getattr(a, side))
    dll = dll or a.dll
    if getattr(a, "dll", None) and tag in dllvariant.SIMPLE_SIDES:
        tag = f"dll-{fixini.sha256(a.dll)[:8]}" + ("" if fix == "on" else "-" + fix)
    own = getattr(a, f"{side}_ini", None) or []
    extra = ",".join(own)
    name = getattr(a, f"name_{side}", None) or (f"{tag}+{extra}" if extra else tag)
    dllvariant.check(dll, None)
    return {"fix": fix, "dll": dll, "tag": tag, "name": name,
            "ident": (fix, str(dll) if dll else None, tuple(side_ini(a, side) or []))}


def side_name(a, side):
    return side_spec(a, side)["name"]


def cmd_ab(a, paths):
    names = {"a": [], "b": []}
    try:
        sides = {k: side_spec(a, k) for k in ("a", "b")}
        if a.dll_ini:
            dllvariant.check(next((x["dll"] for x in sides.values() if x["dll"]), None), a.dll_ini)
        if sides["a"]["ident"] == sides["b"]["ident"]:
            raise ValueError("--a and --b are the same variant (same mode, dll and ini)")
    except (ValueError, RuntimeError) as e:
        raise SystemExit(f"ab: {e}")
    inst = installer(paths)
    stamp = time.strftime("%m%d-%H%M")
    code = 0
    rand = draw_random(a, a.random, a.seed) if a.random else None
    if rand:
        say(f"random spots (seed {a.seed}), the same for both sides:\n{randspots.describe(rand[0])}")
    try:
        inst.install()
        for rnd in range(1, a.rounds + 1):
            for key in ("a", "b"):
                mode, dll = sides[key]["fix"], sides[key]["dll"]
                label = f"{a.label}-{stamp}-{key.upper()}{sides[key]['tag']}-r{rnd}"
                say(f"== round {rnd}/{a.rounds}: {key.upper()} = {sides[key]['name']} ({label})")
                over = {}
                if rand:
                    run_dir = random_run_dir(paths, label)
                    write_random(rand[1], rand[0], run_dir, f"{len(rand[0])} random spots, seed {a.seed}")
                    over = dict(scenario="scenario", scenario_dir=run_dir, run_dir=run_dir, scenes=None, tags=None)
                r = Runner(paths, run_options(a, label=label, fix=mode, dll=dll, dll_ini=a.dll_ini if dll else None,
                                              keep_ue4ss=True, fix_ini=side_ini(a, key), **over),
                           say=say).run()
                if r["outcome"] == "failed":
                    raise SystemExit(f"run {label} failed: {r.get('error')} (see its report.md)")
                code = max(code, 0 if r["outcome"] == "ok" else 1)
                names[key].append(label)
                time.sleep(10)          # let Steam see the game end before the next launch
    finally:
        if not a.keep_ue4ss:
            try:
                inst.remove()
            except Exception as e:
                say(f"WARNING: UE4SS not removed: {e}")
    d = write_comparison(load_runs(names["a"], paths.results), load_runs(names["b"], paths.results),
                         sides["a"]["name"], sides["b"]["name"], paths.results, a.label)
    if rand:
        write_random(rand[1], rand[0], d, f"{len(rand[0])} random spots, seed {a.seed} (both sides)")
    say(f"REPORT {d / 'report.md'}")
    print((d / "report.md").read_text())
    return code


def cmd_redetail(a, paths):
    for d, _ in write_redetail(load_runs(split_list(a.runs), paths.results), paths.results):
        say(f"REDETAIL {d}")


def cmd_reshots(a, paths):
    src = Path(a.run) if Path(a.run).is_dir() else paths.results / a.run
    out = Path(a.out) if a.out else src.parent / (src.name + "-reshots")
    try:
        r = spinshots.reshots(src, out, a.shot_pairs, a.diff_thresh, register=not a.no_register, search=a.reg_search,
                              thresholds={"ssimMaxDrop": a.ssim_max_drop}, say=say)
    except (ValueError, OSError) as e:
        raise SystemExit(f"reshots: {e}")
    nf = ((r.get("images") or {}).get("variants") or {}).get((r["images"] or {}).get("base"), {}).get("noiseFloor")
    say(f"RESHOTS {out / 'report.md'} (noise floor {nf})")
    for row in r.get("variants") or []:
        if row.get("verdict"):
            say(f"  {row['name']}: {row['verdict']['code']} - {row['verdict']['text']}")


def cmd_report(a, paths):
    runs_a, runs_b = load_runs(split_list(a.a), paths.results), load_runs(split_list(a.b), paths.results)
    if a.redetail:
        runs_a, runs_b = redetail_runs(runs_a), redetail_runs(runs_b)
    d = write_comparison(runs_a, runs_b, a.name_a, a.name_b, paths.results, a.label)
    say(f"REPORT {d / 'report.md'}")
    print((d / "report.md").read_text())


def add_random_args(p, spin=False):
    p.add_argument("--random-tags", action="append", metavar="TAG[,TAG]",
                   help="random spots: only places with any of these tags (outdoor, city, interior, water, night...)")
    p.add_argument("--random-worlds", action="append", metavar="W[,W]",
                   help="random spots: Tamriel, Interior, ShiveringIsles, Oblivion or an exact world/cell name")
    p.add_argument("--random-hours", choices=["day", "any"], default="day", help="random hour: daylight (7-17, default) or 0-23")
    p.add_argument("--random-weather", default="Clear",
                   help="Clear (default), a name, a comma list, or 'any' (the spot's scenario weathers)")
    if spin:
        p.add_argument("--random-spot", type=int, metavar="SEED", help="spin at one random spot drawn by this seed")
    else:
        p.add_argument("--random", type=int, default=0, metavar="N",
                       help="N static scenes at seeded random places of all scenarios instead of --scenario's scenes "
                            "(--scenario still supplies settle/measure/profile); written to the run folder as scenario.json")
        p.add_argument("--seed", type=int, default=1, help="seed of --random (same seed = same spots and order)")


def add_run_args(p):
    p.add_argument("--scenario", default="cheydinhal")
    p.add_argument("--scenes", action="append", help="scene ids, comma separated, wildcards allowed")
    p.add_argument("--tags", action="append")
    p.add_argument("--start", choices=["fresh", "continue"], help="default: the scenario's, else fresh")
    p.add_argument("--profile", help="bench/profiles.json (default: the scenario's, else small)")
    p.add_argument("--label", default="run")
    p.add_argument("--warmup", type=warmup_arg, default="auto",
                   help="'auto' (default): wait in the world until the start-up PSO precompile is done (OblivionPerfFix.log; "
                        "frame-time stability without the fix; min 20 s, cap 240 s), or a number of seconds")
    p.add_argument("--native-res", default="2560x1440", help="what profile res 'native' means (default 2560x1440)")
    p.add_argument("--keep-ue4ss", action="store_true", help="leave UE4SS in the game folder afterwards")
    p.add_argument("--show-hud", action="store_true", help="show the MangoHud overlay (default: logging only)")
    p.add_argument("--no-pin", action="store_true", help="do not pin weather/hour/timescale")
    p.add_argument("--no-fixed-seed", action="store_true", help="launch without -FixedSeed")
    p.add_argument("--stall-sec", type=float, default=30, help="watchdog: no new frame for this long = stalled")
    p.add_argument("--max-minutes", type=float, default=0, help="time limit of one run (0: from the scene estimate)")
    p.add_argument("--fix-ini", action="append", metavar="KEY=VAL[,KEY=VAL]",
                   help="set [Fixes] keys in OblivionPerfFix.ini for this run only (restored afterwards)")
    p.add_argument("--env", action="append", metavar="KEY=VAL",
                   help="extra environment (repeat the flag for more) for this launch, e.g. VKD3D_CONFIG=no_upload_hvv")
    p.add_argument("--diag", action="store_true",
                   help="engine diagnostics: HitchLedger + HitchLedgerTickSplit, copied and ranked into the run folder")
    p.add_argument("--detail", action="store_true",
                   help="detail arrival: grab the game window after each door arrival (and in static scenes with "
                        "\"detail\": true) and report the time to sharp textures (costs some fps)")
    p.add_argument("--detail-secs", type=float, default=12, help="seconds of captures after the arrival (default 12)")
    p.add_argument("--detail-interval", type=float, default=0.5, help="seconds between captures (default 0.5)")
    p.add_argument("--dll", metavar="PATH",
                   help="run with this OblivionPerfFix.dll as version.dll (installed one backed up, restored afterwards)")
    p.add_argument("--dll-ini", metavar="PATH", help="with --dll: also install this OblivionPerfFix.ini for the run")
    p.add_argument("--launch-timeout", type=float, default=240)
    p.add_argument("--steam", default="steam")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--game-dir", help="game folder (default: $OBLIVION_GAME_DIR, the Shared library, Steam's libraries)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("setup", help="download and check UE4SS")
    p.add_argument("--zip", help="use this UE4SS_v3.0.1-<build>-g<commit>.zip instead of downloading")
    p.add_argument("--update", action="store_true", help="look for a newer build even if one is unpacked")
    p.add_argument("--allow-unverified", action="store_true")
    sub.add_parser("install-ue4ss", help="put UE4SS and the OblvBench mod into the game folder")
    sub.add_parser("remove-ue4ss", help="take them out again")
    sub.add_parser("status")
    p = sub.add_parser("restore", help="put back the ini, config and saves a killed run left changed")
    p.add_argument("--ue4ss", action="store_true", help="also remove UE4SS")
    p = sub.add_parser("list")
    p.add_argument("--scenario")
    p.add_argument("--scenes", action="append")
    p.add_argument("--tags", action="append")
    add_random_args(p)
    p.set_defaults(scenario=None)
    p = sub.add_parser("run", help="one run in one game session")
    add_run_args(p)
    add_random_args(p)
    p.add_argument("--fix", choices=["on", "fix", "stock", "off"], default="on",
                   help="on/fix: the ini as installed; stock: every switch 0 but FrameRateLimitAtStart; off: DLL not loaded")
    p = sub.add_parser("spin", help="one spot, camera spinning in laps, settings flipped live in ABBA order")
    add_run_args(p)
    p.set_defaults(scenario="linux-hotspots")
    add_random_args(p, spin=True)
    p.add_argument("--scene", help="a static scene of --scenario: its place, hour and weather")
    p.add_argument("--pos", help="x,y,z instead of --scene (with --heading and --world or --cell)")
    p.add_argument("--heading", type=float, help="start heading in degrees (0 = north, 90 = east); default: the scene's")
    p.add_argument("--world", help="with --pos: the worldspace to teleport to (e.g. Tamriel)")
    p.add_argument("--cell", help="with --pos: an interior cell to teleport to")
    p.add_argument("--hour", help="with --pos (or to override the scene): game hour to pin")
    p.add_argument("--weather", help="with --pos (or to override the scene): a weather name of the scenario (Clear...)")
    p.add_argument("--deg-per-sec", type=float, default=30, help="turn rate (default 30 = 12 s per lap)")
    p.add_argument("--pitch", type=float, default=0, help="camera pitch in degrees (default 0)")
    p.add_argument("--variant", action="append", metavar="NAME:ini|cvar:K=V,...",
                   help="a setting set to flip live, e.g. nopar:ini:RdgParallelTranslate=0 or lowlod:cvar:r.ViewDistanceScale=0.5 "
                        "(repeatable; `base` = as installed is always the first)")
    p.add_argument("--rounds", type=int, default=2, help="each round runs the variants forward then backward (default 2: A B B A A B B A)")
    p.add_argument("--laps", type=int, default=2, help="full laps measured per slot (default 2)")
    p.add_argument("--settle", type=float, default=4, help="seconds after a switch before the measured laps (default 4)")
    p.add_argument("--cam-lag", type=float, default=0.3, help="seconds the smoothed camera trails the sent heading (default 0.3)")
    p.add_argument("--look-ms", type=float, default=75, help="interval between heading updates sent to the game (default 75)")
    p.add_argument("--shots", action="store_true",
                   help="after every slot, grab the window at fixed headings (camera held still) and compare each variant with base: "
                        "SSIM against the base-vs-base noise floor, side-by-side pictures, images.md, a GAIN/COST verdict")
    p.add_argument("--shot-headings", metavar="H,H,...", help="headings to capture (default: the 8 sector centres 0,45,...,315)")
    p.add_argument("--shot-settle", type=float, default=1.0, help="seconds the camera holds a heading before the grab (default 1.0)")
    p.add_argument("--shot-width", type=int, default=960, help="capture is block-averaged to about this width (default 960)")
    p.add_argument("--shot-pairs", type=int, default=2, help="slot pairs compared per heading (default 2; more = slower, steadier)")
    p.add_argument("--turn-settle", action="store_true",
                   help="after every slot (outside the fps laps) snap-turn the camera and capture the window for a few seconds: "
                        "how long until the picture stops changing (late pop-in, lighting filling in); settle s, AUC, pops per variant")
    p.add_argument("--turn-headings", metavar="H,H,...", help="headings to snap to (default 0,90,180,270)")
    p.add_argument("--turn-hold", type=float, default=4.0, help="seconds the camera waits facing away before each snap (default 4)")
    p.add_argument("--turn-from", choices=["back", "side"], default="back",
                   help="wait facing away 180 deg (back, default) or 90 deg to the left (side) of the target heading")
    p.add_argument("--turn-interval", type=float, default=0.1, help="seconds between captures after the snap (default 0.1; grabs slower than this just run back to back)")
    p.add_argument("--turn-secs", type=float, default=3.0, help="seconds captured after the snap (default 3)")
    p.add_argument("--turn-width", type=int, default=320, help="turn captures are block-averaged to about this width (default 320: faster grabs)")
    p.add_argument("--diff-thresh", type=int, default=24, help="luminance difference (0-255) that counts as a strongly different pixel (default 24)")
    p.add_argument("--shot-still", type=float, default=1.0, help="a shot is taken when two consecutive grabs differ by at most this mean luminance (default 1.0)")
    p.add_argument("--no-register", action="store_true", help="compare shots as captured, without estimating the shift between them")
    p.add_argument("--reg-search", type=int, default=24, help="registration search range in pixels (default 24)")
    p.add_argument("--ssim-max-drop", type=float, default=0.015, help="COST when the SSIM drop beyond the noise floor exceeds this (default 0.015)")
    p.add_argument("--gain-fps", type=float, default=5.0, help="GAIN when avg fps rises by at least this %% (default 5)")
    p.add_argument("--gain-lows", type=float, default=10.0, help="GAIN when 1%% / 0.1%% low rises by at least this %% (default 10)")
    p.add_argument("--gain-hitches", type=float, default=25.0, help="GAIN when hitches fall by at least this %% (default 25)")
    p = sub.add_parser("reshots", help="re-run the --shots image comparison (with registration) of a finished spin run into <run>-reshots")
    p.add_argument("run", help="spin run folder or label")
    p.add_argument("--out", help="output folder (default <run>-reshots next to it)")
    p.add_argument("--shot-pairs", type=int, help="slot pairs per heading (default: as run)")
    p.add_argument("--diff-thresh", type=int, help="strongly-different luminance threshold (default: as run)")
    p.add_argument("--ssim-max-drop", type=float, help="COST threshold (default: as run)")
    p.add_argument("--no-register", action="store_true", help="no registration (as the original comparison)")
    p.add_argument("--reg-search", type=int, default=24, help="registration search range in pixels (default 24)")
    p = sub.add_parser("ab", help="alternate A and B in fresh games, then report")
    add_run_args(p)
    add_random_args(p)
    p.add_argument("--rounds", type=int, default=2)
    p.add_argument("--a", default="stock", metavar="SIDE", help="on | stock | off | dll:PATH[@stock] (default stock)")
    p.add_argument("--b", default="on", metavar="SIDE", help="on | stock | off | dll:PATH[@stock] (default on)")
    p.add_argument("--a-ini", action="append", metavar="KEY=VAL[,KEY=VAL]",
                   help="[Fixes] keys for side A only (on top of --fix-ini, which applies to both)")
    p.add_argument("--b-ini", action="append", metavar="KEY=VAL[,KEY=VAL]", help="the same for side B")
    p.add_argument("--name-a", help="name of side A in the report (default: its --a mode plus its --a-ini)")
    p.add_argument("--name-b", help="name of side B in the report")
    p = sub.add_parser("report", help="compare existing runs")
    p.add_argument("--a", action="append", required=True, help="run labels or folders, comma separated")
    p.add_argument("--b", action="append", required=True)
    p.add_argument("--name-a", default="A")
    p.add_argument("--name-b", default="B")
    p.add_argument("--label", default="report")
    p.add_argument("--redetail", action="store_true",
                   help="recompute the detail numbers from the stored detailSeries with the current analysis")
    p = sub.add_parser("redetail", help="re-analyse the stored detail series of runs into <run>-redetail folders")
    p.add_argument("runs", nargs="+", help="run labels or folders (comma separated or several)")
    a = ap.parse_args(argv)
    if a.cmd == "ab":
        try:
            a.fix = dllvariant.parse_side(a.a)[0]
            dllvariant.parse_side(a.b)
        except ValueError as e:
            ap.error(str(e))
    paths = Paths(game_dir=a.game_dir) if a.game_dir else Paths()

    def stop(signum, frame):
        raise KeyboardInterrupt
    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)

    handlers = {"setup": cmd_setup, "status": cmd_status, "restore": cmd_restore, "list": cmd_list, "run": cmd_run,
                "ab": cmd_ab, "spin": cmd_spin, "reshots": cmd_reshots, "report": cmd_report, "redetail": cmd_redetail,
                "install-ue4ss": lambda a, p: installer(p).install(),
                "remove-ue4ss": lambda a, p: installer(p).remove()}
    try:
        return handlers[a.cmd](a, paths) or 0
    except KeyboardInterrupt:
        say("stopped (game closed and files restored where a run was going)")
        return 130


if __name__ == "__main__":
    sys.exit(main())
