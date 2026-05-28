---
phase: 04-orchestrator-skill-research-plan-their-codex-validations
type: overview
plans: 3
waves: 2
requirements:
  - ZAP-20
  - ZAP-21
  - ZAP-22
  - ZAP-23
  - ZAP-24
  - ZAP-30
  - ZAP-31
  - ZAP-32
  - ZAP-33
  - ZAP-34
  - ZAP-35
  - ZAP-50
  - ZAP-51
  - ZAP-52
---

# Phase 4 Plan

## Waves

### Wave 1 (parallel-safe)
- **04-01** — codex wrappers + state.sh (ZAP-22, ZAP-34, ZAP-50..52)
- **04-02** — researcher + planner subagent definitions (ZAP-20, ZAP-30..33)

### Wave 2 (depends on Wave 1)
- **04-03** — orchestrator SKILL.md body + commands/zapili.md update (ZAP-21, ZAP-23, ZAP-24, ZAP-35; integrates ZAP-20/30/22/34)

## Disjointness

| Plan | Writes |
|------|--------|
| 04-01 | `plugins/zapili/scripts/codex-review.sh`, `codex-validate-research.sh`, `codex-validate-plan.sh`, `state.sh` |
| 04-02 | `plugins/zapili/agents/researcher.md`, `agents/planner.md` |
| 04-03 | `plugins/zapili/skills/orchestrator/SKILL.md`, `plugins/zapili/commands/zapili.md` |

Pairwise: ∅.

## Decision coverage
All 19 D-IDs from 04-CONTEXT.md cited verbatim across plans (D-01..D-04, D-18 in 04-03; D-05..D-08 in 04-02; D-09..D-17 in 04-01; D-19 cross-cutting).

## Requirements coverage

| REQ | Plan | Notes |
|-----|------|-------|
| ZAP-20 | 04-02 | Read-only researcher; XML+JSON schema-valid |
| ZAP-21 | 04-03 | Orchestrator runs Q&A and writes CONTEXT.md |
| ZAP-22 | 04-01 | codex-validate-research.sh wrapper |
| ZAP-23 | 04-03 | Validation loop with iteration cap (skill body) |
| ZAP-24 | 04-03 | Prior-issue anchoring (skill body) |
| ZAP-30 | 04-02 | Planner subagent produces PLAN.md + PHASE-XX.md |
| ZAP-31 | 04-02 | Bounded phase count (planner prompt references task-sizing.md) |
| ZAP-32 | 04-02 | Mandatory `<files>` blocks in every PHASE-XX.md |
| ZAP-33 | 04-02 | Wave structure (mechanical disjointness verification deferred to Phase 6) |
| ZAP-34 | 04-01 | codex-validate-plan.sh wrapper; stdout/stderr separation; exit-code propagation |
| ZAP-35 | 04-03 | Plan-validation loop (skill body) |
| ZAP-50 | 04-01 | state.sh bootstrap + atomic writes |
| ZAP-51 | 04-01 | Single-writer rule documented in state.sh + skill body |
| ZAP-52 | 04-01 + 04-03 | Temp-then-rename pattern; `<status>complete</status>` sentinel in artifact files |

## Phase-level verification
1. `bash -n` on every new script; all `set -euo pipefail`.
2. All scripts mode 0755, LF, `${CLAUDE_PLUGIN_ROOT}` only.
3. `commands/zapili.md` body invokes `Skill(skill="orchestrator")` after preflight.
4. `skills/orchestrator/SKILL.md` frontmatter has `description`, `allowed-tools` (includes `Agent(researcher, planner)`), `context: fork`.
5. `agents/researcher.md` `tools: Read, Glob, Grep` (no Write/Edit/Bash).
6. `agents/planner.md` `tools: Read, Glob, Grep, Write`.
7. `state.sh` exposes `state_bootstrap`, `state_get`, `state_set`, `state_advance_stage`.
8. All scripts pass `validate-manifests.sh` (no manifest regressions); `validate-schemas.sh` still passes.
9. SKILL.md body documents the Phase-5 stub clearly (`<!-- PHASE-5-STUB ... -->`).
