---
phase: 06
plan: 02
stamp: chaos-rehearsal
status: deferred (autonomous mode)
date: 2026-05-28
---

# Chaos rehearsal log

## Status: DEFERRED for manual rehearsal

The full chaos-rehearsal procedure (11 boundaries — `plugins/zapili/tests/chaos/README.md`) requires live kill-9 of the Claude Code process at specific tool-call boundaries. This cannot be performed inside the autonomous workflow that authored Phase 6 (the autonomous loop has no TTY harness to interrupt itself).

## Contract

Before the v1.0.0 release tag, a maintainer MUST follow the procedure in `plugins/zapili/tests/chaos/README.md` end-to-end and append the results to this file (one row per boundary with PASS/FAIL plus notes).

## What WAS verified (autonomous)

- `derive-stage.sh` was smoke-tested for the `no TASK.md → exit 64` and `bare TASK.md → research` paths.
- `summarize.sh` was smoke-tested with two synthetic `PHASE-XX-attempt-1.md` files; SUMMARY.md was generated correctly and ended with the completion sentinel.
- The Stage-0 resume rule + every artifact's completion sentinel discipline are documented in `skills/orchestrator/SKILL.md`.

## Open

| Boundary | Status |
|----------|--------|
| 1 — bootstrap → researcher | not rehearsed |
| 2 — researcher → CONTEXT.md write | not rehearsed |
| 3 — CONTEXT.md → research-validate | not rehearsed |
| 4 — research-validate clean → plan | not rehearsed |
| 5 — mid-planner | not rehearsed |
| 6 — plan-validate | not rehearsed |
| 7 — mid-engineer Wave 1 | not rehearsed |
| 8 — engineer attempt → review | not rehearsed |
| 9 — review HIGH → fresh fix spawn | not rehearsed |
| 10 — wave clean → summarize | not rehearsed |
| 11 — post-SUMMARY.md | not rehearsed |
