#!/usr/bin/env bash
# Installs scripts/pre-commit into .git/hooks/ so every commit runs the
# headless game test suite when game files are staged.
# Usage: bash scripts/install-hooks.sh
set -eu

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SRC="$REPO_ROOT/scripts/pre-commit"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-commit"

cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "Installed pre-commit hook -> $HOOK_DST"
