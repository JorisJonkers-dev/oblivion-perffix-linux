# Content (asset) modding of Oblivion Remastered for GPU performance on Linux

Date: 2026-11-07. Research only: nothing downloaded, installed or run; no pak files read.
Caveat on sources: nexusmods.com returns HTTP 403 to our fetcher, so Nexus claims below come from
search-result snippets of the cited pages (not read in full). Marked [snippet]. Speculation is marked [SPEC].

## Verdict

CONDITIONAL NO-GO as a first line of attack; GO only for a small, time-boxed probe.
- Mechanically feasible: the community already edits cooked assets with retoc + UAssetGUI and ships .pak/.utoc/.ucas
  from ~mods. The Rust tools (retoc) run natively on Linux; UAssetGUI/UAssetAPI is .NET (Wine or dotnet).
- But no existing mod demonstrates a performance gain from property-edited meshes/foliage. Known perf mods are
  Engine.ini/cvar packs or a runtime DLL, not content edits (section 2). The strongest public GPU-bound data point
  (LTSharpe) says Foliage and View Distance cost the GPU little on its test PC, which undercuts the foliage/clutter hypothesis.
- Cheaper, reversible alternative to try first: cvars (r.Shadow.Virtual.*, Lumen/RT, Nanite) via a pak-shipped or
  user Engine.ini/ConsoleVariables. Content edits only if the profile shows shadow-depth/Nanite/VSM time driven by small clutter.

## 1. Toolchain

| Step | Tool | Linux | Licence | Source |
|---|---|---|---|---|
| Unpack IoStore (.utoc/.ucas) to legacy .uasset/.uexp | retoc (`to-legacy`, `unpack`) | Rust CLI, should build natively (README lists no platform; examples use Windows) | MIT | https://github.com/trumank/retoc |
| Browse/preview/export assets | FModel | Windows .NET app; no Linux build mentioned (Wine or skip) | GPL-3 | https://github.com/4sval/FModel |
| Edit properties of cooked .uasset | UAssetGUI / UAssetAPI | .NET; README documents running under Wine (dotnetdesktop10, 8 for v1.1.0-) ; CLI `UAssetGUI tojson <src> <dst> <engine ver e.g. 5.3> [mappings]` / `fromjson <src> <dst> [mappings]` (JSON round trip, binary-equality preserved, `VerifyBinaryEquality()`) | MIT | https://github.com/atenfyr/UAssetGUI , https://github.com/atenfyr/UAssetAPI |
| Repack to IoStore | retoc `to-zen <dir> out.utoc --version UE5_3` | native (Rust) | MIT | https://github.com/trumank/retoc ; usage with UE5_3 cited in the Nexus UniMerger article https://www.nexusmods.com/oblivionremastered/articles/227 [snippet] |
| Legacy .pak only | repak (pack/unpack/list; no IoStore; writing has no compression/encryption) | Rust CLI | Apache-2.0 / MIT | https://github.com/trumank/repak |
| Generate .usmap | UE4SS USMAP dumper (runs inside the game; no native Linux build, would run under Proton) | in-game | MIT | https://github.com/UE4SS-RE/RE-UE4SS |

Notes
- retoc README: UE 5.3+ "well supported", whole games convertible to .pak; same version/overrides must be used when repacking. MIT. https://github.com/trumank/retoc
- Community bundle "Oblivion Remastered Mod Tools (retoc and uAssetGUI)": ships retoc, UAssetGUI, batch files, oo2core.dll; says UAssetGUI needs a mappings .usmap (FModel can supply it); says FModel does not export .uexp from .utoc so use retoc to extract; occasional "Failed to Parse x Exports" errors; retoc updated to pack .ubulk, use a current build. https://www.nexusmods.com/oblivionremastered/mods/3918 [snippet]
- Other authors list FModel (extraction), Retoc (repack), UAssetGUI (edit), xEdit (ESP), sometimes UE 5.3.2 for final pak builds [snippet, search result for https://www.nexusmods.com/oblivionremastered/mods/4232 and /4326].
- AES key: I found NO source stating the paks are encrypted or giving a key. All community workflows (retoc/UAssetGUI) mention none, which suggests unencrypted [SPEC]. Verify with `retoc list`/`info` on a copy (read-only metadata) before anything else.
- Mappings: a .usmap is needed for unversioned properties; community says FModel/UAssetGUI use one (mods/3918 above). Where to get it: community bundles on Nexus or generate with UE4SS USMAP dumper. Exact current availability not verified.
- Free alternative to the GUI: UAssetAPI as a library from a small .NET script, scriptable for bulk edits [SPEC on 5.3 cooked IoStore-derived assets; README claims support ~4.13 to 5.7 and warns some assets fail binary equality]. https://github.com/atenfyr/UAssetAPI

Tools that would need downloading: retoc (Rust build or release binary), UAssetGUI CLI or UAssetAPI (+ .NET 8/10 SDK/runtime; Wine unnecessary if using dotnet on Linux with UAssetAPI as a library [SPEC]), a .usmap. FModel and repak optional. UE4SS only if we must generate our own .usmap.

## Pak / IoStore conventions for this game

- Folder: `OblivionRemastered/Content/Paks/~mods` (Nexus Vortex extension README). https://github.com/Nexus-Mods/game-oblivionremastered
- Keep .pak + .utoc + .ucas together as one mod (the IoStore data lives in utoc/ucas; the .pak is a small stub). https://fmtweak.com/how-to-install-oblivion-remastered-mods/
- Name: one source says mods must end in `_P` to be loaded [snippet, Nexus forum thread https://forums.nexusmods.com/topic/13514000-unpacking-packing-pak-files-and-sound-replacement-guide-for-oblivion-remastered/page/2/]; CurseForge Denser Foliage says put the `_P.pak` in ~Mods https://www.curseforge.com/oblivion-remastered/mods/denser-foliage . Another Nexus tools page says mods should go in Paks (not ~mods) with names alphabetically lower than the game paks (e.g. 000_Mod) [snippet, mods/3918]. Conflicting advice: test both empirically.
- Priority: paks load in reverse alphabetical order, so name decides conflicts (fmtweak link). Vortex cannot sort paks.
- Blueprint/logic mods that use UE4SS go in `Paks/LogicMods` (not needed for pure asset overrides); one mod warns UE4SS has issues with events and actor spawning [snippet, mods/4232 area].
- Asset-override mods must reproduce the same asset path/package name as the original, with retoc `to-zen` output containing only modified packages [SPEC, standard UE mod practice; consistent with retoc README].

## 2. Existing performance-related mods

- Ultimate Engine Tweaks (Nexus 35): Engine.ini tweaks, shipped by some as a simple pak with config; GamesRadar A/B test reported it "does next to nothing" (650k downloads). https://www.nexusmods.com/oblivionremastered/mods/35 [snippet]; https://www.gamesradar.com/games/the-elder-scrolls/some-players-swear-by-it-but-oblivion-remastered-test-finds-that-performance-mod-with-650k-downloads-seemingly-does-next-to-nothing-after-testing-it-a-b-it-runs-the-same (headline/excerpt only read; numbers not seen).
- Low-end pack with Smooth/No Shadows Engine.ini variants and ConsoleVariables.ini that forces no shadows: https://www.nexusmods.com/oblivionremastered/mods/962 [snippet]. Cvar-based, no content edits.
- Foliage quality +1 over Ultra: reported 1-3 FPS cost vs Ultra on 7800X3D/4090 [snippet]. https://www.nexusmods.com/oblivionremastered/mods/2124
- A pak-delivered config mod overriding DefaultDeviceProfiles.ini, DefaultEngine.ini, WindowsScalability.ini ("use at your own risk") [snippet from search; mod page not identified]. Demonstrates config-in-pak works.
- Steam tip: `r.Nanite.Culling.DrawDistance=0` extends foliage distance at a cost of about 10 FPS (user anecdote). https://steamcommunity.com/app/2623190/discussions/0/604154270792688727 [snippet]. Implies Nanite culling distance is a real lever the other way.
- Denser Foliage (CurseForge, _P.pak in ~Mods): property/asset-level change, increases cost. https://www.curseforge.com/oblivion-remastered/mods/denser-foliage
- LTSharpe OblivionRemasteredPerformanceFix (MIT; version.dll + INI; Claude-assisted; ~40 engine-level changes): runtime DLL, "game files are never modified"; claims up to +37% mostly in CPU-bound towns; "where the graphics card is the limit the gain is smaller or none"; on its 4K test PC Foliage and View Distance cost the GPU little; advice: lower upscaler mode, then hardware RT, then GI and Reflections first. Works on CachyOS/Proton with `WINEDLLOVERRIDES="version=n,b" %command%`. https://github.com/LTSharpe/OblivionRemasteredPerformanceFix , wiki https://github.com/LTSharpe/OblivionRemasteredPerformanceFix/wiki , coverage https://overclock3d.net/news/software/oblivion-remastered-mod-claims-37-fps-boost-with-ai-code/
- I found NO mod that lowers static mesh cull distance, removes foliage/clutter shadow casting, or trims LODs by property edit, and no texture downscale mod with reported fps data (searches for these returned nothing; this is absence of evidence).

## 3. Signature checks, UE4SS, patch fragility

- No source mentions pak signature enforcement or a bypass; dozens of public pak/utoc/ucas mods load from ~mods with no bypass (installation instructions above). Treat signing as NOT enforced; Bethesda says mods are "not officially supported" https://help.bethesda.net/app/answers/detail/a_id/69672 .
- UE4SS: independent of asset paks (dwmapi.dll in Binaries/Win64; Lua in ue4ss/Mods) https://fmtweak.com/how-to-install-oblivion-remastered-mods/ . Pure asset overrides do not need it. Native Linux builds of UE4SS unsupported; under Proton the Windows DLL is used (https://github.com/UE4SS-RE/RE-UE4SS). Conflicts arise only for LogicMods/blueprint spawning (see above).
- Fragility [SPEC]: overridden assets are full replacements; any game patch that changes the same package invalidates or silently reverts our copy, so scripts must regenerate from the installed game at each patch (script the pipeline rather than ship static assets). retoc `--override-container-header-version/--override-toc-version` is needed if the game's IoStore version differs.

## 4. First experiment (hypothesis, low confidence)

Important structural caveat [SPEC]: Oblivion Remastered keeps the original Gamebryo/Oblivion engine running world logic and spawns UE actors from it (hence "SyncMap" and ESP-driven placement mentioned by modders). If so, per-instance flags (CastShadow, cull distance) are not in level .umap files but come from per-mesh/per-type defaults, so edits must be at mesh-asset or blueprint-component-default level, and the number of editable assets is bounded by distinct meshes, not instances. Verify by inspecting one exterior static-mesh blueprint with UAssetGUI before committing.

Candidate A (smallest risk): disable dynamic/VSM shadow casting on small clutter and foliage.
- Select: bulk script via UAssetAPI over retoc-unpacked exterior folders; filter by mesh bounds (small, e.g. bounding sphere radius under ~60 uu) and category path (grass, plants, flora, clutter, rocks small). Set CastShadow=false / bCastDynamicShadow=false (on blueprint components) or mesh-level equivalents.
- Expected count: unknown; thousands of packages touched is plausible, no mod gives a number [SPEC]. A first batch of a few hundred flora meshes is enough for a signal.
- Why plausible: VSM/Nanite shadow-depth cost scales with casters; small casters add little visible shadow. Why risky: LTSharpe found foliage/view distance cheap on GPU, so the gain may be under 5% [SPEC].

Candidate B: shorter draw distance (Nanite/LD max draw distance) on small props; same selection, set LDMaxDrawDistance / cull distance fields where present on cooked meshes [SPEC that these properties survive cooking and are honoured for Nanite meshes; note the opposite cvar r.Nanite.Culling.DrawDistance is a known lever].

Measurement plan:
1. Control experiment first with cvars only (e.g. r.Shadow.Virtual.* bias, no shadow on foliage via cvars if available) to know the upper bound without any content work. If cvars alone give less than 5%, content edits will not rescue it.
2. Spin benchmark A/B/A, fixed seed, SSIM on screenshots, verify the pak loads (diff on a deliberate visible change first, e.g. one distinctive mesh hidden).
3. Go criterion: at least 5% frame-time gain with SSIM above agreed threshold; else stop.

## 5. Licence and redistribution

- Personal use: Bethesda says mods are not officially supported; no ban, and no support when mods are present. https://help.bethesda.net/app/answers/detail/a_id/69672 ; https://www.gamesradar.com/games/action-rpg/bethesda-says-mods-are-not-supported-for-the-elder-scrolls-4-oblivion-remastered-despite-its-pro-mod-history
- I did not find a published Bethesda modding policy specific to this game (no Creation Kit/Bethesda.net support). The general Bethesda Game Content/Creation Club terms were not read; not verified.
- Publishing scripts (extract, patch property, repack) with no game data: lowest risk; tool licences are MIT / Apache-2.0+MIT / GPL-3 (FModel only needed as a viewer, not linked). LTSharpe's MIT DLL contains no game files https://github.com/LTSharpe/OblivionRemasteredPerformanceFix .
- Publishing modified assets: they are derivative of Bethesda/Virtuos content; community practice on Nexus is to publish them (Nexus hosts many pak mods), but legal status unverified [SPEC]. Safer: publish the script plus a binary-diff-free recipe, and let users generate the pak from their own install.
