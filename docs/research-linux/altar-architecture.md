# Oblivion Remastered ("Altar") architecture: research notes

Method: web research only (WebFetch summaries of the OblivionPerfFix repo docs, plus searches). Caveat: the WebFetch tool summarises pages through a small model and truncates at ~100k chars per call; each of how-it-works.md and research.md is ~220k chars, and I read chars 0-200000 of each (not the last ~20k). Quotes below are from those summaries, not raw text. Items marked **[SPECULATION]** or **[UNVERIFIED]** are not backed by a primary source.

Primary sources:
- PerfFix repo: https://github.com/LTSharpe/OblivionRemasteredPerformanceFix
- how-it-works: https://raw.githubusercontent.com/LTSharpe/OblivionRemasteredPerformanceFix/main/docs/how-it-works.md
- research: https://raw.githubusercontent.com/LTSharpe/OblivionRemasteredPerformanceFix/main/docs/research.md

## 1. Architecture and threading

### 1.1 Two engines, one process
- Leak (weak source, post deleted, vouched for by Tom Henderson/Insider Gaming): project codename "Altar", built with a "pairing system" running UE5 alongside a heavily modified original Oblivion (Gamebryo) codebase; new graphics rendered in UE5, "most of the gameplay/physics" still in Oblivion. Virtuos Paris lead, Black Shamrock art. Via https://www.tweaktown.com/news/92631/oblivion-remake-possibly-in-development-but-bethesda-isnt-making-it/ and the r/GamingLeaksAndRumours thread (https://lr.in.psf.lt/r/GamingLeaksAndRumours/comments/1jzsatm/the_oblivion_remasterremake_codename_is_altar_per/mnw7mjj/?context=3).
- PerfFix research.md: "the 2006 engine runs the world (AI, scripts, cells) on its own thread. Unreal Engine 5.3 renders it." Per-thread CPU accounting there lists GameThread, RenderThread, RHIThread, "the old engine's OblivionThread", task helpers.
- A Nexus mod page (mod 5294, not fetchable, 403) reportedly links a GameSettings section to a `UE5AltarPairing` settings class in Altar.ini (per search snippet). So "UE5AltarPairing" appears to be a config class in `Altar.ini`, not just a code symbol. [UNVERIFIED beyond the snippet]
- Search for the exact strings `UE5AltarPairing`, `VActorStateMachine`, `OblivionThread` found no public write-up. `VActorStateMachine` appeared in neither PerfFix doc (within the portion I read). `OblivionThread` appears in research.md only as a measured thread. `VCharacterBodyPairingComponent` (the per-character pairing component) does appear in PerfFix docs.

### 1.2 Pairing objects and sync (what is documented)
- Each NPC has a UE-side character with a `VCharacterBodyPairingComponent`; equipment delegates' owner is that component, and its "root-component word holds data, not a pointer" (NpcCreationPacing / ClothBuildDefer in research.md).
- The old engine's command queue to the Unreal side is **FIFO** ("stays FIFO", NpcCreationPacing). Creation work is therefore ordered and cannot be reordered arbitrarily; PerfFix paces it but preserves order.
- Pairing session blocking (HavokPickWarningGuard, research.md): Havok world update runs on the OblivionThread. When the pick-count warning box (`iMaxPicks`, default 40 under `[HAVOK]`) is open, that thread blocks; the **game thread then blocks in the pairing session at its next `OnWorldPreActorTick`**, freezing the game until the box closes. This is the one concrete documented per-frame cross-thread dependency: GameThread's world pre-actor tick waits on OblivionThread via the pairing session.
- Altar's NPC steering runs on helper threads every frame and does a (navigation query) wait (how-it-works.md, NavmeshBuildNoBusyWait section).
- Per-frame structure inferred from HitchLedger (see 4.3): main-thread frame = world update + actor update + rest + frame-cap wait. [Inference.]

### 1.3 UE thread side
- Stock bottleneck chain at Cheydinhal (research.md): RenderThread ~89% busy (bone-matrix copying, per-frame sun rebuilds), RHIThread 90-95% busy with helpers 60-88% idle (command translation single-threaded), GameThread 78-86% busy (real game logic).
- Cloth is 5-7% of game thread at Cheydinhal chapel square.
- Known blocking/stall cases (how-it-works.md):
  - Navmesh tile builds run inside a game-thread **busy wait** (tick group 0): 28 ms waits, 84 ms frames, 2.6 s stalls (NavmeshBuildNoBusyWait, BusyWaitFlagCheck).
  - Task-wait deadlock: workers in `WaitUntilTasksComplete` hand slot to reserve workers, nobody runs trigger tasks, all stall until 120 s RenderingThread fatal (TaskWaitDeadlockGuard).
  - Lumen array reallocation 25-40 ms RenderThread; GPUScene buffer recreation on power-of-two changes (109/118 ms frame); RT scene buffer drop/recreate; Nanite root-page buffer regrowth up to ~1.7 s (Imperial City); RT TLAS regrowth; grass `ClearInstances` realloc ~20-22 ms; D3D12 upload heap pools destroyed after 20 frames.
  - Physics (Chaos) tree rebuild/catch-up 25-45 ms; exclusive scene lock; body creation takes the solver recursive SRW write lock ~550 times per humanoid via `InitArticulated` (NpcBodiesOneLock).
  - RHI-thread defragmentation vs `FD3D12View::CreateView` race (UE-217692; ViewRenameGuard).
  - Fresh-memory page faults 60-110k/s in Cheydinhal (OsPageCache).
  - AMD FSR frame-gen command-list pool (8 slots) never waits, crashes on long GPU stall (FrameGenCrashGuard).
- Frame-gen: AMD swap chain lets the game run only ~1 frame ahead of GPU; each present waits for the previous generated frame (FrameGenAsyncCompute section).

## 2. Pop-in, cell loading, streaming

### 2.1 Cells and grids
- Original-engine semantics (UESP): `uGridsToLoad` default 5 (5x5 exterior cells), `uExterior Cell Buffer` default 36 slots. https://ck.uesp.net/wiki/UGridsToLoad , https://stepmodifications.org/wiki/Guide:Oblivion_INI/General . Values >5 are widely reported as problematic in the original. Whether Remastered honours `uGridsToLoad` identically: PerfFix's CellBufferPacedEvict code reads these same ini names (`uGridsToLoad`, `uExterior Cell Buffer`) from the running remaster, so yes the OG cell manager is live. No public source found for where the remaster's Oblivion.ini lives (my guess `Content/Dev/ObvData/Oblivion.ini`: **[UNVERIFIED]**).
- CellBufferPacedEvict (how-it-works.md): buffer has 36 slots for 5x5. On a cell-grid crossing 5 new cells (9 diagonal) push the oldest out and they are unloaded **inside the crossing frame** (5-20 ms of a 17-34 ms frame at Kvatch). Fix adds 2*uGridsToLoad-1 spare slots (9) and unloads one cell per later frame; settles in 5-9 frames. Remaining crossing cost: temporary data load ~3.5 ms, attaching cells ~3.5 ms. AnimTeardownParallel moves ~1M interpolator teardowns to helpers (crossing animation teardown 9.4-10 -> 4.9 ms).
- "when travelling attaches a new row of cells, the game creates every NPC and creature in it within a few frames" (research.md).
- Unreal side: PhysicsDestroyBatch note says "World Partition unregisters one big instanced mesh (1,000-2,500 bodies) per frame", i.e. static world content is in UE World Partition/instanced meshes in addition to OG cells. How cell->WP mapping works is not documented publicly. [gap]

### 2.2 NPC spawn cost and pacing
- Each NPC costs the game thread 20-40 ms in unsplittable units (research.md): create command (spawn, first anim setup, construction script, AI controller; 4-12 ms) -> head/headwear (~7 ms) -> appearance apply one frame later (4.6-14.6 ms) -> equipment units per clothing piece (wizard robe 14 ms) -> hair (1-3 ms). Bursts: 31 actors in 4 frames, 40-110 ms frames at shrines.
- NpcCreationPacing (how-it-works.md): defers pieces for characters farther than 1 cell (4096 units); per-frame budget = the sleep a 60 fps cap would give, else 4 ms; clothing/mesh/hair steps in their own queue; budget grows after 8 frames waiting, triples at 15, forced at 30. PacingFadeAware: treats NPC as unseen until fade makes it visible. PacingLeanFlowDrain (PR #25 by mkusm): clothes/hair/body steps run in frames after area setup. Reduced Sheogorath worst frame 61-68 -> 36-43 ms.
- Other creation costs: ClothRegisterLite/ClothBuildDefer (robe cloth rebuilt up to 3x), NpcBodiesOneLock, RigVMHashMemo (`URigVM::ComputeVMHash` called 4x per humanoid; head rig DNA name mapping), NpcFadeInNoRebuild (per-frame fade-in primitive rebuild; dock VRAM 12.9 -> 11.2 GB).
- This directly explains "slow ad hoc pop-in": the OG engine emits creation commands in a FIFO burst when cells attach; UE side executes them as large unsplittable game-thread units.

### 2.3 Texture / geometry streaming
- Virtual textures: stock `r.VT.MaxUploadsPerFrame.Streaming` = 4; PerfFix `VtStreamingUploads` (off by default) raises it (README/ research example 64). Symptom: stair walls ~40 m away blotchy for 5-10 s after a door. A Nexus pop-in/VT mod does the same via DefaultDeviceProfiles (`r.VT.MaxUploadsPerFrame.Streaming=64`) per search snippet (nexusmods mod 3031 page: https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs).
- Nanite: `r.Nanite.Streaming.NumInitialRootPages` 2048 -> 3072 (+32 MiB) avoids mid-session regrowth freeze.
- `r.Streaming.PoolSize` is dropped to 1 MB during loading screens, then restored (research.md). Community Engine.ini guides map PoolSize to VRAM (3072 for 4 GB ... 7168 for 8 GB) with mixed results; no test targeted NPC pop-in. [community, weak]
- `r.pso.PrecompileThreadPoolSize` set to logical procs - 2 by PsoCompileThreadPool (only with deadlock guard); PsoPrecompileFast, "IsPrecompiling", "SetBatchMode" exist as PerfFix concepts. Door loading itself (arrival 2.7-3.1 s) is unchanged by PerfFix; PrepareCollisionBehindLoadingScreen / StreamBehindLoadingScreen / UnfreezeBehindLoadingScreen reduce post-load hitches (worst frame after door at 4K 187 -> 95 ms).
- UploadMemoryKeep: streaming arrives in bursts a few seconds apart; D3D12 upload pools were recreated per burst; fast allocator retains 24 pages vs default `d3d12.FastAllocator.MinPagesToRetain` 5.
- cvars I could NOT confirm have any effect in this game: `s.AsyncLoadingTimeLimit`, `s.LevelStreamingComponentsRegistrationGranularity`, `r.Streaming.*` beyond PoolSize. The only hit for `s.AsyncLoadingTimeLimit` was an FF7 Remake mod. Given the evidence that spawn cost is game-thread unsplittable units driven by the OG engine's FIFO command queue, these UE streaming knobs are likely **low-leverage [SPECULATION]**.
- Altar-specific cvars seen in PerfFix docs: `Altar.GraphicsOptions.FrameRateLimit`, `Altar.Reflex.Mode`; plus `OPF.HudAspect` (PerfFix's own). No public `Altar.*` spawn/stream cvar list found.

## 3. Input latency

- No PerfFix documentation on input latency was found (within read portions); no authoritative source on `r.OneFrameThreadLag` for this game.
- Frame gen: community reports of heavy mouse feel with FG even with Reflex+Boost (Steam: https://steamcommunity.com/app/2623190/discussions/0/604155538457023590 ; Nexus: https://nexusmods.com/oblivionremastered/mods/653?tab=posts). One Nexus post says a later game update fixed an input-lag issue that Engine.ini tweaks addressed. Engine.ini "Reflex: 1 = On, 3 = On + Boost" suggestion exists (`Altar.Reflex.Mode` per PerfFix; user-reported). [community]
- Mechanics from PerfFix: on NVIDIA, Streamline's Reflex path takes `t.MaxFPS` as its limiter (`t.Streamline.Reflex.HandleMaxTickRate` default 1); with FG on, saved `Altar.GraphicsOptions.FrameRateLimit` was lost at launch leaving `t.MaxFPS`=0 (uncapped; fixed by FrameRateLimitAtStart on AMD path). AMD swap chain holds each rendered frame ~half frame time for pacing; stock hold target stuck too long after a few long frames (3-5 s recovery); FrameGenPacingTuning Set B (margin 0.01 ms, var factor 0.3) cuts recovery to 0.5-1 s on the FSR 3.1.4 DLL. Set B trades even pacing for lower hold: present gaps >25 ms rose.
- FrameGenAsyncCompute: `r.FidelityFX.FI.AllowAsyncWorkloads=1` gave +22-29% FPS with FG on.
- Practical guidance (derived, not sourced): cap FPS below refresh so the game stays GPU-unbound; keep vsync/VRR consistent; use Reflex On (not necessarily Boost) on NVIDIA; Digital Foundry found capping at 60 does not fix hitches (https://wccftech.com/oblivion-remastered-is-an-impressive-remaster-with-dire-performance-problems-says-digital-foundry). Render queue depth: AMD swapchain limits to ~1 frame ahead. `r.OneFrameThreadLag` untested [SPECULATION].
- Digital Foundry one-year review: stutter/pacing/long-session decay/crashes unresolved, hybrid setup hard to optimise: https://spilled.gg/digital-foundry-oblivion-remastered-mess-launch/ ; unofficial Engine.ini anti-stutter mods showed no significant improvement: https://wccftech.com/oblivion-remastered-anti-stutter-improvement/amp/ ; Switch 2 traversal hitches up to 230 ms: https://www.notebookcheck.net/Digital-Foundry-s-Oblivion-Remastered-Switch-2-performance-test-finds-a-30-FPS-cap-poorly-hiding-16-50ms-frame-times-230ms-traversal-stutters-drops-to-0-FPS.1372177.0.html

## 4. Profiling available

### 4.1 Tools PerfFix authors used (research.md)
WPR CPU traces, in-game stack sampling and call counting (`tools/FastSampler.cs`), PIX captures, PresentMon frame times, UE4SS widget walks and Lua probes (bench scripts at `mods/ue4ss/OblvBench/Scripts/`), Ghidra/dumpbin static analysis, DoorDiag (timeline of loading-screen/streaming events), lock-wait probes, ABBA live switching of keys. Benchmark harness: docs/benchmark.md, `bench/scenarios/`, Benchmark.cmd.

### 4.2 Shipping-build engine profiling
Nothing found documenting stat commands, csvprofile or Unreal Insights (-trace=) in the shipping build. Not researched successfully: **[GAP]**. Practical suggestion [SPECULATION]: UE4SS can expose console/`ExecuteConsoleCommand`; shipping builds usually strip `stat` and trace but this game's status is unknown. Test `-trace=cpu,frame` and `stat unit` in a Wine run before relying on either.

### 4.3 HitchLedger / HitchLedgerTickSplit (README + how-it-works.md tail)
- `HitchLedger=1` in OblivionPerfFix.ini (off by default; version.dll install only, stays off under OBSE64). Writes `OblivionPerfFix-ledger.csv` (48 MB cap, previous session `.1.csv`) via a background thread once a second; main thread never touches disk.
- Records each main-thread frame >= `HitchLedgerMs` (default 25 ms, frame-cap wait counts): breakdown into world update, actor update, rest of frame, frame-cap wait; plus timings from NpcCreationPacing, new collision bodies, shader precompile progress; flags for menu/loading screen, window focus, player position; a 10-second all-frame summary. Columns for code it cannot locate are -1.
- Analyse with `tools/Record-Session.ps1` or `python tools/stutter_ledger.py`.
- `HitchLedgerTickSplit=1` (since 1.2.3; needs HitchLedger=1): every 2 s writes `OblivionPerfFix-ticksplit.csv` (~0.3 MB/min, 64 MB cap) grouping every main-thread tick by tick kind and updated class (e.g. `SkeletalMeshComponent`), and splitting the rest of world update into timers, camera, streaming buckets; logs top 3 of each slow frame. Rank with `python tools/tick_split.py <csv> [--run <bench run folder>]`. Cost ~45 ns/timed tick (~0.4 ms/frame for ~1300 ticks). Used to diagnose horse corral stutter (-> PhysAnimNoEmptyLock, RigTraceReuse).
- Also `OblivionPerfFix.log` (per-fix applied status, 60 s work-saved reports), `OblivionPerfFix-gpu.txt`, GpuCrashReport.
- Linux/Proton: README says needs `WINEDLLOVERRIDES` launch option (version.dll proxy). Install: `Binaries\Win64\version.dll` + `OblivionPerfFix.ini`; Game Pass uses `Binaries\WinGDK`.

## 5. Config key reference (PerfFix, for porting)
RdgParallelTranslate (0/1/2; auto needs >= 9.5 GB VRAM and >= 8 logical CPUs), RdgSubmitBatch, GpuSceneParallelUpload (`r.GPUScene.ParallelUpdate`=1), PhysicsTreeTimeSlicing (`p.Chaos.AccelerationStructureTimeSlicingMaxQueueSizeBeforeForce` 1000->100000), ChaosMaxPayloadSize (`p.MaxPayloadSize` 100000->10000000; also honoured from Engine.ini), NaniteInitialRootPages, VtStreamingUploads, FrameGenPacingTuning, FrameGenAsyncCompute, FrameRateLimitAtStart, SharedMemoryGpu, ParallelMinProcessors, HitchLedger*, LogFile. Self-disables if code signatures are not found.

## 6. Gaps / next steps
1. Read the unread tails (chars 200000+) of both docs directly (curl locally, grep OblivionThread|pairing|OnWorldPreActorTick|PreActorTick).
2. Find a decompilation/dump write-up for `UE5AltarPairing` / `VActorStateMachine` (Nexus mod 5294 page was 403; try UE4SS dumps, Discord/GitHub issues).
3. Verify whether `stat`/Insights work in the shipping exe under Proton.
4. Test s.AsyncLoadingTimeLimit / LevelStreamingComponentsRegistrationGranularity empirically with HitchLedger.
