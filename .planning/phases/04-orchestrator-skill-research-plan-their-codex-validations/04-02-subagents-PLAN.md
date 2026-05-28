---
phase: 04-orchestrator-skill-research-plan-their-codex-validations
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/agents/researcher.md
  - plugins/zapili/agents/planner.md
autonomous: true
requirements:
  - ZAP-20
  - ZAP-30
  - ZAP-31
  - ZAP-32
  - ZAP-33
must_haves:
  truths:
    - "researcher.md tools allowlist is read-only (Read, Glob, Grep) — no Write, Edit, Bash"
    - "planner.md tools allowlist includes Write (needed to author PLAN.md + PHASE-XX.md)"
    - "Both agents emit XML envelope per contracts.md; payloads validate against the respective schemas"
    - "planner.md prompt enforces mandatory <files>{writes,reads}</files> block in every PHASE-XX.md and phase-count bound per task-sizing.md"
    - "CONTEXT.md decisions implemented: D-05..D-08"
---
<objective>
Author the researcher and planner subagent prompts the orchestrator will dispatch in Phase 4 and Phase 5.
</objective>
<context>
@.planning/phases/04-orchestrator-skill-research-plan-their-codex-validations/04-CONTEXT.md
@plugins/zapili/schemas/research-questions.schema.json
@plugins/zapili/schemas/phase-changes.schema.json
@plugins/zapili/skills/orchestrator/references/contracts.md
@plugins/zapili/skills/orchestrator/references/task-sizing.md
@plugins/zapili/skills/orchestrator/references/codex-prompts.md
</context>
<tasks>
<task type="auto"><name>Task 1: researcher.md</name>
<action>Write `plugins/zapili/agents/researcher.md` per CONTEXT D-05, D-06. YAML frontmatter:
- name: researcher
- description: "zapili researcher: read-only investigator for TASK.md; classifies size and drafts question batch"
- tools: Read, Glob, Grep
Body sections: <role>, <inputs>, <task> (load TASK.md, walk references, classify per task-sizing.md), <output_contract> (XML envelope per contracts.md; payload validates against research-questions.schema.json), forbidden-vocab reminder.</action>
<acceptance_criteria>File exists; frontmatter tools list = `Read, Glob, Grep` exactly; no Write/Edit/Bash in tools; body references research-questions.schema.json by $id; body cites task-sizing.md.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: planner.md</name>
<action>Write `plugins/zapili/agents/planner.md` per CONTEXT D-07, D-08. Frontmatter:
- name: planner
- description: as per D-07
- tools: Read, Glob, Grep, Write
Body sections: <role>, <inputs> (TASK.md + CONTEXT.md + 3 reference docs), <task> (author PLAN.md + zero+ PHASE-XX.md, each with `<files>{"writes":[...],"reads":[...]}</files>` block, phase-count bounded per task-sizing.md), <output_contract> (XML envelope; payload schema is a small summary of {files_written, wave_count, phase_count}), forbidden-vocab reminder.</action>
<acceptance_criteria>File exists; frontmatter tools = `Read, Glob, Grep, Write`; body contains the literal string `<files>{"writes":[...],"reads":[...]}</files>` (or equivalent template); body references task-sizing.md and contracts.md.</acceptance_criteria>
</task>
</tasks>
<output>Create `04-02-subagents-SUMMARY.md`.</output>
