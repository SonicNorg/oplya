# Roadmap: oplya (Claude Code Plugin Marketplace + zapili)

**Created:** 2026-05-27
**Granularity:** standard
**Mode:** Horizontal Layers (technical phases, not user-facing vertical slices)
**Coverage:** 43/43 v1 requirements mapped (100%)

## Vision

A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts. v1 ships the `oplya` public marketplace + the `zapili` seed plugin.

## Phases

- [x] **Phase 1: Marketplace + plugin skeleton** — Installable repo layout with valid manifests, READMEs, LICENSE, .gitignore, .gitattributes, JSON validators (completed 2026-05-28)
- [x] **Phase 2: Plugin packaging — SessionStart hook + slash command shell** — Advisory codex pre-flight + strict command-side check, LF-safe Bash scripts, `${CLAUDE_PLUGIN_ROOT}` discipline (completed 2026-05-28)
- [x] **Phase 3: Inter-agent contracts — JSON Schemas + contract reference docs** — Schemas for every machine-parseable payload, XML envelope spec, task-sizing thresholds, exhaustive-review prompt scaffold + calibration corpus (completed 2026-05-28)
- [x] **Phase 4: Orchestrator skill + research + plan + their codex validations** — Linear single-shot pipeline (research → research-validate → plan → plan-validate) with iteration caps, prior-issue anchoring, artifact-as-truth state model (completed 2026-05-28)
- [x] **Phase 5: Engineer subagent + single-phase implementation + per-phase review + fix loop** — Stress-test the per-phase round-trip and artifact-based continuity before introducing parallelism (completed 2026-05-28)
- [x] **Phase 6: Wave executor + final summary + resume hardening + publication polish** — Lift the single-phase path into wave-parallel execution with mechanical write-scope disjointness, ship-ready polish (completed 2026-05-28)
- [ ] **Phase 7: Review follow-ups cleanup** — Close five non-blocking follow-ups from v1.0.0 ultra-principal review: planner prior-findings contract (C-03), flagged_gaps routing (C-04), fixture completion f3/f4/f5 (F-01/F-02), check-codex.sh hygiene (H-01), check-wave-disjointness regex (S-01)
- [ ] **Phase 8: Codex self-fix fallback after iteration cap** — When the codex review fix-loop exhausts its iteration cap with persistent HIGH findings, dispatch a fixer-role codex pass that emits a unified-diff patch against the offending artifact; re-run the validator on the patched artifact; halt only if post-fix review still has HIGH

## Phase Details

### Phase 1: Marketplace + plugin skeleton

**Goal**: A fresh clone of `oplya` installs end-to-end via `/plugin marketplace add` + `/plugin install zapili@oplya`, with valid manifests, hygiene files, and a local pre-commit JSON validator.
**Depends on**: Nothing (foundation phase)
**Requirements**: MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, MKT-06, MKT-07, MKT-08, ZAP-03
**Success Criteria** (what must be TRUE):

  1. After `git clone` + `/plugin marketplace add <oplya-repo>`, the marketplace is recognized with zero validation errors.
  2. `/plugin install zapili@oplya` resolves successfully and makes the `zapili` plugin entry visible to Claude Code (slash command surface deferred to Phase 2).
  3. Top-level `README.md` and `plugins/zapili/README.md` (English) describe the marketplace, install instructions, and prerequisites — including the `codex` CLI dependency callout.
  4. `scripts/validate-manifests.sh` parses `marketplace.json` and every per-plugin `plugin.json`, exits 0 on valid inputs, non-zero on malformed inputs, and is the only required pre-commit gate.
  5. Top-level `LICENSE`, curated `.gitignore` (covers `.zapili/`, `.claude/cache/`, Node/Python/IDE/OS noise), and `.gitattributes` (`*.sh text eol=lf`, `*.bash text eol=lf`) are present and enforced.

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 01-01-manifests-PLAN.md — Marketplace + plugin JSON manifests (MKT-01, MKT-02, MKT-03, ZAP-03) — Wave 1
- [x] 01-02-documentation-PLAN.md — Top-level + plugin English READMEs (MKT-03, MKT-04, ZAP-03) — Wave 1
- [x] 01-03-hygiene-PLAN.md — LICENSE + .gitignore + .gitattributes (MKT-04, MKT-05, MKT-06) — Wave 1

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-04-validator-PLAN.md — validate-manifests.sh + install-hooks.sh + pre-commit + fixtures + driver (MKT-07, MKT-08) — Wave 2

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-05-install-rehearsal-PLAN.md — Live /plugin marketplace add + /plugin install rehearsal with stamped log (MKT-07) — Wave 3

### Phase 2: Plugin packaging — SessionStart hook + slash command shell

**Goal**: `zapili` exposes a working `/zapili:zapili` command shell whose pre-flight verifies `codex` availability strictly at command time, while the `SessionStart` hook is advisory-only and never bricks Claude Code.
**Depends on**: Phase 1
**Requirements**: ZAP-01, ZAP-02, ZAP-04, ZAP-05
**Success Criteria** (what must be TRUE):

  1. `/zapili:zapili` is discoverable in a session after `/plugin install zapili@oplya`, and its body delegates to the orchestrator skill (the orchestrator's logic is filled in later phases).
  2. With `codex` missing or unauthenticated, the `SessionStart` hook prints an advisory warning and exits 0 — Claude Code starts normally and `/plugin uninstall zapili` continues to work.
  3. With `codex` missing or unauthenticated, invoking `/zapili:zapili` halts with a clear, actionable error message *before* doing any other work (strict command-side pre-flight).
  4. Every `scripts/*.sh` is LF-only, has `#!/usr/bin/env bash`, is committed with mode `100755`, sets `set -euo pipefail`, and references plugin-local paths exclusively through `${CLAUDE_PLUGIN_ROOT}` (no relative `./`, no `$PWD`).
  5. Running `/zapili:zapili` does not write to `~/.claude/*`, `~/.config/codex/*`, or any path outside the user's project CWD — state stays under `<cwd>/.zapili/` and the artifact files in CWD.

**Plans**: 2 plans (1 wave)

**Wave 1**

- [x] 02-01-advisory-hook-PLAN.md — SessionStart hook + check-codex.sh (ZAP-02, partial ZAP-04/ZAP-05) — Wave 1
- [x] 02-02-command-shell-PLAN.md — preflight-codex.sh + commands/zapili.md + README update (ZAP-01, ZAP-04, ZAP-05) — Wave 1

### Phase 3: Inter-agent contracts — JSON Schemas + contract reference docs

**Goal**: Every machine-parseable payload (validation findings, research questions, phase changes, workflow state) is defined by a JSON Schema; the XML envelope, task-sizing thresholds, and exhaustive-review prompt scaffold are authored as the single source of truth that all downstream phases consume.
**Depends on**: Phase 2 (plugin must be installable for schemas to live in the right place)
**Requirements**: ZAP-10, ZAP-11, ZAP-12, ZAP-13, ZAP-14, ZAP-15
**Success Criteria** (what must be TRUE):

  1. `plugins/zapili/schemas/` contains the four mandatory schemas (`validation-findings.schema.json`, `research-questions.schema.json`, `phase-changes.schema.json`, `state.schema.json`); each schema validates a known-good sample and rejects a deliberately-broken one.
  2. `skills/orchestrator/references/contracts.md` specifies the XML envelope (`<request>...</request>` / `<response><payload>{json}</payload></response>`), the stable-issue-ID hashing rule, the soft per-engineer payload-size budget (~10k tokens), and forbidden review-prompt vocabulary (`key`, `main`, `top`, `important`).
  3. `skills/orchestrator/references/task-sizing.md` embeds the hard numeric thresholds for small / medium / large / gigantic task classes (LOC, modules, question count, phase count) verbatim per ZAP-15.
  4. `skills/orchestrator/references/codex-prompts.md` defines the exhaustive-review prompt scaffold (category enumeration → per-category findings including "no findings" → trailing `<coverage>` block → `<reclassification>` block when prior findings are anchored) and forbids top-N filtering vocabulary.
  5. `plugins/zapili/tests/fixtures/` contains 3–5 deliberately-flawed sample plans/diffs that demonstrate the exhaustive-review prompt surfacing every seeded issue at first pass — calibration is reproducible and documented.

**Plans**: 3 plans (2 waves)

**Wave 1** *(parallel-safe)*

- [x] 03-01-schemas-PLAN.md — 4 JSON Schemas + 8 examples + validate-schemas.sh (ZAP-10) — Wave 1
- [x] 03-02-references-PLAN.md — contracts.md + task-sizing.md + codex-prompts.md (ZAP-11, ZAP-12, ZAP-13, ZAP-14) — Wave 1

**Wave 2** *(blocked on Wave 1)*

- [x] 03-03-fixtures-PLAN.md — 5 calibration fixtures + tests/fixtures/README.md (ZAP-15) — Wave 2

### Phase 4: Orchestrator skill + research + plan + their codex validations

**Goal**: A linear, end-to-end one-shot pipeline runs from `TASK.md` through researcher + user Q&A → `CONTEXT.md` → codex research-validate (with iteration cap and prior-issue anchoring) → planner → `PLAN.md` + `PHASE-XX.md` (with mandatory `<files>` blocks) → codex plan-validate, with state.json bootstrap, single-writer discipline, and artifact-derived resume.
**Depends on**: Phase 3 (schemas + contract specs)
**Requirements**: ZAP-20, ZAP-21, ZAP-22, ZAP-23, ZAP-24, ZAP-30, ZAP-31, ZAP-32, ZAP-33, ZAP-34, ZAP-35, ZAP-50, ZAP-51, ZAP-52
**Success Criteria** (what must be TRUE):

  1. Running `/zapili:zapili` on a `TASK.md` produces a `CONTEXT.md` populated by researcher findings + user answers to a size-class-bounded question batch; the researcher subagent is read-only (Read, Grep, Glob only — no Write/Edit) and its XML+JSON output validates against `research-questions.schema.json`.
  2. Codex research-validation runs against `TASK.md` + `CONTEXT.md`, returns schema-valid HIGH/MEDIUM/LOW findings, loops with prior-issue anchoring (stable IDs, "resolved must not reappear" rule) until clean or until the hard iteration cap (≤3) — on cap, halts with a clear error and a persisted findings file.
  3. The planner subagent produces `PLAN.md` (wave structure with phase references) plus zero or more `PHASE-XX.md` files (one per phase, no duplicated content); every `PHASE-XX.md` includes a mandatory `<files>{"writes": [...], "reads": [...]}</files>` block; phase count is bounded per task size class.
  4. Codex plan-validation reviews `PLAN.md` + all `PHASE-XX.md` per the exhaustive-review prompt (including explicit pairwise write-scope disjointness verification per wave), loops until clean or iteration cap; codex scripts separate stdout (final answer) from stderr (progress) and propagate exit codes correctly.
  5. `.zapili/state.json` is bootstrapped by the orchestrator only (single-writer invariant), every artifact write uses temp-then-rename atomic pattern with a `<status>complete</status>` sentinel, and re-invoking `/zapili:zapili` after a kill-9 at any state boundary derives the resume point from artifact inspection (artifacts win over `state.json` on disagreement).

**Plans**: 3 plans (2 waves)

**Wave 1** *(parallel-safe)*

- [x] 04-01-codex-wrappers-and-state-PLAN.md — codex-review.sh + codex-validate-research.sh + codex-validate-plan.sh + state.sh (ZAP-22, ZAP-34, ZAP-50..52) — Wave 1
- [x] 04-02-subagents-PLAN.md — researcher.md + planner.md (ZAP-20, ZAP-30..33) — Wave 1

**Wave 2** *(blocked on Wave 1)*

- [x] 04-03-orchestrator-SKILL-PLAN.md — skills/orchestrator/SKILL.md body + commands/zapili.md skill delegation (ZAP-21, ZAP-23, ZAP-24, ZAP-35, ZAP-52) — Wave 2

### Phase 5: Engineer subagent + single-phase implementation + per-phase review + fix loop

**Goal**: A single phase round-trips cleanly end-to-end — engineer reads its `PHASE-XX.md` + scoped CONTEXT excerpt → edits source files → returns a schema-valid compact payload → codex per-phase review → fresh-engineer-plus-prior-attempt fix iteration → convergence within iteration cap — stress-testing the "agents are roles, continuity is by artifact" pattern before any parallelism.
**Depends on**: Phase 4 (orchestrator backbone + contract plumbing)
**Requirements**: ZAP-40, ZAP-43, ZAP-44, ZAP-45
**Success Criteria** (what must be TRUE):

  1. The engineer subagent (one spawn per phase) receives `TASK.md`, a scoped `CONTEXT.md` excerpt (only sections the phase declares), and its `PHASE-XX.md`, and returns an XML envelope whose `<payload>{files_touched, decisions, change_summary}` validates against `phase-changes.schema.json`.
  2. After the engineer completes for a single-phase wave, codex per-phase review runs against `TASK.md` + the phase plan + the engineer's change list and returns schema-valid HIGH/MEDIUM/LOW findings per the exhaustive-review prompt.
  3. The per-phase fix loop routes review findings back to a fresh engineer spawn together with the prior attempt's reasoning trace artifact; fixes converge within the hard iteration cap (≤3) and code style remains consistent across iterations because continuity is artifact-based.
  4. Each engineer attempt persists a `PHASE-XX-attempt-N.md` artifact (numbered ascending) capturing decisions, key choices, and files touched — these artifacts are deterministically consumed by the next fix iteration and remain human-inspectable.
  5. A reference small-task `TASK.md` (≤100 LOC, single-phase plan) completes the full single-phase pipeline (research → plan → 1 engineer → 1 review → optional fix) with no manual intervention beyond researcher Q&A, and no contract-violation crashes in the orchestrator.

**Plans**: 3 plans (2 waves)

**Wave 1** *(parallel-safe)*

- [x] 05-01-engineer-and-review-wrapper-PLAN.md — engineer.md + codex-review-phase.sh (ZAP-40, ZAP-43) — Wave 1
- [x] 05-02-smoke-fixture-PLAN.md — smoke-small-task fixture + procedure README (supporting ZAP-44/45) — Wave 1

**Wave 2** *(blocked on Wave 1)*

- [x] 05-03-SKILL-stage7-PLAN.md — SKILL.md Stage 7 single-phase round-trip + fix loop (ZAP-44, ZAP-45) — Wave 2

### Phase 6: Wave executor + final summary + resume hardening + publication polish

**Goal**: Lift the single-phase pipeline into wave-parallel execution — with mechanical write-scope disjointness verification before any wave fan-out, parallel codex review fan-out, per-wave fix convergence, automatic artifact-derived resume, a final summary aggregator, and end-to-end publication polish so `oplya` v1 ships.
**Depends on**: Phase 5 (engineer round-trip proven)
**Requirements**: ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54
**Success Criteria** (what must be TRUE):

  1. Before spawning any engineer in a wave, the orchestrator computes pairwise write-set intersection across all phases in the wave from the `<files>` blocks and aborts the wave with a clear error on any overlap — mechanical safety, never trusting LLM-claimed parallel-safety.
  2. Within a wave, all engineer subagents are spawned in parallel via a single assistant turn issuing N `Agent(engineer)` calls; after they complete, N parallel `Bash(codex-review-phase.sh)` calls run in a single assistant turn; waves execute strictly sequentially and the next wave does not start until the prior wave's fix loop has fully converged or hit its per-phase iteration cap.
  3. Automatic resume on `/zapili:zapili` re-invocation derives the current stage from artifact presence and completion sentinels alone; `state.json` is rewritten if it disagrees with artifacts; kill-9 chaos tests at every state boundary (research, validate, plan, validate, wave start, mid-wave, fix loop) all recover correctly.
  4. On workflow completion, a structured final summary lists every modified file aggregated across all waves and the key decisions (with justifications) drawn from each `PHASE-XX-attempt-N.md`, surfaced to the user as the closing message.
  5. The acceptance-criteria smoke tests (small task, large task with parallel waves, kill-9 resume) all pass on a fresh clone in a clean environment; README install instructions match verbatim; CHANGELOG, semver bump discipline, and reserved-name verification are documented and applied.

**Plans**: 4 plans (2 waves)

**Wave 1** *(parallel-safe)*

- [x] 06-01-scripts-PLAN.md — check-wave-disjointness.sh + derive-stage.sh + summarize.sh (ZAP-41, ZAP-53, ZAP-54) — Wave 1
- [x] 06-02-chaos-and-stamps-PLAN.md — chaos rehearsal docs + chaos-rehearsal-LOG + reserved-name-check-LOG (ZAP-53 documented) — Wave 1
- [x] 06-03-publication-polish-PLAN.md — CHANGELOG.md + README ## Status + plugin.json v1.0.0 — Wave 1

**Wave 2** *(blocked on Wave 1)*

- [x] 06-04-SKILL-wave-and-summary-PLAN.md — SKILL.md Stage 0 + Stage 7 wave parallel + Stage 8 summary (ZAP-41, ZAP-42, ZAP-46, ZAP-47) — Wave 2

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Marketplace + plugin skeleton | 5/5 | Complete   | 2026-05-28 |
| 2. Plugin packaging | 2/2 | Complete   | 2026-05-28 |
| 3. Inter-agent contracts | 3/3 | Complete   | 2026-05-28 |
| 4. Orchestrator + research + plan | 3/3 | Complete   | 2026-05-28 |
| 5. Engineer + single-phase + review/fix | 3/3 | Complete   | 2026-05-28 |
| 6. Wave executor + summary + resume + polish | 4/4 | Complete   | 2026-05-28 |
| 7. Review follow-ups cleanup | 0/0 | Not planned | — |
| 8. Codex self-fix fallback after iteration cap | 0/0 | Not planned | — |

## Coverage Map

All 43 v1 REQ-IDs + 6 v1.1 REQ-IDs are mapped to exactly one phase (49 total).

| Phase | Requirement IDs | Count |
|-------|-----------------|-------|
| 1 | MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, MKT-06, MKT-07, MKT-08, ZAP-03 | 9 |
| 2 | ZAP-01, ZAP-02, ZAP-04, ZAP-05 | 4 |
| 3 | ZAP-10, ZAP-11, ZAP-12, ZAP-13, ZAP-14, ZAP-15 | 6 |
| 4 | ZAP-20, ZAP-21, ZAP-22, ZAP-23, ZAP-24, ZAP-30, ZAP-31, ZAP-32, ZAP-33, ZAP-34, ZAP-35, ZAP-50, ZAP-51, ZAP-52 | 14 |
| 5 | ZAP-40, ZAP-43, ZAP-44, ZAP-45 | 4 |
| 6 | ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54 | 6 |
| 7 | ZAP-55, ZAP-56, ZAP-57, ZAP-58, ZAP-59 | 5 |
| 8 | ZAP-60 | 1 |
| **Total** | | **49** |

## Phase Ordering Rationale

- **Schemas (Phase 3) precede agents (Phases 4–5):** every agent prompt and every codex invocation references a schema; authoring agents first forces schema-after-the-fact rewrites of every prompt.
- **Single-phase pipeline (Phase 5) precedes parallelism (Phase 6):** file-scope overlap, payload bloat, and contract drift all manifest at the per-phase level — debugging them inside a wave fan-out is much harder.
- **Hook + slash-command shell (Phase 2) precedes orchestrator logic (Phase 4):** the dev loop needs fail-fast environment verification from day one; every subsequent `/zapili` invocation during development confirms its own preconditions.
- **Marketplace polish is split (Phase 1 + Phase 6):** the minimum installable skeleton is Phase 1 (you cannot test anything without `/plugin install` working); README polish, smoke tests, CHANGELOG, and reserved-name verification are Phase 6 (only meaningful once the workflow actually works).
- **Resume hardening sits in Phase 6, not Phase 4:** resume tests the union of all prior phases' state writes — chaos-test failures must be fixed in whichever phase wrote the bad state, so isolating it as a verification step is correct.
- **State requirements split across Phase 4 (ZAP-50/51/52) and Phase 6 (ZAP-53):** state-file plumbing, single-writer rule, and atomic writes are built into the orchestrator backbone in Phase 4; automatic resume hardening with chaos tests belongs to Phase 6 because it can only be validated against the full pipeline.
- **v1.1 hardening split into Phase 7 (followups) and Phase 8 (codex self-fix):** the followups are tactical bug-class items (UX gaps, fixture completeness, shell hygiene) — bundling them into one phase keeps the cleanup atomic. The codex self-fix fallback is a new capability (changes how the fix-loop terminates), depends on Phase 7's `prior-findings` contract and `flagged_gaps` routing (so the fixer reuses the same artifact-passing convention), and benefits from being a focused phase with its own success criteria and dedicated `f6-fix-loop-exhausted` fixture.

### Phase 7: Review follow-ups cleanup

**Goal**: Close the five non-blocking follow-ups surfaced by the v1.0.0 ultra-principal code review — planner's `prior-findings` input contract, orchestrator routing of `planner.flagged_gaps` to the user, completion of the three broken fixtures (f3/f4/f5 + the `fixtures/README.md` calibration loop), `check-codex.sh` shell-flag hygiene, and the `check-wave-disjointness.sh` phase-ID regex. None of these block end-to-end execution today; together they close the v1.0.0 hardening loop and raise fixture-coverage to 5/5 for codex calibration rehearsals.
**Depends on**: Phase 6 (all v1.0 artifacts shipped)
**Requirements**: ZAP-55, ZAP-56, ZAP-57, ZAP-58, ZAP-59
**Success Criteria** (what must be TRUE):

  1. `plugins/zapili/agents/planner.md` accepts an `<inputs>` block role `prior-findings` (optional) and its `<task>` section instructs the planner how to address each prior HIGH/MEDIUM finding by ID — fix-loop iterations have a defined contract (C-03).
  2. Orchestrator Stage 5 parses `planner.flagged_gaps` from the planner payload; if non-empty, surfaces each gap to the user via `AskUserQuestion` and appends answers to CONTEXT.md before advancing to `plan_validate` (C-04).
  3. `plugins/zapili/tests/fixtures/README.md` calibration loop uses the correct per-role wrapper invocation pattern (no more nonexistent `--role`/`--inputs`/`--out` flags); `f3-plan-ambiguity/PLAN.md`, `f4-phase-missing-tests/TASK.md`, and `f5-phase-style-drift/TASK.md` exist as minimal stub files so every fixture can be prog'd end-to-end (F-01/F-02).
  4. `plugins/zapili/scripts/check-codex.sh` uses `set -euo pipefail` (was `set -uo pipefail` — missing `-e` violates CLAUDE.md hook discipline and Phase 2 D-15); all existing `if !` and `|| true` guards still hold under `-e` (H-01).
  5. `plugins/zapili/scripts/check-wave-disjointness.sh` regex matches both production naming (`PHASE-01`, `PHASE-02`) and fixture naming (`PHASE-XX-a`, `PHASE-XX-b`) so the f2 self-test exercises the overlap-detection code path (S-01).

**Plans**: TBD (run /gsd-plan-phase 7 to break down)

### Phase 8: Codex self-fix fallback after iteration cap

**Goal**: When the codex review fix-loop hits the iteration cap (default: 4 attempts) with HIGH findings still persistent, do NOT abort — instead, dispatch a second codex invocation with role `fixer` whose task is to MODIFY the offending artifact (PHASE-XX.md, PLAN.md, or CONTEXT.md depending on the validator) to address every persistent HIGH finding, then re-run the original validator on the codex-fixed artifact. This is the escape hatch for cases where the engineer/planner subagent has reached its own ceiling on a particular issue but codex (with its independent context window and different model family) can resolve it. The loop terminates when (a) no HIGH findings remain, OR (b) codex's fix attempt itself produces no diff, OR (c) the post-fix re-review still has HIGH findings — at which point the workflow halts with the persisted findings + the codex fix transcript so the human can inspect.
**Depends on**: Phase 7 (planner contract and flagged_gaps routing land first — fixer reuses the same prior-findings contract)
**Requirements**: ZAP-60
**Success Criteria** (what must be TRUE):

  1. `plugins/zapili/scripts/codex-self-fix.sh` exists and accepts `<artifact_to_fix> <validator_role> <prior_findings_json>`; it composes a "fixer" prompt that (a) includes the artifact verbatim, (b) includes every HIGH finding from `prior_findings_json` with file/line/kind/remediation, (c) instructs codex to emit a unified-diff patch wrapped in `<response><patch>...</patch></response>` and nothing else; invokes codex via `codex-review.sh`; applies the patch via `git apply --check` first then `git apply`.
  2. Orchestrator Stage 4/6 fix-loop detects the iteration cap (default 4, configurable via `.zapili/state.json` `.fix_loop_cap`); on cap-hit with persistent HIGH findings, dispatches `codex-self-fix.sh` against the offending artifact; re-runs the original validator on the patched artifact; if post-fix review is clean → workflow proceeds; if post-fix review still has HIGH → workflow halts with a structured `## CODEX SELF-FIX EXHAUSTED` message naming the unresolved finding IDs and the path to the codex fix transcript.
  3. `codex-self-fix.sh` is safe to dry-run: when invoked with `--dry-run`, prints the proposed patch to stdout but does NOT touch the working tree; the orchestrator always dry-runs first and persists the patch under `.zapili/codex-self-fix-attempt-N.patch` before applying.
  4. The fixer prompt is documented in `plugins/zapili/skills/orchestrator/references/codex-prompts.md` as a fourth role alongside `research_validator`, `plan_validator`, `phase_reviewer`; SHA-256 ID derivation rule (CALIB-01) applies if fixer must reference prior IDs.
  5. End-to-end fixture: a new fixture `tests/fixtures/f6-fix-loop-exhausted/` reproduces a case where the engineer cannot resolve a HIGH finding within 4 attempts but codex-self-fix DOES resolve it on the 5th turn; the fixture exists as an integration acceptance test for ZAP-60.

**Plans**: TBD (run /gsd-plan-phase 8 to break down)

---
*Roadmap created: 2026-05-27*
*Phase 1 planned: 2026-05-27 — 5 plans across 3 waves*
