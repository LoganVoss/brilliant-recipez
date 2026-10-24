#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_path="${1:-$(dirname "$repo_root")/RecipeSnap-source.zip}"
if [[ "$output_path" != /* ]]; then output_path="$PWD/$output_path"; fi
if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
  echo 'Commit the intended source changes before packaging.' >&2
  exit 1
fi
mkdir -p "$(dirname "$output_path")"
git -C "$repo_root" archive --format=zip --prefix=RecipeSnap/ -o "$output_path" HEAD
echo "Created $output_path"
