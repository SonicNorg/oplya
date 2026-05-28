# Phase 7 Research

**Compiled:** 2026-05-28
**Novelty:** LOW — all five follow-ups touch existing surfaces with known shapes.

## Surface map

| Follow-up | Touched file | Reference pattern |
|-----------|--------------|-------------------|
| C-03 / ZAP-55 | `plugins/zapili/agents/planner.md` | `plugins/zapili/agents/engineer.md` lines 13–14, 21 — prior-findings `<inputs>` and `<task>` instruction shape, copy verbatim |
| C-04 / ZAP-56 | `plugins/zapili/skills/orchestrator/SKILL.md` Stage 5 | Stage 3 (lines 102–138) — AskUserQuestion pattern + CONTEXT.md append shape |
| F-01/F-02 / ZAP-57 | `plugins/zapili/tests/fixtures/README.md` + 3 stubs | Real wrapper signatures: `codex-validate-research.sh <task> <context> [prior]`; `codex-validate-plan.sh <plan> <phase_glob> [prior]`; `codex-review-phase.sh <task> <phase> <engineer_payload> [prior]` |
| H-01 / ZAP-58 | `plugins/zapili/scripts/check-codex.sh` | 1-char edit; all guards already `-e`-safe per CLAUDE.md hook discipline |
| S-01 / ZAP-59 | `plugins/zapili/scripts/check-wave-disjointness.sh` | Line-44 regex broadening; existing `phase_writes()` already appends `.md` to whatever id is captured |

## Risks / open questions

None. All five follow-ups have explicit success criteria in ROADMAP.md Phase 7 and the v1.0 audit. No new technology surface.

## Verification posture

- Phase 7 verification is mechanical:
  - `bash -n` on the two patched scripts
  - `grep` for the new patterns in agents/SKILL.md
  - run `check-wave-disjointness.sh` against f2 fixture → exit 1 + OVERLAP diagnostic
  - run `check-wave-disjointness.sh` against any production PLAN.md (Phase 1..6) → exit 0 (regression guard)
  - run `check-codex.sh` with codex absent (mock PATH) → exit 0 (advisory contract preserved)

## Calibration of fixture wrappers

Live calibration against the actual codex CLI is deferred to Phase 8 (where it becomes the load-bearing acceptance test for the self-fix loop). For Phase 7, the fixture README rewrite is a documentation correction — its acceptance is "the documented commands match the actual wrapper signatures", not "every fixture passes live codex".

<!-- <status>complete</status> -->
