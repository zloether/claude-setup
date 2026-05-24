# claude-setup

Bootstrap helper for getting [Claude Code](https://claude.ai/code) configured and running on a new machine.

## What's in here

| File | Description |
|------|-------------|
| `claude/` | Mirror of `~/.claude/` — files here are copied to `~/.claude/` by `setup.sh` |
| `claude/CLAUDE.md` | Global instructions for Claude (e.g. git workflow rules) |
| `claude/settings.json` | Opinionated user-level Claude Code settings |
| `claude/statusline-command.sh` | Status line script showing cwd, git branch, model, context %, and rate limit usage |
| `claude-settings-reference.md` | Full reference for all `settings.json` options |
| `setup.sh` | Copies `claude/` to `~/.claude/`; validates install |
| `.claude/settings.json` | Project-level settings for this repo (enables Read/Edit/Write here) |
| `CLAUDE.md` | Minimal project instructions pointing to AGENTS.md |
| `AGENTS.md` | AI agent instructions for assisted setup |

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

- **`Read`/`Edit`/`Write` denied at user level**: these tools are in the user-level `deny` list, so Claude cannot read or modify files in any project unless a project-level `settings.json` explicitly re-allows them (see below).
- **Sensitive file protection**: `.env`, credentials, SSH keys, cloud credentials, and `node_modules` are blocked from reads.
- **Dangerous command blocking**: `sudo`, `rm -rf`, `curl`, `wget`, network exfiltration tools, and service managers are denied outright.
- **Approval prompts for higher-risk actions**: `git push`, `npm install`, `pip install`, web fetch/search, and `chmod` ask for approval.
- **Python scripts auto-allowed, broader invocations ask**: `python *.py` and `python3 *.py` are auto-allowed; patterns like `python script --flags` fall through to `ask`.
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

---

## Project-level `settings.json`

Because `Read`, `Edit`, and `Write` are denied in the user-level `settings.json`, every project you work in needs its own `.claude/settings.json` to re-enable them. Without it, Claude will be blocked from reading or writing any files.

Create `.claude/settings.json` at the root of each project:

```json
{
  "permissions": {
    "allow": [
      "Read(./**)",
      "Edit(./**)",
      "Write(./**)"
    ]
  }
}
```

You can scope these more tightly if needed — for example, restricting writes to a specific directory:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Edit",
      "Write(src/**)"
    ]
  }
}
```

Scoped project-level `allow` rules (e.g. `Read(./**)`) override the generic user-level `deny` for `Read`, because they are more specific. However, the explicitly-patterned deny rules for sensitive files (`.env`, SSH keys, credentials, etc.) remain in force — no project-level allow can override those unless it exactly matches one of those specific patterns.


---

## Optional: system-level lockdown (`managed-settings.json`)

For stronger protection, you can deploy a `managed-settings.json` at the system level. Settings here are **priority 1 — they cannot be overridden by project or user settings**, including by a malicious `.claude/settings.json` in a cloned repo.

This repo includes a sample at [`managed-settings.json`](managed-settings.json). Copy it to the platform path with admin privileges:

| Platform | Path |
|----------|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

**What the sample locks down:**

| Setting | Effect |
|---------|--------|
| `disableAllHooks: true` | Disables all hooks and the statusLine command — unoverridable by any project |
| `disableSkillShellExecution: true` | Blocks shell execution inside skills and slash commands |
| `disableBypassPermissionsMode: "disable"` | Prevents `--dangerously-skip-permissions` from ever running |
| `sandbox.network.allowedDomains: []` | Blocks all outbound network from sandboxed shell commands |
| `sandbox.filesystem.denyRead` | OS-level block on credential paths (`.aws`, `.ssh`, `.gnupg`, `gcloud`) |
| `permissions.deny` | Mirrors the deny rules from `settings.json`, enforced at managed priority |
| `cleanupPeriodDays: 7` | Session transcripts deleted after 7 days |

**Trade-offs to understand before deploying:**

- `disableAllHooks: true` kills the statusLine. You lose the context %, rate limit, and branch display. This is intentional — it's the only way to make hook disabling unoverridable.
- `sandbox.network.allowedDomains: []` blocks **all** outbound from shell commands, including `git push`, `npm install`, `pip install`. Add domains you need, e.g. `"github.com"`, `"*.npmjs.org"`, `"pypi.org"`.
- These settings apply machine-wide to all users. Don't deploy on a shared machine without understanding the impact.

`setup.sh` does **not** install this file — it requires a manual copy with admin privileges by design.
---

## Threat model and limitations

The `Bash` deny rules in `settings.json` are a **best-effort guardrail**, not a security boundary. Claude Code cannot enforce them against shell-level evasion (e.g. `bash -c "..."`, `python -c "..."`, indirect reads via `cat`). The shipped settings add deny rules for the most common evasion patterns, and the `sandbox` section adds OS-level enforcement for sensitive credential paths — but you should assume that a sufficiently motivated prompt injection in any file Claude reads could attempt to bypass these rules.

Key assumptions:
- **Prompt injection is real**: any file Claude reads in your project (README, config, comments) can attempt to redirect Claude's behavior. Review what you allow Claude to read in untrusted repos.
- **`Bash` deny ≠ shell deny**: deny rules match the command string Claude proposes; they do not intercept child processes or shell builtins.
- **Sandbox is the actual barrier**: `sandbox.enabled: true` enforces the `filesystem.denyRead` list at the OS level, bypassing Bash deny entirely for those paths.
- **Project `.claude/settings.json` is trusted on load**: any repo you clone and run Claude in can add `allow` rules and define hooks. Review project settings before accepting them.

### Warning: untrusted repos

**Do not run Claude Code inside a repo you don't trust.** A malicious `.claude/settings.json` in a cloned repo can:

- Define `hooks` (`PreToolUse`, `PostToolUse`, etc.) that run shell commands automatically — without a permission prompt — every time Claude uses a tool. These run at the OS level and are not blocked by your `Bash` deny rules.
- Add `allow` rules that re-enable tools your user settings deny.
- Override scalar settings (e.g. re-enable `bypassPermissions` mode).

Hooks are the sharpest edge: they execute silently, merge across settings scopes, and the only reliable way to disable them machine-wide is via a system-level `managed-settings.json` (requires admin). User-level `disableAllHooks: true` can itself be overridden by a higher-priority project setting.

**Before opening Claude in an unfamiliar repo**, check whether `.claude/settings.json` exists and review its contents — especially any `hooks` key.
