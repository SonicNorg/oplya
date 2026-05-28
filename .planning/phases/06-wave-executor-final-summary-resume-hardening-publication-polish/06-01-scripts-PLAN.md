---
phase: 06-wave-executor-final-summary-resume-hardening-publication-polish
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/scripts/check-wave-disjointness.sh
  - plugins/zapili/scripts/derive-stage.sh
  - plugins/zapili/scripts/summarize.sh
autonomous: true
requirements: [ZAP-41, ZAP-53, ZAP-54]
must_haves:
  truths:
    - "check-wave-disjointness.sh parses PLAN.md waves and PHASE-XX.md <files> blocks, exits 0 only if every wave's pairwise writes intersection is empty"
    - "derive-stage.sh inspects artifacts on disk + completion sentinels and prints the canonical current_stage; orchestrator uses it on resume"
    - "summarize.sh walks PHASE-XX-attempt-N.md (latest attempt per phase) and emits SUMMARY.md in the user's project root aggregating files_touched + decisions"
    - "All three scripts: mode 0755, LF, set -euo pipefail, ${CLAUDE_PLUGIN_ROOT}-relative"
    - "CONTEXT.md decisions implemented: D-01..D-03 (disjointness), D-09 (aggregator), D-11 (derive-stage rule documented in script comments)"
---
<objective>Three scripts the Phase-6 orchestrator composes during wave execution + resume + summary.</objective>
<context>
@.planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/06-CONTEXT.md
@plugins/zapili/skills/orchestrator/SKILL.md
</context>
<tasks>
<task type="auto"><name>Task 1: check-wave-disjointness.sh</name>
<action>Write `plugins/zapili/scripts/check-wave-disjointness.sh`. Args: `<plan_md_path>`. For each wave enumerated in PLAN.md (parses "Wave N" headings + phase ids from bullet list), reads matching PHASE-XX.md `<files>{...}</files>` blocks via jq, computes pairwise writes intersection. Exit 0 if all disjoint; exit 1 with diagnostic if overlap; exit 2 on malformed `<files>` block.</action>
<acceptance_criteria>bash -n; grep -q '<files>'; mode 100755 LF; sample run on an overlapping fixture exits 1.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: derive-stage.sh</name>
<action>Write `plugins/zapili/scripts/derive-stage.sh`. No args. Inspects user CWD for TASK.md, CONTEXT.md, PLAN.md, PHASE-*.md, PHASE-*-attempt-*.md, .zapili/state.json, .zapili/*.json. Checks completion sentinels. Prints one of: `research`, `research_validate`, `plan`, `plan_validate`, `wave_execute`, `wave_review`, `wave_fix`, `summarize`, `complete`. Documented state-machine table in header comment.</action>
<acceptance_criteria>bash -n; prints `research` in an empty dir; prints `complete` when SUMMARY.md + every PHASE artifact exists with sentinel.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: summarize.sh</name>
<action>Write `plugins/zapili/scripts/summarize.sh`. No args. Walks PHASE-XX-attempt-N.md (latest attempt per phase id), extracts `<payload>{...}</payload>` JSON, aggregates `files_touched` (deduped by path), keeps `decisions` per-phase. Writes SUMMARY.md in CWD with sections Overview / Files Changed (by phase) / Decisions (by phase) / Review Outcomes / Open Items. Ends with completion sentinel.</action>
<acceptance_criteria>bash -n; writes SUMMARY.md when run in a dir with mocked PHASE-01-attempt-1.md; SUMMARY.md ends with the sentinel.</acceptance_criteria>
</task>
</tasks>
<output>Create 06-01-scripts-SUMMARY.md.</output>
