---
description: Run the zapili multi-agent development workflow on TASK.md
argument-hint: "[--resume]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)
---

# /zapili:zapili — multi-agent development workflow

Run the strict codex pre-flight, then (in this Phase-2 shell) print a stub message.
The full orchestrator lands in Phase 4.

## Step 1 — Pre-flight (mandatory)

Run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
If it exits non-zero, STOP and report the remediation printed by the script — do not continue.

## Step 2 — Phase-2 stub

If pre-flight succeeded, print:

> **zapili Phase 2 shell active.** Codex is available. The orchestrator (research → plan → wave-parallel implementation → review) is delivered in Phase 4. Until then `/zapili:zapili` only verifies pre-conditions.
