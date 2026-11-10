"""Save guard (tools/Run-Benchmark.ps1 Protect-Saves / Restore-Saves): a benchmark game autosaves at doors and
writes its settings save, so the rolling saves are copied before the run and put back afterwards; saves the run
created are moved out of the save folder (kept in the runtime folder)."""
import json
import re
import shutil
import time
from pathlib import Path

GUARD_RX = re.compile(r"^(autosave|quicksave|saves_meta|Save_Settings)", re.IGNORECASE)


class SaveGuard:
    def __init__(self, save_dir, runtime):
        self.save_dir = Path(save_dir)
        self.dir = Path(runtime) / "save-guard"
        self.pending = self.dir / "pending.json"

    def protect(self):
        if self.pending.exists():
            self.restore()                     # left over from an aborted run
        files = self.dir / "files"
        shutil.rmtree(files, ignore_errors=True)
        files.mkdir(parents=True, exist_ok=True)
        listing = []
        if self.save_dir.is_dir():
            for f in self.save_dir.iterdir():
                if not f.is_file():
                    continue
                st = f.stat()
                listing.append({"name": f.name, "size": st.st_size, "mtime_ns": st.st_mtime_ns})
                if GUARD_RX.match(f.name):
                    shutil.copy2(f, files / f.name)
        self.pending.write_text(json.dumps({"time": time.time(), "files": listing}))

    def restore(self, say=print):
        if not self.pending.exists():
            return
        state = json.loads(self.pending.read_text())
        before = {f["name"]: f for f in state["files"]}
        if self.save_dir.is_dir():
            created = [f for f in self.save_dir.iterdir() if f.is_file() and f.name not in before]
            if created:
                dest = self.dir / time.strftime("created-%Y%m%d-%H%M%S")
                dest.mkdir(parents=True, exist_ok=True)
                for f in created:
                    shutil.move(str(f), dest / f.name)
                say(f"save guard: moved {len(created)} save file(s) created during the run to {dest}")
        restored = 0
        for g in sorted((self.dir / "files").glob("*")):
            cur = self.save_dir / g.name
            b = before.get(g.name)
            if cur.exists() and b:
                st = cur.stat()
                if st.st_size == b["size"] and st.st_mtime_ns == b["mtime_ns"]:
                    continue
            shutil.copy2(g, cur)
            restored += 1
        if restored:
            say(f"save guard: restored {restored} rolling save file(s)")
        self.pending.unlink()
