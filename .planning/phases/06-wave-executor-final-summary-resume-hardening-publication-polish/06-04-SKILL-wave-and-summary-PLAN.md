---
phase: 06-wave-executor-final-summary-resume-hardening-publication-polish
plan: 04
type: execute
wave: 2
depends_on: ["06-01", "06-02", "06-03"]
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
autonomous: true
requirements: [ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54]
must_haves:
  truths:
    - "SKILL.md PHASE-6-STUB block is REPLACED with working Stage 7 wave parallel fan-out (single assistant turn with N Agent + N Bash calls) + per-wave fix loop (cap 3 per phase)"
    - "SKILL.md gets a new Stage 0 — Resume protocol section ABOVE Stage 1 that documents derive-stage.sh invocation + state.json rewrite-from-artifacts rule"
    - "Stage 8 invokes summarize.sh after the wave loop terminates clean"
    - "Stage 7 invokes check-wave-disjointness.sh BEFORE any wave fan-out and aborts the workflow on overlap"
    - "Allowed-tools unchanged (Agent allowlist already has researcher/planner/engineer from Phase 5)"
    - "CONTEXT.md decisions implemented: D-04..D-08, D-10"
---
<objective>Replace PHASE-6-STUB with working wave parallelism + Stage 8 summary + Stage 0 resume.</objective>
<context>
@.planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/06-CONTEXT.md
@plugins/zapili/skills/orchestrator/SKILL.md
@plugins/zapili/scripts/check-wave-disjointness.sh
@plugins/zapili/scripts/derive-stage.sh
@plugins/zapili/scripts/summarize.sh
</context>
<tasks>
<task type="auto"><name>Task 1: SKILL.md edits</name>
<action>Three edits in SKILL.md:
1. Insert a new `## Stage 0 — Resume protocol` section ABOVE Stage 1 documenting the artifact-first resume rule + `derive-stage.sh` invocation + state.json rewrite if it disagrees.
2. Rewrite Stage 7 to: (a) invoke `check-wave-disjointness.sh PLAN.md` first and abort on non-zero; (b) for each wave, branch on wave size: single phase → existing Stage 7a/b/c path; multi-phase → single assistant turn with N `Agent(engineer)` calls, then single assistant turn with N `Bash(codex-review-phase.sh)` calls, then per-phase fix loop (cap 3) keeping the wave open until every phase converges or one hits the cap.
3. Rewrite Stage 8 to invoke `summarize.sh` and surface the resulting `SUMMARY.md` to the user as the closing message.
Remove the PHASE-6-STUB HTML comment block entirely.</action>
<acceptance_criteria>SKILL.md: `Stage 0 — Resume protocol` heading present; `check-wave-disjointness.sh` mentioned; `single assistant turn` mentioned; `summarize.sh` mentioned; `PHASE-6-STUB` ABSENT; forbidden-vocab grep clean.</acceptance_criteria>
</task>
</tasks>
<output>Create 06-04-SKILL-wave-and-summary-SUMMARY.md.</output>
