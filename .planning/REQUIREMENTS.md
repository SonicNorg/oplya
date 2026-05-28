# Requirements: oplya (Claude Code Plugin Marketplace + zapili)

**Defined:** 2026-05-27
**Core Value:** A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts.

## v1 Requirements

Requirements for initial release (`oplya` marketplace + `zapili` plugin v1). Each maps to roadmap phases.

### Marketplace skeleton (MKT)

- [x] **MKT-01**: Repository root contains `.claude-plugin/marketplace.json` listing all plugins (only `name`, `owner`, `plugins` are required by spec; ship `$schema`, `displayName`, `category`, `tags` for polish)
- [x] **MKT-02**: Each plugin lives at `plugins/<plugin-name>/` with its own `.claude-plugin/plugin.json` (`name` required; `version` omitted while iterating so commit-SHA versioning applies)
- [x] **MKT-03**: Top-level `README.md` (English) documents the marketplace, install instructions (`/plugin marketplace add <repo>` then `/plugin install <name>@oplya`), and lists all plugins with one-line summaries
- [x] **MKT-04**: Top-level `LICENSE` file (MIT or Apache 2.0)
- [x] **MKT-05**: Curated top-level `.gitignore` covering Node/Python/IDE/OS noise plus plugin-local state directories (`.zapili/`, `.claude/cache/`, etc.)
- [x] **MKT-06**: Top-level `.gitattributes` enforcing `*.sh text eol=lf` and `*.bash text eol=lf` to prevent CRLF-induced hook failures
- [x] **MKT-07**: Local JSON validation script (`scripts/validate-manifests.sh`) verifying `marketplace.json` and each `plugin.json` parse cleanly before commit (light pre-commit checkpoint, not a CI gate)
- [x] **MKT-08**: Each plugin self-contained — no cross-plugin file references; every file `zapili` needs lives under `plugins/zapili/`

### zapili plugin scaffolding (ZAP-pkg)

- [x] **ZAP-01**: Single entry-point slash command (`/zapili:zapili`) defined in `plugins/zapili/commands/zapili.md` that delegates to the orchestrator skill and drives the entire workflow from `TASK.md` in the user's working directory
- [x] **ZAP-02**: `SessionStart` hook (`plugins/zapili/hooks/hooks.json` + `scripts/check-codex.sh`) emits an **advisory** warning if `codex` CLI is missing or unauthenticated (exit code 0 — must NOT brick Claude Code); strict pre-flight check happens inside the slash command itself
- [x] **ZAP-03**: Plugin-local README (`plugins/zapili/README.md`) explains what `zapili` does, required prerequisites (`codex` CLI + auth), and how to author a `TASK.md`
- [x] **ZAP-04**: All hook and helper scripts (`scripts/*.sh`) are LF-only, have `#!/usr/bin/env bash` shebang, are committed with executable bit, and use `${CLAUDE_PLUGIN_ROOT}` for any plugin-local path
- [x] **ZAP-05**: Plugin does NOT mutate global Claude Code config (no writes to `~/.claude/settings.json`, `~/.claude.json`, etc.); all state lives in the user's project CWD

### Inter-agent contracts (ZAP-spec)

- [x] **ZAP-10**: `plugins/zapili/schemas/` contains JSON Schemas for every machine-parseable payload — minimum: `validation-findings.schema.json`, `research-questions.schema.json`, `phase-changes.schema.json`, `state.schema.json`
- [x] **ZAP-11**: All prompts (orchestrator → subagent, orchestrator → codex) and all expected responses are **English** and use Anthropic-style XML envelope (`<request>...</request>` / `<response><payload>{json}</payload></response>`), with JSON payloads validated against the schemas in ZAP-10
- [x] **ZAP-12**: Orchestrator reference docs (`plugins/zapili/skills/orchestrator/references/contracts.md`) specify the XML envelope, stable-issue-ID rules (hash of `{file, line-range, kind}`), payload-size budgets (soft cap ~10k tokens per engineer prompt), and forbidden vocabulary for review prompts (no "key", "main", "top", "important")
- [x] **ZAP-13**: Task-size policy reference (`plugins/zapili/skills/orchestrator/references/task-sizing.md`) embeds the hard numeric thresholds — small (≤100 LOC, 1–3 modules, 3–4 questions, plan only); medium (≤500 LOC, 1–5 modules, 5–8 questions, plan + 3–4 phases); large (≤1000 LOC, 2–8 modules, 9–12 questions, plan + 5–8 phases); gigantic (>1000 LOC, 13–20 questions, plan + 9–20 phases)
- [x] **ZAP-14**: Codex review prompt scaffold (`plugins/zapili/skills/orchestrator/references/codex-prompts.md`) forces **exhaustive** HIGH/MEDIUM/LOW coverage — explicit category enumeration first, then findings per category (including "no findings"), trailing `<coverage>{files_reviewed, categories_checked}</coverage>` block, forbidden top-N vocabulary, and a `<reclassification>` block when prior findings are anchored
- [x] **ZAP-15**: Reference corpus of 3–5 deliberately-flawed sample plans/diffs exists in `plugins/zapili/tests/fixtures/` and is used to calibrate the exhaustive-review prompt before release

### Research phase (ZAP-research)

- [x] **ZAP-20**: Researcher subagent (`plugins/zapili/agents/researcher.md`) is read-only (tools allowlist: Read, Grep, Glob, Bash for ls/find only — no Write/Edit), reads `TASK.md` + referenced sources, classifies task size per ZAP-13, and produces an XML+JSON question batch with relevant context per question
- [x] **ZAP-21**: Orchestrator presents researcher's questions to the user via AskUserQuestion (or text-mode equivalent), collects answers, and writes consolidated `CONTEXT.md` containing researcher findings, code references, and user answers
- [x] **ZAP-22**: Codex research-validation wrapper (`plugins/zapili/scripts/codex-validate-research.sh`) reviews `TASK.md` + `CONTEXT.md` for contradictions, gaps, missing context; returns schema-validated HIGH/MEDIUM/LOW findings with remediation hints
- [x] **ZAP-23**: Research-validation loop — orchestrator runs additional research + asks targeted user questions to resolve findings, loops until no HIGH/MEDIUM remain or hard iteration cap (≤3) is reached; on cap-reached, halts with a clear error and persisted findings file
- [x] **ZAP-24**: Prior-issue anchoring — each subsequent codex research-validation call receives the prior issue list with stable issue IDs and the rule "resolved must not reappear; reclassifications must be justified"

### Planning phase (ZAP-plan)

- [x] **ZAP-30**: Planner subagent (`plugins/zapili/agents/planner.md`) reads `TASK.md` + `CONTEXT.md` and produces `PLAN.md` (overall plan with wave structure and phase references) plus zero or more `PHASE-XX.md` files (one per phase), with NO duplicated content between documents
- [x] **ZAP-31**: Phase count is bounded per task size class (per ZAP-13)
- [x] **ZAP-32**: Each `PHASE-XX.md` includes a mandatory machine-parseable `<files>{"writes": [...], "reads": [...]}</files>` block declaring its file scope
- [x] **ZAP-33**: `PLAN.md` organizes phases into **waves** — strictly sequential groups in which intra-wave phases may run in parallel iff their write-scopes are pairwise disjoint; the planner proposes wave grouping but the orchestrator verifies disjointness mechanically
- [x] **ZAP-34**: Codex plan-validation wrapper (`plugins/zapili/scripts/codex-validate-plan.sh`) performs ultra-principal review of `PLAN.md` + all `PHASE-XX.md` + referenced sources, checking contradictions, gaps, ambiguity, parallelization safety, completeness, architectural fit, OOP/DRY/KISS, professionalism, and explicitly verifying pairwise write-scope disjointness per wave
- [x] **ZAP-35**: Plan-validation loop — orchestrator routes findings back to the planner for fixes, loops until no HIGH/MEDIUM remain or hard iteration cap (≤3) is reached

### Implementation phase (ZAP-impl)

- [x] **ZAP-40**: Engineer subagent (`plugins/zapili/agents/engineer.md`) is invoked once per phase per wave; receives `TASK.md`, scoped CONTEXT excerpt, its `PHASE-XX.md`, and the formalized XML+JSON contract; returns an XML envelope with a JSON `<payload>{files_touched, decisions, change_summary}` block validated against `phase-changes.schema.json`
- [x] **ZAP-41**: Orchestrator computes pairwise write-set intersection across all phases in a wave **before** spawning any engineer; aborts the wave with a clear error if any overlap detected (mechanical safety, never trusts LLM-claimed parallel-safety)
- [x] **ZAP-42**: Within a wave, all engineer agents are spawned in parallel (single assistant turn issuing N `Agent()` calls)
- [x] **ZAP-43**: After all engineers in a wave complete, per-phase codex review runs in parallel (single assistant turn issuing N `Bash(codex-review-phase.sh)` calls); each review receives `TASK.md`, the phase plan, and the engineer's change list; returns schema-validated HIGH/MEDIUM/LOW findings
- [x] **ZAP-44**: Per-phase fix loop — review findings are routed back to a fresh engineer spawn with the prior attempt's reasoning trace artifact (`PHASE-XX-attempt-N.md`) so continuity is by artifact, not by process identity
- [x] **ZAP-45**: Per-attempt reasoning trace persistence — engineer's decisions, key choices, and files touched are written to `PHASE-XX-attempt-N.md` after each attempt (numbered ascending), enabling the next fix-iteration to consume them
- [x] **ZAP-46**: Per-wave fix loop converges when every phase in the wave has no HIGH/MEDIUM findings; hard iteration cap (≤3) per phase; on cap-reached, the wave halts with a clear error and persisted findings
- [x] **ZAP-47**: Waves execute strictly sequentially; next wave does not start until the prior wave's fix loop has fully converged

### State, resume, and final summary (ZAP-state)

- [x] **ZAP-50**: On-disk artifacts in the user's project CWD are the source of truth for resume — `TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`, `PHASE-XX-attempt-N.md`
- [x] **ZAP-51**: `.zapili/state.json` (schema in `schemas/state.schema.json`) is a cache capturing current phase, current wave, iteration counters, and stable issue IDs; **single-writer rule** — only the orchestrator writes it
- [x] **ZAP-52**: All artifact writes use temp-then-rename atomic pattern; each artifact embeds a completion sentinel (`<status>complete</status>` or equivalent) so half-written files are detectable
- [x] **ZAP-53**: Automatic resume — on `/zapili` re-invocation, the orchestrator derives current stage from artifact presence and completion sentinels; if `.zapili/state.json` disagrees with artifacts, artifacts win and `state.json` is rewritten
- [x] **ZAP-54**: Final summary on workflow completion — user receives a structured report listing all modified files (aggregated across all phases) and the key decisions (with justifications) made by implementation agents, drawn from each `PHASE-XX-attempt-N.md`

## v2 Requirements

Deferred to future releases. Tracked but not in v1 roadmap.

### Additional plugins (PLG)

- **PLG-01**: Sibling plugin for debugging workflow (`zapili-debug` or similar)
- **PLG-02**: Sibling plugin for testing workflow
- **PLG-03**: Sibling plugin for hotfix workflow

### Tooling and polish (TOOL)

- **TOOL-01**: GitHub Actions CI validation of `marketplace.json` and per-plugin `plugin.json` on push
- **TOOL-02**: Automated semver bump check (warn on plugin file change without version bump)
- **TOOL-03**: Windows shim or compatibility layer for hook scripts
- **TOOL-04**: Skill bundles for specific languages (Java, Python, TypeScript) that ship `zapili` with pre-tuned researcher and engineer prompts
- **TOOL-05**: Telemetry collection (opt-in) — task size, iteration counts, time-to-converge per stage

### Alternative reviewers (REV)

- **REV-01**: Pluggable reviewer LLM — support for Gemini CLI or other model families as alternatives to codex (still independent of Claude)
- **REV-02**: Local-only review mode — fall back to a Claude subagent if codex is permanently unavailable, with clear "this is degraded" warning

### UX polish (UX)

- **UX-01**: Web listing page for the marketplace (GitHub Pages)
- **UX-02**: Per-plugin badge/shield generator
- **UX-03**: `/zapili:status` command for inspecting current workflow state without re-running

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Debugging / testing / hotfix in v1 zapili | `zapili` is explicitly scoped to new-development; other workflows are sibling plugins for future milestones |
| Private / self-hosted marketplace | Public GitHub only for v1; corporate Git hosts can be added later if needed |
| Sharing existing personal plugins | None mature yet; `zapili` is the seed plugin |
| Mandatory CI / automated test gates | Solo maintainer + small team; light process. JSON manifests still locally validated (MKT-07) |
| Claude fallback for codex validation | Codex is mandatory in v1 — the cross-model-review property is core. Pluggable alternatives are REV-01, not a fallback |
| GUI / web UI for marketplace | Git + Claude Code `/plugin` commands are the entire interface; web listing is UX-01 (v2) |
| Persistent agent identity across spawns | Claude Code subagents are stateless by spec; continuity is by artifact (ZAP-44/45), not process — designing around this is a category error |
| Aggregated single-pass review | Per-phase parallel review with per-phase fix loops is the design; aggregating across phases would lose locality of feedback |
| Top-N or "key findings" filtering in codex output | Forbidden by ZAP-14; each missed finding costs an extra iteration. Exhaustive coverage is non-negotiable |
| Auto-approve / skip user questions | Researcher's questions must be answered by the user; auto-answer would defeat the context-gathering purpose |
| Worktree-based isolation per engineer | Out of v1 scope; orchestrator-side mechanical disjointness check (ZAP-41) is sufficient |
| Per-language coding-standard skill packs | Tracked as TOOL-04 in v2; v1 ships language-agnostic engineer prompts |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| MKT-01 | 1 | Complete |
| MKT-02 | 1 | Complete |
| MKT-03 | 1 | Complete |
| MKT-04 | 1 | Complete |
| MKT-05 | 1 | Complete |
| MKT-06 | 1 | Complete |
| MKT-07 | 1 | Complete |
| MKT-08 | 1 | Complete |
| ZAP-01 | 2 | Complete |
| ZAP-02 | 2 | Complete |
| ZAP-03 | 1 | Complete |
| ZAP-04 | 2 | Complete |
| ZAP-05 | 2 | Complete |
| ZAP-10 | 3 | Complete |
| ZAP-11 | 3 | Complete |
| ZAP-12 | 3 | Complete |
| ZAP-13 | 3 | Complete |
| ZAP-14 | 3 | Complete |
| ZAP-15 | 3 | Complete |
| ZAP-20 | 4 | Complete |
| ZAP-21 | 4 | Complete |
| ZAP-22 | 4 | Complete |
| ZAP-23 | 4 | Complete |
| ZAP-24 | 4 | Complete |
| ZAP-30 | 4 | Complete |
| ZAP-31 | 4 | Complete |
| ZAP-32 | 4 | Complete |
| ZAP-33 | 4 | Complete |
| ZAP-34 | 4 | Complete |
| ZAP-35 | 4 | Complete |
| ZAP-40 | 5 | Complete |
| ZAP-41 | 6 | Complete |
| ZAP-42 | 6 | Complete |
| ZAP-43 | 5 | Complete |
| ZAP-44 | 5 | Complete |
| ZAP-45 | 5 | Complete |
| ZAP-46 | 6 | Complete |
| ZAP-47 | 6 | Complete |
| ZAP-50 | 4 | Complete |
| ZAP-51 | 4 | Complete |
| ZAP-52 | 4 | Complete |
| ZAP-53 | 6 | Complete |
| ZAP-54 | 6 | Complete |

**Coverage:**
- v1 requirements: 43 total
- Mapped to phases: 43 (100%)
- Unmapped: 0

## User Stories

Behind every requirement is one of these user journeys. Used to generate PR descriptions.

- **As a team member**, I want to install `zapili` from a known marketplace so I can use the same development workflow as the rest of the team
- **As an author**, I want to publish a new plugin by adding a directory and an entry in `marketplace.json` so I don't have to set up CI or release infrastructure
- **As a developer**, I want to drop a `TASK.md` in my working directory and run `/zapili` so an AI workflow handles research, planning, and implementation with formalized review at every stage
- **As a developer**, I want the workflow to ask me focused, context-rich questions sized to my task so I don't have to write a perfect spec up front
- **As a developer**, I want every stage validated by an independent model (codex) so I don't ship work the orchestrator hallucinated
- **As a developer**, I want every codex review to surface ALL issues (HIGH/MEDIUM/LOW) so I don't waste iterations on partial coverage
- **As a developer**, I want phases that touch independent files to run in parallel so large tasks finish faster — without risk of write conflicts
- **As a developer**, I want the workflow to survive my session crashing or laptop sleep so I can resume from the last completed stage without losing context

## Acceptance Criteria

Marketplace install path is verified end-to-end:

1. After `git clone <oplya-repo>`, `/plugin marketplace add ./` succeeds with no validation errors
2. `/plugin install zapili@oplya` makes `/zapili:zapili` available in the current session
3. SessionStart hook produces an advisory message when `codex` is missing, and does NOT block any Claude Code action

`zapili` workflow round-trip on a small reference task:

4. With a `TASK.md` describing a ≤100 LOC change in 1–3 modules, `/zapili:zapili` completes the full pipeline (research → research-validate → plan → plan-validate → 1 wave → review → summary) with no manual intervention beyond answering 3–4 researcher questions
5. Every codex invocation returns schema-valid JSON; orchestrator never crashes on a contract-violation
6. Every researcher/planner/engineer subagent returns an XML envelope with a schema-valid JSON payload
7. Validation loops terminate within the iteration cap; if not, the workflow halts with a clear error and persisted findings file rather than spinning

`zapili` workflow round-trip on a large task with parallel waves:

8. With a `TASK.md` describing a ≤1000 LOC change spanning 2–8 modules, `/zapili:zapili` produces a plan with at least one wave containing ≥2 parallel phases whose write-scopes are mechanically verified disjoint
9. Engineers in the parallel wave are spawned in a single assistant turn (verified by tool-call trace)
10. Per-phase codex review runs in parallel after all engineers complete
11. After completion, the final summary lists every modified file across all waves and the key decisions from each phase

State and resume:

12. Killing the session mid-workflow (any stage) and re-running `/zapili:zapili` resumes from the correct stage as determined by artifact inspection, not from `state.json` alone
13. `.zapili/state.json` is only ever written by the orchestrator; subagents and codex never touch it

## Definition of Done

A requirement is "Complete" only when ALL of:

- Implementation exists in the correct file under `plugins/zapili/`
- Manual smoke test against the acceptance criteria above passes
- Local `scripts/validate-manifests.sh` exits 0
- Atomic git commit landed on the working branch with a descriptive message
- No regressions in previously-completed requirements (re-run small-task acceptance test)

## Release Criteria

`oplya` v1 is releasable when:

- All 43 v1 requirements are Complete per Definition of Done
- Acceptance criteria 1–13 above pass on a fresh clone in a clean environment
- README install instructions verified verbatim against a clean machine (no prior `oplya` install)
- LICENSE present; semver bump policy documented in top-level README
- Reference task fixtures in `plugins/zapili/tests/fixtures/` produce the expected exhaustive-coverage output from codex (ZAP-15 calibration confirmed)

## v1.1 Requirements

Hardening and capability extension for `oplya` v1.1 (added 2026-05-28 from the v1.0.0 ultra-principal review + new codex self-fix capability). Maps to Phases 7 and 8.

### Review follow-ups cleanup (ZAP-followups) — Phase 7

- [ ] **ZAP-55**: `plugins/zapili/agents/planner.md` declares an optional `<file role="prior-findings">` input in its `<inputs>` block; the `<task>` section explicitly instructs the planner how to address each prior HIGH/MEDIUM finding by ID on a fix iteration, cite each finding ID in the revision's `flagged_gaps` for traceability, and avoid removing phases to hide gaps (mirrors `engineer.md`'s existing prior-findings handling). Closes review finding C-03.
- [ ] **ZAP-56**: Orchestrator Stage 5 (post-planner) parses `flagged_gaps` from the planner payload; if non-empty, surfaces each gap to the user via `AskUserQuestion` (one question per gap, or batched), appends the user's answers to `CONTEXT.md` under a new `## Gap Resolutions` section, and only then advances to `plan_validate`. Empty `flagged_gaps` array continues silently. Closes review finding C-04.
- [ ] **ZAP-57**: `plugins/zapili/tests/fixtures/README.md` calibration loop documents the correct per-role wrapper invocation (`codex-validate-research.sh <task> <context>`, `codex-validate-plan.sh <plan> <phase_glob>`, `codex-review-phase.sh <task> <phase> <engineer_payload>`); fixture `f3-plan-ambiguity/` includes a minimal `PLAN.md` referencing its `PHASE-XX.md`; fixtures `f4-phase-missing-tests/` and `f5-phase-style-drift/` each include a minimal `TASK.md` setting context for the engineer payload. Every fixture in `tests/fixtures/f1..f5` and `smoke-small-task` runnable end-to-end via the documented loop. Closes review findings F-01 and F-02.
- [ ] **ZAP-58**: `plugins/zapili/scripts/check-codex.sh` uses `set -euo pipefail` (currently `set -uo pipefail` — missing `-e`); existing `if ! ... ; fi` and `|| true` guards continue to work under `-e`; SessionStart hook still exits 0 on missing/unauthenticated codex (advisory contract per ZAP-02 preserved). CLAUDE.md hook discipline and Phase 2 D-15 honored. Closes review finding H-01.
- [ ] **ZAP-59**: `plugins/zapili/scripts/check-wave-disjointness.sh` regex pattern accepts both production naming (`PHASE-01`, `PHASE-02`) and fixture/test naming (`PHASE-XX-a`, `PHASE-XX-b`, `PHASE-XX.YY`); the f2 fixture's PHASE files are detected, intra-wave write-set intersection is computed, and the seeded overlap surfaces as `kind: "write-scope-overlap"`. Closes review finding S-01.

### Codex self-fix fallback (ZAP-self-fix) — Phase 8

- [ ] **ZAP-60**: After the codex review fix-loop (Stage 4 `plan_validate` or Stage 6 `phase_review`) hits its iteration cap (default 4, configurable via `.zapili/state.json` `.fix_loop_cap`) with at least one persistent HIGH finding, the orchestrator dispatches `plugins/zapili/scripts/codex-self-fix.sh <artifact> <validator_role> <prior_findings_json>` instead of halting. The fixer composes a "fixer-role" prompt (documented as a fourth role in `references/codex-prompts.md`) instructing codex to emit a unified-diff patch wrapped in `<response><patch>...</patch></response>`; the orchestrator dry-runs the patch via `git apply --check`, persists it under `.zapili/codex-self-fix-attempt-N.patch`, then applies it via `git apply`; the original validator re-runs against the patched artifact. Termination: (a) post-fix re-review clean → continue workflow; (b) codex emits an empty patch → halt with `## CODEX SELF-FIX EXHAUSTED — no diff produced`; (c) post-fix re-review still has HIGH → halt with the unresolved finding IDs + patch path. A new fixture `tests/fixtures/f6-fix-loop-exhausted/` exercises this path end-to-end (engineer cannot resolve in 4 attempts; codex self-fix resolves on attempt 5). SHA-256 ID derivation (CALIB-01) applies if the fixer references prior IDs.

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-28 — v1.1 requirements (ZAP-55..60) added after ultra-principal review + new codex self-fix capability*
