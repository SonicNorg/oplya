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

source "$(dirname "${BASH_SOURCE[0]}")/codex-bin.sh"

if [ ! -f "$PROMPT_FILE" ]; then
  printf '[codex-review] prompt file not found: %s\n' "$PROMPT_FILE" >&2
  exit 65
fi

mkdir -p "$(dirname "$OUT_FILE")"

# Pipe prompt to codex; capture JSONL stream; preserve codex exit code via PIPESTATUS.
set +e
"$CODEX_BIN" exec \
  --json \
  --sandbox read-only \
  --skip-git-repo-check \
  --ignore-user-config \
  - <"$PROMPT_FILE" >"$RAW_FILE" 2>>"${OUT_FILE}.codex-stderr.log"
CODEX_RC=$?
set -e

# Extract the final assistant message regardless of codex exit code (best-effort parse).
# codex JSONL event shape (verified against codex-cli 0.133.0 on 2026-05-28):
#   {"type":"thread.started","thread_id":"..."}
#   {"type":"turn.started"}
#   {"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"..."}}
#   {"type":"turn.completed","usage":{...}}
# We want the LAST `item.completed` whose nested item is an `agent_message`, and
# the final assistant text is at `.item.text`. Legacy (older codex / OpenAI Chat-
# Completions-style: {type:"message", role:"assistant", content:"..."} or with
# array content `[{type:"text", text:"..."}]`) is kept as a fallback so this
# wrapper survives a codex downgrade. Writes RAW TEXT (not JSON-encoded) so
# downstream perl -0777 / python re.DOTALL extractors can match
# `<payload>...</payload>` across newlines.
if [ -s "$RAW_FILE" ]; then
  jq -rs '
    # Branch 1: current codex CLI (>= 0.133.0): item.completed events with agent_message.
    (map(select(.type == "item.completed" and .item.type == "agent_message"))
     | if length > 0 then (last | .item.text // "") else null end) as $current
    # Branch 2: legacy/OpenAI-style: message events with assistant role.
    | (map(select((.type // "") == "message" and ((.role // "") == "assistant")))
       | if length > 0 then
           (last | .content) as $c
           | if ($c | type) == "array" then
               ($c | map(select(.type == "text") | .text) | join(""))
             elif ($c | type) == "string" then
               $c
             else
               ((last | .text) // (last | .message) // "")
             end
         else null
         end) as $legacy
    | ($current // $legacy // "")
  ' "$RAW_FILE" >"$OUT_FILE" 2>/dev/null || printf '' >"$OUT_FILE"
fi
[ -f "$OUT_FILE" ] || printf '' >"$OUT_FILE"

if [ "$CODEX_RC" -ne 0 ]; then
  printf '[codex-review] codex exited with %d; see %s\n' "$CODEX_RC" "${OUT_FILE}.codex-stderr.log" >&2
fi

exit "$CODEX_RC"
