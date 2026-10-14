#!/usr/bin/env bash
# Wait until the GitHub Actions run for a commit finishes. Prints "<run_id> <status> <conclusion>".
# Usage: wait-for-ci.sh <sha> [owner/repo]   (run it in the background; it polls every 20 s)
set -euo pipefail
sha="${1:?usage: wait-for-ci.sh <sha> [owner/repo]}"
repo="${2:-ViktorPaskar/Quesly-App}"
# Unauthenticated GitHub API allows ~60 requests/hour, so poll every 60 s and report rate limiting.
while true; do
  line=$(curl -s "https://api.github.com/repos/$repo/actions/runs?head_sha=$sha" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if "workflow_runs" not in d:
    print("none ratelimited " + d.get("message", "?")[:60].replace(" ", "_"))
else:
    runs = d["workflow_runs"]
    print(f"{runs[0][\"id\"]} {runs[0][\"status\"]} {runs[0][\"conclusion\"]}" if runs else "none pending None")
' 2>/dev/null || echo "none error None")
  case "$line" in
    *" completed "*) echo "$line"; exit 0 ;;
    *ratelimited*) echo "GitHub API: $line — retrying in 5 min" >&2; sleep 300; continue ;;
  esac
  sleep 60
done
