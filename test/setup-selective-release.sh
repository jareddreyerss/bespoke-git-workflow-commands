#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Setup: Selective Release (release branch → main)
#
# Resets repo, adds commits to develop, then creates a release branch
# partway through so later commits are excluded from the release.
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

echo "export function add(a, b) { return Number(a) + Number(b); }" > math.js
git add math.js
git commit -m "fix: coerce inputs to numbers in add()"

# --- Create release branch from this point on develop ---
git branch release/1.1.0

# --- Continue adding commits that should NOT ship ---
echo "export function greet(name) { return \`Hello, \${name}\`; }" > greet.js
git add greet.js
git commit -m "feat: add greeting helper"

echo "// experimental — not ready for release" > experiment.js
git add experiment.js
git commit -m "feat: experimental feature (WIP)"

echo '{ "name": "test-project", "version": "1.0.0" }' > package.json
git add package.json
git commit -m "chore: add package.json"

# --- Summary ---
echo ""
echo "========================================"
echo " Selective release ready"
echo "========================================"
echo " Tags:      1.0.0 (on main)"
echo " release/1.1.0 includes: 'feat: add math utility', 'fix: coerce inputs'"
echo " Excluded (on develop only): 'greeting helper', 'experimental', 'package.json'"
echo ""
echo " Run /release to test"
echo "========================================"
