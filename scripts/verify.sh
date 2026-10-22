#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/test.sh"
"$script_dir/build.sh"
# Run scripts/test-ui.sh separately when a simulator runtime is installed.
