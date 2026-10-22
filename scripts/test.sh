#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Request construction, response decoding, error handling and model tests.
# These tests use local fixtures and never require an API key or network.
swift test --package-path "$REPO_ROOT/Packages/RecipeCore"
