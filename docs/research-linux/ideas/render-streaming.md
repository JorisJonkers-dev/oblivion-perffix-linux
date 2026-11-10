# Further optimisation ideas: render and streaming (Linux / Proton)

Date: 2026-11-07. Method: read-only review of `src/OblivionPerfFix/src/render/` and `streaming/` (file header comments),
the matching sections of `docs/research.md` (Rendering, Travelling, Tried and not shipped, What still limits the game),
`docs/tracking/LOG.md` (the canal is GPU-bound: GPU 98 %, CPU 56 %) and `docs/tracking/investigations.md` #18.
Nothing was run, built or benchmarked. Claims are from the source comments and research notes. Anything I could not
confirm in code or docs is marked **[SPECULATION]**. Engine cvar names from memory of UE 5.3 are marked **[VERIFY]**:
check them in the game's cvar list (the console `help` dump or a name search of the exe) before any A/B.

Context that drives the ranking: at the canal the frame is GPU-bound, so CPU-side fixes cannot raise average fps there.
Only GPU work removed at identical image, or work that moves to a second queue, helps those views. Travel hitches are
the other target, and there the streaming items below apply.

## Ranking

| # | Idea | Area | Kind | Expected gain (evidence) | Identical image | Risk | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | Async compute for the passes UE already marks async (cvar A/B first) | GPU | new | unknown; 0-10 % GPU at canal **[SPECULATION]** | yes if UE's own path | medium (driver-specific sync) | low until cvars checked |
| 2 | Re-measure RdgSubmitBatch / RdgParallelTranslate GPU cost on RADV | GPU | tuning | 0-3 ms GPU per frame **[SPECULATION]**, Windows numbers only | yes | low | medium |
| 3 | Skip a TLAS rebuild when its inputs are bit-identical to last frame | GPU | new | depends on build time; unmeasured **[SPECULATION]** | yes | medium | low |
| 4 | Nanite Hierarchy and ImposterData keep capacity (extend NaniteInitialRootPages) | streaming | extension | travel spikes only; zero steady-state | yes | low | medium |
| 5 | Ray-tracing upload buffers keep size (extend RtSceneBufferKeep) | streaming | extension | small; unmeasured | yes | low | low |

Items 6-8 (smaller or mostly speculative extensions) are at the end.

---

## 1. Async compute for passes UE already marks async (GPU, new)

**What.** UE 5.3's render graph supports an async compute queue (RDG async compute, Nanite's async rasterisation and
some shadow / Lumen passes depending on the build). `docs/research.md` ("What still limits the game") says "Async compute
can't be used, because the game was built without inline ray tracing". I read that as a claim about one path (ray
tracing work on compute), not about every pass. The current code has no async-compute hook; the only queue-related
code is the RdgSubmitBatch submission path (`render/submit_batch.cpp`, direct queue) and the frame-generation swap chain
queue (`r.FidelityFX.FI.AllowAsyncWorkloads`, FrameGenAsyncCompute). **[VERIFY]** whether the game's build registers
`r.RDG.AsyncCompute` (UE 5.3 default is passes-flagged only), `r.Nanite.AsyncRasterization` and any Lumen / virtual
shadow map async cvars, and what values the game ships.

**Where.** Cvars only, through the ini or the monitor thread's cvar writer (same pattern as `GpuSceneParallelUpload`,
`VtStreamingUploads`: find the registration by name and shape, write both copies of the int). First step needs no code:
flip them live in the console or the spin harness.

**Why identical.** Async compute reorders work between queues; UE's own path is written for that. The picture should
be the same if UE's sync points hold. This is the same class of change as `RdgParallelTranslate` (UE's own path enabled
by a flag). If a probe shows a flag changes the image, drop it.

**Expected gain.** **[SPECULATION]** At the canal, GPU is 98 % and the GPU work at 1440p with hardware Lumen is mostly
Nanite raster, shadow maps, Lumen and post. Overlap of a raster or shadow pass with a compute pass on RDNA3 (two
compute engines, ACE) could give a few percent to 10 %. RADV exposes compute queues that vkd3d-proton can map D3D12
compute queues to, which is an open question for this game (**[VERIFY]** in a RenderDoc or RGP capture: are there two
queues busy at once?).

**Risk.** Medium. Sync bugs in a driver path UE 5.3 may not exercise on RADV. Watch for device-lost or residency
crashes (the research already saw a `UpdateResidency` crash with another race). Reject if any image change.

**Measure.** `bench.py spin` at `linux-hotspots` canal (GPU-bound, 98 %): flip each cvar live, ABBA, 3 rounds. Record GPU
ms per frame and the present-to-present spread. Check the image with `tools/Compare-Benchmark.ps1`. First, a single
RGP capture (Radeon GPU Profiler runs on RADV) to see whether any async queue is used at all.

## 2. RdgSubmitBatch and RdgParallelTranslate GPU cost on RADV (GPU, tuning)

**What.** The research measured on Windows / D3D12 that `RdgParallelTranslate` alone added ~2.5 ms of GPU time per frame
(about 110 extra ExecuteCommandLists / Signal pairs), and `RdgSubmitBatch` (`render/submit_batch.cpp`, default 32 lists,
1 ms max hold) removed +1.6-3 ms of that. On vkd3d-proton the submission path is different: each D3D12
ExecuteCommandLists becomes a vkQueueSubmit on RADV, with different per-submit costs and no ExecuteCommandLists-level
merge rules. So the GPU cost that batching removes may be smaller, larger, or in the other direction on this machine.
The hold itself (up to 1 ms) also delays GPU start of a batch.

**Where.** Ini keys, already in `common.h`: `RdgParallelTranslate` (0 / 1 / 2) and `RdgSubmitBatch` (0 = off, else
the batch size; default 32). Check whether `RdgSubmitBatch` is live (the research says parallel translate is). If live,
no code change is needed for the first test.

**Why identical.** Only submission grouping changes; the same command lists run in the same order (the file's own
argument). A batch never holds a list that waits or signals.

**Expected gain.** **[SPECULATION]** 0-3 ms GPU per frame at 1440p on this card, which at 98 % GPU is up to a few percent of
frame time. Possible loss if the 1 ms hold creates GPU idle gaps. The result also decides whether the GPU-side cost the
research blamed on parallel translate (2.5 ms) exists here at all, which changes the priority of item 1.

**Risk.** Low. The switches exist and the defaults are the documented ones.

**Measure.** Spin at canal: `RdgSubmitBatch` 0 vs 32 vs 8, `RdgParallelTranslate` 0 vs 1 vs 2 (auto is on for a 24 GB card),
ABBA. Read GPU ms and RHIThread ms from the frame log. A batch-size sweep with the max age at 1 ms and 0.25 ms is a
separate follow-up (a code constant, not an ini key **[VERIFY]**).

## 3. Skip a TLAS rebuild when its inputs are bit-identical (GPU, new)

**What.** `FRayTracingScene::Create` (UE 5.3 RayTracingScene.cpp:88; `streaming/rt_scene_keep.cpp` already hooks its
buffer creation) builds the top-level acceleration structure for the scene every frame it is needed. In a static
view (the canal with a still camera, or the spin at canal) most instances do not move. If the instance list (the
bottom-level pointers, transforms, masks, flags) is bit-identical to the last build, the TLAS result is the same, so
the build could be skipped and the previous TLAS kept.

**Where.** Next to `RtSceneBufferKeep`'s hook: a compare of the instance and transform upload buffers' CPU copies (the
ones `Create` fills) against the last frame's, and a skip of the build command when identical. Needs a lab probe first:
count frames whose instance set is identical, and time the TLAS build (RGP or the existing timers).

**Why identical.** Identical inputs to a deterministic build give the same bytes in the same buffer. The risk is that
the build is not deterministic in its output, or that something else writes into the same buffer in between. A probe
checks both.

**Expected gain.** **[SPECULATION]** Unknown. A TLAS build on 1440p Lumen is perhaps 0.2-1 ms per frame for a city view
(not measured here). Gain only in static views; the picture of a city walk changes instances often (NPCs, grass
instance culling).

**Risk.** Medium. Wrong TLAS after an instance change would be a visible bug; the compare must cover every input the
build reads (masks, flags, user data), not only transforms. Reject unless the probe shows static frames are common.

**Measure.** Probe build with counters only (no skip): fraction of identical frames at canal, the spin's static
view and a walk. Then RGP for the TLAS pass time. Only then an A/B.

## 4. Nanite Hierarchy and ImposterData keep capacity (streaming, extension)

**What.** `streaming/nanite_stream_buffers.cpp` already keeps the ClusterPageData buffer at a bigger first size
(`NaniteInitialRootPages` 2048 -> 3072). The same `ProcessNewResources` also resizes two other buffers from grow-only
span allocators, with the same copy-and-replace pattern:
- Hierarchy: `RoundUpToPowerOfTwo(nodes) * 208` bytes (its power-of-two step is a regrow point, one copy per step);
- ImposterData: `max(NumInitialImposters, imposters rounded to 2 significant bits) * 41,472` bytes.

The file's own header lists both sizes, and the `NaniteStreamProbe` (lab build) already counts their resizes per call.

**Where.** `nanite_stream_buffers.cpp`: the Hierarchy resize's size argument (or the ImposterData minimum), same
mechanism as `NaniteInitialRootPages` (a start-up value, an ini line wins). Lab: `Nanite*MinMB` minimums already exist.

**Why identical.** Buffer capacity only; the nodes and imposters stored are the same, and offsets depend on content, not
on capacity (the header says so for the root pages). Same argument as `NaniteInitialRootPages`.

**Expected gain.** Removes copies on the GPU at travel steps (a Hierarchy copy scales with node count). It does not
touch steady-state fps at a static spot. Gain is in the Imperial City arrival spike class. **[SPECULATION]** size of
the copies is not measured here; the probe gives counts and MB.

**Risk.** Low, same as `NaniteInitialRootPages`. Costs video memory (a bigger start-up buffer), and the Linux video
budget is roomy on a 24 GB card but not on smaller ones.

**Measure.** `NaniteStreamProbe` on the travel scenes (`cheydinhal` door / fast travel, `linux-hotspots`), resize counts
and times before and after; no fps A/B needed at the static canal.

## 5. Ray-tracing upload buffers keep size (streaming, extension)

**What.** `rt_scene_keep.cpp` keeps the TLAS result buffer (the scene buffer) at a big-enough size, but its two upload
buffers (`FRayTracingScene::InstanceUploadBuffer`, `TransformUploadBuffer`) are only timed by the diagnostic. I did not
confirm from the source whether they are re-created in every `Create` or only when they grow.

**Where.** Same hook site as the scene buffer; the keep rule is the same (`need > size` re-creates, `need < size/2`
keeps).

**Why identical.** Same argument as the scene buffer: only the capacity differs.

**Expected gain.** Small: these buffers are about one entry per instance (tens of bytes each), so the copies are small
unless the instance count is large. **[SPECULATION]**. Worth it only if the probe shows they are re-created every
frame.

**Risk.** Low. Video memory cost is small.

**Measure.** Probe counts of `RHICreateBuffer` calls per minute for these two names (the diagnostic exists). Decide from
that.

---

## Smaller and speculative items (6-8)

6. **Instance update command buffer, other growth paths (render/streaming, extension, speculative).**
   `InstanceClearReserve` fixes the reserve for `ClearInstances`. `FInstanceUpdateCmdBuffer` (UE 5.3 HISM) is also filled
   by other per-instance loops (`AddInstance`, `RemoveInstance`, `BuildTree` paths). Each may regrow one step at a time.
   **[SPECULATION]** the same waste exists there. Find the callers of `HideInstance` / the buffer's grow function in the
   binary, count reallocations per streamed area (the grow function is the same one the fix already hooks). Gain only in
   big foliage arrivals; skip unless a probe shows regrowth in a frame.

7. **Atmosphere: one component family not on the accessor filter list (render, extension, speculative).**
   `AtmosphereDirtyFilter` covers the Set/PostSet accessors the weather code uses for the sun, moon, height fog, sky
   atmosphere and sky light. Any other component written through the same accessors every frame would still rebuild its
   render state. A counter on `MarkRenderStateDirty` per component class during a weather blend would show it. I did not
   find a second family in the code. **[SPECULATION]** none exists.

8. **Skinned BLAS refit batching in the skin cache (GPU, speculative).**
   `RayTracingBuildBatch` batches the new-mesh builds (InitRHI). The per-frame refits of dynamic skinned meshes (NPCs,
   skin cache with `allow update`) are not batched by that fix, and the research notes the refits happen before the
   engine's batch. **[SPECULATION]** they are a per-frame GPU cost at crowds; not at the canal. Measure with RGP
   (refit barriers per frame) in a crowd scene. Identical image if the same refits run in the same order, but barrier
   changes need care.

## Revisiting rejected ideas (part c)

| Rejected on Windows | Revisit on Linux? | Why |
|---|---|---|
| `r.RayTracing.AsyncBuild` (no gain, UE 5.4+ default) | yes, together with item 1 | if RADV can run the build on a compute queue, the result may differ; **[SPECULATION]** |
| `D3D12.ResidencyManagement=0` (submission -16-21 %, no fps change; risk on < 16 GB cards) | low | the submission thread is not the limit at the canal (GPU-bound); vkd3d-proton's residency path is different **[VERIFY]**; only if item 2 shows submission matters |
| `r.RDG.Events=0` (RenderThread -0.3 ms, no fps change) | no | RGP and crash reports use the pass names; this is a diagnostic cost, not a GPU one |
| Pinning GameThread / old-engine threads to cores (no fps change) | low | canal is GPU-bound; the CachyOS scheduler may differ, but CPU is not the limit there |
| `VKD3D_CONFIG=no_upload_hvv` | already measured on Linux: no gain (LOG) | do not retry |
| Frame-generation UIMode 1, Lumen LightingMode 0, RT culling radius 5000, shadows High | no | change the look; excluded by the rules |

## What I would do first

1. RGP capture at canal (RADV): which queues are busy, what the top GPU passes are, whether any async work already runs.
   Read-only, one run, no code. This decides items 1 and 3.
2. Item 2 (ini A/B of RdgSubmitBatch and RdgParallelTranslate): cheap, measurable at the canal.
3. Item 1 cvar A/B only if the capture shows an idle async queue and the cvars exist in the game.
4. Items 4 and 5 are travel-hitch work: measure with `NaniteStreamProbe` and the RT buffer timers on door scenes, not
   with spins.

Gaps: no capture, no build and no run were done for this note. The UE cvar names above are not confirmed in the game.
