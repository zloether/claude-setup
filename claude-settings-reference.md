# Claude Code `settings.json` — Reference Notes

Official docs: https://code.claude.com/docs/en/settings
Permission docs: https://code.claude.com/docs/en/permissions

> **Comments not supported.** Standard JSON only — no `//` or `/* */`.
> Workaround: use `"_comment": "your note"` keys (unknown keys are silently ignored).

---

## File Locations & Scope Hierarchy

There are multiple settings files. When the same setting appears in more than one,
**higher scope wins** (except arrays, which are merged/concatenated across all scopes).

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

**Tip:** Run `/status` inside Claude Code to see which settings files are active
and where each setting is coming from.

---

## Schema Validation (Recommended)

Add this line to get autocomplete and inline validation in VS Code/Cursor:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

---

## `permissions` Object

This is the most important section for controlling what Claude can access.

### Rule Evaluation Order

```
deny → ask → allow
```

The **first matching rule wins.** Deny rules always take precedence over ask/allow
rules of equal specificity. More specific rules (with a pattern) beat broader rules
(tool name only), regardless of allow/deny type.

### Rule Syntax

```
"ToolName"               → matches all uses of that tool
"ToolName(pattern)"      → matches uses where the argument matches the pattern
```

Wildcards use gitignore-style glob syntax:
- `*` matches within a single directory level
- `**` matches recursively across directories
- Space before `*` matters: `Bash(ls *)` matches `ls -la` but NOT `lsof`

**Absolute vs. relative file paths in rules:**
- `//Users/you/file` → absolute path (note the double slash)
- `/path/to/file` → relative to the project root
- `./path/to/file` → also relative to project root
- `~/.zshrc` → relative to home directory

### `permissions.allow`

Grants Claude permission to use a tool without asking.

```json
"allow": [
  "Read(//Users/YOU/projects/**)",     // allow reads in your projects folder only
  "Edit(//Users/YOU/projects/**)",     // allow edits there too
  "Write(//Users/YOU/projects/**)",    // allow new file creation there
  "Bash(git status)",                  // exact command, no args variation
  "Bash(git diff *)",                  // git diff with any arguments
  "Bash(git log *)",
  "Bash(git add *)",
  "Bash(git commit *)",
  "Bash(npm run *)",                   // any npm run script
  "Bash(npm install)",
  "Bash(npm test)",
  "Bash(npx *)",
  "Bash(python *)",
  "Bash(pip install *)",
  "WebFetch(domain:docs.anthropic.com)"  // specific domain only
]
```

### `permissions.ask`

Claude will pause and ask your approval before proceeding. Good for
higher-risk actions you still want to allow case-by-case.

```json
"ask": [
  "Bash(git push *)",     // pushing to remote
  "Bash(git pull *)",     // pulling from remote
  "Bash(git merge *)",    // merges
  "WebFetch"              // all web requests (if not already denied)
]
```

### `permissions.deny`

Blocks Claude from using a tool entirely — no prompt, no override.
Use for sensitive files, dangerous commands, and network exfiltration vectors.

```json
"deny": [
  // --- Broad fallback: deny all reads/edits/writes not matched by an allow rule above ---
  "Read",
  "Edit",
  "Write",

  // --- Sensitive files: block even within allowed project paths ---
  "Read(**/.env)",
  "Read(**/.env.*)",
  "Read(**/*.key)",
  "Read(**/*.pem)",
  "Read(**/*.p12)",
  "Read(**/*.pfx)",
  "Read(**/.ssh/**)",
  "Read(**/id_rsa*)",
  "Read(**/id_ed25519*)",
  "Read(**/.aws/**)",
  "Read(**/.config/gcloud/**)",
  "Read(**/node_modules/**)",

  // --- Dangerous shell commands ---
  "Bash(sudo *)",
  "Bash(su *)",
  "Bash(rm -rf *)",
  "Bash(mkfs *)",
  "Bash(dd *)",
  "Bash(chmod *)",
  "Bash(chown *)",
  "Bash(crontab *)",
  "Bash(launchctl *)",
  "Bash(systemctl *)",

  // --- Network exfiltration vectors ---
  "Bash(curl *)",
  "Bash(wget *)",
  "Bash(ssh *)",
  "Bash(scp *)",
  "Bash(sftp *)",
  "Bash(nc *)",
  "Bash(ncat *)",

  // --- Disable web search entirely ---
  "WebSearch"
]
```

**Note on `Read` deny rules:** These also apply to built-in tools like `Grep`,
`Glob`, and `ls` — denied paths are hidden from those commands too
(documented as "best-effort").

### `permissions.defaultMode`

Controls how Claude behaves when a tool call doesn't match any allow/ask/deny rule.

| Value | Behavior |
|-------|----------|
| `"default"` | Ask for approval on anything not explicitly allowed (safest) |
| `"acceptEdits"` | Auto-approve file reads and edits; still ask for shell commands |
| `"plan"` | Read-only analysis mode; no edits or commands without approval |
| `"auto"` | Classifier auto-approves safe operations (research preview) |
| `"dontAsk"` | Silently deny anything not in the allow list (good for CI) |
| `"bypassPermissions"` | Skip all permission checks — **dangerous, use only in containers** |

Cycle modes interactively with `Shift+Tab` in the CLI, or the mode selector in VS Code.
Override for one session with: `claude --permission-mode acceptEdits`

### `permissions.disableBypassPermissionsMode`

```json
"disableBypassPermissionsMode": "disable"
```

Prevents `bypassPermissions` mode from ever being activated. Also disables
the `--dangerously-skip-permissions` CLI flag. Recommended in your personal
`~/.claude/settings.json` to prevent accidental use.

### `permissions.additionalDirectories`

Grants Claude read/write access to directories **outside** the current working
directory. Leave empty unless you have a specific need (e.g., a shared monorepo lib).

```json
"additionalDirectories": [
  "//Users/YOU/shared-libs"
]
```

By default, Claude can only access the directory you launched it from.
**Do not add home directory (~), Desktop, Documents, or other sensitive roots here.**

---

## `sandbox` Object

OS-level isolation for Bash commands — a second layer of defense on top of
permission rules. Sandboxing applies only to shell commands, not to Claude's
file tools (Read/Edit/Write), which are controlled by permission rules.

Enable with the `/sandbox` command in-session, or set it in settings:

```json
"sandbox": {
  "enabled": true,
  "autoAllowBashIfSandboxed": true,   // skip per-command prompts when sandboxed
  "excludedCommands": ["docker *"],   // commands that run outside the sandbox

  "filesystem": {
    "allowWrite": ["/tmp/build", "~/.kube"],
    "denyRead":   ["~/.aws/credentials", "~/.ssh/**"]
  },

  "network": {
    "allowedDomains": ["github.com", "*.npmjs.org", "registry.yarnpkg.com"],
    "deniedDomains":  ["uploads.github.com"],
    "allowLocalBinding": true,
    "allowUnixSockets": ["/var/run/docker.sock"]  // macOS only
  }
}
```

**Platform requirements:**
- macOS: works out of the box (uses Seatbelt)
- Linux / WSL2: install `bubblewrap` and `socat` first

**Tip:** Use permission deny rules AND sandboxing together for defense-in-depth.
Permission rules stop Claude from *attempting* the action; sandboxing stops the
*subprocess* even if Claude tries anyway.

---

## `model`

Override the default model for all sessions.

```json
"model": "claude-sonnet-4-6"
```

Override for one session: `claude --model claude-opus-4-6`
Or via environment variable: `ANTHROPIC_MODEL=claude-haiku-4-5`

---

## `env`

Set environment variables that apply to every Claude Code session.
Useful for disabling telemetry, setting timeouts, or configuring providers.

```json
"env": {
  "DISABLE_AUTOUPDATER": "1",                    // disable automatic updates
  "CLAUDE_CODE_DISABLE_AUTO_MEMORY": "1",        // disable auto memory/notes
  "BASH_DEFAULT_TIMEOUT_MS": "30000",            // 30s timeout for bash commands
  "BASH_MAX_TIMEOUT_MS": "120000",               // max timeout allowed
  "CLAUDE_CODE_ENABLE_TELEMETRY": "0",           // disable usage telemetry
  "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1" // block non-essential network calls
}
```

---

## `cleanupPeriodDays`

How many days to keep local session transcript files before auto-deleting.
Default is 30 days. Set lower for privacy-conscious setups.

```json
"cleanupPeriodDays": 7
```

To skip writing transcripts entirely, set `CLAUDE_CODE_SKIP_PROMPT_HISTORY=1` in `env`.

---

## `attribution`

Controls the co-author byline added to git commits and pull requests.
Set either to an empty string `""` to hide it.

```json
"attribution": {
  "commit": "",    // hide from git commits
  "pr": ""         // hide from pull request descriptions
}
```

Default commit attribution (if not overridden):
```
🤖 Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**Simpler alternative — disable entirely with one flag:**

```json
"includeCoAuthoredBy": false
```

This strips all Claude attribution from commits and PRs in one setting,
without needing to set empty strings on `attribution.commit` and `attribution.pr`.

---

## `autoMemoryEnabled`

Whether Claude automatically writes memory notes across sessions.
Disable if you don't want Claude storing summaries of your work.

```json
"autoMemoryEnabled": false
```

Toggle during a session with `/memory`.

---

## `autoUpdatesChannel`

```json
"autoUpdatesChannel": "stable"   // ~1 week behind latest; skips known bad releases
// or
"autoUpdatesChannel": "latest"   // default; most recent release
```

---

## `hooks`

Run custom shell scripts at lifecycle events. Useful for logging, validation,
notifications, or enforcing policies before/after Claude takes actions.

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
  ],
  "PostToolUse": [...],
  "Stop": [...],
  "Notification": [...]
}
```

Hook events: `PreToolUse`, `PostToolUse`, `Stop`, `Notification`

A `PreToolUse` hook can **approve, deny, or modify** a tool call at runtime —
more flexible than static permission rules for complex logic.

---

## `editorMode`

Key binding style for the input prompt.

```json
"editorMode": "vim"     // or "normal" (default)
```

---

## `preferredNotifChannel`

How Claude notifies you when a long task finishes or needs permission.

```json
"preferredNotifChannel": "terminal_bell"
// Options: "auto", "terminal_bell", "iterm2", "iterm2_with_bell",
//          "kitty", "ghostty", "notifications_disabled"
```

---

## `includeGitInstructions`

Whether to include built-in git workflow instructions in Claude's system prompt.
Set to `false` if you have your own git workflow defined in `CLAUDE.md`.

```json
"includeGitInstructions": false
```

---

## `language`

Set Claude's preferred response language.

```json
"language": "spanish"
```

---

## `showThinkingSummaries`

Show extended thinking/reasoning blocks in interactive sessions.

```json
"showThinkingSummaries": true
```

---

## `tui`

Use the flicker-free fullscreen renderer instead of the classic inline renderer.

```json
"tui": "fullscreen"   // or "default"
```

---

---

## `theme`

UI color theme.

```json
"theme": "dark"
// Options: "dark", "light", "light-daltonism", "dark-daltonism"
```

---

## `viewMode`

Controls how tool calls and responses are displayed in the transcript.

```json
"viewMode": "default"
// Options:
//   "default"  — standard interactive view
//   "verbose"  — expanded tool details
//   "focus"    — prompt + one-line tool summaries + final response only (Ctrl+O to toggle)
```

---

## `showTurnDuration`

Show or hide the "Cooked for 1m 6s" message after each response. Default: `true`.

```json
"showTurnDuration": false
```

---

## `prefersReducedMotion`

Disable spinners, shimmer, and flash animations for accessibility. Default: `false`.

```json
"prefersReducedMotion": true
```

---

## `spinnerTipsEnabled`

Show tips in the spinner while Claude is working. Default: `true`.

```json
"spinnerTipsEnabled": false
```

---

## `spinnerTipsOverride`

Inject custom tips into (or replace) the built-in spinner tips.

```json
"spinnerTipsOverride": {
  "excludeDefault": true,   // true = only show custom tips; false = merge with built-ins
  "tips": [
    "Tip 1: you can hit Escape to interrupt",
    "Tip 2: use /help to see all commands"
  ]
}
```

---

## `spinnerVerbs`

Customize the verbs used in spinner progress messages (e.g., "Thinking...", "Cooking...").

```json
"spinnerVerbs": {
  "mode": "append",   // "append" adds to defaults; "replace" uses only your verbs
  "verbs": ["Pondering", "Scheming"]
}
```

---

## `outputStyle`

Controls the response style for all sessions. Built-in styles: `default`, `Explanatory`, `Learning`.
Custom styles can be added as Markdown files in `~/.claude/output-styles/` or `.claude/output-styles/`.

```json
"outputStyle": "Explanatory"
```

Toggle in-session with `/config`.

---

## `effortLevel`

Persist the reasoning effort level across sessions. Supported on Opus 4.7, Opus 4.6, and Sonnet 4.6.

| Model | Supported levels | Default |
|---|---|---|
| Opus 4.7 | low / medium / high / xhigh / max | xhigh (Max plan) |
| Opus 4.6 | low / medium / high / max | high |
| Sonnet 4.6 | low / medium / high / max | high |

```json
"effortLevel": "high"
```

Override per-session: `claude --effort high`
Or via env: `CLAUDE_CODE_EFFORT_LEVEL=high`
Reset to model default in-session: `/effort auto`

---

## `alwaysThinkingEnabled`

Enable extended thinking by default for all sessions.

```json
"alwaysThinkingEnabled": true
```

Typically set via `/config` rather than editing directly.

---

## `fastMode`

Enable fast mode for Opus 4.6 — same model, ~2.5x faster output, higher per-token cost.
Requires "extra usage" to be enabled on your plan.

```json
"fastMode": true
```

Toggle in-session with `/fast`. See also `fastModePerSessionOptIn`.

---

## `fastModePerSessionOptIn`

When `true`, fast mode does not persist across sessions — users must enable it with `/fast`
each session. Useful for keeping costs predictable.

```json
"fastModePerSessionOptIn": true
```

---

## `availableModels`

Restrict which models are selectable. Arrays merge across settings scopes.

```json
"availableModels": ["claude-sonnet-4-6", "claude-haiku-4-5"]
```

---

## `modelOverrides`

Map Anthropic model IDs to provider-specific IDs (Bedrock ARNs, Vertex version names, etc.).
Used when running Claude Code via Bedrock or Vertex rather than the Anthropic API.

```json
"modelOverrides": {
  "claude-opus-4-6": "arn:aws:bedrock:us-east-2:123456789012:application-inference-profile/opus-prod"
}
```

---

## `claudeMdExcludes`

Glob patterns for CLAUDE.md files to skip. Useful in monorepos where you only want instructions
from your own team's subtree. Patterns match against absolute file paths. Arrays merge across scopes.
Managed-policy CLAUDE.md files cannot be excluded.

```json
"claudeMdExcludes": [
  "**/other-team/.claude/**",
  "/home/user/monorepo/legacy/CLAUDE.md"
]
```

---

## `respectGitignore`

Whether the `@` file picker hides files that match `.gitignore`. Default: `true`.

```json
"respectGitignore": false
```

---

## `plansDirectory`

Where plan files are stored. Path is relative to the project root.
Default: `~/.claude/plans`.

```json
"plansDirectory": "./plans"
```

---

## `autoMemoryDirectory`

Custom path for auto-memory storage. Supports `~/` prefix.
Default: `~/.claude/projects/<sanitized-cwd>/memory/`.

**Note:** Ignored if set in a checked-in `.claude/settings.json` (security restriction).

```json
"autoMemoryDirectory": "~/my-memory-store"
```

---

## `defaultShell`

Shell used for `!` inline commands in the input box. Default: `bash`.

```json
"defaultShell": "bash"
// or "powershell" (Windows only — requires CLAUDE_CODE_USE_POWERSHELL_TOOL=1)
```

---

## `fileSuggestion`

Custom script to power the `@` file autocomplete picker. The command is called as Claude types
and should output file path suggestions.

```json
"fileSuggestion": {
  "type": "command",
  "command": "~/.claude/file-suggestion.sh"
}
```

---

## `showClearContextOnPlanAccept`

When `true`, the plan-approval dialog offers a "clear context" option. Default: `false`.

```json
"showClearContextOnPlanAccept": true
```

---

## MCP Settings

### `enableAllProjectMcpServers`

Auto-approve all MCP servers listed in the project's `.mcp.json` without prompting.

```json
"enableAllProjectMcpServers": true
```

### `enabledMcpjsonServers` / `disabledMcpjsonServers`

Per-server approval/rejection from `.mcp.json`. Arrays merge across scopes.

```json
"enabledMcpjsonServers": ["memory", "github"],
"disabledMcpjsonServers": ["filesystem"]
```

### `allowedMcpServers` / `deniedMcpServers`

Enterprise-level allow/denylist. Can match by server name, exact command, or URL pattern.
Denylist takes precedence if a server appears in both lists.

```json
"allowedMcpServers": [
  { "serverName": "my-server" },
  { "serverUrl": "https://*.example.com/*" }
],
"deniedMcpServers": [
  { "serverName": "untrusted-server" }
]
```

---

## `disableAllHooks`

Kill switch that disables all hooks and the `statusLine` command. When set in managed settings,
users cannot override it.

```json
"disableAllHooks": true
```

---

## `allowedHttpHookUrls`

Allowlist of URL patterns that HTTP hooks may target. Supports `*` as a wildcard.
Undefined = no restriction; empty array = block all HTTP hooks. Arrays merge across scopes.

```json
"allowedHttpHookUrls": [
  "https://hooks.example.com/*",
  "http://localhost:*"
]
```

---

## `httpHookAllowedEnvVars`

Allowlist of env var names that HTTP hooks may interpolate into request headers.
Each hook's effective allowed vars is the intersection with this list. Arrays merge across scopes.

```json
"httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
```

---

## `useAutoModeDuringPlan`

When `true`, applies the auto-mode classifier during plan mode to auto-approve safe read-only
tool calls while planning. Has no effect unless `permissions.defaultMode` is set to `"auto"`.

```json
"useAutoModeDuringPlan": true
```

---

## `agent`

Set a default agent (built-in or custom) for the main session thread.
Applies the agent's system prompt, tool restrictions, and model.

```json
"agent": "code-architect"
```

Override per-session: `claude --agent <name>`

---

## `teammateMode`

How agent-team teammates are displayed. Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

```json
"teammateMode": "auto"
// Options: "auto" (split panes in tmux/iTerm2, in-process otherwise), "in-process", "tmux"
```

---

## `voiceEnabled`

Enable push-to-talk voice dictation. Requires a Claude.ai account.
Typically written automatically when you run `/voice`.

```json
"voiceEnabled": true
```

---

## `prUrlTemplate`

Override the URL used in PR badges (footer and tool-result summaries).
Available placeholders: `{host}`, `{owner}`, `{repo}`, `{number}`, `{url}`.
Useful for pointing PR links at an internal review tool instead of github.com.

```json
"prUrlTemplate": "https://reviews.example.com/{owner}/{repo}/pull/{number}"
```

---

## `worktree`

Configuration for `--worktree` sessions.

```json
"worktree": {
  "sparsePaths": ["packages/my-app", "shared/utils"]
  // Only check out these paths in each worktree (git sparse-checkout cone mode).
  // Faster in large monorepos.
}
```

---

## Auth & Provider Helpers

Scripts for custom authentication and cloud provider integrations.

```json
"apiKeyHelper": "/bin/generate_temp_api_key.sh",
"awsAuthRefresh": "aws sso login --profile myprofile",
"awsCredentialExport": "/bin/generate_aws_grant.sh",
"otelHeadersHelper": "/bin/get_otel_headers.sh"
```

- **`apiKeyHelper`** — script that outputs an API key or auth header values
- **`awsAuthRefresh`** — command run when AWS credentials need refreshing (Bedrock)
- **`awsCredentialExport`** — script that exports AWS credentials (Bedrock)
- **`otelHeadersHelper`** — script that outputs OpenTelemetry headers

---

## `minimumVersion`

Prevent Claude Code from downgrading below this version when switching release channels.

```json
"minimumVersion": "2.1.0"
```

---

## `disableSkillShellExecution`

Disable inline shell execution (`` !`...` `` and ` ```! ` blocks) in skills and custom slash
commands. Replaced with `[shell command execution disabled by policy]`. Does not affect
bundled or managed skills. Most useful in managed settings.

```json
"disableSkillShellExecution": true
```

---

## `disableDeepLinkRegistration`

Prevent Claude Code from registering the `claude://` deep-link protocol handler on startup.

```json
"disableDeepLinkRegistration": "disable"
```

---

## `skipWebFetchPreflight`

Skip the WebFetch blocklist check. For enterprise environments with restrictive outbound
security policies that intercept or block the preflight request.

```json
"skipWebFetchPreflight": true
```

---

## `forceLoginMethod`

Force a specific authentication method.

```json
"forceLoginMethod": "claudeai"
// "claudeai" = Claude Pro/Max subscription
// "console"  = Anthropic Console (API key billing)
```

---

## `forceLoginOrgUUID`

Force a specific organization UUID for OAuth login. Used in enterprise SSO setups.

```json
"forceLoginOrgUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

---

## Tips & Gotchas

**Absolute paths need `//` prefix in permission rules.**
`/Users/you/file` is treated as project-relative. Use `//Users/you/file` for
true absolute paths. This is different from sandbox filesystem paths, which use
normal `/` for absolute paths.

**Broad deny rules + specific allow rules work via specificity.**
`allow: ["Read(//projects/**"]` + `deny: ["Read"]` gives read access only to
your projects. The specific pattern wins over the broad tool-name rule.

**Arrays merge across scopes.**
Permission `allow`, `deny`, `ask` arrays from multiple settings files are
combined — they don't replace each other. A project's `.claude/settings.json`
can add deny rules on top of your user-level ones.

**Some built-in Bash commands never prompt** regardless of mode:
`ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, `cd`,
and read-only git commands. You cannot remove these from the no-prompt list; to
require a prompt, add an explicit `ask` or `deny` rule for them.

**The VS Code extension has known bugs with permission enforcement.**
Permission rules in `~/.claude/settings.json` are sometimes ignored by the VS Code
extension (as of early 2026). For strict access control, use the CLI (`claude` in
terminal) rather than the extension.

**Verify with `/permissions`** inside a session to see all active rules and
which settings file each came from.

**Test safely with `plan` mode** (`defaultMode: "plan"`) when working on
unfamiliar codebases — Claude can read and analyze but cannot make any changes.

**JSONC (comments) not yet supported.** Use `"_comment": "..."` keys as a
workaround — unknown keys are silently ignored by the parser.
