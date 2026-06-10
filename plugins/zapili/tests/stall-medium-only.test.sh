#!/usr/bin/env bash
# Deterministic test for the MEDIUM-only stall exception (exit 9).
#
# Rule: when the loop stalls (severe count does not strictly decrease) but the
# remaining findings are MEDIUM-only (0 HIGH), the workflow does NOT halt — the
# MEDIUMs were attempted and are stuck but non-blocking, so the validator exits 9
# and the orchestrator proceeds. (HIGH still open would be exit 7 — escalate.)
#
# Hermetic: a fake codex on PATH emits a schema-valid MEDIUM-only payload; the
# prior attempt is seeded with the same severe count so the stall fires.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() { # <desc> <cond-rc>
  if [ "$2" -eq 0 ]; then printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1));
  else printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); fi
}

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/.zapili" "$work/bin"

# MEDIUM-only payload (2 MEDIUM, 0 HIGH). Severe count = 2.
cat >"$work/.zapili/payload.json" <<'JSON'
{
  "schema_version": 1,
  "findings": [
    {
      "id": "ISS-dddddddddddd",
      "severity": "MEDIUM",
      "category": "ambiguity",
      "file": "TASK.md",
      "line_range": "1-2",
      "kind": "ambiguous-wording",
      "summary": "stuck medium one",
      "remediation": "pin the intended interpretation",
      "prior_status": "carried"
    },
    {
      "id": "ISS-eeeeeeeeeeee",
      "severity": "MEDIUM",
      "category": "missing-context",
      "file": "CONTEXT.md",
      "line_range": "3-4",
      "kind": "thin-context",
      "summary": "stuck medium two",
      "remediation": "add the missing background",
      "prior_status": "carried"
    }
  ],
  "coverage": {
    "files_reviewed": ["TASK.md", "CONTEXT.md"],
    "categories_checked": ["contradictions", "missing-context", "hallucinated-references", "scope-creep", "ambiguity"]
  }
}
JSON

PAYLOAD_TEXT="<response><payload>$(cat "$work/.zapili/payload.json")</payload></response>"
LINE=$(jq -nc --arg t "$PAYLOAD_TEXT" \
  '{type:"item.completed", item:{id:"item_0", type:"agent_message", text:$t}}')
{
  printf '#!/usr/bin/env bash\n'
  printf 'touch "%s/codex-was-called"\n' "$work"
  printf "printf '%%s\\\\n' %q\n" "$LINE"
  printf 'exit 0\n'
} >"$work/bin/codex"
chmod +x "$work/bin/codex"
cp "$work/bin/codex" "$work/bin/codex-work"

cd "$work"
printf '# Task\nDo a thing.\n' >TASK.md
printf '# Context\n<decisions>\nD-1: x\n</decisions>\n<!-- <status>complete</status> -->\n' >CONTEXT.md
printf '%s\n' '{ "schema_version": 1, "fix_loop_cap": 4, "current_stage": "research_validate" }' >.zapili/state.json
# Prior attempt (N=1) with the same 2 severe MEDIUM findings -> next attempt N=2
# yields 2 >= 2 (no strict decrease) -> stall, but 0 HIGH -> exit 9.
cp .zapili/payload.json .zapili/research-validate-attempt-1.json

export CLAUDE_PLUGIN_ROOT="$ROOT"
export PATH="$work/bin:$PATH"
unset CLAUDE_INSTANCE

"$ROOT/scripts/codex-validate-research.sh" TASK.md CONTEXT.md \
  .zapili/research-validate-attempt-1.json >/dev/null 2>"$work/stderr.log"
rc=$?

[ "$rc" -eq 9 ]; check "exits 9 (proceed) on MEDIUM-only stall, not 7" "$?"
grep -q 'MEDIUM-only' "$work/stderr.log"; check "stderr explains the MEDIUM-only acceptance" "$?"

printf -- '----\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
