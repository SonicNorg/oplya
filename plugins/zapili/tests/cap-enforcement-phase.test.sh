#!/usr/bin/env bash
# Deterministic cap regression test for the PHASE reviewer specifically.
#
# codex-review-phase.sh derives a PHASE_ID from the PHASE-XX.md filename and
# keys its attempt counter on it (.zapili/phase-<ID>-review-attempt-N.json) —
# logic the research/plan validators lack. This test guards that the cap
# enforcement still fires correctly through that phase-id-scoped path: a
# copy-paste divergence in the PHASE_ID/OUT_FILE block would slip past the
# research-only cap test but fail here.
#
# Contract: when next attempt N > fix_loop_cap, exit 6 and do NOT invoke codex.
# Hermetic: fake codex/codex-work on PATH records any invocation; no network.
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

mkdir -p "$work/bin"
cat >"$work/bin/codex" <<EOF
#!/usr/bin/env bash
touch "$work/codex-was-called"
printf '%s\n' '{"type":"item.completed","item":{"type":"agent_message","text":"<payload>{}</payload>"}}'
exit 0
EOF
chmod +x "$work/bin/codex"
cp "$work/bin/codex" "$work/bin/codex-work"

cd "$work"
mkdir -p .zapili
printf '# Task\nDo a thing.\n' >TASK.md
printf '# Phase 01\nImplement the thing.\n<files>{"writes":["src/x"]}</files>\n' >PHASE-01.md
printf '%s\n' '{"files_touched":[],"decisions":[]}' >engineer-payload.json
printf '%s\n' '{ "schema_version": 1, "fix_loop_cap": 2, "current_stage": "wave_review" }' >.zapili/state.json
# Two prior phase-01 reviews already on disk -> next attempt N=3, exceeds cap=2.
printf '%s\n' '{"findings":[]}' >.zapili/phase-01-review-attempt-1.json
printf '%s\n' '{"findings":[]}' >.zapili/phase-01-review-attempt-2.json

export CLAUDE_PLUGIN_ROOT="$ROOT"
export PATH="$work/bin:$PATH"
unset CLAUDE_INSTANCE

"$ROOT/scripts/codex-review-phase.sh" TASK.md PHASE-01.md engineer-payload.json >/dev/null 2>"$work/stderr.log"
rc=$?

[ "$rc" -eq 6 ]; check "phase reviewer exits 6 (cap reached) when N > fix_loop_cap" "$?"
[ ! -f "$work/codex-was-called" ]; check "codex is NOT invoked at the cap (phase-id-scoped path)" "$?"

printf -- '----\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
