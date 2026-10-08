#!/usr/bin/env bash
set -euo pipefail
host="${READOUT_MAC_HOST:-macstudio.local}"
dir="${READOUT_MAC_DIR:-dev/Readout-build}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
paths=()
for candidate in ReadoutKit/Sources ReadoutKit/Tests ReadoutKit/Package.swift App; do
    [ -e "$candidate" ] && paths+=("$candidate")
done
scripts/dev/mac.sh "swift format format --in-place --recursive ${paths[*]} && swift format lint --strict --recursive ${paths[*]}"
ssh "$host" "cd ~/$dir && find ${paths[*]} -name '*.swift' -print0 | tar --null -T - -cf -" | tar -xf -
git status --short
