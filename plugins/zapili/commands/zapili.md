---
description: Run the zapili multi-agent development workflow on TASK.md
argument-hint: "[--resume]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*), Skill(orchestrator)
---

# /zapili:zapili — multi-agent development workflow

Run the strict codex pre-flight, then delegate to the orchestrator skill.

## Step 1 — Pre-flight (mandatory)

Run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
If it exits non-zero, STOP and report the remediation printed by the script — do not continue.

## Step 2 — Orchestrate

Invoke the orchestrator skill. It owns the entire workflow (state bootstrap, research, Q&A, validation loops, planning, plan validation; engineer execution lands in Phase 5+).

```
Skill(skill="orchestrator")
```

The orchestrator forks its own context so the references it loads do not bloat this thread. When it returns, surface its final message verbatim to the user.
