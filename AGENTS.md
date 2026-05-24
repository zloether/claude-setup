# AGENTS.md — Claude Code Setup Repo Instructions

This repo is a bootstrap helper for configuring a personal Claude Code instance. Use it to apply a curated `settings.json`, reference documentation, and a setup script to a new or existing Claude Code installation.

---

## Repo Contents

| File | Purpose |
|------|---------|
| `claude/` | Mirror of `~/.claude/` — everything here is copied to `~/.claude/` by `setup.sh` |
| `claude/CLAUDE.md` | Global instructions for Claude (e.g. git workflow rules) |
| `claude/settings.json` | Opinionated user-level Claude Code settings |
| `claude/statusline-command.sh` | Status line script: cwd, git branch, model, context %, rate limit usage |
| `claude-settings-reference.md` | Comprehensive reference for every `settings.json` key with examples |
| `setup.sh` | Copies `claude/` to `~/.claude/`, validates the environment; run first after cloning |
| `.claude/settings.json` | Project-level settings for this repo — re-enables Read/Edit/Write so Claude can work in this directory |
| `CLAUDE.md` | Minimal project-level instructions pointing here |
| `AGENTS.md` | This file — instructions for AI agents assisting with setup |

---

## How to Apply This Configuration

### Step 1 — Install Claude Code (if not already installed)

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
brew install --cask claude-code
```

### Step 2 — Run the setup script

```bash
./setup.sh
```

This will:
- Back up any existing `~/.claude/settings.json`
- Copy `settings.json` from this repo to `~/.claude/settings.json`
- Install `statusline-command.sh` to `~/.claude/statusline-command.sh`
- Verify the installation is working

### Step 3 — Authenticate

```bash
claude
```

Follow the login prompts. Claude Code supports Claude.ai (Pro/Max) or Anthropic Console (API key).

---

## When Helping a User Set Up Claude Code

If you are an AI agent assisting someone with setup, follow this checklist:

1. **Check if Claude Code is installed**: run `claude --version`. If it fails, direct the user to run the native installer above for their platform.
2. **Apply settings**: run `./setup.sh` to copy `settings.json` and `statusline-command.sh` to `~/.claude/`.
3. **Customize settings**: ask the user which settings they want to change before applying. Key things to personalize:
   - `theme`: `"dark"` or `"light"`
   - `permissions.allow` / `permissions.deny`: adjust to match their workflow
   - `includeCoAuthoredBy`: whether to add Claude attribution to commits
   - `autoUpdatesChannel`: `"stable"` (recommended) or `"latest"`
4. **Verify**: after applying, run `claude --version` and confirm the user can open a session.
5. **Set up project-level settings**: remind the user that each project needs a `.claude/settings.json` to re-enable Read/Edit/Write (see README for the template). Always use scoped patterns like `"Read(./**)"` instead of bare `"Read"` — bare patterns grant global read access across the filesystem. This repo's own `.claude/settings.json` is an example of the scoped form.
6. **Warn about untrusted repos**: running Claude Code inside a repo the user doesn't control is risky. A repo's `.claude/settings.json` can define hooks that execute shell commands automatically (no permission prompt), add `allow` rules that re-enable denied tools, and override user-level settings. Hooks are the most dangerous vector — they run silently at every tool use and are not blocked by `Bash` deny rules. Instruct the user to inspect `.claude/settings.json` (especially any `hooks` key) before opening Claude in an unfamiliar repo. Prompt injection from any file Claude reads is also a real concern.

---

## Customizing `settings.json` Before Applying

The `settings.json` in this repo is a reasonable starting point with:
- Strict deny rules for sensitive files and dangerous commands
- `ask` rules for higher-risk actions (git push, npm install, pip install)
- `allow` rules for common safe operations (git add/commit, run `python *.py` scripts)
- Sandbox enabled with OS-level `denyRead` for credential paths (`~/.aws`, `~/.ssh`, `~/.gnupg`, `~/.config/gcloud`)
- `cleanupPeriodDays: 7` — transcripts deleted after 7 days
- `bypassPermissions` mode disabled for safety
- Dark theme, stable update channel, co-author attribution disabled

Note: `python *.py` / `python3 *.py` are in `allow`, while the broader `python *` / `python3 *` are in `ask`. This means plain script execution is auto-approved but arbitrary python invocations (with flags, module args, etc.) prompt first.

Before running `./setup.sh`, review `settings.json` and adjust for the user's environment. See `claude-settings-reference.md` for a full explanation of every option.

---

## Re-applying After Changes

If you edit any files under `claude/` and want to re-apply:

```bash
./setup.sh
```

`setup.sh` always backs up the existing `settings.json` first.
