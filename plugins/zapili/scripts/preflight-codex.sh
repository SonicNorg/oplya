#!/usr/bin/env bash
set -euo pipefail

# Strict pre-flight invoked by /zapili:zapili.
# Exit codes:
#   0  codex is installed and the exec subcommand is reachable
#   2  codex CLI not found on PATH
#   3  codex --version failed
#   4  codex exec subcommand unavailable (auth or install issue)

REMEDIATION="See https://developers.openai.com/codex/cli/reference for install + auth."

if ! command -v codex >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: codex CLI not found on PATH.\n%s\n' "$REMEDIATION" >&2
  exit 2
fi

VERSION_OUT=$(codex --version 2>&1) || {
  printf '[zapili] preflight FAILED: codex --version failed: %s\n%s\n' "$VERSION_OUT" "$REMEDIATION" >&2
  exit 3
}

if ! codex exec --help >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: codex exec subcommand unavailable (auth or install issue).\n%s\n' "$REMEDIATION" >&2
  exit 4
fi

printf '[zapili] codex preflight OK (%s)\n' "$VERSION_OUT" >&2
exit 0
