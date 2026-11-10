"""Reports: one run (report.md next to its result.json), and A vs B over several runs per side (as
tools/Bench-Report.ps1: per scene the median over the runs of each side, the change in percent, '~' under 5 %,
which is run-to-run noise)."""
import json
import statistics
import time
from pathlib import Path

METRICS = [  # key, title, format, higher is better
    ("fps", "avg fps", "{:.1f}", True),
    ("low1", "1% low", "{:.1f}", True),
    ("low01", "0.1% low", "{:.1f}", True),
    ("p99Ms", "p99 ms", "{:.2f}", False),
    ("worstMs", "max ms", "{:.1f}", False),
    ("hitches", "hitches", "{:.0f}", False),
    ("over50", ">50 ms", "{:.0f}", False),
    ("cpuLoad", "CPU %", "{:.0f}", None),
    ("gpuLoad", "GPU %", "{:.0f}", None),
]
NOISE_PCT = 5.0
TIME_KEYS = ("detailBrightStableS", "detailSettleS", "detailSettleAbsS")
DETAIL_METRICS = [  # key, title, format, higher is better
    ("detailBrightStableS", "brightness stable s", "{:.1f}", False),
    ("detailSettleS", "sharp after s", "{:.1f}", False),
    ("detailSettleAbsS", "sharp at s (from arrival)", "{:.1f}", False),
    ("detailAt1s", "sharpness at 1 s", "{:.2f}", True),
    ("detailAt2s", "at 2 s", "{:.2f}", True),
    ("detailAt4s", "at 4 s", "{:.2f}", True),
]


def _dget(row, key):
    """A detail value; results from before the brightness-stable start only have detailFadeS."""
    v = row.get(key)
    if v is None and key == "detailBrightStableS":
        v = row.get("detailFadeS")
    return v


def _fmt(fmt, v):
    return "-" if v is None else fmt.format(v)


def run_report(r):
    out = [f"# {r.get('label')} ({r.get('time')})", "",
           f"- scenario `{r.get('scenario')}`, profile `{(r.get('profile') or {}).get('name')}`, fix **{r.get('fix')}**, "
           f"start {r.get('start')}, pinned {r.get('pinned')}, outcome **{r.get('outcome')}**",
           f"- frames: MangoHud (Proton); {_timing_line(r.get('frameLog'))}", ""]
    w = r.get("warmup")
    if w:
        out.append(f"- warm-up: {w.get('seconds'):g} s ({w.get('mode')}): {w.get('reason')}")
    dr = r.get("diagRange")
    if dr:
        out.append(f"- diagnostics (`diag/*.txt`): {dr.get('note')}")
    if w or dr:
        out.append("")
    rows = r.get("scenes") or []
    if rows:
        out.append("| scene | type | s | frames | " + " | ".join(m[1] for m in METRICS) + " |")
        out.append("|---|---|---:|---:|" + "---:|" * len(METRICS))
        for s in rows:
            out.append(f"| {s['id']} | {s['type']} | {s.get('seconds', 0):.1f} | {s.get('frames', '-')} | "
                       + " | ".join(_fmt(f, s.get(k)) for k, _, f, _ in METRICS) + " |")
        doors = [s for s in rows if s["type"] == "door" and "arriveSec" in s]
        if doors:
            out += ["", "| door leg | arrived after s | after: fps | 1% low | hitches | max ms |", "|---|---:|---:|---:|---:|---:|"]
            for s in doors:
                out.append(f"| {s['id']} | {s['arriveSec']} | {_fmt('{:.1f}', s.get('afterFps'))} | "
                           f"{_fmt('{:.1f}', s.get('afterLow1'))} | {_fmt('{:.0f}', s.get('afterHitches'))} | "
                           f"{_fmt('{:.1f}', s.get('afterWorstMs'))} |")
    det = [s for s in rows if "detailSamples" in s]
    if det:
        out += ["", "Detail arrival (brightness-normalised sharpness; 'sharp after' counts from the moment the brightness is "
                "stable, 'sharp at' from the arrival; sharpness relative to the final value):", "",
                "| scene | samples | " + " | ".join(m[1] for m in DETAIL_METRICS) + " |",
                "|---|---:|" + "---:|" * len(DETAIL_METRICS)]
        for s in det:
            out.append(f"| {s['id']} | {s['detailSamples']} | "
                       + " | ".join(_fmt(f, _dget(s, k)) for k, _, f, _ in DETAIL_METRICS) + " |")
    if r.get("warnings"):
        out += ["", "## Warnings", ""] + [f"- {w}" for w in r["warnings"]]
    out += ["", "A hitch is a frame longer than max(2 x the scene's median, 40 ms); 1% / 0.1% low = 1000 / the 99th / "
            "99.9th percentile frame time.", ""]
    return "\n".join(out)


def _timing_line(t):
    if not t:
        return "no frame log"
    return f"log start from {t.get('method')} ({t.get('frames')} frames in `{t.get('log')}`)"


# ---------------------------------------------------------------- comparison

def resolve_run(name, results_dir):
    """A run folder: a path holding result.json, or the newest results/<time>-<name>."""
    p = Path(name)
    if (p / "result.json").exists():
        return p
    hits = sorted(d for d in Path(results_dir).glob(f"*-{name}") if (d / "result.json").exists())
    if not hits:
        raise FileNotFoundError(f"no run named '{name}' in {results_dir}")
    return hits[-1]


def load_runs(names, results_dir):
    out = []
    for n in names:
        d = resolve_run(n, results_dir)
        out.append((d, json.loads((d / "result.json").read_text())))
    return out


def _median(v):
    v = [x for x in v if x is not None]
    return statistics.median(v) if v else None


def compare(runs_a, runs_b, name_a="A", name_b="B"):
    """{scene: {metric: {a, b, deltaPct, noise, aRuns, bRuns}}} over the scenes measured on both sides."""
    def by_scene(runs):
        m = {}
        for _, r in runs:
            for s in r.get("scenes") or []:
                if s.get("frames"):
                    m.setdefault(s["id"], []).append(s)
        return m
    a, b = by_scene(runs_a), by_scene(runs_b)
    order = [s for s in a if s in b]
    out = {}
    for sid in order:
        row = {"type": a[sid][0]["type"], "runs": [len(a[sid]), len(b[sid])]}
        for key, _, _, _ in METRICS:
            va = [s.get(key) for s in a[sid]]
            vb = [s.get(key) for s in b[sid]]
            ma, mb = _median(va), _median(vb)
            d = None
            if ma is not None and mb is not None and ma:
                d = 100.0 * (mb - ma) / ma
            row[key] = {"a": ma, "b": mb, "deltaPct": None if d is None else round(d, 1),
                        "noise": d is not None and abs(d) < NOISE_PCT, "aRuns": va, "bRuns": vb}
        for key, _, _, _ in DETAIL_METRICS:
            va = [_dget(s, key) for s in a[sid]]
            vb = [_dget(s, key) for s in b[sid]]
            ma, mb = _median(va), _median(vb)
            if ma is None and mb is None:
                continue
            d = None if ma is None or mb is None else mb - ma
            pct = None if d is None or not ma else 100.0 * d / ma
            row.setdefault("detail", {})[key] = {"a": ma, "b": mb, "delta": None if d is None else round(d, 3),
                                                 "deltaPct": None if pct is None else round(pct, 1),
                                                 "aRuns": va, "bRuns": vb}
        out[sid] = row
    return {"a": name_a, "b": name_b, "scenes": out,
            "onlyA": [s for s in a if s not in b], "onlyB": [s for s in b if s not in a]}


def compare_markdown(cmp, runs_a, runs_b):
    a, b = cmp["a"], cmp["b"]
    first = (runs_a or runs_b)[0][1]
    out = [f"# {a} vs {b}", "",
           f"- {time.strftime('%Y-%m-%d %H:%M')}, scenario `{first.get('scenario')}`, profile "
           f"`{(first.get('profile') or {}).get('name')}`, Linux (Steam + Proton), frames from MangoHud",
           f"- {a}: {', '.join(r.get('label', str(d)) for d, r in runs_a)}",
           f"- {b}: {', '.join(r.get('label', str(d)) for d, r in runs_b)}",
           f"- each cell: median of the runs, {a} -> {b} (change); `~` = under {NOISE_PCT:.0f} %, within run-to-run noise",
           ""]
    keys = ["fps", "low1", "low01", "worstMs", "hitches", "cpuLoad", "gpuLoad"]
    titles = {k: t for k, t, _, _ in METRICS}
    fmts = {k: f for k, _, f, _ in METRICS}
    out.append("| scene | runs | " + " | ".join(titles[k] for k in keys) + " |")
    out.append("|---|---|" + "---|" * len(keys))
    for sid, row in cmp["scenes"].items():
        cells = []
        for k in keys:
            c = row[k]
            if c["a"] is None or c["b"] is None:
                cells.append("-")
                continue
            d = "" if c["deltaPct"] is None else f" ({c['deltaPct']:+.0f}%{' ~' if c['noise'] else ''})"
            cells.append(f"{fmts[k].format(c['a'])} -> {fmts[k].format(c['b'])}{d}")
        out.append(f"| {sid} | {row['runs'][0]}+{row['runs'][1]} | " + " | ".join(cells) + " |")
    dets = {sid: row["detail"] for sid, row in cmp["scenes"].items() if row.get("detail")}
    if dets:
        out += ["", "## Detail arrival (time to sharp textures)", "",
                f"Median of the runs, {a} -> {b} (change). The sharpness is Laplacian variance over mean luminance squared. "
                "'Sharp after' runs from the moment the brightness is stable (within 3 % of its final value for 1 s), "
                "'sharp at' from the arrival; the sharpness at 1 / 2 / 4 s is relative to the final value (1.00 = already sharp). Lower time and higher sharpness "
                "are better.", "",
                "| scene | " + " | ".join(t for _, t, _, _ in DETAIL_METRICS) + " |",
                "|---|" + "---|" * len(DETAIL_METRICS)]
        for sid, dd in dets.items():
            cells = []
            for k, _, f, _ in DETAIL_METRICS:
                c = dd.get(k)
                if not c or c["a"] is None or c["b"] is None:
                    cells.append("-" if not c else f"{_fmt(f, c['a'])} -> {_fmt(f, c['b'])}")
                    continue
                secs = k in TIME_KEYS
                unit = " s" if secs else ""
                chg = f"{c['delta']:+.1f} s" if secs else (
                    f"{c['deltaPct']:+.0f}%" if c["deltaPct"] is not None else "")
                cells.append(f"{f.format(c['a'])} -> {f.format(c['b'])}{unit} ({chg})")
            out.append(f"| {sid} | " + " | ".join(cells) + " |")
    if cmp["onlyA"] or cmp["onlyB"]:
        out += ["", f"Measured on one side only: {', '.join(cmp['onlyA'] + cmp['onlyB'])}"]
    warn = [(r.get("label"), w) for _, r in runs_a + runs_b for w in r.get("warnings") or []]
    if warn:
        out += ["", "## Warnings of the runs", ""] + [f"- {l}: {w}" for l, w in warn]
    out += ["", "Per scene and run, the full numbers are in each run's result.json / report.md. A hitch is a frame "
            "longer than max(2 x median, 40 ms) (upstream's definition).", ""]
    return "\n".join(out)


def write_comparison(runs_a, runs_b, name_a, name_b, results_dir, label="report"):
    cmp = compare(runs_a, runs_b, name_a, name_b)
    d = Path(results_dir) / f"{time.strftime('%Y%m%d-%H%M%S')}-{label}"
    d.mkdir(parents=True, exist_ok=True)
    (d / "report.json").write_text(json.dumps(dict(cmp, runsA=[str(p) for p, _ in runs_a],
                                                   runsB=[str(p) for p, _ in runs_b]), indent=1))
    (d / "report.md").write_text(compare_markdown(cmp, runs_a, runs_b))
    return d


def redetail_runs(runs):
    """[(dir, result)] -> the same with every scene's detail keys recomputed from its stored detailSeries
    (the current analysis: brightness-normalised, timing from brightness-stable). Inputs are not changed."""
    from . import detail
    out = []
    for d, r in runs:
        r2 = dict(r, scenes=[detail.redetail(s) for s in r.get("scenes") or []])
        out.append((d, r2))
    return out


def write_redetail(runs, results_dir):
    """Write each re-analysed run to results/<its folder name>-redetail/ (result.json + report.md); returns the
    new [(dir, result)] list."""
    out = []
    for d, r in redetail_runs(runs):
        nd = Path(results_dir) / (Path(d).name + "-redetail")
        nd.mkdir(parents=True, exist_ok=True)
        (nd / "result.json").write_text(json.dumps(r, indent=1))
        (nd / "report.md").write_text(run_report(r))
        out.append((nd, r))
    return out
