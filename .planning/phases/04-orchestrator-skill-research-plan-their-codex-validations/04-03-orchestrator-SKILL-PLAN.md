---
phase: 04-orchestrator-skill-research-plan-their-codex-validations
plan: 03
type: execute
wave: 2
depends_on: ["04-01", "04-02"]
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
  - plugins/zapili/commands/zapili.md
autonomous: true
requirements:
  - ZAP-21
  - ZAP-23
  - ZAP-24
  - ZAP-35
  - ZAP-52
must_haves:
  truths:
    - "SKILL.md frontmatter declares allowed-tools that include Agent(researcher, planner) and Bash invocations to plugin scripts"
    - "SKILL.md body documents the full pipeline (bootstrap → research → Q&A → research-validate loop → plan → plan-validate loop → halt with PHASE-5-STUB)"
    - "Research-validate and plan-validate loops cap at 3 iterations and anchor prior issues by ID (ZAP-23, ZAP-24, ZAP-35)"
    - "Artifact writes append the <!-- <status>complete</status> --> sentinel (ZAP-52)"
    - "commands/zapili.md Step 2 invokes Skill(skill=\"orchestrator\") instead of printing the Phase-2 stub"
    - "CONTEXT.md decisions implemented: D-01..D-04, D-18 (plus integration of D-09..D-17 and D-05..D-08)"
---
<objective>
Wire the full Phase-4 pipeline by authoring the orchestrator skill body and pointing the slash command at it.
</objective>
<context>
@.planning/phases/04-orchestrator-skill-research-plan-their-codex-validations/04-CONTEXT.md
@plugins/zapili/commands/zapili.md
@plugins/zapili/agents/researcher.md
@plugins/zapili/agents/planner.md
@plugins/zapili/scripts/codex-review.sh
@plugins/zapili/scripts/codex-validate-research.sh
@plugins/zapili/scripts/codex-validate-plan.sh
@plugins/zapili/scripts/state.sh
@plugins/zapili/skills/orchestrator/references/contracts.md
</context>
<tasks>
<task type="auto"><name>Task 1: SKILL.md</name>
<action>Write `plugins/zapili/skills/orchestrator/SKILL.md` per CONTEXT D-01..D-04, D-18. Frontmatter:
- description: per D-02
- allowed-tools: per D-02 list
- context: fork
Body: Stage 0 preflight reminder; Stage 1 state bootstrap (source state.sh, call state_bootstrap); Stage 2 research dispatch (Agent(researcher)); Stage 3 user Q&A (AskUserQuestion per question; consolidate to CONTEXT.md with completion sentinel); Stage 4 research-validate loop (codex-validate-research.sh; iteration cap 3; prior-issue anchoring); Stage 5 plan dispatch (Agent(planner)); Stage 6 plan-validate loop; Stage 7 PHASE-5-STUB clearly demarcated. Each stage names exact tool calls.</action>
<acceptance_criteria>File exists; frontmatter contains `allowed-tools:` with `Agent(researcher, planner)` and `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*)`; body has `Stage 1`..`Stage 7` headings; body explicitly mentions the iteration cap (3) and prior-issue anchoring; body contains `<!-- PHASE-5-STUB` block.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: commands/zapili.md update</name>
<action>Edit `plugins/zapili/commands/zapili.md` to (a) keep the preflight step, (b) replace the Phase-2 stub with `Skill(skill="orchestrator")`. Extend `allowed-tools` frontmatter to include `Skill(orchestrator)` plus the existing `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)`.</action>
<acceptance_criteria>File exists; frontmatter `allowed-tools` includes `Skill(orchestrator)`; body's Step 2 invokes `Skill(skill="orchestrator")` and no longer prints the Phase-2 stub text verbatim.</acceptance_criteria>
</task>
</tasks>
<output>Create `04-03-orchestrator-SKILL-SUMMARY.md`.</output>
