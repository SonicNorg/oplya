#!/usr/bin/env bash
# Resolve which codex binary to use, based on the work/personal instance.
# Sourced (not executed) by the codex-facing scripts; sets CODEX_BIN in the
# caller's shell. Intentionally free of `set -euo pipefail` so it does not
# mutate the sourcing script's shell options.
if [ "${CLAUDE_INSTANCE:-}" = "work" ]; then
  CODEX_BIN="codex-work"
else
  CODEX_BIN="codex"
fi
