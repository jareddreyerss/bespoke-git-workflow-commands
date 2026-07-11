#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Setup: Standard Release (develop → main)
#
# Resets repo, then adds feature/fix commits to develop.
#
# WARNING: This destroys all git history. Only run in a disposable clone.
# Run from the test/ folder inside a disposable repo.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Safety guard: refuse to run inside the command repo ---
if [[ -f "$REPO_DIR/.command-repo-root" ]]; then
  echo "ERROR: don't run the test scripts from the command repo." >&2
  echo "They wipe all git history. Copy test/ into a disposable repo and run it there:" >&2
  echo "  git init /tmp/test-release && cp -R test /tmp/test-release/ && cd /tmp/test-release" >&2
  exit 1
fi

echo "WARNING: This destroys all git history in the parent directory."
echo "Only run this in a disposable clone."
read -rp "Continue? (y/n) " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Aborted."
  exit 0
fi

# --- Reset to clean state ---
source "$SCRIPT_DIR/reset.sh"

# --- Add commits to develop ---
echo "export function add(a, b) { return a + b; }" > math.js
git add math.js
git commit -m "feat: add math utility"

echo "export function greet(name) { return \`Hello, \${name}\`; }" > greet.js
git add greet.js
git commit -m "feat: add greeting helper"

echo "export function add(a, b) { return Number(a) + Number(b); }" > math.js
git add math.js
git commit -m "fix: coerce inputs to numbers in add()"

echo '{ "name": "test-project", "version": "1.0.0" }' > package.json
git add package.json
git commit -m "chore: add package.json"

# --- Summary ---
echo ""
echo "========================================"
echo " Standard release ready"
echo "========================================"
echo " Tags:      1.0.0 (on main)"
echo " Commits on develop ahead of main: $(git rev-list main..develop --count)"
echo ""
echo " Run /release to test"
echo "========================================"
