#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
require_xcode

# Pass a destination such as "platform=iOS Simulator,id=<UDID>" as the first
# argument, or let this script select an available iPhone simulator.
destination="${1:-}"
if [[ -z "$destination" ]]; then
  simulator_sdk="$(xcrun --sdk iphonesimulator --show-sdk-version)"
  simulator_id="$(xcrun simctl list devices available --json | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
sdk_major = int(sys.argv[1].split(".")[0])
def version(runtime):
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return tuple(map(int, match.groups())) if match else (0, 0)
phones = [device for runtime, group in sorted(devices.items(), key=lambda item: version(item[0]), reverse=True)
          if version(runtime) >= (17, 0) and version(runtime)[0] <= sdk_major
          for device in group if "iPhone" in device["name"]]
if not phones:
    sys.exit("No compatible iOS 17+ iPhone simulator. Install a runtime supported by the selected Xcode in Xcode Settings > Components.")
phones.sort(key=lambda item: item["state"] != "Booted")
print(phones[0]["udid"])
' "$simulator_sdk")"
  destination="platform=iOS Simulator,id=$simulator_id"
fi

# Use ad-hoc signing so the tests exercise real simulator Keychain behavior.
xcodebuild \
  -project "$REPO_ROOT/BrilliantRecipez.xcodeproj" \
  -scheme BrilliantRecipez \
  -configuration Debug \
  -destination "$destination" \
  -derivedDataPath "${DERIVED_DATA_PATH:-$REPO_ROOT/build/DerivedData}" \
  -parallel-testing-enabled NO \
  -only-testing:BrilliantRecipezUITests \
  CODE_SIGN_IDENTITY=- \
  test
