# claude-setup

Bootstrap helper for getting [Claude Code](https://claude.ai/code) configured and running on a new machine.

## What's in here

| File | Description |
|------|-------------|
| `claude/` | Mirror of `~/.claude/` — files here are copied to `~/.claude/` by `setup.sh` |
| `claude/settings.json` | Opinionated user-level Claude Code settings |
| `claude/statusline-command.sh` | Status line script showing cwd, git branch, model, context %, and rate limit usage |
| `claude-settings-reference.md` | Full reference for all `settings.json` options |
| `setup.sh` | Copies `claude/` to `~/.claude/`; validates install |

---

## Quick Start

### 1. Install Claude Code

**macOS / Linux / WSL:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://claude.ai/install.ps1 | iex
```

**macOS (Homebrew):**
```bash
brew install --cask claude-code        # stable (~1 week behind)
brew install --cask claude-code@latest # latest releases
```

> Note: native installs auto-update in the background. Homebrew does not — run `brew upgrade claude-code` manually.

### 2. Apply settings

```bash
./setup.sh
```

This backs up any existing `~/.claude/settings.json` and replaces it with the one from this repo, and installs the statusline script. Review `settings.json` first and adjust anything you want to change.

### 3. Log in

```bash
claude
```

Follow the prompts to authenticate with your Claude.ai account (Pro/Max) or an Anthropic Console API key.

---

## What the settings do

The included `settings.json` is set up with these principles:

- **Safe defaults**: `Read`, `Edit`, and `Write` require approval by default, with specific `allow` rules for common safe operations.
- **Sensitive file protection**: `.env`, credentials, SSH keys, cloud credentials, and `node_modules` are blocked from reads.
- **Dangerous command blocking**: `sudo`, `rm -rf`, `curl`, `wget`, network exfiltration tools, and service managers are denied outright.
- **Approval prompts for higher-risk actions**: `git push`, `npm install`, `pip install`, web fetch/search, and `chmod` ask for approval.
- **No co-author attribution**: Claude's name is not added to git commits.
- **Stable update channel**: updates lag ~1 week behind latest to avoid known-bad releases.
- **`bypassPermissions` mode disabled**: prevents accidentally running with no permission checks.

See `claude-settings-reference.md` for a full explanation of every setting.

---

## Keeping settings in sync

If you update files in `claude/`, re-apply with:

```bash
./setup.sh
```
