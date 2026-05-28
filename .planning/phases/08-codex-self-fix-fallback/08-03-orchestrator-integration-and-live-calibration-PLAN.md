---
phase: 08-codex-self-fix-fallback
plan: 03
type: execute
wave: 2
depends_on: [08-01, 08-02]
files_modified:
  - plugins/zapili/skills/orchestrator/SKILL.md
  - .planning/phases/08-codex-self-fix-fallback/live-codex-calibration-LOG.md
autonomous: true
requirements: [ZAP-60]
must_haves:
  truths:
    - "SKILL.md Stage 6 (plan-validate cap-hit) gains an inserted sub-step that dispatches codex-self-fix.sh --dry-run, persists patch, applies, re-runs codex-validate-plan.sh; halts only if post-fix re-validate has HIGH or codex emitted empty patch"
    - "SKILL.md Stage 7c (per-wave fix loop cap-hit) gains the analogous sub-step against the PHASE-XX.md spec artifact (not engineer output)"
    - "fix_loop_cap read via state_get '.fix_loop_cap // 4'"
    - "Halt diagnostic shape: '## CODEX SELF-FIX EXHAUSTED' with finding IDs + patch path"
    - "live-codex-calibration-LOG.md documents the f6 round-trip: command, raw codex output excerpt, dry-run patch content, git apply --check result, post-fix re-validate result"
    - "If live codex round-trip fails (empty patch / malformed diff / re-review still HIGH), the LOG documents the failure mode and the orchestrator's halt path explicitly — counts as a passing acceptance for the script's halt contract"
    - "D-NN decisions cited: D-09, D-10, D-11, D-12 (orchestrator), D-14, D-15 (live calibration)"
---
<objective>Wire codex-self-fix into the orchestrator (Stage 6 + Stage 7c) and prove the round-trip works (or fails cleanly) against live codex-cli 0.133.0.</objective>
<context>
@.planning/phases/08-codex-self-fix-fallback/08-CONTEXT.md
@plugins/zapili/skills/orchestrator/SKILL.md
@plugins/zapili/scripts/codex-self-fix.sh
@plugins/zapili/tests/fixtures/f6-fix-loop-exhausted
</context>
<tasks>
<task type="auto"><name>Task 1: SKILL.md Stage 6 cap-hit codex-self-fix dispatch</name>
<action>Edit `plugins/zapili/skills/orchestrator/SKILL.md`. In Stage 6 (Plan-validate loop), AFTER the current `If N reaches 4, STOP with the analogous diagnostic.` line and BEFORE `state_advance_stage "wave_execute"`, insert a sub-section "### 6.1. Cap-hit codex-self-fix fallback (ZAP-60)" that:
- Reads `cap=$(state_get '.fix_loop_cap // 4')`.
- On cap-hit detection (when iteration N would exceed cap and the latest attempt's findings file has HIGH), instead of halting:
  - `bash codex-self-fix.sh --dry-run PLAN.md plan_validator .zapili/plan-validate-attempt-$((N-1)).json` → patch persisted to `.zapili/codex-self-fix-attempt-1.patch`.
  - Inspect patch (jq-extract or stat). If empty → halt with `## CODEX SELF-FIX EXHAUSTED — no diff produced`.
  - Else `bash codex-self-fix.sh PLAN.md plan_validator .zapili/plan-validate-attempt-$((N-1)).json` (apply mode).
  - Re-run `codex-validate-plan.sh PLAN.md 'PHASE-*.md'`. If clean → proceed to wave_execute. If still HIGH → halt with `## CODEX SELF-FIX EXHAUSTED` listing unresolved finding IDs and the patch path.
- One self-fix attempt per cap-hit (no recursion).</action>
<acceptance_criteria>grep -q 'codex-self-fix' plugins/zapili/skills/orchestrator/SKILL.md; the inserted block appears between Stage 6's STOP line and Stage 7 boundary; bash -n applies (Stage 6 is mostly prose, so syntactic validation is grep-based).</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: SKILL.md Stage 7c cap-hit codex-self-fix dispatch</name>
<action>Edit `plugins/zapili/skills/orchestrator/SKILL.md`. In Stage 7c (per-wave fix loop), find the "If any phase's N reaches 4 — STOP the entire wave with: ..." block and AFTER its diagnostic example, insert a sub-section "#### 7c.1. Cap-hit codex-self-fix fallback (ZAP-60)" with analogous semantics to 6.1 but targeting the offending PHASE-XX.md (NOT the engineer-payload — per D-11, the fixer revises the spec to unblock the engineer). After patch apply, re-run codex-review-phase.sh for that one phase; on clean → mark converged; on still-HIGH → halt the wave with the structured diagnostic.</action>
<acceptance_criteria>second 'codex-self-fix' occurrence inside Stage 7c; the diagnostic vocabulary matches Stage 6.1 (## CODEX SELF-FIX EXHAUSTED).</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: Live-codex round-trip against f6 fixture</name>
<action>Execute the f6 fixture round-trip end-to-end against live codex-cli 0.133.0:
1. `cd plugins/zapili/tests/fixtures/f6-fix-loop-exhausted`
2. `bash ../../../scripts/codex-self-fix.sh --dry-run PHASE-XX.md phase_reviewer prior-findings.json` (dry-run; persists the dry-run patch under that fixture's `.zapili/`)
3. Inspect the patch: empty? malformed? plausible?
4. If non-empty and valid: copy fixture to a tmpdir, apply the patch there, re-run `codex-review-phase.sh TASK.md PHASE-XX.md engineer-payload.json` against the patched copy, capture the result.
5. If empty/malformed: document the failure mode.
6. Persist EVERY artifact (prompt, raw codex JSONL, patch, post-fix re-review output) under `.planning/phases/08-codex-self-fix-fallback/live-codex-calibration-LOG.md` — full transcript embedded as fenced code blocks.
The LOG itself is part of this plan's output regardless of round-trip outcome. The PASS criterion is "round-trip executed; outcome documented; if codex couldn't solve the problem, the script's halt path produced a clean exit code".</action>
<acceptance_criteria>live-codex-calibration-LOG.md exists; contains a "Round-trip outcome" section; contains the raw codex output excerpt; documents exit code of every wrapper invocation.</acceptance_criteria>
</task>
</tasks>
<output>Create 08-03-orchestrator-integration-and-live-calibration-SUMMARY.md.</output>
