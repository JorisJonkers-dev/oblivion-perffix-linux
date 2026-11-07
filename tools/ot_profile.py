"""Ranks the diagnostic OtProfile's csv (OblivionPerfFix-otprofile.csv, written next to the DLL with OtProfile=1 in
OblivionPerfFix.ini at start-up; docs/how-it-works.md "The old engine's thread").

Usage:
    py tools/ot_profile.py <otprofile.csv> [--from-ms A --to-ms B] [--top 15] [--out x.md]

Reads the 2-second aggregate rows (S) and the slow-cycle rows (F). Prints:
  - the OT's cycle: busy (working) vs idle (waiting inside RunSession(-2) for the game thread), and how long the game
    thread waited for the OT inside RunSession(-1) (only when NpcCreationPacing was off);
  - the stages ranked by total time and by time in slow cycles (a stage inside another is marked, lvl_* run inside
    pl_update, so totals overlap), with the average per call;
  - the slow cycles: how many, the worst, and which stage dominates them (the sampled engine marker too).
Times are QueryPerformanceCounter milliseconds (HitchLedger's clock), so --from-ms/--to-ms take a bench scene's
t0Ms/t1Ms. Standard library only.
"""
import argparse
import collections
import sys

MARKERS = {0x0: "frame start", 0x32: "ProcessLists pass 1 done", 0x64: "ProcessLists::Update",
           0x6E: "Update start", 0x78: "Update: level pass 1", 0x82: "Update: level pass 2",
           0x8C: "Update: level pass 3", 0xB4: "Update: level pass 4", 0xBE: "Update done",
           0xC8: "ProcessLists pass 2", 0x12C: "ProcessLists pass 3",
           0x190: "after the passes (player, grid, door, ...)"}
NESTED = {"lvl_low", "lvl_midlow", "lvl_midhigh", "lvl_high"}   # inside pl_update


def parse(path):
    """-> (header dict, F rows, S rows, M rows); rows are dicts keyed by the csv's column names."""
    cols = {}
    f, s, m, head = [], [], [], ""
    with open(path, encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            if line.startswith("# OblivionPerfFix-otprofile"):
                head = line
            elif line.startswith("#F,") or line.startswith("#S,"):
                cols[line[1]] = line[1:].split(",")
            elif line.startswith("F,") or line.startswith("S,"):
                names = cols.get(line[0])
                if not names:
                    continue
                v = line.split(",")
                row = {n: x for n, x in zip(names, v)}
                (f if line[0] == "F" else s).append(row)
            elif line.startswith("M,"):
                v = line.split(",", 3)
                if len(v) == 4:
                    m.append((float(v[1]), int(v[2]), v[3]))
    return head, f, s, m


def num(row, key, default=0.0):
    try:
        return float(row[key])
    except (KeyError, ValueError):
        return default


def stage_names(rows):
    names = []
    for k in (rows[0] if rows else {}):
        if k.endswith("_ms") and k.startswith(("pl_", "lvl_", "grid_", "door", "water", "save")) and not k.startswith("slow_"):
            names.append(k[:-3])
    return names


def marker_label(text):
    try:
        v = int(text, 16)
    except (TypeError, ValueError):
        return "?"
    return "%s (%s)" % (text, MARKERS.get(v, "stage"))


def report(path, lo=None, hi=None, top=15):
    head, f, s, m = parse(path)
    out = []
    if lo is not None or hi is not None:
        keep = lambda r: (lo is None or num(r, "end_ms") >= lo) and (hi is None or num(r, "end_ms") <= hi)
        f, s = [r for r in f if keep(r)], [r for r in s if keep(r)]
        m = [x for x in m if (lo is None or x[0] >= lo) and (hi is None or x[0] <= hi)]
    out.append("OT profile: %s" % path)
    if head:
        out.append(head.lstrip("# ").split(", signals")[0])
    if not s:
        out.append("no 2 s aggregates in the selected range")
        return "\n".join(out) + "\n"
    frames = sum(num(r, "frames") for r in s)
    cycle = sum(num(r, "cycle_ms") for r in s)
    busy = sum(num(r, "busy_ms") for r in s)
    idle = sum(num(r, "idle_ms") for r in s)
    body = sum(num(r, "body_ms") for r in s)
    slow = sum(num(r, "slow") for r in s)
    slow_busy = sum(num(r, "slow_busy_ms") for r in s)
    gt_known = [r for r in s if num(r, "gtwait_ms", -1) >= 0]
    gt = sum(num(r, "gtwait_ms") for r in gt_known)
    gt_n = sum(num(r, "gtwait_n") for r in gt_known)
    out.append("")
    out.append("== The OT's cycle (%d windows, %d cycles, %.1f s) ==" % (len(s), frames, sum(num(r, "window_s") for r in s)))
    if frames:
        out.append("cycle   %7.2f ms avg" % (cycle / frames))
        out.append("busy    %7.2f ms avg  (%4.1f%% of the cycle)  frame body %.2f ms avg" % (busy / frames, 100 * busy / max(cycle, 1e-9), body / frames))
        out.append("idle    %7.2f ms avg  (%4.1f%%)  = waiting in RunSession(-2) for the game thread" % (idle / frames, 100 * idle / max(cycle, 1e-9)))
        if gt_known:
            out.append("GT wait %7.2f ms avg per OT cycle (%d RunSession(-1) calls) = the game thread waiting for the OT" % (gt / max(sum(num(r, "frames") for r in gt_known), 1), gt_n))
        else:
            out.append("GT wait  not measured (NpcCreationPacing owns that call: use HitchLedger's pair column)")
        out.append("slow cycles (busy >= threshold): %d (%.2f%%), average busy %.1f ms" % (slow, 100 * slow / frames, slow_busy / max(slow, 1)))
        out.append("worst busy cycle in a window: %.1f ms" % max(num(r, "max_busy_ms") for r in s))
    names = stage_names(s)
    tot = {n: sum(num(r, n + "_ms") for r in s) for n in names}
    cnt = {n: sum(num(r, n + "_n") for r in s) for n in names}
    slw = {n: sum(num(r, "slow_" + n + "_ms") for r in s) for n in names}
    other = body - sum(t for n, t in tot.items() if n not in NESTED)
    out.append("")
    out.append("== Stages by total time (ms per cycle on average; 'in' = inside pl_update, not added to the sum) ==")
    out.append("%-14s %9s %9s %8s %9s %9s" % ("stage", "total_s", "ms/cycle", "calls", "ms/call", "slow_s"))
    rows = sorted(names, key=lambda n: -tot[n])[:top]
    for n in rows:
        out.append("%-14s %9.2f %9.3f %8d %9.3f %9.2f%s" % (n, tot[n] / 1000, tot[n] / max(frames, 1), cnt[n], tot[n] / max(cnt[n], 1),
                                                           slw[n] / 1000, "  in" if n in NESTED else ""))
    out.append("%-14s %9.2f %9.3f   (frame body not in a timed stage)" % ("other", max(other, 0) / 1000, max(other, 0) / max(frames, 1)))
    out.append("")
    out.append("== Stages by time in slow cycles ==")
    for n in sorted(names, key=lambda n: -slw[n])[:top]:
        if slw[n] > 0:
            out.append("%-14s %9.2f s  (%4.1f%% of slow busy time)%s" % (n, slw[n] / 1000, 100 * slw[n] / max(slow_busy, 1e-9), "  in" if n in NESTED else ""))
    if m:
        hist = collections.Counter()
        for _, _, row in m:
            for part in row.split(";"):
                if "=" in part:
                    k, v = part.split("=")
                    hist[k] += int(v)
        total = sum(hist.values())
        out.append("")
        out.append("== Engine stage marker, share of samples (all cycles, idle included: marker stays at the last stage while waiting) ==")
        for k, v in hist.most_common(top):
            out.append("%-40s %6.1f%%" % (marker_label(k), 100 * v / total))
    if f:
        out.append("")
        out.append("== Slow cycles: %d rows ==" % len(f))
        dom = collections.Counter()
        for r in f:
            best = max(names, key=lambda n: num(r, n + "_ms") if n not in NESTED else 0) if names else None
            if best:
                dom[best if num(r, best + "_ms") >= num(r, "other_ms") else "other"] += 1
        out.append("dominant top-level stage: " + ", ".join("%s %d" % kv for kv in dom.most_common(6)))
        mk = collections.Counter(r.get("marker", "") for r in f if r.get("marker"))
        if mk:
            out.append("sampled marker of the slow cycles: " + ", ".join("%s x%d" % (marker_label(k), v) for k, v in mk.most_common(5)))
        out.append("worst:")
        for r in sorted(f, key=lambda r: -num(r, "busy_ms"))[:5]:
            parts = sorted(((num(r, n + "_ms"), n) for n in names), reverse=True)[:3]
            out.append("  t=%.0f ms busy %.1f (idle %.1f) body %.1f other %.1f  marker %s  %s" % (
                num(r, "end_ms"), num(r, "busy_ms"), num(r, "idle_ms"), num(r, "body_ms"), num(r, "other_ms"), r.get("marker") or "-",
                ", ".join("%s %.1f" % (n, v) for v, n in parts if v > 0)))
    return "\n".join(out) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("csv")
    ap.add_argument("--from-ms", type=float)
    ap.add_argument("--to-ms", type=float)
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--out")
    a = ap.parse_args(argv)
    text = report(a.csv, a.from_ms, a.to_ms, a.top)
    if a.out:
        with open(a.out, "w", encoding="utf-8") as fh:
            fh.write(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
