# Phase 4: Orchestrator skill + research + plan + their codex validations - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution (smart-discuss skipped — decisions derived from ROADMAP success criteria + REQUIREMENTS ZAP-20..24/30..35/50..52 + CLAUDE.md + Phase-3 contracts)

<domain>
## Phase Boundary

A linear, end-to-end one-shot pipeline runs from `TASK.md` through:
- researcher subagent → emits `research-questions` payload
- user Q&A (AskUserQuestion or text fallback) → consolidates into `CONTEXT.md`
- codex research-validate (loops with prior-issue anchoring, iteration cap ≤3) → halts or proceeds
- planner subagent → emits `PLAN.md` + `PHASE-XX.md` files with mandatory `<files>` blocks
- codex plan-validate (loops with same caps)

State bootstrap, single-writer discipline, and artifact-derived resume.

**In scope:**
- `plugins/zapili/skills/orchestrator/SKILL.md` — orchestrator skill body (the actual workflow logic; the existing `commands/zapili.md` now delegates to this skill via skill invocation)
- `plugins/zapili/agents/researcher.md` — read-only subagent (ZAP-20)
- `plugins/zapili/agents/planner.md` — plan-authoring subagent (ZAP-30..33)
- `plugins/zapili/scripts/codex-review.sh` — generic wrapper (codex exec --json --sandbox read-only --ignore-user-config)
- `plugins/zapili/scripts/codex-validate-research.sh` — research validation wrapper (ZAP-22, ZAP-23)
- `plugins/zapili/scripts/codex-validate-plan.sh` — plan validation wrapper (ZAP-34)
- `plugins/zapili/scripts/state.sh` — helpers to bootstrap + atomic-write `.zapili/state.json` (ZAP-50..52)
- Update `plugins/zapili/commands/zapili.md` Step 2 stub → delegate to `skills/orchestrator/SKILL.md`

**Out of scope (Phase 5+):**
- Engineer subagent (Phase 5)
- Per-phase review wrappers (Phase 5)
- Wave executor + parallel fan-out (Phase 6)
- Resume hardening + chaos tests (Phase 6)
- Final summary aggregator (Phase 6)

</domain>

<decisions>
## Implementation Decisions

### Orchestrator skill (single-shot pipeline)
- **D-01:** Orchestrator lives at `plugins/zapili/skills/orchestrator/SKILL.md` (directory form per CLAUDE.md — supporting `references/` already created in Phase 3). The slash command `commands/zapili.md` now invokes the skill via `Skill(skill="orchestrator")` instead of printing a stub. The preflight gate remains in the command body before the skill invocation.
- **D-02:** SKILL.md frontmatter:
  - `description: "zapili end-to-end workflow: research → plan → wave-parallel implementation → review"`
  - `allowed-tools: Read, Glob, Grep, Write, Edit, Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*:*), Agent(researcher, planner)`
  - `context: fork` (skill gets its own context — `references/` files are reachable but don't pollute the main thread)
- **D-03:** SKILL.md body sections (in execution order):
  1. Bootstrap `.zapili/state.json` (or read existing for resume) — single-writer ownership held by the skill.
  2. Research stage — invoke `Agent(researcher, "...prompt...")`, parse XML envelope + JSON payload, validate against `research-questions.schema.json`.
  3. User Q&A — for each researcher question, call `AskUserQuestion` (or text fallback per `workflow.text_mode`). Consolidate into `CONTEXT.md`.
  4. Research-validate loop — `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/codex-validate-research.sh)`. On HIGH/MEDIUM findings, route back to step 3 with prior-issue anchoring. Iteration cap 3.
  5. Plan stage — invoke `Agent(planner, "...prompt...")`. Receive `PLAN.md` + optional `PHASE-XX.md` set with `<files>` blocks.
  6. Plan-validate loop — `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/codex-validate-plan.sh)`. Same loop semantics. Iteration cap 3.
  7. Halt with a "Phase 5 takes over from here" message (engineer execution lands in Phase 5).
- **D-04:** Phase 4 ships the FULL orchestrator skeleton BUT the engineer-execution + per-phase-review steps print "Phase 5 not yet implemented in this release" and exit cleanly. The skill body is structured so Phase 5 just fills in two existing steps without re-architecting.

### Researcher subagent (ZAP-20)
- **D-05:** `plugins/zapili/agents/researcher.md` frontmatter:
  - `description: "zapili researcher: read-only investigator for TASK.md; classifies size and drafts question batch"`
  - `tools: Read, Glob, Grep` (NO Write/Edit/Bash — read-only allowlist)
  - `model: inherit` (no override; respect caller's settings)
- **D-06:** Researcher prompt body specifies: load `TASK.md` + referenced files; classify per `references/task-sizing.md`; emit XML envelope with `<payload>` matching `research-questions.schema.json` (D-06 of Phase 3 CONTEXT). Forbidden vocabulary list applies. Cite line ranges for every question's `context` field.

### Planner subagent (ZAP-30, ZAP-31, ZAP-32, ZAP-33)
- **D-07:** `plugins/zapili/agents/planner.md` frontmatter:
  - `description: "zapili planner: produces PLAN.md and zero+ PHASE-XX.md from TASK.md + CONTEXT.md"`
  - `tools: Read, Glob, Grep, Write` (write needed to author plan files)
  - `model: inherit`
- **D-08:** Planner prompt body:
  - Reads `TASK.md`, `CONTEXT.md`, and the three reference docs
  - Emits `PLAN.md` (wave structure + cross-references) + `PHASE-XX.md` files (one per phase)
  - Each `PHASE-XX.md` MUST contain a mandatory `<files>{"writes":[...],"reads":[...]}</files>` block (ZAP-32)
  - Phase count bounded per task size per `references/task-sizing.md` (ZAP-31)
  - Wave grouping rationale documented; orchestrator verifies disjointness mechanically (ZAP-33, but enforcement is Phase 6)
  - Returns an XML envelope with `<payload>` summarizing what was written (paths) — not embedded contents

### Codex wrappers (ZAP-22, ZAP-34)
- **D-09:** `plugins/zapili/scripts/codex-review.sh` — generic invocation:
  ```bash
  codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config -
  ```
  Reads prompt from stdin, writes raw JSONL to `<out>.raw.jsonl`, extracts the final assistant message via `jq -s 'map(select(.type=="message" and .role=="assistant")) | last | .content // .text // .message // empty'` to `<out>`. Returns codex's exit code.
- **D-10:** `scripts/codex-validate-research.sh` — composes the review prompt for the `research_validator` role per `references/codex-prompts.md`, calls `codex-review.sh`, validates the response against `validation-findings.schema.json` (using `ajv` or python jsonschema fallback). Exits 0 if no HIGH/MEDIUM findings, 1 otherwise. Persists raw + parsed findings to `.zapili/research-validate-attempt-N.json`.
- **D-11:** `scripts/codex-validate-plan.sh` — same shape but for `plan_validator` role; persists to `.zapili/plan-validate-attempt-N.json`.
- **D-12:** All three wrappers use `set -euo pipefail`, `${CLAUDE_PLUGIN_ROOT}` discipline, LF, mode 0755.
- **D-13:** Wrappers separate stdout (final answer JSON) from stderr (codex progress logs) and propagate codex's exit code via `set -o pipefail` + explicit checks (ZAP-34 acceptance #4).

### State (ZAP-50, ZAP-51, ZAP-52)
- **D-14:** `plugins/zapili/scripts/state.sh` — sourced library exposing:
  - `state_bootstrap` — create `.zapili/state.json` with all required fields from `state.schema.json` if missing
  - `state_get <field>` — `jq -r .field .zapili/state.json`
  - `state_set <field> <value>` — temp-then-rename atomic write
  - `state_advance_stage <stage>` — sets `current_stage`, updates `updated_at`
- **D-15:** Atomic write pattern (also applied to every artifact write by the skill body via Write tool's normal semantics, which already does temp-then-rename in Claude Code): write to `.zapili/state.json.tmp`, fsync, `mv` to `.zapili/state.json`.
- **D-16:** Completion sentinel: every artifact file (`CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`) ends with the literal HTML-comment line `<!-- <status>complete</status> -->` after the temp-then-rename, so partial writes are detectable on resume.
- **D-17:** Resume rule: orchestrator first inspects artifacts on disk (presence + completion sentinels) before reading `state.json`. If they disagree, artifacts win and `state.json` is rewritten.

### Wave executor stub (Phase 5/6 prep)
- **D-18:** Phase 4 SKILL.md adds a "stage 7" placeholder section that lists what Phase 5/6 will fill in (engineer per phase, per-phase codex review, wave parallel fan-out). The placeholder is a clear, parseable comment block (`<!-- PHASE-5-STUB ... -->`).

### Plan structure
- **D-19:** Phase 4 is large (~1000+ LOC across SKILL.md body, 2 agents, 4 scripts, state lib). Two-wave structure:
  - **Wave 1 (parallel-safe):**
    - Plan 04-01 — codex wrappers (`codex-review.sh`, `codex-validate-research.sh`, `codex-validate-plan.sh`) + state.sh
    - Plan 04-02 — researcher + planner subagent definitions
  - **Wave 2 (depends on Wave 1):**
    - Plan 04-03 — orchestrator SKILL.md body + commands/zapili.md update + wired pipeline

### Claude's Discretion
- Exact prompt wording inside researcher.md and planner.md, provided D-05/D-08 contracts are met
- Whether codex-validate-research.sh and codex-validate-plan.sh share a common helper or duplicate (KISS: duplicate when ≤30 LOC each)
- Exact jq selectors for parsing codex JSONL output (D-09 baseline; subject to codex schema evolution)
- Whether the orchestrator SKILL.md uses pseudocode or natural-language stages (natural language with explicit "Tool to call: ..." annotations preferred for v1)

</decisions>

<canonical_refs>
- `.planning/REQUIREMENTS.md` — ZAP-20..24, ZAP-30..35, ZAP-50..52
- `.planning/ROADMAP.md` § "Phase 4"
- Phase 3 outputs: `plugins/zapili/schemas/*.schema.json`, `plugins/zapili/skills/orchestrator/references/*.md`, `plugins/zapili/tests/fixtures/`
- `CLAUDE.md` § "Plugin Components Used by zapili", § "Codex invocation pattern", § "What NOT to Use"
- OpenAI codex CLI noninteractive reference

</canonical_refs>

<code_context>
- `plugins/zapili/commands/zapili.md` (Phase 2): preflight gate + stub body. Phase 4 keeps the preflight, replaces the stub with `Skill(skill="orchestrator")` invocation.
- `plugins/zapili/scripts/preflight-codex.sh`, `check-codex.sh` (Phase 2): shell-hygiene reference.
- `plugins/zapili/skills/orchestrator/references/` (Phase 3): contracts, sizing, codex-prompts — referenced by SKILL.md body.
- `plugins/zapili/schemas/` (Phase 3): payload contracts.
- `plugins/zapili/tests/fixtures/` (Phase 3): codex calibration corpus — Phase 4 SKILL.md links to it but does NOT run them inline (calibration is dev-time).

</code_context>

<specifics>
- The skill is intentionally THE workflow logic (not a separate orchestrator binary). Claude Code executes the skill body the same way it executes a slash command body — by interpreting the Markdown as agent instructions.
- Plugin subagents (researcher, planner) cannot use hooks/mcpServers/permissionMode (Claude Code security restriction); they only need tools.
- The `Agent(researcher, planner)` whitelist in SKILL.md frontmatter is required so the skill can dispatch them.

</specifics>

<deferred>
- Engineer execution (Phase 5)
- Per-phase review fix loop (Phase 5)
- Wave parallel fan-out + disjointness verification (Phase 6)
- Resume chaos tests (Phase 6)
- Final summary aggregator (Phase 6)
- Live calibration run against Phase 3 fixtures (defer to Phase 6 polish or v1.1)

</deferred>
