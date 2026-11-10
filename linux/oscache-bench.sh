#!/usr/bin/env bash
# Builds tools/oscache_bench.cpp with the cross toolchain of build-dll.sh and runs it under headless Wine (the same wine and
# throwaway prefix as selftest.sh; the game and Steam are never started). It times VirtualAlloc(MEM_RESERVE|MEM_COMMIT) +
# first touch of every page + VirtualFree for the block sizes OsPageCache sees: what one cache MISS costs here.
#   linux/oscache-bench.sh [bench args]     default: sizes 64 KB..16 MB, 1 and 4 threads, empty and busy address space
#   output: build-linux/oscache-bench/costs.csv (single-thread rows feed `tools/oscache_sim.py run|grid --costs`) and a table
# Env: OPF_OUT, OPF_WINEPREFIX, OPF_XWIN as for selftest.sh; OPF_BENCH_ARGS replaces the default runs.
set -euo pipefail
if [ -z "${OPF_IN_NIX:-}" ] && ! command -v clang-cl >/dev/null; then
  exec env OPF_IN_NIX=1 nix --extra-experimental-features 'nix-command flakes' shell \
    nixpkgs#xwin nixpkgs#llvmPackages.clang-unwrapped nixpkgs#llvmPackages.lld nixpkgs#llvmPackages.bintools \
    -c "$0" "$@"
fi
REPO=$(cd "$(dirname "$0")/.." && pwd)
OUT=$(mkdir -p "${OPF_OUT:-$REPO/build-linux/oscache-bench}" && cd "${OPF_OUT:-$REPO/build-linux/oscache-bench}" && pwd)
XW=${OPF_XWIN:-$HOME/.cache/oblivion-perffix/xwin}
if [ ! -d "$XW/splat/crt/include" ]; then
  xwin --accept-license --cache-dir "$XW/cache" --arch x86_64 --variant desktop splat --output "$XW/splat" --include-debug-libs
fi
X=$XW/splat
clang-cl --target=x86_64-pc-windows-msvc /nologo /std:c++20 /O2 /MT /EHsc -Wno-everything \
  -imsvc "$X/crt/include" -imsvc "$X/sdk/include/ucrt" -imsvc "$X/sdk/include/um" -imsvc "$X/sdk/include/shared" \
  -c "$REPO/tools/oscache_bench.cpp" /Fo"$OUT/oscache_bench.obj" >&2
lld-link /nologo /SUBSYSTEM:console /machine:x64 /OUT:"$OUT/oscache_bench.exe" \
  /LIBPATH:"$X/crt/lib/x86_64" /LIBPATH:"$X/sdk/lib/um/x86_64" /LIBPATH:"$X/sdk/lib/ucrt/x86_64" \
  "$OUT/oscache_bench.obj" kernel32.lib >&2

WINE=$(command -v wine || true)
if [ -z "$WINE" ]; then
  WINE=$(nix --extra-experimental-features 'nix-command flakes' build nixpkgs#wineWow64Packages.stable --no-link --print-out-paths)/bin/wine
fi
export WINEPREFIX=${OPF_WINEPREFIX:-$HOME/.cache/oblivion-perffix/wineprefix} WINEDEBUG=${WINEDEBUG:--all}
unset DISPLAY WAYLAND_DISPLAY   # headless: no window, no wine display driver, no crash dialog
export WINEDLLOVERRIDES="mscoree,mshtml,winex11.drv,winewayland.drv=d"
"$WINE" reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f >/dev/null 2>&1 || true
"$WINE" reg add 'HKCU\Software\Wine\WineDbg' /v Auto /t REG_SZ /d 0 /f >/dev/null 2>&1 || true
cd "$OUT"
{
  echo "# wine: $("$WINE" --version 2>/dev/null) on $(uname -sr), $(nproc) cpus, $(date -Is)"
  if [ "$#" -gt 0 ]; then
    "$WINE" oscache_bench.exe "$@" 2>&1 | tr -d '\r'
  elif [ -n "${OPF_BENCH_ARGS:-}" ]; then
    # shellcheck disable=SC2086
    "$WINE" oscache_bench.exe $OPF_BENCH_ARGS 2>&1 | tr -d '\r'
  else
    "$WINE" oscache_bench.exe --threads 1,4 --bg 0 2>&1 | tr -d '\r'
    "$WINE" oscache_bench.exe --threads 1,4 --bg 3000 2>&1 | tr -d '\r' | tail -n +2
  fi
} > "$OUT/costs.csv"
echo "oscache-bench: $OUT/costs.csv" >&2
python3 -I "$REPO/tools/oscache_sim.py" costs "$OUT/costs.csv"
