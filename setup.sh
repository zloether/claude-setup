#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/claude"
CLAUDE_DIR="$HOME/.claude"

# User-level files copied to ~/.claude/
# statusline-command.sh is intentionally excluded — it lives at a root-owned
# system path so it cannot be tampered with by prompt injection.
MANAGED_FILES=(settings.json CLAUDE.md)

# System-level paths (require sudo to modify)
STATUSLINE_SYSTEM_PATH="/usr/local/bin/claude-statusline"
case "$(uname -s)" in
  Darwin) SYSTEM_SETTINGS_DIR="/Library/Application Support/ClaudeCode" ;;
  Linux)  SYSTEM_SETTINGS_DIR="/etc/claude-code" ;;
  *)      SYSTEM_SETTINGS_DIR="" ;;
esac

echo "==> Claude Code Setup"
echo ""

# Check Claude Code is installed
if ! command -v claude &>/dev/null; then
  echo "WARNING: Claude Code not found in PATH."
  echo "  Install Claude Code first:"
  echo "    macOS/Linux/WSL:  curl -fsSL https://claude.ai/install.sh | bash"
  echo "    Windows:          irm https://claude.ai/install.ps1 | iex"
  echo "    macOS (Homebrew): brew install --cask claude-code"
  echo ""
  read -r -p "Continue applying settings anyway? [y/N] " REPLY
  echo ""
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  echo "  Claude Code: $(claude --version 2>/dev/null | head -1) (OK)"
fi

# --- User-level settings ---
echo ""
echo "==> Applying user-level settings..."

mkdir -p "$CLAUDE_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
for f in "${MANAGED_FILES[@]}"; do
  dest="$CLAUDE_DIR/$f"
  if [ -f "$dest" ]; then
    cp "$dest" "${dest}.backup.${TIMESTAMP}"
    echo "  Backed up $dest → ${dest}.backup.${TIMESTAMP}"
  fi
done

for f in "${MANAGED_FILES[@]}"; do
  src="$SRC_DIR/$f"
  if [ -f "$src" ]; then
    cp "$src" "$CLAUDE_DIR/$f"
    echo "  Copied $f → $CLAUDE_DIR/$f"
  fi
done

# Remove old user-writable statusline script from previous installs.
# It now lives at a root-owned system path — keeping it in ~/.claude/ would
# leave a user-writable execution path that bypasses managed hook controls.
if [ -f "$CLAUDE_DIR/statusline-command.sh" ]; then
  rm "$CLAUDE_DIR/statusline-command.sh"
  echo "  Removed $CLAUDE_DIR/statusline-command.sh (now managed at system level)"
fi

# --- System-level settings ---
echo ""
echo "==> Deploying system-level settings (requires sudo)..."
echo "    managed-settings.json locks down hook execution and is enforced"
echo "    machine-wide at highest priority. The statusline script is installed"
echo "    to $STATUSLINE_SYSTEM_PATH (root-owned, cannot be modified without sudo)."
echo ""

_deploy_system() {
  if [ -n "$SYSTEM_SETTINGS_DIR" ]; then
    sudo mkdir -p "$SYSTEM_SETTINGS_DIR" || return 1
    sudo cp "$REPO_DIR/managed-settings.json" "$SYSTEM_SETTINGS_DIR/managed-settings.json" || return 1
    echo "  Deployed managed-settings.json → $SYSTEM_SETTINGS_DIR/"
  else
    echo "  Unsupported platform — skipping managed-settings.json."
  fi
  sudo cp "$SRC_DIR/statusline-command.sh" "$STATUSLINE_SYSTEM_PATH" || return 1
  sudo chmod +x "$STATUSLINE_SYSTEM_PATH" || return 1
  echo "  Deployed statusline-command.sh → $STATUSLINE_SYSTEM_PATH"
}

_print_manual_steps() {
  echo "  To complete system-level setup manually, run:"
  if [ -n "$SYSTEM_SETTINGS_DIR" ]; then
    echo "    sudo mkdir -p '$SYSTEM_SETTINGS_DIR'"
    echo "    sudo cp '$REPO_DIR/managed-settings.json' '$SYSTEM_SETTINGS_DIR/managed-settings.json'"
  fi
  echo "    sudo cp '$SRC_DIR/statusline-command.sh' '$STATUSLINE_SYSTEM_PATH'"
  echo "    sudo chmod +x '$STATUSLINE_SYSTEM_PATH'"
}

if _deploy_system; then
  : # success messages printed inside _deploy_system
else
  echo ""
  echo "  WARNING: System-level deployment failed."
  echo "  Without managed settings:"
  echo "    - Project-level hooks can run shell commands uncontrolled on every tool use"
  echo "    - Sandbox network/filesystem restrictions for ~/Library and ~/.config are not enforced"
  echo "    - bypassPermissions mode may not be fully disabled"
  _print_manual_steps
  echo ""
  read -r -p "  Continue without managed settings? [y/N] " REPLY
  echo ""
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo ""
echo "==> Done. Review ~/.claude/settings.json and adjust for your workflow."
echo ""
echo "Key things to consider customizing:"
echo "  - theme: \"dark\" or \"light\""
echo "  - permissions.allow / deny: add tools and commands you use frequently"
echo "  - includeCoAuthoredBy: true/false for Claude attribution in commits"
echo ""
echo "See claude-settings-reference.md for full documentation of all options."
echo ""
echo "Next step: run 'claude' to authenticate and start your first session."
