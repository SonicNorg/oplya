---
description: Show current zapili workflow stage, wave/phase position, and iteration counters from .zapili/state.json
model: claude-haiku-4-5
allowed-tools: Bash(test:*), Read
---

# /zapili:status — workflow snapshot

Read `.zapili/state.json` from the project CWD and present its contents as a human-readable status snapshot. Do NOT modify any file — this command is read-only by design (the orchestrator is the single writer to `state.json`, per ZAP-50).

## Step 1 — Check whether a workflow is active

Run `test -f .zapili/state.json`.

**If exit code is non-zero** (file missing): print exactly this and STOP — do not continue:

```
No active zapili workflow in this directory.

To start one:
  1. Create TASK.md describing the change you want.
  2. Run /zapili:zapili.

For help: /zapili:help.
```

**If exit code is zero** (file present): continue to Step 2.

## Step 2 — Load and parse

Read `.zapili/state.json` using the Read tool. It conforms to the state schema documented at `${CLAUDE_PLUGIN_ROOT}/schemas/state.schema.json`. Top-level fields you will encounter:

| Field | Type | Meaning |
|-------|------|---------|
| `schema_version` | const 1 | Schema version — ignore in the output |
| `task_path` | string | Path to the TASK.md that bootstrapped this workflow |
| `current_stage` | enum | One of: `research`, `research_validate`, `plan`, `plan_validate`, `wave_execute`, `wave_review`, `wave_fix`, `summarize`, `complete` |
| `current_wave` | integer or null | Active wave index when `current_stage` starts with `wave_*`; null otherwise |
| `current_phase` | string or null | Active phase id (e.g. `"01-02"`) when in `wave_*` stages; null otherwise |
| `fix_loop_cap` | integer (optional, default 4) | Per-validator iteration cap |
| `iteration_counters.research_validate` | integer | Completed research-validate iterations |
| `iteration_counters.plan_validate` | integer | Completed plan-validate iterations |
| `iteration_counters.per_phase_fix` | object | Map of phase-id → completed per-phase fix iterations |
| `issue_ids.research_validate` | array of `ISS-*` | Open research-validate finding ids carried into the next iteration |
| `issue_ids.plan_validate` | array of `ISS-*` | Open plan-validate finding ids |
| `issue_ids.per_phase_review` | object | Map of phase-id → array of open per-phase review ids |
| `started_at` | ISO-8601 string | When this workflow was bootstrapped |
| `updated_at` | ISO-8601 string | Last single-writer mutation timestamp |

## Step 3 — Render the snapshot

Print a structured snapshot in this exact layout. Replace `{...}` with the actual values from `state.json`. Use `—` (em-dash) for any null / missing optional field. Use `(none)` for empty arrays. Show the `meaning` column for `current_stage` based on the table below.

```
zapili — workflow status

  Task:        {task_path}
  Started:     {started_at}
  Updated:     {updated_at}
  Cap:         {fix_loop_cap, default 4}

Current position
  Stage:       {current_stage} — {meaning lookup, see below}
  Wave:        {current_wave or —}
  Phase:       {current_phase or —}

Iteration counters
  research_validate:  {N} / {cap}
  plan_validate:      {N} / {cap}
  per_phase_fix:      {one line per phase-id: e.g. "01-01: 2/4, 02-03: 1/4" or "(none)"}

Open finding ids
  research_validate:  {comma-joined ISS-* or "(none)"}
  plan_validate:      {comma-joined ISS-* or "(none)"}
  per_phase_review:   {one line per phase-id with its open ids, or "(none)"}
```

### `current_stage` → meaning lookup (use exactly these strings)

| `current_stage` value | meaning to print |
|-----------------------|------------------|
| `research` | Researcher subagent is producing questions for the user |
| `research_validate` | Codex is auditing TASK.md + CONTEXT.md for contradictions/gaps |
| `plan` | Planner subagent is authoring PLAN.md + PHASE-XX.md files |
| `plan_validate` | Codex is auditing PLAN.md for contradictions/parallel-safety/completeness |
| `wave_execute` | Engineer subagents implementing the current wave's phases (parallel fan-out) |
| `wave_review` | Codex per-phase review fanning out across the current wave |
| `wave_fix` | Per-phase fix loop converging engineer attempts for the current wave |
| `summarize` | Final SUMMARY.md being aggregated |
| `complete` | Workflow finished — SUMMARY.md is in the project root |

## Step 4 — Append next-step hint

After the snapshot, print one of these lines depending on `current_stage`:

- If `current_stage == "complete"`: `Workflow complete. See SUMMARY.md in the project root.`
- Otherwise: `To continue this workflow: re-run /zapili:zapili (no flags — Stage 0 resume is automatic).`

## Forbidden

- Do NOT modify `.zapili/state.json` or any other file.
- Do NOT dispatch any subagent or run any other script.
- Do NOT compute or speculate values that are not in `state.json` — if a field is missing, print `—`.
- Do NOT paraphrase the meaning-lookup strings; copy them verbatim from the table above so operators get consistent wording across sessions.
