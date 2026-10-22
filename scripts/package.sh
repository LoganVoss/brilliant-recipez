#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Package tracked source only, so local signing settings, data and build output cannot
# accidentally enter a release bundle. Commit intended changes before running.
output_path="${1:-$(dirname "$REPO_ROOT")/BrilliantRecipez-source.zip}"
if [[ "$output_path" != /* ]]; then
  output_path="$PWD/$output_path"
fi
if ! git -C "$REPO_ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "Commit the project before creating a source bundle." >&2
  exit 1
fi
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  echo "The working tree has uncommitted files. Commit or stash changes before packaging." >&2
  exit 1
fi
mkdir -p "$(dirname "$output_path")"
git -C "$REPO_ROOT" archive --format=zip --prefix=BrilliantRecipez/ -o "$output_path" HEAD
echo "Created $output_path"
