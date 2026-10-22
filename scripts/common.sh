#!/usr/bin/env bash
# Shared by the local build and verification scripts. Does not change xcode-select.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

require_xcode() {
  local xcode_version
  if ! xcode_version="$(xcodebuild -version 2>/dev/null)"; then
    echo "A full Xcode installation is required. Set DEVELOPER_DIR to Xcode.app/Contents/Developer." >&2
    exit 1
  fi
  local xcode_major
  xcode_major="$(awk '/^Xcode / { split($2, version, "."); print version[1] }' <<< "$xcode_version")"
  if [[ -z "$xcode_major" || "$xcode_major" -lt 27 ]]; then
    echo "Xcode 27 or later is required to compile on-device image understanding. The app runs on iOS 26 or later." >&2
    exit 1
  fi
}
