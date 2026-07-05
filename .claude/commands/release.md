---
allowed_tools: Bash(git tag*), Bash(git status*), Bash(git switch*), Bash(git pull*), Bash(git checkout*), Bash(git merge*), Bash(git log*), Bash(git branch*), Bash(git fetch*), Bash(git diff*), Bash(which*)
---

You are executing a production release workflow. The arguments are: $ARGUMENTS

## Pre-flight: Model Check

Before doing anything else, check what model you are. If your model name contains "opus" or "fable" (case-insensitive), display this warning and stop:

> ⚠️ **Warning:** You are running as a higher-tier model (Opus or Fable). This release workflow is designed to run on the cheapest available model to keep costs low. Consider switching to Sonnet (or a Haiku model, if available in your model picker) before proceeding.
>
> Type **continue** to proceed anyway, or switch to a cheaper model and re-run `/release`.

Do NOT proceed until the user explicitly types "continue". If they do not, abort.

If you are running as Sonnet or Haiku, proceed immediately without mentioning the model check.

Parse the arguments:
- The **version number** is the first positional argument (e.g. `1.2.3`). It is optional — if not provided, Step 0 will discover it.
- If `--gh-release` flag is present, a GitHub release will be created after tagging.

Follow these steps exactly, stopping if any step fails:

## Step 0: Version Discovery

**Skip this step if a version number was provided in the arguments.**

1. Run `git tag --list --sort=-v:refname` and filter to tags matching semver patterns (`X.Y.Z` or `vX.Y.Z`).
2. **If matching tags are found:**
   - Identify the latest version (strip the `v` prefix if present for comparison).
   - Present it to the user and offer increment options:
     - **Patch**: e.g. 1.2.3 → 1.2.4
     - **Minor**: e.g. 1.2.3 → 1.3.0
     - **Major**: e.g. 1.2.3 → 2.0.0
     - **Custom**: enter a version manually
   - **STOP and ask the user** which option they'd like. Do NOT proceed until they choose.
3. **If no matching tags are found:**
   - Inform the user: "No existing version tags found."
   - **STOP and ask the user** to enter a version number manually. Do NOT proceed until they provide one.
4. After selection, verify the chosen tag doesn't already exist (`git tag -l VERSION`). If it does, abort: "Tag VERSION already exists. Choose a different version."

Use the selected version as VERSION for all subsequent steps.

## Step 1: Safety Checks

Run all checks and abort with a clear message if any fail:

1. Verify the working tree is clean (`git status --porcelain` should be empty). If not, abort: "Working tree is not clean. Commit or stash changes before releasing."
2. Verify the tag `$ARGUMENTS` does not already exist (`git tag -l $ARGUMENTS`). If it does, abort: "Tag $ARGUMENTS already exists. Choose a different version."
3. Verify the `develop` branch exists locally or on origin. If not, abort: "No develop branch found."
4. Verify the `main` branch exists locally or on origin. If not, abort: "No main branch found."
5. Check if a `release/$ARGUMENTS` branch exists locally or on origin. Note the result — this determines the release path:
   - **Release branch exists** → selective release (pre-built by developer)
   - **No release branch** → standard release (all of develop ships)

Inform the user which path was detected.

## Step 2: Update develop

Always pull the latest develop regardless of release path:

```
git switch develop
git pull origin develop
```

## Step 3: Prepare release source

**If release branch exists (selective release):**
```
git switch release/$ARGUMENTS
git pull origin release/$ARGUMENTS
```
Show what will ship: `git log main..release/$ARGUMENTS --oneline`

**If no release branch (standard release):**
Stay on develop. Show what will ship: `git log main..develop --oneline`

Count the commits and summarise: "This release includes X commits."

## Step 4: Merge to main (local only)

```
git checkout main
git pull origin main
```

**Standard release:**
```
git merge develop --no-edit
```

**Selective release:**
```
git merge release/VERSION --no-edit
```

If the merge has conflicts, stop and tell the user. Do not force or auto-resolve.

## Step 5: Tag (local only)

```
git tag VERSION
```

## Step 6: Confirm before pushing

**This step is mandatory. Do NOT skip or abbreviate it.**

First, fetch the latest remote state to ensure the comparison is accurate:
```
git fetch origin
```

Then show the user **all** of the following — do not truncate any section:

**What will be pushed to main (every commit, no limit):**
```
git log origin/main..main --oneline
```

**What is currently on GitHub (last 5 commits on origin/main):**
```
git log origin/main --oneline -5
```

**Tag to be pushed:** VERSION

**Validation — confirm develop is fully represented in the merge:**

Run:
```
git log origin/main..main --oneline
```

Compare this output against the commit list captured in Step 3 (what develop had to ship).

- If every commit from Step 3 is present: confirm with "✓ All N commits from develop are included in this push."
- If any commit from Step 3 is missing from this list: display a prominent warning showing exactly which commits did not make it into main, and **do not proceed** until the user acknowledges and confirms they want to push anyway.

Present this as a clear, labelled summary with section headings. Make it easy to review at a glance.

**STOP and ask the user:** "Everything looks good locally. Ready to push VERSION to origin? (yes/no)"

Do NOT proceed until the user explicitly says "yes". If the user says "no", inform them they can undo with:
```
git reset --hard origin/main
git tag -d VERSION
```
Then abort.

## Step 7: Push to origin (only after user confirms Step 6)

```
git push origin main
git push origin VERSION
```

## Step 8: GitHub Release (only if `--gh-release` flag was passed)

First, check if `gh` is installed by running `which gh`.

- **If `gh` is not installed**: inform the user that GitHub CLI is required for this step and provide install instructions (`brew install gh`). Skip this step.
- **If `gh` is installed**: run `gh release create VERSION --generate-notes`

## Summary

Report:
- Version released: VERSION
- Source: develop (standard) or release/VERSION (selective)
- Number of commits included
- GitHub release: created / skipped
