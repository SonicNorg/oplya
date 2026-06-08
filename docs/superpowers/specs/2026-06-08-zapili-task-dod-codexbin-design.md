# zapili — TASK.md resolution, Definition of Done, and codex binary selection

**Date:** 2026-06-08
**Status:** Approved design (pending spec review)
**Scope:** Three independent enhancements to the `zapili` plugin workflow.

## Summary

Three enhancements to the `zapili` development workflow:

1. **Flexible TASK.md resolution** — the workflow no longer fails when `TASK.md`
   is absent. The task can come from slash-command arguments, an existing
   `TASK.md` (only with explicit user confirmation), or an interactive prompt.
   Every path ends with a confirmed `TASK.md` on disk.
2. **Definition of Done (DoD)** — after research and the first Q&A session, the
   orchestrator derives a draft DoD, confirms it with the user, and appends a
   stable-ID `## Definition of Done` section to `TASK.md`. Downstream the planner
   and the codex plan/phase validators reference these IDs.
3. **codex binary selection** — when `$CLAUDE_INSTANCE=work`, every codex
   invocation and pre-flight check uses `codex-work` instead of `codex`, via a
   single shared resolver.

The three features are independent and can be implemented in any order. Feature 3
is the most isolated; Features 1 and 2 both touch the orchestrator `SKILL.md`.

## Background

Current behavior (the constraints this design changes):

- `commands/zapili.md` runs a codex pre-flight, then forks the `orchestrator`
  skill with no task arguments.
- `skills/orchestrator/SKILL.md` **STOPs** when `TASK.md` is missing (loading
  order step 4, and Stage 0 via `derive-stage.sh` exit 64).
- There is no Definition of Done anywhere in the workflow.
- The `codex` binary name is hard-coded in three scripts: `codex-review.sh:31`
  (the only real `codex exec`), `preflight-codex.sh` (3 checks), and
  `check-codex.sh` (the SessionStart hook, 2 checks). All other codex wrappers
  delegate to `codex-review.sh`.

## Feature 1 — Flexible TASK.md resolution

### Goal

Never abort because `TASK.md` is missing. Always end with a `TASK.md` the user
has confirmed. Be flexible about where the task text originates, and never adopt
an existing `TASK.md` without explicit confirmation.

### Changes

**`commands/zapili.md`**
- Accept a free-form task description as command arguments.
- `argument-hint`: `"[task description] | [--resume]"`.
- Forward arguments to the orchestrator: `Skill(skill="orchestrator", args="$ARGUMENTS")`.
- Update the command description to mention that a task description may be passed
  inline and that `TASK.md` is optional.

**`skills/orchestrator/SKILL.md` — new Stage 0 "Ensure TASK.md"**

Runs **before** the existing resume protocol. Gated on the absence of
`.zapili/state.json`:

- If `.zapili/state.json` **exists** → this is a resume; `TASK.md` already exists
  from a prior run. Skip resolution entirely and fall through to the existing
  resume protocol. No re-confirmation on resume.
- If `.zapili/state.json` **does not exist** → fresh start; run the resolution
  flow below. The task description is available to the orchestrator as
  `$ARGUMENTS` (may be empty).

Resolution flow (always terminates with a confirmed `TASK.md`):

| State | Behavior |
|-------|----------|
| `TASK.md` exists | `AskUserQuestion`: **use as-is** / **augment with command arguments** / **replace with command arguments**. Never adopt silently. If arguments are empty, the "augment/replace" options are still offered but degrade to a free-form prompt for the new content. |
| No `TASK.md`, arguments present | Draft a `TASK.md` from the arguments, present it for confirmation/edit via `AskUserQuestion`, then write it. |
| No `TASK.md`, no arguments | `AskUserQuestion` asks the user to describe the change, draft a `TASK.md`, confirm, write. |

The orchestrator's `allowed-tools` already include `Write`, `Edit`, and
`AskUserQuestion`, so no frontmatter change is needed there.

After Stage 0 guarantees `TASK.md` exists, the existing resume protocol runs
`derive-stage.sh` (which now always finds `TASK.md`) and proceeds unchanged.

### Deliberately unchanged

- `derive-stage.sh` — the orchestrator guarantees `TASK.md` before it is called,
  so its exit-64 path is simply never reached on a fresh start. No script edit.
- State schema — no new state fields.

### Edge cases

- **Existing `TASK.md` + existing `state.json`** (a prior completed or
  in-progress run): treated as resume — `state.json` wins, no re-confirmation.
  Starting a brand-new task over an old one requires clearing `.zapili/`
  (documented behavior; out of scope to automate).
- **Empty arguments and user dismisses the prompt**: the workflow cannot proceed
  without a task; surface a single clear message and STOP. "Never fail" applies
  to the *missing-TASK.md* condition, not to a user who declines to provide any
  task at all.

## Feature 2 — Definition of Done

### Goal

After research and the first Q&A session, capture a confirmed, stable-ID
Definition of Done in `TASK.md`, and have downstream stages reference it.

### Changes

**`skills/orchestrator/SKILL.md` — new Stage 3.5 "Definition of Done"**

Inserted in Stage 3, after `CONTEXT.md` is written and before
`state_advance_stage "research_validate"`:

1. Derive a draft DoD from the researcher's reasoning plus the user's Q&A
   answers. Each item is a concrete, verifiable acceptance criterion.
2. Present the draft via `AskUserQuestion` (confirm / edit). Apply edits.
3. Append a marked section to `TASK.md`:

   ```markdown
   <!-- zapili:dod -->
   ## Definition of Done

   - **DoD-1:** <criterion>
   - **DoD-2:** <criterion>
   ```

   IDs are stable (`DoD-NN`, 1-based) so downstream agents and codex validators
   can cite them.

**Idempotency / resume**

The `research_validate` stage is ambiguous (Stage 3 ends by advancing to it, and
Stage 4 *is* it), so the resume signal lives in the file: if `TASK.md` already
contains the `<!-- zapili:dod -->` marker, Stage 3.5 is a no-op.

### Downstream references (DoD scope: **medium**)

- **`agents/planner.md`** + Stage 5 dispatch prompt — the planner reads the
  `## Definition of Done` section, ensures every phase maps to ≥1 `DoD-NN`, and
  records the phase→DoD trace in `PLAN.md`.
- **`skills/orchestrator/references/codex-prompts.md`**:
  - `plan_validator` scaffold — add a DoD-coverage check (every `DoD-NN` is
    covered by at least one phase; unmet coverage is a finding).
  - `phase_reviewer` scaffold — add a DoD-conformance check (the phase's changes
    satisfy the `DoD-NN` it claims to cover).
- **`research_validator`** — **not** changed. The DoD is born during the research
  stage; validating it in the same stage adds little and was scoped out.

### Deliberately unchanged

- JSON schemas — the DoD lives in `TASK.md` markdown, not in any JSON payload.
- `derive-stage.sh` / state schema.

## Feature 3 — codex binary selection (`codex` vs `codex-work`)

### Goal

When `$CLAUDE_INSTANCE=work`, use `codex-work` for every codex invocation and
every pre-flight/health check. Otherwise use `codex`. One source of truth.

### Changes

**New file `scripts/codex-bin.sh`** — a sourced helper that sets `CODEX_BIN`:

```bash
# Resolve which codex binary to use, based on the work/personal instance.
if [ "${CLAUDE_INSTANCE:-}" = "work" ]; then
  CODEX_BIN="codex-work"
else
  CODEX_BIN="codex"
fi
```

Sourced by the three scripts that name `codex` literally; each replaces the
literal with `"$CODEX_BIN"`:

- **`codex-review.sh`** — `source` the helper, then `"$CODEX_BIN" exec --json …`.
  This is the single real execution point; every other codex wrapper delegates
  here and inherits the switch for free.
- **`preflight-codex.sh`** — `command -v "$CODEX_BIN"`, `"$CODEX_BIN" --version`,
  `"$CODEX_BIN" exec --help`; the remediation/OK messages name the resolved
  binary.
- **`check-codex.sh`** (SessionStart hook) — `command -v "$CODEX_BIN"`,
  `"$CODEX_BIN" --version`; remediation names the resolved binary. The hook still
  never exits non-zero (per ZAP-02).

The helper resolves its own path independently of `${CLAUDE_PLUGIN_ROOT}` so the
hook (which knows only its own location) can source it via its script directory.

### Deliberately unchanged

- The delegating wrappers (`codex-review-phase.sh`, `codex-validate-plan.sh`,
  `codex-validate-research.sh`, `codex-self-fix.sh`) — they call
  `codex-review.sh`, so the switch propagates without edits.

## Documentation updates

- **`README.md`** — usage now allows `/zapili:zapili <task description>` and an
  optional (vs. required) `TASK.md`; mention `$CLAUDE_INSTANCE=work` → `codex-work`.
- **`commands/help.md`** — reflect the optional `TASK.md` + inline task argument.

## Full list of touched files

| File | Change |
|------|--------|
| `scripts/codex-bin.sh` | **New** — `CODEX_BIN` resolver. |
| `scripts/codex-review.sh` | Source resolver; `"$CODEX_BIN" exec`. |
| `scripts/preflight-codex.sh` | Source resolver; 3 checks + messages. |
| `scripts/check-codex.sh` | Source resolver; 2 checks + messages. |
| `commands/zapili.md` | Accept task arg; forward via `Skill(args=…)`; argument-hint. |
| `skills/orchestrator/SKILL.md` | New Stage 0 (Ensure TASK.md); new Stage 3.5 (DoD); Stage 5 planner prompt references DoD. |
| `skills/orchestrator/references/codex-prompts.md` | DoD checks in `plan_validator` + `phase_reviewer`. |
| `agents/planner.md` | Consume DoD; phase→DoD coverage trace in PLAN.md. |
| `README.md` | Usage updates. |
| `commands/help.md` | Usage updates. |

## Testing

- **Feature 3**: shell-level check — `CLAUDE_INSTANCE=work` makes the scripts
  resolve `codex-work`; unset/other resolves `codex`. Verify the resolver is
  sourced (not duplicated) in all three scripts.
- **Feature 1**: walk the three resolution branches manually against the
  orchestrator instructions (existing TASK.md, args-only, neither); confirm a
  `TASK.md` is produced and no STOP on the missing-file path.
- **Feature 2**: confirm Stage 3.5 appends the marked section once, is a no-op on
  re-run (marker present), and that the planner/validator prompts reference
  `DoD-NN`.
- Existing fixtures under `tests/fixtures/` should still pass; the
  `smoke-small-task` fixture exercises the happy path end-to-end.

## Out of scope

- Automating "start a fresh task over an existing completed run" (clearing
  `.zapili/`).
- DoD validation inside `research_validator`.
- Any JSON schema or `state.json` shape change.
- Multi-plugin abstraction.
