---
phase: 08-codex-self-fix-fallback
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/TASK.md
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PLAN.md
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/engineer-payload.json
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/prior-findings.json
  - plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/README.md
autonomous: true
requirements: [ZAP-60]
must_haves:
  truths:
    - "f6 fixture reproduces an engineer-stuck scenario: PHASE-XX.md DELIBERATELY omits a required test task; engineer-payload simulates 4 attempts all missing the same test task"
    - "prior-findings.json contains exactly one HIGH finding with category 'missing-tasks' targeting the missing test task; ISS-id deterministically derived per CALIB-01 from (PHASE-XX.md|<line_range>|missing-tasks)"
    - "README.md documents the scenario + the expected codex-self-fix outcome"
    - "All fixture files runnable as inputs to codex-self-fix.sh and codex-review-phase.sh"
    - "D-NN decisions cited: D-13 (fixture content), D-14 (live-run expectations — actual live calibration in 08-03)"
---
<objective>Create the integration acceptance fixture that exercises the codex-self-fix path end-to-end.</objective>
<context>
@.planning/phases/08-codex-self-fix-fallback/08-CONTEXT.md
@plugins/zapili/tests/fixtures/f4-phase-missing-tests
@plugins/zapili/skills/orchestrator/references/contracts.md
</context>
<tasks>
<task type="auto"><name>Task 1: TASK.md + PLAN.md + PHASE-XX.md</name>
<action>Write:
- `f6/TASK.md`: short task ("Implement a hash-table cache with unit tests covering insertion, eviction, and overflow")
- `f6/PLAN.md`: single-phase Wave 1 listing PHASE-XX
- `f6/PHASE-XX.md`: phase plan with `<files>` block writing `src/cache.kt` only (no `src/cache.test.kt`). Tasks list a single "Implement insertion" item — no test task. Ends with completion sentinel.</action>
<acceptance_criteria>All three files exist; PHASE-XX.md grep shows the `<files>` block and no test-related task.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: engineer-payload.json (simulated 4 attempts)</name>
<action>Write `f6/engineer-payload.json` — a schema-valid `phase-changes` payload representing the 4th engineer attempt: `attempt: 4`, `files_touched: [{path: "src/cache.kt", operation: "create", summary: "implement insertion"}]`, `decisions: []`, `change_summary: "implemented insertion; tests deferred"`. The engineer-keeps-missing-tests pattern is mirrored at attempt 4; earlier attempts are implied (the fixture only needs the latest for the codex-review-phase invocation).</action>
<acceptance_criteria>jq . on the file succeeds; `.attempt == 4`; `.files_touched | length == 1`.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: prior-findings.json (HIGH missing-tasks)</name>
<action>Write `f6/prior-findings.json` — a schema-valid `validation-findings` payload with exactly one finding: severity HIGH, kind `missing-tasks`, category `missing-tasks`, file `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md`, line_range `null`, remediation `"Add a task to the phase plan: 'Author unit tests in src/cache.test.kt covering insertion, eviction, and overflow' so the engineer's next attempt includes the test file in <files>.writes."`. ISS-id derived via SHA-256 of `"plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md|null|missing-tasks"` first-12-hex.</action>
<acceptance_criteria>jq . succeeds; `.findings | length == 1`; `.findings[0].severity == "HIGH"`; the ISS-id matches the SHA-256 derivation.</acceptance_criteria>
</task>
<task type="auto"><name>Task 4: README.md describing the scenario</name>
<action>Write `f6/README.md` documenting:
- Seeded issue: HIGH missing-tasks finding the engineer cannot self-resolve within the cap (the engineer is stateless and the phase spec is what's wrong).
- Expected codex-self-fix outcome: patch revises `PHASE-XX.md` to add a test-authoring task + extend `<files>.writes` to include `src/cache.test.kt`.
- Live-codex run command (informational; actually executed in Plan 08-03).
- Pass criterion: after applying the patch, re-running `codex-review-phase.sh` against the patched PHASE-XX.md + a stub engineer-payload returns no HIGH finding for the `missing-tasks` category.</action>
<acceptance_criteria>file exists; sections "Seeded issue", "Expected codex-self-fix outcome", "Live-codex run command", "Pass criterion" present.</acceptance_criteria>
</task>
</tasks>
<output>Create 08-02-f6-fixture-SUMMARY.md.</output>
