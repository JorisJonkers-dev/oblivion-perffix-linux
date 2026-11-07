#!/usr/bin/env python3
"""SYNTHETIC OsPageCache trace generator, fitted to the `[oscache]` statistics lines of OblivionPerfFix.log.

This is NOT a recording of the game. The log only holds totals (hits, misses, their bytes, kept, released), and in older
logs no per-size counts, so the size mix, burst structure and block lifetimes below are assumptions; only the request rate,
the mean request size and the live hit rate under the current policy (64 MB, exact size, 5 s) are fitted to the log. Use it
to exercise tools/oscache_sim.py and to see how the policies *could* rank; replace it with a real trace
(OsPageCacheTrace=1, docs/research-linux/ideas/oscache-sim.md) before believing a number. The output file carries the
header flag "synthetic", which the simulator prints on every report.

  oscache_synth.py -o synth.bin [--log LOG ...] [--seconds 600] [--seed 1] [--target-hit 0.30] [--diversity N] [--churn F]

Model: bursts of allocations (a streaming step) arrive as a Poisson process; a "short" burst (share `churn`) is recycled
within milliseconds to seconds, every other burst lives until the end of its 15-45 s epoch and all of an epoch dies together
(cell unloads and level-of-detail swaps release hundreds of MB at once, far over the cap); a burst is mostly one size; sizes follow a geometric mix over 64 KB .. 16 MB classes fitted to the mean request size; sizes above
64 KB come in `diversity` distinct 4 KB-granular values per class (default 48). `churn` (the share of bursts that live
under ~3 s, the rest epoch-long) is bisected so that replaying 'current' reproduces --target-hit (default: the hit rate
in the log).
"""
import argparse
import glob
import math
import os
import random
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import oscache_sim as sim  # noqa: E402

STAT = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+) \[oscache\] hits (\d+) \(([\d.]+) MB\), misses (\d+) \(([\d.]+) MB\), "
                  r"kept (\d+), passed (\d+); released: over cap (\d+), one size over half (\d+), no slot (\d+), unused (\d+)")
FIRST = re.compile(r"^(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+) \[oscache\] installed")
BYSIZE = re.compile(r"(\d+) (KB|MB): hit (\d+)/miss (\d+)")


def stamp(s):
    import datetime
    return datetime.datetime.strptime(s, "%Y-%m-%d %H:%M:%S.%f").timestamp()


def parse_log(path):
    first = last = by = None
    with open(path, errors="replace") as f:
        for line in f:
            m = FIRST.match(line)
            if m and first is None:
                first = stamp(m.group(1))
            m = STAT.match(line)
            if m:
                last = m
            if "[oscache] by size:" in line:
                by = line
    if not (first and last):
        return None
    g = last.groups()
    d = dict(path=path, secs=stamp(g[0]) - first, hits=int(g[1]), hit_mb=float(g[2]), misses=int(g[3]), miss_mb=float(g[4]),
             kept=int(g[5]), passed=int(g[6]), over_cap=int(g[7]), by_size=None)
    if by:
        d["by_size"] = {(int(a) << 10 if u == "KB" else int(a) << 20): (int(h), int(m)) for a, u, h, m in BYSIZE.findall(by)}
    return d


def find_logs(args):
    if args:
        return args
    here = os.path.dirname(os.path.abspath(__file__))
    for base in (os.path.join(here, "..", "linux", "results"),
                 os.path.join(here, "..", "..", "oblivion-perffix-linux", "linux", "results")):
        logs = sorted(glob.glob(os.path.join(base, "*", "diag", "OblivionPerfFix.log")))
        if logs:
            return logs
    return []


def fit_geometric(mean_bytes, classes):
    """Class weights w_k ~ r**k so that sum(w_k * size_k) / sum(w_k) = mean_bytes (bisection on r)."""
    def mean(r):
        w = [r ** i for i in range(len(classes))]
        return sum(wi * c for wi, c in zip(w, classes)) / sum(w)
    lo, hi = 1e-3, 3.0
    if mean_bytes <= mean(lo):
        return [lo ** i for i in range(len(classes))]
    for _ in range(80):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if mean(mid) < mean_bytes else (lo, mid)
    return [lo ** i for i in range(len(classes))]


def generate(rate, seconds, mean_bytes, diversity, seed, churn=0.5, weights=None, burst_mean=10.0, same_size=0.6):
    rng = random.Random(seed)
    classes = [64 << 10 << i for i in range(9)]  # 64 KB .. 16 MB
    w = weights or fit_geometric(mean_bytes, classes)
    tot = sum(w)
    cum = []
    acc = 0.0
    for x in w:
        acc += x / tot
        cum.append(acc)

    def pick_size():
        u = rng.random()
        k = next((i for i, c in enumerate(cum) if u <= c), len(cum) - 1)
        base = classes[k]
        if k == 0:
            return base  # 64 KB: the small-pool page, always this size
        j = int(diversity ** rng.random()) - 1  # log-uniform over `diversity` distinct values: a few common sizes, a long tail
        return base + 4096 * (j * max(base // 4096 // max(diversity, 1), 1) % (base // 4096))

    # epochs (a cell stream-in, a level-of-detail change): what is streamed in during one dies together at its end
    epochs = []
    te = 0.0
    while te < seconds + 120:
        te += rng.uniform(15, 45)
        epochs.append(te)

    def epoch_end(now):
        return next(e for e in epochs if e > now)

    ev = []
    t = 0.0
    nid = 1
    burst_rate = rate / burst_mean
    while t < seconds:
        t += rng.expovariate(burst_rate)
        n = 1 + int(rng.expovariate(1 / (burst_mean - 1))) if burst_mean > 1 else 1
        u = rng.random()
        short = u < churn
        life = rng.expovariate(1 / 0.04) if u < churn * 0.5 else rng.lognormvariate(math.log(2.5), 0.9)
        end = epoch_end(t)
        csize = pick_size()
        ta = t
        for _ in range(n):
            ta += rng.expovariate(1 / 0.004)
            size = csize if rng.random() < same_size else pick_size()
            if short:
                tf = ta + life * rng.lognormvariate(0, 0.35) + rng.expovariate(1 / 0.002)
            else:
                tf = max(ta + 0.01, end + rng.gauss(0, 0.4) + rng.uniform(0, 0.8))
            ev.append((ta, 0, size, nid))
            ev.append((tf, 1, size, nid))
            nid += 1
    ev.sort()
    out = []
    tid = 0x1000
    for ts, op, size, aid in ev:
        out.append((int(ts * 1e6), sim.ALLOC_OFF if op == 0 else sim.FREE_OFF, size, aid & 0xFFFFFFFF, tid))
    return out


def current_hit(events, cap=64.0, keep=5000):
    class T:  # a minimal Trace for prepare()
        pass
    t = T()
    t.events = events
    return sim.replay(sim.prepare(t), sim.Policy(cap=cap, keep=keep)).hit_rate()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--log", action="append", help="OblivionPerfFix.log file(s) with [oscache] lines (default: linux/results/*/diag)")
    ap.add_argument("--seconds", type=float, default=600.0)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--target-hit", type=float)
    ap.add_argument("--diversity", type=int, help="distinct sizes per class above 64 KB (default 48)")
    ap.add_argument("--churn", type=float, help="share of short-lived bursts, 0..1 (default: fitted to the target hit rate)")
    a = ap.parse_args()
    logs = [d for d in (parse_log(p) for p in find_logs(a.log)) if d and d["hits"] + d["misses"] > 1000]
    if not logs:
        sys.exit("no OblivionPerfFix.log with [oscache] statistics found (use --log)")
    n = sum(d["hits"] + d["misses"] for d in logs)
    secs = sum(d["secs"] for d in logs)
    mb = sum(d["hit_mb"] + d["miss_mb"] for d in logs)
    hit = sum(d["hits"] for d in logs) / n
    rate, mean = n / secs, mb * (1 << 20) / n
    print(f"fitted from {len(logs)} log(s): {n} eligible requests in {secs:.0f} s = {rate:.0f}/s, mean {mean / 1024:.0f} KB, "
          f"live hit rate {100 * hit:.1f}% (per log: " + ", ".join(f"{100 * d['hits'] / (d['hits'] + d['misses']):.0f}%" for d in logs) + ")")
    if any(d["by_size"] for d in logs):
        print("note: these logs have per-size counts, but this generator still uses the geometric fit (TODO: use them directly)")
    target = a.target_hit if a.target_hit is not None else hit
    seed = a.seed
    div = a.diversity or 48
    if a.churn is not None:
        churn = a.churn
    else:  # more short-lived bursts = more reuse: bisect on a 120 s trace
        lo, hi = 0.0, 1.0
        for _ in range(14):
            mid = (lo + hi) / 2
            h = current_hit(generate(rate, 120, mean, div, seed, mid))
            lo, hi = (mid, hi) if h < target else (lo, mid)
        churn = (lo + hi) / 2
        print(f"churn {churn:.3f}, diversity {div}: 'current' replays at ~{100 * current_hit(generate(rate, 120, mean, div, seed, churn)):.1f}% "
              f"(target {100 * target:.1f}%)")
    ev = generate(rate, a.seconds, mean, div, seed, churn)
    cap_records = 4 * 1024 * 1024 - 4
    if len(ev) > cap_records:
        ev = ev[:cap_records]
    sim.write_trace(a.out, ev, flags=sim.FLAG_SYNTHETIC)
    print(f"wrote {a.out}: {len(ev)} records, {a.seconds:.0f} s, SYNTHETIC (replay of 'current': {100 * current_hit(ev):.1f}% hits)")


if __name__ == "__main__":
    main()
