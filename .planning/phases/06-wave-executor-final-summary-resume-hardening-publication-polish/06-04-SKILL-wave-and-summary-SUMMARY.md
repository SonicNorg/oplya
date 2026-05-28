---
phase: 06
plan: 04
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
requirements_satisfied: [ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54]
---

Three edits to SKILL.md:
1. **New Stage 0 — Resume protocol** inserted above Stage 1: invokes `derive-stage.sh`, reconciles `.zapili/state.json` with the artifact-derived stage (artifacts win), jumps to the appropriate stage; references `tests/chaos/README.md` for chaos-test scenarios.
2. **Stage 7 rewritten**: Section 7.0 invokes `check-wave-disjointness.sh PLAN.md` BEFORE any wave fan-out (mechanical ZAP-41 verification, aborts on overlap). Section 7a does parallel engineer fan-out via N `Agent(engineer)` calls in a SINGLE assistant turn (ZAP-42). Section 7b does parallel review fan-out via N `Bash(codex-review-phase.sh)` calls in a SINGLE assistant turn (ZAP-43). Section 7c does per-wave fix loop: needs-fix phases re-fan-out (fresh subagents, prior-attempt artifacts as input); per-phase cap 3; wave halts on cap reach (ZAP-46). Section 7d: strict sequential waves — Wave N+1 does not start until Wave N's fix loop fully converged (ZAP-47).
3. **Stage 8 rewritten**: invokes `summarize.sh`, then `state_advance_stage "complete"`, surfaces SUMMARY.md to user (ZAP-54).

PHASE-6-STUB HTML comment block REMOVED entirely.

Decisions D-04..D-08, D-10.

Verification: SKILL.md contains "Stage 0 — Resume protocol"; references check-wave-disjointness.sh, derive-stage.sh, summarize.sh, "single assistant turn" — 5 grep hits total; PHASE-6-STUB absent (0 hits); forbidden-vocabulary grep clean; validate-manifests.sh + validate-schemas.sh pass.
