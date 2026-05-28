# Phase 7 Plan: Review follow-ups cleanup

**Created:** 2026-05-28
**Phase:** 07-review-followups-cleanup
**Requirements:** ZAP-55, ZAP-56, ZAP-57, ZAP-58, ZAP-59

## Goal

Close the five non-blocking follow-ups from the v1.0.0 ultra-principal review: planner prior-findings contract (C-03), orchestrator flagged_gaps routing (C-04), fixtures completion (F-01/F-02), `check-codex.sh` shell-flag hygiene (H-01), and `check-wave-disjointness.sh` phase-id regex (S-01).

## Wave structure

All three plans are parallel-safe (pairwise-disjoint `writes` sets).

### Wave 1 (parallel)

- 07-01-agents-orchestrator-PLAN.md — planner.md `<inputs>` + `<task>` patch + SKILL.md Stage 5 Step 5.5 (ZAP-55, ZAP-56)
- 07-02-fixtures-completion-PLAN.md — fixtures/README.md calibration loop + f3/PLAN.md + f4/TASK.md + f5/TASK.md (ZAP-57)
- 07-03-shell-hygiene-PLAN.md — check-codex.sh `-e` flag + check-wave-disjointness.sh regex (ZAP-58, ZAP-59)

## Requirements traceability

| REQ-ID  | Plan   |
|---------|--------|
| ZAP-55  | 07-01  |
| ZAP-56  | 07-01  |
| ZAP-57  | 07-02  |
| ZAP-58  | 07-03  |
| ZAP-59  | 07-03  |

## Phase-count rationale

5 requirements grouped into 3 deliverable clusters (agents+orchestrator / fixtures / shell). Each cluster touches a distinct file set with zero overlap → single wave, full parallelism, three commits.

<!-- <status>complete</status> -->
