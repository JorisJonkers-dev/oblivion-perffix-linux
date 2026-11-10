# Late-appearing small objects and night lighting that "renders in" (Oblivion Remastered, UE 5.3, Proton)

Date: 2026-11-07. Method: local docs read (AGENTS.md fix index, texture-streaming.md, preloading.md, npc-creation.md,
quality-cvars.md, known-engine-issues.md, how-it-works.md PSO sections, linux/README.md spin/shots) plus a few Epic
docs and UE forum pages. **Nothing was launched or measured.** Tags: **[LOCAL]** repo evidence, **[WEB]** read source,
**[SPEC]** inference. Cvar names from memory of UE 5.3 are **[VERIFY]**: read each one first with the mod's `cvar` verb
(`get` answers nothing for a name that does not exist; the spin runner refuses such names before the run).

Reported: (1) small objects appear only when the camera turns toward them, fps fine; (2) at night lighting visibly
"renders in" and darkness fades into the distance after a turn. Setup: Lumen HW RT, VSM, Nanite, FSR 58.8 % at 1440p,
RX 7900 XTX, vkd3d-proton, OblivionPerfFix (OPF) installed. GPU-bound (98 %) at heavy spots [LOCAL].

## 0. Two corrections to the brief

- Epic's strategy numbering (5.8 page [WEB]): `r.PSOPrecache.ProxyCreationWhenPSOReady` (default on) enables the wait;
  `r.PSOPrecache.ProxyCreationDelayStrategy` (default **0 = skip the draw until PSOs are ready**, **1 = draw with the
  engine default material until ready**). There is no documented "ProxyCreationStrategy 0/1/2". So the owner's
  "2 = default material" is "DelayStrategy 1". Whether 5.3 already has `ProxyCreationDelayStrategy` is **not confirmed**
  (the 5.4 page lists it; 5.3 certainly has `ProxyCreationWhenPSOReady`) [VERIFY by `get`]. Same fact is in preloading.md.
- The camera-direction dependence is a clue: PSO precaching is triggered when a component loads/registers, not by view
  direction. A pure PSO delay would show objects late after a *cell attach*, not after a *turn*, unless the turn
  happens to coincide with new cells. Pure PSO delay therefore ranks below view-dependent systems for symptom (1)
  unless the test below shows otherwise.

## 1. Ranked causes

### Symptom 1: small objects appear on turn

| # | Cause | Evidence | Confidence |
|---|---|---|---|
| P1 | **Nanite geometry streaming is view-dependent and capped** (pages requested only for what is visible; installs capped per frame; pool small). Small props pop when the camera brings them into view because their pages/clusters are requested then. | [LOCAL] game ships Nanite pool 512 MB, `MaxPageInstallsPerFrame` 128, root pages 2048 (OPF raises to 3072) [texture-streaming.md]; both pool and installs are ReadOnly (start-up only). [WEB] Epic: Nanite streams per-view. [SPEC] page IO goes through ntfs-3g/FUSE on this machine (texture-streaming.md 1.2 #8), which lengthens request-to-install latency. | medium |
| P2 | **FSR 58.8 % shrinks the internal resolution, so Nanite/instance culling and mip selection run at ~0.59 x width.** Small objects fall under the pixel-size thresholds later and come in with higher-detail/lower-mip steps as the camera turns. Cull-distance fade (per-component max draw distance, dither fade) adds a visible "fade-in" on turn. | [SPEC] standard UE behaviour; [LOCAL] quality-cvars lists `r.Nanite.MaxPixelsPerEdge`, `r.Nanite.Culling.DrawDistance` (Steam: removing the cap costs ~10 fps), `r.ViewDistanceScale`, `foliage.LODDistanceScale` as the relevant knobs [snippet-level]. | medium |
| P3 | **Texture/VT streaming is view-dependent**: SVT uploads capped at 4 per frame (game scalability) and the classic streamer revisits wanted mips every `FramesForFullUpdate`=5 frames. Surfaces facing the new direction are blurry then sharpen, which reads as "appearing" for small, low-contrast objects. | [LOCAL] strongest measured streaming evidence: 8-10 s blotchy -> ~2.4 s with `VtStreamingUploads=64` [texture-streaming.md 1.2 #1, research.md `VtStreamingUploads`]. | high that it exists, medium that it explains *missing* objects |
| P4 | **PSO proxy delay** (`ProxyCreationWhenPSOReady`=1, strategy 0): new components are not drawn until their precache finishes. vkd3d-proton compiles each D3D12 PSO into a Vulkan pipeline (+ RADV ACO compile); on a cold or just-invalidated driver cache a precache queue of thousands lengthens the delay. When a cell attaches (NPC/prop spawn, `CellBufferPacedEvict` timing) objects exist but are invisible until compiled. | [LOCAL] game precompiles ~18,000 PSOs at start-up, in Background pace for 110-150 s (how-it-works.md PsoPrecompileFast); the cold-guard proxy "queue >= 250" shows Wine hides the driver threads from OPF; npc-creation.md #2 already hypothesises "created but not drawn" and calls it unmeasured. [WEB] Epic page: strategy 0 skips draws, landscape cannot delay, `NumPrecompilesRemaining` should gate loading screens. | medium-low for turn-triggered pop, medium for post-cell-attach |
| P5 | **Occlusion latency**: non-Nanite meshes use HZB occlusion from the previous frame(s); a turn exposes objects culled last frame and they appear 1-3 frames late (each frame is long when GPU-bound, ~16-30 ms). Nanite has two-pass occlusion and is not affected. Pure latency, not seconds. | [SPEC] standard; [LOCAL] OPF touches `r.AllowOcclusionQueries` only for the save thumbnail. | low as a *seconds-long* cause |
| P6 | **Old engine cell attach / NPC pacing** (`NpcCreationPacing`, `CellBufferPacedEvict`) delays far, unseen characters by design (>4096 units, unseen 0.5 s). Affects characters, not "small objects". Test by turning both off. | [LOCAL] AGENTS.md fix index lines 103, 110. Both are labelled timing-only. | low for props, medium for NPCs |

### Symptom 2: night lighting converges slowly

| # | Cause | Evidence | Confidence |
|---|---|---|---|
| L1 | **Lumen Scene lighting update speed and screen-probe temporal accumulation.** Lighting on newly visible surfaces (surface-cache cards captured/lit/radiosity-propagated over several frames) and screen probes reset in newly revealed screen areas then accumulate (MaxFramesAccumulated). Night is the worst case: low direct light, so indirect/emissive (torches, windows) dominates and its history is long. Darkness "fading into the distance" matches a new screen area filling with converging probes plus the far surface cache still dark. | [WEB] UE forum threads: lighting blotches/lag after camera turn; poster found `CardCapturesPerFrame` 30..9999 and `CardCaptureFactor` no help, but PP "Lumen Scene Lighting Update Speed" and "Final Gather Lighting Update Speed" helped; `r.Lumen.ScreenProbeGather.Temporal.MaxFramesAccumulated` lower = faster response, more noise; `r.LumenScene.FastCameraMode` = faster scene update, lower quality (https://forums.unrealengine.com/t/how-do-i-stop-lighting-blotches-from-popping-up-when-i-turn-the-camera-its-almost-like-the-lighting-cant-keep-up-with-simple-or-advanced-camera-movements-without-taking-5-seconds-to-rebuild-itself/2138776 , .../the-scene-takes-long-to-settle-when-switching-between-non-lumen-gi-and-lumen-gi/2692581). [LOCAL] quality-cvars lists `r.LumenScene.DirectLighting.UpdateFactor`/`Radiosity.UpdateFactor` as *quality-for-speed* knobs, i.e. the game may already run them lowered or at defaults. | medium-high |
| L2 | **VSM local-light page caching at night.** Torches/lanterns are local lights; each needs physical pages per visible region. A turn marks new pages needing render; cached pages from the previous direction may be evicted or the page pool is small (`MaxPhysicalPages` from scalability). Shadows pop in over frames; with moving lights (flickering torches) cached pages are invalidated each frame. | [LOCAL] quality-cvars VSM table (cache on; do not touch MaxPhysicalPages). [SPEC] night scenes have many local lights; no measurement. | medium |
| L3 | **Eye adaptation / auto exposure.** Turning from a lit area to a dark one changes histogram; exposure adapts over ~1-3 s by design; this is the exact "darkness fades in after turning" look and is separable from Lumen by watching mean luminance. | [LOCAL] known-engine-issues V01: the game's eye adaptation carries over and is visible in dark scenes; `r.EyeAdaptation.*`/PP exposure speed up/down unsure if the game's own PP overrides [VERIFY]. | medium |
| L4 | **Volumetric fog temporal reprojection** (history weight): fog/lit-volume in the new view converges over ~8-16 frames; night fog is visible against lights. | [SPEC] `r.VolumetricFog.HistoryWeight`, `TemporalReprojection` [VERIFY]. quality-cvars cites only grid size. | low-medium |
| L5 | **HW RT scene churn**: new objects missing from the RT scene/TLAS or Lumen far-field are dark in reflections/GI until built; vkd3d-proton AS builds are slow. OPF already keeps RT buffers and Lumen arrays [LOCAL]. | [LOCAL] known-engine-issues M04, research.md RT BLAS notes. | low |
| L6 | **Sky/atmosphere at night + OPF atmosphere fast path**: known cloud/sky flicker at night with OPF 1.2.4 (V06, issue #47). Not a convergence cause but check `AtmosphereLightFastPath`/`AtmosphereDirtyFilter` OFF to rule out. | [LOCAL] known-engine-issues V06. | low |

## 2. Tests, in order (each: change, runtime-settable?, expected cost)

Run all with the turn-settle method in section 3. Always read the live value first and put it back. "Live" = settable
through the mod's `cvar` verb in a running game; "start" = Engine.ini at launch only (spin cannot flip these; use
`run`/`ab` with a fresh launch).

| ID | Change | Live? | Expected visual / perf cost | Tests |
|---|---|---|---|---|
| T1 | Baseline: record `get` of `r.PSOPrecaching`, `r.PSOPrecache.Components`, `r.PSOPrecache.Resources`, `r.PSOPrecache.ProxyCreationWhenPSOReady`, `r.PSOPrecache.ProxyCreationDelayStrategy`, `r.Nanite.Streaming.*`, `r.LumenScene.*`, `r.Lumen.ScreenProbeGather.Temporal.MaxFramesAccumulated`, `r.EyeAdaptation.*`, `r.Shadow.Virtual.MaxPhysicalPages`, `r.VolumetricFog.HistoryWeight` | yes | none | tells which of the below exist in 5.3 |
| T2 | **PSO discriminator.** `r.PSOPrecache.ProxyCreationWhenPSOReady=0` (no delay: objects drawn at once, may hitch) | maybe live (if not ReadOnly); else Engine.ini `[SystemSettings]` | hitches on first draw of new materials (vkd3d-proton compile on the render thread: could be 10-100+ ms) | if pop-in disappears -> P4 is real |
| T2b | `r.PSOPrecache.ProxyCreationWhenPSOReady=1` + `r.PSOPrecache.ProxyCreationDelayStrategy=1` (default material, no invisible objects) | as T2 | objects briefly show the default grey material (obvious on small props), no hitch | the shipping-friendly fix if T2 confirms P4 |
| T2c | `r.PSOPrecaching.WaitForHighPriorityRequestsOnly=1` | live [VERIFY] | less waiting in loading screens, more late PSOs in play | only to measure sensitivity |
| T3 | Cell-attach discriminator: `NpcCreationPacing=0`, `CellBufferPacedEvict=0` (ini, live) | live | CPU spikes return | if pop disappears -> P6 |
| T4 | Nanite: `r.Nanite.Streaming.StreamingPoolSize=1024` (start), `r.Nanite.Streaming.MaxPageInstallsPerFrame=256` (start), `r.Nanite.Streaming.NumInitialRootPages` 4096 (start, OPF `NaniteInitialRootPages` only handles 3072) | start (ReadOnly) | +512 MB VRAM; small GPU cost on install frames | P1 |
| T5 | Culling/size: `r.Nanite.MaxPixelsPerEdge=0.8` or `r.ViewDistanceScale=1.3`, `r.Nanite.Culling.DrawDistance` leave 0, `r.DisableLODFade=1` | live | `r.ViewDistanceScale` +fps cost (10 % possible); `DisableLODFade` hard pops instead of dither | P2 |
| T6 | Textures: `VtStreamingUploads=64` plus `r.VT.MaxUploadsPerFrame=64`, `r.VT.MaxTilesProducedPerFrame=120`, `r.Streaming.FramesForFullUpdate=2`, `r.Streaming.MaxTempMemoryAllowed=512` (texture-streaming.md rows 1-5) | live | upload CPU/GPU copy in bursts; image identical when settled | P3 |
| T7 | Occlusion: `r.AllowOcclusionQueries=0` (live) or `r.HZBOcclusion=0` [VERIFY] | live | more draws, lower fps in dense scenes; **do not ship** | P5 only |
| T8 | **Lumen speed bundle:** `r.LumenScene.FastCameraMode=1`; `r.LumenScene.SurfaceCache.CardCapturesPerFrame` 2x default; `r.LumenScene.DirectLighting.UpdateFactor` and `r.LumenScene.Radiosity.UpdateFactor` lowered (these are divisors in Epic's "update factor" naming: lower = faster [VERIFY direction by reading default and the cvar help string]); `r.Lumen.ScreenProbeGather.Temporal.MaxFramesAccumulated` 16 -> 8; `r.Lumen.ScreenProbeGather.Temporal` filter unchanged | live | 0.5-2 ms GPU [SPEC]; more shimmer/noise in dark areas (watch SSIM vs base at fixed headings) | L1 |
| T9 | VSM: `r.Shadow.Virtual.Cache.MaxPageAgeSinceLastRequest` up [VERIFY], `r.Shadow.Virtual.MaxPhysicalPages` up (start-up; overflow corrupts if too low), `r.Shadow.Virtual.NonNanite.*` unchanged; or `r.Shadow.Virtual.MarkCoarsePagesLocal=1` to keep coarse local-light pages resident | mixed | VRAM; per-frame page render | L2 |
| T10 | Exposure: `r.EyeAdaptation.ExponentialTransitionDistance`/speed up/down raised, or `r.EyeAdaptation.MethodOverride=2` (manual) for the *test only* [VERIFY the game does not override each frame] | live | brightness differs; test only | L3 |
| T11 | Fog: `r.VolumetricFog.HistoryWeight` 0.9 -> 0.7; `r.VolumetricFog.TemporalReprojection=0` | live | noisier/flickering fog | L4 |
| T12 | OPF off-switches: `AtmosphereLightFastPath=0`, `AtmosphereDirtyFilter=0`, `LumenKeepArrayCapacity=0` | live (most) | perf only | rules out DLL as cause (L6, plus any Lumen interaction) |

Interpretation rule: a cause is "confirmed" when its toggle changes the *settle curve* (section 3) by more than the
run-to-run spread; "fixed" only when the settled image is unchanged (SSIM within the noise floor).

## 3. How to measure: the turn-settle test

Goal: a number, "time until the image stops changing after a 90 deg snap", split into a geometry part (pop-in) and a
lighting part (convergence). Reuses the existing spin machinery; add one scene mode (or a `settle` subcommand next to
`spin`/`--shots`).

1. Place the camera at a fixed spot (`linux-hotspots` scene, a night hour via `--hour 23`, `--weather Clear`; one
   scene with many small props and one with torches: e.g. the Cheydinhal canal and an exterior inn at night). Turn
   motion blur off for the test (`r.MotionBlurQuality=0`) and use the same window size.
2. Hold heading H0 for >= 10 s (everything converged). Snap to H0+90 deg with one heading command (the cinematic camera
   trails ~0.3 s, `--cam-lag`; do the snap in the heading timeline so the lag is subtracted). Capture the window
   for ~3-4 s at the fastest xwd rate (xdotool + xwd, luminance, block-averaged to ~480-960 px as `--shots` does; expect
   ~10-20 Hz; log a monotonic timestamp per frame).
3. Reference frame R = mean of the last 0.5 s of a 6 s capture (or a second 10 s hold at H0+90 taken afterwards).
   Per frame t compute:
   - **SSIM(frame_t, R)** (8x8 windows, `imgcmp.py`) -> "total settle time" = first t after which SSIM stays >= 0.99
     (or noise floor + 0.005, using `base` against its own other slots as the floor).
   - **Low-frequency term**: SSIM or mean absolute difference of images blurred to ~1/32 size (lighting, exposure,
     shadows) -> **lighting settle time**.
   - **High-frequency term**: edge-map difference (Sobel magnitude, thresholded) -> **geometry/texture settle time**;
     the count of connected regions that exist in R but not in frame_t (pixels with |diff| > 24/255 as `--diff-thresh`)
     approximates "objects not yet drawn".
   - Mean luminance curve alone separates eye adaptation (smooth monotone exponential, same speed regardless of
     Lumen settings) from Lumen/VSM convergence (stepwise or noisy).
4. Repeat 6-8 snaps per variant (alternate +90/-90 and 4 headings so the new view is different each time), ABBA with
   `--rounds 2` and the `cvar:`/`ini:` variants exactly as `spin` does; report median and spread of the three settle
   times, plus the avg fps for the cost side. The existing `detail.py` already implements "settle" for texture
   sharpness (stable-brightness gate, `test_detail.py` settle tests): reuse its thresholding and its brightness-stable
   gate rather than reimplementing.
5. For P4 specifically add a log: `r.PSOPrecache.Validation=2` (start-up) and `r.PSO.RuntimeCreationHitchThreshold=20`
   to count misses, and OPF's pso stats line (`PsoPrecompileFast` queue) at the snap times; if misses/queue
   spikes coincide with slow geometry settle -> P4. Also run twice: with and without the driver shader cache (clear
   `~/.cache/mesa_shader_cache`, or the Steam `shadercache` for the app) to see the cold-compile effect; this is
   the vkd3d-proton/RADV amplification Epic's page warns about ("driver cache masking").
6. Verdict lines like `--shots`: GAIN = median settle time down >= 30 % and beyond spread; COST = SSIM vs base at the
   settled state falling below the noise floor by > 0.015, or avg fps drop > 3 %.

Controls: also spin at 30 deg/s (`spin --shots`) to see the steady-state "pop radius" (objects present at heading
sector k vs the settled image) as a second measure.

## 4. Fixes that could live in the DLL (OPF)

OPF already has the pattern: find the cvar registration by name, write the int/float on the monitor thread, optionally
re-write if the game's scalability puts it back (`VtStreamingUploads`, `NaniteInitialRootPages`, `PsoCompileThreadPool`,
`r.AllowOcclusionQueries` slot at exe+0x91D4C80). Candidates in order:

1. **Live cvar defaults at start** (new generic key, e.g. `CvarOverrides=name=value;...` applied once after scalability
   and re-applied if changed): covers T2b (`ProxyCreationDelayStrategy=1`), T6, T8, T11 without per-cvar code. Image
   identical when settled for T6; T8/T11 trade noise for speed (opt-in).
2. **PSO warm-up for nearby objects**: on cell attach, request PSO precache for the components of newly registered
   primitives at high priority (UE already marks pending PSOs high-priority at proxy creation, so the gain is only to
   start before the proxy is created) and keep the `PsoCompileThreadPool` size; also hold the fade gate on
   `NumPrecompilesRemaining()` (preloading.md item 2 says whether the game's 5 s hold covers precache requests is
   open). Risk low, gain unknown until T2 shows P4 is real.
3. **Budgeted Lumen card capture**: raise `r.LumenScene.SurfaceCache.CardCapturesPerFrame` (and `FastCameraMode`) only
   while the previous N frames had GPU headroom (needs a GPU-time source: the monitor thread has frame times; GPU %
   would come from the RHI timestamp or MangoHud-like data; at 98 % GPU-bound spots the budget would stay at stock),
   or only for ~1 s after a large heading change (camera angular velocity read from the camera manager) so the cost
   is a short burst. Evidence that this cvar matters is weak (forum: no effect), so gate on T8 results per cvar.
4. **Raise the Nanite install caps**: `MaxPageInstallsPerFrame` and pool are ReadOnly [LOCAL texture-streaming.md], so
   only by an early start-up write like `NaniteInitialRootPages` (before the streaming manager reads them); verify the
   engine reads them once.

## 5. Concise top 5

1. **T2/T2b first: PSO proxy delay discriminator** (`r.PSOPrecache.ProxyCreationWhenPSOReady=0`, then `=1` with
   `ProxyCreationDelayStrategy=1`). Cheapest test, decisive, and the only fix that removes truly *invisible* objects
   (strategy 1 trades invisibility for a brief default-material look; strategy 0 of the ready-wait trades it for hitches).
   Caveat: turn-triggered pop argues against it; expect it to matter after cell attach and on cold driver caches.
2. **Nanite + culling (T4/T5)**: view-dependent geometry streaming with a 512 MB pool and 128 installs/frame and
   FSR-shrunk thresholds explain "appears when turned toward". Start with live T5, then start-up T4 on NTFS/FUSE.
3. **VT/texture streaming (T6)**: `VtStreamingUploads=64` + `r.VT.MaxUploadsPerFrame=64` + `FramesForFullUpdate=2`; the
   only item with local measured gain (8-10 s -> 2.4 s) and identical settled image.
4. **Lumen response bundle (T8)**: `r.LumenScene.FastCameraMode=1`, higher scene/radiosity update rates, lower
   `ScreenProbeGather.Temporal.MaxFramesAccumulated`; accept some noise at night. Card-capture-count alone is probably
   not enough per the forum evidence.
5. **Separate eye adaptation and VSM from Lumen (T10, T9, T11)** with the luminance curve of the turn-settle test;
   if mean luminance is the slow term, no Lumen cvar will fix it and the answer is exposure speed.

Also: nothing here is measured; run T1 and the settle test before changing any default.
