"""Live session ("bench.py spin"): stand at one spot, turn the camera slowly through full laps, flip settings in the
same game session and compare frame times per variant. This module is the logic that needs no game: variant
parsing, which ini keys can be flipped live, the ABBA order, the heading timeline, lap and sector slicing of the
frame log, the per-variant summary and report, and splitting the HitchLedger by variant window."""
import bisect
import json
import math
import re
import statistics
import time

from . import mangohud

NOISE_PCT = 5.0
SECTORS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]          # 45 degrees each, centred on the compass points
METRICS = [  # key, title, format, higher is better
    ("fps", "avg fps", "{:.1f}", True),
    ("low1", "1% low", "{:.1f}", True),
    ("low01", "0.1% low", "{:.1f}", True),
    ("p99Ms", "p99 ms", "{:.2f}", False),
    ("worstMs", "max ms", "{:.1f}", False),
    ("hitches", "hitches", "{:.0f}", False),
    ("gpuLoad", "GPU %", "{:.0f}", None),
    ("cpuLoad", "CPU %", "{:.0f}", None),
]


class SpinError(ValueError):
    pass


# ---------------------------------------------------------------- variants

class Variant:
    def __init__(self, name, kind=None, values=None):
        self.name = name
        self.kind = kind                    # None (as installed), "ini" or "cvar"
        self.values = dict(values or {})

    def __repr__(self):
        return f"Variant({self.name!r}, {self.kind!r}, {self.values!r})"

    def spec(self):
        return {"name": self.name, "kind": self.kind or "base", "values": self.values}


def parse_variant(spec):
    """'name:ini:KEY=VAL,KEY=VAL' or 'name:cvar:r.Foo=1,r.Bar=2' -> Variant."""
    parts = spec.split(":", 2)
    if len(parts) != 3:
        raise SpinError(f"variant {spec!r}: expected NAME:ini:KEY=VAL,... or NAME:cvar:r.Foo=1,...")
    name, kind, body = (p.strip() for p in parts)
    if not re.fullmatch(r"[A-Za-z0-9_.+-]+", name):
        raise SpinError(f"variant name {name!r}: letters, digits and _ . + - only")
    if kind not in ("ini", "cvar"):
        raise SpinError(f"variant {name}: kind must be ini or cvar, not {kind!r}")
    values = {}
    for kv in body.split(","):
        if not kv.strip():
            continue
        k, eq, v = kv.partition("=")
        if not eq or not k.strip() or not v.strip():
            raise SpinError(f"variant {name}: expected KEY=VALUE, got {kv!r}")
        values[k.strip()] = v.strip()
    if not values:
        raise SpinError(f"variant {name}: no KEY=VALUE given")
    return Variant(name, kind, values)


def parse_variants(specs):
    """The implicit `base` (as installed) first, then the --variant specs in order."""
    out = [Variant("base")]
    for s in specs or []:
        v = parse_variant(s)
        if any(v.name == o.name for o in out):
            raise SpinError(f"variant name {v.name!r} used twice (base is the implicit as-installed variant)")
        out.append(v)
    return out


def balanced_order(names, rounds):
    """Forward then backward, repeated: A B B A A B B A for two variants and two rounds; N variants:
    v1..vN vN..v1, `rounds` times."""
    names = list(names)
    if rounds < 1:
        raise SpinError("--rounds must be at least 1")
    return (names + names[::-1]) * rounds


# ---------------------------------------------------------------- which ini keys can be flipped live

_TAG_RX = re.compile(r"(?P<only>start-up only|takes a restart(?! to switch on))"
                     r"|(?P<install>start-up[^.;]{0,60}then live|installed when the game starts|takes a restart to switch on"
                     r"|start-up\b)"
                     r"|(?P<live>(?<!then )\blive\b)", re.I)


def ini_modes(text):
    """{key: 'startup' | 'install' | 'live'} for the [Fixes] keys of the shipped ini, from the comment paragraph
    above each key: 'Start-up only' (needs a restart), 'Start-up, then live' / 'Installed when the game starts'
    (installed only if on when the game starts, then live), 'Live'. The last tag of the paragraph wins; a key with
    no tag counts as startup (the safe side)."""
    out, para, sec = {}, [], None
    for raw in text.splitlines():
        s = raw.strip()
        m = re.match(r"\[(.+?)\]", s)
        if m:
            sec, para = m.group(1), []
            continue
        if s.startswith(";"):
            para.append(s[1:].strip())
            continue
        if not s:
            para = []
            continue
        m = re.match(r"([A-Za-z0-9]+)\s*=", s)
        if m and sec == "Fixes":
            tags = list(_TAG_RX.finditer(" ".join(para)))
            mode = "startup"
            if tags:
                mode = next(k for k, v in tags[-1].groupdict().items() if v is not None)
                mode = {"only": "startup", "install": "install", "live": "live"}[mode]
            out[m.group(1)] = mode
    return out


def check_ini_variants(variants, modes, installed):
    """Problems (strings) with the ini variants: unknown keys, start-up only keys changed, start-up-then-live keys
    turned on that were off when the game started. `installed` = the [Fixes] values the game starts with."""
    problems = []
    for v in variants:
        if v.kind != "ini":
            continue
        for k, val in v.values.items():
            mode = modes.get(k)
            if mode is None:
                problems.append(f"{v.name}: {k} is not a [Fixes] key of OblivionPerfFix.ini")
                continue
            base = str(installed.get(k, "")).strip()
            if str(val) == base:
                continue
            if mode == "startup":
                problems.append(f"{v.name}: {k} is 'Start-up only': it is read once when the game starts and cannot "
                                f"be flipped in a live session (restart with it set in the ini)")
            elif mode == "install" and base in ("0", ""):
                problems.append(f"{v.name}: {k}={val} but it is {base or 'unset'} in the ini the game starts with, and "
                                f"'Start-up, then live' keys are installed at start-up only when on; set it on before "
                                f"the session and use a variant that turns it off (and back on)")
    return problems


def ini_targets(variants, current_values):
    """{name: {key: value}}: per variant every key any ini variant touches, so switching variants puts the other
    variants' keys back to their as-installed values."""
    keys = sorted({k for v in variants if v.kind == "ini" for k in v.values})
    missing = [k for k in keys if k not in current_values]
    if missing:
        raise SpinError(f"{', '.join(missing)} not in the installed OblivionPerfFix.ini: it could not be put back")
    base = {k: current_values[k] for k in keys}
    return {v.name: {**base, **(v.values if v.kind == "ini" else {})} for v in variants}


def cvar_keys(variants):
    return sorted({k for v in variants if v.kind == "cvar" for k in v.values})


def cvar_targets(variants, base_values):
    """{name: {cvar: value}} for every variant: the as-read base values, overridden by the variant's own."""
    keys = cvar_keys(variants)
    return {v.name: {**{k: base_values[k] for k in keys}, **(v.values if v.kind == "cvar" else {})} for v in variants}


def same_value(a, b):
    try:
        return abs(float(a) - float(b)) <= 1e-4 * max(1.0, abs(float(b)))
    except (TypeError, ValueError):
        return str(a).strip().lower() == str(b).strip().lower()


# ---------------------------------------------------------------- the spin and its heading timeline

def spin_heading(h0, rate, t0, t):
    """Unwrapped heading (degrees, 0 = north, 90 = east) at wall time t of a spin that started at t0."""
    return h0 + rate * (t - t0)


def lap_seconds(rate):
    return 360.0 / abs(rate)


def next_lap_start(t, t_spin0, rate):
    """The first time >= t at which the spin is back at its start heading."""
    lap = lap_seconds(rate)
    return t_spin0 + math.ceil(max(0.0, t - t_spin0) / lap - 1e-9) * lap


class Timeline:
    """(wall time, unwrapped heading) samples of what was sent to the game; heading_at() interpolates."""

    def __init__(self, samples=None):
        self.t, self.h = [], []
        for t, h in samples or []:
            self.add(t, h)

    def add(self, t, h):
        if self.t and t < self.t[-1]:
            raise ValueError("timeline samples must be in time order")
        self.t.append(t)
        self.h.append(h)

    def __len__(self):
        return len(self.t)

    def at(self, t):
        if not self.t:
            return None
        i = bisect.bisect_left(self.t, t)
        if i == 0:
            return self.h[0] if t >= self.t[0] - 1.0 else None
        if i >= len(self.t):
            return self.h[-1] if t <= self.t[-1] + 1.0 else None
        t0, t1, h0, h1 = self.t[i - 1], self.t[i], self.h[i - 1], self.h[i]
        return h0 if t1 == t0 else h0 + (h1 - h0) * (t - t0) / (t1 - t0)

    def to_json(self):
        return [[round(t, 3), round(h, 2)] for t, h in zip(self.t, self.h)]


def sector_of(heading):
    return int(((heading + 22.5) % 360.0) // 45.0)


def sector_label(i):
    c = (i * 45) % 360
    return f"{SECTORS[i]} {c}°"


# ---------------------------------------------------------------- slicing the frame log

def slot_stats(log, start, t0, t1, timeline, lag=0.0, laps=1):
    """Statistics of one measured window: the whole window (as mangohud.stats), each lap on its own, and the
    average fps per 45-degree heading sector. The camera trails the heading sent to the game by about `lag` s (its
    smoothing), so a frame is assigned to the heading `lag` seconds before it."""
    s = mangohud.stats(log, start, t0, t1)
    lap = (t1 - t0) / max(1, laps)
    s["lapsFps"] = [mangohud.stats(log, start, t0 + i * lap, t0 + (i + 1) * lap).get("fps") for i in range(laps)]
    buckets = [[] for _ in SECTORS]
    for i in mangohud.window(log, start, t0, t1):
        h = timeline.at(start + log.elapsed[i] - lag)
        if h is not None:
            buckets[sector_of(h)].append(log.frametime[i])
    s["sectorFps"] = [round(1000 * len(b) / sum(b), 1) if b and sum(b) > 0 else None for b in buckets]
    s["sectorFrames"] = [len(b) for b in buckets]
    return s


# ---------------------------------------------------------------- summary

def _median(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def summarise(slots, variants):
    """Per variant (in --variant order): the median over its slots of every metric and of every sector's fps, the
    slots' fps range (spread), and the change against the first variant."""
    out = []
    for v in variants:
        mine = [s for s in slots if s["variant"] == v.name and s.get("frames")]
        row = {"name": v.name, "kind": v.kind or "base", "values": v.values, "slots": len(mine)}
        for key, _, _, _ in METRICS:
            row[key] = _median([s.get(key) for s in mine])
        row["sectorFps"] = [_median([s["sectorFps"][i] for s in mine if s.get("sectorFps")]) for i in range(len(SECTORS))]
        fps = [s["fps"] for s in mine if s.get("fps") is not None]
        row["fpsMin"], row["fpsMax"] = (min(fps), max(fps)) if fps else (None, None)
        row["spreadPct"] = round(100 * (row["fpsMax"] - row["fpsMin"]) / row["fps"], 1) if fps and row["fps"] else None
        row["slotFps"] = fps
        out.append(row)
    first = out[0] if out else None
    for row in out:
        d = {}
        for key, _, _, _ in METRICS:
            a, b = (first or {}).get(key), row.get(key)
            d[key] = None if a in (None, 0) or b is None else round(100.0 * (b - a) / a, 1)
        row["deltaPct"] = d
        ds = [None if (first or {}).get("sectorFps", [None] * 8)[i] in (None, 0) or row["sectorFps"][i] is None
              else round(100.0 * (row["sectorFps"][i] - first["sectorFps"][i]) / first["sectorFps"][i], 1)
              for i in range(len(SECTORS))]
        row["sectorDeltaPct"] = ds
        sp = max([x for x in (row.get("spreadPct"), (first or {}).get("spreadPct")) if x is not None] or [0.0])
        row["noiseFloorPct"] = max(NOISE_PCT, sp)
    return out


def _f(fmt, v):
    return "-" if v is None else fmt.format(v)


def _delta(row, key):
    d = row["deltaPct"].get(key)
    if d is None or row is None:
        return ""
    return f" ({d:+.0f}%{' ~' if abs(d) < row['noiseFloorPct'] else ''})"


def report_markdown(result):
    r = result
    sp = r["spin"]
    out = [f"# spin {r.get('label')} ({r.get('time')})", "",
           f"- spot `{sp['spot']}`, profile `{(r.get('profile') or {}).get('name')}`, hour/weather pinned: {r.get('pinned')}, "
           f"outcome **{r.get('outcome')}**",
           f"- {sp['degPerSec']:g} deg/s = {sp['lapSec']:.1f} s per lap, pitch {sp['pitch']:g}, "
           f"{sp['laps']} lap(s) per slot, settle {sp['settle']:g} s, camera lag assumed {sp['camLag']:g} s",
           f"- order: {' '.join(sp['order'])}",
           f"- frames: MangoHud (Proton); {_timing(r.get('frameLog'))}", ""]
    rows = r.get("variants") or []
    if rows:
        out.append("| variant | kind | slots | " + " | ".join(m[1] for m in METRICS) + " |")
        out.append("|---|---|---:|" + "---:|" * len(METRICS))
        for row in rows:
            cells = [_f(f, row.get(k)) + (_delta(row, k) if row is not rows[0] and k not in ("gpuLoad", "cpuLoad") else "")
                     for k, _, f, _ in METRICS]
            out.append(f"| {row['name']} | {row['kind']} | {row['slots']} | " + " | ".join(cells) + " |")
        out += ["", f"Each cell: median over the variant's slots; the change is against `{rows[0]['name']}`, `~` = under "
                f"the larger of {NOISE_PCT:.0f} % and the slot-to-slot spread of the two.", "",
                "Slot-to-slot spread of avg fps (min - max, % of median):", ""]
        for row in rows:
            out.append(f"- {row['name']}: {', '.join(f'{x:.1f}' for x in row['slotFps']) or '-'}"
                       + (f" ({row['spreadPct']:.1f} %)" if row.get("spreadPct") is not None else ""))
        out += ["", "## Avg fps by heading sector", "",
                "| variant | " + " | ".join(sector_label(i) for i in range(len(SECTORS))) + " | worst |",
                "|---|" + "---:|" * (len(SECTORS) + 1)]
        for row in rows:
            vals = row["sectorFps"]
            known = [(x, i) for i, x in enumerate(vals) if x is not None]
            worst = min(known)[1] if known else None
            cells = []
            for i, x in enumerate(vals):
                d = row["sectorDeltaPct"][i]
                cells.append(_f("{:.1f}", x) + ("" if row is rows[0] or d is None else f" ({d:+.0f}%)"))
            out.append(f"| {row['name']} | " + " | ".join(cells) + f" | {sector_label(worst) if worst is not None else '-'} |")
    if r.get("slots"):
        out += ["", "## Slots", "", "| # | variant | s | frames | avg fps | 1% low | hitches | lap fps |", "|---:|---|---:|---:|---:|---:|---:|---|"]
        for i, s in enumerate(r["slots"], 1):
            out.append(f"| {i} | {s['variant']} | {s.get('seconds', 0):.1f} | {s.get('frames', '-')} | {_f('{:.1f}', s.get('fps'))} | "
                       f"{_f('{:.1f}', s.get('low1'))} | {_f('{:.0f}', s.get('hitches'))} | "
                       f"{', '.join(_f('{:.1f}', x) for x in s.get('lapsFps', []))} |")
    led = r.get("ledger")
    if led:
        out += ["", "## HitchLedger by variant", ""]
        if led.get("note"):
            out.append(led["note"])
        for name, d in (led.get("variants") or {}).items():
            out.append(f"- {name}: {d['frames']} slow game-thread frames, {d['totalMs']:.0f} ms in them, longest "
                       f"{d['maxMs']:.0f} ms" + (f", ranked in `{d['file']}`" if d.get("file") else ""))
    if r.get("warnings"):
        out += ["", "## Warnings", ""] + [f"- {w}" for w in r["warnings"]]
    out += ["", "A hitch is a frame longer than max(2 x the window's median, 40 ms); 1% / 0.1% low = 1000 / the 99th / "
            "99.9th percentile frame time. Sectors are 45 degrees centred on the compass points (heading 0 = north).", ""]
    return "\n".join(out)


def _timing(t):
    return "no frame log" if not t else f"log start from {t.get('method')} ({t.get('frames')} frames in `{t.get('log')}`)"


def write_result(run_dir, result):
    (run_dir / "result.json").write_text(json.dumps(result, indent=1))
    (run_dir / "report.md").write_text(report_markdown(result))


# ---------------------------------------------------------------- HitchLedger by variant window

def _ledger_cols(text):
    cols = None
    for line in text.splitlines():
        if line.startswith("#F,"):
            cols = line[1:].split(",")
            break
    return cols


def ledger_frames(text):
    """[(end_ms, period_ms, raw line)] of the ledger's F rows."""
    cols = _ledger_cols(text)
    if not cols or "end_ms" not in cols or "period_ms" not in cols:
        return []
    ie, ip = cols.index("end_ms"), cols.index("period_ms")
    out = []
    for line in text.splitlines():
        if line.startswith("F,"):
            row = line.split(",")
            if len(row) == len(cols):
                try:
                    out.append((float(row[ie]), float(row[ip]), line))
                except ValueError:
                    pass
    return out


def anchor_ledger(frames, markers, tol=0.25):
    """wall - end_ms/1000 of the ledger's clock (a QueryPerformanceCounter), from the runner's sync stalls: the
    ledger frames of 300-900 ms (a 350 ms busy loop in the game thread) are matched to the markers' wall times by
    their distance. Needs two markers; None when no unique match exists."""
    if len(markers) < 2:
        return None
    marks = sorted(w for w, _ in markers)
    cands = [e / 1000.0 for e, p, _ in frames if 300.0 <= p <= 900.0]
    first, last = marks[0], marks[-1]
    best = []
    for i, c1 in enumerate(cands):
        for c2 in cands[i + 1:]:
            err = abs((c2 - c1) - (last - first))
            if err <= tol:
                best.append((err, ((first - c1) + (last - c2)) / 2))
    if not best:
        return None
    best.sort()
    # a second match at another offset makes the anchor ambiguous
    if any(abs(o - best[0][1]) > 1.0 for _, o in best[1:] if _ <= best[0][0] + 0.1):
        return None
    return best[0][1]


def split_ledger(text, windows, offset, exclude=()):
    """{variant: filtered ledger text} with the '#' lines and the F/S rows that end inside the variant's windows
    (wall clock; `offset` from anchor_ledger), plus {variant: summary}."""
    texts, summary = {}, {}
    head = [l for l in text.splitlines() if l.startswith("#")]
    cols = {"F": _ledger_cols(text)}
    for line in text.splitlines():
        if line.startswith("#S,"):
            cols["S"] = line[1:].split(",")
    for name, wins in windows.items():
        rows, ms = [], []
        for line in text.splitlines():
            kind = line[:2]
            if kind not in ("F,", "S,") or not cols.get(kind[0]):
                continue
            row = line.split(",")
            c = cols[kind[0]]
            if len(row) != len(c) or "end_ms" not in c:
                continue
            try:
                wall = float(row[c.index("end_ms")]) / 1000.0 + offset
            except ValueError:
                continue
            if any(a <= wall <= b for a, b in wins) and not any(a <= wall <= b for a, b in exclude):
                rows.append(line)
                if kind == "F,":
                    try:
                        ms.append(float(row[c.index("period_ms")]))
                    except (ValueError, IndexError):
                        pass
        texts[name] = "\n".join(head + rows) + "\n"
        summary[name] = {"frames": len(ms), "totalMs": round(sum(ms), 1), "maxMs": round(max(ms), 1) if ms else 0.0}
    return texts, summary


def stamp():
    return time.strftime("%Y%m%d-%H%M%S")
