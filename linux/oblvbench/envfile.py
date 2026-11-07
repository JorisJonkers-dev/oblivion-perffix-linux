"""The env file that linux/oblivion-launch.sh sources at game start (~/.config/oblivion-bench/env).

bench.py writes it just before it asks Steam to start the game and removes it as soon as the game process is up,
so a game the player starts later runs as normal. It also carries an expiry time: the launch script ignores a file
left behind by a runner that was killed before it could remove it."""
import os
import shlex
import time
from pathlib import Path

FIX_MODES = ("on", "fix", "stock", "off")


def dll_overrides(fix_mode, ue4ss=True):
    """WINEDLLOVERRIDES for a run. version.dll is OblivionPerfFix's proxy: n,b loads it (fix and stock, which differ
    only in the ini), b keeps Wine's own (off: the DLL is not loaded at all). dwmapi.dll is UE4SS's proxy."""
    if fix_mode not in FIX_MODES:
        raise ValueError(f"fix mode must be one of {', '.join(FIX_MODES)}")
    parts = ["version=b" if fix_mode == "off" else "version=n,b"]
    if ue4ss:
        parts.append("dwmapi=n,b")
    return ";".join(parts)


def build_env(fix_mode, mangohud_config=None, ue4ss=True, game_args=("-FixedSeed",), marker=None):
    env = {"WINEDLLOVERRIDES": dll_overrides(fix_mode, ue4ss)}
    if mangohud_config:
        env["MANGOHUD"] = "1"
        env["MANGOHUD_CONFIGFILE"] = str(mangohud_config)
    if game_args:
        env["OBLV_GAME_ARGS"] = " ".join(game_args)
    if marker:
        env["OBLV_BENCH_MARKER"] = str(marker)
    return env


def render(env, expires):
    lines = ["# written by linux/bench.py for one benchmark launch; removed once the game is up",
             f"export OBLV_BENCH_EXPIRES={int(expires)}"]
    lines += [f"export {k}={shlex.quote(str(v))}" for k, v in env.items()]
    return "\n".join(lines) + "\n"


def write_env(path, env, ttl=600):
    """Writes the env file atomically; it is honoured for `ttl` seconds from now."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(render(env, time.time() + ttl))
    os.replace(tmp, path)


def clear_env(path):
    """Removes the env file (the launch script then behaves like the normal game)."""
    try:
        Path(path).unlink()
    except FileNotFoundError:
        pass


def parse_env(path):
    """{name: value} of the export lines (for tests and `bench.py status`)."""
    out = {}
    try:
        text = Path(path).read_text()
    except OSError:
        return out
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("export "):
            continue
        name, _, value = line[len("export "):].partition("=")
        parts = shlex.split(value)
        out[name] = parts[0] if parts else ""
    return out
