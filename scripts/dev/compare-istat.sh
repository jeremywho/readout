#!/usr/bin/env bash
set -euo pipefail
host="${READOUT_MAC_HOST:-macstudio.local}"
samples="${1:-5}"
out="${2:-build/istat-compare}"
mkdir -p "$out"
for i in $(seq 1 "$samples"); do
  ssh "$host" "/opt/homebrew/bin/tmux send-keys -t hil 'screencapture -x -R 1240,0,300,30 /tmp/istat-$i.png' Enter"
  ssh "$host" "cd ~/dev/Readout-build && ReadoutKit/.build/release/readout-probe --seconds 2 | tail -n 1"
  sleep 1
  scp -q "$host:/tmp/istat-$i.png" "$out/istat-$i.png"
done
echo "iStat crops saved to $out"
