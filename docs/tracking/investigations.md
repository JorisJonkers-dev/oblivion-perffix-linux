# Investigations

Status: `open`, `running`, `done`, `parked`. Each finding goes into [LOG.md](LOG.md); write-ups are in `../research-linux/`.

| # | Question | Status | Outcome | Write-up / evidence |
|---|---|---|---|---|
| 1 | Does OblivionPerfFix help or hurt on Linux at the player's settings? | done (round 1) | Mixed. Doors improve a lot. Town spots fall 6–25%, but the chapel-square drop doesn't repeat | [runs/20261107-093709-own-off-vs-on.md](runs/20261107-093709-own-off-vs-on.md), LOG 2026-11-07 |
| 2 | Which fix group causes the town regression? | done | No regression in 3 balanced rounds (`cs-ab3`): fps +1%, 0.1% lows +19%. The episodes most likely came from FSR turning off on focus loss (ScreenPercentage 58.8 to 100), not from the fix | [runs.md](runs.md), LOG 2026-11-07 |
| 3 | How do the old engine and UE5 work together (threads, the link between them, stalls)? | done | Each NPC is a FIFO queue of commands from the old engine to UE. The known stalls are listed with numbers | [altar-architecture.md](../research-linux/altar-architecture.md) |
| 4 | Survey of existing perf mods, and their licences | done | Engine.ini packs are mostly placebo. Disabling Lumen is excluded by the owner. Streaming-pool sizing is a lead | [mods-survey.md](../research-linux/mods-survey.md) |
| 5 | Proton input latency and streaming | done | Leads: ntfs-3g IO, vkd3d low-latency (Proton-CachyOS), GPU headroom, `no_upload_hvv`. All need A/B | [proton-latency-streaming.md](../research-linux/proton-latency-streaming.md) |
| 6 | Texture pop-in | done | The upload cap of 4 and the fade's VT flush are the main causes; existing switches cover both. A loading-screen prewarm is a follow-up | [texture-streaming.md](../research-linux/texture-streaming.md) |
| 7 | Parallel and early NPC creation | done | Whole steps stay on the main thread. Leads: helper-thread physics and cloth, warming character shaders, a loading-screen drain | [npc-creation.md](../research-linux/npc-creation.md) |
| 8 | Preloading across the engine | done | Limited by the old engine's cell attach. Cheap leads: persistent shader cache, page-cache warming, destination read-ahead | [preloading.md](../research-linux/preloading.md) |
| 9 | Known engine issues and patch history | done | About 35 issues. Unaddressed: long-session slowdown, crashes after 1–3 h, the minimise crash, the corral, crowds, visual bugs | [known-engine-issues.md](../research-linux/known-engine-issues.md) |
| 10 | Fast iteration: live switches, hot reload, Linux DLL build | done | 22 ini keys fully live. A hot-reload loader is designed. The DLL builds on Linux | [fast-iteration.md](../research-linux/fast-iteration.md) |
| 11 | Spin-session mode and hotspot list | done | `bench.py spin` (85 tests) and 8 hotspots worst-first. Not yet run on the real game | `linux/README.md`, `bench/scenarios/linux-hotspots.json` |
| 12 | Old-engine hotspots that could be parallelised | done | Frame structure and the OT/GT lockstep mapped from the binary. Ranked: C0 profiler, C1a crossing teardown, C2 Havok threads, C1b row pre-parse, C3 pose on helpers | `oldengine-hotspots.md` (branch `oldengine-research2`) |
| 13 | Custom DLL pipeline: self-test under Wine, `--dll`, A/B of our DLL against the installed one | running | 268 PASS, 0 FAIL, then a crash in the sky-light test (fixture suspected). Merge with spin and the crash fix are on branch `integration` | branch `linux-dll-pipeline` |
| 14 | Do the vkd3d options (latency frames, present mode, `no_upload_hvv`, `nodxr`) help? | open | – | needs `--env` A/B runs |
| 15 | Does ntfs-3g file reading cause pop-in? (page cache warm vs cold) | open | – | needs runs on door and travel scenes |
| 16 | Does the game slow down over long sessions (memory)? | open | – | needs a 60–120 min spin session with memory sampling |
| 17 | C0: old-engine profiler and crash context (read-only diagnostics fix) | running | – | branch `oldengine-research2` (agent) |
