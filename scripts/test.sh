#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_xcode

# Ingredient parsing, generated output validation, local storage and error mapping.
# These tests use fixtures; they do not call the Apple Intelligence model.
swift test --package-path "$REPO_ROOT/Packages/RecipeCore"
