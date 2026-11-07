# OblivionPerfFix on Linux (Steam + Proton)

The fix itself needs nothing Linux-specific. This folder holds the Linux port of the benchmark
(`tools/Run-Benchmark.ps1` + `tools/Bench-Report.ps1`): `bench.py`, a Python 3 script that needs only the standard
library, and `oblivion-launch.sh`, a Steam launch wrapper. The in-game side is the same as on Windows: the OblvBench
UE4SS mod (`mods/ue4ss/OblvBench`) and the scenarios in `bench/scenarios/*.json`, both unchanged.

## Installing the fix

1. Copy `OblivionPerfFix.dll` to `<game>/OblivionRemastered/Binaries/Win64/version.dll` and `OblivionPerfFix.ini`
   next to it (as on Windows).
2. Wine loads its own `version.dll` unless told otherwise. In Steam, *Oblivion Remastered* > Properties > General >
   Launch Options:

   ```
   WINEDLLOVERRIDES="version=n,b" %command%
   ```

3. Start the game; `OblivionPerfFix.log` appears next to the DLL. Uninstall: delete both files (and the launch option).

## Setting up the benchmark

Once:

```sh
python3 linux/bench.py setup     # UE4SS experimental build >= 1181 from UE4SS-RE/RE-UE4SS, SHA-256 checked, into linux/third_party/
python3 linux/bench.py status    # game, prefix, fix, UE4SS, env file
```

Then set the launch option to the wrapper (the absolute path of your checkout), **instead of** the one above:

```
/home/ExtraToast/Projects/oblivion-perffix-linux/linux/oblivion-launch.sh %command%
```

You can leave it like that: without a benchmark env file the wrapper is the normal game with the fix
(`WINEDLLOVERRIDES="version=n,b"`, or whatever `WINEDLLOVERRIDES` Steam already passes). Steam does not need to
restart between runs: `bench.py` writes `~/.config/oblivion-bench/env` just before it asks Steam to start the game
(`steam steam://rungameid/2623190`), the wrapper sources it and exports `WINEDLLOVERRIDES` (`dwmapi=n,b` for UE4SS,
`version=n,b`, or `version=b` for `--fix off`), `MANGOHUD=1`, `MANGOHUD_CONFIGFILE` and the game arguments
(`-FixedSeed`), and `bench.py` deletes the file as soon as the game process is up (and again on exit, Ctrl+C, errors).
The file carries an expiry time (launch timeout + 60 s) so one left behind by a killed runner is ignored.

The game must have been started once by hand through its first-start screens (licence, settings) to the main menu.

## Running

```sh
python3 linux/bench.py list                              # scenarios and profiles
python3 linux/bench.py list --scenario cheydinhal        # its scenes
python3 linux/bench.py run --scenario showcase --fix on --label fix1
python3 linux/bench.py run --scenario cheydinhal --scenes canal-noon,inn-door --fix stock --label s1
python3 linux/bench.py ab --scenario showcase --rounds 2 --a stock --b on --label ic    # stock/fix alternating, then the report
python3 linux/bench.py report --a s1,s2 --b fix1,fix2 --name-a stock --name-b fix       # compare existing runs
python3 linux/bench.py restore [--ue4ss]                 # put back what a killed run left changed
```

Options of `run` / `ab`: `--profile` (bench/profiles.json; default the scenario's, else `small`, an 854x480
window), `--native-res 2560x1440` (what `native` profiles mean), `--start fresh|continue`, `--warmup 60`,
`--keep-ue4ss`, `--show-hud`, `--no-pin`, `--no-fixed-seed`, `--max-minutes`, `--stall-sec`.

`--fix`:
- `on` (or `fix`): the DLL with your `OblivionPerfFix.ini` as installed;
- `stock`: the DLL with every `[Fixes]` switch at 0 except `FrameRateLimitAtStart` (it only makes the game apply
  the saved frame cap, a game bug with FSR frame generation; upstream keeps it on for both sides). Your ini is backed
  up first and put back after the run (also after a crash: the next run or `restore` does it);
- `off`: the DLL not loaded at all (`WINEDLLOVERRIDES=version=b`).

What one run does (as `Run-Benchmark.ps1`'s perf pass): installs UE4SS + the mod into Win64 (every added file in
`run/ue4ss-manifest.json`; removed afterwards unless `--keep-ue4ss`), backs up the rolling saves, the window config
inis and the fix ini, starts the game through Steam, waits for the mod (`LOADED bench.lua`), skips the start-up
videos (`menu`), waits for the mod's frame loop (`ping` driver=frame), starts a new game with `obv coc <startCell>`
from the main menu (no save is loaded; `--start continue` loads the latest save), sets god mode, map markers,
`tdetect`, the scenario's cvars and the profile (read back; FSR/frame-generation cvars pinned by the mod), spectator
mode, waits `--warmup` seconds, then runs each scene: teleport (`tp`, checked arrival), pinned hour/weather/timescale,
settle, then the measured window (static: `measure` s; door: `activate` (or a map fast travel) to arrival plus `hold`;
walk: `walk` until `EV walk=done`; flight: `fly` from `EV fly=start` to `EV fly=done`). Then `quit`, and the game is
ended with SIGTERM/SIGKILL only if it does not exit within 30 s. Everything is put back in a `finally`, with signals
held off until it is done. A watchdog ends the run when the process is gone or `bench-heartbeat.txt` shows no new
frame for 30 s; every wait has a timeout and the run has an overall time limit.

Results: `linux/results/<time>-<label>/` with `result.json`, `report.md`, the MangoHud log (`mangohud/*.csv`) and the
config used; `ab`/`report` write `linux/results/<time>-<label>/report.md` + `report.json`.

## Fast iteration: one spot, live switches

`bench.py spin` starts the game once, goes to one spot and turns the camera in full laps (default 30 deg/s, 12 s per
lap, pitch 0), so streaming, LOD and GPU load repeat the same way every lap. Settings are flipped in the same
session, in ABBA order, and each variant is measured over whole laps. The spots are in
`bench/scenarios/linux-hotspots.json` (worst first, each with the doc section that names it; `list --scenario
linux-hotspots` shows them; it is an ordinary scenario, so `run --scenario linux-hotspots` works too).

```sh
# the canal, ini switches off one at a time (base = the ini as installed is always the first variant)
python3 linux/bench.py spin --scenario linux-hotspots --scene cheydinhal-canal --label canal \
    --variant nopar:ini:RdgParallelTranslate=0 --variant nosub:ini:RdgSubmitBatch=0

# UE console variables through the mod's cvar verb
python3 linux/bench.py spin --scene ic-market-crowd --variant lowvd:cvar:r.ViewDistanceScale=0.6 --laps 3

# any spot: --pos x,y,z --heading H with --world or --cell; slower turn, tilted down, with the HitchLedger split by variant
python3 linux/bench.py spin --pos 117567,-120309,3154 --world Tamriel --heading 350 --hour 17 --weather Rain \
    --deg-per-sec 20 --pitch -5 --variant a:ini:GpuSceneParallelUpload=0 --diag --label pond
```

Per slot: apply the variant (ini keys through `OblivionPerfFix.ini`, then 1.5 s for the DLL's one-second re-read;
cvars set and read back with `get`), turn for `--settle` s (default 4), wait until the spin is at its start heading
again and measure `--laps` whole laps (default 2). `--rounds N` (default 2) repeats forward-then-backward: two variants
give A B B A A B B A. The ini and the cvars are put back at the end (also after an error or Ctrl+C; the file itself
by the same guard as `run`).

What can be flipped: ini keys whose comment in the shipped ini says `Live`, or `Start-up, then live` when the key is on in
the ini the game starts with (it is installed at start-up only if on; flipping it off and on again works). Keys that are
`Start-up only` (and `Takes a restart`), keys that are not in `[Fixes]`, and cvars that the benchmark profile pins are
refused before the game starts. Environment variables (`VKD3D_*`) need a restart: use `run --env` / `ab`.

Results in `linux/results/<time>-spin-<label>/`: `report.md` and `result.json` with, per variant, the median over its
slots of avg fps, 1% / 0.1% low, p99 and max frame time, hitches and GPU/CPU load, the change against `base` (`~` =
under 5 % or the slot-to-slot spread), the avg fps in eight 45-degree heading sectors (N, NE, ... NW; the worst is
named) and every slot's fps range; `heading-timeline.json` holds what was sent to the game. The cinematic camera trails
the heading sent by about 0.3 s (`--cam-lag`), which the sector assignment subtracts. With `--diag`, the HitchLedger rows
are cut by variant window (the ledger's clock is anchored on the two sync stalls) and ranked per variant in
`diag/ledger-<variant>.txt`.

## How the numbers are computed

MangoHud logs every presented frame (`log_interval=0`, `autostart_log=1`, overlay cut down to a small fps counter; `no_display` stops MangoHud from logging):
`frametime` (ms) and `elapsed` (ns since logging began), plus `cpu_load` and `gpu_load`.

**Aligning the log with the scene windows.** The runner records each window with `time.time()`. A frame's wall time
is the log start plus its `elapsed`. The log start comes from, in order of precision:
1. **Sync markers** (used when found): before the warm-up and after the last scene the runner has the mod busy-loop
   the game thread for 350 ms (`lua` verb) and notes when the answer arrives; the matching ~350 ms frame in the CSV
   gives `start = answer time - elapsed of that frame`. Expected error: the answer's latency (the runner polls the
   log every 15 ms) plus the frame or two between the game thread and the present, about +-30 ms; the two markers
   should agree to within that (`frameLog.syncMarkers` in result.json shows each one and its distance from the
   file-name estimate).
2. **The file name** (`<process>_YYYY-MM-DD_HH-MM-SS.csv`, local time, truncated to the second): start in
   [name, name + 1 s), used as name + 0.5 s, +-0.5 s. If the runner saw the file appear within 5 s of the name time it
   caps the upper bound (`firstSeen`); MangoHud may also write the file only at the end, then this does not apply.
3. Recorded for cross-checks: the first heartbeat's wall time (`firstHeartbeat`), the process start
   (`processStart`, from /proc), and the mod clock offset (`modClockOffset`: wall - os.clock() from every answer that
   carries `clock=`) with its spread and rate (`clockRate`, 1.0 if os.clock() is wall time under Wine).
   Flights and walks use the mod's own event clock (`EV fly=start/done`), anchored at the `fly`/`walk` answer.

**Per window** (frames whose wall time lies in it), as `tools/BenchLib.cs`: avg fps = 1000 / mean frame time; 1% low
= 1000 / p99 frame time, 0.1% low = 1000 / p99.9 (percentile = sorted[floor(n x p)]); max frame time; **hitches** =
frames longer than max(2 x the window's median, 40 ms) (upstream's definition), hitch ms = their time beyond the
median; frames over 50 / 100 / 250 ms; the longest gap without a frame; mean CPU and GPU load. Door legs also get
the numbers from arrival to the end.

**A vs B** (`ab`, `report`): per scene the median over each side's runs, the change in percent, `~` under 5 %
(run-to-run noise, as `Bench-Report.ps1`). Alternate the sides (`ab` does) and use 2+ rounds.

## Differences from the Windows benchmark

- **Frame times from MangoHud, not PresentMon.** MangoHud measures at vkd3d-proton's Vulkan present (frame time =
  present to present), so there is no CPU-busy / GPU-busy split, no "GPU-bound %" and no displayed-vs-presented
  distinction; `gpu_load`/`cpu_load` are utilisation percentages. With frame generation, generated frames count, as on Windows.
- **No per-thread CPU sampler** (Game/Render/RHI thread ms, worker cores, I/O, memory, page faults): not ported.
- **No window-hook DLL** (`tools/benchhook`): the game window is on screen and audible, may take the focus when
  it opens, and the NPC conversation guard is missing (a forced greeting can pause the world for the rest of a scene:
  the runner warns when a scene ends in a menu). Don't touch the game while it runs.
- **Warm-up:** upstream waits for the driver's shader compilation (D3D background thread CPU) and the game's PSO
  precompile (read from the game's memory); here a fixed `--warmup` (default 60 s) in the world.
- **No crash recovery:** a crash, hang or stall ends the run (`partial`/`failed`); upstream restarts the game and
  carries on. No visual pass (screenshots, reference images), no `-Stacks`, `-Record`, `-Watch`, `-Session reuse`,
  no parking at the main menu (every run is a fresh game).
- `Save_Settings.sav`'s window entries are not edited (upstream does, in C#): the game opens at your saved size, then
  the profile's `r.SetRes` resizes it.
- **Focus.** GNOME on Wayland gives keyboard focus only to the focused window, but nothing here needs real input or
  focus: the mod injects the game's own input actions in-engine (`activate` and walking inject Enhanced Input actions;
  the comments in `bench.lua` say these work with the window in the background), and moves the camera and pawn
  itself. What focus *does* change: the game turns FSR off when its window loses focus (`bench.lua`: "it turns FSR off
  whenever its window loses the focus") and frame generation stops when it is not in front (docs/benchmark.md). The
  runner pins `r.FidelityFX.FSR3.Enabled` and `r.FidelityFX.FI.Enabled` through the mod (put back within 0.5 s, each
  time counted as a warning) and re-applies the profile before every scene, but with an FSR / frame-generation
  profile (`native`, `small-fg`, `cpu`...) keep the game window focused for comparable numbers. The default `small`
  profile uses neither.
- Wine paths: the deployed `main.lua` gets the repository and runtime folders as `Z:/home/.../` (drive Z: is `/` in
  every Proton prefix; forward slashes and the trailing slash as `Install-UE4SS.ps1` writes them).

## Troubleshooting

| You see | Do |
|---|---|
| `the game was not started through linux/oblivion-launch.sh` | set the launch option (above); `status` shows the env file |
| `no OblvBench mod within 240 s` | UE4SS did not load: check `WINEDLLOVERRIDES` in `run/launch-marker.txt`, and `Win64/ue4ss/UE4SS.log` (kept in `run/ue4ss-logs/` after removal) |
| `no MangoHud log` | MangoHud did not reach the game (inside Steam's runtime container the MangoHud Vulkan layer must be visible; on NixOS e.g. via `programs.steam.extraPackages`/`extraCompatPackages`), check `mangohud.conf` in the run folder |
| `NeedsUser` | start the game once by hand to the main menu |
| a run was killed | `python3 linux/bench.py restore --ue4ss` |

## Building and testing the DLL on Linux

No Windows needed; everything runs through `nix` (clang-cl, lld-link, llvm-ml, xwin, Wine) and never starts the game or Steam.

```sh
linux/build-dll.sh                 # -> build-linux/OblivionPerfFix.dll (PE x86-64; first run fetches the MSVC CRT + Windows SDK with xwin, ~800 MB, into ~/.cache/oblivion-perffix/xwin)
linux/selftest.sh [exe]            # builds tests/selftest.cpp with the same toolchain and runs it under Wine against the installed exe (read-only); exit != 0 on any FAIL or crash
linux/dev-cycle.sh                 # build -> self-test
linux/dev-cycle.sh --bench --scenario showcase [--scenes a,b] [--rounds 2] [--ini PATH]   # ... -> bench A/B: installed DLL vs the built one
```

`selftest.sh` runs headless (no `DISPLAY`, Wine's display drivers disabled, crash dialog off) in a throwaway prefix
(`~/.cache/oblivion-perffix/wineprefix`, `OPF_WINEPREFIX`); it uses `wine` from `PATH`, else nixpkgs' `wineWow64Packages.stable`.
Its console output is `build-linux/test/selftest.out.log` (the DLL's own log: `selftest.log`). Wine does not relocate an exe mapped with `LoadLibraryEx`, so the self-test
is linked at `/BASE:0x1C0000000` to leave the game exe its preferred base (0x140000000); without that every scan of
`.rdata` pointers fails.

Benchmarking a built DLL without installing it:

```sh
python3 linux/bench.py run --scenario showcase --dll build-linux/OblivionPerfFix.dll [--dll-ini my.ini] --label try1
python3 linux/bench.py ab  --scenario showcase --a on --b dll:build-linux/OblivionPerfFix.dll --rounds 2 --label try
```

`--dll` backs up the installed `version.dll` (and `OblivionPerfFix.ini` with `--dll-ini`) through the same file guard as the
ini and window config, installs the given files for that run, and puts both back afterwards, also after Ctrl+C or a
crash (the next run or `bench.py restore` repairs a killed one). Without `--dll-ini` your installed ini stays. The DLL's
SHA-256 is in `result.json` under `dll` (`{"path", "sha256", ...}`; for a run without `--dll` it is the installed
`version.dll`, with `"installed": true`). In `ab`, a side is `on`, `stock`, `off` or `dll:PATH[@stock]`; a DLL side is
named `dll-<sha8>` in the labels and the report. `--dll` with `--fix off` is refused.
