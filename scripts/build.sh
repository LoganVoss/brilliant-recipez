#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_xcode

# Build for iOS Simulator without a signing account.
# Ad-hoc signing is required for Keychain access in the installed simulator app.
# Override BUILD_CONFIGURATION or DERIVED_DATA_PATH when needed.
xcodebuild \
  -project "$REPO_ROOT/BrilliantRecipez.xcodeproj" \
  -scheme BrilliantRecipez \
  -configuration "${BUILD_CONFIGURATION:-Debug}" \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "${DERIVED_DATA_PATH:-$REPO_ROOT/build/DerivedData}" \
  CODE_SIGN_IDENTITY=- \
  build
