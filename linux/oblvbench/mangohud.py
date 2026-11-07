"""MangoHud per-frame CSV logs: parsing, the log's wall-clock start, slicing and frame statistics.

A MangoHud log (log_interval=0: one row per presented frame) has a system-info header, then a column header
starting "fps,frametime,..." and one row per frame. `frametime` is in ms, `elapsed` in ns since logging started.
The file name ends in the local start time, "<process>_YYYY-MM-DD_HH-MM-SS.csv" (second resolution).

Wall time of a frame = log start + elapsed. The log start is known from:
  1. sync markers (best, ~1 frame): the runner stalls the game thread for a known time (a busy loop in the mod) and
     notes the wall time the mod's answer arrived; the matching long frame in the CSV pins the offset;
  2. the file name: start in [name, name + 1 s), so +-0.5 s around name + 0.5 s;
  3. narrowed by when the runner first saw the file appear (only if MangoHud writes it while logging)."""
import csv
import io
import math
import re
import statistics
import time
from dataclasses import dataclass, field
from pathlib import Path

NAME_RX = re.compile(r"_(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2})\.csv$")


@dataclass
class FrameLog:
    path: str = ""
    elapsed: list = field(default_factory=list)     # seconds since log start, per frame
    frametime: list = field(default_factory=list)   # ms
    cpu_load: list = field(default_factory=list)    # % (None if missing)
    gpu_load: list = field(default_factory=list)
    columns: list = field(default_factory=list)

    def __len__(self):
        return len(self.elapsed)


def name_time(path):
    """Local start time from the file name (epoch seconds), or None."""
    m = NAME_RX.search(Path(path).name)
    if not m:
        return None
    return time.mktime(time.strptime(m.group(1), "%Y-%m-%d_%H-%M-%S"))


def _num(s):
    try:
        v = float(s)
    except (TypeError, ValueError):
        return None
    return v if math.isfinite(v) else None


def parse_csv(path):
    return parse_text(Path(path).read_text(errors="replace"), str(path))


def parse_text(text, src=""):
    """Reads MangoHud CSV text. Rows without a valid frametime/elapsed are skipped."""
    lines = text.splitlines()
    head = next((i for i, l in enumerate(lines) if l.startswith("fps,") or l.startswith("frametime,")), None)
    if head is None:
        raise ValueError(f"no MangoHud column header (fps,frametime,...) in {src or 'the text'}")
    reader = csv.reader(io.StringIO("\n".join(lines[head:])))
    cols = [c.strip() for c in next(reader)]
    if "frametime" not in cols or "elapsed" not in cols:
        raise ValueError(f"MangoHud log without frametime/elapsed columns: {cols}")
    i_ft, i_el = cols.index("frametime"), cols.index("elapsed")
    i_cpu = cols.index("cpu_load") if "cpu_load" in cols else None
    i_gpu = cols.index("gpu_load") if "gpu_load" in cols else None
    log = FrameLog(path=src, columns=cols)
    for row in reader:
        if len(row) <= max(i_ft, i_el):
            continue
        ft, el = _num(row[i_ft]), _num(row[i_el])
        if ft is None or el is None or ft <= 0:
            continue
        log.elapsed.append(el / 1e9)
        log.frametime.append(ft)
        log.cpu_load.append(_num(row[i_cpu]) if i_cpu is not None and i_cpu < len(row) else None)
        log.gpu_load.append(_num(row[i_gpu]) if i_gpu is not None and i_gpu < len(row) else None)
    return log


def find_logs(folder, since=None):
    """Per-frame logs in a MangoHud output folder (not the *_summary.csv), oldest first; only those whose
    name time is at or after `since` - 2 s when given."""
    out = []
    for p in sorted(Path(folder).glob("*.csv")):
        if p.name.endswith("_summary.csv"):
            continue
        t = name_time(p)
        if t is None or (since is not None and t < since - 2):
            continue
        out.append(p)
    return sorted(out, key=lambda p: name_time(p))


def pick_log(paths, process_hint="OblivionRemastered"):
    """The game's log among several (other Vulkan processes of the launch may log too): the biggest whose name
    has the hint, else the biggest."""
    if not paths:
        return None
    named = [p for p in paths if process_hint.lower() in p.name.lower()]
    return max(named or paths, key=lambda p: p.stat().st_size)


def estimate_start(name_ts, first_seen=None):
    """(start, max error) of logging: the name time is truncated to the second, so start is in [name, name + 1);
    the file exists from logging start on, so a first sighting within a few seconds of the name caps it."""
    lo, hi = name_ts, name_ts + 1.0
    if first_seen is not None and name_ts <= first_seen <= name_ts + 5:
        hi = min(hi, first_seen)
    return (lo + hi) / 2, (hi - lo) / 2


def find_sync(log, start_guess, markers, window=3.0, min_share=0.7):
    """Log start from sync markers: markers = [(wall time the stall ended, stall ms)]. For each, the long frame
    (>= min_share x the stall) whose guessed wall time is nearest within `window` s; its elapsed pins
    start = wall - elapsed. Returns (start or None, [per-marker detail dicts])."""
    found = []
    detail = []
    for wall, stall_ms in markers:
        best = None
        for el, ft in zip(log.elapsed, log.frametime):
            if ft < min_share * stall_ms:
                continue
            d = abs(start_guess + el - wall)
            if d <= window and (best is None or d < best[0]):
                best = (d, el, ft)
        if best:
            found.append(wall - best[1])
            detail.append({"wall": round(wall, 3), "stallMs": stall_ms, "frameMs": round(best[2], 1),
                           "start": round(wall - best[1], 3), "vsNameGuess": round(wall - best[1] - start_guess, 3)})
        else:
            detail.append({"wall": round(wall, 3), "stallMs": stall_ms, "frameMs": None})
    if not found:
        return None, detail
    return statistics.median(found), detail


def window(log, start, t0, t1):
    """Indices of frames whose wall time (start + elapsed) lies in [t0, t1]."""
    return [i for i, el in enumerate(log.elapsed) if t0 <= start + el <= t1]


def _pct(sorted_v, p):
    if not sorted_v:
        return 0.0
    return sorted_v[min(len(sorted_v) - 1, int(math.floor(len(sorted_v) * p)))]


def _mean(v):
    v = [x for x in v if x is not None]
    return sum(v) / len(v) if v else None


def stats(log, start, t0, t1):
    """Frame statistics of [t0, t1] (wall clock), as tools/BenchLib.cs FrameLog.Stats: percentiles by rank
    (sorted[floor(n x p)]), 1% / 0.1% low = 1000 / p99 / p99.9 frame time, a hitch is a frame longer than
    max(2 x median, 40 ms) and its hitch time what it took beyond the median."""
    idx = window(log, start, t0, t1)
    s = {"frames": len(idx), "seconds": round(t1 - t0, 3)}
    times = [start + log.elapsed[i] for i in idx]
    gaps = [b - a for a, b in zip([t0] + times, times + [t1])]
    s["longestGapMs"] = round(1000 * max(gaps), 1) if gaps else round(1000 * (t1 - t0), 1)
    if not idx:
        return s
    v = [log.frametime[i] for i in idx]
    sv = sorted(v)
    avg = sum(v) / len(v)
    p50, p99, p999 = _pct(sv, 0.50), _pct(sv, 0.99), _pct(sv, 0.999)
    limit = max(2 * p50, 40.0)
    hitches = [d for d in v if d > limit]
    s.update({
        "fps": round(1000 / avg, 1),
        "low1": round(1000 / p99, 1), "low01": round(1000 / p999, 1),
        "avgMs": round(avg, 2), "p50Ms": round(p50, 2), "p95Ms": round(_pct(sv, 0.95), 2),
        "p99Ms": round(p99, 2), "p999Ms": round(p999, 2), "worstMs": round(sv[-1], 1),
        "hitches": len(hitches), "hitchMs": round(sum(d - p50 for d in hitches), 1),
        "over50": sum(d > 50 for d in v), "over100": sum(d > 100 for d in v), "over250": sum(d > 250 for d in v),
    })
    cpu, gpu = _mean(log.cpu_load[i] for i in idx), _mean(log.gpu_load[i] for i in idx)
    s["cpuLoad"] = None if cpu is None else round(cpu, 1)
    s["gpuLoad"] = None if gpu is None else round(gpu, 1)
    return s


def config_text(output_folder, show_hud=False):
    """A MangoHud config for benchmark runs: log every frame from 1 s after start.

    MangoHud does not log with `no_display` (seen live on 0.8.x: no CSV at all), so the HUD stays on,
    cut down to a small fps counter unless the full HUD is asked for."""
    lines = [
        f"output_folder={output_folder}",
        "autostart_log=1",
        "log_interval=0",
        "log_duration=0",
        "fps_limit=0",
    ]
    if not show_hud:
        # for the person watching: fps, a frame-time graph with min/max, CPU/GPU load (MangoHud shows a red dot
        # while it logs; there is no option to hide it)
        lines += ["fps", "frametime", "frame_timing=1", "cpu_stats", "gpu_stats", "position=top-left",
                  "font_size=18", "background_alpha=0.4"]
    return "\n".join(lines) + "\n"
