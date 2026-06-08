# zapili

A multi-agent development workflow plugin for Claude Code. Describe the change you want — inline (`/zapili:zapili "<task>"`) or in a `TASK.md` — and `zapili` drives research → plan → wave-parallel implementation, with each stage independently reviewed by the `codex` CLI.

## Prerequisites

- The `codex` CLI installed AND authenticated (`codex --version` should succeed; sign in via ChatGPT or set `OPENAI_API_KEY`). When `$CLAUDE_INSTANCE=work`, `zapili` uses the `codex-work` binary instead of `codex` for every invocation and pre-flight check.
- Claude Code v2.1.143 or later.

## How to provide a task

A `TASK.md` is optional. You can:

- Pass the task inline: `/zapili:zapili "<describe the change>"`.
- Create a `TASK.md` in the directory where you want changes to land.
- Run `/zapili:zapili` with neither — the orchestrator prompts you to describe the change.

Every path ends with a confirmed `TASK.md` on disk: if one already exists, `zapili` asks whether to use it as-is, augment it, or replace it (it never adopts an existing `TASK.md` silently). Describe the change you want, the constraints you care about, and any context links or references the workflow should consult. `zapili`'s researcher reads the resolved `TASK.md`, classifies the task size, and asks focused follow-up questions before any code is written. After the first Q&A it captures a confirmed Definition of Done and appends it to `TASK.md`.

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

## Usage

In a Claude Code session with this plugin installed:

```
/zapili:zapili "<describe the change you want>"
```

or, if you have authored a `TASK.md`:

```
/zapili:zapili
```

The command first runs a strict codex pre-flight; if the resolved codex binary is missing or unauthenticated it halts with a remediation message. It then drives the full orchestrator (TASK.md resolution → research → plan → wave-parallel implementation → review).

## Pre-flight

Two safety nets verify codex is ready:

- **SessionStart hook** (`plugins/zapili/hooks/hooks.json`) — advisory only. If the resolved codex binary (`codex`, or `codex-work` when `$CLAUDE_INSTANCE=work`) is missing, prints remediation to stderr and exits 0 so Claude Code starts normally.
- **Command pre-flight** (`plugins/zapili/scripts/preflight-codex.sh`) — strict. Run from the slash command body; fails fast with distinct exit codes (2 = missing, 3 = `--version` broken, 4 = `exec` unreachable) and a remediation message.

Both probes use `codex exec --help` for auth verification, which never consumes API tokens or writes to `~/.config/codex/*`.
