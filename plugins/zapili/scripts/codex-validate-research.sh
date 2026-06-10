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
#   6  iteration cap reached (next attempt N > fix_loop_cap) — codex NOT invoked;
#      orchestrator escalates per Stage 4
#   7  stalled — severe-finding count did not strictly decrease vs the prior
#      attempt (only checked from N >= 2), with HIGH still open; early cap
#   9  stalled on MEDIUM-only (0 HIGH) — accepted as non-blocking; orchestrator
#      proceeds to the next stage and surfaces the accepted MEDIUM findings
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

# Deterministic cap enforcement (exit 6). Reading state.json is allowed; the
# single-writer invariant only forbids WRITING it. Fall back to 4 if the field
# is absent or not a valid integer.
cap=$(jq -r '.fix_loop_cap // 4' "$STATE_DIR/state.json" 2>/dev/null || echo 4)
case "$cap" in (*[!0-9]*|'') cap=4 ;; esac
if [ "$N" -gt "$cap" ]; then
  printf '[codex-validate-research] cap reached: N=%d > fix_loop_cap=%d; latest findings: %s\n' \
    "$N" "$cap" "$STATE_DIR/research-validate-attempt-$((N - 1)).json" >&2
  exit 6
fi

PRIOR_BLOCK=""
if [ -n "$PRIOR_FINDINGS" ] && [ -f "$PRIOR_FINDINGS" ]; then
  PRIOR_BLOCK=$(jq -r '.findings[] | "<finding id=\"\(.id)\" severity=\"\(.severity)\" status=\"open\" />"' "$PRIOR_FINDINGS" 2>/dev/null || true)
  if [ -n "$PRIOR_BLOCK" ]; then
    PRIOR_BLOCK="<prior_findings>
$PRIOR_BLOCK
</prior_findings>"
  fi
fi

# Exhaustive on the first pass; regression-only on retries so the loop converges.
if [ "$N" -eq 1 ]; then
  REVIEW_BLOCK='<exhaustiveness>
This is a FULL review (exhaustive coverage, not a targeted re-review). Do NOT limit yourself to
previously-discussed findings, do NOT pick a top-N subset, do NOT stop at the first
clear issue. Audit the ENTIRE artifact end-to-end across every category listed in
&lt;categories&gt;. Treat any prior_findings as hypotheses to re-verify from scratch — they
do NOT define your scope.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario, and a remediation an engineer can act on. Speculative or aesthetic
notes belong in `tests_to_add` or a LOW finding with kind="no-findings", not as a
fabricated HIGH.

If you run out of budget before completing a category or a file, add an entry to
`not_fully_audited[]` naming the scope and the reason. Do NOT silently skip — silent
gaps are worse than declared gaps because the orchestrator cannot route around them.
</exhaustiveness>'
else
  REVIEW_BLOCK='<regression>
REGRESSION review — this is attempt N&ge;2. You previously raised the findings listed in
&lt;prior_findings&gt;. For EACH, decide whether it is now resolved. Additionally inspect
ONLY the regions changed since the previous attempt for NEW blocking issues. Do NOT
perform a fresh global audit and do NOT introduce findings unrelated to the prior set
or the changed regions.

Treat user-confirmed decisions as authoritative — the CONTEXT.md `<decisions>` and the
TASK.md `## Definition of Done` items are settled; do NOT re-raise them as
ambiguity/scope/missing-context findings.

Substantiated means each finding has a real risk, a concrete breaking scenario, and a
remediation an engineer can act on. Emit the reclassification block for every prior id.
</regression>'
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

$REVIEW_BLOCK

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
  See \${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/codex-prompts.md for the full scaffold (exhaustiveness contract + severity mapping).
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

# Finding-ID uniqueness check — JSON Schema `uniqueItems` compares whole objects
# (deep equality), so two findings with the same id but different file/category
# still pass schema validation. The orchestrator's prior-issue dedup is set-based
# on .id, so duplicate ids silently drop one finding from the carry-forward set.
# Enforce real id-uniqueness here, after schema validation.
DUPE_IDS=$(jq -r '.findings | map(.id) | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$OUT_FILE" 2>/dev/null)
if [ -n "$DUPE_IDS" ]; then
  printf '[codex-validate-research] duplicate finding ids in payload (orchestrator dedup would lose one): %s\n' "$DUPE_IDS" | tr '\n' ' ' >&2
  printf '\n' >&2
  exit 3
fi

# Decide exit code based on severity.
SEVERE_COUNT=$(jq '[.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$OUT_FILE")
HIGH_COUNT=$(jq '[.findings[] | select(.severity=="HIGH")] | length' "$OUT_FILE")

# Stall detection: from N >= 2, require a strict decrease in the severe-finding
# count vs the prior attempt. A non-decreasing count means the loop is not
# converging. MEDIUM-only stall (0 HIGH) → exit 9 (accept the stuck MEDIUMs and
# proceed; we tried to fix them and they are non-blocking). HIGH still open →
# exit 7 (escalate instead of burning more iterations).
if [ "$N" -ge 2 ]; then
  PRIOR_FILE="$STATE_DIR/research-validate-attempt-$((N - 1)).json"
  prior=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$PRIOR_FILE" 2>/dev/null)
  case "$prior" in
    ''|*[!0-9]*) ;;  # prior missing/unparseable → skip stall
    *)
      if [ "$SEVERE_COUNT" -gt 0 ] && [ "$SEVERE_COUNT" -ge "$prior" ]; then
        if [ "$HIGH_COUNT" -eq 0 ]; then
          printf '[codex-validate-research] stalled on MEDIUM-only (0 HIGH, N=%d: %d >= prev %d) — accepting MEDIUMs, proceeding\n' \
            "$N" "$SEVERE_COUNT" "$prior" >&2
          printf '%s\n' "$OUT_FILE"
          exit 9
        fi
        printf '[codex-validate-research] stalled: no strict decrease (N=%d: %d >= prev %d)\n' \
          "$N" "$SEVERE_COUNT" "$prior" >&2
        exit 7
      fi
      ;;
  esac
fi

printf '%s\n' "$OUT_FILE"
if [ "$SEVERE_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
