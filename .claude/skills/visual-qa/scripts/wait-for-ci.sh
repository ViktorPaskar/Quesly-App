#!/usr/bin/env bash
# Wait until the GitHub Actions run for a commit finishes. Prints "<run_id> completed <conclusion>".
# Usage: wait-for-ci.sh <sha> [owner/repo]   (run it in the background)
# Uses the GitHub CLI (no Python needed, works on Windows Git Bash). Exits non-zero if the run
# is cancelled or fails, so a superseded run never leaves this waiting forever.
set -euo pipefail
sha="${1:?usage: wait-for-ci.sh <sha> [owner/repo]}"
repo="${2:-ViktorPaskar/Quesly-App}"
gh="gh"; command -v gh >/dev/null 2>&1 || gh="/c/Program Files/GitHub CLI/gh.exe"
for _ in $(seq 1 30); do   # the run can take a few seconds to appear after a push
  id=$("$gh" run list -R "$repo" --commit "$sha" -L 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
  [ -n "$id" ] && break
  sleep 10
done
[ -n "${id:-}" ] || { echo "none missing None"; exit 1; }
"$gh" run watch "$id" -R "$repo" --interval 30 >/dev/null 2>&1 || true
conclusion=$("$gh" run view "$id" -R "$repo" --json conclusion -q .conclusion)
echo "$id completed $conclusion"
[ "$conclusion" = "success" ]
