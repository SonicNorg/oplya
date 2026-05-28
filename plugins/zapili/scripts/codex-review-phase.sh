#!/usr/bin/env bash
set -euo pipefail

# codex phase_reviewer wrapper.
# Usage: codex-review-phase.sh <task_md> <phase_xx_md> <engineer_payload_json> [prior_findings_json]
# Reviews one engineer attempt against TASK + phase plan per phase_reviewer role
# in references/codex-prompts.md. Persists to .zapili/phase-<XX>-review-attempt-N.json.
#
# Exit codes mirror codex-validate-plan.sh:
#   0  clean (no HIGH/MEDIUM)
#   1  HIGH or MEDIUM present (orchestrator must spawn a fix iteration)
#   2  codex invocation failed
#   3  output failed schema validation
#   5  no JSON Schema validator available

if [ "$#" -lt 3 ]; then
  printf 'usage: %s <task_md> <phase_xx_md> <engineer_payload_json> [prior_findings_json]\n' "$0" >&2
  exit 64
fi

TASK_MD="$1"
PHASE_MD="$2"
ENGINEER_PAYLOAD="$3"
PRIOR_FINDINGS="${4:-}"

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCHEMA="$ROOT/schemas/validation-findings.schema.json"
PROMPTS_REF="$ROOT/skills/orchestrator/references/codex-prompts.md"
STATE_DIR=".zapili"
mkdir -p "$STATE_DIR"

# Parse XX phase id from the PHASE-XX.md filename.
PHASE_BASENAME=$(basename "$PHASE_MD")
PHASE_ID=$(printf '%s' "$PHASE_BASENAME" | sed -nE 's/^PHASE-([0-9]+-[0-9]+|[0-9]+)\.md$/\1/p')
if [ -z "$PHASE_ID" ]; then
  printf '[codex-review-phase] could not parse phase id from %s\n' "$PHASE_BASENAME" >&2
  exit 64
fi

N=1
while [ -f "$STATE_DIR/phase-$PHASE_ID-review-attempt-$N.json" ]; do
  N=$((N + 1))
done
OUT_FILE="$STATE_DIR/phase-$PHASE_ID-review-attempt-$N.json"
PROMPT_FILE="$STATE_DIR/phase-$PHASE_ID-review-attempt-$N.prompt.txt"

PRIOR_BLOCK=""
if [ -n "$PRIOR_FINDINGS" ] && [ -f "$PRIOR_FINDINGS" ]; then
  PRIOR_BLOCK=$(jq -r '.findings[] | "<finding id=\"\(.id)\" severity=\"\(.severity)\" status=\"open\" />"' "$PRIOR_FINDINGS" 2>/dev/null || true)
  if [ -n "$PRIOR_BLOCK" ]; then
    PRIOR_BLOCK="<prior_findings>
$PRIOR_BLOCK
</prior_findings>"
  fi
fi

cat >"$PROMPT_FILE" <<EOF
<role>phase_reviewer</role>

<inputs>
  <file role="task">$TASK_MD</file>
  <file role="phase">$PHASE_MD</file>
  <file role="engineer-payload">$ENGINEER_PAYLOAD</file>
</inputs>

<categories>
  <category>plan-contradiction</category>
  <category>missing-tasks</category>
  <category>code-quality</category>
  <category>edge-cases</category>
  <category>security</category>
  <category>professionalism</category>
</categories>

<output_contract>
  Respond inside &lt;response&gt;&lt;payload&gt;{ ... }&lt;/payload&gt;&lt;/response&gt;.
  Payload MUST conform to https://oplya.dev/zapili/schemas/validation-findings.schema.json.
  Emit a finding for EVERY listed category. When a category has no finding, emit a
  finding of severity LOW with kind "no-findings".
  Verify the engineer's files_touched matches the phase's <files>.writes declaration.
  Forbidden vocabulary: \`key\`, \`main\`, \`top\`, \`important\`.
  See $PROMPTS_REF for the full scaffold.
</output_contract>

$PRIOR_BLOCK

TASK.md content:
$(cat "$TASK_MD" 2>/dev/null || echo '(missing)')

PHASE plan ($PHASE_MD):
$(cat "$PHASE_MD" 2>/dev/null || echo '(missing)')

Engineer payload ($ENGINEER_PAYLOAD):
$(cat "$ENGINEER_PAYLOAD" 2>/dev/null || echo '(missing)')
EOF

if ! bash "$ROOT/scripts/codex-review.sh" "$PROMPT_FILE" "$OUT_FILE"; then
  printf '[codex-review-phase] codex invocation failed for %s attempt %d\n' "$PHASE_ID" "$N" >&2
  exit 2
fi

PAYLOAD=$(jq -r '.' "$OUT_FILE" 2>/dev/null | sed -n 's/.*<payload>\(.*\)<\/payload>.*/\1/p' | head -n1)
if [ -n "$PAYLOAD" ]; then
  printf '%s' "$PAYLOAD" >"$OUT_FILE"
fi

VALIDATOR=""
if command -v ajv >/dev/null 2>&1; then
  VALIDATOR=ajv
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' >/dev/null 2>&1; then
  VALIDATOR=python
else
  printf '[codex-review-phase] no JSON Schema validator available; install ajv-cli or python jsonschema\n' >&2
  exit 5
fi

case "$VALIDATOR" in
  ajv)
    if ! ajv validate -s "$SCHEMA" -d "$OUT_FILE" --spec=draft2020 --strict=false >/dev/null 2>&1; then
      printf '[codex-review-phase] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
  python)
    if ! python3 - "$OUT_FILE" "$SCHEMA" <<'PY' >/dev/null 2>&1
import json, sys, jsonschema
jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
PY
    then
      printf '[codex-review-phase] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
esac

SEVERE_COUNT=$(jq '[.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$OUT_FILE")
printf '%s\n' "$OUT_FILE"
if [ "$SEVERE_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
