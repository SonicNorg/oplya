#!/usr/bin/env bash
set -euo pipefail

# SessionStart advisory hook: verify codex CLI is available.
# Contract: NEVER exit non-zero (would brick Claude Code per ZAP-02).

# Drain hook stdin (Claude Code writes hook JSON payload here).
cat >/dev/null 2>&1 || true

REMEDIATION=$(cat <<'EOF'
[zapili] codex CLI is required for the /zapili:zapili workflow.
Install one of:
  brew install --cask codex
  npm install -g @openai/codex
  curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-install.sh | sh
Then authenticate per https://developers.openai.com/codex/cli/reference
zapili is loaded but /zapili:zapili will fail-fast until codex is available.
EOF
)

if ! command -v codex >/dev/null 2>&1; then
  printf '%s\n' "$REMEDIATION" >&2
  exit 0
fi

if ! codex --version >/dev/null 2>&1; then
  printf '[zapili] codex is installed but failed to report version; check installation.\n' >&2
  exit 0
fi

# Success: silent (no noise on every session start).
exit 0
