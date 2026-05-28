---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/skills/orchestrator/references/contracts.md
  - plugins/zapili/skills/orchestrator/references/task-sizing.md
  - plugins/zapili/skills/orchestrator/references/codex-prompts.md
autonomous: true
requirements:
  - ZAP-11
  - ZAP-12
  - ZAP-13
  - ZAP-14
must_haves:
  truths:
    - "contracts.md specifies the XML envelope shape and the literal stable-ID formula sha256(file|line_range|kind) ISS- prefix first-12-hex"
    - "contracts.md documents the 10000-token soft budget per engineer prompt"
    - "contracts.md enumerates the forbidden review-prompt vocabulary (key/main/top/important) and lists neutral replacements"
    - "task-sizing.md embeds the verbatim threshold table (small/medium/large/gigantic with LOC/modules/questions/phases columns)"
    - "codex-prompts.md defines role/inputs/categories/output_contract/prior_findings prompt scaffold per D-17 and lists per-role categories per D-18"
    - "codex-prompts.md prose AVOIDS the forbidden words except inside the explicit enumeration (backtick-quoted)"
    - "CONTEXT.md decisions implemented: D-11..D-18 (envelope/ID/budget/forbidden/sizing/scaffold); D-22 (no .gitkeep); D-23 (no SKILL.md created)"
  artifacts:
    - path: "plugins/zapili/skills/orchestrator/references/contracts.md"
      provides: "XML envelope + stable IDs + budgets + forbidden words"
      contains: "ISS-"
    - path: "plugins/zapili/skills/orchestrator/references/task-sizing.md"
      provides: "Numeric thresholds for size classes"
      contains: "gigantic"
    - path: "plugins/zapili/skills/orchestrator/references/codex-prompts.md"
      provides: "Exhaustive-review prompt scaffold + per-role categories"
      contains: "reclassification"
---

<objective>
Write the three reference docs that Phase 4+ subagent prompts and codex wrappers will treat as source of truth.
</objective>

<context>
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-CONTEXT.md
@.planning/phases/03-inter-agent-contracts-json-schemas-contract-reference-docs/03-RESEARCH.md
</context>

<tasks>

<task type="auto"><name>Task 1: contracts.md</name>
<action>
Create `plugins/zapili/skills/orchestrator/references/contracts.md` covering:
1. XML envelope shape (request + response with `<reasoning>` + `<payload>` JSON)
2. Stable issue ID rule: `ISS-` + first-12 hex of `sha256(file + "|" + line_range + "|" + kind)`
3. Payload-size soft budget: 10,000 tokens per engineer prompt; estimator `len_chars / 4`; warn-only (no hard fail)
4. Forbidden review-prompt vocabulary: `` `key`, `main`, `top`, `important` `` (always backtick-quoted in the doc); neutral replacements: `all`, `every category`, `exhaustive coverage`
5. Schema references (link each schema by `$id`)
</action>
<acceptance_criteria>
- File exists.
- Contains the literal formula `sha256(file + "|" + line_range + "|" + kind)`.
- Contains the literal string `10000` and `10,000` (token budget).
- Forbidden words appear only inside backticks or in YAML/JSON code fences (not in prose).
</acceptance_criteria>
</task>

<task type="auto"><name>Task 2: task-sizing.md</name>
<action>
Create `plugins/zapili/skills/orchestrator/references/task-sizing.md` containing the verbatim threshold table per CONTEXT.md D-15 and the definitions of "modules" and "LOC" per D-16.
</action>
<acceptance_criteria>
- File exists.
- Contains a markdown table with rows `small`, `medium`, `large`, `gigantic` and columns `LOC`, `Modules`, `Questions`, `Phases`.
- Defines `LOC = additions + modifications (deletions excluded)` and `Modules = top-level packages/directories`.
</acceptance_criteria>
</task>

<task type="auto"><name>Task 3: codex-prompts.md</name>
<action>
Create `plugins/zapili/skills/orchestrator/references/codex-prompts.md` containing the prompt scaffold per CONTEXT.md D-17 and the per-role category lists per D-18. The doc itself uses neutral vocabulary in prose; lists the forbidden words inside a single explicit enumeration (backtick-quoted).
</action>
<acceptance_criteria>
- File exists.
- Contains the literal section headings `<role>`, `<inputs>`, `<categories>`, `<output_contract>`, `<prior_findings>`, `<reclassification>`.
- Contains the per-role category lists for `research_validator`, `plan_validator`, `phase_reviewer`.
- `grep -nP '\b(key|main|top|important)\b' plugins/zapili/skills/orchestrator/references/codex-prompts.md` returns ONLY matches inside backticks or fenced code blocks.
</acceptance_criteria>
</task>

</tasks>

<verification>
Phase-3 verification steps 3, 4, 5 from 03-PLAN.md pass.
</verification>

<output>
Create `.planning/phases/03-.../03-02-references-SUMMARY.md`.
</output>
