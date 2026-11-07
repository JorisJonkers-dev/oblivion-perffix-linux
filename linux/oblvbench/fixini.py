"""OblivionPerfFix.ini for stock runs, and putting the player's files back afterwards.

"Stock" (as tools/Bench-Report.ps1): the DLL loaded with every switch in [Fixes] at 0 (each fix then leaves the
game's code alone), except FrameRateLimitAtStart, which only makes the game honour the player's saved frame cap
(a game bug with FSR frame generation), so both sides run at the same cap."""
import hashlib
import json
import os
import re
import shutil
import time
from pathlib import Path

STOCK_KEEP = ("FrameRateLimitAtStart",)
_KEY_RX = re.compile(r"^(\s*)([A-Za-z0-9]+)(\s*=\s*)([^;\s]*)(.*)$")


def _sections(lines):
    """Yields (section, line) for each line (section of the line, None before the first)."""
    sec = None
    for line in lines:
        m = re.match(r"^\s*\[(.+?)\]", line)
        if m:
            sec = m.group(1)
        yield sec, line


def fix_values(text):
    """{key: value} of the [Fixes] section."""
    out = {}
    for sec, line in _sections(text.splitlines()):
        m = _KEY_RX.match(line)
        if sec == "Fixes" and m:
            out[m.group(2)] = m.group(4)
    return out


def set_values(text, section, values):
    """The ini text with these keys' values replaced in `section` (comments after the value and the line endings
    kept); keys not there are added right under the section header."""
    lines = text.splitlines(keepends=True)
    nl = "\r\n" if "\r\n" in text else "\n"
    left = dict(values)
    out = []
    header_at = None
    for sec, line in _sections(lines):
        body = line.rstrip("\r\n")
        end = line[len(body):]
        m = _KEY_RX.match(body)
        if sec == section and m and m.group(2) in values:
            body = f"{m.group(1)}{m.group(2)}{m.group(3)}{values[m.group(2)]}{m.group(5)}"
            left.pop(m.group(2), None)
        out.append(body + end)
        if re.match(r"^\s*\[(.+?)\]", body) and sec == section and header_at is None:
            header_at = len(out)
    if left:
        add = [f"{k}={v}{nl}" for k, v in left.items()]
        if header_at is None:
            if out and not out[-1].endswith(("\n", "\r")):
                out[-1] += nl
            out += [nl, f"[{section}]{nl}"] + add
        else:
            out[header_at:header_at] = add
    return "".join(out)


def stock_text(text):
    """The installed ini with every [Fixes] switch at 0 except STOCK_KEEP."""
    keys = [k for k in fix_values(text) if k not in STOCK_KEEP]
    if not keys:
        raise ValueError("no switches in the ini's [Fixes] section")
    return set_values(text, "Fixes", {k: 0 for k in keys})


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class FileGuard:
    """Backs files up before a run changes them and puts them back afterwards. What is pending is written to
    <runtime>/bench-restore.json first, so a run killed half-way is repaired by the next one (or `bench.py restore`)."""

    def __init__(self, runtime):
        self.dir = Path(runtime) / "restore"
        self.pending = Path(runtime) / "bench-restore.json"

    def _load(self):
        try:
            return json.loads(self.pending.read_text())
        except (OSError, ValueError):
            return []

    def _save(self, entries):
        self.pending.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.pending.with_suffix(".tmp")
        tmp.write_text(json.dumps(entries, indent=1))
        os.replace(tmp, self.pending)

    def backup(self, target):
        """Keeps a copy of target (or notes that it did not exist). Once per target until restore()."""
        target = Path(target)
        entries = self._load()
        if any(e["target"] == str(target) for e in entries):
            return
        self.dir.mkdir(parents=True, exist_ok=True)
        entry = {"target": str(target), "time": time.time()}
        if target.exists():
            copy = self.dir / f"{len(entries):02d}-{target.name}"
            shutil.copy2(target, copy)
            entry.update(backup=str(copy), sha256=sha256(copy))
        else:
            entry["backup"] = None             # created by the run: removed on restore
        entries.append(entry)
        self._save(entries)

    def restore(self):
        """Puts every backed-up file back; returns the targets restored."""
        done = []
        for e in self._load():
            target = Path(e["target"])
            if e.get("backup"):
                if Path(e["backup"]).exists():
                    shutil.copy2(e["backup"], target)
                    done.append(str(target))
            elif target.exists():
                target.unlink()
                done.append(str(target))
        if self.pending.exists():
            self.pending.unlink()
        if self.dir.exists():
            shutil.rmtree(self.dir, ignore_errors=True)
        return done

    def has_pending(self):
        return bool(self._load())


def write_stock_ini(ini_path, guard):
    """Backs the player's ini up, then writes the stock version in its place. Returns the keys set to 0."""
    ini_path = Path(ini_path)
    raw = ini_path.read_bytes()
    text = raw.decode("utf-8-sig" if raw.startswith(b"\xef\xbb\xbf") else "utf-8", errors="surrogateescape")
    guard.backup(ini_path)
    new = stock_text(text)
    data = new.encode("utf-8", errors="surrogateescape")
    if raw.startswith(b"\xef\xbb\xbf"):
        data = b"\xef\xbb\xbf" + data
    ini_path.write_bytes(data)
    return sorted(k for k in fix_values(text) if k not in STOCK_KEEP)
