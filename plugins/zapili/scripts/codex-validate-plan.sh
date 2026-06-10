#!/usr/bin/env bash
set -euo pipefail

# codex plan_validator wrapper.
# Usage: codex-validate-plan.sh <plan_md> <phase_xx_glob> [prior_findings_json]
# Reviews PLAN.md + every matched PHASE-XX.md per references/codex-prompts.md
# plan_validator role. Persists output to .zapili/plan-validate-attempt-N.json.
# Same exit-code semantics as codex-validate-research.sh, including:
#   6  iteration cap reached (next attempt N > fix_loop_cap) — codex NOT invoked
#   7  stalled — severe-finding count did not strictly decrease vs prior (N >= 2)
#   9  stalled on MEDIUM-only (0 HIGH) — accepted; orchestrator proceeds

if [ "$#" -lt 2 ]; then
  printf 'usage: %s <plan_md> <phase_xx_glob> [prior_findings_json]\n' "$0" >&2
  exit 64
fi

PLAN_MD="$1"
PHASE_GLOB="$2"
PRIOR_FINDINGS="${3:-}"

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCHEMA="$ROOT/schemas/validation-findings.schema.json"
PROMPTS_REF="$ROOT/skills/orchestrator/references/codex-prompts.md"
STATE_DIR=".zapili"
mkdir -p "$STATE_DIR"

N=1
while [ -f "$STATE_DIR/plan-validate-attempt-$N.json" ]; do
  N=$((N + 1))
done
OUT_FILE="$STATE_DIR/plan-validate-attempt-$N.json"
PROMPT_FILE="$STATE_DIR/plan-validate-attempt-$N.prompt.txt"

# Deterministic cap enforcement (exit 6). Reading state.json is allowed; only
# WRITING it is the orchestrator's exclusive right. Fall back to 4 if absent.
cap=$(jq -r '.fix_loop_cap // 4' "$STATE_DIR/state.json" 2>/dev/null || echo 4)
case "$cap" in (*[!0-9]*|'') cap=4 ;; esac
if [ "$N" -gt "$cap" ]; then
  printf '[codex-validate-plan] cap reached: N=%d > fix_loop_cap=%d; latest findings: %s\n' \
    "$N" "$cap" "$STATE_DIR/plan-validate-attempt-$((N - 1)).json" >&2
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

PHASE_INPUTS=""
PHASE_CONTENT=""
for phase_file in $PHASE_GLOB; do
  [ -f "$phase_file" ] || continue
  PHASE_INPUTS+="  <file role=\"phase\">$phase_file</file>
"
  PHASE_CONTENT+="
--- $phase_file ---
$(cat "$phase_file")
"
done

# Exhaustive on the first pass; regression-only on retries so the loop converges.
if [ "$N" -eq 1 ]; then
  REVIEW_BLOCK='<exhaustiveness>
This is a FULL review (exhaustive coverage, not a targeted re-review). Do NOT limit yourself to
previously-discussed findings, do NOT pick a top-N subset, do NOT stop at the first
clear issue. Audit EVERY phase end-to-end across every category listed in &lt;categories&gt;.
Treat any prior_findings as hypotheses to re-verify from scratch — they do NOT define
your scope. Cross-phase audits (wave dependencies, write-set intersection, completeness
against the goal) are mandatory, not optional.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario (e.g. "in Wave 2, PHASE-XX and PHASE-YY both write src/auth.ts →
second engineer overwrites first"), and a remediation an engineer can act on. Speculative
or aesthetic notes belong in `tests_to_add` or a LOW finding with kind="no-findings".

If you run out of budget before completing a category or a phase file, add an entry to
`not_fully_audited[]` naming the scope (e.g. "PHASE-03.md security category") and the
reason. Do NOT silently skip — silent gaps are worse than declared gaps.
</exhaustiveness>'
else
  REVIEW_BLOCK='<regression>
REGRESSION review — this is attempt N&ge;2. You previously raised the findings listed in
&lt;prior_findings&gt;. For EACH, decide whether it is now resolved. Additionally inspect
ONLY the regions changed since the previous attempt (the revised PLAN.md / PHASE-XX.md
sections) for NEW blocking issues. Do NOT perform a fresh global audit and do NOT
introduce findings unrelated to the prior set or the changed regions.

Treat user-confirmed decisions as authoritative — the CONTEXT.md `<decisions>` and the
TASK.md `## Definition of Done` items are settled; do NOT re-raise them as
ambiguity/scope/missing-context findings.

Substantiated means each finding has a real risk, a concrete breaking scenario, and a
remediation an engineer can act on. Emit the reclassification block for every prior id.
</regression>'
fi

cat >"$PROMPT_FILE" <<EOF
<role>plan_validator</role>

<inputs>
  <file role="plan">$PLAN_MD</file>
$PHASE_INPUTS
</inputs>

<categories>
  <category>contradictions</category>
  <category>gaps</category>
  <category>ambiguity</category>
  <category>parallel-safety</category>
  <category>completeness</category>
  <category>architectural-fit</category>
  <category>dry-kiss</category>
  <category>professionalism</category>
</categories>

$REVIEW_BLOCK

<output_contract>
  Respond inside &lt;response&gt;&lt;payload&gt;{ ... }&lt;/payload&gt;&lt;/response&gt;.
  Payload MUST conform to https://oplya.dev/zapili/schemas/validation-findings.schema.json.
  Emit a finding for EVERY listed category. When a category has no finding, emit a
  finding of severity LOW with kind "no-findings".
  For HIGH and MEDIUM findings, populate \`why_real_risk\` (substantiation) and \`repro\`
  (concrete breaking scenario or steps).
  Explicitly verify pairwise write-scope disjointness across every wave — the disjointness
  finding belongs in category \`parallel-safety\` with a concrete scenario in \`repro\`.
  If anything was not fully audited, populate top-level \`not_fully_audited[]\`.
  Forbidden vocabulary: \`key\`, \`main\`, \`top\`, \`important\`.
  See \${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/codex-prompts.md for the full scaffold (exhaustiveness contract + severity mapping).
</output_contract>

$PRIOR_BLOCK

PLAN.md content:
$(cat "$PLAN_MD" 2>/dev/null || echo '(missing)')

PHASE files:
$PHASE_CONTENT
EOF

if ! bash "$ROOT/scripts/codex-review.sh" "$PROMPT_FILE" "$OUT_FILE"; then
  printf '[codex-validate-plan] codex invocation failed (attempt %d)\n' "$N" >&2
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
  printf '[codex-validate-plan] no JSON Schema validator available; install ajv-cli or python jsonschema\n' >&2
  exit 5
fi

case "$VALIDATOR" in
  ajv)
    if ! ajv validate -s "$SCHEMA" -d "$OUT_FILE" --spec=draft2020 --strict=false >/dev/null 2>&1; then
      printf '[codex-validate-plan] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
  python)
    if ! python3 - "$OUT_FILE" "$SCHEMA" <<'PY' >/dev/null 2>&1
import json, sys, jsonschema
jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))
PY
    then
      printf '[codex-validate-plan] output failed schema validation: %s\n' "$OUT_FILE" >&2
      exit 3
    fi
    ;;
esac

# Finding-ID uniqueness check — JSON Schema uniqueItems is whole-object equality,
# so duplicate-id-different-category passes schema. The orchestrator's prior-issue
# carry-forward is set-based on .id, so duplicates silently drop one finding.
DUPE_IDS=$(jq -r '.findings | map(.id) | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$OUT_FILE" 2>/dev/null)
if [ -n "$DUPE_IDS" ]; then
  printf '[codex-validate-plan] duplicate finding ids in payload (orchestrator dedup would lose one): %s\n' "$DUPE_IDS" | tr '\n' ' ' >&2
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
  PRIOR_FILE="$STATE_DIR/plan-validate-attempt-$((N - 1)).json"
  prior=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$PRIOR_FILE" 2>/dev/null)
  case "$prior" in
    ''|*[!0-9]*) ;;  # prior missing/unparseable → skip stall
    *)
      if [ "$SEVERE_COUNT" -gt 0 ] && [ "$SEVERE_COUNT" -ge "$prior" ]; then
        if [ "$HIGH_COUNT" -eq 0 ]; then
          printf '[codex-validate-plan] stalled on MEDIUM-only (0 HIGH, N=%d: %d >= prev %d) — accepting MEDIUMs, proceeding\n' \
            "$N" "$SEVERE_COUNT" "$prior" >&2
          printf '%s\n' "$OUT_FILE"
          exit 9
        fi
        printf '[codex-validate-plan] stalled: no strict decrease (N=%d: %d >= prev %d)\n' \
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
