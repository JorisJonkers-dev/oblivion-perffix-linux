# Tuning OsPageCache offline: trace, simulator, miss-cost benchmark

Date: 2026-11-07. Branch `oscache-sim` (from `proton-mode`). Status: tooling built and tested; **no real trace exists yet**, so
every policy number below comes from a *synthetic* trace and shows how the tools behave, not what the game does.

## Why

`OsPageCache` (`src/OblivionPerfFix/src/memory/os_page_cache.cpp`) keeps the blocks the allocator releases to the OS (cap
64 MB, exact size match, 5 s) and hands them out again for the allocator's own cache misses. Under Proton its hit rate was
17-44 % (about 10,000 releases over the cap per session). Each miss is a `VirtualAlloc` + page faults + `VirtualFree`, and Wine
runs them through ntdll's virtual-memory code under one lock. Trying a cap or keep time live costs a game run each, so: record
once, replay many times.

## How to record a trace

```bash
linux/build-dll.sh                                   # -> build-linux/OblivionPerfFix.dll
linux/bench.py run ... --dll build-linux/OblivionPerfFix.dll --fix-ini OsPageCacheTrace=1
```

- `OsPageCacheTrace=1` (ini, `[Fixes]`, default 0) records every alloc and free the cache sees; `OsPageCacheTraceMB` (default
  64, 4-1024) is the file size. Start-up or live: the detours are installed at start-up when `OsPageCache=1` **or** the trace key
  is 1 (with `OsPageCache=0` it records the game's stock behaviour); afterwards the key switches recording on and off every
  second (a new recording truncates the file).
- File: `OblivionPerfFix-oscache-trace.bin` next to the DLL (the game's `Win64` folder, where the ini and the log are). The
  runner copies it into `results/<run>/diag/` when `--fix-ini OsPageCacheTrace=1` is given (also without `--diag`; it is in
  `fixini.DIAG_FILES` and `collect_diag` now runs for that key). Copy it by hand otherwise.
- Format: 64-byte header + a ring of 16-byte records (layout in `src/memory/os_page_cache_trace.cpp`): microseconds since
  start (QPC), kind, thread, size in bytes, a 32-bit address hash that is the same for the alloc and the free of one block.
  Kinds: alloc hit / miss / cache-off / other caller; free kept / passed / cache-off; eviction by cap / per-size limit / no slot /
  trim / flush; settings mark. At 16 bytes and a few thousand records a second, 64 MB holds roughly 15-60 minutes; when full
  the oldest records are overwritten (the simulator unrolls the ring).
- Overhead: off = one relaxed atomic load per call. On = a compare-exchange to claim a slot in a 2 MB in-memory ring, one
  `QueryPerformanceCounter`, two stores; a background thread appends to the file every 250 ms and rewrites the header (so a
  crash loses at most 250 ms). If the buffer is full the record is dropped and counted (`dropped` in the header and the stats
  line `[oscache] trace: N records written, M dropped`); a single thread hammering 5 million records a second does drop
  (self-test: 268,928 of 400,000), the game's few thousand a second does not. Not yet measured in the game: check the
  dropped count and the frame times of the first real recording.
- Self-test: 15 new checks in `tests/selftest_oscache.h` (header, record order and kinds, sizes, shared address ids, time
  order, settings marks, ring wrap with bounded file size and correct unrolling, 4 threads: every record written or counted
  as dropped, key 0 stops it and later operations are not recorded). 1488 PASS before, 1503 PASS, 0 FAIL after
  (`linux/selftest.sh`).

## Replay: `tools/oscache_sim.py` (Python, standard library)

```bash
python3 tools/oscache_sim.py info    TRACE                  # kinds, rates, top sizes, the ceiling for exact-size reuse
python3 tools/oscache_sim.py run     TRACE --classes        # current + variants; per size class tables
python3 tools/oscache_sim.py run     TRACE -p cap=256,keep=15000 -p cap=256,keep=15000,evict=lru,per_size=1
python3 tools/oscache_sim.py grid    TRACE [--grid small|exact|full] [--mem peak|avg] [--obj hit|bytes|ms] --csv all.csv
python3 tools/oscache_sim.py costs   build-linux/oscache-bench/costs.csv
python3 tools/oscache_sim.py selftest                       # 10 checks against hand-made traces
```

Model (mirrors `Put` / `Take` / `Release` in the DLL): a freed block of at most `min(16 MB, cap/8)` is kept; one exact size
may hold at most `per_size` x cap (0.5); over the cap the oldest block goes; blocks unused for `keep` ms are released on a 1 s
tick; the newest block of a size is handed out first; 8192 slots. Requests are the cache-miss callers only
(`alloc-hit/miss/off`); other callers always get fresh blocks. The replay of `current` is compared with the hit rate the DLL
recorded in the same trace (`run` prints both; differences come from a trace starting mid-run, ring wrap, MemoryRelief flushes).

Policies it can try: cap, keep time, per-size share, per-power-of-two-class quota, eviction (`fifo` = oldest first, as now;
`lru` = give up the size class requested least recently; `big` = largest block first), take order, **size rounding**
(`pow2`, `pow2h`, `g<K>k`: a miss allocates the rounded size and any request of that rounded size reuses it), **slack**
(`slack=1.25`: a request may be served by a block up to 25 % bigger). Reports: hit rate (requests and bytes), average / peak
bytes held, peak held + rounding waste of live blocks, kept / evicted / trimmed / refused, estimated ms saved using the
measured miss costs, per size class tables, and a Pareto front (minimum memory for each hit-rate gain; larger-block policies
marked `*`, plus a front restricted to exact-size policies).

### Can the game take a larger block than it asked for?

**Not shown by anything in this repository, so treat rounding and slack as unproven upper bounds and test exact-size
policies first.** What the DLL source does show: the detour returns only a pointer; every caller of `BinnedFreeToOS` passes the
size the block was allocated with (`os_page_cache.cpp` header comment); `VirtualFree(MEM_RELEASE)` ignores size; the game's own
cache already hands out recycled blocks of the same size with old contents. A bigger block would need a pointer -> real size
side table in the DLL (so the block is later kept and released at its real size) and would hold extra memory the game's
accounting does not know about. Whether Binned2 or a caller relies on the block being exactly the size it asked for
(alignment, page-count bookkeeping, the OOM reserve) is in UE source that is not in this repo and must not be copied in; check
it in the engine's `FMallocBinned2` / `FCachedOSPageAllocator` before building it. `exact` + `slack=1` is the shipped behaviour.

## Miss cost: `linux/oscache-bench.sh`

`tools/oscache_bench.cpp` (clang-cl, same xwin toolchain as `linux/selftest.sh`) times `VirtualAlloc(MEM_RESERVE|MEM_COMMIT,
PAGE_READWRITE)`, a write to every 4 KB page (the first touch faults each page in), and `VirtualFree(MEM_RELEASE)` for the
sizes the cache sees, plus the cost of writing a block that is already resident (what a hit still pays). Headless Wine (no
`DISPLAY` / `WAYLAND_DISPLAY`, `winex11.drv` / `winewayland.drv` disabled, `ShowCrashDialog=0`), the throwaway prefix of
`selftest.sh`. 4 threads run the same loop at once to show the lock; `--bg 3000` first fills the address space with 3000
live 64 KB blocks and 256 1 MB blocks. Raw table: `docs/research-linux/ideas/oscache-sim-costs-wine.csv`.

Measured on this PC (16 CPUs, Linux 7.3.1-cachyos, wine-11.21 Staging; the bench is stable to ~1 % when the PC is idle; an
early run while other jobs were busy came out 2x slower, so re-run on a quiet PC):

| block | alloc us | first-touch us | free us | **miss total us** | 4 threads at once, total us | busy address space (3000 blocks), 1 thread | a hit still pays (re-touch) |
|---|---|---|---|---|---|---|---|
| 64 KB | 3.6 | 18.5 | 6.4 | **28.5** | 98.5 | 28.5 | 0.1 |
| 128 KB | 3.5 | 36.7 | 9.2 | **49.5** | 131.8 | 49.8 | 0.2 |
| 256 KB | 3.7 | 74.1 | 13.4 | **91.1** | 192.4 | 91.5 | 0.3 |
| 512 KB | 3.9 | 149.5 | 23.4 | **176.8** | 305.0 | 177.1 | 0.6 |
| 1 MB | 4.0 | 300.4 | 41.9 | **346.3** | 541.9 | 350.7 | 1.4 |
| 2 MB | 4.1 | 600.1 | 78.0 | **682.2** | 1003 | 690.3 | 3.0 |
| 4 MB | 4.2 | 694.4 | 82.6 | **781.2** | 1248 | 789.7 | 7.0 |
| 8 MB | 4.4 | 878.9 | 89.4 | **972.6** | 1829 | 969.5 | 14.8 |
| 16 MB | 4.5 | 1246 | 102.7 | **1353** | 3111 | 1353 | 29.8 |

Reading: about 28 us for a 64 KB page (1.8 us per page, nearly all of it the page faults), 0.35 ms per MB up to 2 MB, 1.35
ms for a 16 MB block. The `VirtualAlloc` call itself is 3.5-4.5 us at any size; the cost is first touch and release, which a
cache hit avoids (the physical pages stay mapped). With 4 threads doing it at once a 64 KB miss costs 3.5x as much (98 us):
that is the shared lock / page-fault path in Wine, and the reason a miss on a worker thread can stall others. A busy address
space changed nothing for one thread (3000 live blocks). These are costs of this Wine on this PC, not Proton's nor Windows'
(Windows `VirtualAlloc` is usually cheaper per page); `oscache_sim.py ... --costs` takes any table with the same columns.

**What a miss costs in total is small unless it is a big block or a hitch**: the log's ~300 eligible requests a second (mean 168 KB, ~60 us
each) cost ~18 ms a second of thread time if every one missed (under 2 % of one core); going from 32 % to 44 % hits saves
~2 ms a second (synthetic trace). The reason to raise the hit rate is the large classes (a 4-16 MB miss is 0.8-1.4 ms, and 3 ms with contention)
landing on the game thread during a streaming hitch, which the per-class tables show; weigh policies by `--obj ms`, not only
hit rate.

## Synthetic trace (clearly not the game)

The existing logs only have totals (`hits 5507 (1453 MB), misses 26463 (3507 MB), kept ..., over cap ...`); they pre-date the
`[oscache] by size` line, so no per-size data exists anywhere yet. `tools/oscache_synth.py` fits what the totals allow: from
the four `[oscache]` runs in `linux/results` (191,944 eligible requests in 621 s = 309/s, mean 168 KB, live hit rate 30.8 %,
per run 17 / 17 / 17 / 44 %) it generates bursts of allocations in 15-45 s epochs (what is streamed in during an epoch dies
together, far over the cap), a share of short-lived bursts bisected until replaying `current` gives the log's 30.8 %, a
geometric size mix over 64 KB-16 MB, 48 distinct sizes per class above 64 KB. The file header carries a *synthetic* flag and
every simulator report prints a banner. Assumptions that move the results: size mix, burst and epoch structure, lifetimes.

`python3 tools/oscache_synth.py -o synth.bin` then the commands above. Results on it (600 s, 175,546 eligible requests; replay
of `current` = 31.8 % hits, 36 MB held on average, 64 MB peak):

| policy | hit % | hit % by bytes | avg MB held | peak MB | est. ms saved / min* |
|---|---|---|---|---|---|
| current (64 MB, 5 s, exact, oldest out) | 31.8 | 19.8 | 36 | 64 | 250 |
| cap 128 MB, keep 15 s | 36.5 | 24.7 | 89 | 128 | 308 |
| cap 256 MB, keep 15 s | 43.5 | 29.6 | 140 | 256 | 368 |
| cap 256 MB, keep 15 s, LRU, per-size 1.0 | 51.0 | 27.6 | 149 | 256 | 355 |
| cap 256 MB, keep 15 s, round to 64 KB (larger block) | 45.5 | 34.5 | 106 | 362 incl. waste | 425 |
| cap 256 MB, keep 15 s, slack 1.25 (larger block) | 46.8 | 38.7 | 82 | 285 incl. waste | 462 |
| cap 256 MB, keep 15 s, round to 2^n (larger block) | 43.2 | 38.2 | 69 | 1154 incl. waste | 446 |
| cap 1024 MB, keep 15 s | 60.9 | 42.0 | 420 | 1024 | 522 |
| unbounded, never trimmed (ceiling for exact size) | 88.1 | 68.1 | 1620 | 3229 | 815 |

\* with the measured Wine miss cost; the hit rate is what the tool reports, the ms are only as good as the cost table.

`grid` (800 policies, ~80 s on 16 cores) Pareto front, exact-size policies only, memory = peak held:

| policy | hit % | avg MB | peak MB |
|---|---|---|---|
| cap 32, keep 60 s, per-size 1.0, LRU | 33.2 | 28 | 32 |
| cap 64, keep 60 s, per-size 1.0, LRU | 39.4 | 53 | 64 |
| cap 128, keep 60 s, per-size 1.0, LRU | 50.4 | 100 | 128 |
| cap 256, keep 60 s, per-size 1.0, LRU | 63.0 | 194 | 256 |
| cap 512, keep 60 s, LRU | 74.0 | 351 | 512 |

What the synthetic data says about the *tool* (not the game): on a trace where whole epochs die together, **the cap and the
keep time dominate**, a longer keep time only pays with a bigger cap, LRU-by-size-class keeps more distinct sizes alive (higher
hit rate, but lower hit-by-bytes than FIFO at the same cap), per-class quotas and "biggest first" trade hit rate for fewer large
blocks held, and larger-block service (rounding / slack) mainly raises *hit by bytes* (the big classes) at 10-30 % extra
peak (2^n rounding wastes much more: 1.15 GB of rounding waste live at 256 MB cap). Whether any of that holds depends on the
real size mix, which is why the real trace comes first.

## Recommended first A/B (live)

1. **Config only, exact-size, no code change:** `OsPageCacheMB=256`, `OsPageCacheKeepMs=15000` against the shipped
   64 MB / 5 s (A/B/A with `bench.py ... --variant`/`--fix-ini`, watch the HitchLedger and the `[oscache]` hit/miss per size
   lines). It is the cheapest step on every synthetic front, costs on average ~100 MB more RAM (peak 256 MB; MemoryRelief
   still returns it when RAM or commit is short), and needs nothing the game could object to. If the hit rate barely moves, the
   workload is not reuse-bound and the cache cannot help much more.
2. **At the same time, record the trace** (`OsPageCacheTrace=1`) in the A run, then `oscache_sim.py grid TRACE --costs
   build-linux/oscache-bench/costs.csv --obj ms` and replace this recommendation with the trace's own front. Check
   `info` first: if "unbounded exact-size reuse" is itself low, no cache policy helps.
3. Next, only if the trace says so: LRU-by-size eviction with `per_size=1.0` (small code change, exact-size, same safety), then
   larger-block service after the allocator question above is answered.

## Files

`src/OblivionPerfFix/src/memory/os_page_cache_trace.cpp` (writer), hooks in `os_page_cache.cpp`, keys in `config.cpp` /
`common.h` / `OblivionPerfFix.ini` / `main.cpp`; `tools/oscache_sim.py`, `tools/oscache_synth.py`, `tools/oscache_bench.cpp`;
`linux/oscache-bench.sh`; runner: `linux/oblvbench/fixini.py` (`DIAG_FILES`), `runner.py` (`collect_diag` for the trace key).
