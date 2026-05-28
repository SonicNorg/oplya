---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/schemas/validation-findings.schema.json
  - plugins/zapili/schemas/research-questions.schema.json
  - plugins/zapili/schemas/phase-changes.schema.json
  - plugins/zapili/schemas/state.schema.json
  - plugins/zapili/schemas/examples/validation-findings.valid.json
  - plugins/zapili/schemas/examples/validation-findings.invalid.json
  - plugins/zapili/schemas/examples/research-questions.valid.json
  - plugins/zapili/schemas/examples/research-questions.invalid.json
  - plugins/zapili/schemas/examples/phase-changes.valid.json
  - plugins/zapili/schemas/examples/phase-changes.invalid.json
  - plugins/zapili/schemas/examples/state.valid.json
  - plugins/zapili/schemas/examples/state.invalid.json
  - plugins/zapili/scripts/validate-schemas.sh
autonomous: true
requirements:
  - ZAP-10
must_haves:
  truths:
    - "Four JSON Schemas exist under plugins/zapili/schemas/ using draft 2020-12"
    - "Each schema has additionalProperties:false and $id matching https://oplya.dev/zapili/schemas/<name>.schema.json"
    - "Each schema validates its .valid.json example and rejects its .invalid.json example"
    - "validate-schemas.sh prefers ajv, falls back to python jsonschema, hard-fails with remediation if neither is available"
    - "CONTEXT.md decisions implemented: D-01..D-10 (schemas + validator + examples); D-22 (no .gitkeep); D-23 (no SKILL.md created)"
  artifacts:
    - path: "plugins/zapili/schemas/validation-findings.schema.json"
      provides: "Contract for codex review payloads"
      contains: "\"$id\": \"https://oplya.dev/zapili/schemas/validation-findings.schema.json\""
    - path: "plugins/zapili/schemas/research-questions.schema.json"
      provides: "Contract for researcher subagent output"
      contains: "task_size"
    - path: "plugins/zapili/schemas/phase-changes.schema.json"
      provides: "Contract for engineer subagent output"
      contains: "files_touched"
    - path: "plugins/zapili/schemas/state.schema.json"
      provides: "Contract for .zapili/state.json"
      contains: "current_stage"
    - path: "plugins/zapili/scripts/validate-schemas.sh"
      provides: "Local self-test for schemas + examples"
      contains: "ajv"
---

<objective>
Author the four JSON Schemas + 8 example fixtures + the validator script that proves they all behave as specified.
</objective>

<context>
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-CONTEXT.md
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-RESEARCH.md
@CLAUDE.md
</context>

<tasks>

<task type="auto"><name>Task 1: schemas</name>
<action>
Create `plugins/zapili/schemas/` and write four schemas per RESEARCH.md § "Code Examples" #1 and CONTEXT.md D-05..D-08. All four use draft 2020-12, `$id` pattern `https://oplya.dev/zapili/schemas/<name>.schema.json`, `additionalProperties: false`, `schema_version: { const: 1 }`. Apply per-schema property shape from D-05/D-06/D-07/D-08.
</action>
<acceptance_criteria>
- All four `.schema.json` files exist and parse as valid JSON.
- Each contains `"$schema": "https://json-schema.org/draft/2020-12/schema"`.
- Each contains `"additionalProperties": false`.
- `research-questions.schema.json` includes the `oneOf` task_size→questions count constraint.
</acceptance_criteria>
</task>

<task type="auto"><name>Task 2: schema examples</name>
<action>
Create `plugins/zapili/schemas/examples/` with 8 files: `<name>.valid.json` and `<name>.invalid.json` for each of the four schemas. Valid examples satisfy the schema; invalid examples fail (e.g., extra property to trip `additionalProperties: false`, missing required field, wrong enum value).
</action>
<acceptance_criteria>
- 8 example files exist.
- `validate-schemas.sh` (Task 3) classifies each correctly.
</acceptance_criteria>
</task>

<task type="auto"><name>Task 3: validate-schemas.sh</name>
<action>
Write `plugins/zapili/scripts/validate-schemas.sh` per RESEARCH.md § "Code Examples" #3. Mode 0755, LF, `set -euo pipefail`. Prefers `ajv`, falls back to `python3 -c 'import jsonschema'`, hard-fails with remediation if neither.
</action>
<acceptance_criteria>
- Script is mode 0755, LF, syntax-clean (`bash -n` exits 0).
- `bash plugins/zapili/scripts/validate-schemas.sh` exits 0 when run from the repo root (after Tasks 1+2 complete).
</acceptance_criteria>
</task>

</tasks>

<verification>
Phase-3 verification step 1 and 2 from 03-PLAN.md pass.
</verification>

<output>
Create `.planning/phases/03-.../03-01-schemas-SUMMARY.md`.
</output>
