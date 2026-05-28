---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 01
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/schemas/validation-findings.schema.json
  - plugins/zapili/schemas/research-questions.schema.json
  - plugins/zapili/schemas/phase-changes.schema.json
  - plugins/zapili/schemas/state.schema.json
  - plugins/zapili/schemas/examples/(8 files)
  - plugins/zapili/scripts/validate-schemas.sh
requirements_satisfied:
  - ZAP-10
---

# Plan 03-01 Summary — schemas + examples + validator

Authored four JSON Schemas (draft 2020-12, `additionalProperties: false`, `$id` per CONTEXT D-02), 8 example fixtures (4 valid + 4 invalid), and `validate-schemas.sh` (prefers `ajv`, falls back to python jsonschema). All 8 examples classify correctly under `ajv` (installed via `npm install -g ajv-cli` during execution).

Decisions implemented: D-01..D-10, D-22, D-23.

## Verification
- `jq -e .` on all 12 JSON files → OK
- `bash plugins/zapili/scripts/validate-schemas.sh` → `[validate-schemas] ok: all schemas + examples pass (ajv)`

## Deviations
- `ajv-cli` was not pre-installed on the host; installed during plan execution. The script's graceful-fallback path was the original design (D-09), and would also have worked once `python jsonschema` is installed via pip. Both paths exist.
