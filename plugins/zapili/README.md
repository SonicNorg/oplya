# zapili

A multi-agent development workflow plugin for Claude Code. Drop a `TASK.md` into your working directory, run `/zapili:zapili`, and `zapili` drives research → plan → wave-parallel implementation, with each stage independently reviewed by the `codex` CLI.

## Prerequisites

- The `codex` CLI installed AND authenticated (`codex --version` should succeed; sign in via ChatGPT or set `OPENAI_API_KEY`).
- Claude Code v2.1.143 or later.

## How to author a TASK.md

Create a `TASK.md` in the directory where you want changes to land. Describe the change you want, the constraints you care about, and any context links or references the workflow should consult. `zapili`'s researcher reads the file, classifies the task size, and asks focused follow-up questions before any code is written.

A minimal `TASK.md` looks like:

```markdown
# Add JWT auth to the /login endpoint

Stack: Node 20 + Express + Postgres.
Constraints: backward-compatible with existing session cookie clients for ≥1 release.
References: see src/auth/ for current shape.
```

The full TASK.md schema and worked examples ship in a later release.

## Install

See the [marketplace README](../../README.md#install) — once the `oplya` marketplace is added, install with `/plugin install zapili@oplya`.

## Status

> The slash command surface is not yet wired in this release. This plugin's manifest is published so the marketplace install path is testable end-to-end; the orchestrator slash command lands in the next release.
