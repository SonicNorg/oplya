#!/usr/bin/env bash
set -euo pipefail

# codex plan_validator wrapper.
# Usage: codex-validate-plan.sh <plan_md> <phase_xx_glob> [prior_findings_json]
# Reviews PLAN.md + every matched PHASE-XX.md per references/codex-prompts.md
# plan_validator role. Persists output to .zapili/plan-validate-attempt-N.json.
# Same exit-code semantics as codex-validate-research.sh.

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

<exhaustiveness>
This is a FULL review (полное ревью, not targeted re-review). Do NOT limit yourself to
previously-discussed findings, do NOT pick a top-N subset, do NOT stop at the first
clear issue. Audit EVERY phase end-to-end across every category listed in &lt;categories&gt;.
Treat any prior_findings as hypotheses to re-verify from scratch — they do NOT define
your scope. Cross-phase audits (wave dependencies, write-set intersection, completeness
against the goal) are mandatory, not optional.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario (e.g. "in Wave 2, PHASE-XX and PHASE-YY both write src/auth.ts →
second engineer overwrites first"), and a remediation an engineer can act on. Speculative
or aesthetic notes belong in \`tests_to_add\` or a LOW finding with kind="no-findings".

If you run out of budget before completing a category or a phase file, add an entry to
\`not_fully_audited[]\` naming the scope (e.g. "PHASE-03.md security category") and the
reason. Do NOT silently skip — silent gaps are worse than declared gaps.
</exhaustiveness>

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
  See $PROMPTS_REF for the full scaffold (exhaustiveness contract + severity mapping).
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

SEVERE_COUNT=$(jq '[.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$OUT_FILE")
printf '%s\n' "$OUT_FILE"
if [ "$SEVERE_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
