#!/usr/bin/env bash
# Fetch CI simulator screenshots from the `ci-screenshots` branch into <out_dir>.
# If <sha> is given, abort unless the screenshots were produced for exactly that commit.
# Usage: fetch-screenshots.sh <out_dir> [sha]
set -euo pipefail
out="${1:?usage: fetch-screenshots.sh <out_dir> [sha]}"
sha="${2:-}"
root="$(git rev-parse --show-toplevel)"
git -C "$root" fetch -q origin ci-screenshots
rm -rf "$out" && mkdir -p "$out"
git -C "$root" archive origin/ci-screenshots | tar -x -C "$out"
built_for=$(sed -n 's/^Commit: //p' "$out/README.md" | head -1)
echo "screenshots built for commit: $built_for"
if [[ -n "$sha" && "$built_for" != "$sha"* ]]; then
  echo "ERROR: screenshots are for $built_for, expected $sha (CI not finished, failed, or a newer push ran)." >&2
  exit 1
fi
ls "$out"/*.png | wc -l | xargs echo "png files:"
