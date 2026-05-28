# Phase 7: Review follow-ups cleanup - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution

<domain>
Close the five non-blocking follow-ups surfaced by the v1.0.0 ultra-principal code review. None blocks end-to-end execution today, but together they (a) make the planner's fix-iteration contract symmetric with the engineer's, (b) prevent silent loss of planner-flagged gaps, (c) bring fixture coverage to 5/5 runnable end-to-end, and (d) restore hook-script discipline and regex generality the v1.0 audit flagged.

**In scope:**
- Planner agent: optional `<file role="prior-findings">` input + matching `<task>` instruction (mirrors `engineer.md`)
- Orchestrator Stage 5: parse `flagged_gaps` from planner payload, route each to user via `AskUserQuestion`, append to `CONTEXT.md ## Gap Resolutions`
- Fixtures: rewrite `tests/fixtures/README.md` calibration loop to use real per-role wrapper signatures; add minimal `f3/PLAN.md`, `f4/TASK.md`, `f5/TASK.md`
- `check-codex.sh`: `set -uo pipefail` → `set -euo pipefail` (advisory contract preserved via `|| true` and `if !` guards already in place)
- `check-wave-disjointness.sh`: broaden phase-id regex to match `PHASE-XX-a` fixture naming

**Out of scope:**
- Anything from Phase 8 (codex self-fix fallback)
- Sibling plugins / new features
- Manual chaos rehearsals (already stamped in Phase 6)
</domain>

<decisions>
### Planner prior-findings contract (ZAP-55 / C-03)
- **D-01:** Add `<file role="prior-findings" optional="true">codex review findings from the prior planner attempt (only on fix iterations)</file>` to planner.md `<inputs>` block — verbatim shape mirrors engineer.md line 14.
- **D-02:** Extend planner.md `<task>` with a new numbered step (between current 1 and 2): "On a fix iteration, the prior-findings JSON is your ground truth — address every HIGH/MEDIUM finding by ID, cite each addressed ID in this revision's `flagged_gaps` entry (use `topic: "fix:ISS-..."` form for traceability), and never remove phases to hide gaps." Renumber subsequent steps.
- **D-03:** No schema change needed — `flagged_gaps[].topic` is already free-form string in `planner-output.schema.json` (confirmed by reading current planner payload contract in agents/planner.md output_contract).

### Orchestrator flagged_gaps routing (ZAP-56 / C-04)
- **D-04:** SKILL.md Stage 5 gains a new sub-step (Step 5.5) AFTER planner artifact verification and BEFORE `state_advance_stage "plan_validate"`:
  1. Parse `flagged_gaps` from the planner's payload JSON (already persisted parsing exists elsewhere; here we keep it inline via `jq`).
  2. If non-empty: for each `{topic, context}` entry, call `AskUserQuestion` with `question = "Planner flagged gap: <topic>. Context: <context>. Please clarify."`, accept free-form input as the answer.
  3. Append a new section to `CONTEXT.md` of the form:

     ```markdown
     ## Gap Resolutions

     **GAP-1 (<topic>):** <user answer>
     **GAP-2 (<topic>):** <user answer>
     ...
     ```

     Numbering restarts at 1 per planner attempt (multiple iterations append new sections; Stage 0 resume reads the latest).
- **D-05:** Section heading is plain Markdown `## Gap Resolutions` (NOT an XML block) — keeps CONTEXT.md human-readable and matches Phase 4's `<decisions>` siblings convention (those use XML, but the orchestrator Stage 3 skeleton already mixes XML blocks with plain Markdown headers — `Gap Resolutions` is a new top-level section, not a child of `<decisions>`).
- **D-06:** Empty `flagged_gaps` array → silent continue (no section appended, no user prompt). The mere presence of `## Gap Resolutions` in CONTEXT.md becomes the resume signal that gaps were resolved on a prior run.

### Fixtures completion (ZAP-57 / F-01, F-02)
- **D-07:** Rewrite `tests/fixtures/README.md` § "How Phase 4+ uses these" to invoke the actual wrappers:
  - `f1-research-contradiction` → `bash plugins/zapili/scripts/codex-validate-research.sh <fixture>/TASK.md <fixture>/CONTEXT.md`
  - `f2-plan-write-overlap`, `f3-plan-ambiguity` → `bash plugins/zapili/scripts/codex-validate-plan.sh <fixture>/PLAN.md '<fixture>/PHASE-*.md'`
  - `f4-phase-missing-tests`, `f5-phase-style-drift` → `bash plugins/zapili/scripts/codex-review-phase.sh <fixture>/TASK.md <fixture>/PHASE-XX.md <fixture>/engineer-payload.json`
  - Loop persists `.zapili/<role>-attempt-N.json`; expected IDs come from `expected-findings.json`; pass = every expected ID present in actual output.
- **D-08:** `f3-plan-ambiguity/PLAN.md` content: minimal 12-line markdown — "Wave 1: PHASE-XX" + reference to the existing PHASE-XX.md + the seeded ambiguity sentence repeated in the goal. Ends with completion sentinel. Allows `codex-validate-plan.sh` to consume the fixture.
- **D-09:** `f4-phase-missing-tests/TASK.md` content: minimal task description that justifies the phase's "missing tests" gap (e.g. "Implement a hash-table cache with unit tests covering insertion, eviction, and overflow" — phase's PHASE-XX.md says only "implement cache" with no test task → triggers the seeded `missing-tasks` finding).
- **D-10:** `f5-phase-style-drift/TASK.md` content: minimal task description ("Add a public REST endpoint for user-profile updates") that makes the seeded `code-quality` finding (style drift in the engineer payload) interpretable to the reviewer.

### check-codex.sh hygiene (ZAP-58 / H-01)
- **D-11:** Change `set -uo pipefail` (line 2) → `set -euo pipefail`. The existing guards (`cat >/dev/null 2>&1 || true` line 8; `if ! command -v codex ...; then ... exit 0; fi` lines 21–24; `if ! codex --version ...; then ... exit 0; fi` lines 26–29) are all `-e`-safe by construction. The final `exit 0` on line 32 also unchanged. Net behavior: identical advisory contract (never blocks Claude Code on missing codex) but undefined behavior on a future bug (unguarded failing command) now fails loud instead of silently continuing.

### check-wave-disjointness.sh regex (ZAP-59 / S-01)
- **D-12:** Change regex on line 44 from `PHASE-[0-9]+(-[0-9]+)?` to `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?` — accepts `PHASE-01`, `PHASE-01-02`, `PHASE-XX`, `PHASE-XX-a`, `PHASE-XX-b`. The character class broadening is the minimal change; the existing capture-group structure is preserved.
- **D-13:** No change needed to `phase_writes()` PHASE filename lookup (line 64: `"$PROJECT_ROOT/$pid.md"`) — it just appends `.md` to whatever id was matched, so `PHASE-XX-a.md` resolves correctly the moment the regex starts capturing the suffix.

### Plan structure
- **D-14:** Phase 7 has 3 plans, all parallel-safe (Wave 1 only) because the file-modification sets are pairwise disjoint:
  - **Plan 07-01 — agents + orchestrator** (touches `plugins/zapili/agents/planner.md` + `plugins/zapili/skills/orchestrator/SKILL.md`) — covers D-01..D-06 / ZAP-55, ZAP-56
  - **Plan 07-02 — fixtures completion** (touches `plugins/zapili/tests/fixtures/README.md`, `f3-plan-ambiguity/PLAN.md`, `f4-phase-missing-tests/TASK.md`, `f5-phase-style-drift/TASK.md`) — covers D-07..D-10 / ZAP-57
  - **Plan 07-03 — shell hygiene** (touches `plugins/zapili/scripts/check-codex.sh` + `plugins/zapili/scripts/check-wave-disjointness.sh`) — covers D-11..D-13 / ZAP-58, ZAP-59

</decisions>

<canonical_refs>
- REQUIREMENTS § ZAP-55..59 (lines 243–247)
- ROADMAP § Phase 7 (lines 210–223) — success criteria 1..5
- v1.0 audit (`.planning/v1.0-MILESTONE-AUDIT.md`) — review findings C-03, C-04, F-01, F-02, H-01, S-01
- Phase 5 SKILL.md Stage 5 (planner dispatch) — patched here at Step 5.5
- Phase 5 engineer.md inputs/task — pattern for planner.md prior-findings shape
- Phase 4 codex-validate-research.sh / codex-validate-plan.sh / codex-review-phase.sh signatures
</canonical_refs>

<code_context>
- `plugins/zapili/agents/engineer.md` — reference pattern for `prior-findings` `<inputs>` + `<task>` instruction (lines 14, 21).
- `plugins/zapili/agents/planner.md` — target file; existing payload shape already supports `flagged_gaps[]` (line 51).
- `plugins/zapili/skills/orchestrator/SKILL.md` Stage 5 (lines 171–189) — target insertion site for Step 5.5.
- `plugins/zapili/tests/fixtures/README.md` § "How Phase 4+ uses these" (lines 23–38) — target rewrite zone for D-07.
- `plugins/zapili/scripts/check-codex.sh` line 2 — single-character edit for D-11.
- `plugins/zapili/scripts/check-wave-disjointness.sh` line 44 — single-line regex edit for D-12.
</code_context>

<!-- <status>complete</status> -->
