---
phase: 07-review-followups-cleanup
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/scripts/check-codex.sh
  - plugins/zapili/scripts/check-wave-disjointness.sh
autonomous: true
requirements: [ZAP-58, ZAP-59]
must_haves:
  truths:
    - "check-codex.sh line 2 becomes 'set -euo pipefail'; existing guards (cat || true, if ! command -v, if ! codex --version) all -e-safe; SessionStart still exits 0 on missing codex"
    - "check-wave-disjointness.sh phase-id regex broadens to PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)? matching both production (PHASE-01) and fixture (PHASE-XX-a) naming"
    - "f2 fixture (which uses PHASE-XX-a / PHASE-XX-b) now triggers the overlap detection code path"
    - "Both scripts pass bash -n"
    - "D-NN decisions cited: D-11 (check-codex -e); D-12, D-13 (regex broadening)"
---
<objective>Restore hook-script discipline and regex generality so the wave-disjointness check fires on fixture-style phase IDs and check-codex doesn't silently swallow future bugs.</objective>
<context>
@.planning/phases/07-review-followups-cleanup/07-CONTEXT.md
@plugins/zapili/scripts/check-codex.sh
@plugins/zapili/scripts/check-wave-disjointness.sh
@plugins/zapili/tests/fixtures/f2-plan-write-overlap
</context>
<tasks>
<task type="auto"><name>Task 1: check-codex.sh -e flag</name>
<action>Edit `plugins/zapili/scripts/check-codex.sh` line 2: `set -uo pipefail` → `set -euo pipefail`. No other changes. Verify the three existing guards remain -e-safe.</action>
<acceptance_criteria>head -2 plugins/zapili/scripts/check-codex.sh | tail -1 == "set -euo pipefail"; bash -n plugins/zapili/scripts/check-codex.sh; running the script with codex absent still exits 0 (advisory contract).</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: check-wave-disjointness.sh regex broaden</name>
<action>Edit `plugins/zapili/scripts/check-wave-disjointness.sh` line 44: regex `PHASE-[0-9]+(-[0-9]+)?` → `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?`. Verify by running the script against `plugins/zapili/tests/fixtures/f2-plan-write-overlap/PLAN.md` — exit code should be 1 with an OVERLAP diagnostic naming the two PHASE-XX-a/b files.</action>
<acceptance_criteria>bash -n; running against the f2 fixture exits 1 and stderr contains "OVERLAP"; running against any production PLAN.md (Phase 1..6) still exits 0.</acceptance_criteria>
</task>
</tasks>
<output>Create 07-03-shell-hygiene-SUMMARY.md.</output>
