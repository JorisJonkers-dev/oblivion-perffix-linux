"""Leftovers of a crashed Proton session: fake /proc entries (the process listing helpers are patched). Live game ->
refuse; only the crash reporter (and Steam's reaper) -> it is ended and the reaper waited for; nothing -> proceed."""
import os
import sys
import tempfile
import time
import types
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from oblvbench import game, runner  # noqa: E402

APP = str(game.APP_ID)
GAME_CMD = "S:\\Oblivion Remastered\\OblivionRemastered\\Binaries\\Win64\\OblivionRemastered-Win64-Shipping.exe -FixedSeed"
CRASH_CMD = "Z:\\run\\Engine\\Binaries\\Win64\\CrashReportClient.exe -Unattended"
REAPER_CMD = "/home/u/.local/share/Steam/ubuntu12_32/reaper SteamLaunch AppId=2623190 -- /usr/bin/wine"
PROTON_CMD = "C:\\windows\\system32\\explorer.exe /desktop"
SESSION_ENV = {"SteamGameId": APP, "SteamAppId": APP, "PATH": "/usr/bin"}
OTHER_ENV = {"SteamGameId": "480", "PATH": "/usr/bin"}


class FakeProc:
    """pid -> (environ or None, cmdline). `stubborn` pids are not ended by stop_pid; `linked` maps a pid to pids that
    go with it (the reaper ends with the crash reporter)."""

    def __init__(self, table, stubborn=(), linked=None):
        self.table = dict(table)
        self.stubborn = set(stubborn)
        self.linked = linked or {}
        self.stopped = []

    def patches(self):
        return [
            mock.patch.object(game, "list_pids", lambda: sorted(self.table)),
            mock.patch.object(game, "proc_environ", lambda pid: self.table[pid][0] if pid in self.table else None),
            mock.patch.object(game, "cmdline", lambda pid: self.table[pid][1] if pid in self.table else ""),
            mock.patch.object(game, "pid_alive", lambda pid: pid in self.table),
            mock.patch.object(game, "stop_pid", self.stop_pid),
        ]

    def stop_pid(self, pid, grace=15.0):
        self.stopped.append((pid, grace))
        if pid in self.stubborn or pid not in self.table:
            return pid not in self.table
        del self.table[pid]
        for other in self.linked.get(pid, ()):
            self.table.pop(other, None)
        return True


class LeftoverTest(unittest.TestCase):
    def run_with(self, fake, fn):
        patches = fake.patches()
        for p in patches:
            p.start()
        try:
            return fn()
        finally:
            for p in patches:
                p.stop()

    def test_live_game_is_refused_and_left_alone(self):
        fake = FakeProc({
            100: (SESSION_ENV, GAME_CMD),
            101: (SESSION_ENV, CRASH_CMD),
            102: (SESSION_ENV, REAPER_CMD),
        })
        said = []
        with self.assertRaises(game.LiveGameError) as cm:
            self.run_with(fake, lambda: game.reap_session(said.append, reaper_wait=0.2))
        self.assertIn("still running (pid 100)", str(cm.exception))
        self.assertEqual(fake.stopped, [])                         # nothing was ended
        self.assertEqual(set(fake.table), {100, 101, 102})
        self.assertTrue(any("(game)" in s for s in said), said)     # what was found is logged

    def test_runner_refuses_before_launch_when_game_runs(self):
        fake = FakeProc({100: (SESSION_ENV, GAME_CMD)})
        stub = types.SimpleNamespace(say=lambda m: None)
        with self.assertRaises(RuntimeError) as cm:
            self.run_with(fake, lambda: runner.Runner.clear_leftovers(stub))
        self.assertIn("close the game first", str(cm.exception))
        self.assertEqual(fake.stopped, [])

    def test_only_crash_reporter_is_terminated_and_reaper_waited_for(self):
        fake = FakeProc({
            200: (SESSION_ENV, CRASH_CMD),
            201: (SESSION_ENV, REAPER_CMD),
            202: (SESSION_ENV, PROTON_CMD),          # session helper, not the reporter: not ended
            203: (OTHER_ENV, CRASH_CMD),             # another game's crash reporter: not ours
        }, linked={200: [201]})                       # the reaper goes once the reporter is gone
        said = []
        res = self.run_with(fake, lambda: game.reap_session(said.append, reaper_wait=5))
        self.assertEqual(fake.stopped, [(200, 5.0)])  # SIGTERM with a 5 s grace, then SIGKILL inside stop_pid
        self.assertEqual(res["terminated"], [200])
        self.assertTrue(res["reaperGone"])
        self.assertIn(203, fake.table)
        self.assertIn(202, fake.table)
        self.assertTrue(any("ending the crash reporter (pid 200)" in s for s in said), said)

    def test_reaper_that_stays_is_reported(self):
        fake = FakeProc({200: (SESSION_ENV, CRASH_CMD), 201: (SESSION_ENV, REAPER_CMD)}, stubborn={200})
        said = []
        res = self.run_with(fake, lambda: game.reap_session(said.append, reaper_wait=0.3))
        self.assertFalse(res["reaperGone"])
        self.assertTrue(any("reaper for AppId 2623190 is still running" in s for s in said), said)

        fake = FakeProc({200: (SESSION_ENV, CRASH_CMD), 201: (SESSION_ENV, REAPER_CMD)}, stubborn={200})
        stub = types.SimpleNamespace(say=lambda m: None)
        with self.assertRaises(RuntimeError) as cm:
            self.run_with(fake, lambda: runner.Runner.clear_leftovers(stub))
        self.assertIn("still running", str(cm.exception))

    def test_nothing_left_proceeds(self):
        fake = FakeProc({300: (OTHER_ENV, GAME_CMD), 301: (None, CRASH_CMD), 302: (SESSION_ENV, "bash")})
        # 302 has our environment but is not a session process of the game's kind: helper, but nothing is ended
        said = []
        res = self.run_with(fake, lambda: game.reap_session(said.append, reaper_wait=0.2))
        self.assertEqual(fake.stopped, [])
        self.assertEqual(res["found"], ["302 helper"])
        stub = types.SimpleNamespace(say=lambda m: None)
        fake = FakeProc({300: (OTHER_ENV, GAME_CMD)})
        self.assertEqual(self.run_with(fake, lambda: runner.Runner.clear_leftovers(stub))["found"], [])

    def test_no_processes_at_all(self):
        fake = FakeProc({})
        res = self.run_with(fake, lambda: game.reap_session(lambda m: None))
        self.assertEqual(res, {"found": [], "terminated": [], "reaperGone": True})


class SteamLogTest(unittest.TestCase):
    LINE = ("[2026-11-07 13:42:19] GameAction [AppID 2623190, ActionID 45] : LaunchApp changed task to "
            "WaitingPrevProcess with \"\"\n")

    def test_waiting_prev_process_detected_only_for_the_app(self):
        self.assertTrue(game.waiting_prev_process(self.LINE))
        other = self.LINE.replace("2623190", "480")
        self.assertFalse(game.waiting_prev_process(other))
        self.assertFalse(game.waiting_prev_process("[x] GameAction [AppID 2623190] : LaunchApp started"))

    def test_only_lines_written_after_the_position_count(self):
        d = Path(tempfile.mkdtemp())
        try:
            log = d / "console_log.txt"
            log.write_text("old line\n")
            pos = game.steam_log_size(log)
            with open(log, "a") as f:
                f.write(self.LINE)
            text = game.steam_log_since(pos, log)
            self.assertNotIn("old line", text)
            self.assertTrue(game.waiting_prev_process(text))
            self.assertFalse(game.waiting_prev_process(game.steam_log_since(0, d / "missing.txt")))
        finally:
            import shutil
            shutil.rmtree(d)

    def test_newest_crash_folder_after_launch(self):
        d = Path(tempfile.mkdtemp())
        try:
            crashes = d / "Crashes"
            (crashes / "UnrealEngine_old").mkdir(parents=True)
            (crashes / "UnrealEngine_new").mkdir()
            (crashes / "UnrealEngine_newest").mkdir()
            now = time.time()
            os.utime(crashes / "UnrealEngine_old", (now - 500, now - 500))
            os.utime(crashes / "UnrealEngine_new", (now - 10, now - 10))
            os.utime(crashes / "UnrealEngine_newest", (now - 5, now - 5))
            self.assertEqual(game.newest_crash_folder(crashes, now - 100), "UnrealEngine_newest")
            self.assertIsNone(game.newest_crash_folder(crashes, now + 1))
            self.assertIsNone(game.newest_crash_folder(d / "none", 0))
        finally:
            import shutil
            shutil.rmtree(d)


if __name__ == "__main__":
    unittest.main()
