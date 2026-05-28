---
phase: 05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop
plan: 03
type: execute
wave: 2
depends_on: ["05-01", "05-02"]
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
autonomous: true
requirements: [ZAP-44, ZAP-45]
must_haves:
  truths:
    - "SKILL.md Stage 7 PHASE-5-STUB block is REPLACED with a working single-phase implementation (one wave, one phase at a time)"
    - "Each engineer spawn writes PHASE-XX-attempt-N.md (numbered ascending) with the completion sentinel"
    - "Fix iteration uses a FRESH Agent(engineer, ...) spawn with TASK.md + scoped CONTEXT + PHASE-XX.md + prior PHASE-XX-attempt-(N-1).md + <prior_findings>"
    - "Per-phase iteration cap = 3"
    - "SKILL.md frontmatter allowed-tools includes Agent(researcher, planner, engineer)"
    - "Phase 6 stub clearly demarcated for wave parallelism + summary aggregator"
    - "CONTEXT.md decisions implemented: D-04..D-08"
---
<objective>Wire engineer round-trip + per-phase review + fix loop into the orchestrator SKILL.md.</objective>
<context>
@.planning/phases/05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop/05-CONTEXT.md
@plugins/zapili/skills/orchestrator/SKILL.md
@plugins/zapili/agents/engineer.md
@plugins/zapili/scripts/codex-review-phase.sh
</context>
<tasks>
<task type="auto"><name>Task 1: SKILL.md Stage 7 substitution</name>
<action>Edit `plugins/zapili/skills/orchestrator/SKILL.md`: (a) extend `allowed-tools` to add `engineer` to the Agent allowlist; (b) replace the entire PHASE-5-STUB HTML comment block with a working Stage 7 + Stage 8 section that documents the single-phase round-trip (one phase per wave, sequential across waves) + per-phase review + fix loop with iteration cap 3, and a clearly demarcated `<!-- PHASE-6-STUB ... -->` block for the residual Phase 6 work (wave parallel fan-out, pairwise disjointness pre-flight, summary aggregator, resume hardening).</action>
<acceptance_criteria>SKILL.md contains the literal string `PHASE-XX-attempt-N.md`; contains `iteration cap`; contains `PHASE-6-STUB`; allowed-tools includes `Agent(researcher, planner, engineer)`; no more `PHASE-5-STUB`; forbidden-vocabulary grep clean.</acceptance_criteria>
</task>
</tasks>
<output>Create 05-03-SKILL-stage7-SUMMARY.md.</output>
