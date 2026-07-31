#!/usr/bin/env bash
# Headless test suite for The Last Beacon.
# Every tests/test_*.gd is a simulated playthrough; each runs in its own
# headless Godot process and exits 0 on pass, 1 on fail.
#
# Usage:
#   bash tests/run_tests.sh
#   GODOT_BIN=/path/to/godot bash tests/run_tests.sh   # override detection
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# The Godot exe is a Windows binary: translate MSYS paths (e.g. /c/Users/...)
# into Windows form (C:/Users/...) when running under git-bash/MSYS.
if command -v cygpath >/dev/null 2>&1; then
  PROJECT_DIR="$(cygpath -m "$PROJECT_DIR")"
fi

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
  for cand in "$HOME/tools/godot/"Godot_v*.exe "$HOME/tools/godot/godot" /usr/local/bin/godot /usr/bin/godot; do
    if [ -x "$cand" ]; then GODOT="$cand"; break; fi
  done
fi
if [ -z "$GODOT" ]; then
  echo "ERROR: Godot binary not found. Set GODOT_BIN, e.g." >&2
  echo "  GODOT_BIN=/c/Users/hugob/tools/godot/Godot_v4.7.1-stable_win64.exe bash tests/run_tests.sh" >&2
  exit 2
fi
echo "Godot:   $GODOT"
echo "Project: $PROJECT_DIR"

# Ensure resources are imported (idempotent; fast when nothing changed).
"$GODOT" --headless --path "$PROJECT_DIR" --import >/dev/null 2>&1

LOG_DIR="$(mktemp -d)"
pass=0
fail=0
failed_tests=()
for test_script in "$SCRIPT_DIR"/test_*.gd; do
  name="$(basename "$test_script" .gd)"
  log="$LOG_DIR/$name.log"
  script_arg="$test_script"
  if command -v cygpath >/dev/null 2>&1; then
    script_arg="$(cygpath -m "$test_script")"
  fi
  if "$GODOT" --headless --path "$PROJECT_DIR" --script "$script_arg" >"$log" 2>&1; then
    echo "PASS  $name"
    pass=$((pass + 1))
  else
    echo "FAIL  $name"
    fail=$((fail + 1))
    failed_tests+=("$name")
    tail -n 20 "$log" | sed 's/^/      /'
  fi
done
rm -rf "$LOG_DIR"

echo "----------------------------------------"
echo "Tests: $((pass + fail))   Passed: $pass   Failed: $fail"
if [ "$fail" -eq 0 ]; then
  exit 0
else
  printf 'Failed: %s\n' "${failed_tests[@]}" >&2
  exit 1
fi
