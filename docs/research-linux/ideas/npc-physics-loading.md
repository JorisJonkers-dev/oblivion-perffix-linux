# NPC creation, physics, loading and saves: further optimisation ideas

Status: research only (2026-11-07). Nothing in the source, ini or benchmark was changed. Items tagged **[MEASURED]** rest on
numbers already in `docs/research.md` or the source comments; **[CODE]** means read from the source but not run;
**[SPECULATION]** has no number behind it yet.

Rules applied (AGENTS.md "Rules"): identical output, or timing-only changes with the game's order kept, few frames, off-screen
only, and an off switch. Every idea below states which of these it relies on.

## What was read

- `AGENTS.md` (fix index, Rules), `src/OblivionPerfFix/src/npcs/` (top comments of `npc_pacing`, `cell_buffer`,
  `anim_teardown`, `cloth_defer`, `cloth_register`, `rig_trace_reuse`, `npc_bodies`, `rig_setup`), `physics/` (`static_bodies`,
  `bulk_insert`, `physics_push`, `destroy_batch`, `physics_flush`, `physanim_lock`), `loading/` (`stream_behind_loading`,
  `collision_prepare`, `fade_hook`, `pso_precompile`, `pso_pool`), `saves/` (`save_bytes`, `save_thumb`, `save_refid`,
  `autosave_menu`).
- Code checked directly: `npc_pacing.cpp` (`CreateExecHook`, `FifoHasKey`, `Defer`, the delegate path), `common.h` (pacing
  defaults), `pso_precompile.cpp` header, `physics_push.cpp` header (the lab-only `PhysicsPushGrowParallel` note).
- Docs: `research.md` (the NPC, physics, loading and saving sections; "Tried and not shipped"; "What still limits the game"),
  `docs/research-linux/npc-creation.md`, `preloading.md`, `oldengine-hotspots.md` (sections 4 and C0-C5).
- Bench tools: `linux/bench.py` has `run` (with `--diag`), `spin` (one spot, ABBA ini flips), `ab`, `report`. Scenes in
  `bench/scenarios/`: `npcburst`, `npc`, `blackwood`, `blackwood-onfoot`, `actors`, `roxey-ft`, `roxey-night`, `cheydinhal`,
  `transitions`, `silver-road`, `playlog-spots`, `ic-spots`.

Checked and found missing from this tree: `OtStage`/`OtSplit`/`OtCrashContext` (the C0 profiler in
`oldengine-hotspots.md`) and the `PerceptionIgnoreReuse` source. Both exist only as text in the docs. `PhysicsPushGrowParallel`
is in the source as a lab key (`physics_push.cpp`, its self-test in `tests/selftest_push.h`) and is not in the shipped ini.

---

## Ranked top 5

### 1. A near create waits behind a far, deferred create (pacing head-of-line blocking)

- **Where:** `npcs/npc_pacing.cpp`, `CreateExecHook` (create command, about line 1219) and `GenericExecHook` (heavy generic
  command); `Defer` and the FIFO ring (`kFifoCap` 1024, `Front()`, `FifoAge()`); `OverBudget(kCreate, PairLag())`.
- **What happens [CODE]:** the pairing queue is one FIFO read by the game thread (GT). A distant create is deferred by
  leaving its command at the read position, and the GT then runs nothing behind it. Creates arrive in the old engine's order
  (the cell row's actor order), not distance order. So a create for an NPC that is near the player, or about to be seen,
  waits for every distant create ahead of it in that row. The delegate path has an exception (`FifoHasKey`: a near unit of an
  actor with no queued units runs now). The create path does not: a near create never bypasses a deferred head.
  Each frame runs at least one unit (the first always runs) and about `PacingBudgetMs` = 4 ms of units, so a near create at
  position k behind far units waits roughly k units' worth of frames (each far unit 5-15 ms, so 1 unit per frame at most).
- **Proposed change (timing only):** while the head of the FIFO is a deferred far create and the next queued command is a near
  create or a near actor's unit, let that frame's budget run over for those commands, with the existing bounds: the lag bound
  (`PacingMaxLagFrames` 15) and one extra unit per frame at most. The order does not change: the commands run in queue order,
  only the frame in which they run.
- **Why the output stays identical [CODE]:** the same commands run in the same order against the same references. Only the GT's
  time per frame changes. The rule that matters is the bound on the time per frame and how long the world runs unseen (not
  applicable here: the near units are the ones the player can see). Off switch: a new hidden key set to 0 keeps the present
  behaviour.
- **Expected gain [SPECULATION]:** shorter wait for visible NPCs created behind a far one, so fewer late pop-ins in dense
  rows. The frequency is unknown. The pacing counters (`maxFifo`, `forced`, `maxLag`) show the queue depth, not which command
  waited.
- **Risk:** low to medium. A frame can run long (the thing pacing exists to avoid), so the bound must be as tight as the
  existing lag bound. No threads involved.
- **Measure first:**
  1. Add a counter to the `[pacing]` stats line: near creates executed while a deferred far create was in the FIFO ahead of
     them, and the wait (us) from arrival to run. No behaviour change.
  2. `linux/bench.py run --diag` on `npcburst`, `blackwood`, `roxey-ft` (arrival) and `transitions`; read the `[pacing]` lines
     and `OblivionPerfFix-ledger.csv` (`tools/stutter_ledger.py`).
  3. If the count is non-trivial, `linux/bench.py spin` at the Sheogorath shrine spot (ABBA on the new key).

### 2. Revive `PerceptionIgnoreReuse` as a shipped, identical cache (GT crowd cost)

- **Where:** the game's NPC perception ignore check, on the GT (perception runs there: `diagnostics/tick_split.cpp` line 108
  shows the timer's delegate as the update scope). The lab code is not in this tree; the design is in `research.md` ("Tried and not
  shipped", `PerceptionIgnoreReuse`).
- **What it did [MEASURED, lab]:** 440,971 comparisons against the game's own result, zero differences; 1.4 % conservative
  fallbacks (the cache returns "no answer" and the game's code runs). Crowd: 510.7 vs 544.5 us per round (-6.2 %, about
  0.3-0.35 ms per frame). Battle: -31 to -35 us per round (-9 %) in five noisy pairs, then -8 (-3 %) as the crowd thinned.
- **Why it was not shipped:** the saving was below whole-frame noise. Now it can be read directly from the perception tick
  group (`HitchLedgerTickSplit`) and an ABBA `spin`, so the noise argument is weaker.
- **Why identical [MEASURED]:** the cache answers only when every input of the question is unchanged (same as RigTraceReuse's
  bit-identical inputs). The zero-difference count is the evidence. The remaining work is to prove that the key covers every
  input the perception check reads (positions, sight state, the game's ignore flags, time or generation counters).
- **Expected gain:** 0.3-0.35 ms per frame in a 40-NPC crowd, where the GT is at 25-27 ms. Small, real, cheap.
- **Risk:** low to medium. The only danger is a missing input in the key, which the 440,971-comparison check would not have
  caught if it never varies in the test scenes. Needs a targeted test for the states the test scenes did not reach (a
  sleeping NPC, a dialogue, a fight).
- **Measure:** `linux/bench.py spin` on `npc` or `npcburst` at a crowd spot, ABBA on the key; `--diag` for the perception
  group's ms per round; a second pass in a battle (`actors`).

### 3. Diagnose, then warm, the "created but not drawn" delay for new characters (pop-in)

- **Where:** the time between the create (`CreateExecHook`, `npc_pacing.cpp`) and the first visible draw. The existing hook
  for this is `PacingFadeAware` (dither >= 3 read from the fade component). What is missing is the PSO state of the character
  materials. Related: `loading/pso_precompile.cpp`, `pso_pool.cpp`, `npc-creation.md` idea #2.
- **What is known [CODE + DOCS]:** UE 5.3's PSO precache (Epic's default) can delay a scene proxy until its PSOs are ready.
  Whether this game does that for characters is unmeasured (`npc-creation.md` says so). `research.md` records helpers compiling
  ray-tracing pipelines for new materials while the allocator lock starves the GT (New materials streaming in).
- **Idea:** first measure. Log, per NPC, spawn -> first `Tick` of the fade component -> first visible frame -> PSO-pending
  state (`stat psoprecache` in a dev build, or the existing `PsoPrecompileFast` timing). If the gap is PSO wait, warm the
  character materials' PSOs when the create command is queued (menus, loading, or the cell attach), on UE's own PSO pool
  (`PsoCompileThreadPool`).
- **Why identical:** only the compile time of the same PSOs changes; no game state. The pool and the PSO set are the game's.
- **Expected gain:** unknown, possibly the largest visible pop-in term left. **[SPECULATION]**
- **Risk:** low (no game state). The cost is CPU contention with compile threads, which `pso_pool` already handles for cold
  caches.
- **Measure:** `npcburst` and `blackwood-flight` with a fresh driver cache and a warm one; `roxey-ft` / `roxey-night` for cold
  materials after a teleport; time-to-visible histogram per NPC.

### 4. Pre-touch the memory the physics and streaming growth will use, during loading screens

- **Where:** `loading/` (the screen's idle frames, where `NpcCreationPacing`'s frame hook already runs) and the allocator
  pages `memory/os_page_cache.cpp` keeps. Targets: the physics tree and array growth (`physics/bulk_insert.cpp`
  `TreeBatchReserve`; `physics/physics_push.cpp` `PhysicsPushGrowParallel` notes).
- **Evidence [MEASURED, lab]:**
  - `TreeBatchReserve` cut enlargements from 161-182 to 19-21, but filing time stayed 27.7 ms vs 26.5 ms: "first writes into
    fresh Windows pages still cost the same" (`research.md`).
  - `PhysicsPushGrowParallel`: about 2.5 of 3.2 ms of a 4.8k-body batch is the reallocation with new pages faulted in
    (`physics_push.cpp` line 45 onward).
  - Fresh-memory page faults run at 60-110k per second in Cheydinhal (`altar-architecture.md`, `OsPageCache`).
  - `TreeLeafTransfer`: the copy was removed and the frame did not change; the first write into fresh memory dominated.
- **Idea:** at a loading screen (no GT work that depends on timing), allocate and write once per 4 KB page a reserve sized to
  the next growth (physics arrays, dirty-tree nodes, the streamer's buffers), then return it to `OsPageCache` with its 5 s
  window extended for the screen's length. The next growth then reuses warm pages.
- **Why identical:** memory contents are not observable to the game; no object, order or count changes. Only resident
  memory rises for the time the reserve is held.
- **Expected gain:** the physics filing and array growth at a new area's arrival (the 25-41 ms collision spikes that
  `PhysicsFlushParallel` and `ParallelStaticBodies` attack). The lab numbers say the page cost is real but do not say how much
  of the spike it is. **[SPECULATION]** on the total.
- **Risk:** medium. Memory: the rule for low RAM (`MemoryRelief` under 1 GB; `SharedMemoryGpu` on UMA) must be respected, and
  the reserve must be dropped under pressure. No threads needed beyond the loading screen's own frame.
- **Measure:** page-fault count (`/proc/<pid>/stat` minflt, or the existing `[mem]` counters) and the `[bodies]`/`[bulk]`/`[push]`
  timers across `transitions`, `roxey-ft`, `blackwood` arrivals and `silver-road`; A/B with `linux/bench.py ab`.

### 5. Parallel form serialisation inside `SaveGame` (the autosave frame's remaining cost)

- **Where:** `TESSaveLoadGame::SaveGame` (exe+0x67198B0, the entry detour in `saves/save_refid.cpp`), `SaveFormIDs`; per-form
  `Save` calls on the OblivionThread (OT).
- **What remains [MEASURED]:** after `SaveBytesBulk`, `SaveThumbnailAsync` and `SaveRefIdIndex`, the 4K save frame is 25-32 ms
  (median 28; was 90-113). The metadata writes are now 1.7-2.7 ms each, two per save. The remaining big item is the old
  engine's `SaveGame` at 19-31 ms of OT time, while the GT waits in the pairing pump (`oldengine-hotspots.md`, C4).
- **Idea (C4 in that doc):** each form's `Save` writes to a private buffer on a helper; the OT then appends the buffers in the
  original order. refIDs are appended during the save (`SaveRefIdIndex` depends on that being sequential), so the refID
  assignment has to stay on the OT, in order, before the parallel part, or be replayed from a recorded list.
- **Why identical:** byte-identical saves are the test. The order of forms and refIDs is fixed by the single OT thread.
- **Expected gain:** 10-20 ms once per save, as C4 estimates. A long game's save is larger (`SaveRefIdIndex` note), so the
  gain there is larger, not measured. **[SPECULATION]** on the size.
- **Risk:** medium-high. Forms' `Save` code touches ExtraData and pairing state, and the refID order is the hard part.
- **Measure:** byte-compare saves from a fixed state (`playlog-spots` or a long-game save, which the benchmark does not
  have, so one must be made), then `--diag` on the save frame.

---

## More candidates (not in the top 5)

| # | Idea | Where | Evidence and gain | Risk | Status |
|---|---|---|---|---|---|
| 6 | Ship `PhysicsPushGrowParallel` (33b) | `physics/physics_push.cpp` line 45; self-test `tests/selftest_push.h` | Lab: 1-1.5 ms per affected frame (`research.md`, "Tried and not shipped"). Rejected as "too small to show". It is in the code and self-tested | low | MEASURED (lab), small |
| 7 | Revisit `OblivionThreadCaches` (per-thread free caches) | OT allocator (not in this tree) | 97 % fewer shared-counter trips; one crossing 26.8-28.2 vs 29.6-31.3 ms (about 2.5 ms per crossing). Rejected as within noise across crossings. It should be retested with C0's OT split and combined with C1a teardown | medium | MEASURED (lab), needs C0 |
| 8 | Robe proxy build off the GT for near robed NPCs | `npcs/cloth_defer.cpp`, `cloth_register.cpp` (the build is the `FClothSimulationProxy` constructor, self-contained per `cloth_register.cpp`) | 5-6 ms per robe on the GT in near units; `ClothBuildDefer` only helps far, unseen ones. The build must be joined before the Blueprint reads the proxy | high | [CODE] + [SPECULATION] on overlap |
| 9 | Keep Fast PSO pace through the fade-in of a door in cold-cache runs | `loading/pso_precompile.cpp` (the "in play" test), `fade_hook.cpp` | The game holds the fade-in 5.7-6.7 s while `IsPrecompiling` (`pso_precompile.cpp` header). The fix's cold-cache guard hands the game's pace back after 60 s or a 1000-entry queue. Trade-off: the world may draw before its PSOs are ready | medium | MEASURED (cold start), trade-off |
| 10 | Drain the creation tail in the loading screen's idle time | `npc-creation.md` idea #3; `npc_pacing.cpp` loading path | Only useful if completion delegates and cloth builds are still open at fade-to-game. Not measured. Longer loading screens (a visible trade-off) | low-medium | SPECULATION, diagnose with `DoorDiag` first |
| 11 | RigLogic name-map prewarm for each DNA on the loading screen | `npcs/rig_setup.cpp` (`RigLogicMapCache`) | About 1.3 ms per head, first head of each DNA only (cache is per DNA, content-keyed). Small | low | SPECULATION on the count |
| 12 | Cheaper per-frame streamer update during loading | `loading/stream_behind_loading.cpp` | 2.1-2.7 ms per loading frame measured, above the ~1.2 ms aimed for (`research.md`). The loading screen is not GT-bound, so the gain is the screen's length only | low | MEASURED, small |
| 13 | Metadata save async (`Altar.Save.AsyncMetadataSave`) | `saves/save_bytes.cpp` header | The game's switch is off, the reason is not written down. The writes are now 1.7-2.7 ms each, twice per save: at most ~5 ms per save | low-medium | MEASURED, small |
| 14 | Helper-side shape prep for `InstantiatePhysicsAsset_Internal` | `npcs/npc_bodies.cpp` (the hold is already there) | Covered by `npc-creation.md` #1; the NpcBodiesOneLock hold means bodies cannot be made concurrently. Gain unknown | medium-high | SPECULATION |
| 15 | Horses and creatures: extend the cloth / rig / teardown fixes | `rig_trace_reuse.cpp` (horses covered), `physanim_lock.cpp` (covered), `anim_teardown.cpp` (any actor's data) | No measured remaining cost beyond the Brindle corral (`oldengine-hotspots.md` C5a: 17-20 ms with the GT waiting, not yet split) | low | Needs C0 / ticksplit at the corral |

## Revisit list from `research.md` "Tried and not shipped"

| Rejected idea | What the record says | Revisit? |
|---|---|---|
| `PerceptionIgnoreReuse` | Identical in 440,971 checks, -6 % crowd time | Yes, idea 2 |
| `OblivionThreadCaches` | 2.5 ms less per crossing, "within noise" | Yes, idea 7 |
| `PhysicsPushGrowParallel` | 1-1.5 ms per affected frame, "too small" | Yes, idea 6 |
| `TreeBatchReserve`, `TreeLeafTransfer` | Enlargements fell, but the first write into fresh pages dominated | Yes, as idea 4 (pre-touch) |
| `PhysicsFlushThreeWay` | No measurable gain at 4K | No (already tried with noise) |
| Keeping a character's first animation instance | No measurable gain | No (it also changes set-up) |
| `MeshMergeReserve` | Fewer temporary-array growths, no measurable gain | No |
| `UnfreezeBehindLoadingScreen` (off) | Kept as a trade-off (world runs unseen up to ~1 s) | Only with idea 10's measurement |
| `ClothRegisterSkip` | Bounds need the first build's proxy | Only with idea 8 |

## Ruled out (breaks the order or the output rules)

- Running near creates ahead of far ones in the queue: changes object indices and tick order.
- Pre-creating characters before the old engine asks for them: creation is driven by its create commands.
- Pooling actors or skeletal mesh components: changes identity and state.
- Running pacing units on helpers: UObject creation and Blueprint code are GT-only.
- Starting the world behind the loading screen (already rejected in `research.md`).

## How to measure, in order

1. `linux/bench.py run --diag` on `npcburst` and `blackwood` for the pacing counters (idea 1), `HitchLedgerTickSplit` for
   the perception group (idea 2), and `[bodies]`/`[bulk]`/`[push]` for idea 4.
2. `linux/bench.py spin` at one spot (crowd: `npc`; shrine: `npcburst`; corral: `playlog-spots`) with the key flipped live in
   ABBA order. The spin mode is the one that gives a stationary profile.
3. Fresh driver cache vs warm, and a teleport arrival (`roxey-ft`), for idea 3.
4. Byte-compare saves for idea 5 before any timing.

Every timing change above (ideas 1, 3 and 4 if they add frames) needs an off switch, a log line when it is off, and the
pacing bounds (`PacingMaxLagFrames`, a per-frame cap), as the Rules require.
