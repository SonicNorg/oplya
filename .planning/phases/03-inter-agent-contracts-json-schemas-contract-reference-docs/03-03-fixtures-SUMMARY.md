---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 03
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/tests/fixtures/README.md
  - plugins/zapili/tests/fixtures/f1-research-contradiction/(4 files)
  - plugins/zapili/tests/fixtures/f2-plan-write-overlap/(5 files)
  - plugins/zapili/tests/fixtures/f3-plan-ambiguity/(3 files)
  - plugins/zapili/tests/fixtures/f4-phase-missing-tests/(4 files)
  - plugins/zapili/tests/fixtures/f5-phase-style-drift/(4 files)
requirements_satisfied:
  - ZAP-15
---

# Plan 03-03 Summary — calibration fixtures

Authored five fixture directories per CONTEXT D-19 + the tests/fixtures README per D-21. Every fixture's `expected-findings.json` validates against `validation-findings.schema.json` (verified with `ajv` against all five).

| Fixture | Severity | Issue family | Expected ID |
|---------|----------|--------------|-------------|
| f1-research-contradiction | HIGH | contradictions | ISS-cc94a3aa8710 |
| f2-plan-write-overlap | HIGH | parallel-safety | ISS-da83a9a75c86 |
| f3-plan-ambiguity | MEDIUM | ambiguity | ISS-a5efb5f14a26 |
| f4-phase-missing-tests | MEDIUM | missing-tasks | ISS-3c9a191be875 |
| f5-phase-style-drift | LOW | code-quality | ISS-4653b5e9bc97 |

IDs computed via the formula in `contracts.md`:
```
ISS- + first-12-hex sha256(file + "|" + line_range + "|" + kind)
```
Each fixture's README documents the exact inputs used for the hash so re-computation is reproducible.

Decisions implemented: D-19..D-22, D-23.

## Verification
- `ajv validate` against `validation-findings.schema.json` on all 5 `expected-findings.json` → all valid
- All 5 fixture READMEs include the seeded ID and the SHA derivation
- `find plugins/zapili -name .gitkeep` → no matches

## Deviations
None. (Live codex run against the fixtures is deferred to Phase 4 — calibration is the file artifacts, not a live run, per CONTEXT D-10.)
