# Findings log

Newest first. Each entry gives its date, the finding, its evidence and its confidence. Runs: [runs.md](runs.md).
Investigations: [investigations.md](investigations.md).

## 2026-11-07

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
