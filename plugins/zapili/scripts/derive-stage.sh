#!/usr/bin/env bash
set -euo pipefail

# derive-stage.sh — print the canonical current_stage by inspecting on-disk artifacts.
# No args. Run from the user's project CWD.
# Source of truth: artifacts + completion sentinels (per ZAP-53).
#
# Returns one of: research | research_validate | plan | plan_validate |
#                 wave_execute | wave_review | wave_fix | summarize | complete
#
# State machine:
#   no TASK.md                       → exit 64 (workflow not started; nothing to derive)
#   no CONTEXT.md (or no sentinel)   → research
#   no .zapili/research-validate-attempt-*.json with severe=0 → research_validate
#   no PLAN.md (or no sentinel)      → plan
#   no .zapili/plan-validate-attempt-*.json with severe=0    → plan_validate
#   no PHASE-*-attempt-*.md          → wave_execute
#   no .zapili/phase-*-review-attempt-*.json with severe=0   → wave_review
#   any phase exists with HIGH/MEDIUM in latest review       → wave_fix
#   SUMMARY.md exists with sentinel  → complete
#   else                             → summarize

has_sentinel() {
  grep -qF '<!-- <status>complete</status> -->' "$1" 2>/dev/null
}

# 1. TASK.md required.
[ -f TASK.md ] || { printf 'no TASK.md found in %s\n' "$PWD" >&2; exit 64; }

# 2. CONTEXT.md.
if [ ! -f CONTEXT.md ] || ! has_sentinel CONTEXT.md; then
  printf 'research\n'
  exit 0
fi

# 3. Research-validate clean?
latest_rv=$(ls -1 .zapili/research-validate-attempt-*.json 2>/dev/null | sort -V | tail -n1)
if [ -z "$latest_rv" ]; then
  printf 'research_validate\n'
  exit 0
fi
severe=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$latest_rv" 2>/dev/null || echo 1)
if [ "$severe" != "0" ]; then
  printf 'research_validate\n'
  exit 0
fi

# 4. PLAN.md.
if [ ! -f PLAN.md ] || ! has_sentinel PLAN.md; then
  printf 'plan\n'
  exit 0
fi

# 5. Plan-validate clean?
latest_pv=$(ls -1 .zapili/plan-validate-attempt-*.json 2>/dev/null | sort -V | tail -n1)
if [ -z "$latest_pv" ]; then
  printf 'plan_validate\n'
  exit 0
fi
severe=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$latest_pv" 2>/dev/null || echo 1)
if [ "$severe" != "0" ]; then
  printf 'plan_validate\n'
  exit 0
fi

# 6. Any engineer attempt yet?
shopt -s nullglob
attempts=(PHASE-*-attempt-*.md)
if [ "${#attempts[@]}" -eq 0 ]; then
  printf 'wave_execute\n'
  exit 0
fi

# 7. Any per-phase review yet?
latest_phase_reviews=(.zapili/phase-*-review-attempt-*.json)
if [ "${#latest_phase_reviews[@]}" -eq 0 ]; then
  printf 'wave_review\n'
  exit 0
fi

# 8. Any phase with HIGH/MEDIUM in latest review → wave_fix.
phase_ids=$(printf '%s\n' "${attempts[@]}" | sed -E 's/^PHASE-([0-9]+(-[0-9]+)?)-attempt-[0-9]+\.md$/\1/' | sort -u)
needs_fix=0
for pid in $phase_ids; do
  latest=$(ls -1 ".zapili/phase-$pid-review-attempt-"*.json 2>/dev/null | sort -V | tail -n1)
  [ -n "$latest" ] || { needs_fix=1; break; }
  s=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$latest" 2>/dev/null || echo 1)
  if [ "$s" != "0" ]; then needs_fix=1; break; fi
done
if [ "$needs_fix" -eq 1 ]; then
  printf 'wave_fix\n'
  exit 0
fi

# 9. SUMMARY.md with sentinel → complete.
if [ -f SUMMARY.md ] && has_sentinel SUMMARY.md; then
  printf 'complete\n'
  exit 0
fi

printf 'summarize\n'
exit 0
