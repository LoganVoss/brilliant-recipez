#!/usr/bin/env bash
# Shared by the local build and verification scripts. Does not change xcode-select.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

require_xcode() {
  if ! xcodebuild -version >/dev/null 2>&1; then
    echo "A full Xcode installation is required. Set DEVELOPER_DIR to Xcode.app/Contents/Developer." >&2
    exit 1
  fi
}
