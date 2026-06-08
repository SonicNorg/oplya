#!/usr/bin/env bash
set -euo pipefail

# Strict pre-flight invoked by /zapili:zapili.
# Exit codes:
#   0  codex is installed and the exec subcommand is reachable
#   2  codex CLI not found on PATH
#   3  codex --version failed
#   4  codex exec subcommand unavailable (auth or install issue)

source "$(dirname "${BASH_SOURCE[0]}")/codex-bin.sh"

REMEDIATION="See https://developers.openai.com/codex/cli/reference for install + auth."

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: %s CLI not found on PATH.\n%s\n' "$CODEX_BIN" "$REMEDIATION" >&2
  exit 2
fi

VERSION_OUT=$("$CODEX_BIN" --version 2>&1) || {
  printf '[zapili] preflight FAILED: %s --version failed: %s\n%s\n' "$CODEX_BIN" "$VERSION_OUT" "$REMEDIATION" >&2
  exit 3
}

if ! "$CODEX_BIN" exec --help >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: %s exec subcommand unavailable (auth or install issue).\n%s\n' "$CODEX_BIN" "$REMEDIATION" >&2
  exit 4
fi

printf '[zapili] %s preflight OK (%s)\n' "$CODEX_BIN" "$VERSION_OUT" >&2
exit 0
