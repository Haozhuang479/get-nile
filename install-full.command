#!/bin/bash
# Nile full installer: installs the AI agents you pick (official packages), then Nile itself.
# Double-click in Finder, or: bash install-full.command
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"
HERE="$(cd "$(dirname "$0")" && pwd)"
say() { printf '\n\033[1m▸ %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
clear; echo "Nile full install"; echo "================="
echo "This installs, from the official sources, whatever is missing:"
echo "  [1] Codex (OpenAI)       npm package @openai/codex, then sign in with your ChatGPT account"
echo "  [2] Claude Code          claude.ai/install.sh, then sign in with your Anthropic account"
echo "  [3] Gemini CLI (Google)  npm package @google/gemini-cli, then sign in with Google"
echo "  [4] DeepSeek via Aider   pip package aider-chat; you add DEEPSEEK_API_KEY to your shell yourself"
echo "  [a] all     [n] none, just Nile"
printf "Pick (e.g. 1 2, or a): "; read -r PICK; PICK="${PICK:-a}"
want() { case " $PICK " in *" a "*) return 0;; *" $1 "*) return 0;; *) return 1;; esac; }

if ! have node && (want 1 || want 3); then
  say "Installing Node.js LTS (macOS asks for your password)"
  PKG="$(curl -fsSL https://nodejs.org/dist/latest-v22.x/SHASUMS256.txt | grep -o 'node-v22[^ ]*-arm64\.pkg' | head -1)"
  curl -fsSL -o "/tmp/$PKG" "https://nodejs.org/dist/latest-v22.x/$PKG" && sudo installer -pkg "/tmp/$PKG" -target / && export PATH="/usr/local/bin:$PATH"
fi
if want 1; then
  if have codex || [ -x /Applications/ChatGPT.app/Contents/Resources/codex ]; then echo "Codex already here."; else say "Installing Codex"; npm install -g @openai/codex; fi
  say "Sign in to Codex (opens your browser; close it when it says you are signed in)"; (codex login || /Applications/ChatGPT.app/Contents/Resources/codex login) || true
fi
if want 2; then
  if have claude; then echo "Claude Code already here."; else say "Installing Claude Code"; curl -fsSL https://claude.ai/install.sh | bash; export PATH="$HOME/.local/bin:$PATH"; fi
  say "Sign in to Claude Code"; claude auth login || true
fi
if want 3; then
  have gemini && echo "Gemini CLI already here." || { say "Installing Gemini CLI"; npm install -g @google/gemini-cli; }
  echo "Sign in later by running: gemini"
fi
if want 4; then
  have aider && echo "Aider already here." || { say "Installing Aider (for DeepSeek)"; python3 -m pip install --user aider-chat || pip3 install --user aider-chat; }
  echo "Add this line to ~/.zshrc with your own key, then restart Terminal:  export DEEPSEEK_API_KEY=..."
  echo "In Nile: + → DeepSeek preset."
fi

say "Installing Nile"
if [ -f "$HERE/install.sh" ]; then bash "$HERE/install.sh" "$(ls "$HERE"/Nile-*.zip 2>/dev/null | head -1)"
else echo "install.sh is missing next to this file. Download both from the release page."; fi
echo; read -r -p "Press Return to close." _
