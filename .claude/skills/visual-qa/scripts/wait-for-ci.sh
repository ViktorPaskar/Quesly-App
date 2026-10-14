#!/usr/bin/env bash
# Wait until the GitHub Actions run for a commit finishes. Prints "<run_id> <status> <conclusion>".
# Usage: wait-for-ci.sh <sha> [owner/repo]   (run it in the background; it polls every 20 s)
set -euo pipefail
sha="${1:?usage: wait-for-ci.sh <sha> [owner/repo]}"
repo="${2:-ViktorPaskar/Quesly-App}"
while true; do
  line=$(curl -s "https://api.github.com/repos/$repo/actions/runs?head_sha=$sha" | python3 -c '
import sys, json
runs = json.load(sys.stdin).get("workflow_runs", [])
print(f"{runs[0][\"id\"]} {runs[0][\"status\"]} {runs[0][\"conclusion\"]}" if runs else "none pending None")
' 2>/dev/null || echo "none error None")
  case "$line" in *" completed "*) echo "$line"; exit 0 ;; esac
  sleep 20
done
