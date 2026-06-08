#!/usr/bin/env bash
set -euo pipefail

# SessionStart advisory hook: verify codex CLI is available.
# Contract: NEVER exit non-zero (would brick Claude Code per ZAP-02).

# Drain hook stdin (Claude Code writes hook JSON payload here).
cat >/dev/null 2>&1 || true

# The hook knows only its own location; resolve the helper via its own directory.
# Guard the source: a missing/unreadable helper must NOT trigger a non-zero exit
# under `set -e` (ZAP-02). Degrade to the default binary if it cannot be sourced.
source "$(dirname "${BASH_SOURCE[0]}")/codex-bin.sh" 2>/dev/null || CODEX_BIN="codex"

REMEDIATION="[zapili] $CODEX_BIN CLI is required for the /zapili:zapili workflow."
if [ "$CODEX_BIN" = "codex" ]; then
  REMEDIATION="$REMEDIATION
Install one of:
  brew install --cask codex
  npm install -g @openai/codex
  curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-install.sh | sh
Then authenticate per https://developers.openai.com/codex/cli/reference"
else
  REMEDIATION="$REMEDIATION
Install $CODEX_BIN per your organization's provisioning guide, then authenticate."
fi
REMEDIATION="$REMEDIATION
zapili is loaded but /zapili:zapili will fail-fast until $CODEX_BIN is available."

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  printf '%s\n' "$REMEDIATION" >&2
  exit 0
fi

if ! "$CODEX_BIN" --version >/dev/null 2>&1; then
  printf '[zapili] %s is installed but failed to report version; check installation.\n' "$CODEX_BIN" >&2
  exit 0
fi

# Success: silent (no noise on every session start).
exit 0
