#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Reset: Initializes the repo to a clean starting state
#
# - Deletes and recreates main and develop branches
# - Removes all tags
# - Clones latest release commands from bespoke-git-workflow-commands
# - Creates initial commit on main, tags 1.0.0, creates develop
#
# WARNING: This is destructive. Only run in a disposable test repo.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

# --- Safety guard ---------------------------------------------------------
# This script WIPES all git history in REPO_DIR. The command repo root carries
# a .command-repo-root marker; if it is present we are inside the real repo (or
# a full copy of it), so refuse. The documented sandbox is built by copying
# only test/, so it never contains this marker and passes cleanly.
if [[ -f "$REPO_DIR/.command-repo-root" ]]; then
  echo "ERROR: refusing to run inside the command repo ('$REPO_DIR')." >&2
  echo "These scripts wipe all git history. Copy test/ into a disposable repo first:" >&2
  echo "  git init /tmp/test-release && cp -R test /tmp/test-release/ && cd /tmp/test-release" >&2
  echo "then run the setup script from there. See the Testing section of the README." >&2
  exit 1
fi

# --- Clean up branches ---
git checkout --orphan _reset_temp 2>/dev/null || true
git rm -rf . 2>/dev/null || true
git clean -fdx 2>/dev/null || true

git branch -D main 2>/dev/null || true
git branch -D develop 2>/dev/null || true

# Delete any other branches (e.g. release/*)
for branch in $(git branch --format='%(refname:short)' 2>/dev/null); do
  [[ "$branch" == "_reset_temp" ]] && continue
  git branch -D "$branch" 2>/dev/null || true
done

# --- Clean up tags ---
for tag in $(git tag -l 2>/dev/null); do
  git tag -d "$tag" 2>/dev/null || true
done

# --- Clone latest release commands ---
TMPDIR_CLONE=$(mktemp -d)
git clone --depth 1 https://github.com/jareddreyerss/bespoke-git-workflow-commands.git "$TMPDIR_CLONE" 2>/dev/null
cp -R "$TMPDIR_CLONE/.claude" . 2>/dev/null || true
cp -R "$TMPDIR_CLONE/.github" . 2>/dev/null || true
cp -R "$TMPDIR_CLONE/test" . 2>/dev/null || true
rm -rf "$TMPDIR_CLONE"

# --- Initial commit on main with 1.0.0 tag ---
git config user.name "Test User"
git config user.email "test@example.com"

git checkout -B main
git add -A
git commit -m "Initial commit"
git tag -a 1.0.0 -m "Release 1.0.0"

# --- Create develop from main ---
git checkout -b develop

echo "Reset complete: main (tagged 1.0.0) + develop"
