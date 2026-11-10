"""The file bridge to the OblvBench UE4SS mod (port of Send-Bench & co. in tools/BenchBridge.ps1).

The runner appends "<id> <verb> <args>" lines to bench-commands.txt; the mod answers in bench.log with
"<clock> ACK <id> OK|ERR <text>" and logs events as "<clock> EV <text>" (clock = the mod's os.clock() seconds).
The mod starts reading at the end of the command file as it was when the game started, and starts over when the
file shrinks, so both files are emptied before each game start."""
import re
import time
from datetime import datetime


class BenchError(Exception):
    """A command answered ERR or got no answer."""


class GameDown(Exception):
    """The game exited, hung or stalled (the watchdog's verdict)."""


class Deadline(Exception):
    """The run passed its time limit."""


class NeedsUser(Exception):
    """The game waits for something only the player can do (first-start screens)."""


def parse_state(text):
    """"k=v k=v ..." -> dict (ConvertFrom-BenchState)."""
    return dict(re.findall(r"(\w+)=(\S*)", text or ""))


def parse_events(text):
    """[(clock, text)] of the "EV ..." lines in a chunk of bench.log."""
    out = []
    for line in text.splitlines():
        m = re.match(r"^(\S+) EV (.*)$", line)
        if m:
            try:
                out.append((float(m.group(1)), m.group(2).rstrip("\r")))
            except ValueError:
                pass
    return out


class Bridge:
    def __init__(self, paths, check=None, sleep=time.sleep):
        """check(): raises GameDown/Deadline when the game can no longer answer (the watchdog), or None."""
        self.cmd_file = paths.cmd_file
        self.log_file = paths.log_file
        self.check = check or (lambda: None)
        self.sleep = sleep
        now = datetime.now()
        self.next_id = (now.hour * 3600 + now.minute * 60 + now.second) * 100
        # (wall time when the answer was seen, mod clock in the answer): ties the mod's clock to time.time()
        self.clock_samples = []

    def reset_files(self):
        """Before a game start: the mod treats existing commands as not its own."""
        self.cmd_file.parent.mkdir(parents=True, exist_ok=True)
        self.cmd_file.write_bytes(b"")
        self.log_file.write_bytes(b"")

    def log_length(self):
        try:
            return self.log_file.stat().st_size
        except OSError:
            return 0

    def read_log_from(self, pos):
        try:
            with open(self.log_file, "rb") as f:
                f.seek(pos)
                return f.read().decode("utf-8", errors="replace")
        except OSError:
            return ""

    def events(self, pos):
        return parse_events(self.read_log_from(pos))

    def _append(self, line):
        with open(self.cmd_file, "ab") as f:
            f.write((line + "\n").encode("utf-8"))

    def send(self, command, timeout=8.0, nothrow=False):
        """Sends a command and returns the mod's answer text. Raises BenchError on ERR or timeout unless nothrow
        (then None); GameDown/Deadline from check() always propagate unless nothrow."""
        self.next_id += 1
        cid = self.next_id
        try:
            self.check()
        except (GameDown, Deadline):
            if nothrow:
                return None
            raise
        pos = self.log_length()
        self._append(f"{cid} {command}")
        rx = re.compile(r"(?m)^(\S+) ACK %d (OK|ERR) ?(.*?)\r?$" % cid)
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            m = rx.search(self.read_log_from(pos))
            if m:
                seen = time.time()
                text = m.group(3)
                c = re.search(r"\bclock=([\d.]+)", text)
                if c:
                    self.clock_samples.append((seen, float(c.group(1))))
                if m.group(2) == "OK":
                    return text
                if nothrow:
                    return None
                raise BenchError(f"'{command}' failed: {text}")
            try:
                self.check()
            except (GameDown, Deadline):
                if nothrow:
                    return None
                raise
            self.sleep(0.015)
        if nothrow:
            return None
        raise BenchError(f"no answer to '{command}' within {timeout:.0f} s (game stalled, or mod not loaded)")

    def get(self, name, timeout=8.0):
        """A console variable's value as text ("get <cvar>" answers "<cvar>=<value>"), or None."""
        a = self.send(f"get {name}", timeout=timeout, nothrow=True)
        return None if a is None else re.sub(r"^.*=", "", a)

    def state(self, light=False, timeout=8.0):
        a = self.send("where" if light else "state", timeout=timeout, nothrow=True)
        return None if a is None else parse_state(a)

    def wait_state(self, cond, timeout=60.0, stable=1, poll=0.2):
        """Polls until cond(state) has held for `stable` polls in a row; the last state, or None on timeout."""
        end = time.monotonic() + timeout
        ok = 0
        while time.monotonic() < end:
            self.check()
            s = self.state(timeout=3.0)
            if s and cond(s):
                ok += 1
                if ok >= stable:
                    return s
            else:
                ok = 0
            self.sleep(poll)
        return None

    def wait_event(self, pos, pattern, timeout):
        """First event after log position pos whose text matches; (clock, text) or None."""
        rx = re.compile(pattern)
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            for ev in self.events(pos):
                if rx.search(ev[1]):
                    return ev
            self.check()
            self.sleep(0.1)
        return None

    def clock_offset(self):
        """(offset, spread): wall = clock + offset, from the answers that carried the mod's clock (ping, fly, walk).
        The earliest-seen answer is the tightest bound (answers are seen up to ~20 ms late), so the minimum is used."""
        if not self.clock_samples:
            return None, None
        offs = [w - c for w, c in self.clock_samples]
        return min(offs), max(offs) - min(offs)

    def clock_rate(self):
        """Mod-clock seconds per wall second between the first and last sample (1.0 if os.clock() is wall time)."""
        if len(self.clock_samples) < 2:
            return None
        (w0, c0), (w1, c1) = self.clock_samples[0], self.clock_samples[-1]
        if w1 - w0 < 5:
            return None
        return (c1 - c0) / (w1 - w0)
