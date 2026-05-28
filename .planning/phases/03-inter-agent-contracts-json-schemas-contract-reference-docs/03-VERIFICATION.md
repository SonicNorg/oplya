---
phase: 03
status: passed
verified: 2026-05-28
mode: autonomous
---

# Phase 3 Verification

| # | Check | Result |
|---|-------|--------|
| 1 | `bash plugins/zapili/scripts/validate-schemas.sh` | PASS (ajv) |
| 2 | All schemas have `additionalProperties:false` + draft 2020-12 + `$id` matching oplya.dev URI | PASS |
| 3 | `grep` for forbidden vocab in codex-prompts.md → only backtick-quoted | PASS |
| 4 | task-sizing.md verbatim threshold table | PASS |
| 5 | contracts.md literal stable-ID formula | PASS |
| 6 | All `expected-findings.json` validate against `validation-findings.schema.json` | PASS |
| 7 | `plugin.json` unchanged | PASS |
| 8 | No `.gitkeep` files | PASS |
| 9 | `scripts/validate-manifests.sh` still passes | PASS |

## Requirements coverage

| REQ-ID | Status | Evidence |
|--------|--------|----------|
| ZAP-10 | Complete | `plugins/zapili/schemas/*.schema.json` + examples + validator |
| ZAP-11 | Complete | XML envelope in `contracts.md` |
| ZAP-12 | Complete | Stable-ID + budget + forbidden vocab in `contracts.md` |
| ZAP-13 | Complete | Thresholds in `task-sizing.md` |
| ZAP-14 | Complete | Exhaustive-review scaffold in `codex-prompts.md` |
| ZAP-15 | Complete | 5 fixtures + tests/fixtures/README.md |

## Human verification

None required — all checks automated.

## Notes

- `ajv-cli` was installed during plan execution via `npm install -g ajv-cli`. The validator's python-jsonschema fallback also exists for environments without npm.
- Live codex calibration against the five fixtures is deferred to Phase 4 development per CONTEXT D-10.
