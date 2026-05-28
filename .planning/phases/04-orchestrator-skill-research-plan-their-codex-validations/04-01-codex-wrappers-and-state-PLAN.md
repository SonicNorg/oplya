---
phase: 04-orchestrator-skill-research-plan-their-codex-validations
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/scripts/codex-review.sh
  - plugins/zapili/scripts/codex-validate-research.sh
  - plugins/zapili/scripts/codex-validate-plan.sh
  - plugins/zapili/scripts/state.sh
autonomous: true
requirements:
  - ZAP-22
  - ZAP-34
  - ZAP-50
  - ZAP-51
  - ZAP-52
must_haves:
  truths:
    - "codex-review.sh shells out to codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config, reads prompt from stdin, persists raw JSONL alongside parsed final message"
    - "codex-validate-research.sh composes the research_validator prompt per codex-prompts.md and writes findings JSON validated against validation-findings.schema.json"
    - "codex-validate-plan.sh same shape for plan_validator role"
    - "state.sh exposes state_bootstrap/state_get/state_set/state_advance_stage with atomic temp-then-rename writes"
    - "Every script is mode 0755, LF, set -euo pipefail, ${CLAUDE_PLUGIN_ROOT}-only paths"
    - "CONTEXT.md decisions implemented: D-09..D-17 (wrappers + state)"
---
<objective>
Ship four shell artifacts that the Phase-4 orchestrator skill body will compose during the workflow: a generic codex invocation wrapper, two role-specific validator wrappers, and the state library.
</objective>
<context>
@.planning/phases/04-orchestrator-skill-research-plan-their-codex-validations/04-CONTEXT.md
@.planning/phases/04-orchestrator-skill-research-plan-their-codex-validations/04-RESEARCH.md
@plugins/zapili/schemas/validation-findings.schema.json
@plugins/zapili/skills/orchestrator/references/codex-prompts.md
</context>
<tasks>
<task type="auto"><name>Task 1: codex-review.sh</name>
<action>Write `plugins/zapili/scripts/codex-review.sh` per RESEARCH § "codex-review.sh skeleton" and CONTEXT D-09. Takes `<prompt_file> <out_file>`. Invokes `codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config -` reading prompt from stdin. Writes raw JSONL to `<out>.raw.jsonl`, extracts final assistant message via jq to `<out>`. Returns codex's exit code. set -euo pipefail. Mode 0755 LF.</action>
<acceptance_criteria>bash -n passes; head -1 = #!/usr/bin/env bash; grep -q 'set -euo pipefail'; grep -q 'codex exec --json --sandbox read-only' .</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: codex-validate-research.sh</name>
<action>Write per CONTEXT D-10. Args: `<task_md> <context_md> [prior_findings_json]`. Composes a research_validator prompt block (XML, per codex-prompts.md scaffold), pipes to `codex-review.sh`, validates output against `validation-findings.schema.json` (prefer ajv, fallback python jsonschema; if neither, write findings file but exit 5). Persists to `.zapili/research-validate-attempt-N.json` where N is auto-incremented based on existing files. Exits 0 if no HIGH/MEDIUM findings, 1 otherwise. Separates stdout (parsed findings JSON) from stderr (codex progress). Mode 0755 LF.</action>
<acceptance_criteria>bash -n passes; grep -q 'research_validator'; grep -q 'codex-review.sh'; grep -q 'validation-findings.schema.json'.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: codex-validate-plan.sh</name>
<action>Same shape as Task 2 but for plan_validator role; args `<plan_md> <phase_xx_md_glob> [prior_findings_json]`; persists to `.zapili/plan-validate-attempt-N.json`. Mode 0755 LF.</action>
<acceptance_criteria>bash -n passes; grep -q 'plan_validator'; grep -q 'codex-review.sh'.</acceptance_criteria>
</task>
<task type="auto"><name>Task 4: state.sh</name>
<action>Write `plugins/zapili/scripts/state.sh` as a sourced helper library (no top-level execution). Functions: `state_bootstrap`, `state_get <field>`, `state_set <field> <value>`, `state_advance_stage <stage>`, `state_iter_inc <counter_path>` (jq-based, atomic temp-then-rename). `.zapili/state.json` schema per `state.schema.json`. Includes ASCII source-only guard: `[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { echo "source me"; exit 1; }`. Mode 0755 LF (still executable for line-3 source guard).</action>
<acceptance_criteria>bash -n passes; grep -q 'state_bootstrap'; grep -q 'mv .*state.json' (atomic write present); state_bootstrap sourced + invoked in a temp dir creates a state.json that validates against state.schema.json (manual verify).</acceptance_criteria>
</task>
</tasks>
<output>Create `04-01-codex-wrappers-and-state-SUMMARY.md`.</output>
