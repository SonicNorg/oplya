# Phase 8: Codex self-fix fallback after iteration cap - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution

<domain>
When the codex review fix-loop (Stage 4 `plan_validate` or Stage 6 `phase_review`) hits its iteration cap (default 4) with at least one persistent HIGH finding, do NOT halt the workflow. Instead, dispatch a fourth `codex` role — `fixer` — whose entire job is to MODIFY the offending artifact (PHASE-XX.md, PLAN.md, or CONTEXT.md) to address every persistent HIGH finding, then re-run the original validator. The fixer's contract is a unified-diff patch wrapped in `<response><patch>...</patch></response>`. The orchestrator dry-runs the patch via `git apply --check`, persists it under `.zapili/codex-self-fix-attempt-N.patch`, then applies via `git apply` and re-runs the validator.

**In scope:**
- New script `plugins/zapili/scripts/codex-self-fix.sh <artifact> <validator_role> <prior_findings_json>` + `--dry-run` flag.
- Orchestrator Stage 4 (plan-validate) and Stage 6 (per-phase review) gain fix-loop cap detection + codex-self-fix dispatch + post-fix re-validate.
- `references/codex-prompts.md` documents the `fixer` role as a fourth role with its own category-free contract (the fixer ingests prior findings; it does not emit findings).
- New fixture `tests/fixtures/f6-fix-loop-exhausted/` reproduces an engineer-stuck → codex-self-fix-resolves scenario for the integration acceptance test.
- Live calibration of `codex-self-fix.sh` end-to-end against codex-cli 0.133.0 (the env confirmed working in Phase 7's calibration; transcript persisted under the f6 fixture).

**Out of scope:**
- Replacing the engineer/planner with codex (codex is only the LAST-RESORT fixer; engineer/planner remain the primary implementers).
- New validator roles beyond `fixer`.
- Multi-artifact patches (one self-fix invocation = one artifact).
- Auto-application of patches without `git apply --check` dry-run (always dry-run first per CALIB-04).
</domain>

<decisions>
### Fixer role + prompt contract (ZAP-60 acceptance #4)
- **D-01:** Add `fixer` as the fourth role in `references/codex-prompts.md` after `phase_reviewer`. The fixer prompt structure differs from the three validators:
  - `<role>fixer</role>` header.
  - `<inputs>` block lists exactly one artifact (the file to fix) and the prior-findings file path.
  - NO `<categories>` block (the fixer is single-purpose, not exhaustive).
  - `<task>` block instructs codex to address every HIGH finding by `ISS-...` id (citing each id in the patch's diff hunk-header comment line if the diff format allows) and emit ONLY a unified-diff patch.
  - `<output_contract>` requires the response shape `<response><patch>...</patch></response>` and nothing else. The patch MUST be a valid unified diff applicable from the repo root via `git apply` (i.e. starts with `--- a/<path>` and `+++ b/<path>` lines).
- **D-02:** SHA-256 ID derivation rule (CALIB-01) applies to the fixer the same way it applies to validators: when the fixer cites prior IDs in its prose comments inside the patch, those IDs MUST be the verbatim `ISS-...` values from the prior-findings file (the fixer never invents new IDs).
- **D-03:** When the patch is empty (codex couldn't produce a diff — typically because the prior findings are mis-scoped or the artifact is structurally unfixable), the orchestrator halts with the diagnostic `## CODEX SELF-FIX EXHAUSTED — no diff produced`.

### codex-self-fix.sh wrapper (ZAP-60 acceptance #1 + #3)
- **D-04:** Signature: `codex-self-fix.sh [--dry-run] <artifact_path> <validator_role> <prior_findings_json>`. Optional `--dry-run` flag is the FIRST argument when present; otherwise the script behaves as if dry-run-first then apply. The orchestrator ALWAYS dry-runs first (writes `.zapili/codex-self-fix-attempt-N.patch`), inspects the patch, then issues a second invocation without `--dry-run` to actually apply.
- **D-05:** The wrapper composes the fixer prompt by interpolating the artifact verbatim + the HIGH (and MEDIUM) findings list (filtered from `prior_findings_json` via `jq`), invokes `codex-review.sh` to talk to codex, extracts the `<patch>...</patch>` block via `perl -0777` (same pattern as `<payload>` extraction in the validators), writes the patch to `.zapili/codex-self-fix-attempt-N.patch`.
- **D-06:** Attempt counter N is auto-derived from existing `.zapili/codex-self-fix-attempt-*.patch` files (analogous to validator attempt counters).
- **D-07:** Apply path: `git apply --check <patch>` must succeed before `git apply <patch>`; if `--check` fails, exit 4 with a diagnostic naming the offending patch file and the underlying `git apply --check` stderr.
- **D-08:** Exit codes:
  - `0` — patch generated, dry-run successful (when `--dry-run`); OR patch generated, dry-run + apply both successful (no `--dry-run`).
  - `1` — codex emitted an empty patch (handled by orchestrator as "exhausted").
  - `2` — codex invocation failed (codex-review.sh non-zero).
  - `4` — `git apply --check` rejected the patch (malformed diff or context mismatch).
  - `64` — usage error.

### Orchestrator integration — Stage 4 + Stage 6 (ZAP-60 acceptance #2)
- **D-09:** `.zapili/state.json` gains optional `fix_loop_cap` field (integer, default 4). Both Stage 4 (plan-validate) and Stage 6 (phase-review) read this via `state_get '.fix_loop_cap // 4'`.
- **D-10:** SKILL.md Stage 6 (plan-validate loop) gets a new sub-step inserted AFTER its current iteration-cap diagnostic and BEFORE the `STOP` line: on cap-hit with HIGH findings persistent, the orchestrator (a) extracts the most-recent attempt's findings, (b) invokes `codex-self-fix.sh --dry-run PLAN.md plan_validator .zapili/plan-validate-attempt-N.json`, (c) persists the dry-run patch, (d) invokes `codex-self-fix.sh` (no `--dry-run`) to apply, (e) re-runs `codex-validate-plan.sh` on the patched artifact, (f) on clean re-validate → continue workflow; on still-HIGH → STOP with `## CODEX SELF-FIX EXHAUSTED`.
- **D-11:** SKILL.md Stage 7c (per-wave fix loop) gets the analogous insertion: on per-phase N reaching the cap, instead of halting the whole wave the orchestrator dispatches `codex-self-fix.sh --dry-run PHASE-XX.md phase_reviewer .zapili/phase-XX-review-attempt-N.json` against the phase artifact (NOT the engineer's output — the fixer revises the spec/plan, not the implementation, since the engineer has already tried 4 times against the current spec). Then re-runs `codex-review-phase.sh`. Termination paths identical to D-10.
- **D-12:** Self-fix is per-cap-hit, NOT iterative. One self-fix attempt per validator cap-hit. If the post-fix re-validate still has HIGH findings, the workflow halts (the fixer doesn't get a second turn on the same artifact in the same run — re-running `/zapili:zapili` resets the counter, giving the human a chance to inspect first).

### f6 fixture — integration acceptance test (ZAP-60 acceptance #5)
- **D-13:** Create `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/`. Contents:
  - `TASK.md` — short task description.
  - `PLAN.md` — minimal plan with a single Wave 1 / single PHASE-XX.
  - `PHASE-XX.md` — phase plan that DELIBERATELY omits a required test task (mirrors f4's seeded `missing-tasks` finding).
  - `engineer-payload.json` — 4 attempts' worth of engineer output, each missing the same test task (simulates engineer ceiling).
  - `prior-findings.json` — codex-style findings payload listing one HIGH `missing-tasks` finding (the `ISS-...` id deterministically derived per CALIB-01).
  - `README.md` — describes the seeded scenario + the expected outcome (after `codex-self-fix.sh` runs, the patched PHASE-XX.md gains the missing test task).
- **D-14:** Live-codex acceptance run: invoke `codex-self-fix.sh --dry-run f6/PHASE-XX.md phase_reviewer f6/prior-findings.json` against real codex-cli 0.133.0. Expected outcomes:
  - Codex emits a non-empty patch.
  - `git apply --check` succeeds (NOTE: f6 is inside the repo, so the patch must be applied via `git apply --directory=plugins/zapili/tests/fixtures/f6-fix-loop-exhausted` if needed; alternative is to copy the fixture to a tmpdir for the live run).
  - Re-running `codex-review-phase.sh` on the patched artifact reports no HIGH findings on the seeded `missing-tasks` category.
- **D-15:** If the live run fails (codex can't produce a clean diff against the synthetic example), document the failure mode in the f6 README and adjust the script's halt-on-empty-patch path so the integration test is "the self-fix dispatch completes and either applies a patch or halts cleanly" — i.e. the value-add is that the script exits with a meaningful code, not necessarily that codex always solves the problem.

### Plan structure
- **D-16:** Phase 8 has 3 plans, organized as 2 waves:
  - **Wave 1 (parallel-safe):**
    - Plan 08-01 — codex-self-fix.sh + fixer-prompt documentation (`scripts/codex-self-fix.sh` + `skills/orchestrator/references/codex-prompts.md` fixer-role section). Independent file edits.
    - Plan 08-02 — f6 fixture (`tests/fixtures/f6-fix-loop-exhausted/*`). Pure additions.
  - **Wave 2 (depends on Wave 1):**
    - Plan 08-03 — SKILL.md Stage 6 + Stage 7c integration (`skills/orchestrator/SKILL.md`) + live calibration log against the f6 fixture (`.planning/phases/08-codex-self-fix-fallback/live-codex-calibration-LOG.md`). Depends on Wave 1's script + fixture.

</decisions>

<canonical_refs>
- REQUIREMENTS § ZAP-60 (line 251)
- ROADMAP § Phase 8 (lines 225–238) — success criteria 1..5
- Phase 7 SUMMARY of planner prior-findings contract (same shape applies to fixer)
- `plugins/zapili/scripts/codex-review.sh` — JSONL parse path the fixer reuses
- `plugins/zapili/scripts/codex-review-phase.sh` — pattern for prompt composition + prior-findings interpolation
- `plugins/zapili/skills/orchestrator/references/codex-prompts.md` — three existing roles; fixer is appended as the fourth
- v1.0 audit `.planning/v1.0-MILESTONE-AUDIT.md` — calibration philosophy (live transcript persistence)
</canonical_refs>

<code_context>
- `plugins/zapili/scripts/codex-review.sh` (raw wrapper): handles JSONL → final-message extraction. `codex-self-fix.sh` composes the prompt + calls this wrapper.
- `plugins/zapili/scripts/codex-review-phase.sh` lines 47–55: PRIOR_BLOCK composition pattern — fixer uses the same `jq -r '.findings[]'` shape but emits a richer block (full remediation text, not just id+severity).
- `plugins/zapili/skills/orchestrator/SKILL.md` Stage 6 (lines 226–246) + Stage 7c (lines 304+): target insertion sites.
- `plugins/zapili/scripts/state.sh`: `state_get`, `state_set` helpers (read `fix_loop_cap`).
- `git apply --check` is the cheap pre-flight; codex output that fails `git apply --check` is treated as a malformed patch, not a half-application.
</code_context>

<!-- <status>complete</status> -->
