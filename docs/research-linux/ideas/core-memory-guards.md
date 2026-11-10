# Core, memory, guards: review for Linux/Proton overhead, Wine behaviour, known issues, input latency

Date: 2026-11-07. Scope: `src/OblivionPerfFix/src/core/` (main.cpp, mem.cpp, config.cpp, log.cpp), `memory/`, `guards/`,
`menus/`, `framegen/`, `diagnostics/`, plus `render/submit_batch.cpp` where it touches latency. Read-only review: no game run,
no builds, no benchmark. Every number below comes from reading the source unless it is marked as the user's log or as
speculation. **[SPECULATION]** = my inference, not measured. **[UNVERIFIED]** = a name or behaviour I could not confirm in the
repo or the game.

## What the DLL does per second and at start-up (facts from the code)

- **Monitor thread** (`core/main.cpp`, `MonitorThread`, line ~126): `Sleep(1000)`, then `LoadConfig(iniPath)` (config.cpp: 114
  `GetPrivateProfileIntW` calls, each one opens, reads and parses the whole ini), then `UpdateMemory` (memory_monitor.cpp:971),
  then about 150 setter calls. Almost all setters are an atomic `exchange` plus a log line on change. The two setters that write
  code (`SetNavmeshBuildNoBusyWait`, `SetBusyWaitFlagCheck`) return early when the value has not changed, so the per-second cost is
  the ini work, the `UpdateMemory` sample, and the atomics.
- **UpdateMemory** per second: `GlobalMemoryStatusEx`, `PageFileGrowRoom()` (`NtQuerySystemInformation(144)` plus
  `GetDiskFreeSpaceExW` per page file), `K32GetProcessMemoryInfo`, and two DXGI `QueryVideoMemoryInfo` calls. Cheap, but it is
  the only per-second call that crosses into the Windows/Wine layers beyond file I/O.
- **OpenAdapter** (memory_monitor.cpp:~200): retried every 10 s until the game's GPU is found; each try creates a DXGI factory and
  enumerates adapters. Not a problem once found; cheap to bound.
- **Start-up**: `FindAllFast` (mem.cpp) scans the whole `.text` once per pattern, with the rarest-byte SSE2 filter. You reported
  474 searches over ~20 GB in about 1 s (`[startup]` line, main.cpp ~790; that line is from your log, not from the repo).
  Start-up cost matters on the version.dll route because the game waits for it (it runs before game code).
- **Log** (log.cpp): `fflush` after every line, mutex per line, 8 MB cap per session. Stats lines every 60 s
  (`statsIntervalSeconds`). The log is not a leak source: it stops at the cap.
- **Hot-path hooks** that matter for latency: `submit_batch.cpp` (RdgSubmitBatch=32 lists per submit, RdgSubmitMaxAgeUs=1000
  us, held-back command lists flushed by `AgeThread`, which uses a high-resolution waitable timer and falls back to `Sleep(1)`),
  `framegen_guard.cpp` (spins with `Sleep(1)` when all 8 frame-gen command lists are busy), `task_wait_guard.cpp` (spins with
  `_mm_pause` for 64 iterations, then `SwitchToThread`), `atmosphere.cpp`, `save_*`, `collision_prepare.cpp` and similar
  (`QueryPerformanceCounter` around calls, cheap).
- **Diagnostics off by default**: `hitch_ledger.cpp` and `tick_split.cpp` (`HitchLedgerTickSplit` redirects every tickable's
  `Tick` through a timing stub). Keep both off for every A/B, or the A/B measures the probe.
- **No present or latency hook exists.** `grep` for `Present`, `SetMaximumFrameLatency`, `FrameLatency`, `Reflex` finds only
  `frame_cap_start.cpp`, which reads the Reflex flag to decide whether to leave the frame limit to the game. The DLL never
  touches the swap chain queue depth.

## (a) Overhead the DLL adds itself

**A1. One ini read per second is 114 file opens (cheap on Windows, not free under Wine).** `LoadConfig` runs every tick. Under
Wine, `CreateFile` is a server-side operation, so each `GetPrivateProfileIntW` costs a round trip to wineserver plus the parse.
Estimated 114 opens per second, all on the monitor thread, so this does not touch the game thread.
- Fix: read the file once per tick with `GetPrivateProfileSectionW` per section, or read the file into memory and parse once; or
  compare `GetFileAttributesExW` (last-write time) first and reuse the last `Config` when unchanged. The third option costs one
  stat per second and keeps the live-edit behaviour.
- Why safe: only the reading changes; the Set* calls and their order stay the same. Live switching still works (a changed
  timestamp reloads the whole file).
- Gain: small. [SPECULATION] under 1% of one core on Proton, invisible to the frame time. Mostly removes wineserver traffic.
- Risk: a race with an editor that writes the file in pieces. Mitigate by reloading on the next tick when the size or time
  changes again.
- Measure: `strace -f -c -p <game pid>` (or Wine's `WINEDEBUG=+server` count) for one minute with the DLL on and off; expect the
  server-request count to drop by roughly 100 per second. Frame time should be unchanged. Confirm with `--diag`.

**A2. Start-up scan: ~1 s per launch, all of it memory-bandwidth bound.** Every `FindAll` reads the whole section, so 474 scans
read ~20 GB. Three options, ranked by safety:
1. Cache the hit offsets per pattern, keyed on `TimeDateStamp` + `SizeOfImage` + the DLL version. On a launch with the same exe,
   check each cached hit with `MatchesAt` (microseconds) and fall back to the full scan on any mismatch. Same result by
   construction, since only identical binaries use the cache. Saves nearly all of the ~1 s after the first launch.
   Risk: a cache file next to the DLL in the game folder. Write it once, keep it small, and skip it if the directory is read-only.
2. Run the independent scans on helpers before `Init` continues. The searches are read-only over `.text`, so they can run
   together. Gain bounded by memory bandwidth: [SPECULATION] 2 to 3x on a desktop, less on a handheld.
3. Shrink each scan: scan a 64 KB window around known neighbours. Riskier; the patterns are not all anchored.
- Gain: about 0.7 to 0.9 s of game start-up on the version.dll route after the first launch (option 1). Does not touch play.
- Risk: option 1 keeps a stale-result risk only if the key is wrong; include the pattern text in the key.
- Measure: the `[startup]` line (user's log already has it); compare first and second launch with the cache on.

**A3. Thread priorities and affinity.** `SetThreadPriority(HIGHEST)` in `submit_batch.cpp:247` and `destroy_batch.cpp:450` and
`physics_flush.cpp:215`. Under Wine these map to Linux nice values only when Wine can raise priorities (root, or rtkit). Without
that, they are no-ops. [SPECULATION] So on a stock Proton install these calls do nothing, which is harmless. No
`SetThreadAffinityMask` exists in src/ (checked with grep). Nothing to change; say so in the notes so nobody adds one blindly.

**A4. Wait loops that sleep for a full millisecond.** `framegen_guard.cpp:128` (`Sleep(1)` until a frame-gen command list is
free) and `submit_batch.cpp:271-273` (fallback `Sleep(1)` when the high-resolution waitable timer cannot be created). On Linux,
`Sleep(1)` is a `nanosleep` of at least 1 ms plus scheduler slack. [UNVERIFIED] whether `CreateWaitableTimerExW` with
`CREATE_WAITABLE_TIMER_HIGH_RESOLUTION` succeeds under the Proton versions you use. The current code does not log which path it
takes.
- Fix: log once which branch `AgeThread` took (timer or fallback); for the frame-gen wait, wait on the fence event instead of
  polling.
- Gain: only when the path is hit. Rare in practice (the log counts these waits).

**A5. OsPageCache under Wine is on, and that is probably the right default but unmeasured.** `OsPageCache` (default 1, 64 MB,
5 s trim, `common.h:217-220`) keeps freed blocks so the game's ~1,350 `VirtualAlloc`/`VirtualFree` pairs per second become
mostly cache hits (`os_page_cache.cpp` header). `SharedMemoryGpu` turns it off only on a UMA GPU on Windows itself, so on Proton
it stays on. Wine's virtual memory calls go through ntdll's `virtual.c` under one process-wide lock and are not as cheap as on
Windows, so the cache may matter more under Proton than the comments say.
- Measure: run the same scene with `OsPageCache=0` and `=1` live (the ini switch is live, so one game session can do it). The
  `[oscache]` stats line at 60 s gives the hit counts; MangoHud frame-time spikes give the effect. `bench.py ab` does the
  alternation. [SPECULATION] the gain shows up as fewer hitches at door loads, not as average fps.

## (b) Linux/Proton-specific behaviour

**B1. The Wine gate turns off the automatic memory policy on Linux handhelds (biggest Linux-specific gap).**
`memory_monitor.cpp:53-63` and `SharedMemoryGpuWanted`/`SharedMemoryGpuPossible` (around line 359): under Wine
(`wine_get_version` in ntdll), the device is never asked (`QueryGpuMemoryKind` is skipped at line ~273, so the kind stays Pending) and the automatic mode
(`SharedMemoryGpu=2`) never applies. The comment gives the reason: Linux "handles running out of RAM their own way" (OOM killer).
Consequence for a Steam Deck (16 GB, UMA APU, Proton): the game keeps the upload pools, Lumen and GPU-scene keeps and OsPageCache
at full size, which is the exact pattern that froze the 16 GB ROG Ally on Windows (memory_monitor.cpp comment, "A player's ROG Ally
... froze hard with 1.2.1 defaults"). The only protection left on Proton is `MemoryRelief` (RAM or commit free under 1 GB).
- Fix: keep the Wine exclusion for the rule itself, but allow the device query under Wine (vkd3d-proton implements
  `CheckFeatureSupport(D3D12_FEATURE_ARCHITECTURE1)`; a second device on the game's adapter is a singleton per adapter). Or, on
  Linux, use `MemAvailable` from `GlobalMemoryStatusEx` (Wine's value comes from `/proc/meminfo`) with a higher relief threshold
  (1 GB is late for a 16 GB UMA device where a stall, not an OOM kill, is the failure).
- Why safe: changes memory keeping only, never the image. The same keeps already have a stock path (`ApplySharedGpu`).
- Gain: unknown. [SPECULATION] it prevents the Deck-class stall the Windows comment describes; it may also cost some of the
  streaming gain the keeps give. Needs a device to decide.
- Risk: the reason for the Wine exclusion (device query under Wine was never tested) is real. Test on a 16 GB UMA device first.
- Measure: `[mem]` lines (`RAM free min`, `commit free min`, `relief` tags), MangoHud `ram`/`vram` columns during a 1 h run
  around Imperial City and a door load; count stalls longer than 100 ms in the frame log.

**B2. Proton's `VirtualAlloc` path** (see A5). `os_page_cache.cpp:343,454`, `cloth_config.cpp:477-485`, `focus_restore.cpp:292-300`:
the allocations sit on Wine's virtual-memory path. Only OsPageCache is hot; the others run once per event. No action beyond A5.

**B3. Wine-aware code that is already correct.** `SharedMemoryGpuHostFacts` detects Wine with `wine_get_version`; `DescribeThread`
uses `SetThreadDescription` (Wine maps it to the pthread name, visible in `top -H` and perf); `WaitOnAddress` is looked up in
`kernelbase.dll`, which Wine provides, and maps to futex or ntsync, so the spin-then-wait in `mem.cpp` `SpinPhase` is sound. No
change needed.

**B4. Thread-priority calls** (see A3): no-ops under stock Proton. If a real priority effect is wanted, use Linux directly
(`sched_setscheduler` / rtkit) from a helper. Not recommended: it changes scheduling for the whole process and is not needed to
fix a measured problem.

## (c) Known engine issues not yet addressed

**C1. Long-session slowdown and crashes after 1 to 3 h (M01, C01): hook for evidence first.** The DLL logs `[mem]` game private
bytes (max per 60 s) already. What is missing is object-count and crash-site data.
- Add a slope logger on the monitor thread: every 60 s, write `GUObjectArray` `NumElements` (the object array's live count;
  object_replace_guard.cpp already uses the GUObjectArray base and its lock offset `+0x30`; the `NumElements` offset must be read
  from the game's layout, [UNVERIFIED]) to a CSV, the way `hitch_ledger` writes its CSV. Read-only. Pair it with the private bytes
  and the VRAM sample.
- Extend `GpuCrashHandler` (memory_monitor.cpp:948) to log first-chance access violations (0xC0000005) with `exe+0x...` and the
  faulting address, rate-limited (for example 20 lines). It already runs as a vectored handler, which works under Wine. Today it
  only handles the GPU device-removed code; the C01 crashes give no exe offset at all.
- Why safe: diagnostics only; no image or timing change. Keep it behind a switch, default off, as the other diagnostics are.
- Gain: none directly. It decides whether M01 is a leak (object count climbs with time) or not, and gives C01 a site to guard.
- Measure: a 2 h soak on Linux with MangoHud logging and the CSV; compare slope with and without OsPageCache. Also the
  `[oscache]` counters.

**C2. Crash when minimised during start-up (C02, issue #39).** `D3D12Util.cpp:903` `CopyCommandList->Close` returns `E_INVALIDARG`
after device removal, within a second of restore. Nothing in the DLL touches the copy queue at that point, except the
`CommandAllocatorTrim` (copy queue allocator pool, `allocator_trim.cpp`) and `UploadMemoryKeep`. [SPECULATION] the trimmer could
free the allocator the initial-data upload is still using if the window restore arrives while a copy is in flight.
- Concrete hook: log `IsIconic` and `WM_SIZE` transitions from the monitor thread, plus `CommandAllocatorTrim` events, into the
  same log, so the next repro shows the order. Diagnostics only.
- A test: with `CommandAllocatorTrim=0` (ini, takes a restart) and minimise-then-restore at the menu; if the crash stops, the
  allocator trim is the trigger. [SPECULATION] This needs a repro, which the issue already has (reproduces every time on one PC).

**C3. Menu brightness flash (V01).** `MenuOpenFlashFix` (menus/menu_open_flash.cpp) already disables occlusion queries for the
player-menu open frame. The remaining flash is eye adaptation carrying over and the preview box's own exposure (known-engine-issues
V01). [SPECULATION] a second switch in the same window (`RequestCapture` exec thunk), freezing auto-exposure for the frames the
blurred background is captured, would address it. [UNVERIFIED] the exact console-variable names for exposure lock; check the
game's console-variable table before writing the hook. The existing `MenuOpenFlashFix` shows the pattern: set the cvar in the thunk,
restore it on the same game-thread frame.
- Image: this changes what the flash looks like, so it belongs with the "game bug fix" class (the ini label), not the "same image"
  class.

**C4. Cheydinhal banners LOD flicker (V03).** Blueprint `SetForcedLOD` runs about 20 times a second and flips the drawn LOD in a
feedback loop. The honest fix changes the image, so it is a game-bug-fix item, not a speed-up. A dedup guard (skip a call that
repeats the last value within the same frame) is the least invasive form. [SPECULATION] whether that stops the loop depends on
whether the loop is within one frame or across frames; check the call's frame index first. Risk: the banner may then keep a LOD
the artist did not intend. Low priority.

## (d) Input latency: what the DLL could do without changing the image

**D1. Submit hold-back, the only latency-relevant knob the DLL owns.** `RdgSubmitBatch=32` and `RdgSubmitMaxAgeUs=1000`
(common.h:80-81). A command list can be held up to 1 ms before submission, only while parallel translate is on. [SPECULATION]
the cost is at most 1 ms of input latency per held batch, and the gain is GPU submit overhead. The image is unchanged (same lists,
same order).
- Measure: `RdgSubmitMaxAgeUs` 1000 vs 250 vs 0 (0 = age flush off, batch only by count) with `bench.py spin` (settings flipped in
  ABBA order on one spot). Frame time from MangoHud and the GPU-busy column. The latency effect is too small for MangoHud alone; use
  an external click-to-photon probe if you need it.

**D2. The frame-rate cap as a queue-depth control.** `frame_cap_start.cpp` already sets `Altar.GraphicsOptions.FrameRateLimit`
through the game's own setter. On Proton, proton-latency-streaming.md recommends capping just below sustained fps so the GPU does
not stay at 99% (and the queue does not fill). The DLL could set a cap automatically, but that changes the frame timing the
player sees, so it stays a player choice; the DLL should only document it.

**D3. UE's one-frame thread lag** [UNVERIFIED cvar name `r.OneFrameThreadLag`, check the game's console-variable table]. Setting
it to 0 would let the game thread stop one frame earlier relative to the render thread. [SPECULATION] that reduces input latency by
about one frame and costs CPU parallelism. This uses the existing console-variable pattern (`VtStreamingUploads`,
`FrameGenAsyncCompute`), so it is cheap to add as a switch, default off. Image: unchanged, timing only.
- Measure: `bench.py ab` with the switch flipped, MangoHud frame times (look at CPU frame vs GPU frame columns), and
  click-to-photon if the latency claim matters.

**D4. Frame-gen command-list wait** (A4): only when all 8 slots are busy; a fence-event wait would cut the 1 ms polling. Rare.

## Ranked top 5

1. **C1 - Long-session evidence (object-count slope logger + access-violation logging).** What: 60 s CSV of GUObjectArray count
   and private bytes; log exe offsets for access violations in `GpuCrashHandler`. Where: `memory_monitor.cpp` (UpdateMemory,
   GpuCrashHandler), `object_replace_guard.cpp` for the array layout. Why safe: diagnostics only, default off. Gain: none
   direct; it decides M01 and gives C01 a site. Risk: low. Measure: 2 h soak on Linux with MangoHud. Highest value per hour, and
   it unblocks the two open crash/leak items.
2. **B1 - Linux-aware memory policy for UMA handhelds (Steam Deck / APUs on Proton).** What: let the device query (or
   `MemAvailable`) decide under Wine too, with a higher relief threshold than 1 GB. Where: `memory_monitor.cpp:53-63, 258-263,
   359-382`. Why safe: changes keeps, not the image. Gain: [SPECULATION] avoids the Deck-class stall; cost unknown. Risk: the
   Wine exclusion was a deliberate choice; test first on a 16 GB UMA device. Measure: `[mem]` lines, MangoHud ram/vram, stall
   count over a 1 h run.
3. **A2 - Start-up scan cache keyed on exe identity (then, optionally, parallel scans).** What: store hit offsets per pattern,
   validate with `MatchesAt`, fall back to the scan on any miss. Where: `core/mem.cpp` (FindAll), `core/main.cpp` (cache file
   next to the DLL). Why safe: same result for the same exe; the self-test already pins the build. Gain: ~0.7 to 0.9 s per launch
   after the first. Risk: a file in the game folder; skip if read-only. Measure: `[startup]` line, first vs second launch.
4. **A5 / B2 - OsPageCache under Proton: measure before changing anything.** What: A/B the cache live (`OsPageCache=0/1`) and
   read the `[oscache]` hit counts. Where: `memory/os_page_cache.cpp`, ini `OsPageCache`. Why safe: already shipped as a
   default; this is measurement only. Gain: [SPECULATION] fewer door-load hitches under Wine's slower virtual memory. Risk: none
   beyond the existing relief rules. Measure: `bench.py ab` with the switch flipped in one session, MangoHud frame spikes at
   doors.
5. **A1 - One ini read per tick (or a timestamp check first).** What: `GetFileAttributesExW` once per second; reparse only when
   the file changed. Where: `core/config.cpp` (LoadConfig), `core/main.cpp` (MonitorThread). Why safe: the Set* calls and their
   order are unchanged; live switching still works. Gain: small; removes ~110 wineserver round trips per second on Proton
   [SPECULATION on the cost]. Risk: a partial write by an editor; reparse on the next tick if the size or time changes again.
   Measure: `strace -f -c` or `WINEDEBUG=+server` request count; frame time should not change.

Lower-ranked but noted: C2 (minimise-at-start crash: log IsIconic/WM_SIZE and allocator trims, repro with
`CommandAllocatorTrim=0`); C3 (menu flash: exposure lock during capture, needs the cvar name); D1 (`RdgSubmitMaxAgeUs` A/B, at
most 1 ms per batch); D3 (`r.OneFrameThreadLag`, name unverified); C4 (banner LOD: image-changing, game-bug-fix class).

## Not worth doing

- Thread affinity or priority tuning inside the DLL: no measured problem; under stock Proton the priority calls do nothing (A3).
- Log rotation changes: the 8 MB cap and two-session rotation are fine; they do not leak.
- Turning on the diagnostics (`HitchLedger`, `HitchLedgerTickSplit`) as a default: they add per-tick timing work; keep them off
  for every benchmark A/B.
