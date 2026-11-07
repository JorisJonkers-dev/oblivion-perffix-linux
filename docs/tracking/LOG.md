# Findings log

Newest first. Each entry gives its date, the finding, its evidence and its confidence. Runs: [runs.md](runs.md).
Investigations: [investigations.md](investigations.md).

## 2026-11-07

### OsPageCache offline tuning kit (branch `oscache-sim`)
**Tools:**
- Trace recorder: `OsPageCacheTrace=1`, writes `OblivionPerfFix-oscache-trace.bin`.
- Replay simulator: `tools/oscache_sim.py`, with grid search, a Pareto front and `--obj ms`.
- Wine miss-cost benchmark: `linux/oscache-bench.sh`.

**Cost of a miss under Wine 11.21 on this PC:** `VirtualAlloc` itself costs 3.5–4.5 µs. The real cost is the first touch
of each page, about 1.8 µs per page.

| Block | Miss cost |
|---|---|
| 64 KB | 28.5 µs |
| 1 MB | 346 µs |
| 16 MB | 1.35 ms |

With 4 threads contending, a miss costs about 3.5× more. That fits Wine's single lock on its virtual-memory code.

**Synthetic trace** (fitted to the logged totals; the policy numbers below are therefore indicative):

| Policy | Hit rate |
|---|---|
| Current | 31.8% |
| 256 MB, 15 s | 43.5% |
| 256 MB, 15 s, LRU | 51% |
| Unbounded ceiling | 88% |

**First live A/B:** `OsPageCacheMB=256`, `OsPageCacheKeepMs=15000`, with `OsPageCacheTrace=1` recording in the same run.
Exact-size reuse only. Policies that hand out larger blocks wait until it is known that the game's allocator tolerates
a bigger block than it asked for.


### Canal spin of the render and cache switches (`spin-canal-render`, 4 slots each): `RdgSubmitBatch` stays on
| Variant | avg fps | 1% low | 0.1% low | Worst frame | Hitches | GPU |
|---|---|---|---|---|---|---|
| base | 75.5 | 56.0 | 38.2 | 32.2 ms | 0 | 98% |
| `RdgParallelTranslate=0` | 80.0 (+6%, noise) | | 42.0 | 38.1 ms | 0 | |
| **`RdgSubmitBatch=0`** | 68.3 | 37.4 (−33%) | **18.4 (−52%)** | **56.2 ms** | **8** | **91%** |
| `OsPageCache=0` | 79.0 (+5%, noise) | | 44.2 (+16%) | | 2 | |

- `RdgSubmitBatch` clearly helps under Proton. Keep it on.
- `RdgParallelTranslate=0` and `OsPageCache=0` look slightly better, but within noise. Retest them in a quiet run (the
  OsPageCache simulator is in progress).
- Noise was high: slot-to-slot spread 33–40%, against 15% earlier. Likely cause: agents building with clang and running
  Wine self-tests on the same machine during the spin.
- **Rule:** no heavy builds or Wine self-tests while a benchmark runs. Check `pgrep -f "clang|wine|selftest"` before
  starting one.
- `--warmup auto` works: it ended when `[pso] shader precompile finished` appeared, at +65.7 s after launch.


### Detail arrival, re-analysed with brightness-normalised sharpness: switches help on entering interiors only
Metric: Laplacian variance divided by the squared mean luminance. Timing starts once the brightness has been stable for
1 s. Re-analysis of the `vtdoor` A/B: 3+3 runs, medians, base → `VtStreamingUploads=64` + `FadeVtFlushSkip=1`.

| Door | Brightness stable | Sharp after it | Sharp, counted from arrival |
|---|---|---|---|
| inn enter | 3.9 → 3.4 s | 0 → 0 s | 5.9 → 3.4 s |
| inn exit | 4.4 → 4.6 s | 3.5 → 4.1 s | 7.9 → 9.1 s |
| chapel enter | 3.4 → 3.8 s | **4.0 → 0.0 s (all 3 runs)** | 7.4 → 3.8 s |
| chapel exit | 4.2 → 4.2 s | 4.0 → 4.0 s | 8.1 → 8.2 s |
| west gate enter | 4.6 → 4.6 s | 0 → 0 s | 4.6 → 4.6 s |
| west gate exit | 4.3 → 4.7 s | 0 → 0 s | 4.3 → 4.7 s |

- Entering interiors: detail arrives 2.5–3.5 s sooner with the switches.
- Leaving to exteriors: no change. Detail keeps sharpening for about 3.5–4.5 s after the brightness settles on both sides.
  That is real streaming, and these switches don't address it.
- The earlier 0.03 and 0.06 ratios were dark frames: an artefact of the old metric.
- Verdict: small benefit, and FPS was mixed (inn enter −13%, the rest within noise). Candidate to enable after a
  confirmation run. Exterior detail arrival is open: see `texture-streaming.md`, the loading-screen prewarm idea.


### Door test of `VtStreamingUploads=64` + `FadeVtFlushSkip=1` with detail arrival (3+3 runs): inconclusive
Report: [runs/20261107-111019-vtdoor.md](runs/20261107-111019-vtdoor.md). The detail capture (xwd through XWayland) works live.

| Door | Sharp after (s) | Sharpness at 1 s |
|---|---|---|
| Inn, entering | 7.9 → 8.1 | 0.03 → 0.97 |
| Inn, leaving | 3.5 → 4.1 | ~ |
| Chapel, entering | 4.5 → 0.5 | 0.90 → 1.00 |
| Chapel, leaving | 2.5 → 5.5 | ~ |
| West gate, leaving | 0.0 → 3.5 | ~ (at 2 s: 0.99 → 0.06) |

- Interior entries look clearly better with the switches; exits are mixed.
- FPS is mixed: inn entry −13%, the rest within noise.
- **Problem with the metric:** Laplacian variance falls with brightness, so the fade-in tail and eye adaptation read as
  blur. The 0.03 and 0.06 values are almost certainly dark frames, not blurry ones.
- Fix needed: normalise sharpness by luminance (or use gradient energy over mean luminance), and start timing only once
  the brightness is stable.
- Not adopted yet.


### Run-log analysis (Haiku): the runner's own sync stalls polluted the ledgers
Source: [../research-linux/ideas/run-log-analysis.md](../research-linux/ideas/run-log-analysis.md).

The runner makes two 350 ms sync frames to align the MangoHud log. They made up 61–68% of the ledger's "unlabelled:
before the world tick" bucket in the `cs-ab3` runs. The earlier conclusion that half of all slow-frame time is
unlabelled was wrong: that half was mostly the runner's own stalls.

With the sync frames removed:
- **PSO precompile in play is the main real cost.** The precompile ends 40–58 s after reaching the world, which is
  longer than the 40 s warm-up. It accounts for 302 of 317 ms of real excess in on-r2. The driver-thread guard finds no
  driver compile threads under Wine, so it does nothing here.
- **Frame-end sync and GPU waits** are large in slow frames; the GPU is the limit at these settings.
- **NPC units:** one unit alone costs 17–61 ms, and the 4 ms budget is overrun 3–9 times per run.
- **Steady tick:** `VPairedPawnMovementComponent` costs 0.63 ms per frame (26% of listed tick time).
- **`OsPageCache`:** hit rate only 17–44%, with about 10k releases over its 64 MB cap.
- No periodic spike pattern, so no sign of GC or autosave timers. No memory pressure.

Fix under way: the runner's warm-up will wait for the PSO precompile to finish, and diag analysis will be limited to the
measured windows (branch `runner-warmup`).


### Idea reviews (Haiku), in `docs/research-linux/ideas/`

**render-streaming.md**
- Re-measure `RdgSubmitBatch` and `RdgParallelTranslate` on RADV; their costs and savings were measured on Windows D3D12.
- Check whether async-compute cvars exist in this build, then flip them live.
- Skip TLAS rebuilds when the inputs are identical.
- Make Nanite's Hierarchy and ImposterData keep their capacity.
- Make the RT upload buffers keep their size.

**npc-physics-loading.md**
- Near-create waiting behind far deferred creates: needs a counter first.
- Revive PerceptionIgnoreReuse (lab: 441k comparisons with zero differences, about 6% less crowd GT time).
- Measure, then warm, character PSOs.
- Pre-touch memory at the loading screen.
- Parallel save serialisation, an estimated 10–20 ms per save.

**core-memory-guards.md**
- A long-session soak with an object-count CSV and first-chance access-violation logging.
- A UMA memory policy that works under Wine.
- A start-up scan cache, about 0.8 s per launch.
- A/B `OsPageCache` under Proton.
- Re-parse the ini only when it changed.

**run-log-analysis.md**: still being written.

### Method correction: tick split adds overhead
`HitchLedgerTickSplit` adds up to about 0.4 ms per frame in crowds. In `cs-ab3` only the fix-on side had `--diag`, so
that side carried extra overhead; the small gain there is, if anything, understated. From now on, A/B comparisons run
without `--diag`, with separate diag runs.


### `VKD3D_CONFIG=no_upload_hvv` at the canal: no measurable gain (2+2 runs)

| Variant | fps (r1 / r2) | 1% lows | Worst frame |
|---|---|---|---|
| base | 63.7 / 67.0 | 54.2 / 54.5 | 40.0 / 20.0 ms |
| no_upload_hvv | 64.2 / 68.9 | 40.9 / 56.8 | 27.8 / 19.5 ms |

The difference is within run-to-run noise. Not adopted. Investigation 18 stays open for other identical-image GPU options.

### Monitor layout reset by GNOME (not a benchmark setting)
The Sony TV on DP-1 became active and GNOME fell back to default modes: everything landscape at 60 Hz. The layout was
restored with `gnome-monitor-config` to the saved one: HDMI-2 portrait-left at 144 Hz, HDMI-1 2560x1440 at 144 Hz as
primary, DP-1 off.
- Pitfall: the tool repeats `-t` on later logical monitors, so give `-t normal` explicitly for each.
- Before the next benchmark, check that the layout and refresh rates are intact.


### First spin session: canal, base vs `VtStreamingUploads=64` (`spin-canal-vt64`)
Report: [runs/20261107-100653-spin-canal-vt64.md](runs/20261107-100653-spin-canal-vt64.md).

**The spin method works:**
- Laps inside a slot agree within 1–3 fps.
- Live ini flips take effect.
- The ledger anchors to the frame log and splits by variant.

**Result:**
- Base: 80.2 fps; vt64: 81.3 fps. All differences are within noise: 1% low −2%, 0.1% low +10%, worst frame 22.9 → 27.1 ms.
- That is expected: the switch targets detail arriving after doors, and nothing streams at a static spot.

**The canal at the user's settings is GPU-bound** (GPU 98%, CPU 56%).
- By heading, SE is about 102 fps and W/NW about 68 fps, the worst.
- The CPU-side fixes (most of OblivionPerfFix) cannot raise average fps here.
- Gains at GPU-bound spots must come from GPU efficiency at identical image: vkd3d/driver options, async compute,
  upload paths. Or the work targets hitches and pop-in rather than average fps.

**Lessons:**
- The first slot after the warm-up runs low (73 vs 83 fps in later base slots). Add a throw-away first slot, or a
  longer settle.
- Test `VtStreamingUploads` / `FadeVtFlushSkip` on door scenes (`cheydinhal` inn-door, `transitions`), not spins.


### Chapel square, 3 balanced rounds: no regression from the fix (`cs-ab3`)
Report: [runs/20261107-100513-cs-ab3.md](runs/20261107-100513-cs-ab3.md).

| | Fix not loaded | Fix on | Change |
|---|---|---|---|
| avg fps | 69.2 | 70.0 | +1%, within noise |
| 1% low | 55.7 | 58.3 | +5% |
| 0.1% low | 45.5 | 54.1 | +19% |
| worst frame | 25.8 ms | 18.8 ms | −27% |

- Neutral to slightly positive. The earlier −25% and the CPU-bound episodes did not repeat in 6 balanced runs, so
  they were not caused by the fix itself.
- The spread between sessions is large: without the fix, fps went from 64 to 74 here, against 94 earlier today.
- Suspect for the spread: FSR. The game turns FSR off when its window loses focus, so it renders at 100% instead of
  58.8%. Run on-r1 caught exactly that: `r.ScreenPercentage changed during the pass: 58.8 -> 100`. The user working
  on the PC during runs, or the window not being in front, probably explains the episodes.
- Next:
  - record focus and ScreenPercentage per scene;
  - keep the game in front;
  - consider the `small` profile (no FSR) for CPU-side work.

### Hitch ledger on Linux (first data, `cs-ab3` on-r1)
Slow frames in play, by share of excess time:

| Cause | Share |
|---|---|
| Unlabelled (async loading, GC and streaming at the frame tail) | 50% |
| PSO precompile still running after the 40 s warm-up (render- or GPU-bound) | 24% |
| Render-thread bound | 14% |
| Actor arrival | 7% |
| Tick work | 4% |

At start-up in the menu, one 2.6 s old-engine wait.

Lessons:
- The warm-up should wait until the PSO precompile has finished, not a fixed 40 s.
- The unlabelled half is what the C0 old-engine profiler and DoorDiag should break down.


### Chapel square: the slowdown comes in episodes where the CPU spikes and the GPU waits
At Cheydinhal's chapel square, some runs fall into a mode where the CPU is the limit, with many hitches. The fix-group
runs show this is an episode, not a constant cost of one fix group.

| Run | fps | Hitches | CPU / GPU |
|---|---|---|---|
| Fix not loaded (2 runs) | 94 | 0 | 56% / 97% |
| Fix on, round 1 | 87 | 0 | 54% / 98% |
| **Fix on, round 2** | **53** | **36** | **81% / 79%** |
| Fix on, diag run | 76.5 | 0 | 56% / 98% |
| Render-threading fixes off | 79 | 0 | 52% / 98% |
| **NPC fixes off** | **42** | **146** | **82% / 69%** |
| Physics fixes off | 83 | 0 | 59% / 95% |

- Hypothesis: a burst of NPC creation or AI work at the square. It was worst with the NPC fixes off, and so far it has
  never happened with the fix not loaded (2 of 2 runs).
- Confidence: low (single runs). A follow-up is running: `cs-ab3`, 3 balanced rounds with `--diag`.

### MangoHud can write a garbage frametime
One row in `cs-keep-off` held 37,337,300 ms, which broke that run's stats (it showed 0 fps). The parser now replaces any
frametime longer than 2 × the row gap + 50 ms with the gap. `cs-keep-off` needs a rerun.

### Benchmarks run from their own worktree
Chains now run from `~/Projects/opf-run`, a detached worktree whose `linux/results` and `linux/third_party` are symlinks
to the main checkout. Agents working on branches can no longer change code under a running benchmark.


### Process: give each agent its own git worktree
Several agents shared one checkout and switched branches in it, while benchmark chains ran code from that same
checkout. Rule from now on:
- every agent works in its own `git worktree` (`~/Projects/opf-<name>`);
- the main checkout stays on `linux-bench`, and only the main session runs the game.

### The fix's regression at the chapel square comes and goes
The busiest town spot got slower with OblivionPerfFix on in the first comparison, but not in the next run.

| Run | Fix not loaded | Fix on |
|---|---|---|
| Off-vs-on comparison, Cheydinhal chapel square (2+2 runs, own settings) | 94.0 fps | 70.3 fps (−25%), 18 hitches, GPU 97% → 88% |
| `cs-base-diag`, the next run, same spot | – | 76.5 fps, 0 hitches, GPU 98% |
| `cs-render-off` | – | 79.0 fps |

Confidence: low. Next: a balanced series with 3 or more rounds, plus the fix-group bisect (`cs-*` runs).

### Off vs on at the player's own settings (2 rounds)
Report: [runs/20261107-093709-own-off-vs-on.md](runs/20261107-093709-own-off-vs-on.md).
- Settings are GPU-bound: 97–98% GPU load.
- Doors with the fix on:
  - fps: +9–11%;
  - 1% lows: +34% entering, +87% leaving;
  - the 1.6–1.9 s loading frame stays on both sides.
- Road run with the fix on: −10% fps, but 0.1% lows +49% and fewer hitches (5 → 2).
- Canal with the fix on: −6% fps.

### MangoHud does not log with `no_display`
With `no_display` set, MangoHud wrote no CSV at all. The runner now keeps a visible overlay (fps, frame-time graph,
CPU/GPU) while logging. The red dot is MangoHud's logging indicator, and it cannot be hidden.

### The Linux benchmark works end to end under Proton
UE4SS loads through `WINEDLLOVERRIDES=dwmapi=n,b`, and the in-game mod's file protocol works on `Z:/` paths. A run:
1. starts a new game with no save (`coc`);
2. runs the scenes;
3. closes the game;
4. restores settings, saves and the fix's ini;
5. removes UE4SS from the game folder.

Lining up the MangoHud log with the game's own clock: the runner makes one deliberately long frame (a 350 ms busy loop)
at a known time and finds it in the log. That places the log to about ±30 ms, against ±0.5 s from the file name alone.

### Character pop-in comes mostly from main-thread work
Each NPC costs the main thread 20–40 ms in steps that can't be split. Whole steps can't run off the main thread, because
UE 5.3 creates objects only there. The candidates:
- helper-thread physics and cloth preparation;
- warming character shaders before they are needed;
- a capped loading-screen drain.

Evidence: [../research-linux/npc-creation.md](../research-linux/npc-creation.md).

### Texture detail after doors is limited by the virtual-texture upload cap
- `r.VT.MaxUploadsPerFrame.Streaming` is 4. In the repo's own measurement, 64 took detail settling from about 8–10 s
  down to about 2.4 s.
- The fade-in's `r.VT.Flush` throws away textures streamed behind the loading screen.
- Both have existing switches that are off by default: `VtStreamingUploads` and `FadeVtFlushSkip`.

Evidence: [../research-linux/texture-streaming.md](../research-linux/texture-streaming.md). Not yet measured on Linux.

### Preloading has a hard limit
Most of the costly work comes from the old engine attaching a cell, so it cannot exist before the cell does. Without
changing gameplay, only these can move earlier:
- read-only file warming;
- shader cache persistence;
- garbage collection placement;
- the tail of the loading screen.

Evidence: [../research-linux/preloading.md](../research-linux/preloading.md).

### The fix DLL builds on Linux
clang-cl, lld-link and llvm-ml with xwin's MSVC CRT and SDK build it with no source patches, in about 23 s
(`linux/build-dll.sh`, branch `linux-build`). Not yet self-tested against the exe, and not yet run under Wine.

### Owner rules (standing)
- Keep Lumen, lighting and image quality.
- Changes to the old engine are allowed: multithreading and offloading its work, and fixing its problems.
- Keep gameplay exploits and old gameplay bugs.
- Work on the worst spots first, using a spinning camera and live switches.
- Subagents run on Sonnet or Haiku.

### Proton and Linux setup lessons
- `ntfs3` cannot create symlinks on the shared NTFS volume, so the drive must be mounted with `ntfs-3g`.
- Proton prefixes live on ext4, through a symlink.
- Edit Steam's `localconfig.vdf` only while Steam is fully closed.
- Wolfenstein II's 60 FPS cap came from vsync halving the rate on XWayland, which `mailbox` mode fixed. Its FPS limit
  lives in `com_adaptiveTickMaxHz`.

Full setup notes: the `linux-gaming` repo.
