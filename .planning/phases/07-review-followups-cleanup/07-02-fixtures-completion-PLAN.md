---
phase: 07-review-followups-cleanup
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/tests/fixtures/README.md
  - plugins/zapili/tests/fixtures/f3-plan-ambiguity/PLAN.md
  - plugins/zapili/tests/fixtures/f4-phase-missing-tests/TASK.md
  - plugins/zapili/tests/fixtures/f5-phase-style-drift/TASK.md
autonomous: true
requirements: [ZAP-57]
must_haves:
  truths:
    - "fixtures/README.md calibration loop invokes per-role wrappers with their real signatures (no --role/--inputs/--out flags)"
    - "f3-plan-ambiguity/PLAN.md exists, references its PHASE-XX.md, ends with completion sentinel"
    - "f4-phase-missing-tests/TASK.md exists and describes the task that makes the seeded 'missing tests' gap interpretable"
    - "f5-phase-style-drift/TASK.md exists and describes the task that makes the seeded 'code-quality' finding interpretable"
    - "D-NN decisions cited: D-07 (loop rewrite), D-08 (f3 PLAN.md), D-09 (f4 TASK.md), D-10 (f5 TASK.md)"
---
<objective>Bring fixture coverage to 5/5 runnable end-to-end and remove documentation drift between the calibration loop and the actual wrapper signatures.</objective>
<context>
@.planning/phases/07-review-followups-cleanup/07-CONTEXT.md
@plugins/zapili/tests/fixtures/README.md
@plugins/zapili/scripts/codex-validate-research.sh
@plugins/zapili/scripts/codex-validate-plan.sh
@plugins/zapili/scripts/codex-review-phase.sh
</context>
<tasks>
<task type="auto"><name>Task 1: Rewrite tests/fixtures/README.md calibration loop</name>
<action>Edit `plugins/zapili/tests/fixtures/README.md` § "How Phase 4+ uses these". Replace the existing pseudo-loop with one that dispatches each fixture to the matching real wrapper: f1 → codex-validate-research.sh; f2, f3 → codex-validate-plan.sh; f4, f5 → codex-review-phase.sh. Document the per-fixture command shape. Keep the pass-criterion text and ID-derivation section unchanged.</action>
<acceptance_criteria>grep -q "codex-validate-research.sh" plugins/zapili/tests/fixtures/README.md; grep -q "codex-validate-plan.sh" plugins/zapili/tests/fixtures/README.md; grep -q "codex-review-phase.sh" plugins/zapili/tests/fixtures/README.md; no "--role" / "--inputs" / "--out" flags remain.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: f3-plan-ambiguity/PLAN.md minimal stub</name>
<action>Write `plugins/zapili/tests/fixtures/f3-plan-ambiguity/PLAN.md`. Minimal content: goal sentence ("Add a session-renewal API; sessions should last longer than the default"), single wave with PHASE-XX, requirements-traceability stub. Ends with completion sentinel. Length ≤ 25 lines.</action>
<acceptance_criteria>file exists; grep -q "PHASE-XX" plugins/zapili/tests/fixtures/f3-plan-ambiguity/PLAN.md; ends with the &lt;status&gt;complete&lt;/status&gt; sentinel.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: f4-phase-missing-tests/TASK.md minimal stub</name>
<action>Write `plugins/zapili/tests/fixtures/f4-phase-missing-tests/TASK.md`. Single short task description ("Implement a hash-table cache with unit tests covering insertion, eviction, and overflow"). No frontmatter, no sentinel needed (TASK.md is user input, not an orchestrator-written artifact). Length ≤ 10 lines.</action>
<acceptance_criteria>file exists; grep -q "tests" plugins/zapili/tests/fixtures/f4-phase-missing-tests/TASK.md.</acceptance_criteria>
</task>
<task type="auto"><name>Task 4: f5-phase-style-drift/TASK.md minimal stub</name>
<action>Write `plugins/zapili/tests/fixtures/f5-phase-style-drift/TASK.md`. Single short task description ("Add a public REST endpoint for user-profile updates"). Length ≤ 10 lines.</action>
<acceptance_criteria>file exists; grep -q "REST" plugins/zapili/tests/fixtures/f5-phase-style-drift/TASK.md.</acceptance_criteria>
</task>
</tasks>
<output>Create 07-02-fixtures-completion-SUMMARY.md.</output>
