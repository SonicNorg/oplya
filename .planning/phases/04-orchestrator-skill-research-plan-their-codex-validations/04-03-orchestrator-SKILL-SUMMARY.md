---
phase: 04
plan: 03
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
  - plugins/zapili/commands/zapili.md
requirements_satisfied: [ZAP-21, ZAP-23, ZAP-24, ZAP-35, ZAP-52]
---

Authored `skills/orchestrator/SKILL.md` with full Phase-4 pipeline (Stages 1–6) plus Stage 7 PHASE-5-STUB demarcated by a parseable HTML comment block. Frontmatter:
- `description`: per D-02
- `allowed-tools: Read, Glob, Grep, Write, Edit, Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*), Bash(jq:*), Bash(date:*), Bash(mkdir:*), Agent(researcher, planner), AskUserQuestion`
- `context: fork`

Body:
- Stage 1 Bootstrap — sources state.sh, calls state_bootstrap
- Stage 2 Research — dispatches `Agent(researcher)`, schema-validates payload, persists `.zapili/researcher-output.json`
- Stage 3 User Q&A — `AskUserQuestion` per question, writes `CONTEXT.md` with completion sentinel
- Stage 4 Research-validate loop — iteration cap 3, prior-issue anchoring, persist findings per attempt (ZAP-23, ZAP-24)
- Stage 5 Planning — dispatches `Agent(planner)`, verifies on-disk artifacts + sentinel + `<files>` blocks
- Stage 6 Plan-validate loop — same loop semantics (ZAP-35)
- Stage 7 PHASE-5-STUB — clear placeholder for engineer execution (Phase 5) and wave fan-out (Phase 6)
- Error contract section — fail-fast diagnostics; no half-committed state; never touches `~/.claude/*` or `~/.config/codex/*` (ZAP-05 preserved)

Single-writer invariant for `.zapili/state.json` is documented at the top of the skill.

Completion sentinel (`<!-- <status>complete</status> -->`) rule embedded (ZAP-52).

`commands/zapili.md` updated:
- `allowed-tools` extended to include `Skill(orchestrator)`
- Body's Step 2 now invokes `Skill(skill="orchestrator")` instead of printing the Phase-2 stub
- Preflight gate (Step 1) preserved verbatim

Decisions: D-01..D-04, D-18.

Verification: `validate-manifests.sh` + `validate-schemas.sh` still pass; SKILL.md frontmatter parses; forbidden-vocabulary grep clean (fixed unquoted "top" → "start" in single-writer section).
