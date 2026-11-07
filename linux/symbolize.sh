#!/usr/bin/env bash
# Symbolise crash offsets in a Linux-built OblivionPerfFix.dll (UE crash reports show them as VERSION+0x19fcd: an RVA).
#   linux/symbolize.sh <dll> <rva>...      e.g. linux/symbolize.sh build-linux/OblivionPerfFix.dll 0x19fcd 0xc430
# Needs OblivionPerfFix.pdb / .map next to the DLL (build-dll.sh writes both) from the SAME build: the rebuilt DLL's
# .text is not byte-identical (link timestamp / layout), so keep the pdb of the DLL that was deployed.
# Prints: function (llvm-symbolizer, with file:line when the pdb has it), the map entry, and the instructions around it.
set -euo pipefail
if ! command -v llvm-symbolizer >/dev/null || ! command -v llvm-objdump >/dev/null; then
  exec nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#llvmPackages.bintools -c "$0" "$@"
fi
DLL=${1:?usage: symbolize.sh <dll> <rva>...}; shift
[ $# -gt 0 ] || { echo "usage: symbolize.sh <dll> <rva>..." >&2; exit 2; }
D=$(dirname "$DLL"); B=$(basename "$DLL" .dll); MAP=$D/$B.map
BASE=0x180000000
for off in "$@"; do
  va=$(printf '0x%x' $((BASE + off)))
  echo "== $B+$off  (va $va)"
  llvm-symbolizer --obj="$DLL" --demangle --functions=linkage --inlining "$va" 2>/dev/null | sed 's/^/  /' || true
  if [ -f "$MAP" ]; then
    python3 - "$MAP" "$va" <<'PY'
import re, sys
t = int(sys.argv[2], 16); best = None
for l in open(sys.argv[1], errors='ignore'):
    m = re.match(r'\s*0001:[0-9a-f]{8}\s+(\S+)\s+([0-9a-f]{16})\s+(?:f\s+)?(\S+)', l)
    if m:
        a = int(m.group(2), 16)
        if a <= t and (best is None or a > best[0]): best = (a, m.group(1), m.group(3))
if best: print("  map: %s +0x%x (%s)" % (best[1], t - best[0], best[2]))
PY
  fi
  llvm-objdump -d --no-show-raw-insn --start-address=$((va - 0x30)) --stop-address=$((va + 0x20)) "$DLL" | tail -n +6 | sed 's/^/  /'
done
