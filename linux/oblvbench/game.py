"""The game process under Proton: launch through Steam, find, watch, stop."""
import os
import re
import signal
import subprocess
import threading
import time
from dataclasses import dataclass
from pathlib import Path

from .paths import APP_ID, GAME_PGREP, GAME_PROCESS
from .protocol import Deadline, GameDown


def find_game_pids(pattern=GAME_PGREP):
    try:
        r = subprocess.run(["pgrep", "-f", pattern], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return []
    return [int(x) for x in r.stdout.split()]


def find_game_pid():
    pids = find_game_pids()
    return min(pids) if pids else None


def pid_alive(pid):
    try:
        with open(f"/proc/{pid}/stat") as f:
            return f.read().split(") ", 1)[1][0] != "Z"     # a zombie has exited
    except (OSError, IndexError):
        return False


def cmdline(pid):
    try:
        return Path(f"/proc/{pid}/cmdline").read_bytes().replace(b"\0", b" ").decode(errors="replace").strip()
    except OSError:
        return ""


def process_start_wall(pid):
    """Wall-clock start of a process (boot time + start ticks), to about 10 ms."""
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().split(") ", 1)[1].split()
        ticks = int(fields[19])
        btime = next(int(l.split()[1]) for l in Path("/proc/stat").read_text().splitlines() if l.startswith("btime"))
        return btime + ticks / os.sysconf("SC_CLK_TCK")
    except (OSError, IndexError, ValueError, StopIteration):
        return None


def launch_via_steam(steam="steam", args=()):
    """Asks the running Steam to start the game (steam://rungameid). Steam's own launch options (the
    oblivion-launch.sh wrapper) apply. Returns at once; the client hands the URL to the running instance."""
    cmd = [steam, f"steam://rungameid/{APP_ID}", *args]
    try:
        p = subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
    except OSError as e:
        raise RuntimeError(f"could not run {steam}: {e}")
    try:
        p.wait(timeout=20)
    except subprocess.TimeoutExpired:
        pass   # a Steam that was not running stays in the foreground: leave it


def stop_pid(pid, grace=15.0):
    """SIGTERM, then SIGKILL after `grace` seconds. True once gone."""
    for sig, wait in ((signal.SIGTERM, grace), (signal.SIGKILL, 10.0)):
        if not pid_alive(pid):
            return True
        try:
            os.kill(pid, sig)
        except ProcessLookupError:
            return True
        except PermissionError:
            return False
        end = time.monotonic() + wait
        while time.monotonic() < end:
            if not pid_alive(pid):
                return True
            time.sleep(0.25)
    return not pid_alive(pid)


def wait_gone(pid, timeout):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if not pid_alive(pid):
            return True
        time.sleep(0.25)
    return False


# ------------------------------------------------------------ leftovers of an earlier session

STEAM_CONSOLE_LOG = Path("~/.local/share/Steam/logs/console_log.txt").expanduser()
CRASH_REPORTER = "CrashReportClient"
REAPER_RE = re.compile(r"\breaper\b.*\bSteamLaunch\b")


class LiveGameError(RuntimeError):
    """The game is still running: the leftovers are left alone."""


@dataclass
class Leftover:
    pid: int
    role: str        # game | crash-reporter | reaper | helper
    cmd: str


def list_pids():
    try:
        return [int(d) for d in os.listdir("/proc") if d.isdigit()]
    except OSError:
        return []


def proc_environ(pid):
    """The environment a process started with, or None when it cannot be read."""
    try:
        raw = Path(f"/proc/{pid}/environ").read_bytes()
    except OSError:
        return None
    env = {}
    for item in raw.split(b"\0"):
        k, sep, v = item.partition(b"=")
        if sep:
            env[k.decode(errors="replace")] = v.decode(errors="replace")
    return env


def _role(cmd, env_match, app_id):
    if GAME_PROCESS in cmd:
        return "game"
    if CRASH_REPORTER in cmd:
        return "crash-reporter"
    if REAPER_RE.search(cmd) and f"AppId={app_id}" in cmd:
        return "reaper"
    return "helper" if env_match else None


def find_leftovers(app_id=APP_ID):
    """Processes of this game's Proton session: those started with SteamGameId / SteamAppId = app_id, and Steam's
    reaper for the app (it may not carry the variables). Read only."""
    found = []
    for pid in list_pids():
        env = proc_environ(pid)
        env_match = bool(env) and (env.get("SteamGameId") == str(app_id) or env.get("SteamAppId") == str(app_id))
        cmd = cmdline(pid)
        if not env_match and not (REAPER_RE.search(cmd) and f"AppId={app_id}" in cmd):
            continue
        role = _role(cmd, env_match, app_id)
        if role:
            found.append(Leftover(pid, role, cmd))
    return found


def reap_session(say=print, app_id=APP_ID, reaper_wait=20.0):
    """Clears what a crashed session left behind. Refuses (LiveGameError) while the game exe runs: the user may be
    playing. Otherwise the crash reporter is ended (SIGTERM, SIGKILL after 5 s) and the wait is up to `reaper_wait`
    seconds for Steam's reaper of the app to exit. Returns what was found and what became of it."""
    found = find_leftovers(app_id)
    res = {"found": [f"{l.pid} {l.role}" for l in found], "terminated": [], "reaperGone": True}
    if not found:
        return res
    for l in found:
        say(f"leftover of the game session: pid {l.pid} ({l.role}) {l.cmd[:120]}")
    live = [l for l in found if l.role == "game" and pid_alive(l.pid)]
    if live:
        raise LiveGameError(f"the game is still running (pid {live[0].pid}): not touching its session; "
                            "close the game first")
    for l in found:
        if l.role == "crash-reporter" and pid_alive(l.pid):
            say(f"ending the crash reporter (pid {l.pid})")
            stop_pid(l.pid, grace=5.0)
            res["terminated"].append(l.pid)

    def reapers():
        return [l for l in find_leftovers(app_id) if l.role == "reaper"]

    end = time.monotonic() + reaper_wait
    while reapers() and time.monotonic() < end:
        time.sleep(0.25)
    left = reapers()
    res["reaperGone"] = not left
    if left:
        say(f"Steam's reaper for AppId {app_id} is still running after {reaper_wait:.0f} s (pid {left[0].pid})")
    return res


def steam_log_size(path=STEAM_CONSOLE_LOG):
    try:
        return Path(path).stat().st_size
    except OSError:
        return 0


def steam_log_since(pos, path=STEAM_CONSOLE_LOG):
    """Steam's console log written after byte `pos` (from the start if the log was truncated since)."""
    try:
        with open(path, "rb") as f:
            size = f.seek(0, os.SEEK_END)
            f.seek(pos if pos <= size else 0)
            return f.read().decode(errors="replace")
    except OSError:
        return ""


def waiting_prev_process(text, app_id=APP_ID):
    """True when Steam reports that the app waits for a previous process of it to exit."""
    return any("WaitingPrevProcess" in line and f"AppID {app_id}" in line for line in text.splitlines())


def newest_crash_folder(crashes_dir, since):
    """Name of the newest folder in the prefix's Saved/Crashes modified at or after `since`, or None."""
    try:
        dirs = [d for d in Path(crashes_dir).iterdir() if d.is_dir() and d.stat().st_mtime >= since]
    except OSError:
        return None
    return max(dirs, key=lambda d: d.stat().st_mtime).name if dirs else None


class Watchdog(threading.Thread):
    """Notices that the game exited or stopped running frames: the mod rewrites bench-heartbeat.txt once a second
    ("<clock> <frames> <driver> <state>"); no new frames for stall_sec (default 30, as upstream's GameWatch) is a
    stall. Before the first heartbeat only the process is checked (start-up, shader screen)."""

    def __init__(self, pid, heartbeat_file, stall_sec=30.0, deadline=None):
        super().__init__(daemon=True)
        self.pid = pid
        self.heartbeat_file = Path(heartbeat_file)
        self.stall_sec = stall_sec
        self.deadline = deadline          # time.time() limit for the whole run, or None
        self.problem = None
        self.first_heartbeat = None       # wall time the first heartbeat was seen
        self.frames = None
        self._last_change = time.monotonic()
        self._stop = threading.Event()

    def read_heartbeat(self):
        try:
            parts = self.heartbeat_file.read_text().split()
            return float(parts[0]), int(parts[1])
        except (OSError, ValueError, IndexError):
            return None

    def run(self):
        while not self._stop.wait(0.5):
            if not pid_alive(self.pid):
                self.problem = "exited: the game process is gone"
                return
            hb = self.read_heartbeat()
            if hb is None:
                continue
            if self.first_heartbeat is None:
                self.first_heartbeat = time.time()
            if hb[1] != self.frames:
                self.frames = hb[1]
                self._last_change = time.monotonic()
            elif time.monotonic() - self._last_change > self.stall_sec:
                self.problem = f"stalled: no new frame for {self.stall_sec:.0f} s (frames={self.frames})"
                return

    def stop(self):
        self._stop.set()

    def check(self):
        if self.problem:
            raise GameDown(self.problem)
        if self.deadline and time.time() > self.deadline:
            raise Deadline("the run passed its time limit")
