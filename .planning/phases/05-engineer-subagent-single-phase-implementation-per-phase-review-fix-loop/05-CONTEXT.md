# Phase 5: Engineer subagent + single-phase implementation + per-phase review + fix loop - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution

<domain>
A single phase round-trips cleanly end-to-end:
1. Engineer subagent reads its `PHASE-XX.md` + scoped CONTEXT excerpt → edits source files → returns schema-valid `phase-changes` payload.
2. Codex per-phase review runs against TASK + phase plan + engineer's change list.
3. Per-phase fix loop routes findings back to a fresh engineer spawn with the prior attempt's reasoning trace artifact (`PHASE-XX-attempt-N.md`).
4. Convergence within iteration cap ≤3.

**In scope:**
- `plugins/zapili/agents/engineer.md` (ZAP-40)
- `plugins/zapili/scripts/codex-review-phase.sh` (per-phase review wrapper; ZAP-43)
- `plugins/zapili/skills/orchestrator/SKILL.md` Stage 7 — fill in the single-phase round-trip path
  - Per-phase attempt artifact (`PHASE-XX-attempt-N.md`) write contract (ZAP-44, ZAP-45)
  - Fix loop with iteration cap ≤3
- Update `plugins/zapili/skills/orchestrator/SKILL.md` `allowed-tools` to add `Agent(engineer)` and the new Bash invocation
- Provide a documented reference small-task `TASK.md` smoke-test scenario in `plugins/zapili/tests/fixtures/smoke-small-task/`

**Out of scope (Phase 6):**
- Parallel wave fan-out + pairwise disjointness verification
- Per-wave fix-loop convergence orchestration across multiple phases
- Final summary aggregator
- Resume hardening + chaos tests

</domain>

<decisions>
### Engineer subagent (ZAP-40)
- **D-01:** `plugins/zapili/agents/engineer.md` frontmatter:
  - `name: engineer`
  - `description: "zapili engineer — implements one phase per spawn; receives TASK.md + scoped CONTEXT excerpt + PHASE-XX.md + optional prior attempt; returns phase-changes payload."`
  - `tools: Read, Glob, Grep, Edit, Write, Bash` — engineer needs to run language-specific verification commands (test runners, formatters) so Bash is allowed. Constrained per-task by the phase plan's `<files>` block (engineer MUST NOT write outside listed paths).
- **D-02:** Engineer prompt body specifies: read inputs in order (TASK.md → CONTEXT excerpt → PHASE-XX.md → optional prior PHASE-XX-attempt-(N-1).md); implement; emit XML envelope with `<payload>` matching `phase-changes.schema.json`; cite all `<files>` writes/reads; do NOT touch state.json or other phases' files.

### Per-phase review wrapper (ZAP-43)
- **D-03:** `plugins/zapili/scripts/codex-review-phase.sh` — same shape as Phase-4 wrappers. Args: `<task_md> <phase_xx_md> <engineer_payload_json> [prior_findings_json]`. Composes `phase_reviewer` prompt per `references/codex-prompts.md`. Persists to `.zapili/phase-XX-review-attempt-N.json`. Same exit-code semantics as `codex-validate-plan.sh` (0 = clean, 1 = HIGH/MEDIUM present, 2 = codex failed, 3 = schema invalid, 5 = no validator).

### Attempt artifact (ZAP-44, ZAP-45)
- **D-04:** After each engineer spawn, the orchestrator writes `PHASE-XX-attempt-N.md` (numbered ascending starting at 1) in the user's CWD next to PHASE-XX.md. Content: the engineer's full XML envelope (reasoning + payload) plus a header showing the inputs the engineer received and the attempt number. Ends with completion sentinel.
- **D-05:** On a fix iteration, the orchestrator dispatches a FRESH `Agent(engineer, ...)` with these inputs:
  - TASK.md + scoped CONTEXT + PHASE-XX.md (unchanged)
  - The PRIOR attempt artifact (`PHASE-XX-attempt-(N-1).md`) — labeled `<prior_attempt>`
  - The codex review findings from the prior pass (`<prior_findings>` block, matching `validation-findings.schema.json`)
- **D-06:** Per-phase iteration cap = 3. On cap reach, halt with diagnostic referencing the latest review file and attempt artifact.

### Orchestrator SKILL.md update
- **D-07:** Replace Stage 7 PHASE-5-STUB block with a working single-phase implementation that handles exactly ONE phase per wave (sequential). Multi-phase parallel wave handling is the Phase 6 substitution.
- **D-08:** Extend `allowed-tools` to include `Agent(researcher, planner, engineer)`. No other frontmatter changes.

### Smoke-test fixture
- **D-09:** `plugins/zapili/tests/fixtures/smoke-small-task/` contains a small `TASK.md` (≤100 LOC class) for documenting the manual smoke test of the full single-phase pipeline. No automation, no codex run inline — just the fixture and a README explaining the manual procedure.

### Plan structure
- **D-10:** Phase 5 is medium (~400 LOC across engineer prompt + review wrapper + SKILL.md Stage 7 update + smoke fixture).
  - **Wave 1 (parallel-safe):** Plan 05-01 (engineer.md + codex-review-phase.sh) and Plan 05-02 (smoke fixture)
  - **Wave 2 (depends on Wave 1):** Plan 05-03 (SKILL.md Stage 7 wiring)

</decisions>

<canonical_refs>
- REQUIREMENTS ZAP-40, ZAP-43, ZAP-44, ZAP-45
- ROADMAP § "Phase 5"
- `plugins/zapili/schemas/phase-changes.schema.json`, `validation-findings.schema.json`
- `plugins/zapili/skills/orchestrator/references/codex-prompts.md` § "phase_reviewer"
- `plugins/zapili/skills/orchestrator/SKILL.md` (Phase 4 — Stage 7 PHASE-5-STUB)
- Phase 4 `agents/researcher.md` + `agents/planner.md` (template style)
- Phase 4 `scripts/codex-validate-plan.sh` (wrapper template)

</canonical_refs>

<code_context>
- Engineer subagent uses Edit/Write/Bash — broadest tools allowlist of any subagent. Compensating control: the engineer prompt constrains writes to the phase's `<files>.writes` list mechanically; the orchestrator post-verifies after the engineer returns.
- Per-phase review wrapper mirrors `codex-validate-plan.sh` structure; deduplication via a shared `lib.sh` is deferred (KISS — only 3 wrappers exist).
- SKILL.md Stage 7 PHASE-5-STUB was authored with substitution in mind — the comment block becomes a code-style section.
</code_context>

<specifics>
- `Agent(engineer)` requires the `name: engineer` matches Claude Code's subagent dispatch convention.
- Fix-loop artifact pattern: prior attempts are RAW inputs to the next attempt — never edited or summarized by the orchestrator.
- `<files>.writes` enforcement: orchestrator runs `git diff --name-only HEAD` after engineer returns; any file outside the declared `writes` list triggers a HIGH finding inserted into the review's prior_findings (Phase 6 makes this mechanical; Phase 5 documents the rule and runs the diff but does not yet auto-route).

</specifics>

<deferred>
- Mechanical `<files>.writes` enforcement that auto-rolls-back violations (Phase 6)
- Per-wave fix-loop convergence (Phase 6)
- Parallel engineer fan-out (Phase 6)

</deferred>
