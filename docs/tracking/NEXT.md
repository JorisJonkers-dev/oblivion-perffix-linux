# Resume here

State as of the pause on 2026-11-07. Read this first, then [LOG.md](LOG.md) (newest first) and
[investigations.md](investigations.md).

## Where things are
- **Integration branch:** `docs-tracking`, in the fork `~/Projects/oblivion-perffix-linux`. Every finished branch is
  merged into it. Worktree: `~/Projects/opf-tracking`.
- **Benchmark runner worktree:** `~/Projects/opf-run`. It is a detached checkout of `docs-tracking`, and its
  `linux/results` and `linux/third_party` are symlinks to the main checkout. Run benchmarks only from here.
- **Our DLL builds** go into `~/Projects/opf-run/build-linux/` (PDB and map file next to each DLL). Build with
  `linux/build-dll.sh` (clang-cl, `/EHa`). Self-test with `linux/selftest.sh` (headless Wine).
- **The player's game is stock:** the installed `version.dll` is OblivionPerfFix 1.2.4 (MSVC) with the player's ini, and
  the Steam launch option is `WINEDLLOVERRIDES="version=n,b" %command%`. Benchmarks with our DLL use `--dll` and
  restore everything afterwards.
- **For benchmarking**, set the launch option back to
  `/home/ExtraToast/Projects/oblivion-perffix-linux/linux/oblivion-launch.sh %command%` (Steam fully closed;
  `~/Projects/linux-gaming/scripts/set-launch-options.py 2623190 '...'`).
- **Displays:** if GNOME falls back to 60 Hz landscape (it does when the TV joins), restore the layout with
  `gnome-monitor-config set -LM HDMI-2 -m 1920x1080@143.999 -t left -x 0 -y 0 -LpM HDMI-1 -m 2560x1440@144.006 -t normal -x 1080 -y 203`.
  The tool is in the nix store (`nixpkgs#gnome-monitor-config`).

## Proven so far (see LOG)
- **Shader gate:** works on Continue and `coc`. The start-up precompile finishes before play.
- **PSO record and replay:** runtime pipeline creation time in play fell 10.9 s → 3.3 s, and creations of 20 ms or more
  fell 31 → 0 (8 random spots).
- **Old engine:** not the limit in town; busy 25% of its cycle.
- **Player settings:** GPU-bound at 97–99% everywhere.
- **`RdgSubmitBatch`:** helps under Proton.
- **OsPageCache:** near its ceiling in play; defaults kept.
- **Texture switches** (`VtStreamingUploads=64` + `FadeVtFlushSkip=1`): detail arrives 2.5–3.5 s sooner when entering
  interiors, no gain on exits.
- **Crash fixed:** clang-cl `/EHsc` dropped `__try`; the build now uses `/EHa`.

## Open, in priority order
1. **PSO replay with the compressed record** (DLL `02144ca7`, run `pso-record5`/`pso-replay5`):
   - check the file size against 133.8 MB;
   - check the cap is no longer hit;
   - check the replay failures, which should be 0.
   Then fps and hitches A/B on random spots, and decide whether `PsoRecordReplay=1` becomes the default.
2. **Late pop-in and night lighting after turning** (owner priority):
   - the turn-settle metric saturates at busy spots. Branch `turn-settle2` (merged) only has the fast X11 capture
     (`linux/oblvbench/xcap.py`: 21 ms per grab at a centre crop of 0.5, against 109 ms with xwd), and it is not wired
     in yet. Still to do:
     1. wire `xcap` into turns and shots (`--turn-crop` / `--shot-crop`);
     2. a motion-masked settle;
     3. a 6 s window with a 1 s tail, reporting ">X s" when not settled;
     4. an AI-off pin during the laps (`obv tai` is a toggle; `freeze` may stop streaming);
     5. calm test spots;
   - then A/B VT/streaming budgets (fewest missing regions so far), Lumen response, eye adaptation and Nanite at a calm
     spot and a night spot.
3. **GPU per-pass profile**, to know where the 98% goes:
   - the patched RADV u_trace driver is staged (`linux/gpuprof.sh build`, then stage 1 idle, then stage 2 a 40-frame
     window; see `docs/research-linux/gpu-profiling.md`);
   - fallback: RGP captures.
4. **Image trade-offs** (allowed when slight, at least 5% gain, SSIM-checked, opt-in): blocked until the GPU profile
   shows the big passes and the shot comparison is stable.
   - Lumen reflections, probe downsample and VSM rays gave no gain.
5. **Old engine:** C1a (crossing teardown on helpers), C2 (Havok threads, determinism-checked). Profile travel (Silver
   Road), crowds and saves with `OtProfile=1` first.
6. **Upstream:** report the clang `/EHsc` finding, the Proton driver-thread guard gap and the `ShaderGate` idea to
   LTSharpe.

## Rules (owner)
- Lumen and lighting stay. Slight image changes only for at least 5% gain, SSIM-checked and opt-in.
- Old-engine changes are allowed. Keep gameplay exploits.
- Benchmarks never use the owner's saves (fresh `coc` only), and never run during builds.
- Subagents run on Haiku or Sonnet, each in its own git worktree. No AI attribution lines in commits (a hook enforces it).
