# Fast iteration on Linux: what is live today, hot-reload design, Linux DLL build

Status 2026-11-07. Branch `linux-build`. Nothing here launched the game or Steam, and nothing was written to the game
folder or the Steam config. Sections 1 and 2 come from reading this repo's source and ini; statements about other
projects (UE4SS, Live++, cr.h, ...) are from memory and were not re-checked online.

## 1. What can change in a running game today

### 1a. OblivionPerfFix.ini (monitor thread re-reads the file every second, `MonitorThread` in `src/core/main.cpp`)

The ini's own header: "Live" = switch on/off while the game runs; "Start-up" = installed when the game starts, and once
installed it can be switched off/on live. Consequence: a fix that was OFF at start was never installed (its pattern was
not even searched), so turning it on live does nothing ("no-op unless installed at start-up" in the monitor code).
Classes below are taken from each key's ini comment (generated, then spot-checked).

| Class | Meaning | Keys |
|---|---|---|
| Live (on and off, no install step) | value or flag read each second | `AtmosphereLightFastPath`, `AtmosphereLightCloudPath`, `RdgParallelTranslate`, `GpuSceneParallelUpload`, `GpuSceneKeepCapacity`, `NavmeshBuildNoBusyWait`, `BusyWaitFlagCheck`, `PhysicsTreeTimeSlicing`, `PhysicsFlushParallel`, `PipelinedBodyCreation`, `PacingLeanFlowDrain`, `PsoPrecompileFastBudgetMs`, `PsoPrecompileColdQueue`, `PsoPrecompileFastInGameMenus`, `FrameGenPacingTuning`, `MemoryRelief`, `SharedMemoryGpu`, `CommandAllocatorTrim`, `SeparableSkinAbove4K`, `VtStreamingUploads`, `UnfreezeBehindLoadingScreenFastTravel`, `HdrGamma22` |
| Installed at start, then live toggle (must be ON at launch to be usable at all) | detour/patch placed at start; flag flips it | `AtmosphereDirtyFilter`, `RdgSubmitBatch`, `ClothConfigCache`, `WaterCapture*` (4), `RayTracingBuildBatch`, `PhysAnimNoEmptyLock`, `RigTraceReuse`, `LumenKeepArrayCapacity`, `UploadMemoryKeep`, `RtSceneBufferKeep`, `InstanceClearReserve`, `OsPageCache`, `NavLinkFast`, `ParallelStaticBodies`, `DirtyTreeQuickInsert`, `BulkIndexInsert`, `PhysicsInternalFlushParallel`, `PhysicsPushParallel`, `PhysicsQueueShrinkOnce`, `PhysicsDestroyBatch`, `NpcFadeInNoRebuild`, `NpcCreationPacing`, `ClothRegisterLite`, `ClothBuildDefer`, `RigVmHashMemo`, `RigLogicMapCache`, `NpcBodiesOneLock`, `AnimTeardownParallel`, `CellBufferPacedEvict`, `PrepareCollisionBehindLoadingScreen`, `StreamBehindLoadingScreen`, `PsoPrecompileFast`, `DisplayModeCache`, `MenuScreenshotFilter`, `ScreenshotReadbackConvert`, `ScreenshotParallel`, `SaveBytesBulk`, `SaveThumbnailAsync`, `SaveRefIdIndex`, `FrameGenCameraInfo`, all 7 crash guards, `RestoreFsrAfterAltTab`, `MenuOpenFlashFix`, `FrozenClothStretchFix`, `VramCounterFix`, `BowSneakAttackFix`, `AutosaveFollowsMenu`, `HitchLedger*` |
| Restart to switch on, then live | | `FadeVtFlushSkip`, `UnfreezeBehindLoadingScreen`, `HdrMenuBackground`, `HdrSaveThumbnail`, `MonitorNativeFromWindows`, `FullscreenAllResolutions`, `HdrMenuRows` |
| Start-up only (even off is final; changes later are ignored or only logged) | value consumed once | `BoneUploadStores`, `ChaosMaxPayloadSize`, `NaniteInitialRootPages`, `FrameGenAsyncCompute`, `PsoCompileThreadPool`, `FrameRateLimitAtStart`, `ShaderScreenAfterDriverChange`, `HudAspectRow`, `DlssRayReconstruction`, `LogFile`, `GpuCrashReport` |

Not live, ever, by ini: the detours themselves, the byte patterns, any new code. Any change to C++ means restart.
So the ini loop is good for A/B of existing fixes (switch off/on mid-run), not for developing a new fix.

### 1b. UE4SS Lua bench mod (`mods/ue4ss/OblvBench`)

| Mechanism | How | Live? | Notes |
|---|---|---|---|
| Lua reload | write `<id> reload` to `bench-commands.txt`; `main.lua` (l.109) calls `M.Unload` then re-`loadfile`s `bench.lua` from the repo path | yes, no restart | `main.lua` itself (the bootstrap) is not reloaded; edit `bench.lua` only. `luafile <path>` runs any Lua file; `lua <code>` runs one line; `bench-autoload.lua` is run on every load |
| `cvar <name> <value>` | `Exec(name.." "..value)` via `KismetSystemLibrary:ExecuteConsoleCommand` (tries 3 call signatures), then reads back | yes | the reply is the value read back, so a refused set is visible as an unchanged value |
| `get <name>` | reads cvar | yes | |
| `exec <console cmd>` | any console string (stat, r.*, etc.) | yes | |
| `obv <cmd>` | `ObvConsole <cmd>`, the old engine's console | yes | |
| `pin <cvar> <value>` / `pin clear` | frame loop re-sets the cvar every 0.5 s if the game changed it | yes | needed e.g. because the game turns FSR off on focus loss |
| other verbs | fly, cam, tp, walk, quickload, mainmenu, menu, freeze, pause, god, cond, state, ismcensus... | yes | scene drivers |

Does this Shipping build honour cvars? Evidence in the repo only (not tested by me, the game was not started):
`cvar`/`pin` are used by the shipped scenarios and tools for `Altar.UpscalingMethod`, `Altar.FSR*`, `t.MaxFPS`,
`r.FidelityFX.FSR*`, `r.ScreenPercentage`, `Altar.GraphicsOptions.*` (frame-rate limit, VSync, RT mode),
`Altar.Audio.*Volume`. So console execution works in this Shipping build and those cvars take effect. Not
established: other `r.*` cvars. General UE rules to expect: cvars flagged `ECVF_ReadOnly`/cheat are refused (read back
shows no change); cvars latched at init (e.g. `r.Nanite.Streaming.NumInitialRootPages`, which the ini marks start-up only
because the pool is sized once) accept the write but have no effect; render-thread cvars apply from the next frame.
Always judge by the `cvar` verb's read-back plus the measured effect. The PerfFix also writes some cvar storage
directly (e.g. `r.GPUScene.ParallelUpdate`, `r.VT.MaxUploadsPerFrame.Streaming`, `r.FidelityFX.FI.AllowAsyncWorkloads`),
which bypasses the console.

## 2. Hot-reload design for native code

### 2.1 Facts about the current code that constrain the design
- One DLL is the proxy (`proxy.cpp` + `proxy_stubs.asm`: 17 `jmp [g_real_X]` stubs) AND the payload. `DllMain` calls
  `opf::Init` at `DLL_PROCESS_ATTACH` (before game code runs, so patching is race-free at that moment) and starts one
  `MonitorThread`. There is no uninstall path, no `DLL_PROCESS_DETACH`, and `DisableThreadLibraryCalls` is used.
- All code and vtable/slot patching goes through two chokepoints in `src/core/mem.cpp`: `WriteCode` (85 call sites) and
  `WritePointer` (49 call sites; atomic 8-byte store), and stub memory through `AllocNear`/`AllocNearGame` (+ a few
  direct `VirtualProtect`s, in `save_refid`, `save_thumb`, `save_bytes`, `autosave_menu`, `npc_fade_in`,
  `framegen_pacing`, `frame_cap_start`). So an undo journal is a small change in one file.
- `WriteCode` is a plain `memcpy` into live code: not atomic for patches wider than 8 bytes and aligned. Fine at
  start-up, a race on a running game.
- Helper threads: monitor, `static_bodies` (workers + pipeline), `physics_flush`, `physics_push`, `bulk_insert`,
  `destroy_batch`, `anim_teardown`, `screenshot_parallel`, `save_thumb`, `submit_batch` (age thread), `framegen_async`.
  None has a stop flag. Game threads also sit inside our detours and stubs at arbitrary times.
- `thread_local` state in `save_*`, `view_rename_guard`, `nav_link_fast` (static CRT `/MT`; each DLL copy has its own CRT).
- Several fixes capture function pointers/offsets found by pattern scan; a reload would rescan (the scan is the
  "start-up cost"; `Init` logs it).

### 2.2 Architecture: loader + payload with a hook journal
1. **Loader** (the permanent `version.dll`, ~100 lines, rarely rebuilt, contains only the 17 proxy stubs and the loader
   logic). On `DLL_PROCESS_ATTACH` it resolves the real version.dll (existing `ResolveVersionProxy`), then starts the
   payload. Same idea as Ultimate ASI Loader (a proxy dll that `LoadLibrary`s plug-ins), but one payload and with reload.
2. **Payload** (`OblivionPerfFix.payload.dll`): the current code minus `DllMain`/proxy. Exports
   `opf_install(const LoaderApi*, const void* carried_state)` and `opf_uninstall(void** state_out)`. `LoaderApi` gives
   the journaled primitives (below), the log, the ini path.
3. **Load from a copy**: loader copies `payload.dll` to `payload.<n>.dll` (n = generation) in a temp dir next to it and
   `LoadLibraryExW`s that copy; the build output is never locked or mapped (Wine maps files; replacing a mapped file in
   place is unsafe, and on Windows it fails). Old copies deleted when unloaded, or at next start.
4. **Trigger**: loader's watcher thread polls (1 Hz, or `ReadDirectoryChangesW` which Wine supports) the payload's
   mtime/size and a command file `reload.txt` (`reload`, `unreload`, `status`). Debounce until the file is stable for
   ~500 ms (the linker is still writing). Also a Lua verb (`exec` cannot do it; add a `luafile`/file write) so the
   benchmark can reload between runs.
5. **Hook journal** (the key piece, makes uninstall generic instead of per-fix): the loader exports `JWriteCode`,
   `JWritePointer`, `JAlloc` which `mem.cpp` forwards to. Each records `{address, original bytes, installed bytes,
   owner generation}`. Uninstall = walk the journal newest-first and restore, but only if the current bytes still equal
   the installed bytes (someone else, e.g. an overlay, hooked on top: then leave that hook in place and mark the entry
   "pinned", which forces the leak path in 2.3). Stub memory from `JAlloc` is freed only after the quiesce step.
6. **Quiesce, then restore** (MinHook's approach, `MH_DisableHook` with `Freeze`): enumerate threads
   (`CreateToolhelp32Snapshot`), `SuspendThread` all but the caller, and for each check `RIP` (from `GetThreadContext`)
   against ranges: payload image, journaled stub pages. If any thread is inside, resume it, sleep 1 ms, retry (cap ~50
   tries; MinHook instead moves RIP; here a retry is simpler because stubs call back into game code and a RIP fix-up
   cannot be exact). Return addresses on stacks are not checked by MinHook either: a thread *below* us in a call (e.g.
   game thread -> our detour -> game function -> ... ) will return into freed code. That is the residual danger, hence 2.3.
   Also stop helper threads cooperatively first: each fix gets an `Stop()` that sets a flag and joins (needs adding;
   they currently loop forever).
7. **Leak-or-free policy**: default = **do not `FreeLibrary` the old payload**. Restore the journal so the game stops
   calling it, then leave the old image mapped (1.2 MB per generation, bounded by a cap of e.g. 20 per session; the
   status line shows the count). Any thread still returning into old code, any pointer the game stored, any trampoline,
   stays valid. `FreeLibrary` only when a dev flag `UnloadOld=1` is set AND the quiesce check found no thread with a
   return address in the old ranges (walk each suspended thread's stack with `RtlVirtualUnwind` or conservatively scan
   the stack for values within the ranges). This is cr.h's "safe mode" idea inverted: it can crash safely-ish via SEH
   there; here a crash kills the game, so leaking is the safe default.
8. **State carried across** (cr.h `CR_STATE`/static section idea, UE4SS keeps mod state in the host): anything that must
   survive (stats counters, the one-shot "already logged" flags, original function pointers found by scan) lives in a
   small `CarriedState` blob owned by the loader, versioned (`size`, `abi`). A payload whose `abi` differs refuses
   to carry and starts clean. First iteration: carry nothing, rescan everything (a pattern scan of the exe is
   ~hundreds of ms; the log prints it).
9. **Ini and monitor thread**: monitor thread moves to the loader (stable), calling `opf_tick(cfg)`; or the payload
   owns it and `uninstall` joins it. The first is simpler: the payload is then pure callbacks, no thread of its own.
10. **Failure handling**: wrap `opf_install` in SEH; on failure run `opf_uninstall`/journal restore and keep the
    previous generation's hooks (install new payload only after the old one is fully restored; a failed new install
    reverts to "no hooks", log it, and a second file change retries). Log every step with the generation number.

### 2.3 Which existing fixes are safe to uninstall live
Rule of thumb from how they patch (counts from `grep`; per-fix details in each file header):
- **Safe after quiesce (single atomic pointer swap, restore = one `WritePointer`)**: the vtable/import-slot fixes:
  `fade_hook` (two vtable slots, "safe at any time"), `display_modes` (import slot), `framegen_pacing` (a slot),
  `name_lookup_guard`, `trap_guard`, `havok_pick_warning`, `task_wait_guard`, parts of `nav_link_fast`,
  `parallel_translate`, `submit_batch`, `water_info`, `rt_build_batch`, `cloth_defer`/`cloth_register`,
  `menu_open_flash`, `stream_behind_loading`, `fade_vt_flush`, `atmosphere` (which use `WritePointer` somewhere).
  Residual risk: a thread currently inside the detour.
- **Safe only with all threads suspended (inline code patches via `WriteCode`, `jmp` to a stub + trampoline)**: most
  of the 85 sites: `bone_upload` (masked stores rewritten in place, multi-byte), `save_bytes`/`save_thumb`/
  `save_refid` (their own `VirtualProtect`ed trampolines), `npc_fade_in`, `autosave_menu`, `frame_cap_start` (rewrites
  a function's first 8 bytes), call-site redirects to `AllocNear` stubs (`cell_buffer` clamp stub, `physics/*`,
  `anim_teardown`, `rig_setup`, `rig_trace_reuse`...). Restore is an exact byte copy from the journal; the
  stub pages must stay until no thread is inside (leak policy).
- **Unsafe / not worth reloading (restart instead)**:
  - Start-up only values consumed once: `NaniteInitialRootPages`, `ChaosMaxPayloadSize` (changes tree/pool sizing the
    engine then treats as fixed), `PsoCompileThreadPool` (pool resized once), `FrameRateLimitAtStart`,
    `ShaderScreenAfterDriverChange`, `HudAspectRow`, `FrameGenAsyncCompute`, `DlssRayReconstruction`. Uninstalling
    would not undo what the engine already did with the value.
  - Fixes that change allocated data layout or keep the game's memory differently: `LumenKeepArrayCapacity`,
    `UploadMemoryKeep`, `RtSceneBufferKeep`, `InstanceClearReserve`, `OsPageCache` (it hands out/caches pages that the
    engine frees later through the old path), `allocator_trim`, `cell_buffer`, `static_bodies` (worker threads +
    pipelined body creation hold state across frames), `physics_flush`/`destroy_batch`/`bulk_insert` (own queues and
    helper threads holding game objects). Their state is not restorable by a byte restore; uninstall must drain.
  - Fixes holding objects the game owns after the fix ran: `save_refid` (index tied to the save in progress),
    `rig_setup`/`anim_teardown` (captured FName/skeleton caches), `nav_link_fast` (thread_local cache, valid per call).
  - `thread_local` data: a leaked generation is fine; a freed one leaves dangling TLS slots in threads (static CRT
    + implicit TLS in a dynamically loaded DLL works since Vista, but destructors of thread-locals do not run at
    unload for live threads).
  - Anything that installed a Vectored/Unhandled handler or registers callbacks inside the engine (none found by grep
    of `AddVectoredExceptionHandler`/`SetUnhandledExceptionFilter`; the `__try` blocks are local).
- **Practical consequence**: aim hot reload at one fix at a time during development. Add a per-fix `Uninstall()`
  (restore from journal + stop helpers) in the order: vtable fixes first, then in-place code patches, never the
  start-up-only/data-layout group; for those, `reload` reports "needs restart" and the dev workflow is a fresh launch.
  Intermediate step that needs no unload at all: a dev-only `Experimental` fix slot in the loader that is the *only*
  thing reloaded (the 80 stable fixes stay in the permanent payload). That gives 90 % of the iteration speed at a
  fraction of the risk.

### 2.4 Prior art and what to take from each
- **UE4SS C++ mods**: mods are DLLs implementing `start_mod()`/`uninstall_mod()`, loaded with `LoadLibrary` and the
  GUI has a reload-all that calls uninstall, `FreeLibrary`, loads again (also restarts Lua mods). It has no hook journal:
  the mod must undo its own hooks; mods that do not are why it is flaky. Take: the entry-pair contract.
- **cr.h (fungos/cr)**: host loads a copy of the DLL, calls one `cr_main(ctx, op)` with ops LOAD/STEP/UNLOAD/CLOSE,
  keeps guest static state in a section that is saved and restored across reloads, optionally SEH-protected
  (`CR_SAFE`), tracks a version number per reload. Take: copy-before-load, generation number, state section, op codes.
- **Live++**: patches the live process function-by-function from a recompile (no unload at all, hot-patch old
  function entries to new code, keeps old code mapped). Commercial, Windows-only, needs the program built with
  hot-patch-friendly options and its agent; not usable here (we do not rebuild the game), but its "keep old code
  mapped, redirect entries" is the model for our leak policy.
- **Ultimate ASI Loader**: proxy dll named after a system dll (version/winmm/dinput8...) that loads `*.asi` plug-ins; no
  unload. Take: the loader role; the way it forwards exports.
- **MinHook**: `MH_DisableHook` restores the original prologue bytes and, with its "freeze" step, suspends all other
  threads and moves any whose `RIP` lies in the patched bytes or the trampoline. `MH_Uninitialize` frees the
  trampoline buffer. Does not examine return addresses (documented limitation). Take: freeze + restore order.
- **Wine/Proton notes**: replacing the file while mapped is the main hazard (hence copy-load); `LoadLibraryEx` on a
  new unique name works; `SuspendThread`/`GetThreadContext` are supported; the proxy needs the DLL override
  `version=n,b`, already handled by `linux/README.md`.

### 2.5 Implementation plan (order, each step shippable)
1. `mem.cpp` journal (`WriteCode`/`WritePointer`/`AllocNear` record entries) with `UndoAll()`; no behaviour change.
2. Split the build in two outputs: `version.dll` (proxy + loader, ~10 KB) and `payload.dll` (everything else, no
   `DllMain` proxy). The same sources, two link lines (`linux/build-dll.sh` can do both).
3. Loader: copy-load, `opf_install/opf_uninstall`, file watcher, `reload.txt`.
4. Thread quiesce + `UndoAll()` + leak policy. First test fix: a vtable one (`fade_hook`).
5. Per-fix `Stop()` for helper-thread fixes, then widen.
Expected loop: edit -> `linux/build-dll.sh` (23 s full, incremental much less if object reuse is added) -> loader
notices -> swap in ~1 s -> measure with the bench mod's `reload`/`cvar` verbs.

## 3. Linux build of the DLL (WORKS)

Result: `src/OblivionPerfFix` cross-compiles to a valid x86_64 PE DLL on this NixOS box with **no source changes**.
Toolchain: clang-cl 21.1.8 + lld-link + `llvm-ml` (all from nixpkgs `llvmPackages`) against the MSVC CRT and Windows
SDK 10.0.26100 fetched by `xwin` 0.9.0 (nixpkgs has `xwin`; it downloads Microsoft's packages and needs
`--accept-license`; ~800 MB into `~/.cache/oblivion-perffix/xwin`, once).

```sh
linux/build-dll.sh [outdir]       # default outdir: build-linux/ ; produces OblivionPerfFix.dll (1.2 MB)
OPF_DEBUG=1 linux/build-dll.sh    # /Od /MTd
```
Measured: full build 23 s wall on this machine (4.5 min CPU, all cores via `xargs -P`). First run adds the xwin fetch
(about 20 s on this connection). The script re-execs itself inside `nix shell` with
`nixpkgs#xwin nixpkgs#llvmPackages.clang-unwrapped nixpkgs#llvmPackages.lld nixpkgs#llvmPackages.bintools`.

Equivalent manual steps (what the script does):
```sh
xwin --accept-license --cache-dir C --arch x86_64 --variant desktop splat --output X --include-debug-libs
llvm-ml -m64 -nologo -c -Fo obj/proxy_stubs.obj src/core/proxy_stubs.asm        # MASM macro file assembles as is
clang-cl --target=x86_64-pc-windows-msvc /std:c++20 /O2 /MT /EHsc /DUNICODE /D_UNICODE -Wno-everything \
  -imsvc X/crt/include -imsvc X/sdk/include/{ucrt,um,shared} /Isrc/core -c src/<area>/<f>.cpp /Fo obj/<f>.obj  # 81 files
lld-link /DLL /machine:x64 /DEF:OblivionPerfFix.def /OUT:OblivionPerfFix.dll /OPT:REF /OPT:ICF \
  /LIBPATH:X/crt/lib/x86_64 /LIBPATH:X/sdk/lib/um/x86_64 /LIBPATH:X/sdk/lib/ucrt/x86_64 obj/*.obj kernel32.lib
```
Checked with `llvm-readobj`: the 17 version.dll exports (via the `.def`, targets `Proxy_*` from the asm) plus
`OBSEPlugin_Load` / `OBSEPlugin_Version`; the only import is KERNEL32.dll (same as the MSVC build's `kernel32.lib`).
The `__try/__except` blocks (13 files) compile fine under clang-cl (it supports MSVC SEH on x86_64); MinGW would have
needed `__try` work and a MASM-to-GAS port, which is why clang-cl was chosen.

Differences from `build.ps1` (not bugs, but be aware):
- no `/W4 /WX` (clang's warnings differ; `-Wno-everything` used so a clean build is not blocked), no `/GL /LTCG`
  (clang-cl would need `-flto`; costs some inlining across files), no `/Zi` PDB, no version resource (`.rc`);
  those are cosmetic or size/speed only.
- Codegen is clang's, not MSVC's. Not tested: whether the fixes behave identically and the byte-level
  self-test (`tests/selftest.cpp`) passes: the self-test needs the game exe (read only) and a Windows process. It
  could be built the same way and run under Wine against a copy of the exe, not attempted here. Before trusting this
  DLL for a benchmark, compare it against the MSVC build in the bench (`log` should match, same fixes "applied").
- Nothing was deployed. `build-linux/` is git-ignored.

## 4. Open risks
- Clang vs MSVC behaviour: struct layout/ABI is MSVC-compatible in clang-cl, but any code relying on MSVC-specific
  optimisation behaviour, inline detours calling conventions, or `/GL` could differ. Run the self-test under Wine.
- Hot reload: the leak policy bounds but does not remove the risk of a thread returning into restored hooks; the
  quiesce retry can starve if the game spins in a detour (e.g. `submit_batch`); suspending threads of a game in the
  middle of a D3D12 submit can stall or deadlock if a suspended thread holds a lock another needs (keep the suspend
  window < 10 ms and never suspend while resolving something that takes loader locks; do not call `LoadLibrary`/log/
  allocate while others are suspended).
- Anti-cheat/overlay hooks stacked on the same address (Steam overlay, RTSS, OBS capture): the "current bytes ==
  installed bytes" check must refuse, otherwise restore would remove their hook.
- Proton/Wine: `ReadDirectoryChangesW` and file replace semantics under the prefix; polling is the fallback.
- Start-up-only fixes remain restart-bound; the cvar route (section 1b) is the fastest loop for tuning values, and
  reading a cvar back is the only reliable check that a Shipping build honoured it.
- Each reload re-runs the exe pattern scan; if a fix scans for a pattern inside bytes the previous generation already
  patched, it will not match (the loader must restore before the new generation scans: the order in 2.2 step 10 covers
  this, but a fix that caches "found" addresses in carried state must verify, not trust).
