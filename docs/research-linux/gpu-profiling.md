# Per-pass GPU profiling under Proton / RADV

Goal: where the GPU spends its time (Lumen, VSM, Nanite, base pass, post, FSR ...) at a GPU-bound spot, on
Mesa RADV 26.2.6, RX 7900 XTX, vkd3d-proton in Proton Experimental 11.0. Tags: [TESTED] ran on this machine, [SOURCE] read in
the Mesa / vkd3d-proton source, [UNVERIFIED] not run.

## Recommendation

Use Mesa's **u_trace "ranges" mode** with a RADV rebuilt from the same nixpkgs Mesa (26.2.6) with `-Dradv-u_trace=true`. It writes
a CSV with a GPU timestamp at begin and end of every draw, dispatch, barrier, render pass and command buffer; `tools/gpuprof/utrace_report.py`
turns that into ranked tables. Nothing is named (see "Names" below) but every row carries the RADV pipeline hash, the render
area and the dispatch grid, which identifies UE passes well. RGP is the fallback (works on the stock driver, needs the GUI).

## What each option gives on this machine

| # | Option | Status | Output |
|---|---|---|---|
| a1 | **u_trace ranges** (`MESA_VK_TRACE=ranges`) | [TESTED] natively with vkcube on this GPU; not yet in the game. The stock nixpkgs driver has the code compiled out: it prints `radv: warning: u_trace enabled but radv-u_trace was not enabled for the build` and writes nothing [TESTED]. Needs the custom build below. | per draw/dispatch/barrier/rendering begin+end ns, pipeline hash, grid, render area |
| a2 | RGP thread trace (`MESA_VK_TRACE=rgp`) | [TESTED] works on the stock driver (vkcube: 2.8 MB `.rgp` in `/tmp`). Also `MESA_VK_TRACE_FRAME=N`, `MESA_VK_TRACE_TRIGGER=<file>` (touch it), F1 on X11; `RADV_THREAD_TRACE_BUFFER_SIZE`, `_INSTRUCTION_TIMING`, `_CACHE_COUNTERS`, `_QUEUE_EVENTS`; `MESA_VK_TRACE_PER_SUBMIT`. | `.rgp`; per-event times come from the SQTT bitstream. No open-source CLI decoder found (web search found none; rocprof-trace-decoder is a closed binary). nixpkgs has `rgp` 2.7.1 but it is unfree (`NIXPKGS_ALLOW_UNFREE=1`, AMD's own binary, your call). Without it the file is only useful in the Windows/Linux RGP GUI. No pass names either (the UE shipping build emits no markers). |
| b | vkd3d-proton env vars | `VKD3D_QUEUE_PROFILE`/`_ABSOLUTE` exist in Proton's d3d12core.dll [TESTED, strings]: a submission/queue timeline, not per pass. `VKD3D_PROFILE_PATH` is CPU-only and needs a profiling build. `VKD3D_TIMESTAMP_PROFILE` (per-PSO GPU time keyed by D3D12 PSO and shader hashes) is in the vkd3d-proton source (and nixpkgs 3.0.1) but only compiled with `-Denable_profiling=true`; **Proton Experimental 11.0 and GE-Proton 11-7/11-11 do not contain it** [TESTED, strings]. My nix mingw cross-build attempt (`pkgsCross.mingwW64.vkd3d-proton` with `-Denable_profiling=true`) failed in nixpkgs' mingw cross set (an i686 evaluation error; not pursued) and is not working. Breadcrumbs/markers need non-release builds. | not usable as is |
| c | UE's own profiler through the UE4SS mod (`ProfileGPU`, `stat gpu`, `r.GPUStatsEnabled`, `r.ProfileGPU.*`) | [UNVERIFIED, from UE 5.3 knowledge] GPU stats and `ProfileGPU` are compiled under `WITH_PROFILEGPU`, which is off in Shipping and Test; RDG events (`r.RDG.Events`) and the D3D12 PIX/debug markers go the same way. Expect "unknown command" / empty output. Cheap to confirm: run `ProfileGPU` and `stat gpu` via the mod's exec verb once and look at the log. Even if a variant works it would not put names into the Vulkan stream. | probably none |
| d | Timestamps from the DLL around RDG pass execution | Design only. The DLL already detours the RDG translate path (`src/render/parallel_translate.cpp`). Per pass: `FRDGBuilder` pass lambdas run on the render thread / translate workers against an RHI command list; insert `RHICmdList.EndRenderQuery` / `WriteGPUTimestamp` pairs (needs the RHI vtable of `FRHICommandList` and a timestamp query pool wrapper) around each pass, name from the `FRDGPass` (`GetName()`, present in Shipping since RDG keeps pass names for the `FRDGBuilder` validation off? **[UNVERIFIED]** whether names survive). Gives true names but needs engine struct offsets for 5.3 Shipping, a per-pass drain/readback, and several days of work. Do this only if the u_trace table cannot be mapped to passes. | named passes, if names survive |

## Build the driver (once, ~2 min)

```
linux/gpuprof.sh build        # -> ~/.cache/oblivion-bench/gpuprof/mesa  (gc root), RADV only, 64-bit only
linux/gpuprof.sh check        # native vkcube run with it, prints a report: proves driver + parser (no game)
```

`tools/gpuprof/mesa-radv-utrace.nix` takes nixpkgs' `mesa` (26.2.6), keeps only the AMD Vulkan driver, turns on
`radv-u_trace`, and runs `tools/gpuprof/patch-utrace.py`, which adds the **pipeline hash** to every draw/dispatch tracepoint and the
**render area + attachment count** to `vkCmdBeginRendering` (the stock tracepoints carry only counts).
The driver is loaded by `VK_DRIVER_FILES`, nothing in the system changes.

## Capture (main session)

Uses the existing launch wrapper; `bench.py` already takes `--env`. `linux/gpuprof.sh env` prints the arguments:

```
linux/gpuprof.sh clear
python3 linux/bench.py spin <your usual spin args for the GPU-bound spot> $(linux/gpuprof.sh env)
```

What they set: `VK_DRIVER_FILES`/`VK_ICD_FILENAMES` (the custom RADV), `MESA_VK_TRACE=ranges`, `MESA_VK_TRACE_PER_SUBMIT=1` (trace every
submit; see "Limits" for why not a trigger), `MESA_GPU_TRACES=print_csv`, `MESA_GPU_TRACEFILE=~/.cache/oblivion-bench/gpuprof/trace.csv`
(under `$HOME` so Steam's container sees it; `/tmp` is private there).

**First check that the custom driver is really the one in the game** (the one thing I could not test): after the run
`grep -c . ~/.cache/oblivion-bench/gpuprof/trace.csv` must be large. If the file is empty/absent the container ignored the ICD override.
Then (1) look at the game's stderr/steam log for `radv: warning: u_trace enabled but radv-u_trace was not enabled` (stock driver was used) and
try `PRESSURE_VESSEL_FILESYSTEMS_RW=/nix/store` or `PRESSURE_VESSEL_FILESYSTEMS_RO=/nix/store` via `--env` (if `/nix` is not visible
inside pressure-vessel); (2) otherwise make the build the system driver for one session: `hardware.graphics.package = (import
/path/tools/gpuprof/mesa-radv-utrace.nix {});`-style override in the NixOS config (user's decision) and run without the VK_* vars.
Also try `VK_LOADER_DEBUG=driver` as an `--env` to see which ICD the loader picked.

Expect the game to run **much slower** while traced (each tracepoint adds a pipeline flush); one short spin (20-30 s) is enough,
the report reads the last 300 frames by default. Do not leave the env on for other runs; the trace file grows without bound (`gpuprof.sh clear`).

## Report

```
linux/gpuprof.sh report --internal-res 1506x847 --output-res 2560x1440 --timeline 120 --top 30
linux/gpuprof.sh report --real-ms 12.4        # scale traced ms to the measured frame time
linux/gpuprof.sh report --name 0x1234abcd5678ef00="Lumen screen probe gather" --names names.json
```

Output (tested format; numbers below are vkcube's, not the game's):

1. **Frame summary** (ms/frame): draws, dispatches, barriers, copies, render-pass overhead, internal clears/transitions, gaps; sums to the command-buffer time.
2. **Render passes**: `vkCmdBeginRendering` grouped by area + attachments: ms, share, passes, draws, avg us, and a hint when the area is the internal
   resolution, a fraction of it (`internal/2`, `/4` ...), the output resolution, or a large square (shadow map / VSM page pool) or small square (probe atlas / LUT).
3. **Pipelines**: draws and dispatches grouped by RADV pipeline hash, ranked by ms.
4. **Dispatch shapes**: (pipeline, grid) with a hint when the grid covers the screen at a fraction of the internal resolution with 4/8/16/32 thread groups.
5. `--timeline FRAME`: that frame in order, consecutive identical events folded into runs ("render 1506x847 c=4 internal x3 (212 draws)"), with start offset and duration:
   read it against UE's pass order (depth/Nanite, Lumen scene + screen probe gather = a chain of mid/low-res dispatches, VSM = large square renderings and
   many indirect draws, base pass = internal-res rendering with several colour attachments, post/FSR = full-screen dispatches at internal and then output res).

Rows are labelled by passing pipeline hashes through `--name`/`--names`; once a hash is identified (by order, grid and resolution) it stays valid
as long as the shader cache / game build stays the same.

## Limits

- **Absolute numbers are inflated**: every tracepoint inserts PS+CS partial flushes and a cache flush (`radv_utrace_write_timestamp` in
  `layers/radv_utrace_layer.c`), so overlapped work runs serially. Trust ranking and share, or scale with `--real-ms`. Async compute work is
  serialised too and not separated (`batch` column is per flush, not per queue).
- **Always-on capture**: in ranges mode `MESA_VK_TRACE_TRIGGER`/`_FRAME` do nothing (RADV only implements them for RGP/RRA; the layer
  checks `capture_key_pressed` (X11 hotkey, held) or `MESA_VK_TRACE_PER_SUBMIT`). Hence per-submit tracing for the whole run.
- **No pass names**: Shipping emits none. Names come from you via `--name`. Pipeline hashes are RADV's (what RGP shows as "pipeline hash"),
  not vkd3d's shader hashes.
- `RADV_GPU_TRACEPOINT=<categories>` (to trace only `draw,dispatch,rendering`) exists in the source but my one try crashed vkcube [TESTED]; do not use it.
- The driver is 64-bit only (all vkd3d-proton needs). The ICD JSON points at a `/nix/store` library; keep the `~/.cache/oblivion-bench/gpuprof/mesa` gc root.
- Only tested natively (vkcube, 60 frames). The game run is the first real test; shader-compile hitches in the first seconds are skipped by the
  "first 10% of frames" rule.

## RGP fallback (stock driver, no rebuild)

```
python3 linux/bench.py spin ... --env MESA_VK_TRACE=rgp --env MESA_VK_TRACE_TRIGGER=$HOME/.cache/oblivion-bench/gpuprof/rgp-trigger \
   --env RADV_THREAD_TRACE_BUFFER_SIZE=268435456
touch ~/.cache/oblivion-bench/gpuprof/rgp-trigger     # captures the next frame; file appears in the game's /tmp (inside the container: look in
                                                       # $XDG_RUNTIME_DIR/../pressure-vessel or set TMPDIR via --env TMPDIR=$HOME/.cache/oblivion-bench/gpuprof)
```
Open the `.rgp` in AMD's Radeon GPU Profiler (Event timing / Wavefront occupancy / Pipeline hash views give per-draw times with real overlap, without the u_trace serialisation).
The format is chunked (`ac_rgp.c`, `ac_sqtt.h` in Mesa) but the per-event times need the SQTT decode, which only RGP does.

## Files

`linux/gpuprof.sh`, `tools/gpuprof/{mesa-radv-utrace.nix,patch-utrace.py,utrace_report.py}`, `linux/tests/test_gpuprof.py`.
