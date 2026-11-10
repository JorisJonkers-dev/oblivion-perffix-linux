#!/usr/bin/env bash
# Steam launch option for Oblivion Remastered:  /abs/path/to/linux/oblivion-launch.sh %command%
#
# Without a benchmark env file this is the normal game with OblivionPerfFix (WINEDLLOVERRIDES="version=n,b").
# linux/bench.py writes ~/.config/oblivion-bench/env just before it asks Steam to start a benchmark game (MangoHud
# logging, UE4SS's dwmapi.dll, the fix mode, -FixedSeed) and removes it once the game is up. A file past its
# OBLV_BENCH_EXPIRES time (a runner that was killed) is ignored.

env_file="${OBLIVION_BENCH_ENV:-${XDG_CONFIG_HOME:-$HOME/.config}/oblivion-bench/env}"

if [ -s "$env_file" ]; then
    expires=$(sed -n 's/^export OBLV_BENCH_EXPIRES=\([0-9][0-9]*\)$/\1/p' "$env_file" | head -n 1)
    if [ -n "$expires" ] && [ "$(date +%s)" -le "$expires" ]; then
        # shellcheck source=/dev/null
        . "$env_file"
    fi
fi

export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-version=n,b}"

extra=()
if [ -n "${OBLV_GAME_ARGS:-}" ]; then
    read -r -a extra <<< "$OBLV_GAME_ARGS"
fi

# tells bench.py that this script ran and what it applied
if [ -n "${OBLV_BENCH_MARKER:-}" ]; then
    {
        echo "time=$(date +%s.%N)"
        echo "WINEDLLOVERRIDES=$WINEDLLOVERRIDES"
        echo "MANGOHUD=${MANGOHUD:-}"
        echo "MANGOHUD_CONFIGFILE=${MANGOHUD_CONFIGFILE:-}"
        echo "args=${extra[*]}"
    } > "$OBLV_BENCH_MARKER" 2>/dev/null
fi

exec "$@" "${extra[@]}"
