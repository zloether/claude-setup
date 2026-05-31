# macOS `~/Library/` Paths to Block

The default config in this repo uses a blanket `Read(~/Library/**)` deny rule at user and managed scope. macOS app developers who need to read their own app's data (typically under `~/Library/Application Support/<MyApp>/` or `~/Library/Logs/<MyApp>/`) must narrow that rule.

Because `deny` beats `allow` across scopes, a project-level allow cannot punch through the user-level deny. To re-enable specific paths, remove the blanket `Read(~/Library/**)` rule from `~/.claude/settings.json` (and `/Library/Application Support/ClaudeCode/managed-settings.json` if you're enforcing the managed mirror) and replace it with a targeted list. This file enumerates the high-value sensitive paths a developer typically wants to keep blocked even after relaxing the blanket deny. Use it as a starting point — adjust based on the apps you use.

> **Path coverage note**: each entry is a Claude Code permission rule. To enforce the same boundaries at the OS level for arbitrary subprocesses (Python, Node, etc.), mirror these into `sandbox.filesystem.denyRead` in `managed-settings.json` — drop the `Read(...)` wrapper and keep the `~/` prefix. See the bottom of this file for a sandbox-format block.

---

## Categories

### Communications and personal data

User messaging, mail, calendar, contacts, iOS backups, Apple Notes.

```json
"Read(~/Library/Messages/**)",
"Read(~/Library/Mail/**)",
"Read(~/Library/Calendars/**)",
"Read(~/Library/Application Support/AddressBook/**)",
"Read(~/Library/Application Support/MobileSync/**)",
"Read(~/Library/Group Containers/group.com.apple.notes/**)"
```

### Browsers

Saved passwords, cookies, session tokens, history, bookmarks, local web storage.

```json
"Read(~/Library/Safari/**)",
"Read(~/Library/Cookies/**)",
"Read(~/Library/Application Support/Google/Chrome/**)",
"Read(~/Library/Application Support/Chromium/**)",
"Read(~/Library/Application Support/BraveSoftware/**)",
"Read(~/Library/Application Support/Firefox/**)",
"Read(~/Library/Application Support/Microsoft Edge/**)",
"Read(~/Library/Application Support/Arc/**)",
"Read(~/Library/Application Support/Vivaldi/**)",
"Read(~/Library/HTTPStorages/**)",
"Read(~/Library/WebKit/**)"
```

### Keychain and password managers

```json
"Read(~/Library/Keychains/**)",
"Read(~/Library/Application Support/1Password/**)",
"Read(~/Library/Application Support/Bitwarden/**)",
"Read(~/Library/Application Support/Dashlane/**)",
"Read(~/Library/Application Support/Enpass/**)",
"Read(~/Library/Application Support/KeePassXC/**)"
```

### Communications apps

Chat history, workspace tokens, attachments.

```json
"Read(~/Library/Application Support/Slack/**)",
"Read(~/Library/Application Support/discord/**)",
"Read(~/Library/Application Support/Signal/**)",
"Read(~/Library/Application Support/Telegram Desktop/**)",
"Read(~/Library/Application Support/WhatsApp/**)",
"Read(~/Library/Application Support/zoom.us/**)",
"Read(~/Library/Application Support/Microsoft Teams/**)"
```

### Notes and productivity

```json
"Read(~/Library/Application Support/Notion/**)",
"Read(~/Library/Application Support/Obsidian/**)",
"Read(~/Library/Containers/md.obsidian.Obsidian/**)"
```

### Cloud storage syncs

Local copies of files synced from cloud providers (iCloud Drive, Dropbox, OneDrive, Google Drive, Box).

```json
"Read(~/Library/CloudStorage/**)",
"Read(~/Library/Mobile Documents/**)"
```

### macOS internals

System and app metadata that often contain sensitive material.

```json
"Read(~/Library/Containers/**)",
"Read(~/Library/Group Containers/group.com.apple.notes/**)",
"Read(~/Library/Application Support/com.apple.TCC/**)",
"Read(~/Library/Logs/**)",
"Read(~/Library/Saved Application State/**)"
```

> `~/Library/Containers/**` is broad — many sandboxed apps store data under this root. If you're developing a sandboxed macOS app, your data lives at `~/Library/Containers/<your.bundle.id>/` and you'll need a more specific deny or scoped allow.
>
> `~/Library/Group Containers/**` is intentionally **not** used as a blanket block. The 1Password SSH agent socket lives at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`; a blanket deny on `Group Containers` prevents `git commit` signing from reaching it. Block specific Group Containers paths you care about (e.g. `group.com.apple.notes`) rather than the whole subtree.

---

## Combined block (permission rules)

Paste into the `permissions.deny` array in `~/.claude/settings.json`:

```json
"Read(~/Library/Messages/**)",
"Read(~/Library/Mail/**)",
"Read(~/Library/Calendars/**)",
"Read(~/Library/Application Support/AddressBook/**)",
"Read(~/Library/Application Support/MobileSync/**)",
"Read(~/Library/Group Containers/group.com.apple.notes/**)",
"Read(~/Library/Safari/**)",
"Read(~/Library/Cookies/**)",
"Read(~/Library/Application Support/Google/Chrome/**)",
"Read(~/Library/Application Support/Chromium/**)",
"Read(~/Library/Application Support/BraveSoftware/**)",
"Read(~/Library/Application Support/Firefox/**)",
"Read(~/Library/Application Support/Microsoft Edge/**)",
"Read(~/Library/Application Support/Arc/**)",
"Read(~/Library/Application Support/Vivaldi/**)",
"Read(~/Library/HTTPStorages/**)",
"Read(~/Library/WebKit/**)",
"Read(~/Library/Keychains/**)",
"Read(~/Library/Application Support/1Password/**)",
"Read(~/Library/Application Support/Bitwarden/**)",
"Read(~/Library/Application Support/Dashlane/**)",
"Read(~/Library/Application Support/Enpass/**)",
"Read(~/Library/Application Support/KeePassXC/**)",
"Read(~/Library/Application Support/Slack/**)",
"Read(~/Library/Application Support/discord/**)",
"Read(~/Library/Application Support/Signal/**)",
"Read(~/Library/Application Support/Telegram Desktop/**)",
"Read(~/Library/Application Support/WhatsApp/**)",
"Read(~/Library/Application Support/zoom.us/**)",
"Read(~/Library/Application Support/Microsoft Teams/**)",
"Read(~/Library/Application Support/Notion/**)",
"Read(~/Library/Application Support/Obsidian/**)",
"Read(~/Library/Containers/md.obsidian.Obsidian/**)",
"Read(~/Library/CloudStorage/**)",
"Read(~/Library/Mobile Documents/**)",
"Read(~/Library/Containers/**)",
"Read(~/Library/Group Containers/group.com.apple.notes/**)",
"Read(~/Library/Application Support/com.apple.TCC/**)",
"Read(~/Library/Logs/**)",
"Read(~/Library/Saved Application State/**)"
```

## Combined block (sandbox format)

Paste into `sandbox.filesystem.denyRead` in `managed-settings.json` for OS-level enforcement that covers arbitrary subprocesses (Python, Node, etc.):

```json
"~/Library/Messages/**",
"~/Library/Mail/**",
"~/Library/Calendars/**",
"~/Library/Application Support/AddressBook/**",
"~/Library/Application Support/MobileSync/**",
"~/Library/Group Containers/group.com.apple.notes/**",
"~/Library/Safari/**",
"~/Library/Cookies/**",
"~/Library/Application Support/Google/Chrome/**",
"~/Library/Application Support/Chromium/**",
"~/Library/Application Support/BraveSoftware/**",
"~/Library/Application Support/Firefox/**",
"~/Library/Application Support/Microsoft Edge/**",
"~/Library/Application Support/Arc/**",
"~/Library/Application Support/Vivaldi/**",
"~/Library/HTTPStorages/**",
"~/Library/WebKit/**",
"~/Library/Keychains/**",
"~/Library/Application Support/1Password/**",
"~/Library/Application Support/Bitwarden/**",
"~/Library/Application Support/Dashlane/**",
"~/Library/Application Support/Enpass/**",
"~/Library/Application Support/KeePassXC/**",
"~/Library/Application Support/Slack/**",
"~/Library/Application Support/discord/**",
"~/Library/Application Support/Signal/**",
"~/Library/Application Support/Telegram Desktop/**",
"~/Library/Application Support/WhatsApp/**",
"~/Library/Application Support/zoom.us/**",
"~/Library/Application Support/Microsoft Teams/**",
"~/Library/Application Support/Notion/**",
"~/Library/Application Support/Obsidian/**",
"~/Library/Containers/md.obsidian.Obsidian/**",
"~/Library/CloudStorage/**",
"~/Library/Mobile Documents/**",
"~/Library/Containers/**",
"~/Library/Group Containers/group.com.apple.notes/**",
"~/Library/Application Support/com.apple.TCC/**",
"~/Library/Logs/**",
"~/Library/Saved Application State/**"
```

## See also

- `claude-settings-reference.md` — full settings reference
- `README.md` — threat model and limitations
- `AGENTS.md` — agent instructions for setup
