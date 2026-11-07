# Texture pop-in in Oblivion Remastered (UE 5.3, vkd3d-proton, NTFS via ntfs-3g)

Date: 2026-11-07. Method: local docs/sources read, web research; **nothing was benchmarked or launched**. Tags: **[LOCAL]** repo evidence, **[WEB]** cited, **[SPEC]** speculation/inference. The cvar defaults quoted from the cvar wiki are UE **5.4.4** engine defaults; this game (5.3) overrides several through its own scalability settings, so read the live values first (step 0 below).

## 1. The pipeline and where latency comes from

### 1.1 Three streaming systems, three budgets

| System | What uses it | Governing knobs | Writable live? |
|---|---|---|---|
| Classic texture streamer (mip streaming) | characters, props, UI, most non-VT materials | `r.Streaming.PoolSize` (-1 = engine default), `LimitPoolSizeToVRAM` (0), `FramesForFullUpdate` (5), `MaxTempMemoryAllowed` (50 MB), `MaxNumTexturesToStreamPerFrame` (0 = no limit), `AmortizeCPUToGPUCopy` (0 = off), `MipBias`, `Boost` | yes (plain cvars) |
| Streaming Virtual Textures (SVT) | open-world walls, roofs, stairs (per the repo: "walls, roofs and stairs of the open world") | `r.VT.MaxUploadsPerFrame` (engine 8), `r.VT.MaxUploadsPerFrame.Streaming` (engine 0 = share the general cap; **this game: 4**), `r.VT.MaxTilesProducedPerFrame` (engine 30), `r.VT.PoolSizeScale` | `.Streaming` is overwritten by the game's scalability; needs the DLL's monitor-thread write |
| Nanite geometry streaming | all Nanite meshes | `r.Nanite.Streaming.StreamingPoolSize` (512 MB), `NumInitialRootPages`, `MaxPageInstallsPerFrame` (128) | **no: ECVF_ReadOnly** (start-up only, i.e. Engine.ini before the engine reads it) |

Sources: classic cvars https://dev.epicgames.com/documentation/en-us/unreal-engine/texture-streaming-configuration-in-unreal-engine ; defaults https://indxzero.github.io/ue544cvarwiki/articles/r.streaming.poolsize , .../r.streaming.framesforfullupdate (5, "number of frames to visit all textures"), .../r.streaming.maxtempmemoryallowed (50), .../r.streaming.maxnumtexturestostreamperframe (0, only effective with AmortizeCPUToGPUCopy), .../r.streaming.amortizecputogpucopy (0), .../r.streaming.limitpoolsizetovram (0); VT https://indxzero.github.io/ue544cvarwiki/articles/r.vt.maxuploadsperframe (8), .../r.vt.maxuploadsperframe.streaming (0 = share the general cap; help text says use a high limit "when streaming pages is slow, so I/O requests aren't throttled"; flags RenderThreadSafe|Scalability), .../r.vt.maxtilesproducedperframe (30); Nanite https://indxzero.github.io/ue544cvarwiki/articles/r.nanite.streaming.streamingpoolsize (512, ReadOnly), .../r.nanite.streaming.maxpageinstallsperframe (128, ReadOnly).

### 1.2 Evidence for each latency source

1. **SVT upload cap (strongest evidence).** [LOCAL] research.md `VtStreamingUploads`: the game's scalability sets `.Streaming` to 4 after all ini layers; Engine.ini [SystemSettings]/[ConsoleVariables]/DeviceProfiles all left it at 4. At the Imperial City Waterfront lighthouse exit, stair walls ~40 m away stay blotchy until ~8-10 s; with 64 set from the console they are final as the fade completes (~2.4 s), 1-px detail at 0.060 by ~4.5 s (2+2 runs). Not Lumen (RT reflection/indirect off: same). Hundreds of pages are wanted at once vs 4 per frame (at 60 fps = 240 pages/s). [WEB, secondary] A Nexus mod readme reportedly sets `r.VT.MaxUploadsPerFrame(.Streaming)=64` via DeviceProfiles to fix VT pop-in (read through a search summary only; the readme fetch returned 404/403) https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs . Other UE5 games: a RoboCop Rogue City user reports MaxUploadsPerFrame=64 "had a dramatic effect" https://steamcommunity.com/app/1681430/discussions/0/3940146862825267627/?ctp=5 (anecdote). Counter-evidence: a UE forum cinematic thread saw no change when doubling VT cvars because residency was near pool limit https://forums.unrealengine.com/t/community-tutorial-cinematic-prestreaming-virtual-textures/2232467 : so also check VT pool size.
2. **The fade-in `r.VT.Flush`.** [LOCAL] research.md `FadeVtFlushSkip`: 1.5 s after fade-to-game, the game runs `r.VT.Flush` on every transition (11 in a test run); everything loaded behind the loading screen is thrown away and must be re-streamed at the upload cap ("a flash of blur right as you arrive", ~2 s at 64 uploads/frame). This is probably the single largest cause of "blurry after doors/fast travel" for VT surfaces. Skipping it changes only the transient (settled image identical), not final quality.
3. **Pool collapsed during loading screen.** [LOCAL] `StreamBehindLoadingScreen`: loading-start sets `r.Streaming.PoolSize` to 1 MB (drops every streamed mip), the fade handler restores it and calls stream-all, which blocks 99-710 ms; with the shipped fix on, that wait is 0.3-1.9 ms and the loading screen is shorter. Already shipped (ini line 342, `StreamBehindLoadingScreen=1`); it restores the pool and runs the streamer update before the fade. Confirm it is on in the Linux ini.
4. **Pool size / eviction is probably NOT the limit on a 24 GB card.** [LOCAL] research.md "tried" table: `r.Streaming.PoolSize 6000` had "no effect on travel hitches". Game uses ~9-10 GB at 4K, briefly ~13 GB after a door. [WEB] Community pool-size tables target 3-8 GB cards (Nexus pack: 3072/4096/5120 for 4/5/6 GB; Steam user raising to 50% of VRAM "didn't do much") https://steamcommunity.com/app/2623190/discussions/0/604154837573086222 , https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs (search-summary level). [SPEC] Eviction pressure is low; pool tweaks are mainly insurance.
5. **Nanite.** [LOCAL] `NaniteInitialRootPages=3072` already removes a root-page growth step (pool starts at 608 MB). Nanite pool (512 MB) and page installs per frame (128) are ReadOnly [WEB above]; they can only be changed via Engine.ini at start-up. [SPEC] Geometry pop-in (not texture) is governed by these; test `r.Nanite.Streaming.StreamingPoolSize=1024` only if geometry (not texture) pop remains. Costs 512 MB VRAM.
6. **Streamer CPU cadence (classic path).** `FramesForFullUpdate` 5 = a full wanted-mip recompute every 5 frames (~83 ms at 60 fps; at 30 fps ~170 ms): small but additive latency. Lower = faster reaction, more game/render CPU. [SPEC] The game is CPU-limited in towns ([LOCAL] benchmark docs), so keep an eye on cost.
7. **Upload amortization / temp memory.** Engine defaults are "no limit" and 50 MB temp. [SPEC] 50 MB temp can starve the streamer during bursts (large 2K/4K mips; many textures simultaneously); raising costs only transient RAM. The game's actual values are unknown; read them.
8. **IO.** UE5 reads via IoStore (.utoc/.ucas, compressed) on the zen/IoDispatcher path; pages/mips are small, scattered reads. On Proton the game files sit on ntfs-3g (FUSE): each read is a kernel-to-userspace round trip, single-threaded by default in the FUSE daemon unless configured. [WEB] No published ntfs-3g vs ntfs3 vs ext4 random-read benchmark exists; only vendor sequential numbers (ext4 3.4 GB/s vs ntfs-3g 2.8 GB/s) https://lore.kernel.org/lkml/alpine.DEB.2.20.2109030047330.23375@tuxera.com/ and anecdotes (ntfs3 ~4x faster than ntfs-3g on one Gentoo setup) https://forums.gentoo.org/viewtopic.php?p=8668803 . [SPEC] For VT pop-in, IO latency matters most in the first burst after a door when the page cache is cold. Existing notes: docs/research-linux/proton-latency-streaming.md rec. 1. [LOCAL] The DLL already has an OS-page-cache module (`memory/os_page_cache.cpp`) but that is about the allocator's VirtualAlloc churn, not file preloading.
9. **No DirectStorage.** [SPEC / not verified] I found no evidence the game uses DirectStorage; UE 5.3 ships it as an optional plugin only. Treat as absent; do not spend time on it.
10. **GPU-side decode/crash-risk items** are not the pop-in cause here.

## 2. Ranked testable changes

Image quality: **identical when settled** unless stated; all of these only change *how fast* the same data arrives. Costs are estimates [SPEC] unless measured.

Step 0 (free, do first): read the live values with the in-game mod's `cvar` verb for: `r.Streaming.PoolSize`, `r.Streaming.LimitPoolSizeToVRAM`, `r.Streaming.FramesForFullUpdate`, `r.Streaming.MaxTempMemoryAllowed`, `r.Streaming.MaxNumTexturesToStreamPerFrame`, `r.Streaming.AmortizeCPUToGPUCopy`, `r.Streaming.MipBias`, `r.Streaming.Boost`, `r.VT.MaxUploadsPerFrame`, `r.VT.MaxUploadsPerFrame.Streaming`, `r.VT.MaxTilesProducedPerFrame`, `r.VT.PoolSizeScale`, `r.Nanite.Streaming.*`, `s.AsyncLoadingThreadEnabled`, `s.IoDispatcher*` (record them in the report so the list below is checked against reality). Also `r.Streaming.PoolSize` shows the pool; `Stat Streaming` is not available in shipping, so use the mod.

| # | Change | Expected effect | Cost | Quality identical? |
|---|---|---|---|---|
| 1 | `VtStreamingUploads=64` (ini, DLL live write of `r.VT.MaxUploadsPerFrame.Streaming`); try 32 and 128. Also set `r.VT.MaxUploadsPerFrame=64` live (cvar verb) in the same arm, because streaming VTs fall back to it in some paths | final detail ~2.4 s instead of 8-10 s at the Waterfront exit [LOCAL measurement] | upload CPU/GPU copy work in streaming frames; contributor measured on flights (research.md); watch 1% lows | Settled: yes. Transient: sharper sooner |
| 2 | `FadeVtFlushSkip=1` (DLL) on top of #1 | removes the post-fade re-blur (~2 s at 64/frame) | none known; textures loaded behind the loading screen stay | Yes (settled); the transient is better |
| 3 | `r.VT.MaxTilesProducedPerFrame` 30 -> 120 (live cvar verb; confirm the game's actual value first) | if the produce cap, not the upload cap, binds after #1, finishes sooner; "page production" is the GPU work that converts requests into physical tiles | more GPU time in burst frames | Yes |
| 4 | `r.Streaming.FramesForFullUpdate=2` (from 5) | faster reaction of mip requests after teleports | some game-thread CPU per frame (town is CPU-bound): measure `cheydinhal-show` | Yes |
| 5 | `r.Streaming.MaxTempMemoryAllowed=512` (from 50) | removes starving when many mips are in flight | up to ~0.5 GB RAM transient | Yes |
| 6 | `r.Streaming.FullyLoadUsedTextures=1` (docs: streams used textures to max resolution and keeps them for app lifetime) | eliminates mip pop on revisit | VRAM growth over the session; with 24 GB acceptable but risk: pool exhaustion then eviction thrash. Test with pool 12000 + `LimitPoolSizeToVRAM=1` | Yes, (max mips always: may look *sharper* than the budgeted streamer on distant props) |
| 7 | `r.Streaming.PoolSize=` 12000 and `r.Streaming.LimitPoolSizeToVRAM=1` | only if Step 0 shows the game's pool is < 6-8 GB or the streamer reports over-budget; otherwise no effect [LOCAL: PoolSize 6000 had no effect on travel] | VRAM | Yes, or sharper |
| 8 | `r.Streaming.Boost=1.0` stays; do **not** lower `MipBias` below the game's setting (changes quality) | n/a | n/a | n/a |
| 9 | `UnfreezeBehindLoadingScreen=N` (already in DLL, trade-off) | world settles behind the loading screen | ~1 s unseen simulation | Yes |
| 10 | Nanite: `r.Nanite.Streaming.StreamingPoolSize=1024` (Engine.ini, start-up only) | geometry pop only | +512 MB VRAM | Yes |

Combinations: A = {1,2}; B = A + {3,4,5}; C = B + {6,7}. Run each as a fresh launch (start-up-only keys) and alternate (ABBA).

### How to measure

- Scene: `waterfront` mini-scenario from the `showcase` flight (docs/benchmark.md "Mini-scenarios": `py -3 tools/slice_flight.py ... --spot waterfront:23.9:26.5`), and the lighthouse door exit that research.md used. Add `cheydinhal` `inn-door` and fast-travel scenes for the classic streamer and the loading path (`transitions` scenario).
- Primary metric (needs a capture, the Linux MangoHud log has no image content): full-resolution screenshots at 0.5/1/2/4/8/12 s after the fade-in starts, with the 1-px detail metric from research.md (0.052 -> 0.060 style: high-frequency energy of a fixed crop of the stair walls) plus contrast. If the Windows tooling for this is not ported to `bench.py`, take screenshots through the mod and compute the metric offline. Secondary: frame-time hitch ms and 1%/0.1% low in the window after arrival (`bench.py` already computes), per scene.
- Commands (Linux runner): `python3 linux/bench.py ab --scenario <s> --scenes <ids> --rounds 2 --a stock --b on --label vt` with `--fix-ini VtStreamingUploads=64 --fix-ini FadeVtFlushSkip=1` on side B (see `bench.py --help`; my read of the README: `--fix-ini KEY=VAL` and `--env` exist). For non-DLL cvars use the live mode / scenario cvars via the mod's `cvar` verb after the warm-up, before the scene, then read back.
- Controls: same weather/hour pinned (the runner pins by default), cold vs warm page cache identical between arms (see section 3), 2+ rounds, report medians, treat <5% as noise (as the runner does).
- Check VRAM: MangoHud `vram` for #6/#7; a rise above ~20 GB is the stop condition.

### Code changes in the DLL's style

- Generalize `streaming/vt_streaming_uploads.cpp`: the same name-find + monitor write could cover `r.VT.MaxTilesProducedPerFrame` and `r.VT.MaxUploadsPerFrame` (both are scalability-owned in other titles; check whether the game rewrites them: the wiki says `.Streaming` has the Scalability flag, `MaxTilesProduced` may not). Prefer first checking through the cvar verb whether a plain live write sticks; only add DLL code for variables that revert.
- [SPEC] A "burst governor": raise the cap only for N seconds after each transition (fade-to-game) and drop back to 4-8 afterwards, to keep the steady-state cost of #1 at zero. The DLL already has fade hooks (`loading/fade_hook.cpp`, `stream_behind_loading.cpp`).
- [SPEC] A pre-warm: during `StreamBehindLoadingScreen`'s idle loading frames, set the upload cap to 64+ and `FramesForFullUpdate=1` (behind the loading screen, cost is invisible), restore at fade-to-game; combined with `FadeVtFlushSkip`, the new view would arrive already sharp. This is the most promising "no quality change" option: the work moves behind the black screen.

## 3. Linux IO experiment plan

Hypothesis [SPEC]: cold page cache + FUSE round trips make the first burst of reads after a door slow, lengthening VT/mip arrival independently of upload caps.

Instrumentation first: `perf trace`/`strace -f -T -e trace=read,pread64` is heavy under Wine; prefer `bpftrace` on `vfs_read` for the wine process latency histogram, or `iostat -x 1` / `/proc/<pid>/io`; and `cat /proc/pressure/io`. Also log page cache residency of the container before/after: `vmtouch -v <file>`.

Experiments (each: same save, same scenes, cold cache via `echo 3 | sudo tee /proc/sys/vm/drop_caches` before each run, then once warm):
1. **Baseline microbench:** `fio --name=r4k --filename=<big .ucas on NTFS mount> --rw=randread --bs=16k --iodepth=1 --ioengine=psync --runtime=30 --time_based` (and `--bs=64k --iodepth=16 --ioengine=libaio`; drop `--direct=1` on FUSE). Repeat on the ext4/ntfs3 copy. Compare latency percentiles, not throughput (the published numbers are sequential only [WEB above]).
2. **Page-cache preload:** `vmtouch -t <Content/Paks/*.ucas *.utoc *.pak>` (or `cat file > /dev/null`) before launch; `vmtouch -l` + `-d` to lock. Size check first: it needs the files to fit in the 32 GB RAM alongside the game (~9-10 GB RAM use is unknown here [SPEC]); preload only the biggest-hit containers (the pakchunk holding the world textures) if the whole set does not fit. Compare cold/preloaded in the waterfront and fast-travel scenes. Expected: removes IO from the hot path; if pop-in time is unchanged, IO is not the bottleneck and the problem is cap/CPU, which settles the question cheaply. This needs no change to the game and is the best first IO test. (vmtouch: https://github.com/hoytech/vmtouch, [WEB not fetched here, standard tool].)
3. **Readahead:** `blockdev --setra 4096 /dev/<nvme-partition>` (and `/sys/class/bdi/<id>/read_ahead_kb`) to see if it shifts the cold-run result. Small expected effect for random reads [SPEC].
4. **ntfs-3g mount options:** remount with `-o noatime,big_writes,kernel_cache,big_writes,max_read=...` Note: `big_writes` affects writes only (irrelevant for reads) and is a no-op on current FUSE; `noatime` avoids metadata writes on each read (relevant), `kernel_cache` lets the kernel cache pages across opens (relevant), `ro` for a read-only library. Test `ro,noatime,kernel_cache` first. Option names are from ntfs-3g man pages: not fetched in this session [UNVERIFIED].
5. **ntfs3 kernel driver:** `mount -t ntfs3 -o ro,noatime,uid=...,gid=...,windows_names ...` (needs the dirty bit cleared; Windows fast-startup disabled). [WEB] Anecdotal 4x gains https://forums.gentoo.org/viewtopic.php?p=8668803 ; Valve notes NTFS is unsupported for Proton https://github.com/ValveSoftware/Proton/wiki/Using-a-NTFS-disk-with-Linux-and-Windows . Keep compatdata on ext4.
6. **Copy to ext4/XFS/btrfs** (the real fix): rsync the game dir to a Linux filesystem library. If pop-in timing improves versus (2), then the filesystem matters beyond cold-cache effects (metadata and IoStore open overhead).

Measurement: the same screenshots/1-px detail timeline as section 2 plus `bpftrace` read-latency p50/p99 for the first 10 s after fade-in; and the loading screen duration (the runner already logs transition times).

Decision rule: if (2) preload shows no improvement, drop IO from the suspect list and put effort into section 2 changes.

## 4. Top 5

1. `VtStreamingUploads=64` (+ `r.VT.MaxUploadsPerFrame=64` live): measured 8-10 s -> ~2.4 s settle at the Waterfront; settled image identical.
2. `FadeVtFlushSkip=1`: removes the self-inflicted VT flush 1.5 s into the fade-in (mechanism documented in research.md); picture only better during the transient.
3. Streaming prewarm behind the loading screen (code, [SPEC], extension of `StreamBehindLoadingScreen`): raise the VT upload cap and streamer cadence while the loading screen idles, restore at fade-to-game. Eliminates the burst cost in view.
4. Page-cache preload of the .ucas/.utoc/.pak with vmtouch, then A/B against cold: cheapest test of whether FUSE/ntfs-3g IO matters; follow with ntfs3 or an ext4 copy.
5. Classic streamer CPU/memory headroom: `r.Streaming.MaxTempMemoryAllowed=512`, `r.Streaming.FramesForFullUpdate=2`, `r.VT.MaxTilesProducedPerFrame=120` (read live values first), measured for CPU cost in `cheydinhal-show`.

Not recommended: pool-size increases as a standalone fix ([LOCAL]: no effect at 6000), `MipBias` changes (quality), Nanite pool (ReadOnly, geometry only).

## 5. Gaps

- The Nexus readme and HotHardware article ("Simple Trick Stops Game Stutters in Oblivion Remastered") could not be fetched (403/404); their claims are from search snippets only.
- Defaults are UE 5.4.4 wiki values; the game's actual runtime values are unknown until Step 0.
- No independent measurement of any Engine.ini pop-in tweak in this game was found beyond the repo's own measurements and contributor PR #34.
- No ntfs-3g small-read latency benchmark was found.
