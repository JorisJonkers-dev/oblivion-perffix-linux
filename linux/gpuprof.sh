#!/usr/bin/env bash
# Per-pass GPU time for the game under Proton/RADV, from Mesa's u_trace tracepoints (docs/research-linux/gpu-profiling.md).
#   linux/gpuprof.sh build             build the RADV-with-tracepoints driver (nix, ~2 min, cached) -> ~/.cache/oblivion-bench/gpuprof/mesa
#   linux/gpuprof.sh env               print the bench.py --env arguments that turn tracing on
#   linux/gpuprof.sh check             native vkcube dry run: proves driver + parser work (does not start the game)
#   linux/gpuprof.sh report [csv] ...  ranked tables from the trace (extra args go to tools/gpuprof/utrace_report.py)
#   linux/gpuprof.sh clear             delete the trace file (it grows for as long as the game runs traced)
# Env: GPUPROF_DIR (default ~/.cache/oblivion-bench/gpuprof).
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
DIR=${GPUPROF_DIR:-$HOME/.cache/oblivion-bench/gpuprof}
TRACE=$DIR/trace.csv
NIX=(nix --extra-experimental-features 'nix-command flakes')
mkdir -p "$DIR"

icd() { echo "$DIR/mesa/share/vulkan/icd.d/radeon_icd.x86_64.json"; }

case "${1:-}" in
  build)
    "${NIX[@]}" build --impure --out-link "$DIR/mesa" -f "$REPO/tools/gpuprof/mesa-radv-utrace.nix"
    echo "driver: $(readlink -f "$DIR/mesa")"; echo "icd:    $(icd)" ;;
  env)
    [ -e "$(icd)" ] || { echo "gpuprof: run 'linux/gpuprof.sh build' first" >&2; exit 1; }
    ICD=$(icd)
    # the ICD file names the library by its /nix/store path; steam's container must be able to see it (see the doc)
    printf -- '--env %q ' "VK_DRIVER_FILES=$ICD" "VK_ICD_FILENAMES=$ICD" "MESA_VK_TRACE=ranges" \
      "MESA_VK_TRACE_PER_SUBMIT=1" "MESA_GPU_TRACES=print_csv" "MESA_GPU_TRACEFILE=$TRACE"
    echo ;;
  check)
    [ -e "$(icd)" ] || { echo "gpuprof: run 'linux/gpuprof.sh build' first" >&2; exit 1; }
    VC=$(command -v vkcube || true)
    [ -n "$VC" ] || { VC=$("${NIX[@]}" build --no-link --print-out-paths nixpkgs#vulkan-tools | tail -1)/bin/vkcube; }
    rm -f "$DIR/check.csv"
    VK_DRIVER_FILES=$(icd) MESA_VK_TRACE=ranges MESA_VK_TRACE_PER_SUBMIT=1 MESA_GPU_TRACES=print_csv \
      MESA_GPU_TRACEFILE="$DIR/check.csv" timeout 30 "$VC" --c 60 >/dev/null 2>&1 || true
    python3 -I "$REPO/tools/gpuprof/utrace_report.py" "$DIR/check.csv" --internal-res 250x250 --top 3 ;;
  report)
    shift
    f=$TRACE
    if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then f=$1; shift; fi
    [ -s "$f" ] || { echo "gpuprof: no trace at $f" >&2; exit 1; }
    exec python3 -I "$REPO/tools/gpuprof/utrace_report.py" "$f" "$@" ;;
  clear) rm -f "$TRACE"; echo "removed $TRACE" ;;
  *) sed -n '2,8p' "$0" >&2; exit 2 ;;
esac
