# Spec: Linux performance program for Oblivion Remastered

Status: ready-for-agent (not yet published to an issue tracker: the fork has issues disabled and no triage setup).
Scope: every improvement found feasible in `docs/research-linux/` and the first Linux benchmark runs (2026-11-07).
Each numbered workstream below can be picked up on its own.

## Problem Statement

I play Oblivion Remastered on Linux (Steam + Proton, NixOS, GNOME Wayland, RX 7900 XTX, 2560x1440 at 144 Hz,
soon 165 Hz). The game files live on an NTFS drive shared with Windows. I installed OblivionPerfFix to make the game
smoother, but in busy towns it made things worse. In the Cheydinhal chapel square the frame rate dropped from about 94 to 70 fps,
with 18 hitches where there were none. Beyond that, objects and characters appear slowly and in bursts, textures stay blurry for
seconds after a door, and mouse look feels delayed. I can't tell which of the many fixes and settings help or hurt on my machine.
Every experiment costs a full game restart, which makes improving things slow. I want the game to look the same
(lighting stays on, no quality cuts) but run faster and appear complete sooner.

## Solution

A repeatable, Linux-native measurement and iteration loop, and fixes chosen and proven with it:

- A benchmark that runs fixed, save-free scenes by itself under Proton, and compares variants. It works on whole
  scenarios, and on a single worst spot with a slowly spinning camera where settings flip live in one game session.
- The regression at busy town spots found, and then switched off or fixed, so the fix is never slower than stock on Linux.
- Texture detail that arrives promptly after doors and travel. Existing, off-by-default fixes are measured and turned on
  if they help.
- Characters that appear complete sooner. Character shaders are warmed before they are needed, the thread-safe parts of
  character setup move to helper threads, and leftover creation work is finished while the loading screen is still up.
- Proven answers on Linux-specific factors: file reading from the NTFS drive, and the latency and present-mode options in
  vkd3d-proton.
- The fix itself built on Linux and reloadable in a running game, so native changes iterate as fast as ini changes.

Every change keeps the project's Rules: identical image and gameplay, fail-safe switches, and evidence from A/B runs.

## User Stories

1. As a Linux player, I want to install OblivionPerfFix with one documented launch option, so that the fix loads under Proton.
2. As a Linux player, I want to know whether the fix makes my game faster or slower at my own settings, so that I only keep it if it helps.
3. As a Linux player, I want the fix never to be slower than the stock game in busy towns, so that installing it is safe.
4. As a Linux player, I want textures to sharpen within a couple of seconds after a door or fast travel, so that the world doesn't look blurry while I move.
5. As a Linux player, I want characters to appear complete instead of popping in part by part, so that towns feel alive and not assembled in front of me.
6. As a Linux player, I want fewer hitches when I travel along roads, so that riding and running feel smooth.
7. As a Linux player, I want mouse look to respond quickly, so that combat and exploring feel direct.
8. As a Linux player, I want my lighting and image quality unchanged, so that the game keeps its look.
9. As a Linux player, I want the game to handle a monitor at any refresh rate (144 Hz now, 165 Hz later) with no fixed caps, so that I get every frame my hardware can give.
10. As a Linux player, I want my settings, saves and the game folder put back exactly after every benchmark, so that measuring never damages my game.
11. As a Linux player, I want to watch a benchmark with a frame-time graph on screen, so that I can see stutter myself.
12. As a tuner, I want to start the game once and flip fix switches and engine settings live at one spot, so that I can compare variants in minutes, not hours.
13. As a tuner, I want the camera to spin at a fixed rate at a hotspot, so that every lap exercises streaming and GPU load the same way.
14. As a tuner, I want frame rate per view direction, so that I can see which direction of a spot is the worst.
15. As a tuner, I want variants run in balanced A-B-B-A order, so that warm-up and drift don't bias the comparison.
16. As a tuner, I want a list of hotspots ordered worst-first with the reason each is bad, so that I improve the places that matter most first.
17. As a tuner, I want the runner to refuse to flip start-up-only switches live, so that I don't measure a change that never took effect.
18. As a tuner, I want to add environment variables (vkd3d options) to one launch, so that I can test Proton-level options without editing Steam.
19. As a tuner, I want to set fix switches for one run only, so that I can bisect which fix causes a regression.
20. As a tuner, I want the fix's engine diagnostics (hitch ledger, tick split) captured and ranked per run, so that I know where slow frames spend their time.
21. As a tuner, I want each run's verdict as one line (ok / partial / failed), so that chains of runs can be scripted and checked.
22. As a tuner, I want reports with medians, spread, and a marker for differences under the noise level, so that I don't chase noise.
23. As a developer, I want to build the fix DLL on Linux, so that I can change native code without a Windows machine.
24. As a developer, I want to reload a changed fix DLL in the running game, so that native iteration needs no restart.
25. As a developer, I want each fix that is unsafe to unload live clearly marked, so that hot reload never leaves a broken hook.
26. As a developer, I want the offline self-test to run against the installed exe after a Linux build, so that every patch is checked before it touches the game.
27. As a developer, I want measured evidence of whether character materials wait on shader compilation before they are drawn, so that shader warming is only built if it pays.
28. As a developer, I want the thread-safe parts of character setup (physics shapes, cloth preparation) to run on helper threads, with results added in the game's order, so that the main thread does less per character.
29. As a developer, I want leftover character creation finished during the loading screen's idle time, capped and off by default, so that the fade-in shows a complete scene.
30. As a developer, I want texture streaming kept running behind the loading screen at a higher upload rate, and put back at fade-in, so that detail is resident when the screen fades in.
31. As a Linux player, I want to know whether reading game files through the NTFS (FUSE) driver causes pop-in, so that I can decide whether to move the game to a native Linux filesystem.
32. As a Linux player, I want a measured recommendation on vkd3d latency options and present mode, so that mouse look feels as fast as possible without new stutter.
33. As a maintainer, I want every borrowed idea credited to its author and licence, so that the project stays honest and redistributable.
34. As a maintainer, I want Linux-specific changes kept apart from upstream's Windows tooling, so that upstream changes merge cleanly.
35. As a maintainer, I want my findings written up so they can be reported upstream, so that Windows players benefit too.

## Implementation Decisions

Workstreams in priority order. Each one ends with an A/B measurement through the benchmark.

1. **Regression bisect at busy towns (first).**
   - Stock vs fix on the Cheydinhal chapel square showed −25% fps, 18 hitches, and GPU load falling from 97% to 88% with the fix on.
   - Bisect fix groups with per-run overrides (render threading, NPC pacing, physics, memory keeping), then single keys.
   - Proton-specific suspects: render-graph parallel translate and its frame fence, submit batching, parallel GPU-scene upload.
   - Outcome: either a Linux default that turns the culprit off (detected from the fix's own Wine check, as `SharedMemoryGpu` does), or a corrected fix in the fork.

2. **Live spin-session mode in the Linux runner.**
   - One game session, one spot, the camera turning at a fixed rate.
   - Variants are either ini switches (the fix re-reads its ini every second) or engine console variables set through the in-game bench mod.
   - Balanced order; per-variant medians and per-45° sector fps.
   - Start-up-only switches are detected from the shipped ini's comments and refused.
   - Environment-level options stay restart-only.

3. **Hotspot scenario.**
   - A Linux hotspot scenario made of static spots copied from upstream scenarios.
   - Ordered worst-first by the repo's own evidence: Cheydinhal squares, the Imperial City market crowd, Peryite's shrine, Blackwood, the Silver Road climb, Roxey Inn at night, the Fort Doublecross pond.

4. **Texture detail after transitions.**
   - First, read the live values of the streaming and virtual-texture console variables.
   - Then measure the existing off-by-default switches on door and fast-travel scenes: virtual-texture streaming uploads at 64, and skipping the fade's virtual-texture flush.
   - Turn each on only if the settled image is identical and the fps cost is within noise.
   - Follow-up feature: raise uploads and the streamer's update rate only while the loading screen is idle, and restore them at fade-to-game. This extends the existing stream-behind-loading-screen fix.

5. **Character appearance.**
   - Measure first: a spawn-to-first-drawn time per character, and whether proxy creation waits on shader (PSO) precache.
   - If it does: warm character-material PSOs when cells attach. Same timing order, compile only.
   - Physics shape and cloth preparation on helper threads during the appearance and equipment steps, using the pattern of the existing parallel static bodies fix. Scene adds stay in the game's order on the main thread.
   - A capped loading-screen drain of pending creation work, off by default because it lengthens loading.
   - Rejected under the Rules:
     - character pooling;
     - running whole creation steps off the main thread;
     - a larger loaded-cell radius. That changes gameplay, so at most an off-by-default trade-off.

6. **Linux IO.**
   - Compare pre-reading the game's pak and `.ucas`/`.utoc` files into the page cache against a dropped cache, on door and travel scenes.
   - If IO matters, compare the kernel NTFS driver (blocked by its symlink bug on this volume for Proton prefixes, but fine for the read-only game files) and an ext4 copy.

7. **Latency and present path.**
   - Restart-level A/B of vkd3d options through the runner's per-launch environment: latency frames, present mode, `no_upload_hvv`, `nodxr`.
   - A frame cap just below the sustained fps.
   - Proton's Wayland driver where it actually loads.
   - Input latency has no direct measurement in the benchmark. Use the frame-time spread and present-to-present pacing as proxies, and state that limit.

8. **Native iteration.**
   - Cross-compile the fix DLL on Linux (clang-cl or mingw route, whichever builds the MASM stubs and SEH).
   - A thin permanent `version.dll` loader that loads a copied payload DLL and can unload and reload it on a trigger.
   - Each fix declares whether it can be uninstalled live. The ones that patch code at start-up only are reloaded only at game restart.

Interfaces that stay stable:
- the fix's ini keys (new keys get safe defaults);
- the in-game bench mod's command-file protocol and verbs;
- the runner's CLI (`run`, `ab`, `report`, `spin`, `status`, `restore`), its result folder layout (`result.json`, `report.md`) and the `BENCH-RESULT` line.

Linux work lives in its own directories and branches of the fork, so upstream merges stay clean. Borrowed ideas are credited in the docs, with licence notes from `docs/research-linux/mods-survey.md`.

## Testing Decisions

- **What makes a good test:** it checks external behaviour through the highest seam, not internals.
  - For the runner: given a scenario and options, the commands sent to the game, the windows measured, the report numbers, and that every touched file is restored byte-for-byte.
  - For the fix: given the game exe, every patch is found, checked and applied, and anything unexpected switches the fix off cleanly.
- **Seam 1, the Linux runner end-to-end against a fake game.** A fake mod answers the command file, there is a generated MangoHud log, and Steam and process lookup are patched. Prior art: the existing whole-run test with byte-for-byte restore checks, plus the protocol, MangoHud, ini, env and scenario tests. The spin mode, hotspots and overrides are tested here.
- **Seam 2, the fix's offline self-test.** It maps the installed exe, applies every fix to that copy, and reports PASS/FAIL per check. New or changed native fixes, the Linux build, and the hot-reload loader's install/uninstall pairs are tested here.
- **Acceptance, the live A/B in the real game** through the runner. Balanced order, at least 2 rounds; differences under 5% are treated as noise. Image comparisons are needed for anything that could touch the picture. A change ships only if it is not worse on any hotspot and better on its target scenes.

## Out of Scope

- Disabling or reducing Lumen, ray tracing, or any other quality setting.
- Frame generation and upscaler swaps (OptiScaler and others), which own `version.dll` too.
- Gameplay changes such as a larger active cell radius, unless offered as an explicit, off-by-default trade-off.
- Character pooling or any change to actor identity.
- Windows-only tooling: PresentMon, the window-hook DLL, per-thread CPU sampling.
- Moving the game off the shared NTFS drive. This spec only measures whether it would help.

## Further Notes

Evidence and sources live in `docs/research-linux/`:
- `altar-architecture.md`
- `mods-survey.md`
- `proton-latency-streaming.md`
- `texture-streaming.md`
- `npc-creation.md`
- `preloading.md`
- `fast-iteration.md`

Still being written: `known-engine-issues.md`. It may add workstreams.

Native iteration status:
- The fix DLL already cross-compiles on Linux (clang-cl, lld-link and llvm-ml with xwin's CRT/SDK, no source patches, branch `linux-build`).
- Still to do before trusting it: run the self-test against the installed exe, load it under Wine, and benchmark the clang build against the MSVC release.
- Live-switchable today (table in `fast-iteration.md`):
  - 22 ini keys are fully live;
  - about 60 are "installed at start, then live";
  - 7 need a restart to switch on;
  - 11 are start-up only.

Preloading constraint:
- Most of the costly work comes from the old engine's cell attach, so it cannot happen before the cell exists.
- What may move earlier: read-only IO warming (page cache, read-ahead of the destination), shader cache persistence, GC placement, and the tail of the loading screen.
- A persistent shader cache on a fast Linux filesystem is the cheapest high-value check: a cold driver cache costs about 6 minutes of compiles.

First benchmark results:
- Results folder: `linux/results/20261107-093709-own-off-vs-on/report.md`, made at the player's own settings, which are GPU-bound at 97-98% load.
- Run-to-run noise is about ±5-10% on fps, so decisions need balanced order and several rounds.
