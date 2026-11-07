# The old engine: frame structure, hotspots and a ranked change list

Scope: build 19115871 (TimeDateStamp 0xF19077A4 as read by `pefile`; image base 0x140000000). Everything is an RVA written
`exe+0x...`. Static analysis only: the game and Steam were not started, the game folder was not modified, the exe was
read through a read-only mapping.

Confidence tags used throughout:

- **[V]** verified in the binary by this study (disassembly, `.pdata` function bounds, RTTI, string references, byte
  pattern that matches exactly once in `.text`).
- **[D]** taken from this repo's docs/sources (`docs/research.md`, `docs/how-it-works.md`, fix sources); measured
  there, not re-measured here.
- **[I]** inferred (from names, shapes, original-Oblivion knowledge); plausible, not proven.
- **[U]** unverified; the "how to confirm" is given.

## 0. Method, and what the sources gave

1. **OBSE64** (github.com/ianpatt/obse64, cloned and read). It is small but gives four exact anchors for this build
   family and they all match the binary: `OblivionThread_Target = exe+0x65D2070 + 0x1208` (the call that is passed the
   string "Oblivion Main loop"; `exe+0x65D3278` here, string at 0x65D3271 [V]), `UnrealGameThread_Target =
   exe+0x3907660 + 0x53`, `g_extraListCS = exe+0x947FF00` (one global CRITICAL_SECTION for ExtraDataList), `g_dataHandler =
   exe+0x9480018` (TESDataHandler), player `exe+0x941F708` (our code and the loop agree), `LookupFormByID = exe+0x66114B0`,
   `FMemory::Malloc exe+0xE32F40`. xOBSE (the 2006 x86 headers) was cloned too; its struct layouts are *not* valid for
   x64 and were used only for class names.
2. **RTTI**. The exe keeps MSVC RTTI for the old engine: 2,255 type descriptors, 1,982 classes with vtables recovered
   (script: scan `.data` for `.?AV` names, find COLs, then the qword that points at each COL). That names `TES*`,
   `Actor`, `Character`, `Creature`, `PlayerCharacter`, `HighProcess`/`MiddleHighProcess`/`MiddleLowProcess`/
   `LowProcess`, `bhkWorld`/`bhkWorldM`/`bhkRigidBody`/`bhkCharacterController`, `Script`, `ScriptEffect`,
   `BSTaskManager<__int64>`, `ExteriorCellLoaderTask`, `DistantLODLoaderTask`, `AttachDistant3DTask`, `LipTask`,
   `NiPSysUpdateTask`, `NiGeomMorpherUpdateTask`, `IOManager`, `BackgroundLoaderThread`, `BackgroundCloneThread`,
   `PathBuilder`, `PathHigh/MiddleHigh/Low`, `ObjectThreadLock::LOCK_DATA`, `hkMultiThreadedSimulation` listeners, ... [V].
   There is no `ProcessLists` or `TES` vtable (they are plain singletons); there is no `ScriptRunner` type either.
3. **Assert-path strings** (`W:\Altar\Oblivion\Sources\...`) tie functions to source files. The ones that exist as
   strings: `Oblivion\AI\{Actor,BaseProcess,HighProcess,MiddleHighProcess,MiddleLowProcess,LowProcess,ProcessLists,
   PlayerCharacter,CombatController,...}.cpp`, `TES Shared\{TES,TESObjectCELL,TESObjectREFR,ExtraDataList,TESScript,
   TESSaveLoadGame,TESPathGrid,TESQuest,GridCell,Animation,...}.cpp`, `BSHavok\{bhkRigidBody,bhkConstraint,...}.cpp`,
   `Oblivion\UE5Pairing\{HandlersATO\Magic\VATOSpellHandlers,SaveSystem\VAltarSaveData}.cpp`. Each was resolved to the
   functions that load the string (RIP-relative `lea` index over `.text`), e.g. `ProcessLists.cpp` -> exe+0x6749B8E /
   0x674A152 / 0x674A5F2 / 0x674ABA6 [V].
4. **Function bounds** from `.pdata`; calls from capstone; callers by E8/E9 scan; globals by RIP-relative scan.
   One caveat: `.pdata` splits big functions into chunks, so "size" below can be only the first chunk.
5. **Settings table**. Ini settings are an array of 16-byte `{value, name-pointer}` records in `.data`. Finding who reads
   a setting = finding RIP-relative references to its value slot. This gave the "dead switch" findings in 1.4 [V].

Not done: no full decompile (no Ghidra run), no dynamic confirmation. Names marked [I] are my labels, not the
developers'.

## 1. The old engine's frame in the remaster

### 1.1 Thread and loop [V unless tagged]

| What | Where |
|---|---|
| OblivionThread body (start-up, load of data, then the loop), 0x18C5 bytes | `exe+0x65D2070` .. `0x65D3935` |
| Loop head, after the "Oblivion Main loop" debug call (a stubbed `ret`, `exe+0xD4A910`) | `exe+0x65D3271` |
| `Begin(frame)` of the pairing manager: `mgr = exe+0x4593DE0()` (global `exe+0x92CE738`), `call [vtbl+0x30]` with `edx = [exe+0x8FAA708]` (OT frame counter) | `0x65D327E`..`0x65D328F` |
| Windows message pump for the OT's window (PeekMessage-style loop on imports) | `0x65D32E0`..`0x65D3322` |
| **The frame body**: `call exe+0x65D3940` (size 0x909) with rcx = `[exe+0x941F740]` (the "Main" object; byte +0 = quit, +1 = pending reload/new game request handled at the frame boundary, `0x65D3375`) | `0x65D333B` |
| End of frame: `mgr = 4593DE0()`; `call [vtbl+0x38]` (`Handler_End`, edx = frame counter, r8d = 1: the OT's end-of-frame command into the queue to the GT); then **if frame counter > 1: `call [vtbl+0x70]` (`RunSession`) with edx = -2** | `0x65D360B`..`0x65D363D` |
| Back to the loop head | `0x65D365D` -> `0x65D3271` |

Pattern for the end-of-frame wait (unique in `.text`; it is the pairing sync point):
`41 FF 51 38 83 3D ?? ?? ?? ?? 01 76 ?? 4C 8B 03 BA FE FF FF FF 48 8B CB 41 FF 50 70` (match at exe+0x65D3625).
Pattern for the frame body's entry (unique): `48 89 5C 24 08 48 89 6C 24 18 48 89 74 24 20 57 41 56 41 57 48 83 EC 60 48 8B E9
48 8B 05 ?? ?? ?? ?? 80 B8 1B 01 00 00 00 0F` (exe+0x65D3940); it returns at once when `TES+0x11B` is set (travel pending),
as `npc_pacing.cpp` also relies on (`TES+0x11A/0x11B/0x120` are the Change_Level_With_Fade flags).

Singletons seen in the frame (all [V] as addresses, labels [I]): TES `exe+0x941F748`; player `exe+0x941F708`; Main
`exe+0x941F740`; TESDataHandler `exe+0x9480018`; TESSaveLoadGame `exe+0x9482E80`; ProcessLists getter `exe+0x674B050`;
frame delta `exe+0x9486F3C` (float seconds) with its time-scale companions `exe+0x8FB2E28/2C/30` chosen per game state
(three branches at `0x65D3A5B`..`0x65D3B59`); frame counter `exe+0x8FAA708`.

### 1.2 What one frame runs, in order (`exe+0x65D3940`) [V order; names [I]]

Called functions in source order, with what I could confirm about each. "stage" = the value the engine itself writes to
`exe+0x9484250` just before a stage, see 1.5.

1. **Menu/pause gate** (`0x65D396F`..`0x65D3A0D`): `exe+0x65699B0` (a cheap menu-mode query, called ~12 times in the
   frame) decides whether the world runs; `exe+0x65E4410(flag)` sets the Havok pick-counting flag `exe+0x941F986` and zeroes
   the per-kind pick counters `exe+0x941F9A8..9B4` when the flag changes (so picks are counted only while the world
   runs). On the pause edge (`exe+0x941F7FA` toggles) the high-process actor list is walked once.
2. **Time**: `exe+0x68D4090`, frame counter++, a tick-count import call, `exe+0x68220B0` (delta), `exe+0x65E0E50(dt)`,
   time-scale globals, `exe+0x67E2190`.
3. **Interface/menu update** (`exe+0x65DA4D0`, `0x656A010/2D0/240`, ...: InterfaceManager.cpp assert path) -
   UI-side old-engine code; not the cost centre.
4. **TES housekeeping**: `exe+0x66B1000` (strings `TestAllCells.xls`, `Cell "%s" Verts`: a debug/test sweep; no-op in
   play), `exe+0x68CDFE0`, `exe+0x672B160` (string `Send_Oblivion_Date`: the game date sent over the pairing to UE),
   `exe+0x66AFAE0`, `exe+0x66DEB70`, `exe+0x68C7530`, `exe+0x66AFE10`.
5. **ProcessLists, part 1** (stage markers 0 -> 0x32): `exe+0x674B050()` then `exe+0x67406B0(ProcessLists)`; its first
   chunk calls `exe+0x65FEE90` and loops the list at `ProcessLists+0xB0` (calls an Actor virtual) [I: movement/physics
   pre-pass].
6. **ProcessLists main update**, only if the menu gate allows (`0x65D3D86`: `65699B0()==0` or the menu's "world
   keeps running" flag, `exe+0x68A5760(0x948BCC8, 2)`): marker 0x64, **`exe+0x674AC70`** (details in 1.3); marker 0xC8,
   `exe+0x67406B0` again; marker 0x12C, `exe+0x6749330` (loops `ProcessLists+0xB0`, Actor virtual `+0x350` per entry);
   marker 0x190. Exact byte pattern of the marker writes in the source (unique): `C7 05 ?? ?? ?? ?? 32 00 00 00 E8 ?? ?? ?? ??
   84 C0 74 ?? BA 02 00 00 00 48 8B 0D` (exe+0x65D3D7C).
7. **Player and the grid** (`0x65D3DFA`..`0x65D4047`): menu-mode variant (`exe+0x65F7660`, `0x65F76F0` = `UpdateActorAlpha`)
   or the normal variant (player virtual `+0x2D8` then `+0x4C0(dt)`); `exe+0x66B28B0(TES)`; then the player's
   position -> `exe+0x665DE60`/`0x665CBD0`/`0x662BA90` (find the cell at the player) -> **`exe+0x66B2000` (the cell-grid
   change; call site `0x65D3F20`)** unless the cell type is 3 or 6; `exe+0x6655BE0` (`BaseExtraList::AddExtra` string);
   `exe+0x68D5930` (camera: `SetCamera() requires non-NULL position and direction values`); a **second grid-change call**
   (`0x65D3F86`) with the player's own position (`player+0x64`) when `player+0xB68 == 0`; then `exe+0x6602180` (size
   0xCA7: the player cell/door arrival handler; strings `FadeToGameFromSameJailInterior`, `OTA_TriggerGetUp_Quick`, music
   folders, "Failed to send %s at frame %u : object %s is NOT pairable", `Spawn_Actor`). Both grid-change sites are the
   ones `CellBufferPacedEvict` hooks [D, matches].
8. **ProcessLists, part 2** (`0x65D406E`): `exe+0x674AE00(ProcessLists, dt)` (loops `ProcessLists+0x80`) [I: the
   per-frame time-driven pass: active effects/timers].
9. **Water / time-driven world**: `exe+0x66B1D50(TES, dt)` (strings `Interior Water Node`, `Time_Update_Handler`),
   `exe+0x66E3E30`, `exe+0x68C03A0`, interface refresh, `exe+0x6794240` (date/time UI, `Send_Slider_Value_Changes_From_
   SleepWaitMenu`).
10. **Level-change / music / fade / save tail**: `exe+0x66B0E80` (`Global_Stop_Dialogue_Voice`, `Data\Music\*`),
    `exe+0x67E1290`, `exe+0x68A51F0` (fader), `exe+0x65D4570` (`autosave` / `quicksave` / `Send_Save_Data`: the
    OT-side save entry), `exe+0x66F9D60` (main menu).

Not located in this frame's direct call list: the **per-frame Havok step**. `exe+0x65E1030` (bhkWorld::Update, docs) is
vtable slot 32 of both `bhkWorld` (vtbl `exe+0x861B5D0`) and `bhkWorldM` (`exe+0x867D578`) [V], and its only direct-call-
shaped callers are the two world-creation sites `exe+0x665D716` (in `0x665D310`) and `exe+0x665922C` (in `0x6658F30`)
[V]. The stepping call site is a virtual call I did not find statically [U]; one OT stack sample inside a fight
(`-Stacks OblivionThread`) names it. Havok settings applied here: `fMaxTime=0.0167` (read only at creation,
`0x66592...`/`0x665D6C0`), `iNumHavokThreads=1` (read at creation, `0x6658FA2`, `0x665D39D`), `iMaxPicks=40`,
`iUpdateType=0`. The bhkWorld has two enter/leave counters at `+0x34`/`+0x38` (`exe+0x65E4450/60`, `0x65E4590/A0`)
that the grid change brackets itself with (calls at `0x66B2647`/`0x66B2678`, `0x66B24EA`..`0x66B2504`) [V]; I read them
as "world update suspended while cells are attached" [I].

### 1.3 `ProcessLists::Update` (`exe+0x674AC70`) [V structure, level names I]

Pattern (unique): `40 53 48 83 EC 30 48 8B D9 0F 29 74 24 20 48 8B 0D ?? ?? ?? ?? C7 05 ?? ?? ?? ?? 6E 00 00 00 48 85 C9 74`.
It accumulates the frame delta into `ProcessLists+0x48`, derives an integer from `870FDAC / dt` (a frame-rate bucket:
<10, 10..49, >=50) and uses it to throttle how often the low levels run; then, each guarded by a byte flag of the lists
object, calls in this order (stage marker in brackets):

| order | flag | callee | marker | notes |
|---|---|---|---|---|
| 1 | `+0x141` | `exe+0x6749B30` (31 bytes, a list walk) | 0x78 | [I] low process list |
| 2 | `+0x143` | `exe+0x674A580` -> `exe+0x674A5F2` (markers 0x83..0x8A, 0x1F9, 0x84 inside) | 0x82 | [I] middle-low |
| 3 | `+0x142` | `exe+0x674A1D0` (a list walk) | 0x8C | [I] middle-high |
| 4 | `+0x140` | **`exe+0x6749460`** (0x6D0 bytes) | 0xB4 | [I] **high process**: walks `ProcessLists+0xB0`, calls Actor virtuals `+0x350,+0x3A0,+0x2D8,+0x2C0,+0x3F0,+0x310,+0x420,+0x360,+0x418,+0x428` per actor, `0x65C59C0`, `0x65C5CE0/5F50` |
| end | | | 0xBE | |

The mapping flag -> "high/middle/low" is my reading from the original Oblivion design (`HighProcess`,
`MiddleHighProcess`, `MiddleLowProcess`, `LowProcess` all exist as classes [V]) and from `BaseProcess` virtual slots 257
/ 271 / 272 which each of the four process classes overrides and which read `bUseBackgroundPathing` (1.4); the order of
the four calls and the markers are [V]. Per-actor work therefore sits behind *virtual calls on the actor and on its
process object*, with the actor list order being the BSSimpleList order of `ProcessLists`.

### 1.4 Parallelism and switches that already exist in the old engine [V]

Shipped `Content/Dev/ObvData/Oblivion.ini` (identical to `Oblivion_default.ini` for these keys), and who reads the
setting in code:

| setting | shipped | readers in code | meaning |
|---|---|---|---|
| `bBackgroundCellLoads:BackgroundLoad` | 1 | **1 reader**: the grid change `0x66B2140` | cells' models etc. load through `ExteriorCellLoaderTask`/`BSTaskManager<int64>` threads, results are posted for the OT |
| `bUseBackgroundPathing:PathFinding` | 1 | the process classes' virtuals (slot 257 of all four process vtables, `0x667C280`, `0x6815AA0`, ...; and `0x6812660/AF0`) and a `NiTPointerMap<Actor*,PathingData*>` | path building already runs on a background thread (`PathBuilder`) |
| `bUseMultiThreadedFaceGen`, `bLoadBackgroundFaceGen` | 1 / 0 | `0x681ED10`, `0x681FA20`, `0x684B490`, ... | FaceGen on helpers |
| `bLoadHelmetsInBackground`, `iAnimationClonePerLoop=5` | 1 / 5 | `0x681ED10`, `0x681FA20`, `0x67F2060`, `0x67F63A0` ... | `BackgroundCloneThread` animation clones, 5 per loop |
| `iNumHavokThreads:HAVOK` | **1** | world creation only (`0x6658FA2`, `0x665D39D`) | `hkMultiThreadedSimulation` is linked in [V] |
| **`bUseThreadedParticleSystem`, `bUseThreadedMorpher`, `bUseThreadedTempEffects`, `bUseThreadedBlood`** | 0 | **no reader** (only the static initialiser/destructor) | **dead**: compiled out; setting them does nothing |
| **`bUseMultiThreadedTrees`, `bUseBackgroundFileLoader`, `[OPENMP] iThreads=3`** | 1 / 0 / 3 | **no reader**; the exe imports no `vcomp` | **dead** |
| `iPostProcessMilliseconds=5` (+ `...LoadingQueuedPriority=20`) | 5 | slot not found by value reference [U] | per-frame budget for post-processing background-loaded objects |

So: the "turn on the engine's own threads" idea is mostly closed (the threaded particle/morph/temp-effect paths were
removed; UE renders those). Two real knobs remain: `iNumHavokThreads` and the BackgroundLoad budgets.
Allocator [V]: old-engine `new`/`malloc` go through `exe+0x4702CB0` -> `exe+0xE32F40` = UE's `FMemory::Malloc`
(thread-safe binned allocator), so the old engine's non-reentrant-allocator problem of 2006 does not exist here.
RNG [V]: the old engine uses the CRT `rand`/`srand` imports (IAT `exe+0x6D982C8/D8`); old-engine call sites cluster at
`0x681B570..0x681B7A0` (a wrapper set with srand) and `0x6A2xxxx-0x6A3xxxx` (script commands), plus FaceGen/other
(`0x69B58..`). UCRT keeps `rand`'s state per thread [I, UCRT behaviour], so **a `rand` call moved to another thread
changes the sequence the OT sees**: never move, never add a second consumer.
Global ExtraData lock [V, OBSE64 + 58 references]: `BaseExtraList::Lock/Unlock` = one CRITICAL_SECTION at
`exe+0x947FF00`, used by the `ExtraDataList.cpp` functions (`exe+0x661A660`.. region); the background loader can take it
too. Per-object locks: `ObjectThreadLock::LOCK_DATA` map (RTTI) [V].
Script runner [V]: `exe+0x694D290` is `ScriptRunner::Run` (string "Nested call to ScriptRunner::Run. Script '%s'
attempting to execute script '%s'."; opcode loop `exe+0x694C810`, command call `call rax` at `0x694D4B0`); wrappers
`0x694D1D0` (<- `0x662F950`) and `0x694D580` (<- `0x6630F53`, `0x66310B0`, `0x6631110`, `0x6631170`). It detects and
refuses nesting: scripts are strictly one-at-a-time on the OT.

### 1.5 The engine's own stage marker: a free profiler hook [V]

The OT writes a stage code to `exe+0x9484250` before each ProcessLists stage and each big section of the frame
(these are the crash-site breadcrumbs of the original game): in `0x65D3940` (0 at `0x65D3D69`, 0x32 at `0x65D3D7C`, 0x64
`0x65D3DAB`, 0xC8 `0x65D3DC2`, 0x12C `0x65D3DD9`, 0x190 `0x65D3DF0`) and in `0x674AC70`/`0x674A5F2` (0x6E, 0x78, 0x82,
0x8C, 0xB4, 0xBE; 0x83..0x8A, 0x1F9, 0x84). 22 writers in total. A monitor thread that reads that DWORD 1-2 kHz
(no hook, no code patch) gives a time-in-stage histogram of the OT per frame class. Missing stages (Havok step, script
runs, cell attach) do not write it; use stubs for those (section 4, C0).

### 1.6 The GameThread hand-off [V for the OT side, D + V for the GT side]

Both threads use the same manager singleton (`exe+0x4593DE0` = `[exe+0x92CE738]`; `exe+0x4593DD0` is a second manager,
`[exe+0x92CE6D0]`, used for the "type A" budgeted sessions). The GT calls it from the world-tick delegates:
`OnWorldPreActorTick` = `exe+0x4899B50` (uses `4593DE0` at `0x4899B73`, `RunSession(-1)` at `0x4899E09`) and
`OnWorldPostActorTick` = `exe+0x4899AF0` (flow runner `0x4881920`, then `4593DE0` and `call [vtbl+0x38]` = `Handler_End` at
`0x4899B29`) [V by disassembly; `npc_pacing.cpp` patterns].

Protocol (OT view confirmed above, GT view from `npc_pacing.cpp`, which is the repo's most careful description):

- OT frame g: `Begin(g)` -> game logic of 1.2, every effect on the UE side is a *command* appended to the OT's writer
  session (the "Replication" queue; create-actor command Execute `exe+0x657C8D0`, generic Execute `exe+0x4919D40`) ->
  `Handler_End` (end-of-frame command) -> **`RunSession(-2)`**: the OT now *executes the GT's reverse commands* (GT ->
  OT: UE-side results such as hits, `Arrow_hit_Reverse_Pairing` handler `exe+0x65572E0`, input) **until the GT's end
  command arrives**. So the OT cannot start frame g+1 before the GT has reached `OnWorldPostActorTick` of frame g.
- GT frame g: `OnWorldPreActorTick` -> `RunSession(-1)`: executes the OT's commands until the OT's end command of frame g.
  **If the OT's frame g is not done, the GT blocks here** ("pair" in HitchLedger; research.md: 2-6 ms per frame in
  crowds, 17-20 ms in the Brindle corral state, 13-44 ms at cell-row crossings before the fixes). The GT then ticks all
  tick groups, and in `OnWorldPostActorTick` runs the level flows and sends its end command.
- Timeline: OT(g+1) runs while the GT does the *rest* of frame g (post-tick work, Slate, draw, `FFrameEndSync::Sync`,
  frame-cap sleep) and the start of frame g+1 up to `OnWorldPreActorTick`. OT time is therefore **hidden** as long as
  `OT_frame(g+1) <= GT_post(g) + GT_pre(g+1)` (+ the frame-cap sleep if capped). Only the excess shows up as "pair". This is
  why steady frames with a 60 fps cap show no wait while a crossing frame (13-28 ms of OT work) or a crowd (~OT 8-15 ms
  against a 6-10 ms window on a fast GPU) does. **Corollary for every proposal below: only OT work above the GT's window
  matters; first measure the OT's busy time and its wait inside `RunSession(-2)` (C0).**
- The queue is FIFO and counted: `S` = `RunSession(-1)` calls, `E` = executed end commands (`npc_pacing.cpp`); any change
  that reorders commands or lets the OT run ahead of the GT's end command changes *when* UE-side results reach the
  old engine, i.e. gameplay timing. Excluded below.

## 2. Subsystem table: cost, dependencies, thread safety, parallelisability

"Cost" = what the repo measured [D] or "unmeasured" where I found nothing; "par." = can it be moved/parallelised with an
identical result.

| subsystem (where) | cost / spikes | data dependencies | thread-safety of the old code | par.? |
|---|---|---|---|---|
| **Actor update by process level** (`674AC70` -> `6749460` high, `674A5F2` middle-low, `674A1D0`, `6749B30`; Actor/Process virtuals) | "per-actor scene-graph update dominates" the OT frame in crowds [D]; ~0.4 ms of **GT** time per standing NPC is UE-side, not this. OT per-level split: unmeasured. | each actor reads/writes: its process, its 3D (NiNode tree), Havok character controller, the cell's reference lists, ExtraData lists (global CS), other actors (targets, packages, followers), the pick budget (see below), `rand`, scripts it triggers, UE commands | virtual calls into a huge object graph; global state everywhere; ExtraData under one global CS; no per-actor locks. **Not safe to run actors concurrently as-is.** | only pure sub-steps (below), after profiling |
| **Scene-graph update** (`NiNode::Update` family, vtbl `0x86443A0`; `Animation.cpp` `0x67F2830/2D30`) | dominant in the OT for crowds [D]; animation teardown at a heavy crossing was 9.4-10 ms for 8-10 NPCs [D] | child-before-parent transforms inside one skeleton; text-key/animation events fire callbacks into actor logic [I]; bone <-> Havok sync | Gamebryo-style: an actor's subtree is independent of other actors' subtrees *except* attachments (weapons, torch), Havok sync and event callbacks [I]; `AnimTeardownParallel` already proved destruction of already-dead interpolators is safe on helpers [D] | possible for **pure pose evaluation**, hard; events must stay in order |
| **Havok world step** (`bhkWorld` slot 32 `65E1030`; `hkMultiThreadedSimulation` linked; `iNumHavokThreads=1`, `fMaxTime 1/60`) | unmeasured per frame; part of the Brindle corral state [D, uncharacterised] | everything physical; the pick budget | single-threaded by setting; Havok MT is Havok's own, with pthread-style pool created at world creation [I] | the stock switch `iNumHavokThreads` exists; result equality **unverified** (C4) |
| **Picks: path / LOS / view caster / detection** (pick `65E1B60` = bhkWorld slot 34; `iMaxPicks=40`, 31 path, `iDetectionPicks=21`, `iDetectionHighNumPicks=40`; the LOS function `exe+0x65BA450` has 13 callers: combat, packages, ...) | at most 40 rays a frame by construction | a **shared per-frame budget**: a pick past the cap is dropped (`result cleared, fraction 1.0`). Which actor's pick gets dropped depends on call order. | read-only world access during the OT frame (the step is another stage) -> picking itself is thread-safe in principle [I]; the counters `941F9A8..B4` are plain globals | **no**: ordering dependency (budget) and ≤40 rays; negligible gain |
| **Script runner** (`694D290`, opcode loop `694C810`, command table call) | unmeasured per script; quests, `fQuestScriptDelayTime=5` | forms, globals, other scripts; refuses nesting | strictly single-threaded; command callbacks touch everything | **no** |
| **Pathfinding** | `bUseBackgroundPathing=1`: the heavy search is already off-thread [V/I]; path *use* (smoothing, avoidance) is on the OT | path grids, navmesh data, actors | already uses a thread boundary (`NiTPointerMap<Actor*,PathingData*>`) | already done; check thread count/priority only |
| **Cell attach / detach** (`66B2000` 0x8AF, `66ABEC0` attach 0x467, `662E360` teardown 0xAE, `6926B60/CA0` loader tasks, `65E4450..` bhkWorld counters) | crossing frame 24.9-26.2 ms stock -> 13.2-14.3 after paced eviction + anim teardown [D]; incoming row: temp data 3.5 ms + attach 3.5 ms [D]; later evict frames +3.5 ms mean, one cell 10-13 ms [D]; interior attach 1.2-2.9 s behind the loading screen [D] | master files (read), cell reference lists, ExtraData (global CS), Havok world, scene graph, UE commands (create/destroy/model release) | models: `ExteriorCellLoaderTask` threads (done); records parse and attach: OT. Teardown frees through the thread-safe UE allocator. | parts: yes (see C2/C3) |
| **Magic effects** (`ActiveEffect.cpp` `6881ECF`, `ScriptEffect`, `SummonCreatureEffect`, `VATOSpellHandlers`) | unmeasured | actors, scripts, UE handlers (`UE5Pairing`) | single thread | **no** (effect application order is gameplay: Fortify loops) |
| **Sound / music** (`66B0E80`, `Data\Music\*`) | small | audio goes through UE/Wwise via commands | n/a | not a target |
| **Save** (`TESSaveLoadGame::SaveGame exe+0x67198B0`, `SaveFormIDs 0x671C270`) | 30-36 -> 19-31 ms at 480p, 19-23 at 4K after `SaveRefIdIndex` [D]; GT waits for it | whole world state | single stream | by-form buffers possible (C6) |
| **Pairing commands to UE** | NPC creation 20-40 ms of **GT** per NPC [D] (already paced) | FIFO order | queue is a semaphore-guarded double buffer [D: `kStep`, `kWriteSwitch`] | order must stay |
| **Menu/UI/time** (1.2 items 3, 9) | small | | | not a target |

### 2.1 Determinism rules for anything proposed (gameplay identical)

1. **Order**: the OT's actor order, script order, effect order and command order are observable. A parallel stage must be
   a *map* over independent items followed by an in-order *reduce* done on the OT, or an in-order replay of recorded
   results (the `ParallelStaticBodies`/`AnimTeardownParallel` pattern: helpers do the work, the OT joins before the
   next dependent step).
2. **No shared budgets inside the map**: the pick budget, `ProcessLists+0x48` throttle accumulator, the stage marker,
   `rand` state, the ExtraData CS, the pairing writer session are shared mutable state.
3. **No new consumer of `rand`/`srand`** and no move of an existing one off the OT.
4. **Frame timing** (`fMaxTime`, `iFPS`, `iUpdateType`): the simulation is frame-rate dependent in the original; changes
   that alter OT frame *length* alter results for a given real time, but not for a given frame sequence; compare with
   fixed frame stepping (`-FixedSeed` plus the bench's pinned runs).
5. **Heap addresses may differ** (the game does not depend on them [D: AnimTeardownParallel audit]).

## 3. Known exploits and quirks to keep intact next to these systems

Only things that this study can tie to a mechanism in the binary or the shipped ini are listed as [V]/[D]; the rest is
community knowledge (UESP/Nexus) and is [U] here.

- **Bounded picks as AI blindness** [V/D]: the per-frame cap (40; path 31; `iDetectionPicks 21`) means that in big fights
  some detection/LOS rays are skipped and read as "nothing hit". `HavokPickWarningGuard` keeps that on purpose. Anything that
  changes pick order or counts changes who notices whom. Keep call order and the counters.
- **LOS/target timers** (`fLowPerfNPCTargetLOSTimer=1.0`, `fHiPerfNPCTargetLOSTimer=0.5`, `iMaxHiPerf*Count=4`) [V ini]:
  stealth timing and "NPC loses you" behaviour; do not touch.
- **Sneak attack multipliers / projectile impact order** [D]: `BowSneakAttackFix` is the only deliberate behaviour change; the
  1x/2x duality there is a fixed bug, keep it as is.
- **Frame-rate dependent physics** (`fMaxTime 0.0167`, `fMoveLimitMass`, `bAllowHavokGrabTheLiving=0`, horse
  `fHorseRunGravity`): jump height, object launching, telekinesis "throws", cliff/rock climbing with horses, items clipping
  through floors are all consequences of the Havok step and its order. Do not alter step size, ordering of bodies, or the
  bhkWorld enter/leave counters during cell attach.
- **Cell lifecycle quirks** [U community, mechanism V]: cell buffer / `uExterior Cell Buffer=36` / `bPreemptivelyUnloadCells=0`
  and the 5x5 grid decide when references reset, when containers respawn and which NPCs are "loaded"; `CellBufferPacedEvict`
  already moved the *when* by a few frames off-screen. Do not change *which* cells are loaded, the grid size, or the
  teardown order.
- **Script ordering and delay** (`fQuestScriptDelayTime=5`, `bAllowScriptedAutosave`, `bAllowConsole`): quest-stage skips,
  stage-order bugs and autosave-after-script behaviour rely on the exact OT order of script runs and on the "nested call
  is refused" rule at `0x694D305`.
- **Effect stacking** (Fortify/Restore loops, Alchemy loops [U community]): active-effect update order inside
  `ProcessLists` must not be parallelised.
- **Save/load** [D]: `SaveRefIdIndex` returns the same refIDs; any save change must keep byte-identical saves.
- **Autosave behaviour** (`AutosaveFollowsMenu` stays off by default): do not "fix" it here.

## 4. Ranked change list

Gain figures are for the specific scenes named; "needs C0" means the gain cannot be estimated until the OT profile exists.
All new fixes follow AGENTS.md "Rules": own ini key, off switch, pattern + checks, self-test, `OPF_VERSION`/CHANGELOG.

### C0. OT frame profiler and crash context (enabler, do first; no gameplay effect)

- **What**: (a) `OtStageSampler`: monitor thread reads `exe+0x9484250` at 1-2 kHz (and the OT's busy/wait state from
  C0b) and writes a per-frame-class histogram into the ledger CSV; (b) `OtSplit`: timing stubs (the `tick_split.cpp`
  approach) around the *call sites* confirmed in 1.2 - `0x65D333B` (whole frame), `0x65D3D77/0x65D3DD4` (`67406B0`),
  `0x65D3DBD` (ProcessLists::Update), `0x65D3DEB`, `0x65D407E`, `0x65D3F20`/`0x65D3F86` (grid), `0x65D4042`, `0x65D40AB`,
  `0x65D3CF6` and the pair `0x65D3625`/`0x65D363D` (End and the `RunSession(-2)` wait) -> **OT busy ms vs OT waiting for
  the GT per frame**; the stages inside `674AC70` come from the marker; (c) `OtCrashContext`: a vectored handler that, only for
  an exception on the OT, writes the marker value, RIP, module offset and the last 16 stage values to the log (this
  attributes the C01 "crash after 1-3 hours" reports to a stage; the game has no such breadcrumb in the log).
- **Expected gain**: none directly; it decides everything else. **Gameplay-identical**: read-only.
- **Risk**: very low (a read thread; call-site redirects as in `tick_split.cpp`/`hitch_ledger.cpp`).
- **Hook points**: patterns in 1.1-1.3 (all unique), plus `FindAll` of `E8` at the listed return addresses.
- **Test**: self-test `PASS` lines for each pattern; run `actors`, `npc`, `cheydinhal`, `silver-road` with
  `HitchLedger=1 HitchLedgerTickSplit=1` + the new columns; the live spin mode at one spot gives a stationary profile
  (crowd, battle at the Oblivion gate, Brindle corral). Cross-check with `-Stacks OblivionThread`.
- **Keep intact**: nothing is changed.

### C1. Trim OT-side work that is only needed at a crossing, further (cell-row change, `66B2000` family)

Already shipped: `AnimTeardownParallel`, `CellBufferPacedEvict`. Remaining in the same function [D]:

- **C1a. More teardown on helpers** (`0x662E360`: "references' 3D, NPC animation, scene graph, model release, OS frees").
  Extend the AnimTeardownParallel idea to *detached* scene-graph subtrees of the evicted cell's references: run the final
  destruction of an already-unlinked subtree on helpers (the objects have refcount 1 held by the queue; frees go through
  the thread-safe UE allocator [V]). **Gain**: crossing frames 13-14 ms -> perhaps 8-10; each evict frame (mean +3.5 ms,
  worst 10-13 ms) shrinks. **Identical because** only the thread running destructors changes and the OT joins before the
  cell teardown returns (the AnimTeardownParallel argument [D]); the 3D/model-release commands to UE keep their
  position in the queue. **Risk**: medium - the model-release/pairing commands must still be queued in OT order from the OT;
  destructors that call back (NiSourceTexture cache, KF cache) must be excluded by class check as in the anim version.
  **Hook**: `0x662E360` internals; needs an audit like `docs/npc-animation-teardown-audit.md` (cited in the source, not in this
  repo - I did not find it) before any code. **Test**: Kvatch wall flight and `silver-road` crossings, crossing-frame OT
  time (C0), compare cell/reference counts and a heap census before/after; self-test with a fake queue. **Exploits**: cell
  respawn timing, teardown order (do not skip teardown of anything).
- **C1b. Pre-parse the incoming row's "temporary data" on a worker** (3.5 ms of the crossing frame: string "Failed to
  load temporary data for cell (%i, %i) in worldspace '%s'" lives in `66B2000`). The read is a pure parse of master-file
  records into per-cell buffers; the OT would only instantiate. **Gain**: up to ~3.5 ms per crossing, i.e. a quarter of
  what is left. **Identical because** the parsed bytes are the same and are consumed at the same point; **risk**: high-ish
  - the record reader shares file handles/position state and the form table (`TESDataHandler`), and the engine's own
  background loader deliberately does *not* do this [I]; needs a thread-private reader. **Hook**: the callee of `66B2000`
  that loads temp data (not yet isolated [U]: candidates `0x6926B60`/`0x6926CA0`, `0x670CE30`). **Test**: byte-compare the
  per-cell reference arrays against the stock load for 50 cells; `cheydinhal`/`silver-road` crossings.
- **C1c. Do not** pre-attach cells early or change which cells are loaded (preloading.md item 10; changes state).

### C2. Havok worker threads - an experiment, not a patch (`iNumHavokThreads`)

- **Facts [V]**: setting default 1 in the shipped ini; read only at world creation (`0x6658FA2`, `0x665D39D`);
  `hkMultiThreadedSimulation` (broad-phase listeners) is in the binary. The pick function and the step are the
  `bhkWorld` slots 34/32 (`0x65E1B60`, `0x65E1030`).
- **Hypothesis [U]**: with 2-3 threads the Havok step in fights and in the Brindle corral state shortens. Original
  Oblivion players reported this setting as unstable [U community]; Havok's own MT simulation is documented to be
  deterministic for a given island decomposition, but bit-equality between 1 and N threads is **not** established here.
- **Plan**: a lab ini switch (`HavokThreads=N`, default 0 = engine's value) implemented as a *value write* to the setting
  slot before the first world is created (the slot is in `.data`; the DLL already patches console variables), no code
  patch. **Test**: scripted scene (fixed seed, pinned weather, frame-stepped), 120 s of `actors` battle: hash all
  `bhkRigidBody` transforms per 60 frames, compare N=1 vs N=2/3, 5 repeats each; stage time from C0. **Accept only if the hash
  stream is identical**; otherwise drop. **Risk**: crashes, nondeterminism - hence "experiment". **Exploits**: all
  physics-dependent ones in section 3.

### C3. Parallel *pure* actor sub-steps (only after C0 shows per-level cost)

- **What**: if C0 shows the high-process pass is dominated by per-actor skeleton/pose evaluation, split it into (i) a
  pure pose compute (controller/interpolator evaluation into a private buffer) on helpers over disjoint actors and (ii) the
  in-order application and all callbacks on the OT. The engine already ships the shape for this (`NiTask`,
  `NiGeomMorpherUpdateTask`, `NiPSysUpdateTask`, `BSTaskManager`) but its threaded morph/particle/temp-effect paths are
  dead in this build [V], so the infrastructure is unusable as is.
- **Gain**: needs C0; ceiling: the scene-graph share of OT time in crowds (a few ms) - this is the one item that changes
  the steady-state wait of 2-6 ms.
- **Identical because**: floating-point evaluation of one actor does not depend on the thread, provided the inputs are
  snapshotted at the same point and events (text keys, footsteps, hit frames) are dispatched afterwards in the original order.
- **Risk**: high. Event callbacks may be interleaved with evaluation in the engine [I]; attachments and Havok sync touch
  other objects; ExtraData under the global CS. **Hook**: the Actor/Process virtuals called from `0x6749460` (identify by
  OT stack sample first [U]). **Test**: hash of every actor's bone transforms and of the OT->UE command stream per frame
  (`npc`, `actors`), N frames, stock vs patched must be byte-identical; self-test with a fake actor set.
- **Exploits**: effect order, combat timing, animation-driven hit windows (power attack frames), stuck-in-animation glitches.

### C4. Parallel serialisation in `SaveGame` (autosaves/quicksaves)

- Save is 19-31 ms of OT time with the GT waiting (after `SaveRefIdIndex`). Per-form `Save` into private buffers on helpers
  then concatenation in the original order gives byte-identical saves. **Gain**: ~10-20 ms once per save; no steady
  state effect. **Risk**: medium-high (forms' save code touches ExtraData and pairing, refIDs are appended while saving - the
  existing index relies on that being sequential [D]). **Hook**: `TESSaveLoadGame::SaveGame exe+0x67198B0`, `SaveFormIDs
  exe+0x671C270`. **Test**: byte-compare saves from a fixed state, `playlog-spots`. Low priority.

### C5. Targeted fixes for known problems

- **C5a. Brindle Home corral state (S04, 17-20 ms with the GT waiting)**: measure with C0 which OT stage and how many
  picks (`941F9A8..B4`) and Havok contacts; likely a pathological loop (horses against corral geometry) that may be fixable
  by *skipping redundant identical work* only. Gain 5-10 ms in that state. Test: `brindle-corral-hold` scenario (playlog-spots).
- **C5b. `OtCrashContext`** (C0c) is the prerequisite for the 1-3 hour crash class (C01) and "animations break after many
  hours" (M03). Candidate guards so far: name lookup, trap listener, picks box, object replace - all shipped.
- **C5c. Long-session growth watch** (`OldEngineCensus`, diagnostic): once a minute log `ProcessLists` list lengths
  (`+0x80/+0xB0`), the formID table count (`TESSaveLoadGame+0xE8`, +0x14), cell buffer fill, UE allocator bytes and OT
  frame percentile; this separates "old-engine data grows" from "UE-side build-up" for M01, where the repo's 105-minute test
  saw no drift. No behaviour change.

### C6. Things looked at and rejected (so nobody repeats them)

- **Parallel LOS/pick batching**: by construction at most 40 rays per frame with a first-come budget; negligible gain, order dependency.
- **Parallel script execution**: the runner refuses nesting and every command mutates shared state.
- **Reordering or merging the pairing queue / relaxing the `RunSession(-2)` wait** (letting the OT run frame g+1 before the GT's
  end of frame g): shifts the time at which UE-side results reach the old engine; gameplay-visible. (A *measured* version of
  this is only worth discussing after C0 shows the OT idle in `RunSession(-2)` and a gameplay-neutral subset of reverse
  commands.)
- **Re-enabling the engine's threaded particle/morph/temp-effect switches**: dead code in this build [V].
- **Raising `uGridsToLoad`/cell buffer**: changes what is simulated (preloading.md).
- **Perception cost (4 ms/frame in a 40 NPC crowd)**: GT/UE-side AI perception [D], not the old engine.

### Summary ranking

| # | change | gain | gameplay-identical argument | risk |
|---|---|---|---|---|
| C0 | OT profiler + OT crash context | none (enabler) | read-only | very low |
| C1a | more teardown on helpers at crossings | 3-6 ms off 13-14 ms crossing frames | thread of destruction only, OT joins | medium |
| C2 | `iNumHavokThreads` N>1 experiment | needs C0; possibly several ms in fights | only if per-frame transform hash identical | high (instability) |
| C1b | pre-parse temp data for the incoming row | up to 3.5 ms per crossing | same bytes, same moment | medium-high |
| C3 | pure per-actor pose sub-step on helpers | needs C0; the only steady-state lever | snapshot inputs, in-order events | high |
| C4 | parallel serialisation in SaveGame | 10-20 ms per save | byte-identical saves | medium-high |

## 5. How to test

- **Offline self-test** (`src/OblivionPerfFix/tests`): maps the exe, applies the fix to the copy, checks the result. For each new
  hook add: the pattern(s) in this doc (all verified unique), RVA checks "at exe+0x..." (build-pinned), and a simulated
  OT/GT pair like the NpcCreationPacing test for anything that touches the queue.
- **Linux benchmark** (`linux/bench.py`): scenarios `actors` (IC market crowd + Legion/Daedra battle at the Bruma gate: steady
  OT load, picks), `npc` / `npcburst` (creation), `cheydinhal` (road crossings, inn door), `silver-road` (row crossings with NPCs),
  `playlog-spots` (`brindle-corral-hold`), and the live spin mode at a fixed spot (stationary profile; A/B by flipping ini keys
  live). Use `ab` rounds, trust per-thread ms more than fps (AGENTS.md).
- **Attribution**: `HitchLedger=1` (columns pre/actor/post, "pair", `gridUs` = the OT's cell-grid transition, which is the
  entry detour `exe+0x66B2000`) and `HitchLedgerTickSplit=1`; add the C0 columns. Stack timelines with `-Stacks
  GameThread,OblivionThread` and `-StackSampler fast` for the Havok step location [U] and for C3's hot virtuals.
- **Equality tests** for C1-C4: (1) command-stream hash (OT -> UE, per frame), (2) transform hash of all actors and rigid
  bodies per N frames, (3) cell/reference census before and after a crossing, (4) byte-compare of saves. All under
  `-FixedSeed`, pinned weather/hour and frame stepping; A-B-A runs.

## 6. Open items (unverified, with the cheapest way to settle each)

1. The per-frame Havok step call site (virtual call on bhkWorld slot 32). One OT stack sample in a fight, or a hardware
   write-breakpoint-free alternative: read the OT RIP from a monitor thread and match it against `0x65E1030`..`0x65E1B60`.
2. Exact meaning of the four ProcessLists flags (`+0x140..0x143`) and of `67406B0`, `6749330`, `674AE00`: print the actor-
   virtual slot names from the vtable of `Actor`/`Character` (`0x86175D8`/`0x8649520`) and match with xOBSE's x86 slot order.
3. Which stage owns the "per-actor scene-graph update" (`NiNode::Update` call chain under `0x6749460`): OT stack samples.
4. The callee of `66B2000` that loads the cell's temporary data (C1b).
5. Whether `iNumHavokThreads>1` is stable and bit-identical (C2): needs the live test.
6. `iPostProcessMilliseconds` readers (not found by value reference); `BackgroundLoaderThread` thread count/priority.
7. `docs/npc-animation-teardown-audit.md` is cited by `anim_teardown.cpp` but is not in this checkout; C1a depends on that audit.
8. Windows-vs-Proton: nothing here depends on Wine; thread names/stack sampling on Linux use the existing sampler through Wine.

## 7. Offset index (build 19115871)

| exe+ | meaning | tag |
|---|---|---|
| 0x65D2070 | OblivionThread body (init + loop) | V |
| 0x65D3271 | loop head ("Oblivion Main loop") | V |
| 0x65D3940 | per-frame body | V |
| 0x65D3625 / 0x65D363D | `Handler_End` / `RunSession(-2)` at the end of the OT frame | V |
| 0x4593DE0 / 0x4593DD0 | pairing manager getters (globals 0x92CE738 / 0x92CE6D0) | V |
| 0x8FAA708 | OT frame counter | V |
| 0x9484250 | OT stage marker | V |
| 0x674AC70 | ProcessLists::Update | V (name I) |
| 0x6749460, 0x674A5F2, 0x674A1D0, 0x6749B30 | the four level passes | V order, I names |
| 0x67406B0, 0x6749330, 0x674AE00 | other ProcessLists passes | V calls, I meaning |
| 0x674B050 | ProcessLists singleton getter | V |
| 0x66B2000 | cell-grid change | V (D) |
| 0x66ABEC0, 0x662E360 | cell attach / teardown | D/V |
| 0x6602180 | player cell/door arrival handler | V |
| 0x66B1D50 | water / time-driven update | V |
| 0x65D4570 | autosave/quicksave entry | V |
| 0x65E1030 / 0x65E1B60 | bhkWorld::Update / pick (vtable 0x861B5D0 slots 32/34) | V |
| 0x65E4410, 0x941F986, 0x941F9A8..B4 | pick counting flag and counters | V |
| 0x65BA450 | LOS/detection function (13 callers, reads `iDetectionPicks`) | V (name I) |
| 0x694D290, 0x694C810 | ScriptRunner::Run / opcode loop | V |
| 0x947FF00 | global ExtraData CRITICAL_SECTION | V (OBSE64) |
| 0x941F748 / 0x941F708 / 0x941F740 / 0x9480018 / 0x9482E80 | TES / player / Main / DataHandler / SaveLoad | V |
| 0x8FABD30 (iNumHavokThreads), 0x8FABD50 (fMaxTime), 0x8FB6500 (bUseBackgroundPathing), 0x8FB8438 (bBackgroundCellLoads) | setting value slots | V |
| 0x6D982C8 / 0x6D982D8 | IAT `rand` / `srand` | V |
