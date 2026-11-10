# NPC creation and pop-in: pipeline, limits, and fix ideas

Method: local docs and source (grep'd, not read whole) plus web searches. Local refs: `research.md` = docs/research.md section
"Travelling: characters and cells" (lines ~980-1290), "Doors, loading screens" (~1291+), "What still limits the game" (~2581),
"Tried and not shipped" (~2515). Source refs are file headers in `src/OblivionPerfFix/src/`. Web claims carry a URL. Anything
marked **[SPECULATION]** has no measurement or source behind it. No game was run and nothing was measured for this note.

## 1. The per-NPC pipeline today

### 1.1 Stages (all on the UE GameThread, "GT"; research.md "Far-away characters created a piece per frame")
The OblivionThread ("OT", old engine) attaches a cell row and emits a create command per actor into the FIFO pairing queue
(OT -> GT, "Replication" session -1; npc_pacing.cpp header (a)). The GT runs it in `OnWorldPreActorTick` via `RunSession`.
Per NPC, 20-40 ms of GT work in units that cannot be split:

| # | Unit | Cost | Notes |
|---|---|---|---|
| 1 | create command: SpawnActor, first anim setup (InitAnim #1), construction script, AI controller | 4-12 ms | npc_pacing.cpp `kCreateExec` |
| 2 | head / headwear generic pairing command | ~7 ms | "heavy generic command", paced when a distant create preceded it |
| 3 | appearance apply, one frame later, from an async-load completion delegate (real body + head meshes, InitAnim #2, physics asset, control rigs) | 4.6-14.6 ms (16-22 ms at the worst) | FStreamableDelegateDelayHelper runs all due delegates in one frame (header (b)) |
| 4 | one equipment unit per clothing piece (child actors; robe: Chaos cloth proxy built 1-3x) | 13-21 ms per robe | ClothRegisterLite / ClothBuildDefer |
| 5 | hair | 1-3 ms | |

Inside units 1/3/4 (research.md): `InitArticulated` -> `InstantiatePhysicsAsset_Internal` makes ~37 bodies plus constraints per
humanoid, ~550 solver write-lock scopes (NpcBodiesOneLock); 2-3 `UControlRig` per humanoid each call `URigVM::ComputeVMHash` 4x
(RigVmHashMemo) and the head rig's `FRigUnit_RigLogic` maps every DNA name to a hierarchy index on a worker the GT waits for
(RigLogicMapCache); cloth `RecreateClothSimulationProxy` is "most of a robed NPC's creation unit" (few ms per robe, 3 builds).
Also GT waits on the allocator's global lock while helpers compile new materials' RT pipelines ("What still limits the game").

### 1.2 What already exists
- `NpcCreationPacing`: far (>4096 u), unseen (not rendered 0.5 s, or still in dither fade-in >= 3) units run under a ~4 ms/frame budget; FIFO
  kept; grows with age (3x at 15 frames), forced at 30 frames; off in loading screens/menus/travel (drains at once). Worst frame
  61-98 -> 31-54 ms, "the same work runs in about twice as many shorter frames". It does not reduce total work; it spreads it, which is
  itself the "slow, staggered" pop-in the goal wants to reduce (but only for unseen far NPCs).
- Work removed or moved: ClothRegisterLite (builds without AddRules, completes once), ClothBuildDefer (held to a quiet frame inside budget),
  NpcBodiesOneLock, RigVmHashMemo + RigLogicMapCache, NpcFadeInNoRebuild, AnimTeardownParallel (helpers), CellBufferPacedEvict.
- Behind the loading screen: PrepareCollisionBehindLoadingScreen (zero-time physics step), StreamBehindLoadingScreen (textures; the arming-to-fade
  window is idle: fade gate is a 0.5 s timer), optional UnfreezeBehindLoadingScreen (off; trade-off, world runs unseen up to ~1 s).
- Physics parallelism precedent: ParallelStaticBodies (`CreateShapesAndActors` split over threads, scene add stays ordered on GT),
  PhysicsPushParallel.

### 1.3 What must stay on the GT, and why
- UObject creation: UE 5.3 `NewObject`/`SpawnActor`/`RegisterComponent` are GT-only in practice; off-thread creation is only for the async loader,
  and risks GC races. Forum reports of the assert and the RF_Async flag: https://forums.unrealengine.com/t/creation-of-uobjects-outside-the-game-thread/339290
  and the advice to keep worker data as plain C++ and build the UObject on the GT: https://answers.unrealengine.com/questions/337378/view.html
  (forum sources, not Epic docs).
- Order: component registration, `AddPrimitive`, Blueprint construction script, delegates and the pairing queue define observable order (object
  indices, tick order, FIFO to OT). Reordering breaks "identical output".
- Scene writes: Chaos scene add and the GT acceleration-structure copy; `ExecuteWrite` takes the solver lock (NpcBodiesOneLock).
- Thread-safe candidates (plain data, no UObject writes): physics shape/geometry creation (precedent `ParallelStaticBodies`), cloth solver/proxy
  internals after the asset is read, DNA parsing/name-to-index replay (already cached), Anim interpolator teardown (already helper), texture/mesh/material
  async loads (streamable manager / async loader), PSO compiles (UE's own pool).

## 2. What the UE side offers (web)
- Level streaming already time-slices registration: `s.LevelStreamingActorsUpdateTimeLimit` (ms/frame), `s.LevelStreamingComponentsRegistrationGranularity`,
  parallel primitive add granularity, `s.UnregisterComponentsTimeLimit`: https://dev.epicgames.com/documentation/unreal-engine/streaming-settings-of-the-unreal-engine-project-settings .
  Limitation reported: granularity counts components, not their cost, and a time limit is only checked per increment:
  https://forums.unrealengine.com/t/world-partition-streaming-performance/2577446 . **Local evidence they do not help here**: the game's NPCs are not created
  by level streaming but by the old-engine pairing queue; `AddToWorldTimeSliceMax 2` and `RegistrationGranularity 2` gave "no gain" within noise
  (research.md "Tried and not shipped"), as did `p.EnableDeferredPhysicsCreation 1` and finer level streaming budgets.
- Actor pooling/deferred spawn: Epic has no native pool; recommendation is a custom pool per actor type or per-frame spawn budgets
  (https://forums.unrealengine.com/t/actor-pooling/2686724 , https://forums.unrealengine.com/t/spread-spawning-across-multiple-frames/2001269).
  Mass's actor spawner already spawns under a time budget and has overridable `SpawnOrRetrieveFromPool`
  (https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/MassActors/UMassActorSpawnerSubsystem). Pooled skeletal mesh components skip init cost but can
  carry stale transforms into motion vectors (https://forums.unrealengine.com/t/how-to-properly-manage-motion-vectors-for-primitives-in-render-scene/2704355).
  Pooling here would change object identity/state (construct scripts, AI controllers, fade-in), so it breaks the Rules; **do not pursue**.
- Async asset loading helps only if no hard references are resolved synchronously afterwards (sync-loaded refs of an async-loaded asset block the GT):
  https://forums.unrealengine.com/t/requestasyncload-blocks-gamethread/217684 . In this game the appearance apply is already an async-load completion
  (research.md `exe+0x48D09B0` note; header (b)), so mesh loading is already off the GT; the unit's cost is registration, InitAnim, physics, rigs.
- PSO precaching: components gather PSOs after load, compile on a thread pool, and by default **delay scene-proxy creation until PSOs are ready**
  (https://dev.epicgames.com/documentation/unreal-engine/pso-precaching-for-unreal-engine); on in cooked D3D12 builds in 5.3. If the remaster uses the default
  strategy, a freshly created character can be created on the GT yet drawn later. `PsoPrecompileFast`/`PsoCompileThreadPool` already speed the pool.
  `stat psoprecache` and `r.PSOPrecache.Validation` exist in packaged builds per that page. Whether this game has a cold-PSO delay for characters is **unmeasured**.
- RigLogic: DNA runtime context is shared between rig instances of the same DNA (https://dev.epicgames.com/documentation/unreal-engine/API/Plugins/RigLogicModule/UDNAAsset),
  consistent with RigLogicMapCache's per-DNA replay.
- Other games: Bethesda games tie pop-in to `uGridsToLoad`/exterior cell buffer; community reports that larger values reduce pop-in but cost memory/performance and
  can break saves/quests (https://ck.uesp.net/wiki/UGridsToLoad , https://forums.nexusmods.com/topic/13000854-psa-ugridstoload-limits ,
  https://forums.nexusmods.com/topic/6558706-fallout-4-objectnpc-load-in-problem). Nothing usable found for Starfield or Cyberpunk NPC pre-spawn internals (searches returned mod pages only).

## 3. Ranked fix ideas

Ranking weighs expected gain per unit risk under the project Rules (identical output, order, off switch).

### #1 Helper-thread shape/body prep for `InitArticulated` (and cloth proxy internals)
- **Moves**: the shape/geometry creation part of `InstantiatePhysicsAsset_Internal` (~37 bodies, constraints) onto helpers, with the scene add and lock order kept on the GT; as `ParallelStaticBodies` does for instances (static_bodies.cpp: first instance on GT, rest parallel, add in array order).
  Optional second target: `FClothSimulationProxy` build inside ClothBuildDefer's held build, which already runs at pacing's frame start (known isolated point).
- **Identical because**: same code, same inputs, results filed in the same order; precedent already verified (ParallelStaticBodies/PhysicsPushParallel). Needs a proof that skeletal-body creation touches no GT-only state (UObject reads of the physics asset's body setups, `FPhysicalMaterial` first-use init, weak-pointer serial numbers).
- **Gain**: unknown; appearance apply is 4.6-14.6 ms, of which physics is a fraction. **[SPECULATION]** 1-4 ms per humanoid. NpcBodiesOneLock's note says the GT waited behind scene queries, so lock contention may be the bigger share, and `p.Chaos.EnableAsyncInitBody` is already 1 in the game (research.md) so part of body init is already async.
- **Risk**: medium-high. Shape creation in a skeletal context is sequenced through `FPhysicsCommand::ExecuteWrite` per body (~550 lock scopes), which NpcBodiesOneLock merged; running bodies concurrently conflicts with that single hold. Cloth proxy build touches asset UObjects and solver lists.
- **Sketch**: detour `InstantiatePhysicsAsset_Internal` (already wrapped in npc_bodies.cpp; pinned by FNV-1a) into a two-phase wrapper; reuse the helper pool from static_bodies.cpp.
- **Measure**: `npcburst` scene `peryite-flight` (5 robed worshippers + 4 creatures; Sheogorath equivalent `blackwood-flight`); metrics: sum of NpcCreationPacing units over the ~18 frames (baseline 183/194/181/181 ms with ClothBuildDefer off, 110-119 on), frames >25 ms; HitchLedger CSV; ABBA live toggle.

### #2 Prove or kill "created but not drawn" (PSO precache / render-state delay) and warm PSOs for character materials
- **Moves**: PSO compile of character materials from first draw time to earlier (menus, loading screens, cell attach). Candidates: enlarge the PSO precache thread pool priority while pacing queues are non-empty; kick `PrecachePSOs` for the character materials of a queued create command's actor class **[SPECULATION: needs the asset list per queued command]**.
- **Identical because**: only compile timing changes; the same PSOs compile either way. If the proxy waits for PSOs (Epic's default strategy), earlier PSOs mean earlier appearance without extra GT work.
- **Gain**: unknown, could be the biggest visible pop-in term if the delay exists; pure speculation until `stat psoprecache` / the existing pso hooks (`loading/pso_precompile.cpp`, `pso_pool.cpp`) show characters pending. Local notes already show helpers compiling RT pipelines for new materials starve the allocator lock and delay first draws ("New materials streaming in", "What still limits the game").
- **Risk**: low (no game-state change); only CPU contention with compile threads.
- **Sketch**: diagnostic first (log time from SpawnActor to first render for a sample of NPCs via the fade component's first tick vs. first visible, extend pacing's stats line); then act.
- **Measure**: `npcburst`, `blackwood-flight` (night: `roxey-ft` / `roxey-sercen-night` for cold materials after teleport); fresh-driver-cache vs warm runs.

### #3 Use the loading screen's idle tail for pending creation, with a bounded gate hold (optional, off by default)
- **Moves**: units that are still queued or whose async-load completion delegates are still pending (appearance, equipment, hair, one frame behind the create) get drained before the fade-in, in the window between "loading idle" and fade (StreamBehindLoadingScreen already uses this window per frame via NpcCreationPacing's frame hook).
- **Identical because**: same units, same order; pacing is already off in loading screens (research.md "Nothing waits during travel, loading screens or menus"), so for door and fast-travel arrivals the NPCs in the destination cell are created while the screen is up. What is **unknown** is how many *completion* delegates and cloth builds are still outstanding at fade-to-game; the dither fade-in also makes characters appear over 1.25 s (research.md) regardless. A hold on the fade gate beyond stock lengthens the loading screen, which is a visible trade-off (same class as UnfreezeBehindLoadingScreen), so it needs a cap and a default of off.
- **Gain**: removes post-fade creation hitches only if they exist; diagnosis first with DoorDiag (per-door timeline) plus pacing unit logs after fade. The door-exit hitch the existing fixes already attack (123-270 ms frame at fade) was collision/texture, not NPCs.
- **Risk**: low-medium (loading flow is fragile: fade gate delegates, freeze state; see UnfreezeBehindLoadingScreen's "First version wrong").
- **Measure**: `actors` scene `ic-market-inn-door` (in and out of the busy district), `roxey-ft` (teleport arrival), transitions.json; count GT units after fade-to-game; compare pop-in time of first visible complete NPCs.

### #4 Smarter pacing policy for visible-soon NPCs (not just far/unseen)
- **Moves**: pacing already delays far unseen units up to 30 frames. Improve ordering within the FIFO is impossible (order must hold), but the budget can scale with distance/time-to-visible (player speed) so nearer-soon NPCs complete sooner while far ones stay cheap. Reduces *staggering*, not total cost.
- **Identical because**: timing only, same bounds as the Rules require (few frames, off-screen only, game order, off switch).
- **Gain**: reduces late appearance of NPCs that become visible while queued; gain depends on route. **[SPECULATION]**.
- **Risk**: low; already well-instrumented. **Measure**: `blackwood-flight` / `blackwood-return`, `npcburst`; time from cell attach to completion, frames >=33 ms.

### Not recommended
- **Run NpcCreationPacing units on helpers** (3c): units are SpawnActor/RegisterComponent/Blueprint/child-actor calls; UObject creation and Blueprint VM are GT-only (see 1.3). Only the thread-safe sub-work in #1 is viable.
- **Pre-creating characters before the OT asks for them**: creation is driven by the OT's create commands (queue is FIFO and defines references); the UE side cannot create an NPC the OT has not attached. The only knob that moves the attach earlier is uGridsToLoad.
- **Actor pooling**: breaks identity/state; Epic provides none natively (links in section 2).

## 4. Evaluation of the four requested items
- **(a) Create/cache characters of destination cells behind the loading screen**: already partially true (creation runs unpaced during loading; destination cells are attached by the OT behind the screen). Caching finished characters between visits is not possible without pooling/identity changes. Remaining opportunity is idea #3 (drain outstanding completion work before the fade, bounded). Needs DoorDiag-style measurement first; risk is a longer loading screen.
- **(b) Warm character assets when cells attach but before the NPC unit runs**: meshes/materials already load async (the appearance apply is an async-load completion). What can still be warmed is PSOs and render resources (idea #2). Rig DNA is already memoised after the first head (RigLogicMapCache); a first-ever DNA could be warmed on a helper at start-up by replaying the name mapping **[SPECULATION; no gain figure]**.
- **(c) Run units on helpers**: only sub-work (#1), not units; UObject creation is GT-only.
- **(d) Larger look-ahead (uGridsToLoad / buffer)**: `uExterior Cell Buffer` bigger is already done (CellBufferPacedEvict adds 2g-1 slots) and only keeps detached cells, creating no NPCs. A larger `uGridsToLoad` makes the OT attach and activate more cells earlier: NPCs are created farther away and sooner (more lead time, which pacing could use), but it changes which actors are active (AI, scripts, memory, load time) so it violates "no gameplay change" and the community reports instability/saves breakage (links in section 2; the Bethesda-engine reports are for other games' builds of the same engine lineage). **Optional off-by-default trade-off at best; not a fix.**

## 5. Top 3 summary
1. **Helper-thread physics (and cloth) prep inside unit 3/4** - expected 1-4 ms per humanoid **[SPECULATION]**, evidence: ParallelStaticBodies precedent, NpcBodiesOneLock lock-wait finding. Risk medium-high (lock order, GT-only UObject reads).
2. **Diagnose then warm PSO/render-state delay for new characters** - gain unknown (potentially the largest visible-appearance term), risk low, first step is measurement; UE's default delays proxy creation until PSOs are ready (https://dev.epicgames.com/documentation/unreal-engine/pso-precaching-for-unreal-engine).
3. **Drain outstanding creation work in the loading screen's idle tail** (optional trade-off, bounded) - gain only if post-fade hitches are confirmed by DoorDiag; risk low-medium (loading flow; longer screen).

Honest conclusion: most remaining cost is GT-only registration, anim init, Blueprint and physics, in 4-22 ms unsplittable units. Large wins from "more threads" or "earlier creation" are limited; the stagger is mainly bounded by pacing itself, so a policy tweak (#4) and measurement of PSO delay (#2) are the cheapest ways to shrink visible pop-in. Related negative results already in the repo: keeping the first anim instance (no gain), UE streaming time-slice cvars (no gain), `MeshMergeReserve` (no gain).
