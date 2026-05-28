#!/usr/bin/env bash
set -euo pipefail

# codex research_validator wrapper.
# Usage: codex-validate-research.sh <task_md> <context_md> [prior_findings_json]
# Composes the research_validator prompt per references/codex-prompts.md,
# invokes codex via codex-review.sh, validates the findings against
# validation-findings.schema.json, persists raw + parsed output under .zapili/.
#
# Exit codes:
#   0  no HIGH/MEDIUM findings (research is clean)
#   1  HIGH or MEDIUM findings present (orchestrator must loop)
#   2  codex invocation failed
#   3  output failed schema validation
#   5  no JSON Schema validator available (ajv or python jsonschema)
#
# Stdout: path to the parsed findings JSON file.
# Stderr: codex progress + this script's diagnostic messages.

if [ "$#" -lt 2 ]; then
  printf 'usage: %s <task_md> <context_md> [prior_findings_json]\n' "$0" >&2
  exit 64
fi

TASK_MD="$1"
CONTEXT_MD="$2"
PRIOR_FINDINGS="${3:-}"

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCHEMA="$ROOT/schemas/validation-findings.schema.json"
PROMPTS_REF="$ROOT/skills/orchestrator/references/codex-prompts.md"
STATE_DIR=".zapili"
mkdir -p "$STATE_DIR"

# Auto-increment attempt counter based on existing files.
N=1
while [ -f "$STATE_DIR/research-validate-attempt-$N.json" ]; do
  N=$((N + 1))
done
OUT_FILE="$STATE_DIR/research-validate-attempt-$N.json"
PROMPT_FILE="$STATE_DIR/research-validate-attempt-$N.prompt.txt"

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
<role>research_validator</role>

<inputs>
  <file role="task">$TASK_MD</file>
  <file role="context">$CONTEXT_MD</file>
</inputs>

<categories>
  <category>contradictions</category>
  <category>missing-context</category>
  <category>hallucinated-references</category>
  <category>scope-creep</category>
  <category>ambiguity</category>
</categories>

<exhaustiveness>
This is a FULL review (полное ревью, not targeted re-review). Do NOT limit yourself to
previously-discussed findings, do NOT pick a top-N subset, do NOT stop at the first
clear issue. Audit the ENTIRE artifact end-to-end across every category listed in
&lt;categories&gt;. Treat any prior_findings as hypotheses to re-verify from scratch — they
do NOT define your scope.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario, and a remediation an engineer can act on. Speculative or aesthetic
notes belong in \`tests_to_add\` or a LOW finding with kind="no-findings", not as a
fabricated HIGH.

If you run out of budget before completing a category or a file, add an entry to
\`not_fully_audited[]\` naming the scope and the reason. Do NOT silently skip — silent
gaps are worse than declared gaps because the orchestrator cannot route around them.
</exhaustiveness>

<output_contract>
  Respond inside &lt;response&gt;&lt;payload&gt;{ ... }&lt;/payload&gt;&lt;/response&gt;.
  Payload MUST conform to https://oplya.dev/zapili/schemas/validation-findings.schema.json.
  Emit a finding for EVERY listed category. When a category has no finding, emit a
  finding of severity LOW with kind "no-findings".
  For HIGH and MEDIUM findings, populate \`why_real_risk\` (substantiation) and \`repro\`
  (concrete breaking scenario or steps). For phase-test-relevant findings, populate
  \`tests_to_add\` with one prose item per recommended test.
  Trailing &lt;coverage&gt; block lists files_reviewed and categories_checked. If anything
  was not fully audited, populate top-level \`not_fully_audited[]\` with {scope, reason}.
  Forbidden vocabulary in your response: \`key\`, \`main\`, \`top\`, \`important\`.
  See $PROMPTS_REF for the full scaffold (exhaustiveness contract + severity mapping).
</output_contract>

$PRIOR_BLOCK

TASK.md content:
$(cat "$TASK_MD" 2>/dev/null || echo '(missing)')

CONTEXT.md content:
$(cat "$CONTEXT_MD" 2>/dev/null || echo '(missing)')
EOF

# Invoke codex via the generic wrapper.
if ! bash "$ROOT/scripts/codex-review.sh" "$PROMPT_FILE" "$OUT_FILE"; then
  printf '[codex-validate-research] codex invocation failed (attempt %d)\n' "$N" >&2
  exit 2
fi

# Strip XML envelope if present; keep only the JSON payload.
# Use perl -0777 (slurp mode) + /s flag so `.` matches across newlines —
# `sed` is single-line by default and silently returns empty when the
# <payload> opening and closing tags land on separate lines (typical for
# pretty-printed JSON from codex).
PAYLOAD=$(perl -0777 -ne 'print $1 if /<payload>(.*?)<\/payload>/s' "$OUT_FILE" 2>/dev/null)
if [ -n "$PAYLOAD" ]; then
  printf '%s' "$PAYLOAD" >"$OUT_FILE"
fi

# Validate against schema.
VALIDATOR=""
if command -v ajv >/dev/null 2>&1; then
  VALIDATOR=ajv
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' >/dev/null 2>&1; then
  VALIDATOR=python
else
  printf '[codex-validate-research] no JSON Schema validator available; install ajv-cli or python jsonschema\n' >&2
  exit 5
fi

case "$VALIDATOR" in
  ajv)
    if ! ajv validate -s "$SCHEMA" -d "$OUT_FILE" --spec=draft2020 --strict=false >/dev/null 2>&1; then
      printf '[codex-validate-research] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
  python)
    if ! python3 - "$OUT_FILE" "$SCHEMA" <<'PY' >/dev/null 2>&1
import json, sys, jsonschema
jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
PY
    then
      printf '[codex-validate-research] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
esac

# Decide exit code based on severity.
SEVERE_COUNT=$(jq '[.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$OUT_FILE")
printf '%s\n' "$OUT_FILE"
if [ "$SEVERE_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
