#!/usr/bin/env bash
# Deterministic regression test for derive-stage.sh stage derivation.
#
# Root cause being guarded: derive-stage.sh runs under `set -euo pipefail` and used
# `ls -1 <glob> | sort -V | tail -n1` to find the newest attempt file. With `nullglob`
# still off (it was enabled far below, mid-script), an unmatched glob reached `ls` as a
# literal pattern -> `ls` exits 2 -> `pipefail` propagates 2 -> the failing command
# substitution in an assignment trips `set -e` -> the script dies with exit 2 and, because
# of `2>/dev/null`, ZERO output. The orchestrator's Stage 0b (`derived_stage=$(...)`)
# therefore got an empty stage and could not resume. Reachable only once CONTEXT.md
# carries its completion sentinel, since the CONTEXT.md branch returns earlier.
#
# The same idiom below `shopt -s nullglob` fails the other way: the glob vanishes, `ls -1`
# runs with no arguments, lists the CWD, exits 0 — so a phase with no review at all is
# judged against an arbitrary project file. When that file is JSON without `.findings`
# (package.json, tsconfig.json), jq returns 0 severe findings and the unreviewed phase is
# silently treated as converged, skipping wave_fix.
#
# Contracts this test pins:
#   1. Every reachable state prints its stage on stdout and exits 0 (64 only for no TASK.md).
#   2. Attempt selection is version-ordered: attempt-10 wins over attempt-2.
#   3. A phase with zero reviews forces wave_fix even when a decoy JSON sits in the CWD.
#   4. The `ls -1` idiom stays out of the script.
#
# Hermetic: pure filesystem fixtures, no codex, no network.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVE="$ROOT/scripts/derive-stage.sh"
PASS=0
FAIL=0

# Version-sort and the pre-fix `ls` path both read the locale; pin it so the fixtures
# order identically everywhere.
export LC_ALL=C

check() { # <desc> <cond-rc>
  if [ "$2" -eq 0 ]; then printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1));
  else printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); fi
}

work="$(mktemp -d)"
# u+rwX first: case 4 chmods a fixture directory to 000.
trap 'chmod -R u+rwX "$work" >/dev/null 2>&1; rm -rf "$work"' EXIT

SENTINEL='<!-- <status>complete</status> -->'
CLEAN_JSON='{"schema_version":1,"findings":[]}'
SEVERE_JSON='{"schema_version":1,"findings":[{"severity":"HIGH","summary":"blocking"}]}'

# --- fixture + assertion helpers ---------------------------------------------
new_case() { # <name> -> prints a fresh fixture dir with TASK.md
  local d="$work/$1"
  mkdir -p "$d"
  printf '# Task\nDo a thing.\n' >"$d/TASK.md"
  printf '%s' "$d"
}

with_context() { printf '# Context\n%s\n' "$SENTINEL" >"$1/CONTEXT.md"; }
with_plan()    { printf '# Plan\n%s\n'    "$SENTINEL" >"$1/PLAN.md"; }

run_derive() { # <dir> -> sets OUT / RC / ERR
  OUT=$(cd "$1" && "$DERIVE" 2>"$work/err.log")
  RC=$?
  ERR=$(cat "$work/err.log")
}

expect_stage() { # <desc> <dir> <stage>
  run_derive "$2"
  [ "$RC" -eq 0 ] && [ "$OUT" = "$3" ]
  local ok=$?
  check "$1 -> $3" "$ok"
  [ "$ok" -eq 0 ] || printf '      got rc=%s stdout=[%s] stderr=[%s]\n' "$RC" "$OUT" "$ERR"
}

# --- case 1: no TASK.md -> exit 64 -------------------------------------------
d="$work/c1"; mkdir -p "$d"
run_derive "$d"
[ "$RC" -eq 64 ] && [ -z "$OUT" ]
check "no TASK.md -> exit 64, nothing on stdout" "$?"

# --- case 2: TASK.md only -> research ----------------------------------------
d=$(new_case c2)
expect_stage "TASK.md only" "$d" research

# --- case 3: sentinel CONTEXT.md, empty .zapili/ -> research_validate --------
# THE REPORTED CRASH: exits 2 with no output before the fix.
d=$(new_case c3); with_context "$d"; mkdir -p "$d/.zapili"
expect_stage "CONTEXT.md complete, no research-validate attempt" "$d" research_validate

# --- case 4: unreadable .zapili/ ---------------------------------------------
# Pins a KNOWN GAP, not desired behavior: under nullglob an unreadable directory
# expands to zero matches, indistinguishable from "no attempts yet". Deliberately
# not guarded here — the orchestrator's next call (state.sh -> jq on state.json)
# fails loudly on the same condition. Root bypasses permission bits, so skip there.
if [ "$(id -u)" -eq 0 ]; then
  printf 'SKIP: unreadable .zapili/ (running as root — permission bits do not apply)\n'
else
  d=$(new_case c4); with_context "$d"; mkdir -p "$d/.zapili"
  printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
  chmod 000 "$d/.zapili"
  expect_stage "unreadable .zapili/ reads as no attempts (known gap)" "$d" research_validate
  chmod 755 "$d/.zapili"
fi

# --- case 5: clean research-validate + sentinel PLAN.md -> plan_validate -----
# SECOND CRASH SITE: same idiom on the plan-validate glob.
d=$(new_case c5); with_context "$d"; with_plan "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
expect_stage "PLAN.md complete, no plan-validate attempt" "$d" plan_validate

# --- case 6: attempt-10 must beat attempt-2 (version, not lexicographic) -----
# Lexicographically attempt-2 sorts last and is clean -> would wrongly advance to plan.
d=$(new_case c6); with_context "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON"  >"$d/.zapili/research-validate-attempt-2.json"
printf '%s' "$SEVERE_JSON" >"$d/.zapili/research-validate-attempt-10.json"
expect_stage "attempt-10 (severe) wins over attempt-2 (clean)" "$d" research_validate

# --- case 7: both validations clean, no engineer attempt -> wave_execute -----
d=$(new_case c7); with_context "$d"; with_plan "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/plan-validate-attempt-1.json"
expect_stage "no PHASE-*-attempt-*.md" "$d" wave_execute

# --- case 8: engineer attempt written, no review yet -> wave_review ----------
d=$(new_case c8); with_context "$d"; with_plan "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/plan-validate-attempt-1.json"
printf '# Phase 01\n' >"$d/PHASE-01-attempt-1.md"
expect_stage "engineer attempt written, no phase review" "$d" wave_review

# --- case 9: partially reviewed wave + decoy JSON -> wave_fix ----------------
# THE LATENT BUG: phase 02 has no review. Pre-fix the eaten glob makes `ls -1` list
# the CWD, package.json wins the sort, jq finds no severe findings in it, and the
# unreviewed phase is declared converged -> `summarize`.
d=$(new_case c9); with_context "$d"; with_plan "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/plan-validate-attempt-1.json"
printf '# Phase 01\n' >"$d/PHASE-01-attempt-1.md"
printf '# Phase 02\n' >"$d/PHASE-02-attempt-1.md"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/phase-01-review-attempt-1.json"
printf '%s' '{"name":"decoy","version":"1.0.0"}' >"$d/package.json"
expect_stage "phase 02 unreviewed, decoy package.json present" "$d" wave_fix

# --- case 10: every phase reviewed clean, no SUMMARY.md -> summarize --------
d=$(new_case c10); with_context "$d"; with_plan "$d"; mkdir -p "$d/.zapili"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/research-validate-attempt-1.json"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/plan-validate-attempt-1.json"
printf '# Phase 01\n' >"$d/PHASE-01-attempt-1.md"
printf '# Phase 02\n' >"$d/PHASE-02-attempt-1.md"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/phase-01-review-attempt-1.json"
printf '%s' "$CLEAN_JSON" >"$d/.zapili/phase-02-review-attempt-1.json"
expect_stage "all phases reviewed clean, no SUMMARY.md" "$d" summarize

# --- case 11: SUMMARY.md with sentinel -> complete ---------------------------
printf '# Workflow summary\n%s\n' "$SENTINEL" >"$d/SUMMARY.md"
expect_stage "SUMMARY.md complete" "$d" complete

# --- case 12: the `ls -1` idiom must not come back ---------------------------
! grep -q 'ls -1' "$DERIVE"
check "derive-stage.sh contains no 'ls -1' glob idiom" "$?"

printf -- '----\nPASS=%d FAIL=%d\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
