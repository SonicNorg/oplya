---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
plan: 02
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/skills/orchestrator/references/contracts.md
  - plugins/zapili/skills/orchestrator/references/task-sizing.md
  - plugins/zapili/skills/orchestrator/references/codex-prompts.md
requirements_satisfied:
  - ZAP-11
  - ZAP-12
  - ZAP-13
  - ZAP-14
---

# Plan 03-02 Summary — orchestrator reference docs

Authored three reference docs:
- `contracts.md` — XML envelope, stable ID rule (`sha256(file|line_range|kind)` first-12 hex, `ISS-` prefix), 10,000-token soft budget, forbidden vocabulary enumeration (`key/main/top/important` quoted in backticks), schema registry table.
- `task-sizing.md` — verbatim threshold table (small/medium/large/gigantic with LOC/Modules/Questions/Phases columns), definitions for LOC (additions+modifications only) and Modules (top-level packages).
- `codex-prompts.md` — mandatory prompt structure (role/inputs/categories/output_contract/prior_findings), per-role category lists (research_validator: 5; plan_validator: 8; phase_reviewer: 6), reclassification rules.

Decisions implemented: D-11..D-18, D-22, D-23.

## Verification
- `grep -nP '\b(key|main|top|important)\b' codex-prompts.md` → returns only matches inside backticks (the two enumeration mentions, both backtick-quoted)
- `grep 'sha256(file + "|" + line_range + "|" + kind)' contracts.md` → present
- `grep '10,000' contracts.md` → present; `grep '10000' contracts.md` → present
- `grep gigantic task-sizing.md` → 3 hits (table row + prose + wave-count row)

## Deviations
None.
