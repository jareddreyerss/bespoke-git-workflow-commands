---
description: "Automate a production release: merge develop (or a pre-built release branch) into main, tag, and push."
---

You are executing a production release workflow.

Follow these steps exactly, stopping if any step fails:

## Step 0: Version Discovery

1. Run `git tag --list --sort=-v:refname` and filter to tags matching semver patterns (`X.Y.Z` or `vX.Y.Z`).
2. **If matching tags are found:**
   - Identify the latest version (strip the `v` prefix if present for comparison).
   - Present it to the user and offer increment options:
     - **Patch**: e.g. 1.2.3 → 1.2.4
     - **Minor**: e.g. 1.2.3 → 1.3.0
     - **Major**: e.g. 1.2.3 → 2.0.0
     - **Custom**: enter a version manually
   - Ask the user which option they'd like. **You MUST wait for the user to reply before continuing.** Do NOT run any commands until the user has chosen.
3. **If no matching tags are found:**
   - Inform the user: "No existing version tags found."
   - Ask the user to enter a version number manually. **You MUST wait for the user to reply before continuing.**
4. After selection, verify the chosen tag doesn't already exist (`git tag -l VERSION`). If it does, abort: "Tag VERSION already exists. Choose a different version."

Use the selected version as VERSION for all subsequent steps.

Also ask the user whether they want to **create a GitHub release** after tagging — optional, defaults to no.

## Step 1: Safety Checks

Run all checks using the terminal and abort with a clear message if any fail:

1. Verify the working tree is clean (`git status --porcelain` should be empty). If not, abort: "Working tree is not clean. Commit or stash changes before releasing."
2. Verify the tag VERSION does not already exist (`git tag -l VERSION`). If it does, abort: "Tag VERSION already exists. Choose a different version."
3. Verify the `develop` branch exists locally or on origin. If not, abort: "No develop branch found."
4. Verify the `main` branch exists locally or on origin. If not, abort: "No main branch found."
5. Check if a `release/VERSION` branch exists locally or on origin. Note the result — this determines the release path:
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
git switch release/VERSION
git pull origin release/VERSION
```
Show what will ship: `git log main..release/VERSION --oneline`

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

Show the user a summary of what was done locally:
- The merge commit on main
- The tag created
- The commits included (`git log --oneline -5`)

Ask the user: "Everything looks good locally. Ready to push to origin? (yes/no)"

**You MUST wait for the user to reply before continuing.** Do NOT run any push or release commands until the user has explicitly said "yes". If the user says "no", inform them they can undo with `git reset --hard HEAD~1 && git tag -d VERSION` and abort.

## Step 7: Push to origin (only after user confirms Step 6)

```
git push origin main
git push origin VERSION
```

## Step 8: GitHub Release (only if user opted in)

First, check if `gh` is installed by running `which gh`.

- **If `gh` is not installed**: inform the user that GitHub CLI is required for this step and provide install instructions (`brew install gh`). Skip this step.
- **If `gh` is installed**: run `gh release create VERSION --generate-notes`

## Summary

Report:
- Version released: VERSION
- Source: develop (standard) or release/VERSION (selective)
- Number of commits included
- GitHub release: created / skipped