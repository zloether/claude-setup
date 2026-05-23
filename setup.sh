#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/claude"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_DEST="$CLAUDE_DIR/settings.json"

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

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# Back up existing settings.json
if [ -f "$SETTINGS_DEST" ]; then
  BACKUP="${SETTINGS_DEST}.backup.$(date +%Y%m%d_%H%M%S)"
  cp "$SETTINGS_DEST" "$BACKUP"
  echo "  Backed up existing settings → ${BACKUP}"
fi

# Copy everything from claude/ into ~/.claude/
cp -r "$SRC_DIR/." "$CLAUDE_DIR/"
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "  Applied claude/ → ${CLAUDE_DIR}/"

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
