#!/usr/bin/env bash
# Deterministic regression test for review-loop STALL detection (exit 7).
#
# Root cause being guarded: the validators used to perform a FULL exhaustive
# re-audit every pass with the objective "maximum findings". On subjective
# categories that structurally never converges — the severe-finding count can
# stay flat or grow forever while N climbs toward the cap. The fix makes the
# validator short-circuit with exit 7 when, from attempt N >= 2, the current
# severe (HIGH+MEDIUM) count does NOT strictly decrease vs the prior attempt.
#
# Contract this test pins:
#   Given a prior attempt with K severe findings on disk, when the current
#   attempt also yields >= K severe findings, codex-validate-research.sh MUST
#   exit 7 (stalled) — distinct from a clean exit 0 and from a blocking exit 1.
#
# Hermetic: a fake `codex`/`codex-work` on PATH emits a schema-valid payload
# (3 severe findings) wrapped in the codex JSONL envelope; no network.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() { # <desc> <cond-rc>
  if [ "$2" -eq 0 ]; then printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1));
  else printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); fi
}

# --- fixture workspace -------------------------------------------------------
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/.zapili"

# The schema-valid payload the fake codex returns for attempt 2: three distinct
# severe findings (2 HIGH + 1 MEDIUM). Severe count = 3 >= prior 3 -> stall.
cat >"$work/.zapili/payload.json" <<'JSON'
{
  "schema_version": 1,
  "findings": [
    {
      "id": "ISS-aaaaaaaaaaaa",
      "severity": "HIGH",
      "category": "contradictions",
      "file": "CONTEXT.md",
      "line_range": "1-2",
      "kind": "context-task-contradiction",
      "summary": "still-open contradiction one",
      "remediation": "reconcile the two statements",
      "prior_status": "carried"
    },
    {
      "id": "ISS-bbbbbbbbbbbb",
      "severity": "HIGH",
      "category": "missing-context",
      "file": "CONTEXT.md",
      "line_range": "3-4",
      "kind": "undefined-reference",
      "summary": "still-open missing context two",
      "remediation": "introduce the referenced system",
      "prior_status": "carried"
    },
    {
      "id": "ISS-cccccccccccc",
      "severity": "MEDIUM",
      "category": "ambiguity",
      "file": "TASK.md",
      "line_range": "5-6",
      "kind": "ambiguous-wording",
      "summary": "still-open ambiguity three",
      "remediation": "pin the intended interpretation",
      "prior_status": "carried"
    }
  ],
  "coverage": {
    "files_reviewed": ["TASK.md", "CONTEXT.md"],
    "categories_checked": ["contradictions", "missing-context", "hallucinated-references", "scope-creep", "ambiguity"]
  }
}
JSON

# Fake codex: emit one JSONL agent_message whose text embeds the payload inside
# the <payload>...</payload> envelope. jq @json handles the escaping correctly.
mkdir -p "$work/bin"
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
# Prior attempt (N=1) already on disk with 3 severe findings -> next attempt N=2.
cp .zapili/payload.json .zapili/research-validate-attempt-1.json

export CLAUDE_PLUGIN_ROOT="$ROOT"
export PATH="$work/bin:$PATH"
unset CLAUDE_INSTANCE

# --- run (no `set -e` here: failing assertions must not abort the harness) ---
"$ROOT/scripts/codex-validate-research.sh" TASK.md CONTEXT.md \
  .zapili/research-validate-attempt-1.json >/dev/null 2>"$work/stderr.log"
rc=$?

# --- assertions --------------------------------------------------------------
[ "$rc" -eq 7 ]; check "research validator exits 7 (stalled) when severe count does not strictly decrease" "$?"
[ -f "$work/codex-was-called" ]; check "codex IS invoked for stall (the pass runs, then the result is judged non-converging)" "$?"
grep -q 'stalled: no strict decrease' "$work/stderr.log"; check "stderr names the stall with the comparison" "$?"

printf -- '----\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
