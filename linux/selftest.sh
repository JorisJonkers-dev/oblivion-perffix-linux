#!/usr/bin/env bash
# Build src/OblivionPerfFix/tests/selftest.cpp with the cross toolchain of build-dll.sh (same sources minus
# core/main.cpp and core/proxy.cpp, as build.ps1 -SelfTest) and run it under Wine against the game exe.
# The exe is only read (mapped as data); the game and Steam are never started.
#   linux/selftest.sh [exe]      exit status: the self-test's (1 on any FAIL, except the Wine-only checks listed in the script), 2 on a build/Wine problem
# Env: OPF_EXE (exe path; default: the Shared Steam library install), OPF_OUT (build dir, default build-linux/test),
#      OPF_WINEPREFIX (default ~/.cache/oblivion-perffix/wineprefix, throwaway), OPF_XWIN, OPF_JOBS, OPF_DEBUG.
set -euo pipefail
if [ -z "${OPF_IN_NIX:-}" ] && ! command -v clang-cl >/dev/null; then
  exec env OPF_IN_NIX=1 nix --extra-experimental-features 'nix-command flakes' shell \
    nixpkgs#xwin nixpkgs#llvmPackages.clang-unwrapped nixpkgs#llvmPackages.lld nixpkgs#llvmPackages.bintools \
    -c "$0" "$@"
fi
REPO=$(cd "$(dirname "$0")/.." && pwd); SRC=$REPO/src/OblivionPerfFix
EXE=${1:-${OPF_EXE:-/run/media/ExtraToast/Shared/SteamLibrary/steamapps/common/Oblivion Remastered/OblivionRemastered/Binaries/Win64/OblivionRemastered-Win64-Shipping.exe}}
[ -f "$EXE" ] || { echo "selftest: exe not found: $EXE" >&2; exit 2; }
OUT=$(mkdir -p "${OPF_OUT:-$REPO/build-linux/test}" && cd "${OPF_OUT:-$REPO/build-linux/test}" && pwd); OBJ=$OUT/obj; mkdir -p "$OBJ"
XW=${OPF_XWIN:-$HOME/.cache/oblivion-perffix/xwin}
if [ ! -d "$XW/splat/crt/include" ]; then
  xwin --accept-license --cache-dir "$XW/cache" --arch x86_64 --variant desktop splat --output "$XW/splat" --include-debug-libs
fi
X=$XW/splat
if [ -n "${OPF_DEBUG:-}" ]; then OPT="/Od /MTd"; else OPT="/O2 /MT"; fi
INC=(-imsvc "$X/crt/include" -imsvc "$X/sdk/include/ucrt" -imsvc "$X/sdk/include/um" -imsvc "$X/sdk/include/shared")
cd "$SRC"
mapfile -t FILES < <(ls src/*/*.cpp | grep -v -e '^src/lab/' -e '^src/core/main.cpp$' -e '^src/core/proxy.cpp$' | sort)
FILES=(tests/selftest.cpp "${FILES[@]}")
printf '%s\n' "${FILES[@]}" | xargs -P "${OPF_JOBS:-$(nproc)}" -I{} sh -c '
  clang-cl --target=x86_64-pc-windows-msvc /nologo /std:c++20 '"$OPT"' /EHa /DUNICODE /D_UNICODE \
    '"${INC[*]}"' /I'"$SRC"'/src/core -Wno-everything -c {} /Fo'"$OBJ"'/$(basename {} .cpp).obj' >&2 \
  || { echo "selftest: compile failed" >&2; exit 2; }
OBJS=(); for f in "${FILES[@]}"; do OBJS+=("$OBJ/$(basename "$f" .cpp).obj"); done
# Wine does not relocate an exe it maps with LoadLibraryEx: the game exe must get its preferred base (0x140000000,
# ~160 MB), so the self-test itself sits well above it (otherwise the vtable/thunk scans see unrelocated pointers).
lld-link /nologo /SUBSYSTEM:console /machine:x64 /BASE:0x1C0000000 /OUT:"$OUT/selftest.exe" \
  /LIBPATH:"$X/crt/lib/x86_64" /LIBPATH:"$X/sdk/lib/um/x86_64" /LIBPATH:"$X/sdk/lib/ucrt/x86_64" \
  "${OBJS[@]}" kernel32.lib >&2 || { echo "selftest: link failed" >&2; exit 2; }

# Wine: the one on PATH, else from nixpkgs. Throwaway prefix.
WINE=$(command -v wine || true)
if [ -z "$WINE" ]; then
  WINE=$(nix --extra-experimental-features 'nix-command flakes' build nixpkgs#wineWow64Packages.stable --no-link --print-out-paths)/bin/wine
fi
export WINEPREFIX=${OPF_WINEPREFIX:-$HOME/.cache/oblivion-perffix/wineprefix} WINEDEBUG=${WINEDEBUG:--all}
# Headless: no display, no Wine drivers that could open a window, no crash dialog / winedbg (a crash is just an exit code).
unset DISPLAY WAYLAND_DISPLAY
export WINEDLLOVERRIDES="mscoree,mshtml,winex11.drv,winewayland.drv=d"
"$WINE" reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f >/dev/null 2>&1 || true
"$WINE" reg add 'HKCU\Software\Wine\WineDbg' /v Auto /t REG_SZ /d 0 /f >/dev/null 2>&1 || true
cd "$OUT"
echo "selftest: $WINE selftest.exe against $EXE" >&2
set +e
"$WINE" selftest.exe "Z:${EXE//\//\\}" 2>&1 | tee "$OUT/selftest.out.log"
rc=${PIPESTATUS[0]}
set -e
# Checks that can only fail under Wine because they assert "this PC is Windows itself" (listed, never hidden):
WINE_ONLY='^FAIL  SharedMemoryGpu: this PC is Windows itself'
nwine=$(grep -c "$WINE_ONLY" "$OUT/selftest.out.log" || true)
nfail=$(grep '^FAIL' "$OUT/selftest.out.log" | grep -vc "$WINE_ONLY" || true); npass=$(grep -c '^PASS' "$OUT/selftest.out.log" || true)
[ "$nwine" -eq 0 ] || echo "selftest: $nwine Wine-only FAIL (expected, not counted): $(grep "$WINE_ONLY" "$OUT/selftest.out.log" | head -1)" >&2
echo "selftest: $npass PASS, $nfail FAIL (exit $rc, log $OUT/selftest.out.log; the DLL's own log: $OUT/selftest.log)" >&2
# exit 1 from the self-test is "some FAIL": fine when only the Wine-only ones failed
[ "$rc" -eq 1 ] && [ "$nfail" -eq 0 ] && [ "$nwine" -gt 0 ] && rc=0
[ "$rc" -eq 0 ] && [ "$nfail" -eq 0 ] && [ "$npass" -gt 0 ] || exit "$((rc ? rc : 1))"
