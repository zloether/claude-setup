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
| `macos-library-deny-paths.md` | Categorized list of sensitive `~/Library/` paths; reference for macOS app developers who need to narrow the blanket `Read(~/Library/**)` deny |
| `setup.sh` | Copies `claude/` to `~/.claude/`, validates the environment; run first after cloning |
| `.claude/settings.json` | Project-level settings for this repo — allows Read/Edit/Write within this directory |
| `CLAUDE.md` | Minimal project-level instructions pointing here |
| `AGENTS.md` | This file — instructions for AI agents assisting with setup |
| `managed-settings.json` | Sample system-level settings for maximum lockdown (see README) |

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
- Back up and replace `~/.claude/settings.json` and `CLAUDE.md` (no sudo needed)
- Deploy `managed-settings.json` to the system path (requires sudo — this is expected)
- Install `statusline-command.sh` to `/usr/local/bin/claude-statusline` (root-owned, requires sudo)

The sudo step is intentional: managed settings and the statusline script must be root-owned so they cannot be modified by prompt injection or a malicious repo.

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
4. **Verify**: after applying, run `claude --version` and confirm the user can open a session. Then open a session and run `/status` to confirm that `managed-settings.json` is listed as an active settings source. If it is missing, hook isolation and sandbox restrictions for `~/Library` and sensitive `~/.config` subdirectories are not in effect — follow the manual steps printed by `setup.sh` to deploy it.
5. **Set up project-level settings**: remind the user that each project needs a `.claude/settings.json` to allow Read/Edit/Write within the project directory (see README for the template). Without it, Claude cannot read or write project files at all — `dontAsk` mode denies everything not explicitly allowed. Always use scoped patterns like `"Read(./**)"` instead of bare `"Read"` — bare patterns allow reads across the entire filesystem. This repo's own `.claude/settings.json` is an example of the scoped form.
6. **Warn about untrusted repos**: running Claude Code inside a repo the user doesn't control is risky. A repo's `.claude/settings.json` can define hooks that execute shell commands automatically (no permission prompt), add `allow` rules and expand `additionalDirectories` to broaden Claude's read scope, and override scalar settings. User-level `deny` rules still hold across scopes (deny beats allow at every level), so the expanded deny list in this repo protects high-value targets (browser data, mail, Keychain, password managers, shell history) even in malicious projects. **Hooks are the most dangerous vector** — they run silently at every tool use, are not blocked by `Bash` deny rules, and can only be reliably disabled via `managed-settings.json` (this repo uses `allowManagedHooksOnly: true`). Instruct the user to inspect `.claude/settings.json` (especially any `hooks` key, `additionalDirectories`, and broad `allow` rules) before opening Claude in an unfamiliar repo. Prompt injection from any file Claude reads is also a real concern.

---

## Customizing `settings.json` Before Applying

The `settings.json` in this repo is a reasonable starting point with:
- `defaultMode: "dontAsk"` — Claude silently denies any tool not in the allow list; memory (`~/.claude/projects/*/memory/`) read and plans (`~/.claude/plans/`) read/edit/write paths are pre-allowed; strict deny rules for sensitive files (credentials, **blanket `~/Library/**` block** covering Keychain/browsers/Mail/iMessage/password managers/app data, Linux browser/communications equivalents, password stores, shell histories, CLI tool credentials) and dangerous shell commands. Per the official docs, `Read` deny rules also block the recognized Bash file commands `cat`, `head`, `tail`, and `sed` — no need to duplicate as `Bash(cat …)` rules. **macOS app developers** who need to read their own app's data under `~/Library/Application Support/<MyApp>/` must narrow the user-level (and possibly managed) deny — `deny` beats `allow` across scopes, so project allows cannot punch through.
- `ask` rules for higher-risk actions (git push, npm install, pip install, python execution, web fetch/search, chmod, rm, memory writes). **In `dontAsk` mode, `ask` entries are silently denied — `ask` functions as a second deny list.** To approve a gated action, cycle modes with `Shift+Tab` to a prompting mode (`default` or `acceptEdits`) or relaunch with `claude --permission-mode default`. The lockdown holds until you explicitly opt in for the session.
- `allow` rules for common safe operations (read-only git commands, plans/memory reads); `git add` and `git commit` are **not** in `allow` by default — add them to a project-level `allow` to enable autonomous commits in that project
- Sandbox enabled with OS-level `denyRead` for credential paths (`~/.aws`, `~/.ssh`, `~/.gnupg`, and targeted `~/.config` subdirs: `gcloud`, `op`, `doctl`, `fly`, `stripe`, `heroku`, `pypoetry`, `configstore`, `helm`, `rclone`, `restic`) — note the sandbox applies to shell (Bash) commands only, not to Claude's native Read/Edit/Write tools, which are governed by permission rules. CLI tools that need to authenticate as subprocesses (`gh`, `netlify`, `vercel`) are intentionally omitted from `sandbox.denyRead` so the binary can read its own credentials, but are still listed in `permissions.deny` so Claude's native Read tool cannot access the token files directly. To add a new CLI tool with the same treatment: add it to `permissions.deny` only, not to `sandbox.denyRead`.
- `cleanupPeriodDays: 7` — transcripts deleted after 7 days
- `bypassPermissions` mode disabled for safety
- Dark theme, stable update channel, co-author attribution disabled

Note on Python: both `python *.py` / `python3 *.py` and the broader `python *` / `python3 *` are in `ask`. This means *all* Python execution is gated by default — even running a basic script requires switching out of `dontAsk` for the session. Projects that routinely run Python can opt back in via their own `.claude/settings.json` setting `"defaultMode": "default"` (project scalars override user scalars). A project-level `allow` rule alone cannot override a user-level `ask` rule.

Before running `./setup.sh`, review `settings.json` and adjust for the user's environment. See `claude-settings-reference.md` for the settings used in this repo. For authoritative behavior details, fetch from the official docs rather than relying on the local reference file alone.

`setup.sh` deploys `managed-settings.json` by default (the sudo step). It uses `allowManagedHooksOnly: true` to block project and user hooks while keeping the statusline (which is defined in managed settings and points to the root-owned `/usr/local/bin/claude-statusline`). Key trade-off: `sandbox.network.allowedDomains: []` blocks all outbound shell network until the user adds domains they need (e.g. `"github.com"`, `"*.npmjs.org"`).

---

## Official Documentation

When verifying behavior, fetch from these URLs rather than relying solely on the local reference file:

- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Permissions: https://docs.anthropic.com/en/docs/claude-code/security/permissions
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks

---

## Re-applying After Changes

If you edit any files under `claude/` and want to re-apply:

```bash
./setup.sh
```

`setup.sh` always backs up the existing `settings.json` first.
