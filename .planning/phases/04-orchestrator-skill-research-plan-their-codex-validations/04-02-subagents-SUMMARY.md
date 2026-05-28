---
phase: 04
plan: 02
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/agents/researcher.md
  - plugins/zapili/agents/planner.md
requirements_satisfied: [ZAP-20, ZAP-30, ZAP-31, ZAP-32, ZAP-33]
---

Authored:
- `agents/researcher.md` — tools allowlist `Read, Glob, Grep` (no Write/Edit/Bash). Body specifies classify-per-task-sizing + question batch sized to class + XML envelope per contracts.md + forbidden-vocab reminder (D-05, D-06).
- `agents/planner.md` — tools allowlist `Read, Glob, Grep, Write`. Body specifies PLAN.md authoring + per-phase `PHASE-XX.md` with mandatory `<files>{"writes":[...],"reads":[...]}</files>` block + phase-count bound + wave-grouping pre-screening for disjoint writes (D-07, D-08).

Decisions: D-05..D-08.

Verification: forbidden-vocabulary grep returns matches only inside backtick-quoted enumeration. (Fixed a stray "top" usage in planner prompt prose during execution — see commit `c230a71`.)
