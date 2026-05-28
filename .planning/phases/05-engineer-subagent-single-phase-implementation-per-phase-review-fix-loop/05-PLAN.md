---
phase: 05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop
type: overview
plans: 3
waves: 2
requirements: [ZAP-40, ZAP-43, ZAP-44, ZAP-45]
---

# Phase 5 Plan

## Waves

### Wave 1 (parallel-safe)
- **05-01** — engineer.md + codex-review-phase.sh (ZAP-40, ZAP-43)
- **05-02** — smoke-small-task fixture (supporting; documents acceptance test for ZAP-44, ZAP-45 round-trip)

### Wave 2 (depends on Wave 1)
- **05-03** — SKILL.md Stage 7 wiring (ZAP-44, ZAP-45 mechanically applied via attempt artifacts + fix loop)

## Disjointness
| Plan | Writes |
|------|--------|
| 05-01 | `plugins/zapili/agents/engineer.md`, `plugins/zapili/scripts/codex-review-phase.sh` |
| 05-02 | `plugins/zapili/tests/fixtures/smoke-small-task/**` |
| 05-03 | `plugins/zapili/skills/orchestrator/SKILL.md` |
Pairwise: ∅.

## Decision coverage
D-01..D-10 from 05-CONTEXT.md cited verbatim across plan files (D-01..D-03 in 05-01; D-09 in 05-02; D-04..D-08 in 05-03; D-10 cross-cutting).

## Requirements coverage
| REQ | Plan |
|-----|------|
| ZAP-40 | 05-01 (engineer.md) |
| ZAP-43 | 05-01 (codex-review-phase.sh) |
| ZAP-44 | 05-03 (fix loop with fresh spawn + prior attempt) |
| ZAP-45 | 05-03 (PHASE-XX-attempt-N.md write) |

## Phase-level verification
1. `bash -n` on codex-review-phase.sh passes; mode 0755 LF.
2. `agents/engineer.md` frontmatter tools = `Read, Glob, Grep, Edit, Write, Bash`.
3. SKILL.md Stage 7 PHASE-5-STUB block REPLACED with working single-phase pipeline; iteration cap 3 and prior-attempt routing explicit.
4. SKILL.md `allowed-tools` includes `Agent(researcher, planner, engineer)`.
5. `validate-manifests.sh` + `validate-schemas.sh` still pass.
6. Smoke fixture README documents the manual round-trip procedure.
