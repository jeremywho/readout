#!/usr/bin/env bash
set -euo pipefail
host="${READOUT_MAC_HOST:-macstudio.local}"
dir="${READOUT_MAC_DIR:-dev/Readout-build}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
ssh "$host" "mkdir -p ~/$dir && cd ~/$dir && find . -type f -not -path './build/*' -not -path './dist/*' -not -path './ReadoutKit/.build/*' -delete"
git ls-files -co --exclude-standard -z | tar --null -T - -cf - | ssh "$host" "tar -xf - -C ~/$dir"
ssh "$host" "cd ~/$dir && export PATH=/opt/homebrew/bin:/usr/local/bin:\$PATH && $*"
