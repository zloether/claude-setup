#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/claude"
CLAUDE_DIR="$HOME/.claude"

# Files this script manages — anything else in ~/.claude/ is left untouched
MANAGED_FILES=(settings.json CLAUDE.md statusline-command.sh)

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

# Back up each managed file individually before overwriting
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
for f in "${MANAGED_FILES[@]}"; do
  dest="$CLAUDE_DIR/$f"
  if [ -f "$dest" ]; then
    cp "$dest" "${dest}.backup.${TIMESTAMP}"
    echo "  Backed up ${dest} → ${dest}.backup.${TIMESTAMP}"
  fi
done

# Copy only the managed files — leave the rest of ~/.claude/ untouched
for f in "${MANAGED_FILES[@]}"; do
  src="$SRC_DIR/$f"
  if [ -f "$src" ]; then
    cp "$src" "$CLAUDE_DIR/$f"
    echo "  Copied $f → ${CLAUDE_DIR}/$f"
  fi
done

chmod +x "$CLAUDE_DIR/statusline-command.sh"

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
