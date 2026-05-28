---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 03
type: execute
wave: 2
depends_on: ["03-01", "03-02"]
files_modified:
  - plugins/zapili/tests/fixtures/README.md
  - plugins/zapili/tests/fixtures/f1-research-contradiction/
  - plugins/zapili/tests/fixtures/f2-plan-write-overlap/
  - plugins/zapili/tests/fixtures/f3-plan-ambiguity/
  - plugins/zapili/tests/fixtures/f4-phase-missing-tests/
  - plugins/zapili/tests/fixtures/f5-phase-style-drift/
autonomous: true
requirements:
  - ZAP-15
must_haves:
  truths:
    - "Five fixture directories exist, one per seeded-issue family"
    - "Each fixture contains the input artifacts, an expected-findings.json (matching validation-findings.schema.json), and a per-fixture README.md"
    - "expected-findings.json files use ISS- prefixed IDs computed via sha256(file|line_range|kind)"
    - "tests/fixtures/README.md documents how to run codex calibration during Phase 4 development"
    - "CONTEXT.md decisions implemented: D-19..D-21 (fixtures + expected-findings + calibration README); D-22 (no .gitkeep); D-23 (no SKILL.md created)"
  artifacts:
    - path: "plugins/zapili/tests/fixtures/README.md"
      provides: "Calibration workflow documentation"
      contains: "expected-findings.json"
---

<objective>
Author five calibration fixtures and the calibration README so Phase 4's codex wrapper development has a deterministic regression suite for the exhaustive-review prompt.
</objective>

<context>
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-CONTEXT.md
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-RESEARCH.md
@plugins/zapili/schemas/validation-findings.schema.json
@plugins/zapili/skills/orchestrator/references/codex-prompts.md
</context>

<tasks>

<task type="auto"><name>Task 1: five fixture directories</name>
<action>
Per CONTEXT.md D-19, create:
- `f1-research-contradiction/` — TASK.md + CONTEXT.md with a seeded HIGH contradiction
- `f2-plan-write-overlap/` — PLAN.md + PHASE-XX-a.md + PHASE-XX-b.md with overlapping `<files>` write blocks (seeded HIGH)
- `f3-plan-ambiguity/` — PHASE-XX.md with two incompatible interpretations of one task (seeded MEDIUM)
- `f4-phase-missing-tests/` — engineer phase-changes payload claiming tests but no test files in files_touched (seeded MEDIUM)
- `f5-phase-style-drift/` — Kotlin code summary describing mixed Java/Kotlin conventions (seeded LOW)
Each directory contains the input artifacts + `expected-findings.json` + per-fixture `README.md`.
</action>
<acceptance_criteria>
- Five directories under `plugins/zapili/tests/fixtures/` exist.
- Each contains at least one input artifact, `expected-findings.json`, and `README.md`.
- Each `expected-findings.json` parses and validates against `validation-findings.schema.json` (verify via `validate-schemas.sh` extension OR explicit `jq -e .` + ajv/jsonschema check).
</acceptance_criteria>
</task>

<task type="auto"><name>Task 2: calibration README</name>
<action>
Write `plugins/zapili/tests/fixtures/README.md` per CONTEXT.md D-21 documenting:
- Purpose (calibrate exhaustive-review prompt)
- Directory layout convention
- How Phase 4 development invokes codex against each fixture (placeholder for the wrapper that lands in Phase 4)
- Pass criterion: every ID in `expected-findings.json` appears in the codex output
</action>
<acceptance_criteria>
- File exists.
- Contains a table or list of the five fixtures with their seeded severities.
- Mentions `validation-findings.schema.json` and `codex-prompts.md` as upstream contracts.
</acceptance_criteria>
</task>

</tasks>

<verification>
Phase-3 verification step 6 from 03-PLAN.md passes.
</verification>

<output>
Create `.planning/phases/03-.../03-03-fixtures-SUMMARY.md`.
</output>
