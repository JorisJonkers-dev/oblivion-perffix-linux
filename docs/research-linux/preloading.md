# Oblivion Remastered: what can be preloaded instead of done just in time

Date: 2026-11-07. Method: local docs and source read by keyword (docs/research.md, docs/how-it-works.md, AGENTS.md, src/OblivionPerfFix/src/**, bench/scenarios, docs/research-linux/*.md) plus web search/fetch. Nothing was launched or benchmarked. Marks: **[LOCAL]** = measured or stated by the repo's own docs; **[WEB url]** = cited; **[SPECULATION]** = my inference; **[UNVERIFIED]** = secondary or snippet-only source.

Rule check (AGENTS.md "Rules"): every candidate below is judged against "bit-identical or proven equivalent; timing changes only off-screen, a few frames, with an off switch". Candidates that would change what the old engine loads, when scripts run, or what the player sees are marked as such and ranked down.

Cross-references (out of scope here): NPC/character creation internals -> docs/research-linux/npc-creation.md; texture/VT streaming -> docs/research-linux/texture-streaming.md; Proton input latency and the ntfs-3g question -> docs/research-linux/proton-latency-streaming.md; architecture -> docs/research-linux/altar-architecture.md.

Test machine facts seen locally: 31 GB RAM (about 21 GB already page cache), a Mesa disk cache at `~/.cache/mesa_shader_cache`, game library on a `fuseblk` (ntfs-3g) mount (`/run/media/ExtraToast/Shared`, `findmnt` type fuseblk; I could not locate the game exe under it, so which library holds the game is **not confirmed**; the Steam library entry for app 2623190 is in `libraryfolders.vdf`, line 45). No `shadercache/2623190` directory and no `vkd3d-proton.cache` were found under `~/.local/share/Steam/steamapps` or `~/.cache`; the vkd3d cache may live elsewhere, see section 3.

---

## 0. The model of the work (what "just in time" means in this game)

**[LOCAL]** Two engines in one process. The 2006 engine runs the world on `OblivionThread` and feeds a FIFO command queue to UE 5.3 (game thread, render thread, RHI thread, task workers). On an exterior grid crossing (about every 4,100 units) the old engine shifts its 5x5 cell grid; the crossing frame is about 13 ms after CellBufferPacedEvict, of which "temporary data load ~3.5 ms, attaching the cells ~3.5 ms" is what is left (how-it-works.md, CellBufferPacedEvict). UE-side, the new row's NPCs, instanced meshes (World Partition), collision bodies, nav chunks, ray-tracing BLAS and materials/PSOs arrive over the following seconds. Doors, gates, fast travel and save loads hide the big work (old engine attaches a cell 1.2-2.9 s; about 2.4 GB re-read when leaving a city interior) behind the loading screen (research.md, "What still limits the game").

**Structural limit [SPECULATION, consistent with LOCAL]:** almost all expensive items are created by the old engine's cell attach, so they cannot exist before the old engine has the cell. The only things that can truly be done "earlier" without changing game state are (a) read-only I/O warming (page cache), (b) shader/PSO work that depends on assets and not on cell state, (c) moving housekeeping (GC, memory trimming, cache eviction) into moments already hidden, and (d) shortening the tail work after the loading screen. Pre-attaching a cell in the old engine early would change scripts, AI and save state and is not allowed by the rules.

---

## 1. Exterior cell attach on travel

**Today.** **[LOCAL]** Per grid crossing: old-engine crossing frame ~13 ms (from ~25 before CellBufferPacedEvict); incoming row = temporary data load ~3.5 ms + attach ~3.5 ms (the cell's records are read from the master files, so this is I/O plus parse on OblivionThread). Then, spread over frames on the UE side: NPC creation (20-40 ms per NPC in unsplittable units, paced by NpcCreationPacing), World Partition AddToWorld of instanced meshes and nav chunks (`ANavigationDataChunkActor::BeginPlay` -> `dtNavMesh::addTile`, one actor per chunk, cannot be time-sliced), static body creation (ParallelStaticBodies), Chaos acceleration structure updates, BLAS builds on first render, new material PSOs. "Fast travel across the landscape at high speed: the GameThread is saturated. We saw no blocking streaming waits." (research.md). Digital Foundry describes constant cell-loading hitches on high-end GPUs [WEB https://spilled.gg/digital-foundry-oblivion-remastered-mess-launch/ , secondary report].

**Opportunity.**
1. *Do not enlarge the loaded grid.* `uGridsToLoad` (default 5) changes what the old engine simulates (AI, scripts) and is reported to worsen stutter when raised in the original [WEB https://forums.nexusmods.com/topic/1340369-skyrim-memory-patch-fixing-ils-ugrids-ctd-freezes-for-real , Skyrim, anecdotal]. Out of bounds for "same gameplay".
2. *Read-only prefetch of the next row's data.* Predict the next grid row from player velocity (the crossing is deterministic: the player's cell coordinate crosses a known boundary) and `posix_fadvise(WILLNEED)` / read-ahead the master data and the matching UE I/O Store ranges so the crossing's 3.5 ms temporary load and the UE sublevel loads hit the page cache. No game state is touched. Needs a cell -> file-range map; the BSA/ESM offsets are public format knowledge (UESP/xEdit), the IoStore side needs the `.utoc` index **[SPECULATION: feasible, untested]**.
3. *UE-side early registration of the next World Partition cells.* Raising the WP loading range would load more than the stock game does (visible content/memory change; UE's dynamic loading-range scaling is PIE-only per Epic [WEB https://dev.epicgames.com/documentation/unreal-engine/dynamic-loading-range-scaling-in-unreal-engine]). Not recommended without a proof that it stays invisible.
4. *Already tried, no gain [LOCAL "Tried and not shipped"]:* `s.AdaptiveAddToWorld.AddToWorldTimeSliceMax 2`, `s.LevelStreamingComponentsRegistrationGranularity 2`, `p.EnableDeferredPhysicsCreation 1`, finer level streaming budgets, `r.Streaming.PoolSize 6000`. Smaller slices "only make cells appear later".

**Evidence.** Local numbers above; no web source documents Altar's cell->WP mapping (altar-architecture.md gap). Skyrim analogue: raising grids plus cell buffers is the community's lever, not a preloader; SSE Engine Fixes does not offer a dedicated cell preload (stutter persisted with all options off) [WEB https://forum.step-project.com/topic/14330-periodic-infinite-loading-screen-on-modded-sse-multiple-cells/ and search summary of https://stepmodifications.org/wiki/SkyrimSE:SSE_Engine_Fixes , weak].

**Risk.** Prefetch: very low (read-only, page cache only; memory use is bounded). Anything that starts the old engine's attach early: unacceptable (state change).

**Measure.** `bench cheydinhal` (cheydinhal-road-run), `silver-road`, `blackwood` (flight at 340 u/s), `roxey-ft`. Metric: crossing-frame OblivionThread time (HitchLedger world-update column, `HitchLedger=1`) and `iostat`/`/proc/<pid>/io` `rchar` vs `read_bytes` across crossings, A/B with prefetcher off.

---

## 2. Doors, fast travel, save load

**Today.** **[LOCAL]**
- Behind the loading screen: old-engine cell attach 1.2-2.9 s; `PrepareCollisionBehindLoadingScreen` hands the new area's bodies to Chaos with a zero-time step just before the fade-in (slow frame 144-199 ms -> 29-60 ms median 37-41, 720p exits); `StreamBehindLoadingScreen` restores the stored pool size and runs the streamer's non-blocking update per frame once the fade gate is armed (fade-in texture wait 99-710 ms -> 0.3-1.9 ms; loading screens 89-450 ms shorter; Cheydinhal inn door on the author's PC).
- After the fade-in: UnfreezeBehindLoadingScreen (off, trade-off) shows the interior-to-exterior "T-pose settle" and grass completing ~2.5-3 s after the world starts; `FadeVtFlushSkip` (off) skips `r.VT.Flush` at 1.5 s into the fade-in; PSO precompile holds loading screens 5 s longer while `IsPrecompiling` (game's `FadeInExtraDurationPSOCompilation`).
- The gate is a 0.5 s looping timer; world partition streaming completed + no pending travel + no async load -> fade-to-game.
- The latest Linux benchmark on this machine (linux/results/20261107-093214-own-off-vs-on-1107-0917-on-r2, cheydinhal): inn-door/exit leg hitches 5 with max 1729 ms; inn-door/enter max 1917 ms; arrival ~3.4 s. These are the loading-screen frames (included in the scene window), not necessarily visible; `door leg` rows show after-arrival max 192 / 1729 ms, so the exit leg still has at least one very long frame after arrival on this machine **[LOCAL data, interpretation SPECULATION: check what that 1.7 s frame is with DoorDiag before acting]**.

**Opportunity.**
1. *Pre-warm the destination while the player approaches a door.* The door's target cell is known to the old engine (door reference -> teleport destination). Safe variant: resolve the target interior and warm its file data (BSA ranges for its meshes/textures, and the IoStore packages of its UE assets) into the page cache. The 2.4 GB re-read when leaving an interior is the best case: leaving an interior re-reads the exterior city data that was evicted. Unsafe variant: call the old engine's cell load early to fill the interior cell buffer. The interior buffer exists in the original (`uInterior Cell Buffer`, default 3 [WEB https://stepmodifications.org/wiki/Guide:Oblivion_INI/General]) but a load can run OnLoad scripts and AI package init, so state equivalence is not provable without reverse-engineering the load path **[SPECULATION]**.
2. *Keep the exterior's data resident during an interior stay (page cache pinning).* The exit costs 3.9-4.4 s (Cheydinhal inn exit 3.95-4.4 s, research.md measurements); pinning the exterior cell's files (vmtouch -l or `mlock`) is the Linux-specific way to attack the re-read **[SPECULATION on size of effect; measure]**.
3. *Fast-travel destination:* the destination is chosen at the map click, seconds before the fade completes (`DelayFastTravelRequestUntilFadeEnd` is called before the gate arms [LOCAL]). A read-only warm of the destination's cell data/IoStore range could start at that call. Same pattern for save load: the save's player cell is known at the load click.
4. *Tail after fade-in:* grass completes 2.5-3 s after world start [LOCAL]. Pre-sizing the instanced-mesh arrays (see `InstanceClearReserve`) is the allowed kind of fix; nothing else is identified.

**Evidence.** Local numbers above. No web source on Altar transitions.

**Risk.** Warm-only: very low. Early cell load: high (gameplay state).

**Measure.** `bench transitions` (wawnet-inn-door, roxey-inn-door, cheydinhal-gate-ft, fast-travel, saves via `--start continue`), with `DoorDiag=1` for the timeline; compare loading-screen length (arrival time) and post-arrival max ms.

---

## 3. PSO / shader compilation

**Today.**
- **[LOCAL]** On every launch, UE's `FShaderPipelineCache` replays the game's bundled caches (build 19115871: 15,551 + 2,536 pipelines). Stock runs this in Background mode (5 per batch, 1 ms), taking ~110-150 s on a warm driver cache; during it frame rates drop (canal 34-36 vs 41-53 fps) and door/fast-travel screens are 5 s longer. `PsoPrecompileFast` runs it at UE's Fast values in menus/loading screens (done in 22-27 s after launch, 4 ms render-thread budget in menus) and the game's pace in play. Cold driver cache: ~6 min and 4 cores busy; guarded by cold-queue checks. `PsoCompileThreadPool` puts `r.pso.PrecompileThreadPoolSize` on UE's own pool (default 0 = off in the game). `ShaderScreenAfterDriverChange` forces the game's own shader screen after a driver change.
- **[WEB https://dev.epicgames.com/documentation/en-us/unreal-engine/pso-precaching-for-unreal-engine]** UE PSO precaching: components precache their PSOs right after load (PostLoad) with proxy creation delayed until ready by default (`r.PSOPrecache.ProxyCreationWhenPSOReady`, `ProxyCreationDelayStrategy` 0 = skip draw until ready); `r.PSOPrecache.Resources` default disabled; `r.PSOPrecache.Validation` 1/2 logs misses; `r.PSO.RuntimeCreationHitchThreshold` 20 ms counts runtime compile hitches. Epic's own known limits: components that cannot delay proxy creation (landscape) may pop or hitch unless the loading screen waits (`FShaderPipelineCache::NumPrecompilesRemaining()`), global graphics PSOs can still be created at runtime in the first frames after load, precached PSOs are dropped after compile so the first driver-cache fetch costs several ms. Docs are the current version; **5.3 defaults not confirmed** (Epic page says PSO precaching needs cooked D3D12 on Windows as of 5.3 [WEB search summary of the same page]). Whether Altar ships with `r.PSOPrecaching` on is **not known to me**; the local docs say only that the pool is off.
- **[WEB https://raw.githubusercontent.com/HansKristian-Work/vkd3d-proton/master/README.md]** vkd3d-proton keeps an internal DXBC/DXIL -> SPIR-V cache, `vkd3d-proton.cache` (+ `.write`) in the *current working directory* unless `VKD3D_SHADER_CACHE_PATH` is set; `=0` disables it; `VKD3D_CONFIG=pipeline_library_app_cache` is the alternative. **Under Steam/Proton the variable is normally set by Proton to the shadercache dir [SPECULATION from memory; verify with `grep -a VKD3D_SHADER_CACHE_PATH /proc/<pid>/environ` while the game runs]**. If it is unset, the cache lands in `Binaries/Win64` on the NTFS mount.
- Steam Fossilize pre-caching: reports conflict on whether it only downloads or also compiles, and that it helps native Vulkan and vkd3d games most [WEB https://www.gamingonlinux.com/2020/05/valve-improve-linux-vulkan-shader-pre-caching , comments, weak]. For a game compiling its own PSOs at start-up, Fossilize adds little beyond what the game's own precompile does **[SPECULATION]**.
- On AMD/RADV the GPU ISA is cached by Mesa in `~/.cache/mesa_shader_cache` (exists on this machine). Mesa's default size limit may evict entries on a game this big **[SPECULATION from memory: default cap is 1 GB; verify at https://docs.mesa3d.org/envvars.html before relying on it; `MESA_SHADER_CACHE_MAX_SIZE` is the knob]**.

**Opportunity.**
1. *Make a full pre-warm at the main menu the default, and make sure it is a real warm.* The repo already does this in menus (PsoPrecompileFast), so the remaining Linux question is whether the Mesa/vkd3d caches *persist* between sessions (otherwise every launch is a 6-minute "cold" start). Checks: where does `vkd3d-proton.cache` live; is Mesa's cache big enough; is the Steam shader cache cleaned by Steam on updates. Fix is configuration (launch options `MESA_SHADER_CACHE_MAX_SIZE=...`, `VKD3D_SHADER_CACHE_PATH=<ext4 dir>`), not code.
2. *Detect residual runtime PSO misses.* Set `r.PSOPrecache.Validation 2` and `r.PSO.RuntimeCreationHitchThreshold` in a test ini to count misses per scenario; if misses cluster at first visits (cheydinhal, silver-road, blackwood), the opportunity is to precompile those pipelines in the menu (a recorded extra PSO cache cannot be shipped by this repo: "no game bytes" rule), so instead extend the *wait*: hold the fade-in until `NumPrecompilesRemaining()` and the driver's compile threads are idle. The game already has this hold (5 s) while IsPrecompiling; verifying it covers precache requests, not only the bundled cache, is open. **[SPECULATION]**
3. *`r.PSOPrecache.Resources=1`* would precache mesh/resource PSOs earlier; but with proxy delay it can turn a hitch into a visible late appearance, and it consumes memory (each compiling thread up to 2 GB per Epic's docs). Needs image comparison. Medium risk.
4. *Hitch ledger signal.* HitchLedger already logs "shader precompile progress" per slow frame (altar-architecture.md 4.3): use it to see if slow frames at first visits correlate with driver compiles (the "D3D Background Thread" CPU the repo already reads).

**Evidence.** Local: PsoPrecompileFast numbers above; cold cache table. Web: Epic page; vkd3d README.

**Risk.** Config changes: very low. Pacing changes: low (already done). Resource precache: medium.

**Measure.** Run `bench cheydinhal` twice from a cleared vs warm Mesa/vkd3d cache (back up `~/.cache/mesa_shader_cache` first, never delete the only copy), count frames > 40 ms in the first visit vs second visit of each scene (a first-visit-only hitch is a PSO miss), and read `[pso]` stats lines in OblivionPerfFix.log.

---

## 4. Physics (Chaos)

**Today.** **[LOCAL]** Bodies come from the cell attach: static bodies of instanced meshes (ParallelStaticBodies, PipelinedBodyCreation), characters' bodies (NpcBodiesOneLock), then the acceleration-structure insert and flush (PhysicsTreeTimeSlicing, PhysicsFlushParallel, bulk insert). After a door the first step takes in every body at once (fixed by PrepareCollisionBehindLoadingScreen). Removing bodies is World Partition unregistering 1,000-2,500-body meshes per frame (PhysicsDestroyBatch). Game ships `p.Chaos.EnableAsyncInitBody=1`; turning it off was worse.

**Opportunity.** Bodies of the next row cannot exist before the cell is attached. What *can* be moved earlier is the **zero-time tick that flushes the new bodies into the broad phase**, as is done behind loading screens. In open world the player stands on the new ground within the same frame, and the repo already evaluated this: "Deferring the immediate insert of new bodies into the game thread's collision structure ... ~35 ms of game thread spread over the spike second at 4K ... risks falling through new ground" (not shipped). A *speculative* equivalent for the exterior: run the zero-time tick for **far-ring bodies** (outermost cells of the new row, beyond a distance the player cannot reach in a few frames) on the physics thread right after their registration, so the later "catch-up" has less to do. The repo's current time slicing already spreads this. Expect small gain. **[SPECULATION]**

**Risk.** Medium for exterior (query visibility rules), none behind loading screens (already shipped).

**Measure.** `blackwood`, `silver-road`; HitchLedger "new collision bodies" column; physics catch-up ms per crossing.

---

## 5. Navmesh

**Today.** **[LOCAL]** Altar uses UE navigation (Recast) for NPC steering, plus the old engine's own pathing; nav data is streamed as chunk actors (`ANavigationDataChunkActor::BeginPlay` -> `AddNavigationDataChunk` -> `AttachTiles` -> `dtNavMesh::addTile`); tile *builds* (`RecastBuildLayers`, 20-110 ms each) also occur at run time on the queued-thread pool. NavmeshBuildNoBusyWait prevents them from running inside a tick-group busy wait; NavLinkFast speeds the chunk attach's link search. Which tiles are built at run time vs read from the prebuilt chunk is not documented locally: only that Recast tile-build samples were seen (76 of 1,898 helper samples in one run), so some tiles do get built at run time.

**Opportunity.**
1. *Prebuilt vs runtime.* If the runtime builds correspond to dynamic modifiers (doors, objects) they cannot be precomputed without changing nav results. If they correspond to missing prebuilt data, a build-ahead pass is possible only with the same inputs, which are not available before the cell attaches. **[SPECULATION]**
2. *Chunk attach is one actor, cannot be sliced* by AddToWorld time slicing [LOCAL]. The remaining lever is making `addTile` cheaper (NavLinkFast is exactly that) and avoiding doing it in the crossing frame by moving the chunk attach to a different frame within the same row (timing only, a few frames). The repo shows the attach is already inside the time-sliced AddToWorld, so effect is uncertain.

**Risk.** Low for work-reduction; high for any precompute that must match the stock navmesh.

**Measure.** HitchLedgerTickSplit for NavigationSystem ticks; `[navlink]` and `[navmesh]` stats; `silver-road`.

---

## 6. Audio, UI/menus, save thumbnails

- **Audio (Wwise bank loading on area change).** **[LOCAL]** Nothing in the repo or docs mentions audio. **[WEB]** Only old UE4-era Audiokinetic threads about async bank loading blocking the main thread and the Event Driven Loader [WEB https://blog.audiokinetic.com/qa/3854/asynchronous-loading-soundbanks-ue4-hangs-packaged-build , old, anecdotal]. I could not confirm that the Remaster uses Wwise at all **[UNVERIFIED]**, nor measure bank loads. Opportunity: none proven. First step is observation: HitchLedgerTickSplit grouping by ticked class on a door/gate arrival and a `strace`/`/proc/<pid>/io` view of `.bnk`/`.wem` reads.
- **UI/menu assets (map, inventory).** **[LOCAL]** MenuOpenFlashFix shows the menu background is a captured screenshot (`VBackgroundWidgetBase::RequestCapture`); the menu screenshot filter and copies are already optimised. No measured first-open widget creation cost in the docs. Candidate: pre-construct menu widget classes at the main menu (the game's own UObject loading), which is a pure timing change but I have no number showing it matters **[SPECULATION]**. Measure with HitchLedgerTickSplit on first open of map/inventory vs second open.
- **Save thumbnails.** **[LOCAL]** Done: SaveThumbnailAsync, SaveBytesBulk, SaveRefIdIndex. Nothing left identified.

---

## 7. Lumen surface cache, ray-tracing BLAS, Nanite, distance fields

- **BLAS builds.** **[LOCAL]** RayTracingBuildBatch already batches the requests (e.g. 71 builds 16.0 ms -> 0.8 ms; the 97.6 s frame GPU busy 37-45 -> 19-21 ms). Spreading builds over frames (`r.RayTracing.Geometry.MaxBuiltPrimitivesPerFrame`) hit DEVICE_HUNG with 50000 and was a look change. BLAS cannot exist before the mesh loads; the only earlier point is "mesh loaded but not yet visible", i.e. a request at load that the batch already takes at the next frame start. Remaining: none.
- **Lumen surface cache card capture for newly streamed meshes.** **[LOCAL]** `r.LumenScene.SurfaceCache.CardCapturesPerFrame` tried; at 480p GPU time equals a quiet stretch, so the 4K spike is resolution-bound; a look change. No candidate.
- **Nanite page streaming.** **[LOCAL]** `NaniteInitialRootPages` 2048 -> 3072 avoids a +32 MiB mid-flight re-creation (up to ~1.7 s freeze at the Imperial City). Page-in itself is I/O: covered by the page-cache warming below and by texture-streaming.md.
- **Distance field generation.** No local mention. UE builds mesh distance fields at cook time, so I expect no run-time generation in a shipping build **[SPECULATION; unverified for this game]**. Global distance field updates are per-frame GPU work, not preloadable.

---

## 8. Garbage collection and old-engine housekeeping

**Today.** **[LOCAL]** "Garbage collection has no cheap anchor in this game build, so it is not timed on its own" (how-it-works.md, HitchLedger); GC is lumped in "rest of the frame". Memory: "The game itself does not leak: no object build-up and no frame-rate drift over 105 minutes" (research.md) while Digital Foundry reports long-session decay [WEB https://www.purexbox.com/news/2025/05/oblivion-remastereds-performance-degrades-over-time-digital-foundry-discovers , secondary]. A forced `KismetSystemLibrary::CollectGarbage` was used in a repo test, so the game permits it.
**[WEB, anecdotal forum threads, not 5.3-specific]** `gc.TimeBetweenPurgingPendingKillObjects` default 60 s; larger intervals make fewer but larger hitches (50 -> 62 ms for 30 -> 120 s in one report); `gc.IncrementalBeginDestroyEnabled` is experimental and did not remove freezes in a World Partition report [WEB https://forums.unrealengine.com/t/gc-extremely-huge-hitches-in-empty-map/147738 , https://forums.unrealengine.com/t/freeze-on-one-frame-for-garbage-collector/2681510 ; as summarised by search, not read in full].
Old engine: OblivionThreadCaches (per-thread free caches) cut shared counter trips 97% but frame times stayed within noise (not shipped) **[LOCAL]**; the unloading itself dominates.

**Opportunity.** Move UE GC into moments already hidden: loading screens (UE already collects around map load/seamless travel; **whether Altar's door loads trigger a full GC is unconfirmed**) and, if periodic purge hitches show in the ledger, raise the interval so the purge lands on the next transition rather than mid-travel. This changes only when memory is freed. Risk: memory growth during long exterior travel (the repo's MemoryRelief logic exists for RAM pressure). Do not touch `gc.MaxObjectsNotConsideredByGC`/disregard-for-GC pools (changes what gets scanned; dangerous).
**Measure first:** the 25 ms-plus frames in the ledger with a periodic 30-60 s signature (HitchLedger summaries "rates per hour"); a `world` or long `cheydinhal-road-run` spin with `HitchLedger=1`; if no 60 s periodicity, drop this item.

---

## 9. Linux-specific I/O and caches

**Today.** **[LOCAL]** The game files are on an ntfs-3g (`fuseblk`) mount on this machine (see mount list). Door exit re-reads ~2.4 GB. 21 GB of the 31 GB RAM is already page cache.
**[WEB]** Valve discourages NTFS libraries [https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows]; ntfs-3g sequential throughput is close to ext4 per its maintainer but random small-read cost is unbenchmarked (see proton-latency-streaming.md; and one user saw no change moving to ext4 [https://lemm.ee/post/44579603]). vmtouch is "a tool for learning about and controlling the file system cache" and can touch/lock/evict files [WEB https://github.com/hoytech/vmtouch ; flag details not fetched, check `man vmtouch`].

**Opportunity (all read-only, no game change).**
1. At launch (the wrapper `linux/oblivion-launch.sh` is the natural place) read the large, streamed containers into the page cache in the background at idle priority: `Content/Paks/*.ucas` (and `.utoc`, `.pak`) and `Data/*.bsa`. The total install size is large (the Proton doc says 100+ GB, unverified); only warm what fits comfortably: BSAs first (old engine reads), then the UE containers' hot ranges. Evidence for benefit: the 2.4 GB exit re-read and 3.9-4.4 s exits; but the benefit is measurable only if the reads actually miss the cache today (check `/proc/<pid>/io` `read_bytes` vs `rchar` per door).
2. Pin (`vmtouch -l`, needs `RLIMIT_MEMLOCK`) the *currently active* region only, otherwise 21 GB of pinned cache starves the game and its 10+ GB working set.
3. Move the game (or just `compatdata`, shader caches) to ext4/xfs/btrfs: removes FUSE round trips; the strongest single I/O lever per the other research file.
4. `VKD3D_SHADER_CACHE_PATH` and `MESA_SHADER_CACHE_DIR/MAX_SIZE` on a fast, persistent Linux filesystem (section 3).

**Risk.** Warming: none for fidelity; contention risk if it reads during play (run it at start-up behind the start-up videos, `ionice -c3`, and limit to one pass).

**Measure.** Cold-cache A/B: `echo 3 > /proc/sys/vm/drop_caches` (root) before a `transitions` run vs after a warm-up, and `bench.py` arrival time, plus `perf trace -e read` or `iostat -x 1` on the NTFS device during the door legs.

---

## 10. Ranked top 10: expected player-visible gain vs risk

Scale: gain = how much of a visible hitch/pop-in it could remove (my estimate, not measured); risk = chance of changing image/gameplay or crashing.

| # | Change | Where | Gain | Risk | Why this rank |
|---|---|---|---|---|---|
| 1 | Persistent, large shader caches on a fast Linux fs: `VKD3D_SHADER_CACHE_PATH`, `MESA_SHADER_CACHE_MAX_SIZE`/`DIR`, verify Steam is not clearing them | launch config | High (removes the cold-driver ~6 min start and first-visit compile hitches if the caches are being lost) | None | Config only; local docs prove cold cache is a large effect |
| 2 | Page-cache warm of `.bsa` and the hot `.ucas`/`.pak` ranges at launch (idle I/O priority) | wrapper script | Medium-high on NTFS/FUSE (door exits, row arrivals) | Very low | Read-only; depends on measured cache misses |
| 3 | Read-ahead of the destination cell's data when a door is in front of the player / at fast-travel click / at save-load click | DLL hook on the door/travel call | Medium (shortens loading screens, 2.4 GB exit re-read) | Low (read-only) | Needs hooks and a cell -> file-range map; verify first with DoorDiag |
| 4 | Move the game (or at least compatdata and caches) off ntfs-3g | system | Medium, unproven | None | Per proton-latency-streaming.md; independent of this repo |
| 5 | Exterior row read-ahead from velocity (next grid row) | DLL | Medium-low (crossing frame is ~3.5 ms of load already) | Low | Small per-crossing share; best gain on a cold cache |
| 6 | Verify PSO precache coverage with `r.PSOPrecache.Validation 2` and, if misses exist, extend the loading-screen hold to cover precache requests | DLL/ini test | Medium if misses are found | Low-medium (loading screens may get longer) | Needs measurement before any change |
| 7 | GC pushed onto transitions (raise `gc.TimeBetweenPurgingPendingKillObjects` or force a collect at a loading screen) | cvar or hook | Low-medium, only if the ledger shows 60 s periodic hitches | Low-medium (memory growth) | Measure first, drop if no periodicity |
| 8 | Zero-time Chaos tick for the far ring of a new row right after registration | DLL | Low | Medium | Related approach was rejected for fall-through risk |
| 9 | Pre-construct menu widgets (map, inventory) at the main menu | DLL | Low (no measured hitch) | Low | Pure timing; unmeasured |
| 10 | Pre-warm the old engine's interior cell buffer for a door destination | DLL (reverse engineering needed) | Medium (would hide the 1.2-2.9 s attach, partly) | High (scripts/AI/save state; fails the "identical gameplay" rule unless proven) | Listed to record why it is last, not as a plan |

Not worth pursuing (evidence says no): larger `uGridsToLoad`, smaller AddToWorld slices, `p.EnableDeferredPhysicsCreation`, spreading BLAS/Lumen card captures (look change or DEVICE_HUNG), `D3D12.ResidencyManagement=0`, `r.Streaming.PoolSize` bumps (all in research.md "Tried and not shipped").

## Open questions to settle by measurement (cheap, no code)
1. Where does `vkd3d-proton.cache` live in this Proton setup and does it survive launches? (`/proc/<pid>/environ`, `find / -name vkd3d-proton.cache` after one run.)
2. Per door/exit leg, are game reads hitting the page cache? (`/proc/<pid>/io` rchar vs read_bytes before and after the leg.)
3. Does the 1.7 s max frame in the latest inn-door/exit leg after arrival come from I/O, PSO or GC? (DoorDiag + HitchLedger.)
4. Is there a 60 s GC cadence in the ledger?
5. Does Altar ship with `r.PSOPrecaching` on in the version shipped?

Sources used: local docs listed above, plus
- https://dev.epicgames.com/documentation/en-us/unreal-engine/pso-precaching-for-unreal-engine
- https://raw.githubusercontent.com/HansKristian-Work/vkd3d-proton/master/README.md
- https://www.gamingonlinux.com/2020/05/valve-improve-linux-vulkan-shader-pre-caching
- https://github.com/hoytech/vmtouch
- https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows
- https://stepmodifications.org/wiki/Guide:Oblivion_INI/General
- https://forums.nexusmods.com/topic/1340369-skyrim-memory-patch-fixing-ils-ugrids-ctd-freezes-for-real
- https://forum.step-project.com/topic/14330-periodic-infinite-loading-screen-on-modded-sse-multiple-cells/
- https://spilled.gg/digital-foundry-oblivion-remastered-mess-launch/
- https://www.purexbox.com/news/2025/05/oblivion-remastereds-performance-degrades-over-time-digital-foundry-discovers
- https://dev.epicgames.com/documentation/unreal-engine/dynamic-loading-range-scaling-in-unreal-engine
- https://forums.unrealengine.com/t/gc-extremely-huge-hitches-in-empty-map/147738
- https://forums.unrealengine.com/t/freeze-on-one-frame-for-garbage-collector/2681510
- https://blog.audiokinetic.com/qa/3854/asynchronous-loading-soundbanks-ue4-hangs-packaged-build
- https://lemm.ee/post/44579603
