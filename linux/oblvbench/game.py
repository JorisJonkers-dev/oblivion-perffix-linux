"""The game process under Proton: launch through Steam, find, watch, stop."""
import os
import signal
import subprocess
import threading
import time
from pathlib import Path

from .paths import APP_ID, GAME_PGREP
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
