# Roadmap: oplya (Claude Code Plugin Marketplace + zapili)

**Created:** 2026-05-27
**Granularity:** standard
**Mode:** Horizontal Layers (technical phases, not user-facing vertical slices)
**Coverage:** 43/43 v1 requirements mapped (100%)

## Vision

A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts. v1 ships the `oplya` public marketplace + the `zapili` seed plugin.

## Phases

- [x] **Phase 1: Marketplace + plugin skeleton** — Installable repo layout with valid manifests, READMEs, LICENSE, .gitignore, .gitattributes, JSON validators (completed 2026-05-28)
- [ ] **Phase 2: Plugin packaging — SessionStart hook + slash command shell** — Advisory codex pre-flight + strict command-side check, LF-safe Bash scripts, `${CLAUDE_PLUGIN_ROOT}` discipline
- [ ] **Phase 3: Inter-agent contracts — JSON Schemas + contract reference docs** — Schemas for every machine-parseable payload, XML envelope spec, task-sizing thresholds, exhaustive-review prompt scaffold + calibration corpus
- [ ] **Phase 4: Orchestrator skill + research + plan + their codex validations** — Linear single-shot pipeline (research → research-validate → plan → plan-validate) with iteration caps, prior-issue anchoring, artifact-as-truth state model
- [ ] **Phase 5: Engineer subagent + single-phase implementation + per-phase review + fix loop** — Stress-test the per-phase round-trip and artifact-based continuity before introducing parallelism
- [ ] **Phase 6: Wave executor + final summary + resume hardening + publication polish** — Lift the single-phase path into wave-parallel execution with mechanical write-scope disjointness, ship-ready polish

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

**Plans**: TBD

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

**Plans**: TBD

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

**Plans**: TBD

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

**Plans**: TBD

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

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Marketplace + plugin skeleton | 5/5 | Complete   | 2026-05-28 |
| 2. Plugin packaging | 0/TBD | Not started | - |
| 3. Inter-agent contracts | 0/TBD | Not started | - |
| 4. Orchestrator + research + plan | 0/TBD | Not started | - |
| 5. Engineer + single-phase + review/fix | 0/TBD | Not started | - |
| 6. Wave executor + summary + resume + polish | 0/TBD | Not started | - |

## Coverage Map

All 43 v1 REQ-IDs are mapped to exactly one phase.

| Phase | Requirement IDs | Count |
|-------|-----------------|-------|
| 1 | MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, MKT-06, MKT-07, MKT-08, ZAP-03 | 9 |
| 2 | ZAP-01, ZAP-02, ZAP-04, ZAP-05 | 4 |
| 3 | ZAP-10, ZAP-11, ZAP-12, ZAP-13, ZAP-14, ZAP-15 | 6 |
| 4 | ZAP-20, ZAP-21, ZAP-22, ZAP-23, ZAP-24, ZAP-30, ZAP-31, ZAP-32, ZAP-33, ZAP-34, ZAP-35, ZAP-50, ZAP-51, ZAP-52 | 14 |
| 5 | ZAP-40, ZAP-43, ZAP-44, ZAP-45 | 4 |
| 6 | ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54 | 6 |
| **Total** | | **43** |

## Phase Ordering Rationale

- **Schemas (Phase 3) precede agents (Phases 4–5):** every agent prompt and every codex invocation references a schema; authoring agents first forces schema-after-the-fact rewrites of every prompt.
- **Single-phase pipeline (Phase 5) precedes parallelism (Phase 6):** file-scope overlap, payload bloat, and contract drift all manifest at the per-phase level — debugging them inside a wave fan-out is much harder.
- **Hook + slash-command shell (Phase 2) precedes orchestrator logic (Phase 4):** the dev loop needs fail-fast environment verification from day one; every subsequent `/zapili` invocation during development confirms its own preconditions.
- **Marketplace polish is split (Phase 1 + Phase 6):** the minimum installable skeleton is Phase 1 (you cannot test anything without `/plugin install` working); README polish, smoke tests, CHANGELOG, and reserved-name verification are Phase 6 (only meaningful once the workflow actually works).
- **Resume hardening sits in Phase 6, not Phase 4:** resume tests the union of all prior phases' state writes — chaos-test failures must be fixed in whichever phase wrote the bad state, so isolating it as a verification step is correct.
- **State requirements split across Phase 4 (ZAP-50/51/52) and Phase 6 (ZAP-53):** state-file plumbing, single-writer rule, and atomic writes are built into the orchestrator backbone in Phase 4; automatic resume hardening with chaos tests belongs to Phase 6 because it can only be validated against the full pipeline.

---
*Roadmap created: 2026-05-27*
*Phase 1 planned: 2026-05-27 — 5 plans across 3 waves*
