# Plan 08-02: f6 fixture — SUMMARY

**Completed:** 2026-05-28
**Status:** done
**Files touched:** 6

## Changes

| File | Operation | Summary |
|------|-----------|---------|
| `f6/TASK.md` | create | Short user-task description (hash-table cache with unit tests). |
| `f6/PLAN.md` | create | Single-phase Wave 1 plan referencing PHASE-XX. |
| `f6/PHASE-XX.md` | create | Phase plan that DELIBERATELY omits a unit-test authoring task and lists `src/cache.kt` (only) in `<files>.writes` — the seeded `missing-tasks` HIGH finding has its root cause here. |
| `f6/engineer-payload.json` | create | Schema-valid `phase-changes` payload simulating the 4th engineer attempt: stays in scope per PHASE-XX.md, never authors a test file. |
| `f6/prior-findings.json` | create | Schema-valid `validation-findings` payload with one HIGH `missing-tasks` finding (`ISS-23ba7d51473d`, SHA-256-derived per CALIB-01). |
| `f6/README.md` | create | Documents the scenario, ID derivation reproducer, live-codex round-trip command, and dual-outcome pass criterion (best case: codex solves it; acceptable case: codex halts cleanly with a documented exit code). |

## Acceptance gate

- All 6 files exist.
- `jq . engineer-payload.json` succeeds with `.attempt == 4`, `.files_touched | length == 1`.
- `jq . prior-findings.json` succeeds with `.findings | length == 1`, `.findings[0].severity == "HIGH"`, `.findings[0].id == "ISS-23ba7d51473d"`.
- `printf '%s' "plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md|null|missing-tasks" | sha256sum | cut -c1-12` → `23ba7d51473d` (matches the prior-findings id).
- PHASE-XX.md has the `<files>` block and no test-related task.

## Requirements progressed

- ZAP-60 acceptance #5 (f6 fixture exists; integration acceptance scaffolded): COMPLETE for the fixture inputs. The live round-trip itself is Plan 08-03.

## Decisions cited

D-13 (fixture content), D-14 (live-run expectations — actual live calibration in 08-03), D-15 (dual-outcome acceptance contract).

<!-- <status>complete</status> -->
