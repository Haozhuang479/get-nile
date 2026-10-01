#!/bin/bash
# Nile quick install for macOS (Apple Silicon).
#   bash install.sh                 downloads the latest build from the private release page (needs `gh` signed in)
#   bash install.sh ~/Downloads/Nile-0.3.0-mac-arm64.zip   installs a zip you already downloaded
# Env: NILE_INSTALL_DIR (default /Applications), NILE_REGISTER_MCP=0 (skip agent registration), NILE_AGENT_SETUP=0 (skip the agent's own check)
set -euo pipefail
REPO="${NILE_REPO:-Haozhuang479/get-nile}"
DEST="${NILE_INSTALL_DIR:-/Applications}"
ZIP="${1:-}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
say() { printf '\033[1m▸ %s\033[0m\n' "$*"; }
[ "$(uname -s)" = Darwin ] || { echo "Nile runs on macOS."; exit 1; }
[ "$(uname -m)" = arm64 ] || echo "Note: this build is for Apple Silicon Macs."

say "Looking for AI agents on this Mac"
CODEX="$(command -v codex 2>/dev/null || true)"; [ -z "$CODEX" ] && [ -x /Applications/ChatGPT.app/Contents/Resources/codex ] && CODEX=/Applications/ChatGPT.app/Contents/Resources/codex
CLAUDE="$(command -v claude 2>/dev/null || true)"; [ -z "$CLAUDE" ] && CLAUDE="$(ls -d "$HOME/Library/Application Support/Claude/claude-code"/*/claude.app/Contents/MacOS/claude 2>/dev/null | sort -V | tail -1 || true)"
NODE="$(command -v node 2>/dev/null || true)"
[ -n "$CODEX" ] && echo "  Codex        $CODEX" || echo "  Codex        not found"
[ -n "$CLAUDE" ] && echo "  Claude Code  $CLAUDE" || echo "  Claude Code  not found"
[ -n "$NODE" ] && echo "  Node         $NODE" || echo "  Node         not found — Nile needs it to talk to your agent. Run install-full.command, or install from https://nodejs.org"
if [ -z "$CODEX$CLAUDE" ]; then echo; echo "No agent found. Run install-full.command to install Codex, Claude Code, Gemini CLI or DeepSeek first (Nile itself still installs now)."; fi

if [ -z "$ZIP" ]; then
  say "Downloading Nile"
  TMP="$(mktemp -d)"
  if curl -fsSL --progress-bar -o "$TMP/Nile-mac-arm64.zip" "https://github.com/$REPO/releases/latest/download/Nile-mac-arm64.zip"; then ZIP="$TMP/Nile-mac-arm64.zip"
  elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release download --repo "$REPO" --pattern 'Nile-*.zip' --dir "$TMP"; ZIP="$(ls "$TMP"/Nile-*.zip | head -1)"
  else
    echo "Could not download. Get the zip from https://github.com/$REPO/releases/latest and run: bash install.sh ~/Downloads/Nile-*.zip"; exit 2
  fi
fi
[ -f "$ZIP" ] || { echo "Zip not found: $ZIP"; exit 2; }

say "Installing to $DEST"
osascript -e 'tell application "Nile" to quit' >/dev/null 2>&1 || true; sleep 1
mkdir -p "$DEST"; rm -rf "$DEST/Nile.app"
ditto -x -k "$ZIP" "$DEST"
xattr -dr com.apple.quarantine "$DEST/Nile.app" 2>/dev/null || true
MCP="$DEST/Nile.app/Contents/Resources/app/mcp/server.mjs"

if [ "${NILE_REGISTER_MCP:-1}" = 1 ]; then
  say "Letting your agents drive the Nile window (MCP server nile-pro)"
  if [ -n "$CODEX" ]; then "$CODEX" mcp remove nile-pro >/dev/null 2>&1 || true; "$CODEX" mcp add nile-pro -- "${NODE:-node}" "$MCP" >/dev/null 2>&1 && echo "  Codex: registered" || echo "  Codex: could not register (run: codex mcp add nile-pro -- node \"$MCP\")"; fi
  if [ -n "$CLAUDE" ]; then "$CLAUDE" mcp remove -s user nile-pro >/dev/null 2>&1 || true; "$CLAUDE" mcp add -s user nile-pro -- "${NODE:-node}" "$MCP" >/dev/null 2>&1 && echo "  Claude Code: registered" || echo "  Claude Code: could not register (run: claude mcp add -s user nile-pro -- node \"$MCP\")"; fi
fi

say "Opening Nile"
open "$DEST/Nile.app"

# If an agent is signed in, let it confirm the install from inside Nile.
if [ "${NILE_AGENT_SETUP:-1}" = 1 ] && [ -n "$CODEX" ] && "$CODEX" login status 2>&1 | grep -qi "logged in"; then
  say "Asking Codex to check the window"
  sleep 5
  "$CODEX" exec --skip-git-repo-check -s read-only -C "$HOME" -c 'mcp_servers.nile-pro.default_tools_approval_mode="approve"' \
    "The Nile desktop app was just installed and opened. Using the nile-pro MCP tools: call status, then show_setup with step 1. Reply in two short lines: did the window answer, and which agents does it list as ready." 2>/dev/null | tail -4 || echo "  (Codex could not reach the window yet; open Nile and follow Set up Nile.)"
fi
echo; say "Done. Nile is in $DEST. Setup inside the app: Agent → Data → Test drive → Payment → Tour."
