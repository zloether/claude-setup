# claude-setup

Bootstrap helper for getting [Claude Code](https://claude.ai/code) configured and running on a new machine.

## What's in here

| File | Description |
|------|-------------|
| `claude/` | Mirror of `~/.claude/` — files here are copied to `~/.claude/` by `setup.sh` |
| `claude/CLAUDE.md` | Global instructions for Claude (e.g. git workflow rules) |
| `claude/settings.json` | Opinionated user-level Claude Code settings |
| `claude/statusline-command.sh` | Status line script showing cwd, git branch, model, context %, and rate limit usage — deployed to a root-owned system path by `setup.sh` |
| `claude-settings-reference.md` | Full reference for all `settings.json` options |
| `macos-library-deny-paths.md` | Reference list of sensitive `~/Library/` paths for macOS app developers narrowing the blanket deny |
| `setup.sh` | Copies `claude/` to `~/.claude/`; validates install |
| `.claude/settings.json` | Project-level settings for this repo (allows Read/Edit/Write within this directory) |
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

This does two things:

1. **User-level** (no sudo): backs up and replaces `~/.claude/settings.json` and `CLAUDE.md`
2. **System-level** (requires sudo): deploys `managed-settings.json` to the platform path and installs `statusline-command.sh` to `/usr/local/bin/claude-statusline` (root-owned)

The sudo prompt is expected — managed settings and the statusline script must be root-owned so they cannot be modified by prompt injection. Review `settings.json` first and adjust anything you want to change before running.

### 3. Log in

```bash
claude
```

Follow the prompts to authenticate with your Claude.ai account (Pro/Max) or an Anthropic Console API key.

---

## What the settings do

The included `settings.json` is set up with these principles:

- **`dontAsk` mode**: Claude silently denies any tool call not in the `allow` list. File reads and edits within a project are enabled by a project-level `.claude/settings.json` (see below). Plan reads/writes (`~/.claude/plans/`) and memory reads (`~/.claude/projects/*/memory/`) are pre-allowed at user level.
- **Sensitive file protection**: `.env`, credentials, SSH keys, cloud credentials, `node_modules`, Desktop/Documents/Downloads, **all of `~/Library/**`** (blanket block covers Keychain, browser data, iMessage/Mail/Calendar/Contacts/iPhone backups, Slack/Signal/Discord local data, password manager stores, app preferences, and any other sensitive paths we haven't enumerated), Linux equivalents for browsers and communications apps (`~/.mozilla/**`, `~/.config/google-chrome/**`, `~/.config/Signal/**`, etc.), `pass`/`op` password stores, shell/REPL histories (`~/.zsh_history`, `~/.bash_history`, `~/.python_history`, etc.), and CLI tool credentials (`doctl`, `heroku`, `fly`, `netlify`, `vercel`) are all blocked from reads. Per the official docs, `Read` deny rules also block recognized Bash file commands (`cat`, `head`, `tail`, `sed`) automatically — they don't need duplicate `Bash(cat …)` rules.

  > **macOS app development trade-off**: the blanket `Read(~/Library/**)` deny applies at user and managed scope. If you're developing a macOS app and need to read your own app's data at `~/Library/Application Support/<YourApp>/` or its logs at `~/Library/Logs/<YourApp>/`, you'll need to remove or scope down the user-level deny — deny beats allow across scopes, so a project-level `allow` cannot punch through. To re-enable: edit `~/.claude/settings.json` to narrow the deny, and (if you also need managed-scope relaxation) edit `/Library/Application Support/ClaudeCode/managed-settings.json` with sudo. See `macos-library-deny-paths.md` for a categorized list of high-value `~/Library/` paths to keep blocked after relaxing the blanket rule.
- **Dangerous command blocking**: `sudo`, `rm -rf`, `curl`, `wget`, network exfiltration tools, and service managers are denied outright.
- **Higher-risk actions are gated**: `git push`, `npm install`, `pip install`, `python`/`python3` execution, web fetch/search, `chmod`, `rm`, and memory writes are in the `ask` list. **In `dontAsk` mode, `ask` is effectively a second deny list — there is no approval prompt.** To run a gated action, cycle modes with `Shift+Tab` to a prompting mode (`default` or `acceptEdits`), or exit and relaunch with `claude --permission-mode default`. The lockdown holds until you explicitly opt in for the session.
- **Memory writes gated by design**: Memory persists across sessions, which makes it a high-value target for prompt-injection attacks (a malicious memory survives and re-fires every session). Gating writes ensures a human reviews each save. Periodically audit `~/.claude/projects/*/memory/` for entries that weren't intentionally saved — there is no automatic mechanism to expire memories written under injection conditions.
- **No co-author attribution**: Claude's name is not added to git commits.
- **Stable update channel**: updates lag ~1 week behind latest to avoid known-bad releases.
- **`bypassPermissions` mode disabled**: prevents accidentally running with no permission checks.

See `claude-settings-reference.md` for the settings used in this repo, or fetch the official docs for authoritative behavior details: https://docs.anthropic.com/en/docs/claude-code/settings

---

## Keeping settings in sync

If you update files in `claude/`, re-apply with:

```bash
./setup.sh
```

---

## Project-level `settings.json`

With `dontAsk` mode, Claude denies any file operation not covered by an `allow` rule. A project-level `.claude/settings.json` adds allow rules scoped to that directory, giving Claude free access within the project without prompting. Without it, Claude cannot read or write project files at all.

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
      "Read(./**)",
      "Edit(./**)",
      "Write(src/**)"
    ]
  }
}
```

The path-specific deny rules for sensitive files (`.env`, SSH keys, credentials, etc.) remain in force regardless — no project-level allow can override those.


---

## System-level settings (`managed-settings.json`)

`setup.sh` deploys `managed-settings.json` to the platform path automatically (this is the sudo step). Settings here are **priority 1 — they cannot be overridden by project or user settings**, including by a malicious `.claude/settings.json` in a cloned repo.

| Platform | Path |
|----------|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

**What it locks down:**

| Setting | Effect |
|---------|--------|
| `allowManagedHooksOnly: true` | Only hooks defined in managed settings can run — blocks project-level and user-level hooks entirely |
| `statusLine` | Configures the statusline via the managed hook allowlist, pointing to the root-owned `/usr/local/bin/claude-statusline` script |
| `disableSkillShellExecution: true` | Blocks shell execution inside skills and slash commands |
| `disableBypassPermissionsMode: "disable"` | Prevents `--dangerously-skip-permissions` from ever running |
| `sandbox.network.allowedDomains: []` | Blocks all outbound network from sandboxed shell commands |
| `sandbox.filesystem.denyRead` | OS-level block on credential paths (`.aws`, `.ssh`, `.gnupg`, `gcloud`) |
| `permissions.deny` | Mirrors the deny rules from `settings.json`, enforced at managed priority |
| `cleanupPeriodDays: 7` | Session transcripts deleted after 7 days |

**Why `allowManagedHooksOnly` instead of `disableAllHooks`:**
`disableAllHooks: true` would kill the statusline along with malicious hooks. `allowManagedHooksOnly: true` blocks project and user hooks while still allowing the statusline defined here in managed settings.

**Why the statusline script must be root-owned:**
If the script lived at `~/.claude/statusline-command.sh` (user-writable), a prompt injection could overwrite it and get code executed every 5 seconds outside the permission system. Deploying it to `/usr/local/bin/claude-statusline` (root-owned) closes that vector.

**`sandbox.network.allowedDomains: []`** blocks all outbound from shell commands, including `git push`, `npm install`, `pip install`. Add domains you need, e.g. `"github.com"`, `"*.npmjs.org"`, `"pypi.org"`.

These settings apply machine-wide. Don't deploy on a shared machine without understanding the impact.
---

## Threat model and limitations

The `Bash` deny rules in `settings.json` are a **best-effort guardrail**, not a security boundary. Claude Code cannot fully enforce them against shell-level evasion (e.g. `bash -c "..."`, `python -c "..."`, arbitrary subprocess file reads). The shipped settings add deny rules for the most common evasion patterns and mirror critical paths into the managed sandbox's `filesystem.denyRead` for OS-level enforcement — but you should assume that a sufficiently motivated prompt injection in any file Claude reads could attempt to bypass these rules.

Key assumptions:
- **Prompt injection is real**: any file Claude reads in your project (README, config, comments) can attempt to redirect Claude's behavior. Review what you allow Claude to read in untrusted repos.
- **`Read` deny ≠ subprocess deny**: per the official docs, `Read` and `Edit` deny rules apply to Claude's native file tools *and* to the Bash file commands Claude Code recognizes (`cat`, `head`, `tail`, `sed`). They do **not** apply to arbitrary subprocesses that open files indirectly (e.g. a `python script.py` that calls `open()`). For OS-level enforcement that covers all subprocesses, use the `sandbox.filesystem.denyRead` list — `managed-settings.json` mirrors the most sensitive paths there.
- **Sandbox covers shell commands only**: `sandbox.enabled: true` enforces `filesystem.denyRead` at the OS level for Bash subprocesses and their children. The sandbox automatically merges `Read`/`Edit` deny rules into its boundary, so adding a `Read(…)` deny rule also tightens the sandbox.
- **Project `.claude/settings.json` is trusted on load**: any repo you clone and run Claude in can add `allow` rules, expand `additionalDirectories`, and define hooks. Review project settings before accepting them.

### Warning: untrusted repos

**Do not run Claude Code inside a repo you don't trust.** A malicious `.claude/settings.json` in a cloned repo can:

- Define `hooks` (`PreToolUse`, `PostToolUse`, etc.) that run shell commands automatically — without a permission prompt — every time Claude uses a tool. These run at the OS level and are not blocked by your `Bash` deny rules.
- Add `allow` rules that grant tools your user settings did not enable. (Deny still beats allow across scopes, so user-level `deny` rules cannot be unlocked this way.)
- Expand `additionalDirectories` and pair it with `Read(~/**)`-style allow rules to make most of your home directory readable. The expanded user-level `deny` list in this repo blocks the highest-value targets (browser data, mail, Keychain, password managers, shell history, communications apps) regardless of what a project allows.
- Override scalar settings (e.g. re-enable `bypassPermissions` mode unless `disableBypassPermissionsMode` is set in managed settings — this repo's `managed-settings.json` sets it).

Hooks are the sharpest edge: they execute silently, merge across settings scopes, and the only reliable way to disable them machine-wide is via a system-level `managed-settings.json` (requires admin). User-level `disableAllHooks: true` can itself be overridden by a higher-priority project setting; this repo uses `allowManagedHooksOnly: true` in managed settings instead, which blocks all non-managed hooks.

**`git add` and `git commit` are in the allow list** by design, enabling Claude to stage and commit its own changes in autonomous workflows. The trade-off: prompt injection in any file Claude reads could stage and commit malicious changes silently — including modifications to `setup.sh` in this bootstrap repo, which runs with `sudo` and deploys to other machines. `git push` is in `ask` (silently denied in `dontAsk` mode), so changes stay local, but reviewing pending commits before pushing is important.

**Before opening Claude in an unfamiliar repo**, check whether `.claude/settings.json` exists and review its contents — especially any `hooks` key, any expansion of `additionalDirectories`, and any broad `allow` rules.

### Stricter lockdown option: `allowManagedPermissionRulesOnly`

For maximum hardening, `managed-settings.json` supports a managed-only setting `allowManagedPermissionRulesOnly: true`, which causes user- and project-level `allow`/`ask`/`deny` rules to be **completely ignored** — only managed permission rules apply. This closes the project-allow-expansion vector entirely.

The trade-off is significant: this repo's design relies on per-project `.claude/settings.json` adding `Read(./**)`, `Edit(./**)`, `Write(./**)` allow rules so Claude can access files in each project under `dontAsk` mode. With `allowManagedPermissionRulesOnly: true`, those project allows are ignored, and you'd need to enumerate all allow rules in managed settings instead. **Not enabled by default** in this repo. Enable it only if you're prepared to manage all permission rules centrally.
