"""Run a benchmark with a DLL (and ini) other than the installed ones: `--dll PATH [--dll-ini PATH]`, or an A/B side
written `dll:PATH`. The installed version.dll + OblivionPerfFix.ini are backed up through the FileGuard (so a killed run
is repaired by the next run or `bench.py restore`) and the given files are copied over them."""
import shutil
from pathlib import Path

from . import fixini

SIMPLE_SIDES = ("on", "stock", "off")


def check(dll, dll_ini=None):
    """Raises before anything is touched when a file is missing."""
    if dll is not None and not Path(dll).is_file():
        raise RuntimeError(f"--dll {dll}: no such file")
    if dll_ini is not None:
        if dll is None:
            raise RuntimeError("--dll-ini needs --dll")
        if not Path(dll_ini).is_file():
            raise RuntimeError(f"--dll-ini {dll_ini}: no such file")


def install(paths, guard, dll, dll_ini=None):
    """Backs up and replaces version.dll (and the ini if dll_ini); returns what to record in result.json."""
    check(dll, dll_ini)
    target = paths.win64 / "version.dll"
    guard.backup(target)
    shutil.copyfile(dll, target)
    info = {"path": str(Path(dll).resolve()), "sha256": fixini.sha256(dll), "size": Path(dll).stat().st_size}
    if dll_ini is not None:
        guard.backup(paths.fix_ini)
        shutil.copyfile(dll_ini, paths.fix_ini)
        info["ini"] = str(Path(dll_ini).resolve())
        info["iniSha256"] = fixini.sha256(dll_ini)
    return info


def parse_side(text):
    """An A/B side: on | stock | off | dll:PATH[@on|@stock]  ->  (fix, dll, name). `name` labels runs and the report."""
    if text in SIMPLE_SIDES:
        return text, None, text
    if text.startswith("dll:"):
        path, fix = text[4:], "on"
        if path.endswith("@stock"):
            path, fix = path[:-6], "stock"
        elif path.endswith("@on"):
            path = path[:-3]
        if not path:
            raise ValueError("dll: needs a path")
        if not Path(path).is_file():
            raise ValueError(f"dll:{path}: no such file")
        return fix, path, f"dll-{fixini.sha256(path)[:8]}" + ("" if fix == "on" else "-" + fix)
    raise ValueError(f"{text!r}: expected on, stock, off or dll:PATH")
