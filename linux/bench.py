#!/usr/bin/env python3
"""OblivionPerfFix benchmark on Linux (Steam + Proton): the Linux replacement for tools/Run-Benchmark.ps1 and
tools/Bench-Report.ps1. Standard library only. See linux/README.md.

  bench.py setup                         download + check UE4SS into linux/third_party/
  bench.py install-ue4ss | remove-ue4ss  put UE4SS + the OblvBench mod into the game folder / take them out
  bench.py status | restore              what is in place / put back files a killed run left changed
  bench.py list [--scenario S]           scenarios, scenes, profiles
  bench.py run --scenario showcase --fix stock --label s1
  bench.py ab --scenario showcase --rounds 2 --a stock --b on
  bench.py report --a s1,s2 --b f1,f2
"""
import argparse
import signal
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from oblvbench import envfile, fixini, game, scenario, ue4ss  # noqa: E402
from oblvbench.paths import Paths  # noqa: E402
from oblvbench.report import load_runs, write_comparison  # noqa: E402
from oblvbench.runner import Options, Runner  # noqa: E402
from oblvbench.saves import SaveGuard  # noqa: E402


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


def run_options(a, **over):
    kw = dict(scenario=a.scenario, scenes=split_list(a.scenes), tags=split_list(a.tags), start=a.start,
              label=a.label, fix=a.fix, profile=a.profile, warmup=a.warmup, keep_ue4ss=a.keep_ue4ss,
              show_hud=a.show_hud, pin=not a.no_pin, fixed_seed=not a.no_fixed_seed, native_res=a.native_res,
              stall_sec=a.stall_sec, max_minutes=a.max_minutes, launch_timeout=a.launch_timeout, steam=a.steam)
    kw.update(over)
    return Options(**kw)


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


def cmd_list(a, paths):
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
    r = Runner(paths, run_options(a), say=say).run()
    return 0 if r["outcome"] == "ok" else (1 if r["outcome"] == "partial" else 2)


def cmd_ab(a, paths):
    inst = installer(paths)
    names = {a.a: [], a.b: []}
    stamp = time.strftime("%m%d-%H%M")
    code = 0
    try:
        inst.install()
        for rnd in range(1, a.rounds + 1):
            for side in (a.a, a.b):
                label = f"{a.label}-{stamp}-{side}-r{rnd}"
                say(f"== round {rnd}/{a.rounds}: {side} ({label})")
                r = Runner(paths, run_options(a, label=label, fix=side, keep_ue4ss=True), say=say).run()
                if r["outcome"] == "failed":
                    raise SystemExit(f"run {label} failed: {r.get('error')} (see its report.md)")
                code = max(code, 0 if r["outcome"] == "ok" else 1)
                names[side].append(label)
                time.sleep(10)          # let Steam see the game end before the next launch
    finally:
        if not a.keep_ue4ss:
            try:
                inst.remove()
            except Exception as e:
                say(f"WARNING: UE4SS not removed: {e}")
    d = write_comparison(load_runs(names[a.a], paths.results), load_runs(names[a.b], paths.results), a.a, a.b,
                         paths.results, a.label)
    say(f"REPORT {d / 'report.md'}")
    print((d / "report.md").read_text())
    return code


def cmd_report(a, paths):
    runs_a, runs_b = load_runs(split_list(a.a), paths.results), load_runs(split_list(a.b), paths.results)
    d = write_comparison(runs_a, runs_b, a.name_a, a.name_b, paths.results, a.label)
    say(f"REPORT {d / 'report.md'}")
    print((d / "report.md").read_text())


def add_run_args(p):
    p.add_argument("--scenario", default="cheydinhal")
    p.add_argument("--scenes", action="append", help="scene ids, comma separated, wildcards allowed")
    p.add_argument("--tags", action="append")
    p.add_argument("--start", choices=["fresh", "continue"], help="default: the scenario's, else fresh")
    p.add_argument("--profile", help="bench/profiles.json (default: the scenario's, else small)")
    p.add_argument("--label", default="run")
    p.add_argument("--warmup", type=float, default=60, help="seconds in the world before the first scene (default 60)")
    p.add_argument("--native-res", default="2560x1440", help="what profile res 'native' means (default 2560x1440)")
    p.add_argument("--keep-ue4ss", action="store_true", help="leave UE4SS in the game folder afterwards")
    p.add_argument("--show-hud", action="store_true", help="show the MangoHud overlay (default: logging only)")
    p.add_argument("--no-pin", action="store_true", help="do not pin weather/hour/timescale")
    p.add_argument("--no-fixed-seed", action="store_true", help="launch without -FixedSeed")
    p.add_argument("--stall-sec", type=float, default=30, help="watchdog: no new frame for this long = stalled")
    p.add_argument("--max-minutes", type=float, default=0, help="time limit of one run (0: from the scene estimate)")
    p.add_argument("--fix-ini", action="append", metavar="KEY=VAL[,KEY=VAL]",
                   help="set [Fixes] keys in OblivionPerfFix.ini for this run only (restored afterwards)")
    p.add_argument("--diag", action="store_true",
                   help="engine diagnostics: HitchLedger + HitchLedgerTickSplit, copied and ranked into the run folder")
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
    p = sub.add_parser("run", help="one run in one game session")
    add_run_args(p)
    p.add_argument("--fix", choices=["on", "fix", "stock", "off"], default="on",
                   help="on/fix: the ini as installed; stock: every switch 0 but FrameRateLimitAtStart; off: DLL not loaded")
    p = sub.add_parser("ab", help="alternate A and B in fresh games, then report")
    add_run_args(p)
    p.add_argument("--rounds", type=int, default=2)
    p.add_argument("--a", default="stock", choices=["on", "stock", "off"])
    p.add_argument("--b", default="on", choices=["on", "stock", "off"])
    p = sub.add_parser("report", help="compare existing runs")
    p.add_argument("--a", action="append", required=True, help="run labels or folders, comma separated")
    p.add_argument("--b", action="append", required=True)
    p.add_argument("--name-a", default="A")
    p.add_argument("--name-b", default="B")
    p.add_argument("--label", default="report")
    a = ap.parse_args(argv)
    if a.cmd == "ab":
        a.fix = a.a
        if a.a == a.b:
            ap.error("--a and --b must differ")
    paths = Paths(game_dir=a.game_dir) if a.game_dir else Paths()

    def stop(signum, frame):
        raise KeyboardInterrupt
    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, stop)

    handlers = {"setup": cmd_setup, "status": cmd_status, "restore": cmd_restore, "list": cmd_list, "run": cmd_run,
                "ab": cmd_ab, "report": cmd_report,
                "install-ue4ss": lambda a, p: installer(p).install(),
                "remove-ue4ss": lambda a, p: installer(p).remove()}
    try:
        return handlers[a.cmd](a, paths) or 0
    except KeyboardInterrupt:
        say("stopped (game closed and files restored where a run was going)")
        return 130


if __name__ == "__main__":
    sys.exit(main())
