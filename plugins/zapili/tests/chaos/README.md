# Chaos rehearsal procedure

Use this procedure whenever you touch `skills/orchestrator/SKILL.md` Stage 0 (resume) or any code path that writes `.zapili/state.json` or an artifact with a completion sentinel. Phase 6 documents the scenarios; live execution is a manual rehearsal because programmatically killing Claude Code mid-tool-call requires a TTY harness that v1 does not ship.

## Setup

1. Sandbox dir with a small TASK.md (use `plugins/zapili/tests/fixtures/smoke-small-task/TASK.md`).
2. Run `/zapili:zapili` and stop it (Ctrl+C in the Claude Code TTY) at each of the boundaries below.
3. After the kill, run `derive-stage.sh` from the sandbox and verify it prints the expected stage.
4. Re-run `/zapili:zapili` and verify the orchestrator picks up exactly from `derive-stage.sh`'s output.

## Boundaries

| # | Kill point | Expected `derive-stage.sh` output | Expected resume behavior |
|---|------------|-----------------------------------|--------------------------|
| 1 | After `state_bootstrap` returns, before `Agent(researcher)` returns | `research` | Re-dispatches researcher (idempotent; researcher is read-only). |
| 2 | After researcher returns, before `CONTEXT.md` write completes (no sentinel) | `research` | CONTEXT.md without sentinel is treated as absent; orchestrator re-runs Q&A. |
| 3 | After `CONTEXT.md` write completes, before `codex-validate-research.sh` exits | `research_validate` | Re-runs codex-validate-research; iteration counter increments correctly. |
| 4 | After research-validate clean, before planner dispatch | `plan` | Re-dispatches planner. |
| 5 | Mid-planner write (PLAN.md exists but no sentinel) | `plan` | Treated as absent; planner re-runs. |
| 6 | After PLAN.md complete, mid plan-validate | `plan_validate` | Re-runs codex-validate-plan. |
| 7 | Mid-engineer in Wave 1 (no `PHASE-XX-attempt-1.md` yet) | `wave_execute` | Engineer re-dispatched; prior in-flight edits in working tree are not rolled back automatically (Phase 6 NOTE — git workflow keeps user in control). |
| 8 | After engineer attempt 1 written, before per-phase review exits | `wave_review` | Per-phase review re-runs. |
| 9 | Mid-fix-loop: review found HIGH; killed before fresh engineer dispatched | `wave_fix` | Fresh engineer spawn with prior-attempt artifact + findings. |
| 10 | After every phase review clean, before `summarize.sh` writes SUMMARY.md | `summarize` | summarize.sh re-runs and writes SUMMARY.md. |
| 11 | After SUMMARY.md sentinel written | `complete` | Orchestrator prints "workflow already complete" and exits. |

## Pass criterion

Every boundary above resumes correctly (the orchestrator picks up from `derive-stage.sh`'s output and reaches `complete` without manual intervention beyond Q&A re-answering when the kill happened mid-Q&A).

## Single-writer reminder

If `.zapili/state.json` disagrees with `derive-stage.sh`'s output, the orchestrator REWRITES `state.json` to match — single-writer rule preserved. Subagents and codex never touch `state.json` regardless.
