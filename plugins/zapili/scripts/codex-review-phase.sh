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
#   6  iteration cap reached (next attempt N > fix_loop_cap) — codex NOT invoked
#   7  stalled — severe-finding count did not strictly decrease vs prior (N >= 2)
#   9  stalled on MEDIUM-only (0 HIGH) — accepted; orchestrator proceeds

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
# Phase id pattern: production naming (PHASE-01, PHASE-01-02) AND fixture
# naming (PHASE-XX, PHASE-XX-a). Mirrors check-wave-disjointness.sh broadening
# from Phase 7 D-12 / ZAP-59.
PHASE_ID=$(printf '%s' "$PHASE_BASENAME" | sed -nE 's/^PHASE-([A-Za-z0-9]+(-[A-Za-z0-9]+)?)\.md$/\1/p')
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

# Deterministic cap enforcement (exit 6). Reading state.json is allowed; only
# WRITING it is the orchestrator's exclusive right. Fall back to 4 if absent.
cap=$(jq -r '.fix_loop_cap // 4' "$STATE_DIR/state.json" 2>/dev/null || echo 4)
case "$cap" in (*[!0-9]*|'') cap=4 ;; esac
if [ "$N" -gt "$cap" ]; then
  printf '[codex-review-phase] cap reached: N=%d > fix_loop_cap=%d; latest findings: %s\n' \
    "$N" "$cap" "$STATE_DIR/phase-$PHASE_ID-review-attempt-$((N - 1)).json" >&2
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
clear issue. Audit the ENTIRE engineer payload + phase spec + every file in
files_touched, end-to-end across every category listed in &lt;categories&gt;. Treat any
prior_findings as hypotheses to re-verify from scratch — they do NOT define your scope.
Runtime concerns are mandatory: state transitions, error paths, retries, idempotency,
contract drift between docs and code, stale comments that can mislead implementation.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario (e.g. "POST /api/auth with empty body returns 500 instead of 400",
"second retry attempt sees stale lease and double-charges"), and a remediation an engineer
can act on. Speculative or aesthetic notes belong in `tests_to_add` or a LOW finding
with kind="no-findings".

For phase_reviewer specifically, `tests_to_add` is a primary deliverable — every HIGH
or MEDIUM finding that could be caught by a test SHOULD recommend one or more tests
(unit/integration/property/manual) with concrete assertion names, not "add tests".

If you run out of budget before completing a category or a file, add an entry to
`not_fully_audited[]` naming the scope and the reason. Do NOT silently skip — silent
gaps are worse than declared gaps.
</exhaustiveness>'
else
  REVIEW_BLOCK='<regression>
REGRESSION review — this is attempt N&ge;2. You previously raised the findings listed in
&lt;prior_findings&gt;. For EACH, decide whether it is now resolved. Additionally inspect
ONLY the regions changed since the previous attempt (the engineer files_touched in this
attempt) for NEW blocking issues. Do NOT perform a fresh global audit and do NOT
introduce findings unrelated to the prior set or the changed regions.

Treat user-confirmed decisions as authoritative — the CONTEXT.md `<decisions>` and the
TASK.md `## Definition of Done` items are settled; do NOT re-raise them as
ambiguity/scope/missing-context findings.

Substantiated means each finding has a real risk, a concrete breaking scenario, and a
remediation an engineer can act on. `tests_to_add` stays a primary deliverable for any
HIGH/MEDIUM that is test-catchable. Emit the reclassification block for every prior id.
</regression>'
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

$REVIEW_BLOCK

<output_contract>
  Respond inside &lt;response&gt;&lt;payload&gt;{ ... }&lt;/payload&gt;&lt;/response&gt;.
  Payload MUST conform to https://oplya.dev/zapili/schemas/validation-findings.schema.json.
  Emit a finding for EVERY listed category. When a category has no finding, emit a
  finding of severity LOW with kind "no-findings".
  For HIGH and MEDIUM findings, populate \`why_real_risk\` (substantiation), \`repro\`
  (concrete breaking scenario or steps), and \`tests_to_add\` (one prose item per
  recommended test — required when the finding is test-catchable).
  Verify the engineer's files_touched matches the phase's <files>.writes declaration —
  surface drift in category \`plan-contradiction\`.
  If anything was not fully audited, populate top-level \`not_fully_audited[]\`.
  Forbidden vocabulary: \`key\`, \`main\`, \`top\`, \`important\`.
  See \${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/codex-prompts.md for the full scaffold (exhaustiveness contract + severity mapping).
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

# Strip XML envelope; perl -0777 + /s handles multi-line <payload>...</payload>
# that sed (single-line by default) misses.
PAYLOAD=$(perl -0777 -ne 'print $1 if /<payload>(.*?)<\/payload>/s' "$OUT_FILE" 2>/dev/null)
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

# Finding-ID uniqueness check — JSON Schema uniqueItems is whole-object equality,
# so duplicate-id-different-category passes schema. The orchestrator's prior-issue
# carry-forward is set-based on .id, so duplicates silently drop one finding.
DUPE_IDS=$(jq -r '.findings | map(.id) | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$OUT_FILE" 2>/dev/null)
if [ -n "$DUPE_IDS" ]; then
  printf '[codex-review-phase] duplicate finding ids in payload (orchestrator dedup would lose one): %s\n' "$DUPE_IDS" | tr '\n' ' ' >&2
  printf '\n' >&2
  exit 3
fi

SEVERE_COUNT=$(jq '[.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$OUT_FILE")
HIGH_COUNT=$(jq '[.findings[] | select(.severity=="HIGH")] | length' "$OUT_FILE")

# Stall detection: from N >= 2, require a strict decrease in the severe-finding
# count vs the prior attempt; non-decrease means no convergence. MEDIUM-only
# stall (0 HIGH) → exit 9 (accept the stuck MEDIUMs and proceed); HIGH still
# open → exit 7 (escalate).
if [ "$N" -ge 2 ]; then
  PRIOR_FILE="$STATE_DIR/phase-$PHASE_ID-review-attempt-$((N - 1)).json"
  prior=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$PRIOR_FILE" 2>/dev/null)
  case "$prior" in
    ''|*[!0-9]*) ;;  # prior missing/unparseable → skip stall
    *)
      if [ "$SEVERE_COUNT" -gt 0 ] && [ "$SEVERE_COUNT" -ge "$prior" ]; then
        if [ "$HIGH_COUNT" -eq 0 ]; then
          printf '[codex-review-phase] stalled on MEDIUM-only (0 HIGH, N=%d: %d >= prev %d) — accepting MEDIUMs, proceeding\n' \
            "$N" "$SEVERE_COUNT" "$prior" >&2
          printf '%s\n' "$OUT_FILE"
          exit 9
        fi
        printf '[codex-review-phase] stalled: no strict decrease (N=%d: %d >= prev %d)\n' \
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
