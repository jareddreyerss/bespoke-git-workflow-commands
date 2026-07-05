# Bespoke Git Workflow

Automated release command for Claude Code. Replaces the manual git release process with a single command that handles safety checks, merging to main, and tagging.

## What it does

Runs the standard release flow:

1. Discovers the latest version from git tags and offers increment options (patch, minor, major)
2. Checks working tree is clean and tag doesn't exist
3. Pulls latest develop
4. Detects if a pre-built `release/x.x.x` branch exists (for selective releases) or uses develop directly
5. Shows what will ship and asks for confirmation
6. Merges to main, tags, and pushes
7. Optionally creates a GitHub release (requires [GitHub CLI](https://cli.github.com/))

## Install

Clone this repo into your `~/.claude` folder to make the command available globally across all projects:

```bash
git clone <repo-url> /tmp/bespoke-git-workflow-commands
cp /tmp/bespoke-git-workflow-commands/.claude/commands/release.md ~/.claude/commands/release.md
```

To scope it to a single project instead, copy into that project's `.claude/commands/` directory:

```bash
cp /tmp/bespoke-git-workflow-commands/.claude/commands/release.md your-project/.claude/commands/release.md
```

## Usage

```
/release              # auto-detect version from tags
/release 1.2.3        # skip discovery, use explicit version
/release --gh-release # auto-detect version + create GitHub release
/release 1.2.3 --gh-release
```

## Selective releases

If certain features on develop need to be excluded, create a `release/x.x.x` branch from `develop` manually before running the command. Cherry-pick or include only the commits you want, then run `/release`. The command will detect the release branch and use it instead of develop.

## Testing

> **Warning:** Test scripts destroy all git history in the repo they run in. Only run these in a disposable repo — never in your real project.

Create a disposable repo, copy the `test/` folder into it, then run a setup script. Each script sources `test/reset.sh` which nukes `.git`, re-inits, clones the latest release commands from GitHub, and creates `main` (tagged `1.0.0`) + `develop`.

```bash
# Create a disposable test repo and copy test scripts into it
git init /tmp/test-release
cp -R test /tmp/test-release/
cd /tmp/test-release

# Standard release: develop → main
bash test/setup-standard-release.sh

# Or selective release: release branch → main
bash test/setup-selective-release.sh
```

After running a setup script, run `/release` from the same repo to test the flow.