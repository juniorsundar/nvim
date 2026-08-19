#!/usr/bin/env sh
# Run the issue-06 end-to-end check against the real installed plugins.
# Non-destructive: creates a scratch XDG_CONFIG_HOME (temp lockfile); the
# real data dir (~/.local/share/nvim) is only read.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")" && pwd)"  # .../micro.nvim/tests
micro_dir="$(dirname "$repo_dir")"          # .../micro.nvim

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

XDG_CONFIG_HOME="$SCRATCH" nvim --headless --noplugin -u "$repo_dir/e2e_blink_gate.lua"

echo "E2E OK"