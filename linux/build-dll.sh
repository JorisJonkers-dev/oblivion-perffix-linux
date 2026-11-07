#!/usr/bin/env bash
# Cross-compile src/OblivionPerfFix to OblivionPerfFix.dll (x86_64 Windows PE) on Linux/NixOS.
# clang-cl + lld-link + llvm-ml (MASM for proxy_stubs.asm) against the MSVC CRT and Windows SDK fetched by xwin
# (Microsoft's redistributable headers/libs; --accept-license accepts Microsoft's licence for them).
#   linux/build-dll.sh [outdir]      default outdir: build-linux/ at the repo root; output <outdir>/OblivionPerfFix.dll
# Env: OPF_XWIN=<dir> (default ~/.cache/oblivion-perffix/xwin, ~800 MB, fetched once), OPF_JOBS=<n>, OPF_DEBUG=1 (/Od /MTd).
# Same flags as build.ps1 minus /W4 /WX /GL /LTCG and the version resource. Never touches the game or Steam.
set -euo pipefail
if [ -z "${OPF_IN_NIX:-}" ] && ! command -v clang-cl >/dev/null; then
  exec env OPF_IN_NIX=1 nix --extra-experimental-features 'nix-command flakes' shell \
    nixpkgs#xwin nixpkgs#llvmPackages.clang-unwrapped nixpkgs#llvmPackages.lld nixpkgs#llvmPackages.bintools \
    -c "$0" "$@"
fi
REPO=$(cd "$(dirname "$0")/.." && pwd); SRC=$REPO/src/OblivionPerfFix
OUT=$(mkdir -p "${1:-$REPO/build-linux}" && cd "${1:-$REPO/build-linux}" && pwd); OBJ=$OUT/obj; mkdir -p "$OBJ"
XW=${OPF_XWIN:-$HOME/.cache/oblivion-perffix/xwin}
if [ ! -d "$XW/splat/crt/include" ]; then
  xwin --accept-license --cache-dir "$XW/cache" --arch x86_64 --variant desktop splat --output "$XW/splat" --include-debug-libs
fi
X=$XW/splat
if [ -n "${OPF_DEBUG:-}" ]; then OPT="/Od /MTd"; else OPT="/O2 /MT"; fi
INC=(-imsvc "$X/crt/include" -imsvc "$X/sdk/include/ucrt" -imsvc "$X/sdk/include/um" -imsvc "$X/sdk/include/shared")
cd "$SRC"
llvm-ml -m64 -nologo -c -Fo"$OBJ/proxy_stubs.obj" src/core/proxy_stubs.asm
# every .cpp in the area folders except lab/ (same set as build.ps1); object names must be unique
mapfile -t FILES < <(ls src/*/*.cpp | grep -v '^src/lab/' | sort)
printf '%s\n' "${FILES[@]}" | xargs -P "${OPF_JOBS:-$(nproc)}" -I{} sh -c '
  clang-cl --target=x86_64-pc-windows-msvc /nologo /std:c++20 '"$OPT"' /EHsc /DUNICODE /D_UNICODE \
    '"${INC[*]}"' /I'"$SRC"'/src/core -Wno-everything -c {} /Fo'"$OBJ"'/$(basename {} .cpp).obj'
OBJS=("$OBJ/proxy_stubs.obj"); for f in "${FILES[@]}"; do OBJS+=("$OBJ/$(basename "$f" .cpp).obj"); done
lld-link /nologo /DLL /machine:x64 /DEF:"$SRC/OblivionPerfFix.def" /OUT:"$OUT/OblivionPerfFix.dll" \
  /OPT:REF /OPT:ICF /LIBPATH:"$X/crt/lib/x86_64" /LIBPATH:"$X/sdk/lib/um/x86_64" /LIBPATH:"$X/sdk/lib/ucrt/x86_64" \
  "${OBJS[@]}" kernel32.lib
ls -l "$OUT/OblivionPerfFix.dll"
