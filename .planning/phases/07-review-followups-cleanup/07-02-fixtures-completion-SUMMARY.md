# Plan 07-02: fixtures completion — SUMMARY

**Completed:** 2026-05-28
**Status:** done
**Files touched:** 4

## Changes

| File | Operation | Summary |
|------|-----------|---------|
| `plugins/zapili/tests/fixtures/README.md` | modify | Rewrote § "How Phase 4+ uses these" → "How the calibration loop runs". New loop invokes the actual per-role wrappers with their real signatures (no `--role`/`--inputs`/`--out` flags). Added per-fixture command shape comments. Added note that `smoke-small-task` is exercised via the orchestrator skill, not the per-role wrappers. (D-07) |
| `plugins/zapili/tests/fixtures/f3-plan-ambiguity/PLAN.md` | create | Minimal 16-line plan referencing the existing PHASE-XX.md. Ends with completion sentinel. (D-08) |
| `plugins/zapili/tests/fixtures/f4-phase-missing-tests/TASK.md` | create | 5-line task description for JWT issuance with explicit unit-tests expectation — makes the seeded `missing-tasks` finding interpretable. (D-09) |
| `plugins/zapili/tests/fixtures/f5-phase-style-drift/TASK.md` | create | 5-line task description for Kotlin coroutine refactor — makes the seeded `code-quality` (style-drift) finding interpretable. (D-10) |

## Acceptance gate

- `grep "codex-validate-research.sh" plugins/zapili/tests/fixtures/README.md` → match.
- `grep "codex-validate-plan.sh" plugins/zapili/tests/fixtures/README.md` → match.
- `grep "codex-review-phase.sh" plugins/zapili/tests/fixtures/README.md` → match.
- No usages of the non-existent `--role` / `--inputs` / `--out` flags as actual commands (the only mention is a prose note that they do not exist).
- f3-plan-ambiguity/PLAN.md, f4-phase-missing-tests/TASK.md, f5-phase-style-drift/TASK.md all exist.
- All fixtures f1..f5 now have the inputs their wrapper signature expects (f1: TASK+CONTEXT; f2,f3: PLAN+PHASE-*; f4,f5: TASK+PHASE-XX+engineer-payload).

## Requirements closed

- ZAP-57 (F-01, F-02): fixtures completion + calibration-loop signature correction

## Decisions cited

D-07 (loop rewrite), D-08 (f3 PLAN.md), D-09 (f4 TASK.md), D-10 (f5 TASK.md).

<!-- <status>complete</status> -->
