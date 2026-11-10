import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from fakemod import FakeMod  # noqa: E402
from oblvbench.paths import Paths  # noqa: E402
from oblvbench.protocol import BenchError, Bridge, GameDown, parse_events, parse_state  # noqa: E402


def handlers():
    return {
        "ping": lambda m, r: f"pong clock={m.clock():.3f} driver=frame frames=10 loops_per_s=60.0",
        "state": lambda m, r: "pc=1 level=L_Tamriel pawn=1 x=1.5 y=2 z=3 frozen=0 loadscreen=0 travel=0",
        "where": lambda m, r: "pc=1 level=L_Tamriel pawn=1 x=1.5 y=2 z=3",
        "get": lambda m, r: f"{r}=42",
        "bad": lambda m, r: (False, "nope"),
        "silent": lambda m, r: None,
        "fly": lambda m, r: (m.log("EV fly=start"), m.log("EV fly=done reason=arrived"), f"flying clock={m.clock():.3f} secs=1")[-1],
    }


class ProtocolTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.paths = Paths(game_dir=self.tmp.name, runtime=Path(self.tmp.name) / "run")
        self.bridge = Bridge(self.paths)
        self.bridge.reset_files()
        self.mod = FakeMod(self.paths.cmd_file, self.paths.log_file, handlers())
        self.mod.start()

    def tearDown(self):
        self.mod.stop()
        self.mod.join(1)
        self.tmp.cleanup()

    def test_ok_answer(self):
        self.assertTrue(self.bridge.send("ping").startswith("pong"))
        self.assertEqual(self.mod.received[0][0], "ping")

    def test_ids_increase_and_answers_match(self):
        for _ in range(5):
            self.assertEqual(self.bridge.get("t.MaxFPS"), "42")
        lines = self.paths.cmd_file.read_text().splitlines()
        ids = [int(l.split()[0]) for l in lines]
        self.assertEqual(ids, sorted(set(ids)))

    def test_err_raises_or_none(self):
        with self.assertRaises(BenchError):
            self.bridge.send("bad")
        self.assertIsNone(self.bridge.send("bad", nothrow=True))
        with self.assertRaises(BenchError):
            self.bridge.send("nosuchverb")

    def test_timeout(self):
        t = time.monotonic()
        with self.assertRaises(BenchError):
            self.bridge.send("silent", timeout=0.5)
        self.assertLess(time.monotonic() - t, 2)
        self.assertIsNone(self.bridge.send("silent", timeout=0.3, nothrow=True))

    def test_check_aborts_wait(self):
        def down():
            raise GameDown("exited")
        self.bridge.check = down
        with self.assertRaises(GameDown):
            self.bridge.send("silent", timeout=5)
        self.assertIsNone(self.bridge.send("silent", timeout=5, nothrow=True))

    def test_state_and_wait_state(self):
        s = self.bridge.state()
        self.assertEqual(s["level"], "L_Tamriel")
        self.assertEqual(s["x"], "1.5")
        got = self.bridge.wait_state(lambda s: s.get("pawn") == "1", timeout=5, stable=3, poll=0.01)
        self.assertIsNotNone(got)
        self.assertIsNone(self.bridge.wait_state(lambda s: s.get("pawn") == "0", timeout=0.5, poll=0.05))

    def test_events_and_clock(self):
        pos = self.bridge.log_length()
        a = self.bridge.send("fly x")
        self.assertIn("secs=1", a)
        ev = self.bridge.wait_event(pos, r"^fly=done", 2)
        self.assertIsNotNone(ev)
        self.assertIn("reason=arrived", ev[1])
        self.bridge.send("ping")
        off, spread = self.bridge.clock_offset()
        self.assertAlmostEqual(off, self.mod.t0, delta=0.2)    # wall = clock + offset

    def test_mod_ignores_commands_before_its_start(self):
        self.mod.stop()
        self.mod.join(1)
        self.paths.cmd_file.write_text("1 ping\n")
        mod2 = FakeMod(self.paths.cmd_file, self.paths.log_file, handlers())
        mod2.start()
        try:
            self.bridge.send("ping")
            self.assertEqual(len(mod2.received), 1)
        finally:
            mod2.stop()


class ParseTest(unittest.TestCase):
    def test_parse_state(self):
        self.assertEqual(parse_state("a=1 b=L_X c="), {"a": "1", "b": "L_X", "c": ""})
        self.assertEqual(parse_state(None), {})

    def test_parse_events(self):
        text = "1.000 ACK 5 OK x\n2.500 EV fly=start\r\nbad EV x\n3.25 EV cell=Foo bar\n"
        self.assertEqual(parse_events(text), [(2.5, "fly=start"), (3.25, "cell=Foo bar")])


if __name__ == "__main__":
    unittest.main()
