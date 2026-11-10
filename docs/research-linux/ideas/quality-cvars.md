# Quality-trading console variables for Oblivion Remastered (UE 5.3)

Goal: find UE 5.3 cvars that buy >= ~5% fps or fewer hitches for a small image change, on an RX 7900 XTX at 2560x1440, FSR at 58.8% screen percentage, GPU-bound (~98%).

Method: web research only (no engine source checked, no in-game tests). Confidence is marked on every claim:
- **[sourced]** stated by Epic docs or a named community source that was actually read.
- **[snippet]** seen only in a search-result snippet, page not read or fetch failed.
- **[guess]** from general engine knowledge, not verified in this research. Test before trusting.

Caveat on versions: the Epic VSM page fetched (dev.epicgames.com, virtual-shadow-maps-in-unreal-engine) is the **UE 5.8** version, not 5.3. Defaults quoted from it may differ in 5.3. Check against `Engine/Config/BaseScalability.ini` and `ConsoleVariables` in the 5.3 source.

Several community sources conflict. Where they do, both are listed.

---

## 1. Ranked top 10 (test in this order)

Ranking = expected gain x (1 / visual risk), tempered by how well sourced it is.

| Rank | cvar | Default (UE 5.3) | Test value | Expected gain | Visual | Runtime? | Confidence |
|---|---|---|---|---|---|---|---|
| 1 | `r.Lumen.Reflections.MaxRoughnessToTraceForFoliage` | not verified | `0` | Epic: "significant performance" with no stated quality loss. Likely best Lumen-reflection win for forest. | Foliage reflections fall back to SSR/nothing. Hard to see at normal play. | Yes (console) | [sourced] Epic Lumen perf guide |
| 2 | `r.Lumen.Reflections.DownsampleFactor` | not verified (Epic range 1 or 2) | `2` | Half-res reflection trace. Community estimate 1-2 ms. Fits the >=5% target at 2560x1440 (about 16 ms frame). | Blurrier, less stable reflections (Epic: "blurrier and less stable"). Visible on water and chrome. | Yes | [sourced] Epic guide for range and effect; [guess] for ms number |
| 3 | `r.Lumen.ScreenProbeGather.DownsampleFactor` | not verified. Medium post says 16 at Epic, 32 at High. Unreliable. | `24` or `32` | Probe-gather cost scales with probe count. Forum: 16 vs 8 is about 4 ms on a 4090, so going up saves real time. | Indirect light and indirect shadows softer and blurrier. Mostly noticeable in dim interiors and under overhangs. | Yes | [sourced] direction (Epic guide); cost figure [snippet] forum |
| 4 | `r.Lumen.HardwareRayTracing.Reflections.HitLighting` | not verified (0 in Overkill/community config) | `0` | Community estimate 0.5-1 ms. Epic says hit lighting is costly and not worth it for most games. | Reflections show surface-cache colour instead of lit hits. Subtle on most surfaces. | Yes | [sourced] Epic says costly; [snippet] ms number from Stray Spark |
| 5 | `r.Nanite.MaxPixelsPerEdge` | `1.0` [snippet, wiki and forum]. Epic docs not read. | `1.5` then `2.0` | Forum calls it probably the largest single perf lever. Higher = less geometry. Affects every Nanite mesh. | Small props, leaves, and rocks lose tessellation detail and can shimmer or pop at distance. Watch the canal and bridges. | Yes (cvar read each frame) | [snippet] wiki + forum |
| 6 | `r.Shadow.Virtual.SMRT.SamplesPerRayDirectional` | `8` [sourced, UE 5.8 page] | `4` | Fewer shadow-map samples per penumbra ray. Epic: "fewer samples are cheaper", recommends 4-8. | Penumbra noisier, softer edge detail lost. Visible on contact shadows of sun-lit objects. | Yes | [sourced] Epic VSM (5.8) |
| 7 | `r.Shadow.Virtual.SMRT.RayCountDirectional` | `8` at Shadows Epic [sourced, 5.8 page] | `4` | Fewer rays per pixel. Epic: "fewer rays add visible noise". Cost scales with rays. | Penumbra noise, most visible on moving objects. Pair with (6). | Yes | [sourced] Epic VSM (5.8) |
| 8 | `r.Shadow.Virtual.MarkCoarsePagesDirectional` | enabled (implied) [sourced] | `0` | Epic: disabling coarse pages "can yield large gains" when non-Nanite dynamic geometry sits in coarse pages. Forum: helps a lot with few atmospheric effects. | Possible shadow pop or missing far-shadow on dynamic geometry. Check on NPCs and far trees. | Yes | [sourced] Epic VSM (5.8); [snippet] forum |
| 9 | `r.Shadow.Virtual.ResolutionLodBiasDirectional` | `0` per Epic 5.8 page (set by Shadow scalability). Forum cites `-1.5` at Epic presets. Conflict. | `+0.5` (lower res) | Each -1 doubles resolution. So +0.5 cuts sun-shadow resolution. Epic notes changing it at runtime costs performance and can overflow the page pool. | Blurrier sun shadows far from camera. Visible on building edges. | Yes, but expect a hitch (cache invalidation) | [sourced] direction; default conflict |
| 10 | `r.Lumen.ScreenProbeGather.TracingOctahedronResolution` | "around 2" per community Lumen page, unclear | `8` or `12` (Epic default in 5.3 unknown; one forum and one blog say 16 at Epic) | Fewer rays per probe. Forum reported noise reduction at 8 with downsample 8. Epic: lower values reduce directionality and rough reflection quality. | Indirect lighting less directional, rough reflections blurrier. Subtle. | Yes | [sourced] direction (Epic); values [snippet] |

Honourable mentions, not in top 10:
- `r.Lumen.ScreenProbeGather.IntegrateDownsampleFactor=2` [sourced, Epic guide]: "greatly speeds up integration", adds noise and softens normals. Could be swapped in if (3) alone is not enough.
- `r.Lumen.Reflections.MaxRoughnessToTrace` 0.4 -> 0.3 [snippet, Medium and forum]: community says reduces work. Forum warns lowering it can reveal Lumen GI errors. Check GI leaks.
- `r.Lumen.Reflections.DownsampleCheckerboard` [sourced, Epic guide]: one ray every 2 px. Between full and quarter res. Alternative to (2) if (2) looks too soft.
- `r.Lumen.TraceMeshSDFs=0` [snippet, community Steam guide]: unknown gain; affects GI quality.

### Rejected (large visual change, despite claims)

- `r.Lumen.DiffuseIndirect.Allow=0` appears in Oblivion Engine.ini guides (Overkill, Steam "Lumen Begone"). Claims 5-10 fps. This disables Lumen GI entirely, which is a visible change to the whole scene. Overkill says the drop is "smaller than expected", but it is still a much bigger change than the owner allows. Keep as a control only, not a candidate.
- Overkill's Steam Deck preset sets Lumen Hardware RT off and Software RT Quality Low. Fine for handheld, too low for this card.
- `r.Nanite.Culling.DrawDistance=0` (Steam discussion): increases foliage draw distance; about 10 fps cost reported. Wrong direction for us.
- `r.Shadow.Virtual.UseFarShadowCulling=0` (Epic): this makes non-Nanite geometry render into shadows at any distance. Increases cost. Wrong direction.

---

## 2. Grouped candidates by system

### Lumen

| cvar | Default (5.3) | Test | Gain | Visual | Runtime | Conf |
|---|---|---|---|---|---|---|
| `r.Lumen.Reflections.Allow` | not verified | `0` (SSR fallback) | Epic: saves cost. Replaces Lumen reflections, so "a bit" more than (2) but worse look. | SSR reflections, obvious on water and glass. | Yes | [sourced] |
| `r.Lumen.Reflections.DownsampleFactor` | not verified | `2` | see top 10 #2 | see above | Yes | [sourced] |
| `r.Lumen.Reflections.DownsampleCheckerboard` | not verified | `1` | between full and quarter | medium | Yes | [sourced] |
| `r.Lumen.Reflections.MaxRoughnessToTrace` | not verified | `0.3-0.4` | community | rough surfaces lose Lumen | Yes | [snippet] |
| `r.Lumen.Reflections.MaxRoughnessToTraceForFoliage` | not verified | `0` | top 10 #1 | foliage reflections lost | Yes | [sourced] |
| `r.Lumen.Reflections.RadianceCache` | not verified | experimental | Epic: helps only many rough pixels | risky | Yes | [sourced] |
| `r.Lumen.HardwareRayTracing.Reflections.HitLighting` | 0 in Overkill config | `0` | 0.5-1 ms [snippet, Stray Spark] | low | Yes | [sourced]/[snippet] |
| `r.Lumen.HardwareRayTracing.MaxIterations` | not verified | lower (console only) | Epic: caps BVH traversal; terminated rays read as fully occluded | over-occlusion | Yes | [sourced] |
| `r.Lumen.HardwareRayTracing.MaxTraceDistance` | 10000 [Stray Spark] | lower | GI/reflection range shortened | far reflections change | Yes | [snippet] |
| `r.Lumen.ScreenProbeGather.DownsampleFactor` | disputed (16?) | 24-32 | top 10 #3 | indirect softer | Yes | [sourced]/[snippet] |
| `r.Lumen.ScreenProbeGather.IntegrateDownsampleFactor` | off | `2` | Epic: "greatly speeds" integration | noise, softer normals | Yes | [sourced] |
| `r.Lumen.ScreenProbeGather.TracingOctahedronResolution` | ~2 (unclear) | 8-12 | fewer rays | less directional | Yes | [sourced]/[snippet] |
| `r.Lumen.ScreenProbeGather.RadianceCache.ProbeResolution` | not verified | lower | cheaper updates | GI detail | Yes | [sourced] |
| `r.Lumen.ScreenProbeGather.RadianceCache.NumProbesToTraceBudget` | not verified | lower | cheaper | pops on fast camera | Yes | [sourced] |
| `r.LumenScene.Radiosity.UpdateFactor` | not verified | higher | cheaper scene updates | slower response to light change | Yes | [sourced] |
| `r.LumenScene.DirectLighting.UpdateFactor` | not verified | higher | cheaper | slower response | Yes | [sourced] |
| `r.LumenScene.DirectLighting.MaxLightsPerTile` | not verified | lower | cost less sensitive to light count (Epic) | few light artifacts | Yes | [sourced] |
| `r.LumenScene.SurfaceCache.*` (resolution, MeshCardsMinSize) | MeshCardsMinSize 20 [Stray Spark] | larger min size | fewer cards | lower-detail indirect | Possibly restart/ rebuild | [snippet] |
| `r.Lumen.TraceMeshSDFs` | 1 (community) | `0` | unknown | GI detail | Yes | [snippet] |
| `r.Lumen.DiffuseIndirect.Allow` | 1 | 0 | large | see Rejected | Yes | [snippet] |
| `r.LumenScene.FarField` | off [guess] | leave off | Far field costs | none | startup [guess] | [sourced] |
| `sg.GlobalIlluminationQuality` / `sg.ReflectionQuality` | not verified | 1 or 2 | Epic: each lower level costs about half the level above | big. Use as a bundle only | scalability re-apply | [sourced] |

Note: Stray Spark says `r.Lumen.SceneUpdateRayTracingBudget` is not a real shipping cvar. Do not use it.

### Virtual shadow maps

| cvar | Default | Test | Gain | Visual | Runtime | Conf |
|---|---|---|---|---|---|---|
| `r.Shadow.Virtual.SMRT.RayCountDirectional` | 8 | 4 | fewer rays, cost scales | noisier penumbra | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.SMRT.RayCountLocal` | 8 | 4 | same for local lights | noisier local penumbra | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.SMRT.SamplesPerRayDirectional` | 8 | 4 | fewer samples | penumbra detail | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.SMRT.SamplesPerRayLocal` | not stated | 4 | same | same | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.SMRT.RayLengthScaleDirectional` / `MaxRayAngleFromLight` | not stated | lower | penumbra clamp | cap on softness | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.MarkCoarsePagesDirectional` | on | 0 | large per Epic | possible pop | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.MarkCoarsePagesLocal` | on | 0 | same, local | same | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.MarkPixelPagesMipModeLocal` | not stated | 1 or 2 | Epic: fewer mips for local lights, can help non-Nanite | minor | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.ResolutionLodBiasDirectional` | 0 at Epic (conflict: -1.5 forum) | +0.5 | each -1 doubles res; positive cuts | blurrier sun shadow | Yes, hitch | [sourced] direction |
| `r.Shadow.Virtual.ResolutionLodBiasLocal` | set by scalability | +0.5 | same, local | local shadow blur | Yes | [sourced] |
| `r.Shadow.Virtual.ResolutionLodBiasDirectionalMoving` / `...LocalMoving` | scalability | lower | moving lights only | minimal | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.Cache` | on | leave on | caching is the main saver | none | Yes | [sourced] |
| `r.Shadow.Virtual.MaxPhysicalPages` | scalability | do not change | page pool overflow corrupts | none | Only at startup [guess] | [sourced] |
| `r.Shadow.Virtual.NormalBias` | 0.5 | leave | higher = fine detail lost | none | Yes | [sourced] 5.8 |
| `r.Shadow.Virtual.TranslucentQuality` | 0 | leave 0 | high cost for lit translucency | none | Yes | [sourced] 5.8 |
| `r.Shadow.RadiusThreshold` | not stated | raise slightly [guess] | culls small distant non-Nanite casters | small object shadows vanish at distance | Yes | [sourced] 5.8 (name only) |
| `r.Nanite.VSMInvalidateOnLODDelta` | not stated | leave | experimental | | | [sourced] 5.8 |

Do not confuse with `r.Shadow.Virtual.Visualize.*`, which adds cost. Keep them off when measuring.

### Shadows for small objects / contact shadows

| cvar | Test | Note | Conf |
|---|---|---|---|
| `r.Shadow.DistanceScale` | 0.7-0.8 [guess] | shrink shadow draw distance | [guess] |
| `r.ContactShadows` | 0 [guess] | screen-space contact shadows, cheap but visible on small props | [guess] |
| `r.Shadow.MaxResolution` / `r.Shadow.RadiusThreshold` | raise threshold [guess] | culls tiny casters | [guess] |

No Epic or community source was read for these. Treat as guesses.

### Foliage, grass, view distance (all [guess] except where noted)

| cvar | Default | Test | Note | Conf |
|---|---|---|---|---|
| `foliage.DensityScale` | 1.0 | 0.7-0.8 | Editor-side density multiplier; affects foliage instances. | [guess] |
| `grass.DensityScale` | 1.0 | 0.7-0.8 | Grass density; visible in forest floor and fields. | [guess] |
| `grass.CullDistanceScale` | 1.0 | 0.7 | Shorter grass cull. Visible pop-in. | [guess] |
| `foliage.LODDistanceScale` | 1.0 | 0.8 | Community Nexus mention (values not read). | [snippet] |
| `r.ViewDistanceScale` | 1.0 | 0.9 | Global cull distance. Nexus Palworld values do not transfer. | [guess] |
| `r.StaticMeshLODDistanceScale` | 1.0 | 0.8 | Earlier LOD switch. | [guess] |
| `r.SkeletalMeshLODBias` | 0 | 1 | Lower skinned mesh LOD. Visible on NPCs. | [guess] |
| `r.Nanite.Culling.DrawDistance` | 0 (no cap) | leave | Steam reports about 10 fps cost to remove cap. | [snippet] |

Note: the Steam discussion says `r.Nanite.Culling.DrawDistance=0` costs about 10 fps to keep. Our measurements should check whether a cap of, say, 2000 cm is free.

### Post (mostly cheap; test as headroom check, not for fps)

| cvar | Test | Note | Conf |
|---|---|---|---|
| `r.SSR.Quality` | 2 or 3 | SSR cost; Nexus says turn SSR off if water tanks fps. | [snippet] |
| `r.AmbientOcclusion.*` / `r.AmbientOcclusionLevels` | lower | Exact name in 5.3 not verified. | [guess] |
| `r.DepthOfFieldQuality` | 1 | probably negligible in town | [guess] |
| `r.MotionBlurQuality` | 0 | motion blur changes SSIM frame-to-frame; disable for measurement | [guess] |
| `r.BloomQuality` | 3 | low visible | [guess] |
| `r.Tonemapper.Quality` | 2 | cost small | [guess] |
| `r.LensFlareQuality` | 0 | visible on sun, small cost | [guess] |
| `r.SeparateTranslucencyScreenPercentage` | 50-75 | translucency res; visible on glass and smoke | [guess] |

### Volumetrics

| cvar | Default | Test | Gain | Visual | Runtime | Conf |
|---|---|---|---|---|---|---|
| `r.VolumetricFog.GridPixelSize` | 8 (forum) | 12 or 16 | fewer voxels | blocky fog at distance | scalability; forum: runtime change dropped fps 10+ | [snippet] |
| `r.VolumetricFog.GridSizeZ` | 128 (forum) | 96 | fewer depth slices | banding | same | [snippet] |
| `r.LocalFogVolume.RenderIntoVolumetricFog` | 1 | 0 | keeps local fog volumes out | local fog missing | yes | [snippet] |
| `r.VolumetricCloud.*` | not found | | no source found | | | none |

### Nanite and other geometry

| cvar | Default | Test | Gain | Visual | Runtime | Conf |
|---|---|---|---|---|---|---|
| `r.Nanite.MaxPixelsPerEdge` | 1.0 | 1.5-2 | largest single lever per forum | tessellation loss at distance | yes | [snippet] |
| `r.Nanite.PrimaryRaster.PixelsPerEdgeScaling` | 0 | 0.2 | scales MaxPixelsPerEdge up under load (wiki example: 1 to 5) | dynamic detail loss | yes | [snippet] |
| `r.Nanite.ShadowRaster.PixelsPerEdgeScaling` | | | forum says engine may not use it | | | [snippet] |

### Animation (all [guess] unless noted)

| cvar | Test | Note |
|---|---|---|
| `a.URO.Enable` | 1 | update-rate optimisation; NPCs off-screen update less. Shown as on. |
| `a.URO.ForcedRate` / `a.URO.Enable` | leave | |
| `a.ParallelAnimEvaluation` | 1 | CPU side only. |
| Animation budget allocator (`a.BudgetAllocator.*` or similar) | enable | exact name not verified in 5.3 | 

### Water, particles, translucency

- `fx.*` (Niagara): lower particle budget, e.g. `fx.MaxCPUParticlesPerEmitter`. Names not verified.
- Water: no sourced cvars. Overkill's note is to turn SSR off if water is slow (see Post).
- `r.SeparateTranslucencyScreenPercentage` (see Post).

### Oblivion-specific keys

- Community sources list `Altar.` keys for upscaling and frame gen (`Altar.UpscalingMethod`, `Altar.DLSS.*`, `Altar.FSR3.*`, `Altar.Reflex.Mode`) [snippet, Nexus mod search]. None of them is a quality-trade cvar for this rendering path. No `Altar.Scalability` key was found in any source.
- `Altar.ini` holds gameplay values, not rendering.
- Overkill and Nexus Engine.ini guides name no other rendering cvars beyond `r.Lumen.DiffuseIndirect.Allow` and `[ConsoleVariables]`/`[/Script/Engine.RendererSettings]` section headers.

---

## 3. Sweep packs (test first)

Each pack is run as a group, then bisected if it helps. Hold everything else at the same values, use the same spinning-camera spot, and turn off motion blur for the SSIM runs.

### Pack A: Lumen cost (outdoor town, Cheydinhal canal)
- `r.Lumen.Reflections.DownsampleFactor 2`
- `r.Lumen.Reflections.MaxRoughnessToTraceForFoliage 0`
- `r.Lumen.HardwareRayTracing.Reflections.HitLighting 0`
- `r.Lumen.ScreenProbeGather.IntegrateDownsampleFactor 2`
- `r.Lumen.Reflections.MaxRoughnessToTrace 0.3`

Expected: most of the Lumen reflection and probe saving. The canal has water and chrome, so check the water reflection SSIM region.

### Pack B: VSM cost (outdoor town)
- `r.Shadow.Virtual.SMRT.RayCountDirectional 4`
- `r.Shadow.Virtual.SMRT.SamplesPerRayDirectional 4`
- `r.Shadow.Virtual.MarkCoarsePagesDirectional 0`
- `r.Shadow.Virtual.ResolutionLodBiasDirectional 0.5` (test +0.5 only; if it hitches, skip)

Expected: sun shadow cost. Watch NPC and building shadow pop. Run once after a warm-up to avoid the cache-rebuild hitch from (4).

### Pack C: Geometry and foliage (forest spot)
- `r.Nanite.MaxPixelsPerEdge 1.5` (then 2.0 if free)
- `r.Lumen.Reflections.MaxRoughnessToTraceForFoliage 0`
- `grass.DensityScale 0.8` [guess] (unverified)
- `r.StaticMeshLODDistanceScale 0.8` [guess]

Expected: forest is foliage and Nanite heavy. Score fps and SSIM on leaves and grass edges.

### Pack D: Control and headroom (both spots)
- `r.Lumen.ScreenProbeGather.DownsampleFactor 24` (sole change)
- `r.Lumen.ScreenProbeGather.TracingOctahedronResolution 8`
- `r.SSR.Quality 2` [snippet] (only useful if water is an SSR bottleneck)

Expected: measures probe-gather alone, so the winner in Pack A can be separated.

---

## 4. Measurement and hitch notes

- Runtime changes to VSM bias, page pool, volumetric fog grid, and moving-light LOD bias invalidate caches. Expect a one-time hitch or 1-3 frames of cost. Warm up before measuring fps (Epic VSM 5.8 page; forum on VSM runtime changes).
- Volumetric fog grid changes at runtime caused a 10+ fps drop in one forum report [snippet]. Do not change them mid-session.
- Turn off `r.Shadow.Virtual.Visualize.*`, `r.RDG.AsyncCompute` (keep on for normal runs), and any `ShowFlag.Visualize*`. They add cost and skew timings. For clean timings use `r.RDG.AsyncCompute 0` for profiling only.
- Motion blur and temporal effects (TAA, TSR, FSR jitter) make SSIM noisy between runs. Use a fixed camera, and compare the same frame index.
- Epic's Lumen guide states Lumen targets 8 ms at 30 fps and 4 ms at 60 fps at 1080p on consoles, i.e. the default budget is well below our frame cost at 1440p. Expect Lumen to be the largest slice on this card.

---

## 5. Sources

Read in full or fetched successfully:
- Epic, Lumen performance guide for Unreal Engine (UE 5.x docs): https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-performance-guide-for-unreal-engine
- Epic, Virtual shadow maps console variables (UE 5.8 version, read via fetch): https://dev.epicgames.com/documentation/en-us/unreal-engine/virtual-shadow-maps-in-unreal-engine
- Epic, Lumen technical details (only three cvars on that page: `r.LumenScene.FarField`, `r.LumenScene.FarField.MaxtraceDistance` 1 km default, `r.Lumen.Visualize.CardPlacement`): https://dev.epicgames.com/documentation/en-us/unreal-engine/lumen-technical-details-in-unreal-engine
- Stray Spark, "The Lumen Performance Challenge" (author states some listed cvars are not real; use with care): https://www.strayspark.studio/blog/ue5-lumen-optimization-60fps
- Overkill, Oblivion Remastered Steam Deck settings (archive copy; the live URL returned 404): https://archive.overkill.wtf/elder-scrolls-oblivion-remastered-best-settings-steam-deck/

Search snippets or partially read (treat as lower confidence):
- indxzero UE 5.4 CVar wiki, `r.Nanite.MaxPixelsPerEdge` (default 1.0): https://indxzero.github.io/ue544cvarwiki/articles/r.nanite.maxpixelsperedge
- Epic forums, Nanite performance options: https://forums.unrealengine.com/t/nanite-performance-options/2687737
- Epic forums, UE5 Lumen Noise Effect (ScreenProbe downsample cost, 16 vs 8 at 4090): https://forums.unrealengine.com/t/ue5-lumen-noise-effect/621063/15
- Epic forums, Ways to dynamically scale VSM: https://forums.unrealengine.com/t/ways-to-dynamically-scale-vsm-for-flatter-performance/2670416
- Epic forums, Low resolution shadow using VSM (ResolutionLodBias; default -1.5 claim): https://forums.unrealengine.com/t/low-resolution-shadow-using-virtual-shadow-maps/794246
- Epic forums, Volumetric fog artifacts (GridPixelSize tip): https://forums.unrealengine.com/t/volumetric-fog-artifacts/407889/4
- Epic forums, Volumetric fog settings changing during play (runtime fps drop): https://forums.unrealengine.com/t/issue-volumetric-fog-settings-changing-during-play/2685091
- Epic forums, Rough Lumen reflections cheat sheet: https://forums.unrealengine.com/t/rough-lumen-reflections-cheat-sheet/875826
- Steam, Oblivion Remastered discussion with `r.Nanite.Culling.DrawDistance=0` (about 10 fps cost): https://steamcommunity.com/app/2623190/discussions/0/604154270792688727
- Nexus, Oblivion Remastered mod 754 (SSR and ViewDistanceScale comment; page returned 403, search snippet only): https://www.nexusmods.com/oblivionremastered/mods/754
- Nexus, Oblivion Remastered mod 1056 (403, search snippet only): https://www.nexusmods.com/oblivionremastered/mods/1056
- Epic API, `FQualityLevels::SetShadowQuality` (5.3, scale 0 to 4): https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Engine/FQualityLevels/SetShadowQuality?application_version=5.3
- Medium, "Lumen Lighting for Indies" (unsourced numbers; some defaults disputed): https://medium.com/@sarah.hyperdense/lumen-lighting-for-indies-good-results-without-melting-your-gpu-517cfe83c6c7

Not fetched (403, 405, or 404): deltiasgaming.com (405), dafy.site and sportskeeda results (not read), Nexus mods 754, 1056 (403), overkill.wtf live URL (404).

## 6. Open items

1. Read UE 5.3 `Engine/Config/BaseScalability.ini` and `Engine/Config/BaseEngine.ini` for the real defaults (Lumen downsample factors, ResolutionLodBias, MaxPixelsPerEdge). Most of the defaults in this file are unverified.
2. Confirm which of the `[guess]` cvars exist in 5.3 (`r.ContactShadows`, `grass.CullDistanceScale`, `a.BudgetAllocator`, `r.AmbientOcclusion*`) with `help <name>` in the game console before testing.
3. Run the four sweep packs with fps and SSIM, one at a time, then bisect any pack that helps.
