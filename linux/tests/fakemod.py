"""A stand-in for the OblvBench mod: a thread that reads bench-commands.txt like main.lua (from the end of the file
as it was at start, complete lines only) and answers in bench.log."""
import re
import threading
import time


class FakeMod(threading.Thread):
    def __init__(self, cmd_file, log_file, handlers=None, delay=0.0):
        super().__init__(daemon=True)
        self.cmd_file, self.log_file = cmd_file, log_file
        self.handlers = handlers or {}
        self.delay = delay
        self.t0 = time.time()
        self.received = []
        self._stop = threading.Event()
        try:
            self.offset = cmd_file.stat().st_size
        except OSError:
            self.offset = 0

    def clock(self):
        return time.time() - self.t0

    def log(self, msg):
        with open(self.log_file, "a") as f:
            f.write(f"{self.clock():.3f} {msg}\n")

    def run(self):
        while not self._stop.wait(0.02):
            try:
                data = self.cmd_file.read_bytes()
            except OSError:
                continue
            if len(data) < self.offset:
                self.offset = 0
            chunk = data[self.offset:]
            nl = chunk.rfind(b"\n")
            if nl < 0:
                continue
            self.offset += nl + 1
            for line in chunk[:nl + 1].decode().splitlines():
                self.handle(line)

    def handle(self, line):
        m = re.match(r"^\s*(\d+)\s+(\S+)\s*(.*?)\s*$", line)
        if not m:
            return
        cid, verb, rest = m.groups()
        self.received.append((verb, rest))
        h = self.handlers.get(verb)
        if h is None:
            self.log(f"ACK {cid} ERR unknown verb {verb}")
            return
        if self.delay:
            time.sleep(self.delay)
        res = h(self, rest)
        if res is None:          # no answer (a stalled game)
            return
        ok, text = res if isinstance(res, tuple) else (True, res)
        self.log(f"ACK {cid} {'OK' if ok else 'ERR'} {text}")

    def stop(self):
        self._stop.set()
