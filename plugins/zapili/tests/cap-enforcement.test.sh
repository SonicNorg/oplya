#!/usr/bin/env bash
# Deterministic regression test for the review-loop iteration cap (research/plan/phase).
#
# Root cause being guarded: the iteration cap used to live only in orchestrator
# prose, with N tracked in the LLM's memory; the validator scripts never read
# `fix_loop_cap` nor enforced it, so a non-converging codex could loop far past
# the cap (observed: 20 research-validate iterations against cap 4).
#
# Contract this test pins:
#   When the next attempt number N would exceed `fix_loop_cap`, the validator
#   script MUST short-circuit with exit code 6 (cap reached) and MUST NOT invoke
#   codex (no further review pass at the cap — the orchestrator escalates instead).
#
# Hermetic: a fake `codex`/`codex-work` on PATH records any invocation; no network.
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
printf '# Context\n<decisions>\nD-1: x\n</decisions>\n<!-- <status>complete</status> -->\n' >CONTEXT.md
printf '%s\n' '{ "schema_version": 1, "fix_loop_cap": 2, "current_stage": "research_validate" }' >.zapili/state.json
# Two prior attempts already on disk -> next attempt N=3, which exceeds cap=2.
printf '%s\n' '{"findings":[]}' >.zapili/research-validate-attempt-1.json
printf '%s\n' '{"findings":[]}' >.zapili/research-validate-attempt-2.json

export CLAUDE_PLUGIN_ROOT="$ROOT"
export PATH="$work/bin:$PATH"
unset CLAUDE_INSTANCE

# --- run (no `set -e` here: failing assertions must not abort the harness) ---
"$ROOT/scripts/codex-validate-research.sh" TASK.md CONTEXT.md >/dev/null 2>"$work/stderr.log"
rc=$?

# --- assertions --------------------------------------------------------------
[ "$rc" -eq 6 ]; check "research validator exits 6 (cap reached) when N > fix_loop_cap" "$?"
[ ! -f "$work/codex-was-called" ]; check "codex is NOT invoked at the cap (no extra review pass)" "$?"

printf -- '----\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
