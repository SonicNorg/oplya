---
description: Run the zapili multi-agent development workflow. A task description may be passed inline; a TASK.md is optional and will be drafted/confirmed if absent.
argument-hint: "[task description] | [--resume]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*), Skill(orchestrator)
---

# /zapili:zapili — multi-agent development workflow

Run the strict codex pre-flight, then delegate to the orchestrator skill. A `TASK.md` in the project root is optional: pass a task description as arguments, rely on an existing `TASK.md`, or let the orchestrator prompt you — it always ends with a confirmed `TASK.md`.

## Step 1 — Pre-flight (mandatory)

Run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
If it exits non-zero, STOP and report the remediation printed by the script — do not continue.

## Step 2 — Orchestrate

Invoke the orchestrator skill, forwarding any task description as arguments. It owns the entire workflow (TASK.md resolution, state bootstrap, research, Q&A, validation loops, planning, plan validation; engineer execution lands in Phase 5+).

```
Skill(skill="orchestrator", args="$ARGUMENTS")
```

The orchestrator forks its own context so the references it loads do not bloat this thread. When it returns, surface its final message verbatim to the user.
