# Phase 8 Plan: Codex self-fix fallback after iteration cap

**Created:** 2026-05-28
**Phase:** 08-codex-self-fix-fallback
**Requirements:** ZAP-60

## Goal

When the codex review fix-loop hits its iteration cap (default 4) with persistent HIGH findings, do NOT halt — dispatch a fourth `codex` role (`fixer`) that emits a unified-diff patch against the offending artifact, dry-run/apply via `git apply`, re-run the original validator. Halt only if the post-fix re-review still has HIGH (or codex emits an empty patch).

## Wave structure

### Wave 1 (parallel)

- 08-01-fixer-script-and-prompt-PLAN.md — `scripts/codex-self-fix.sh` + `references/codex-prompts.md` fixer-role section
- 08-02-f6-fixture-PLAN.md — `tests/fixtures/f6-fix-loop-exhausted/*` (TASK + PLAN + PHASE-XX + engineer-payload + prior-findings + README)

### Wave 2 (blocked on Wave 1)

- 08-03-orchestrator-integration-and-live-calibration-PLAN.md — SKILL.md Stage 6 + Stage 7c integration; live-codex round-trip against f6, transcript persisted under `.planning/phases/08-.../live-codex-calibration-LOG.md`

## Requirements traceability

| REQ-ID  | Plan(s)       |
|---------|---------------|
| ZAP-60  | 08-01 + 08-02 + 08-03 |

## Phase-count rationale

Wave 1 produces the script + the fixture; both are pre-requisites for Wave 2's orchestrator wiring + the live-codex acceptance run. Cross-wave dependency = Wave 2 reads (does not write) both Wave 1 outputs. Single ZAP-60 requirement decomposed into three deliverable clusters because the live calibration is too cross-cutting to share a plan with either the script or the fixture (each fails closed if the live codex run is part of its acceptance criteria).

<!-- <status>complete</status> -->
