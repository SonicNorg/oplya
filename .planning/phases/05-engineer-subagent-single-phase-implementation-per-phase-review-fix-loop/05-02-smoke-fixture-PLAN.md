---
phase: 05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/tests/fixtures/smoke-small-task/TASK.md
  - plugins/zapili/tests/fixtures/smoke-small-task/README.md
autonomous: true
requirements: [ZAP-44, ZAP-45]
must_haves:
  truths:
    - "smoke-small-task/ contains a small-class TASK.md (≤100 LOC change) suitable for the single-phase round-trip"
    - "smoke-small-task/README.md documents the manual procedure (clone into a sandbox, run /zapili:zapili, expected stages, what to verify)"
    - "CONTEXT.md decision implemented: D-09"
---
<objective>Authoring the smoke-test fixture and procedure document.</objective>
<context>
@.planning/phases/05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop/05-CONTEXT.md
@plugins/zapili/tests/fixtures/README.md
</context>
<tasks>
<task type="auto"><name>Task 1: TASK.md + README.md</name>
<action>Create `plugins/zapili/tests/fixtures/smoke-small-task/TASK.md` describing a small (≤100 LOC, 1–3 modules) reference change. Then create `README.md` documenting the manual smoke procedure: clone repo, drop TASK.md, run `/zapili:zapili`, expected stages, expected artifacts (CONTEXT.md, PLAN.md, PHASE-01.md, PHASE-01-attempt-1.md, `.zapili/state.json`), expected halt point in Phase 5 ("Phase 6 takes over from here for parallel waves").</action>
<acceptance_criteria>Both files exist; TASK.md classifies as small (researcher would pick small per task-sizing.md); README mentions PHASE-01-attempt-1.md as the expected attempt artifact.</acceptance_criteria>
</task>
</tasks>
<output>Create 05-02-smoke-fixture-SUMMARY.md.</output>
