# Claude Code `settings.json` — Reference

This file covers only the settings used by this repo. For all other settings, see the official docs.

**Official docs:**
- Settings: https://docs.anthropic.com/en/docs/claude-code/settings
- Permissions: https://docs.anthropic.com/en/docs/claude-code/security/permissions
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks

> **Comments not supported.** Standard JSON only — no `//` or `/* */`.
> Workaround: use `"_comment": "your note"` keys (unknown keys are silently ignored).

---

## File Locations & Scope Hierarchy

| Priority | File | Scope | Shared? |
|----------|------|--------|---------|
| 1 (highest) | `managed-settings.json` (system path) | All users on the machine | IT-deployed, cannot be overridden |
| 2 | CLI flags / `--settings` | Current session only | No |
| 3 | `.claude/settings.local.json` | You, in this project only | No (gitignored) |
| 4 | `.claude/settings.json` | Everyone on the project | Yes (commit to git) |
| 5 (lowest) | `~/.claude/settings.json` | You, all projects | No |

**Managed settings file paths (system-level, requires admin):**
- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux/WSL: `/etc/claude-code/managed-settings.json`
- Windows: `C:\Program Files\ClaudeCode\managed-settings.json`

**Scalars** (single values like `defaultMode`) are overridden by higher scope.
**Arrays** (`allow`, `deny`, `ask`) are merged across all scopes.

Run `/status` inside Claude Code to see which settings files are active and where each setting came from.

---

## Schema Validation

Add this to get autocomplete and inline validation in VS Code/Cursor:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

---

## `permissions` Object

### Rule Evaluation Order

```
deny → ask → allow
```

The **first matching rule wins.** Deny beats ask beats allow, regardless of pattern specificity. A specific `allow` rule cannot override a broad `deny` or `ask`.

This order applies **across scopes too**: a project-level `allow` cannot override a user-level or managed-level `deny`.

### Rule Syntax

```
"ToolName"               → matches all uses of that tool
"ToolName(pattern)"      → matches uses where the argument matches the pattern
```

Wildcards use gitignore-style glob syntax:
- `*` matches within a single directory level
- `**` matches recursively across directories
- Space before `*` matters: `Bash(ls *)` matches `ls -la` but NOT `lsof`

**Path prefixes in rules:**
- `~/.zshrc` → home-directory relative
- `./path` or `./**` → project root relative
- `**/pattern` → any location

### `permissions.defaultMode`

Controls behavior when a tool call doesn't match any rule.

| Value | Behavior |
|-------|----------|
| `"default"` | Read is auto-approved; Edit/Write/Bash prompt on first use per session |
| `"acceptEdits"` | Auto-approve file edits within working directory; Bash still prompts |
| `"plan"` | Read-only analysis mode; no edits or commands without approval |
| `"dontAsk"` | Silently deny anything not in the allow list. **Entries in `ask` are also silently denied** — there is no approval UI in this mode. |
| `"bypassPermissions"` | Skip all permission checks — **dangerous, use only in containers** |

Cycle modes interactively with `Shift+Tab`, or override for one session: `claude --permission-mode default`

### `permissions.allow`

Grants Claude permission to use a tool without asking.

```json
"allow": [
  "Read(~/.claude/projects/**/memory/**)",
  "Read(~/.claude/plans/**)",
  "Edit(~/.claude/plans/**)",
  "Write(~/.claude/plans/**)",
  "Bash(git status)",
  "Bash(git diff *)",
  "Bash(git add *)",
  "Bash(git commit *)"
]
```

### `permissions.ask`

Claude pauses and asks approval before proceeding.

> **Behavior in `dontAsk` mode**: `ask` entries are silently denied — `ask` functions as a second deny list. To approve a gated action, cycle modes with `Shift+Tab` to a prompting mode (`default` or `acceptEdits`), or relaunch with `claude --permission-mode default`.
>
> **`ask` beats `allow` across scopes**: a project-level `allow` rule cannot override a user-level `ask` rule. The only way to permit a user-level `ask` entry inside a specific project is if the project sets its own `defaultMode` to a prompting mode (project scalars override user scalars), or if the user runs that session in a prompting mode.

```json
"ask": [
  "Bash(git push *)",
  "Bash(npm install)",
  "WebFetch",
  "WebSearch"
]
```

### `permissions.deny`

Blocks Claude from using a tool entirely — no prompt, no override.

```json
"deny": [
  "Read(**/.env)",
  "Read(**/.ssh/**)",
  "Bash(sudo *)",
  "Bash(rm -rf *)",
  "Bash(curl *)"
]
```

**`Read` deny rules automatically cover recognized Bash file commands** (`cat`, `head`, `tail`, `sed`) — no need for duplicate `Bash(cat ...)` rules for paths already covered by `Read` denies. For example, `"Read(~/.aws/**)"` also blocks `cat ~/.aws/credentials`.

**Note on scope**: `deny` beats `allow` at every scope. User-level and managed-level `deny` rules cannot be unlocked by a project-level `allow` rule.

### `permissions.disableBypassPermissionsMode`

```json
"disableBypassPermissionsMode": "disable"
```

Prevents `bypassPermissions` mode and the `--dangerously-skip-permissions` CLI flag from ever being activated. Recommended in `~/.claude/settings.json` to prevent accidental use; set it in `managed-settings.json` to enforce it machine-wide.

### `permissions.additionalDirectories`

Grants Claude access to directories outside the current working directory.

```json
"additionalDirectories": []
```

Leave empty unless you have a specific need (e.g., a shared monorepo lib). A malicious project `.claude/settings.json` can expand this to broaden read scope — user-level `deny` rules still apply.

---

## `sandbox` Object

OS-level isolation for Bash commands — applies only to shell commands, not to Claude's native Read/Edit/Write tools (those are governed by `permissions` rules).

```json
"sandbox": {
  "enabled": true,
  "filesystem": {
    "denyRead": [
      "~/.aws/**",
      "~/.ssh/**",
      "~/.gnupg/**",
      "~/.config/gcloud/**",
      "~/.config/op/**",
      "~/.config/doctl/**",
      "~/.config/fly/**",
      "~/.config/stripe/**",
      "~/.config/heroku/**",
      "~/.config/pypoetry/**",
      "~/.config/configstore/**",
      "~/.config/helm/**",
      "~/.config/rclone/**",
      "~/.config/restic/**",
      "~/Library/**"
    ]
  },
  "network": {
    "allowedDomains": []
  }
}
```

`sandbox.filesystem.denyRead` is enforced at the OS level and covers arbitrary subprocesses (Python, Node, etc.) — not just Claude's own tool calls. This is stronger enforcement than `permissions.deny` alone.

**`allowedDomains: []`** blocks all outbound network from sandboxed shell commands (including `git push`, `npm install`). Add domains you need, e.g. `"github.com"`, `"*.npmjs.org"`.

The sandbox automatically merges `Read`/`Edit` deny rules from `permissions` into its boundary — you don't need to duplicate every `Read` deny in `sandbox.filesystem.denyRead`. The sandbox-specific paths are for OS-level enforcement of anything not already covered by permission rules.

**Two-tier pattern for CLI tools that authenticate as subprocesses:** some CLIs (e.g. `gh`, `netlify`, `vercel`) need to read their own credential files at runtime. Blocking them in `sandbox.denyRead` breaks authentication entirely. The solution is to add them to `permissions.deny` only — this prevents Claude's native Read tool from reading the token files directly, while leaving the subprocess free to authenticate normally. To apply this pattern to a new CLI: add `"Read(~/.config/<tool>/**)"` (or `"Read(~/.<tool>/**)"`) to `permissions.deny`, and do **not** add it to `sandbox.denyRead`.

**Platform requirements:**
- macOS: works out of the box (uses Seatbelt)
- Linux/WSL2: install `bubblewrap` and `socat` first

---

## `cleanupPeriodDays`

How many days to keep local session transcript files before auto-deleting. Default is 30 days.

```json
"cleanupPeriodDays": 7
```

---

## `includeCoAuthoredBy`

Whether to add Claude's co-author byline to git commits and PRs.

```json
"includeCoAuthoredBy": false
```

---

## `autoUpdatesChannel`

```json
"autoUpdatesChannel": "stable"   // ~1 week behind latest; skips known bad releases
```

---

## `hooks`

Run custom shell scripts at lifecycle events (`PreToolUse`, `PostToolUse`, `Stop`, `Notification`).

A `PreToolUse` hook can approve, deny, or modify a tool call at runtime. Hooks run at the OS level and are not blocked by `Bash` deny rules — they are the most dangerous vector for malicious `.claude/settings.json` files.

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "echo 'Claude wants to run bash' >> ~/claude-audit.log"
        }
      ]
    }
  ]
}
```

---

## `disableAllHooks`

Kill switch that disables all hooks and the `statusLine` command. When set in managed settings, users cannot override it.

```json
"disableAllHooks": true
```

This repo uses `allowManagedHooksOnly` instead (see below), which blocks project/user hooks while still running the statusline defined in managed settings.

---

## `allowManagedHooksOnly` *(managed settings only)*

Blocks all project-level and user-level hooks. Only hooks defined in `managed-settings.json` itself can run. This is the preferred alternative to `disableAllHooks` when you still want a managed statusline.

```json
"allowManagedHooksOnly": true
```

Cannot be set in user or project settings — managed scope only.

---

## `disableSkillShellExecution`

Disables inline shell execution (`` !`...` `` and `` ```! `` blocks) in skills and custom slash commands. Has no effect on bundled or managed skills. Most useful in managed settings.

```json
"disableSkillShellExecution": true
```

---

## `allowManagedPermissionRulesOnly` *(managed settings only)*

Causes user-level and project-level `allow`/`ask`/`deny` rules to be completely ignored — only permission rules defined in `managed-settings.json` apply. This closes the project-allow-expansion vector entirely.

**Not used by default in this repo.** This repo's design relies on per-project `.claude/settings.json` adding `Read(./**)` / `Edit(./**)` / `Write(./**)` allow rules so Claude can access files under `dontAsk` mode. Enabling `allowManagedPermissionRulesOnly` would ignore those project allows, requiring all allow rules to be enumerated in managed settings instead.

Enable only if you're prepared to manage all permission rules centrally.

```json
"allowManagedPermissionRulesOnly": true
```

---

## Tips & Gotchas

**Specificity only matters within the same rule tier.** Deny always beats ask, and ask always beats allow — regardless of how specific the pattern is. A specific `allow: ["Read(~/.claude/**)"` does NOT override a bare `ask: ["Read"]` or `deny: ["Read"]`. To allow specific paths while blocking others, use `defaultMode: "dontAsk"` and enumerate paths in `allow`.

**Arrays merge across scopes.** Permission `allow`, `deny`, `ask` arrays from multiple settings files are combined. A project's `.claude/settings.json` can add deny rules on top of your user-level ones.

**Verify with `/permissions`** inside a session to see all active rules and which settings file each came from.

**Test safely with `plan` mode** (`defaultMode: "plan"`) when working on unfamiliar codebases — Claude can read and analyze but cannot make any changes.

**Absolute paths need `//` prefix in permission rules.** `/Users/you/file` is treated as project-relative. Use `//Users/you/file` for true absolute paths. This differs from sandbox filesystem paths, which use normal `/`.

**JSONC (comments) not supported.** Use `"_comment": "..."` keys as a workaround — unknown keys are silently ignored.
