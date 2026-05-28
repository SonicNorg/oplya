---
phase: 04
plan: 01
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/scripts/codex-review.sh
  - plugins/zapili/scripts/codex-validate-research.sh
  - plugins/zapili/scripts/codex-validate-plan.sh
  - plugins/zapili/scripts/state.sh
requirements_satisfied: [ZAP-22, ZAP-34, ZAP-50, ZAP-51, ZAP-52]
---

Authored:
- `codex-review.sh` — generic `codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config` wrapper, reads prompt via stdin, persists raw JSONL + parsed final message, propagates exit code (D-09).
- `codex-validate-research.sh` — composes `research_validator` prompt per `codex-prompts.md`, validates output against `validation-findings.schema.json` (ajv → python jsonschema fallback), persists to `.zapili/research-validate-attempt-N.json`, exits 0/1/2/3/5 (D-10).
- `codex-validate-plan.sh` — same shape for `plan_validator` role with explicit pairwise-disjointness instruction (D-11, ZAP-34).
- `state.sh` — sourced library exposing `state_bootstrap`, `state_get`, `state_set`, `state_advance_stage`, `state_iter_inc`; atomic temp-then-rename writes; source-guard refuses direct execution (D-14, D-15).

Decisions: D-09..D-17.

Verification: smoke test `state_bootstrap` produces a state.json that validates against `state.schema.json`; all scripts pass `bash -n`; all are mode 0755 LF.
