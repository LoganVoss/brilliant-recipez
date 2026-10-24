#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
xcodebuild -project "$repo_root/RecipeSnap.xcodeproj" \
  -scheme RecipeSnap -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$repo_root/build" \
  CODE_SIGNING_ALLOWED=NO build "$@"
