#!/usr/bin/env python3
"""Offline simulator for OblivionPerfFix's OsPageCache (src/memory/os_page_cache.cpp).

Replays an allocation trace (OblivionPerfFix-oscache-trace.bin, written with [Fixes] OsPageCacheTrace=1, or a SYNTHETIC one
from tools/oscache_synth.py) against cache policies and reports hit rate, memory held and OS calls avoided, per size
class. Standard library only.

  oscache_sim.py info  TRACE                      what the trace holds, what was recorded live, the infinite-cache bound
  oscache_sim.py run   TRACE [-p POLICY ...]      replay named/explicit policies (default: current + a few variants)
  oscache_sim.py grid  TRACE [--grid small|full]  grid search over caps, keep times, rounding, quotas, eviction; Pareto front
  oscache_sim.py dump  TRACE [-n N]               first N records as text
  oscache_sim.py costs BENCH.csv                  the miss-cost table of linux/oscache-bench.sh
  oscache_sim.py selftest                         checks the replay against hand-made traces

A POLICY is "name" (a preset from PRESETS) or "key=value,key=value" over: cap (MB), keep (ms), per_size (fraction of the cap
one exact size may hold), quota (fraction of the cap one power-of-two class may hold; 0 = none), evict (fifo|lru|big),
take (newest|oldest), round (exact|pow2|pow2h|g<K>k), slack (a request may be served by a block up to slack x its
size; 1 = exact), maxblock (MB; 0 = the current rule min(16, cap/8)), nodes, tick (ms between trims, 1000 as the DLL's).

Size rounding and slack > 1 mean the cache hands a request a block LARGER than it asked for (and a rounded fresh block on a
miss). The DLL's detour only returns a pointer and the game frees with the size it asked for, so this needs a pointer -> real
size side table in the DLL; whether Binned2 tolerates it is NOT shown by this repo (docs/research-linux/ideas/oscache-sim.md);
treat those policies as upper bounds until checked. exact + slack 1 is the current behaviour.
"""
import argparse
import bisect
import collections
import csv
import itertools
import math
import multiprocessing
import os
import struct
import sys

HDR = struct.Struct("<8sIIQQQQIIII")  # magic, version, recSize, qpcFreq, startQpc, capacity, total, capMB, keepMs, flags, dropped
assert HDR.size == 64
MAGIC = b"OPFOSTRC"
(ALLOC_HIT, ALLOC_MISS, ALLOC_OFF, ALLOC_OTHER, FREE_KEPT, FREE_PASSED, FREE_OFF, EV_CAP, EV_SIZE, EV_ROOM, EV_TRIM,
 EV_FLUSH, MARK) = range(1, 14)
KIND_NAMES = {1: "alloc-hit", 2: "alloc-miss", 3: "alloc-off", 4: "alloc-other", 5: "free-kept", 6: "free-passed",
              7: "free-off", 8: "evict-cap", 9: "evict-size", 10: "evict-room", 11: "evict-trim", 12: "evict-flush",
              13: "mark"}
FLAG_SYNTHETIC = 1
PAGE = 4096
MB = 1 << 20


# ---- trace files -------------------------------------------------------------------------------------------------------
class Trace:
    def __init__(self, path, hdr, events):
        self.path, self.hdr, self.events = path, hdr, events  # events: (t_us, kind, size, id, tid), oldest first
        self.synthetic = bool(hdr["flags"] & FLAG_SYNTHETIC)


def read_trace(path):
    with open(path, "rb") as f:
        raw = f.read()
    if len(raw) < 64:
        sys.exit(f"{path}: not a trace (too short)")
    magic, ver, rec, freq, start, cap, total, capmb, keepms, flags, dropped = HDR.unpack_from(raw, 0)
    if magic != MAGIC or ver != 1 or rec != 16:
        sys.exit(f"{path}: not an OsPageCache trace (magic {magic!r}, version {ver}, record {rec})")
    n = min(total, cap, (len(raw) - 64) // 16)
    first = total % cap if total > cap else 0
    body = memoryview(raw)[64:64 + 16 * n]
    recs = list(struct.iter_unpack("<QQ", body))
    if first:
        recs = recs[first:] + recs[:first]
    ev = []
    for w0, w1 in recs:
        ev.append((w0 >> 24, w0 & 0xFF, w1 >> 32, w1 & 0xFFFFFFFF, (w0 >> 8) & 0xFFFF))
    hdr = dict(version=ver, freq=freq, capacity=cap, total=total, capMB=capmb, keepMs=keepms, flags=flags, dropped=dropped,
               wrapped=total > cap)
    return Trace(path, hdr, ev)


def write_trace(path, events, cap_mb=64, keep_ms=5000, flags=0, capacity=None):
    """events: (t_us, kind, size, id, tid) oldest first. Writes a trace file the DLL's own layout (no wrap)."""
    capacity = capacity or max(len(events), 1)
    with open(path, "wb") as f:
        f.write(HDR.pack(MAGIC, 1, 16, 1000000, 0, capacity, len(events), cap_mb, keep_ms, flags, 0))
        for t, k, size, aid, tid in events:
            f.write(struct.pack("<QQ", k | (tid & 0xFFFF) << 8 | t << 24, aid | min(size, 0xFFFFFFFF) << 32))


def size_class(size):
    """The DLL's ClassOf: log2 of the size in 4 KB units, 0..12."""
    c, v = 0, size >> 12
    while v > 1 and c < 12:
        v >>= 1
        c += 1
    return c


def class_label(c):
    kb = 4 << c
    return (f"{kb >> 10} MB" + ("+" if c == 12 else "")) if kb >= 1024 else f"{kb} KB"


# ---- cost model (microseconds one OS block costs when it is NOT reused: VirtualAlloc + first touch + VirtualFree) --------
DEFAULT_COSTS = [  # size_kb, pair_us: measured by linux/oscache-bench.sh under Wine 11.21 (Staging) on the dev PC, 1 thread, empty
    # address space (docs/research-linux/ideas/oscache-sim-costs-wine.csv). Not Windows, not another PC: pass --costs for yours.
    (64, 28.50), (128, 49.51), (256, 91.13), (512, 176.77), (1024, 346.29), (2048, 682.15), (4096, 781.19), (8192, 972.61),
    (16384, 1353.39)]


class CostModel:
    def __init__(self, rows=None, source="built-in: Wine 11.21 on the dev PC (oscache-sim-costs-wine.csv)"):
        self.rows = sorted(rows or DEFAULT_COSTS)
        self.source = source
        self.xs = [math.log2(r[0]) for r in self.rows]

    @classmethod
    def from_csv(cls, path):
        rows = []
        with open(path, newline="") as f:
            for r in csv.DictReader(line for line in f if not line.startswith("#")):
                if r.get("threads", "1") != "1" or r.get("bg_blocks", "0") != "0":
                    continue
                rows.append((float(r["size_kb"]), float(r["pair_us"])))
        if not rows:
            sys.exit(f"{path}: no single-thread rows (size_kb,pair_us)")
        return cls(rows, f"measured: {path}")

    def pair_us(self, size):
        kb = max(size / 1024.0, 1.0)
        x = math.log2(kb)
        xs, rows = self.xs, self.rows
        if len(rows) == 1:
            return rows[0][1] * kb / rows[0][0]
        i = min(max(bisect.bisect_left(xs, x), 1), len(xs) - 1)
        (x0, y0), (x1, y1) = (xs[i - 1], rows[i - 1][1]), (xs[i], rows[i][1])
        return max(0.0, y0 + (y1 - y0) * (x - x0) / (x1 - x0))  # linear in log2(size): extrapolates at both ends


# ---- policies ----------------------------------------------------------------------------------------------------------
class Policy:
    FIELDS = dict(cap=64.0, keep=5000.0, per_size=0.5, quota=0.0, evict="fifo", take="newest", round="exact", slack=1.0,
                  maxblock=0.0, nodes=8192, tick=1000.0)

    def __init__(self, **kw):
        for k, v in self.FIELDS.items():
            setattr(self, k, kw.pop(k, v))
        if kw:
            raise ValueError("unknown policy key(s): " + ", ".join(kw))
        self.cap_b = int(self.cap * MB)
        self.maxblock_b = int(self.maxblock * MB) if self.maxblock else min(16 * MB, self.cap_b // 8)
        self.rnd = make_rounder(self.round)
        if self.evict not in ("fifo", "lru", "big") or self.take not in ("newest", "oldest"):
            raise ValueError("evict is fifo|lru|big, take is newest|oldest")

    @property
    def tolerant(self):
        return self.round != "exact" or self.slack > 1.0

    def label(self):
        d = [f"cap={self.cap:g}", f"keep={self.keep:g}"]
        for k in ("per_size", "quota", "evict", "take", "round", "slack", "maxblock", "nodes", "tick"):
            if getattr(self, k) != self.FIELDS[k]:
                d.append(f"{k}={getattr(self, k):g}" if isinstance(getattr(self, k), float) else f"{k}={getattr(self, k)}")
        return ",".join(d)

    @classmethod
    def parse(cls, text):
        if text in PRESETS:
            return cls(**PRESETS[text])
        kw = {}
        for part in text.split(","):
            if not part:
                continue
            k, _, v = part.partition("=")
            if k not in cls.FIELDS:
                raise ValueError(f"unknown policy key {k!r} (presets: {', '.join(PRESETS)})")
            t = type(cls.FIELDS[k])
            kw[k] = t(v) if t is not str else v
        return cls(**kw)


def make_rounder(spec):
    if spec == "exact":
        return lambda s: s
    if spec == "pow2":
        return lambda s: 1 << (max(s, PAGE) - 1).bit_length()
    if spec == "pow2h":  # 2^n or 1.5 * 2^n

        def f(s):
            p = 1 << (max(s, PAGE) - 1).bit_length()
            return p * 3 // 4 if s <= p * 3 // 4 and p >= 2 * PAGE else p
        return f
    if spec.startswith("g") and spec.endswith("k"):
        g = int(spec[1:-1]) * 1024
        return lambda s: -(-s // g) * g
    raise ValueError(f"round is exact|pow2|pow2h|g<K>k, not {spec!r}")


PRESETS = {
    "current": dict(),  # 64 MB, exact, 5 s, one size <= half the cap, oldest first, newest block handed out
    "cap128": dict(cap=128), "cap256": dict(cap=256), "cap512": dict(cap=512),
    "keep15s": dict(keep=15000), "keep60s": dict(keep=60000), "keep1s": dict(keep=1000),
    "cap256-keep15s": dict(cap=256, keep=15000),
    "lru": dict(evict="lru"), "big-first": dict(evict="big"),
    "pow2": dict(round="pow2"), "g64k": dict(round="g64k"), "pow2h": dict(round="pow2h"),
    "fit1.25": dict(slack=1.25), "fit2": dict(slack=2.0),
    "quota25": dict(quota=0.25),
    "cap256-pow2-keep15s": dict(cap=256, keep=15000, round="pow2"),
    "unbounded": dict(cap=1 << 20, keep=1e12, per_size=1.0, maxblock=1024),  # the upper bound for exact-size reuse
}
DEFAULT_RUN = ["current", "cap128", "cap256", "keep15s", "cap256-keep15s", "lru", "pow2", "fit1.25", "quota25", "unbounded"]


# ---- the replay --------------------------------------------------------------------------------------------------------
class Result:
    __slots__ = ("policy", "requests", "hits", "hit_bytes", "req_bytes", "others", "frees", "kept", "evicted", "trimmed",
                 "ev_cap", "ev_size", "ev_room", "ev_quota", "refused", "peak_held", "peak_total", "avg_held", "saved_us",
                 "cls", "span_s", "wasted_kept")

    def hit_rate(self):
        return self.hits / self.requests if self.requests else 0.0


def prepare(trace):
    """The replay stream: (t_ms, op, size, id) with op 0 = eligible alloc (cache-miss caller), 1 = other alloc, 2 = free."""
    out = []
    for t, k, size, aid, _tid in trace.events:
        if k in (ALLOC_HIT, ALLOC_MISS, ALLOC_OFF):
            out.append((t / 1000.0, 0, size, aid))
        elif k == ALLOC_OTHER:
            out.append((t / 1000.0, 1, size, aid))
        elif k in (FREE_KEPT, FREE_PASSED, FREE_OFF):
            out.append((t / 1000.0, 2, size, aid))
    return out


def replay(stream, pol, costs=None):
    cost = costs.pair_us if costs else (lambda s: 0.0)
    cap, keep, tick = pol.cap_b, pol.keep, pol.tick
    per_size_b = int(pol.per_size * cap)
    quota_b = int(pol.quota * cap) if pol.quota else 0
    rnd, slack, maxblock, nodes = pol.rnd, pol.slack, pol.maxblock_b, pol.nodes
    newest = pol.take == "newest"
    evict_mode = pol.evict
    buckets = {}                   # real size -> deque of (bid, t_free)
    sizes = []                     # sorted real sizes with a non-empty bucket (only used when slack > 1)
    order = collections.deque()    # (bid) in release order (trim and 'room' eviction), lazily purged
    alive = {}                     # bid -> (real, t_free)
    size_bytes = collections.defaultdict(int)
    class_bytes = collections.defaultdict(int)
    last_req = {}                  # real size -> time of the last request served from / for that size (for lru)
    live = {}                      # trace id -> (real, requested)
    held = waste = 0
    peak_held = peak_total = 0
    area = 0.0
    next_tick = None
    bid = 0
    r = Result()
    r.policy = pol
    r.requests = r.hits = r.hit_bytes = r.req_bytes = r.others = r.frees = r.kept = r.evicted = r.trimmed = 0
    r.ev_cap = r.ev_size = r.ev_room = r.ev_quota = r.refused = r.wasted_kept = 0
    r.saved_us = 0.0
    r.cls = collections.defaultdict(lambda: [0, 0, 0, 0, 0, 0, 0])  # requests, hits, kept, refused, evicted, trimmed, hit bytes
    reused = set()
    tlast = stream[0][0] if stream else 0.0
    t0 = tlast

    def remove(b):
        """Takes block b out of the cache structures; returns its real size."""
        nonlocal held
        real, _tf = alive.pop(b)
        dq = buckets[real]
        if dq[0][0] == b:  # usually at an end of its size's list
            dq.popleft()
        elif dq[-1][0] == b:
            dq.pop()
        else:
            for i, e in enumerate(dq):
                if e[0] == b:
                    del dq[i]
                    break
        if not dq:
            del buckets[real]
            if slack > 1.0:
                sizes.pop(bisect.bisect_left(sizes, real))
        held -= real
        size_bytes[real] -= real
        class_bytes[real.bit_length()] -= real
        return real

    def drop(b, why):
        """Block b goes to the OS (counted by reason)."""
        real = remove(b)
        if b not in reused:
            r.wasted_kept += 1
        r.cls[size_class(real)][5 if why == "trim" else 4] += 1
        if why == "trim":
            r.trimmed += 1
        else:
            r.evicted += 1
            if why == "cap":
                r.ev_cap += 1
            elif why == "size":
                r.ev_size += 1
            elif why == "room":
                r.ev_room += 1
            else:
                r.ev_quota += 1

    def oldest_alive():
        while order and order[0] not in alive:
            order.popleft()
        return order[0] if order else None

    def victim(exclude_real):
        """The block to give up when over the cap, by the evict policy; never the block just added (it is the last of its size)."""
        if evict_mode == "fifo":
            while order and order[0] not in alive:
                order.popleft()
            for b in order:  # oldest first; skip the new block
                if b in alive and b != exclude_real:
                    return b
            return None
        best, key = None, None
        for real, dq in buckets.items():
            cand = dq[0][0] if dq[0][0] != exclude_real else (dq[1][0] if len(dq) > 1 else None)
            if cand is None:
                continue
            k = last_req.get(real, -1.0) if evict_mode == "lru" else -real
            if key is None or k < key:
                best, key = cand, k
        return best

    for t, op, size, aid in stream:
        if next_tick is None:
            next_tick = t + tick
        # time passes: held bytes integrate, the 1-second trims run (the DLL trims on its main loop's tick)
        while next_tick <= t:
            area += held * (next_tick - tlast)
            tlast = next_tick
            while True:
                b = oldest_alive()
                if b is None or next_tick - alive[b][1] < keep:
                    break
                drop(b, "trim")
            next_tick += tick
        area += held * (t - tlast)
        tlast = t
        if op == 2:
            r.frees += 1
            real, req = live.pop(aid, (size, size))
            waste -= real - req
            if real < PAGE or real & (PAGE - 1) or real > maxblock:
                r.refused += 1
                r.cls[size_class(real)][3] += 1
                continue
            bid += 1
            if len(alive) >= nodes:
                b = oldest_alive()
                drop(b, "room")
            dq = buckets.get(real)
            if dq is None:
                dq = buckets[real] = collections.deque()
                if slack > 1.0:
                    bisect.insort(sizes, real)
            dq.append((bid, t))
            alive[bid] = (real, t)
            order.append(bid)
            held += real
            size_bytes[real] += real
            cb = real.bit_length()
            class_bytes[cb] += real
            ok = True
            while size_bytes[real] > per_size_b:
                if len(dq) <= 1:
                    ok = False
                    break
                drop(dq[0][0], "size")
            if ok and quota_b:
                while class_bytes[cb] > quota_b:
                    vb = None
                    for rr, dd in buckets.items():
                        if rr.bit_length() == cb and (len(dd) > 1 or rr != real):
                            vb = dd[0][0] if dd[0][0] != bid else (dd[1][0] if len(dd) > 1 else None)
                            if vb is not None:
                                break
                    if vb is None:
                        ok = False
                        break
                    drop(vb, "quota")
            while ok and held > cap:
                v = victim(bid)
                if v is None:
                    ok = False
                    break
                drop(v, "cap")
            if not ok or held > cap or size_bytes[real] > per_size_b:  # still over: this block is not kept either
                remove(bid)
                r.refused += 1
                r.cls[size_class(real)][3] += 1
                continue
            r.kept += 1
            r.cls[size_class(real)][2] += 1
            if held > peak_held:
                peak_held = held
            if held + waste > peak_total:
                peak_total = held + waste
        elif op == 1:
            r.others += 1
            live[aid] = (size, size)
        else:
            r.requests += 1
            r.req_bytes += size
            c = r.cls[size_class(size)]
            c[0] += 1
            want = rnd(size)
            last_req[want] = t
            got = None
            if slack == 1.0:
                dq = buckets.get(want)
                if dq:
                    got = want
            else:
                i = bisect.bisect_left(sizes, want)
                if i < len(sizes) and sizes[i] <= want * slack:
                    got = sizes[i]
            if got is not None:
                dq = buckets[got]
                b, _tf = dq.pop() if newest else dq.popleft()
                alive.pop(b)
                reused.add(b)
                if not dq:
                    del buckets[got]
                    if slack > 1.0:
                        sizes.pop(bisect.bisect_left(sizes, got))
                held -= got
                size_bytes[got] -= got
                class_bytes[got.bit_length()] -= got
                r.hits += 1
                r.hit_bytes += size
                c[1] += 1
                c[6] += size
                r.saved_us += cost(size)
                live[aid] = (got, size)
                waste += got - size
            else:
                live[aid] = (want, size)
                waste += want - size
            if held + waste > peak_total:
                peak_total = held + waste
    r.peak_held, r.peak_total = peak_held, peak_total
    r.span_s = (tlast - t0) / 1000.0
    r.avg_held = area / (tlast - t0) if tlast > t0 else 0.0
    return r


# ---- reports -----------------------------------------------------------------------------------------------------------
def banner(trace):
    if trace.synthetic:
        print("*** SYNTHETIC TRACE: generated by tools/oscache_synth.py, not recorded from the game. Numbers show how the "
              "tool behaves, not what the game does. ***")
    h = trace.hdr
    note = "ring wrapped (oldest records lost)" if h["wrapped"] else "complete"
    print(f"trace {trace.path}: {len(trace.events)} records of {h['total']} written ({note}), {h['dropped']} dropped at record time, "
          f"settings at start cap {h['capMB']} MB keep {h['keepMs']} ms")


def fmt_row(cols, widths):
    return "  ".join(str(c).rjust(w) for c, w in zip(cols, widths))


def table(header, rows):
    widths = [max(len(str(x)) for x in col) for col in zip(header, *rows)] if rows else [len(h) for h in header]
    print(fmt_row(header, widths))
    for row in rows:
        print(fmt_row(row, widths))


def summary_rows(results, costs):
    rows = []
    for r in results:
        rows.append([r.policy.label() if len(r.policy.label()) < 46 else r.policy.label()[:45] + "~",
                     f"{100 * r.hit_rate():.1f}%", f"{100 * r.hit_bytes / r.req_bytes:.1f}%" if r.req_bytes else "-",
                     r.hits, f"{r.avg_held / MB:.1f}", f"{r.peak_held / MB:.1f}", f"{r.peak_total / MB:.1f}",
                     r.kept, r.evicted, r.trimmed, r.refused, f"{r.saved_us / 1e3:.0f}",
                     f"{r.saved_us / 1e3 / (r.span_s / 60):.0f}" if r.span_s else "-"])
    return rows


SUMMARY_HEAD = ["policy", "hit%", "hit%MB", "hits", "avgMB", "peakMB", "peak+waste", "kept", "evicted", "trimmed", "refused", "saved ms", "ms/min"]


def per_class_table(r):
    rows = []
    for c in sorted(r.cls):
        q, h, k, ref, ev, tr, hb = r.cls[c]
        rows.append([class_label(c), q, h, f"{100 * h / q:.1f}%" if q else "-", k, ref, ev, tr, f"{hb / MB:.0f}"])
    table(["class", "requests", "hits", "hit%", "kept", "refused", "evicted", "trimmed", "hit MB"], rows)


def cmd_info(a):
    tr = read_trace(a.trace)
    banner(tr)
    ev = tr.events
    if not ev:
        return
    kinds = collections.Counter(e[1] for e in ev)
    span = (ev[-1][0] - ev[0][0]) / 1e6
    print(f"span {span:.1f} s, {len(ev) / max(span, 1e-9):.0f} records/s")
    table(["kind", "records"], [[KIND_NAMES.get(k, k), n] for k, n in sorted(kinds.items())])
    marks = [(t / 1e6, s, i) for t, k, s, i, _ in ev if k == MARK]
    for t, s, i in marks[:8]:
        print(f"  mark at {t:.1f} s: cap {s >> 20} MB, cache {'on' if s & 1 else 'off'}, keep {i} ms")
    h, m = kinds[ALLOC_HIT], kinds[ALLOC_MISS]
    if h + m:
        print(f"recorded by the DLL: {h} hits / {m} misses = {100 * h / (h + m):.1f}% hit rate (cache on)")
    stream = prepare(tr)
    sizes = collections.Counter(s for _, op, s, _ in stream if op == 0)
    print(f"{sum(sizes.values())} cache-eligible allocs of {len(sizes)} distinct sizes; top sizes:")
    table(["size KB", "allocs", "share"], [[s >> 10, n, f"{100 * n / sum(sizes.values()):.1f}%"] for s, n in sizes.most_common(12)])
    res = replay(stream, Policy.parse("unbounded"))
    print(f"exact-size reuse with an unbounded, never-trimmed cache: {100 * res.hit_rate():.1f}% (peak {res.peak_held / MB:.0f} MB) "
          "-- the ceiling for any exact-size policy")
    per_class_table(res)


def cmd_costs(a):
    """Renders linux/oscache-bench.sh's CSV: the cost of one cache miss (VirtualAlloc + touch + VirtualFree) per size."""
    with open(a.csv, newline="") as f:
        text = f.read().splitlines()
    for line in text:
        if line.startswith("#"):
            print(line)
    rows = list(csv.DictReader(line for line in text if not line.startswith("#")))
    out = []
    for r in rows:
        kb, pair, rt = float(r["size_kb"]), float(r["pair_us"]), float(r["retouch_us"])
        out.append([f"{kb:g}", r["threads"], r["bg_blocks"], r["alloc_us"], r["touch_us"], r["free_us"], r["pair_us"], r["pair_p50_us"],
                    r["pair_p95_us"], r["retouch_us"], f"{max(pair - rt, 0.0) / 1000.0:.3f}", f"{pair / (kb / 4):.3f}"])
    table(["size KB", "threads", "bg", "alloc us", "touch us", "free us", "pair us", "p50", "p95", "retouch us", "saved ms/hit", "us/page"], out)
    print("saved ms/hit = pair - retouch: a hit still writes the (resident) pages, so only the OS calls and the page faults are saved")


def cmd_dump(a):
    tr = read_trace(a.trace)
    banner(tr)
    for t, k, size, aid, tid in tr.events[:a.n]:
        print(f"{t / 1e6:12.6f}s  {KIND_NAMES.get(k, k):12s}  {size:>10d}  id {aid:08x}  tid {tid:04x}")


def load_costs(a):
    return CostModel.from_csv(a.costs) if a.costs else CostModel()


def cmd_run(a):
    tr = read_trace(a.trace)
    banner(tr)
    costs = load_costs(a)
    print(f"miss cost model: {costs.source}")
    stream = prepare(tr)
    names = a.policy or DEFAULT_RUN
    pols = [Policy.parse(n) for n in names]
    results = [replay(stream, p, costs) for p in pols]
    kinds = collections.Counter(e[1] for e in tr.events)
    h, m = kinds[ALLOC_HIT], kinds[ALLOC_MISS]
    if h + m:
        cur = results[0] if names[0] == "current" else replay(stream, Policy.parse("current"), costs)
        print(f"check: the DLL recorded {100 * h / (h + m):.1f}% hits ({h}/{h + m}); the replay of 'current' gives "
              f"{100 * cur.hit_rate():.1f}% ({cur.hits}/{cur.requests}). Differences: a trace that starts mid-run, ring wrap, "
              "the DLL's real clock, relief flushes.")
    print()
    table(SUMMARY_HEAD, [[n if len(n) < 46 else n[:45]] + row[1:] for n, row in zip(names, summary_rows(results, costs))])
    print("\npolicy columns: " + "; ".join(f"{n} = {r.policy.label()}" for n, r in zip(names, results) if n in PRESETS))
    if a.classes:
        for n, r in zip(names, results):
            print(f"\nper size class: {n} ({r.policy.label()})")
            per_class_table(r)


GRIDS = {
    "small": dict(cap=[32, 64, 128, 256, 512], keep=[1000, 2500, 5000, 15000, 60000], round=["exact", "pow2", "g64k"],
                  slack=[1.0, 1.25], evict=["fifo", "lru"], per_size=[0.5, 1.0], quota=[0.0, 0.25]),
    "full": dict(cap=[16, 32, 64, 96, 128, 192, 256, 384, 512, 1024], keep=[500, 1000, 2500, 5000, 10000, 15000, 30000, 60000, 300000],
                 round=["exact", "pow2", "pow2h", "g64k", "g256k"], slack=[1.0, 1.25, 2.0], evict=["fifo", "lru", "big"],
                 per_size=[0.25, 0.5, 1.0], quota=[0.0, 0.25, 0.5], take=["newest", "oldest"]),
    "exact": dict(cap=[16, 32, 64, 96, 128, 192, 256, 384, 512], keep=[500, 1000, 2500, 5000, 10000, 15000, 30000, 60000],
                  per_size=[0.25, 0.5, 1.0], evict=["fifo", "lru", "big"], quota=[0.0, 0.25]),  # no larger-block service: safe set
}
_G = {}


def _init(stream, costs):
    _G["stream"], _G["costs"] = stream, costs


def _one(kw):
    pol = Policy(**kw)
    r = replay(_G["stream"], pol, _G["costs"])
    return (kw, r.hit_rate(), r.hit_bytes / r.req_bytes if r.req_bytes else 0.0, r.avg_held, r.peak_held, r.peak_total, r.saved_us,
            r.hits, r.evicted + r.trimmed, r.refused)


def grid_points(spec):
    keys = list(spec)
    pts = []
    for combo in itertools.product(*(spec[k] for k in keys)):
        kw = dict(zip(keys, combo))
        if kw.get("round", "exact") != "exact" and kw.get("slack", 1.0) != 1.0:
            continue  # rounding and slack are alternatives
        pts.append(kw)
    return pts


def pareto(rows, xi, yi, step=0.0):
    """rows are (…); minimise column xi (memory), maximise yi (benefit). Returns the non-dominated rows sorted by memory;
    with step > 0 a row must beat the previous one by that much (relative to the best value) to be listed."""
    best = []
    top = max(r[yi] for r in rows) if rows else 0.0
    for row in sorted(rows, key=lambda r: (r[xi], -r[yi])):
        if not best or row[yi] > best[-1][yi] + max(step * top, 1e-12):
            best.append(row)
    return best


def cmd_grid(a):
    tr = read_trace(a.trace)
    banner(tr)
    costs = load_costs(a)
    print(f"miss cost model: {costs.source}")
    stream = prepare(tr)
    spec = dict(GRIDS[a.grid])
    pts = grid_points(spec)
    print(f"grid '{a.grid}': {len(pts)} policies over {len(stream)} operations, {a.jobs} worker(s)")
    if a.jobs > 1:
        with multiprocessing.Pool(a.jobs, _init, (stream, costs)) as pool:
            rows = pool.map(_one, pts, chunksize=4)
    else:
        _init(stream, costs)
        rows = [_one(p) for p in pts]
    if a.csv:
        with open(a.csv, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["policy", "hit_rate", "hit_byte_rate", "avg_held_mb", "peak_held_mb", "peak_total_mb", "saved_ms", "hits",
                        "released", "refused"])
            for kw, hr, hbr, avg, pk, pt, sv, hits, rel, ref in rows:
                w.writerow([Policy(**kw).label(), f"{hr:.5f}", f"{hbr:.5f}", f"{avg / MB:.2f}", f"{pk / MB:.2f}", f"{pt / MB:.2f}",
                            f"{sv / 1e3:.1f}", hits, rel, ref])
        print(f"all rows -> {a.csv}")
    obj = {"hit": 1, "bytes": 2, "ms": 6}[a.obj]
    mem = {"peak": 5, "avg": 3, "held": 4}[a.mem]
    front = pareto(rows, mem, obj, a.step)
    _init(stream, costs)
    cur = _one(dict(cap=64, keep=5000))
    print(f"\ncurrent policy: hit {100 * cur[1]:.1f}%, avg held {cur[3] / MB:.1f} MB, peak {cur[5] / MB:.1f} MB, saves {cur[6] / 1e3:.0f} ms")
    print(f"\nPareto front: {a.obj} vs {a.mem} memory (minimum memory for each achievable gain; larger-block policies are marked *)")
    out = []
    for kw, hr, hbr, avg, pk, pt, sv, hits, rel, ref in front:
        p = Policy(**kw)
        out.append([("*" if p.tolerant else " ") + p.label(), f"{100 * hr:.1f}%", f"{100 * hbr:.1f}%", f"{avg / MB:.1f}", f"{pt / MB:.1f}",
                    f"{sv / 1e3:.0f}", f"{100 * (hr - cur[1]):+.1f}"])
    table(["policy", "hit%", "hit%MB", "avgMB", "peak+waste", "saved ms", "d hit"], out)
    exact = [r for r in rows if not Policy(**r[0]).tolerant]
    if exact and len(exact) != len(rows):
        print("\nPareto front restricted to exact-size policies (no larger block ever returned):")
        out = []
        for kw, hr, hbr, avg, pk, pt, sv, hits, rel, ref in pareto(exact, mem, obj, a.step):
            out.append([" " + Policy(**kw).label(), f"{100 * hr:.1f}%", f"{100 * hbr:.1f}%", f"{avg / MB:.1f}", f"{pt / MB:.1f}",
                        f"{sv / 1e3:.0f}", f"{100 * (hr - cur[1]):+.1f}"])
        table(["policy", "hit%", "hit%MB", "avgMB", "peak+waste", "saved ms", "d hit"], out)
    top = sorted(rows, key=lambda r: -r[obj])[:a.top]
    print(f"\ntop {a.top} by {a.obj} regardless of memory:")
    table(["policy", "hit%", "avgMB", "peak+waste"],
          [[Policy(**r[0]).label(), f"{100 * r[1]:.1f}%", f"{r[3] / MB:.1f}", f"{r[5] / MB:.1f}"] for r in top])


def cmd_selftest(_a):
    """Hand-made traces with known answers (the DLL's own rules: exact size, newest first, cap, half-cap per size, trim)."""
    K = 1024
    n = [0]

    def check(cond, what):
        n[0] += 1
        print(("PASS  " if cond else "FAIL  ") + what)
        if not cond:
            sys.exit(1)

    def ev(*rows):  # (t_ms, 'a'|'o'|'f', size_kb, id)
        out = []
        for t, op, kb, i in rows:
            out.append((float(t), {"a": 0, "o": 1, "f": 2}[op], kb * K, i))
        return out
    P = Policy.parse
    r = replay(ev((0, "a", 64, 1), (1, "f", 64, 1), (2, "a", 64, 2), (3, "a", 128, 3), (4, "f", 64, 2), (5, "a", 64, 4)), P("current"))
    check(r.requests == 4 and r.hits == 2 and r.kept == 2, "exact size: the freed 64 KB block serves the next 64 KB request, not a 128 KB one")
    r = replay(ev((0, "a", 64, 1), (1, "f", 64, 1), (6000, "a", 64, 2)), P("current"))
    check(r.hits == 0 and r.trimmed == 1, "a block unused for the keep time (5 s, trimmed on the 1 s tick) is released")
    r = replay(ev((0, "a", 64, 1), (1, "f", 64, 1), (3000, "a", 64, 2)), P("current"))
    check(r.hits == 1, "a block younger than the keep time is reused")
    # cap 4 MB (min) -> max block 512 KB, one size at most 2 MB: 5 x 512 KB freed keeps 4
    rows = [(0, "a", 512, i) for i in range(1, 6)] + [(1, "f", 512, i) for i in range(1, 6)]
    r = replay(ev(*rows), P("cap=4"))
    check(r.kept == 5 and r.ev_size == 1 and r.peak_held == 2 * MB, "one size holds at most half the cap: the oldest block goes")
    r = replay(ev((0, "a", 1024, 1), (1, "f", 1024, 1)), P("cap=4"))
    check(r.refused == 1 and r.kept == 0, "blocks over cap/8 are not kept")
    rows = [(0, "a", 64, i) for i in range(1, 4)] + [(1, "f", 64, i) for i in range(1, 4)] + [(2, "a", 64, 9)]
    r = replay(ev(*rows), P("take=oldest"))
    check(r.hits == 1, "take=oldest still reuses a block")
    r = replay(ev((0, "a", 100, 1), (1, "f", 100, 1), (2, "a", 90, 2)), P("slack=1.25"))
    check(r.hits == 1, "slack 1.25: a 100 KB block serves a 90 KB request")
    r = replay(ev((0, "a", 100, 1), (1, "f", 100, 1), (2, "a", 90, 2)), P("current"))
    check(r.hits == 0, "exact: the same pair misses")
    r = replay(ev((0, "a", 90, 1), (1, "f", 90, 1), (2, "a", 100, 2), (3, "f", 100, 2), (4, "a", 70, 3)), P("round=g64k"))
    check(r.hits == 2 and r.peak_total >= 128 * K, "round=g64k: 90 and 100 KB both become 128 KB blocks and are reused; the rounding waste is counted")
    r = replay(ev((0, "a", 100, 1), (1, "f", 100, 1), (2, "a", 100, 2), (3, "f", 100, 2), (4, "a", 100, 3)), P("evict=lru,cap=4"))
    check(r.hits == 2, "evict=lru works")
    print(f"selftest: {n[0]} PASS")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("info")
    p.add_argument("trace")
    p.set_defaults(fn=cmd_info)
    p = sub.add_parser("costs")
    p.add_argument("csv")
    p.set_defaults(fn=cmd_costs)
    p = sub.add_parser("selftest")
    p.set_defaults(fn=cmd_selftest)
    p = sub.add_parser("dump")
    p.add_argument("trace")
    p.add_argument("-n", type=int, default=40)
    p.set_defaults(fn=cmd_dump)
    p = sub.add_parser("run")
    p.add_argument("trace")
    p.add_argument("-p", "--policy", action="append")
    p.add_argument("--costs", help="miss-cost CSV from linux/oscache-bench.sh (size_kb,pair_us,...)")
    p.add_argument("--classes", action="store_true", help="per size class tables")
    p.set_defaults(fn=cmd_run)
    p = sub.add_parser("grid")
    p.add_argument("trace")
    p.add_argument("--grid", choices=sorted(GRIDS), default="small")
    p.add_argument("--jobs", type=int, default=min(os.cpu_count() or 1, 16))
    p.add_argument("--obj", choices=["hit", "bytes", "ms"], default="hit", help="benefit axis of the Pareto front")
    p.add_argument("--mem", choices=["peak", "avg", "held"], default="peak", help="memory axis: peak held+rounding waste, average held, peak held")
    p.add_argument("--costs")
    p.add_argument("--csv")
    p.add_argument("--top", type=int, default=10)
    p.add_argument("--step", type=float, default=0.02, help="list a Pareto point only if it gains this fraction of the best value (default 0.02)")
    p.set_defaults(fn=cmd_grid)
    a = ap.parse_args(argv)
    a.fn(a)


if __name__ == "__main__":
    main()
