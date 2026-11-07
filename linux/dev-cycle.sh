#!/usr/bin/env bash
# One shot: build the DLL -> self-test (Wine, offline, game not started) -> optionally a short bench A/B of the
# installed DLL against the built one.
#   linux/dev-cycle.sh [--bench --scenario S [--scenes ID,ID] [--rounds N] [--label L] [--ini PATH]] [--skip-selftest]
# Without --bench nothing touches the game folder. --bench starts the game through Steam (bench.py ab --a on --b dll:...);
# the installed version.dll/ini are backed up and restored by bench.py. Extra args after `--` go to bench.py ab.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); REPO=$(dirname "$HERE")
BENCH=0; SELFTEST=1; SCENARIO=; SCENES=; ROUNDS=1; LABEL=devcycle; INI=
while [ $# -gt 0 ]; do
  case $1 in
    --bench) BENCH=1;; --skip-selftest) SELFTEST=0;;
    --scenario) SCENARIO=$2; shift;; --scenes) SCENES=$2; shift;; --rounds) ROUNDS=$2; shift;;
    --label) LABEL=$2; shift;; --ini) INI=$2; shift;;
    --) shift; break;;
    *) echo "dev-cycle: unknown option $1" >&2; exit 64;;
  esac; shift
done
if [ "$BENCH" = 1 ] && [ -z "$SCENARIO" ]; then echo "dev-cycle: --bench needs --scenario" >&2; exit 64; fi
echo "== build"; "$HERE/build-dll.sh"
DLL=$REPO/build-linux/OblivionPerfFix.dll
if [ "$SELFTEST" = 1 ]; then echo "== self-test"; "$HERE/selftest.sh"; fi
if [ "$BENCH" = 1 ]; then
  echo "== bench A/B: installed (on) vs $DLL"
  ARGS=(ab --scenario "$SCENARIO" --rounds "$ROUNDS" --a on --b "dll:$DLL" --label "$LABEL")
  [ -n "$SCENES" ] && ARGS+=(--scenes "$SCENES")
  [ -n "$INI" ] && ARGS+=(--dll-ini "$INI")
  python3 "$HERE/bench.py" "${ARGS[@]}" "$@"
else
  echo "== done (no bench: add --bench --scenario S to A/B against the installed DLL)"
fi
