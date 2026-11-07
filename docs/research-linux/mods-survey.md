# Oblivion Remastered: performance / stutter / pop-in mods and tweaks survey

Date of research: 2026-11-07. Scope: web search only, no local files changed.

**Verification limits.** Nexus Mods pages returned HTTP 403 to WebFetch, and the ProtonDB page came back empty. Nexus rows below are therefore built from search-result snippets and secondary press, not from the Nexus permissions tab. Licence and redistribution status is marked "unverified" wherever it was not read directly. The only licence read directly is OblivionPerfFix (MIT, from its GitHub page). Search returned no results for several requested items (Special K, NTSync, Anti-Lag 2, dedicated NPC pop-in/LOD mods, vkd3d-proton tuning for this title, PCGamingWiki), and those are listed as "not found" rather than guessed.

## Main table

| Mod / tweak | Author | URL | Licence / permissions | What it changes | Claimed effect | Linux / Proton | Conflicts with OblivionPerfFix |
|---|---|---|---|---|---|---|---|
| OblivionPerfFix (LTSharpe) | LTSharpe | https://github.com/LTSharpe/OblivionRemasteredPerformanceFix | MIT, source in repo (read directly on GitHub page) | `version.dll` proxy + `OblivionPerfFix.ini` in `Binaries\Win64\`; OBSE64 variant; WinGDK files for Game Pass. Runtime in-memory patches, no game files modified. Includes Lumen, upload and GPU-scene memory fixes, and a shader-screen fix. | Test PC (5800X, RX 9070 XT, 4K FSR Perf): Imperial City flight with FG 72→102 fps, hitches 19.5→4.8 per flight; Cheydinhal 55→63 fps, 1% low 26→43. Gains are CPU-limit dependent. Per-page claims, not independently verified. | Partial. One CachyOS user reports it works using Windows files. Steam Deck "untested, please report". Needs launch option `WINEDLLOVERRIDES="version=n,b" %command%`. `SharedMemoryGpu` leaves Proton/Wine alone. | (is the baseline) |
| Ultimate Engine Tweaks (UET) | P40L0X | https://www.nexusmods.com/oblivionremastered/mods/35 (search result: https://nexusmods.com/oblivionremastered/mods/35) | Unverified (Nexus 403). Permissions tab not read. | Replacement `Engine.ini` (Saved\Config\Windows, or WinGDK for Game Pass). Includes streaming pool tuning (user suggests pool = VRAM minus ~2048 MB). Author warns against mixing with other optimisation ini mods. | Mixed. Some users say it fixes most random stutter. VideoGamer (citing Digital Foundry) and GamesRadar A/B tests say it is placebo. Source: https://www.videogamer.com/news/oblivion-remastered-most-popular-performance-mod-is-actually-all-placebo and https://www.gamesradar.com/games/the-elder-scrolls/some-players-swear-by-it-but-oblivion-remastered-test-finds-that-performance-mod-with-650k-downloads-seemingly-does-next-to-nothing-after-testing-it-a-b-it-runs-the-same | Ini-only, so OS-agnostic in principle. No Linux report found. | Overlaps: both swap `Engine.ini`, and the LTSharpe page itself says "Engine.ini tweak packs: unclear (two reports of problems with one installed)". Treat as conflict. |
| Lumen Begone | HerrTiSo | Not fetched. Referenced at https://www.nexusmods.com/oblivionremastered (search snippet source: https://www.nexusmods.com/oblivionremastered/mods/35 context, and https://steamcommunity.com/app/2623190/discussions/0/604154444533296655) | Unverified | Engine.ini that disables Lumen at engine level. Bundles UET tweaks, so it replaces the UET ini. | One report: up to 39% gain. Warns that disabling Lumen fully may cause flickering shadows on small bushes/grass. | Ini-only. No Linux report found. | Yes: bundles UET content, and LTSharpe's fix already contains a Lumen fix. Stacking may double-apply or fight. Test individually. |
| Luxury Visuals - TSO | Not confirmed from snippet | https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs | Unverified | `.pak` with core engine INIs; sets `r.Streaming.PoolSize=4096`; raises texture pool. Overwrites core configs. | Targets texture pop-in from Virtual Texturing. | Pak + ini, no Linux report found. | Yes: overwrites core config files and is incompatible with other mods that change those files. |
| Mod 399: Dynamic Texture Streaming Cap | Not confirmed | https://nexusmods.com/oblivionremastered/mods/399 | Unverified | Caps texture pool to a percentage of VRAM to avoid OOM. | Stability (OOM) rather than speed. | Unknown. | Likely conflicts with any fixed `PoolSize` setting. |
| Mod 962: streaming pool presets | Not confirmed | https://nexusmods.com/oblivionremastered/mods/962 | Unverified | Presets setting streaming pool to 70–80% VRAM, temp memory capped (low/mid PCs). | Not stated. | Unknown. | Same Engine.ini conflict class. |
| Optimized Tweaks OBLR | Not confirmed | https://www.nexusmods.com/oblivionremastered/mods/79 | Unverified | `.pak` (not ini). A user warns it is incompatible with engine.ini mods. | Not stated in snippets. | Pak-based, Linux not reported. | Yes per user report: remove any modded Engine.ini first. |
| OptiScaler (for DLSS/FSR FG on non-40-series) | Not confirmed | Mentioned on https://www.nexusmods.com/oblivionremastered/mods/3191?tab=posts and https://www.nexusmods.com/oblivionremastered/mods/3293 (snippets; not fetched) | Unverified (OptiScaler itself is a separate project; licence not checked) | Upscaler/FG injection DLL. One user reports Game Pass install trouble on 2080 Ti. | Anecdotal: one user says a Lumen-disabling mod plus OptiScaler plus nukem's dlssg-to-fsr3 works better than UET. No official guidance found. | Not found. Proton/DXGI-proxy DLL setups are often workable but unverified here. | Uses `dxgi.dll`/`version.dll`-style proxies. Check for clash with `version.dll` proxy of OblivionPerfFix (LTSharpe page notes upscaler mods using `version.dll` conflict). |
| Ultra+ (sammilucia) | sammilucia | Not located on Nexus in search. Coverage: https://wccftech.com/oblivion-remastered-seems-to-be-rather-well-suited-to-mods-and-one-of-them-adds-ray-reconstruction/amp/ | Unverified | Visual-quality mod (fog, lighting, reflections, DLSS Ray Reconstruction). | Visual quality, not performance. Not a stutter/pop-in fix. | Not found. | Not assessed. Not a perf tool, so low conflict risk with a DLL fix, but check for shared DLLs. |
| UE4SS-based mods | n/a | Not found | n/a | Not found in search. | n/a | n/a | n/a |
| Special K | n/a | Not found as an Oblivion Remastered recommendation. Only a Nexus thread advising "force Auto Exposure through Special K or DLSSTweaks" and "force Reflex through Special K" (no URL resolved). | n/a | Would be a DLL hook. | Reflex forcing reported as more reliable than native Reflex. | Not found. | Likely conflicts with `version.dll` proxies, since Special K uses dxgi/d3d hooks. Unverified. |
| Reflex / Anti-Lag 2 frame-pacing mods | n/a | Steam discussions only (https://steamcommunity.com/app/2623190/discussions/0/604154444533232256). Reflex "Boost" reported to force max GPU clocks; plain "On" recommended. | n/a | Setting, not a mod. | Anecdotal. | Not found. | None known. Anti-Lag 2 not found for this title. |
| Remove streaming pool limit | n/a | Not found as a standalone mod. Closest: Luxury Visuals TSO and mod 399 above. | n/a | n/a | n/a | n/a | n/a |
| NPC pop-in / LOD mods | n/a | Not found for Remastered. Pop-in discussion is texture-based (Luxury Visuals TSO page). The NPC "no pop-in" fix found was for the 2006 original game, not Remastered. | n/a | n/a | n/a | n/a | n/a |
| Proton env vars (ProtonDB / Steam discussions) | community | https://www.protondb.com/app/2623190 (not readable); https://steamcommunity.com/app/2623190/discussions/0/604154725799035354 | n/a | Launch options reported: `gamemoderun %command%`; `MESA_VK_WSI_PRESENT_MODE=immediate %command%` (Steam Deck frame pacing report); `VKD3D_CONFIG=dxr VKD3D_FEATURE_LEVEL=12_3 VKD3D_SHADER_MODEL=6_7 %command%` (Linux Mint crash fix, slow launch). Esync/fsync disabling mentioned in ProtonDB entries. | Anecdotal. | Yes (Linux-specific). | `WINEDLLOVERRIDES="version=n,b"` is required for LTSharpe's `version.dll` route, so it must not be combined blindly with other proxy DLLs. |
| vkd3d-proton / NTSync | n/a | https://www.gamingonlinux.com/2025/11/vkd3d-proton-3-0-brings-fsr4-support-shader-backend-rewrite-lots-of-bug-fixes-and-performance-upgrades/page=1/ (general vkd3d, not title-specific). NTSync: not found. | n/a | No title-specific vkd3d tuning found. An older NVIDIA forum thread reports up to 30% vkd3d performance hit on Nvidia (anecdotal): https://forums.developer.nvidia.com/t/directx12-performance-is-terrible-on-linux/303207?page=2 | n/a | Not found for this title. | n/a |
| gamescope | n/a | Not found as an Oblivion Remastered recommendation. | n/a | n/a | n/a | n/a | n/a |
| Frame generation / stutter (Bethesda) | Bethesda | Press context: https://www.dsogaming.com/mods/this-oblivion-remastered-mod-will-greatly-reduce-its-stutters | n/a | Reports Bethesda is looking at a patch for frame pacing/stutter. | n/a | n/a | n/a |

## Notes

1. **Engine.ini is a single-owner file.** UET, Lumen Begone, Optimized Tweaks (pak, incompatible per user), and the TSO pak all touch the same config space. Only one of these should be active at a time. Back up the original before any test.
2. **LTSharpe's fix is the only item here with a verified permissive licence (MIT)**, which makes it the easiest candidate to integrate or reference with attribution. Re-check the repository LICENSE file before any copying.
3. **`version.dll` is contested.** LTSharpe's fix, OptiScaler-style proxies, and possibly Special K all use proxy DLL names. Only one proxy can own `version.dll`; use `WINEDLLOVERRIDES` carefully and check which proxy each mod ships.
4. **Lumen.** LTSharpe's fix has its own Lumen fix, and Lumen Begone is an ini equivalent. If both are used, the ini can override the DLL's behaviour unpredictably.
5. **Evidence quality is weak.** Most claimed gains are single-PC or single-user anecdotes. The strongest independent evidence is the negative A/B result on UET (VideoGamer / GamesRadar).
6. **Items not searchable:** Special K setup, UE4SS mods, NTSync, gamescope, Anti-Lag 2, dedicated NPC LOD mods, PCGamingWiki page. A follow-up with Nexus access (or a browser) is needed for their permissions and file details.

## Five most promising candidates for integration

1. **LTSharpe's OblivionPerfFix** (https://github.com/LTSharpe/OblivionRemasteredPerformanceFix). MIT-licensed, in-memory patching, documented CPU-bound gains, and it already handles the Lumen and memory issues. It is the project this survey is for, so integration is natural, with attribution.
2. **Lumen-disable approach (Lumen Begone idea)** (https://steamcommunity.com/app/2623190/discussions/0/604154444533296655). Largest single anecdotal gain (up to 39%). Worth reproducing as a documented option rather than shipping a bundled ini, because licence is unverified and it overlaps with OblivionPerfFix's Lumen fix.
3. **Streaming pool tuning** (UET ini guidance, https://www.nexusmods.com/oblivionremastered/mods/35; TSO pak, https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs). Pool sized to VRAM is the most mechanistically plausible explanation for texture stutter, and is simple to expose as a config value rather than a whole ini replacement.
4. **Proton launch-option set** (ProtonDB / Steam threads, https://steamcommunity.com/app/2623190/discussions/0/604154725799035354). Linux-specific and cheap to document: `WINEDLLOVERRIDES="version=n,b" %command%` for the fix, `MESA_VK_WSI_PRESENT_MODE=immediate` for frame pacing on Mesa, and VKD3D feature-level overrides if the crash-on-launch case shows up.
5. **Reflex "On" (not Boost) plus Special K forcing** (https://steamcommunity.com/app/2623190/discussions/0/604154444533232256). Frame-pacing relevant for input latency. Special K was not verified, so treat as a research lead, not a tested recommendation.

## Source list

- https://github.com/LTSharpe/OblivionRemasteredPerformanceFix
- https://www.nexusmods.com/oblivionremastered/mods/35
- https://nexusmods.com/oblivionremastered/mods/35
- https://www.nexusmods.com/oblivionremastered/mods/1129 (fetch returned 403; not used)
- https://www.nexusmods.com/oblivionremastered/mods/79
- https://www.nexusmods.com/oblivionremastered/mods/3031?tab=docs
- https://nexusmods.com/oblivionremastered/mods/399
- https://nexusmods.com/oblivionremastered/mods/962
- https://www.nexusmods.com/oblivionremastered/mods/3191?tab=posts
- https://www.nexusmods.com/oblivionremastered/mods/3293
- https://www.videogamer.com/news/oblivion-remastered-most-popular-performance-mod-is-actually-all-placebo
- https://www.gamesradar.com/games/the-elder-scrolls/some-players-swear-by-it-but-oblivion-remastered-test-finds-that-performance-mod-with-650k-downloads-seemingly-does-next-to-nothing-after-testing-it-a-b-it-runs-the-same
- https://steamcommunity.com/app/2623190/discussions/0/604154444533296655
- https://steamcommunity.com/app/2623190/discussions/0/604154444533232256
- https://steamcommunity.com/app/2623190/discussions/0/604154725799035354
- https://www.protondb.com/app/2623190 (not readable)
- https://www.gamingonlinux.com/2025/11/vkd3d-proton-3-0-brings-fsr4-support-shader-backend-rewrite-lots-of-bug-fixes-and-performance-upgrades/page=1/
- https://forums.developer.nvidia.com/t/directx12-performance-is-terrible-on-linux/303207?page=2
- https://wccftech.com/oblivion-remastered-seems-to-be-rather-well-suited-to-mods-and-one-of-them-adds-ray-reconstruction/amp/
- https://www.dsogaming.com/mods/this-oblivion-remastered-mod-will-greatly-reduce-its-stutters
- https://en.uesp.net/wiki/Oblivion:Linux (surfaced in search, not read)
