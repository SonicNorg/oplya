---
phase: 05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/agents/engineer.md
  - plugins/zapili/scripts/codex-review-phase.sh
autonomous: true
requirements: [ZAP-40, ZAP-43]
must_haves:
  truths:
    - "engineer.md frontmatter tools include Read, Glob, Grep, Edit, Write, Bash"
    - "engineer prompt body requires emitting XML envelope with payload matching phase-changes.schema.json"
    - "engineer prompt forbids writes outside the phase's <files>.writes list"
    - "codex-review-phase.sh composes the phase_reviewer prompt per codex-prompts.md and validates output against validation-findings.schema.json"
    - "codex-review-phase.sh persists output to .zapili/phase-XX-review-attempt-N.json"
    - "CONTEXT.md decisions implemented: D-01..D-03"
---
<objective>Engineer subagent definition + per-phase review wrapper script.</objective>
<context>
@.planning/phases/05-engineer-subagent-single-phase-implementation-per-phase-review-fix-loop/05-CONTEXT.md
@plugins/zapili/schemas/phase-changes.schema.json
@plugins/zapili/schemas/validation-findings.schema.json
@plugins/zapili/skills/orchestrator/references/codex-prompts.md
@plugins/zapili/scripts/codex-validate-plan.sh
@plugins/zapili/agents/planner.md
</context>
<tasks>
<task type="auto"><name>Task 1: engineer.md</name>
<action>Write `plugins/zapili/agents/engineer.md` per CONTEXT D-01, D-02. Frontmatter name/description/tools per D-01. Body: <role>, <inputs>, <task> (read inputs in order, implement, do not write outside <files>.writes), <output_contract> (XML envelope + payload schema $id + forbidden vocab).</action>
<acceptance_criteria>File exists; frontmatter tools list = `Read, Glob, Grep, Edit, Write, Bash`; body references phase-changes.schema.json by $id; body has explicit "do not write outside <files>.writes" rule; forbidden-vocab grep only inside backticks.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: codex-review-phase.sh</name>
<action>Write `plugins/zapili/scripts/codex-review-phase.sh` mirroring `codex-validate-plan.sh` shape per CONTEXT D-03. Args `<task_md> <phase_xx_md> <engineer_payload_json> [prior_findings_json]`. Composes `phase_reviewer` prompt with 6 categories per codex-prompts.md D-18. Persists to `.zapili/phase-<XX>-review-attempt-N.json` where XX is parsed from the PHASE-XX.md filename. Exit codes 0/1/2/3/5. Mode 0755 LF.</action>
<acceptance_criteria>bash -n passes; grep -q 'phase_reviewer'; grep -q 'validation-findings.schema.json'; grep -q 'codex-review.sh' (delegates to generic wrapper); mode 100755.</acceptance_criteria>
</task>
</tasks>
<output>Create 05-01-engineer-and-review-wrapper-SUMMARY.md.</output>
