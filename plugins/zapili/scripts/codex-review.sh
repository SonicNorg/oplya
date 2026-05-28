#!/usr/bin/env bash
set -euo pipefail

# Generic codex invocation wrapper.
# Usage: codex-review.sh <prompt_file> <out_file>
# Reads the prompt from stdin (piped in), writes the raw JSONL stream to
# <out_file>.raw.jsonl, extracts the final assistant message into <out_file>,
# and propagates codex's exit code.
#
# Stdout: nothing of consequence (the parsed result is written to <out_file>).
# Stderr: codex progress messages + script remediation messages.

if [ "$#" -lt 2 ]; then
  printf 'usage: %s <prompt_file> <out_file>\n' "$0" >&2
  exit 64
fi

PROMPT_FILE="$1"
OUT_FILE="$2"
RAW_FILE="${OUT_FILE}.raw.jsonl"

if [ ! -f "$PROMPT_FILE" ]; then
  printf '[codex-review] prompt file not found: %s\n' "$PROMPT_FILE" >&2
  exit 65
fi

mkdir -p "$(dirname "$OUT_FILE")"

# Pipe prompt to codex; capture JSONL stream; preserve codex exit code via PIPESTATUS.
set +e
codex exec \
  --json \
  --sandbox read-only \
  --skip-git-repo-check \
  --ignore-user-config \
  - <"$PROMPT_FILE" >"$RAW_FILE" 2>>"${OUT_FILE}.codex-stderr.log"
CODEX_RC=$?
set -e

# Extract the final assistant message regardless of codex exit code (best-effort parse).
# codex JSONL event shape can vary across versions; isolate it here so a future
# schema bump is a one-file change.
if [ -s "$RAW_FILE" ]; then
  jq -s '
    map(select((.type // "") == "message" and ((.role // "") == "assistant")))
    | if length > 0 then (last | (.content // .text // .message)) else "" end
  ' "$RAW_FILE" >"$OUT_FILE" 2>/dev/null || printf '' >"$OUT_FILE"
else
  printf '' >"$OUT_FILE"
fi

if [ "$CODEX_RC" -ne 0 ]; then
  printf '[codex-review] codex exited with %d; see %s\n' "$CODEX_RC" "${OUT_FILE}.codex-stderr.log" >&2
fi

exit "$CODEX_RC"
