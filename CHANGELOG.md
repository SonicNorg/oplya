# Changelog

All notable changes to the `oplya` marketplace and the `zapili` plugin are documented here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions live on the `zapili` plugin (`plugins/zapili/.claude-plugin/plugin.json`); the marketplace itself is commit-SHA-versioned.

## [Unreleased]

(Nothing yet — next changes land here. v1.2 candidate will collect deferred NITs.)

## [1.1.2] - 2026-05-29

### Added

- **`/zapili:status` slash command** (`plugins/zapili/commands/status.md`) — read-only snapshot of `.zapili/state.json` for the project CWD. Renders the current workflow stage with a human-readable meaning, active wave + phase position, iteration counters per validator (with `cap` from `fix_loop_cap`), and any open finding ids carried across the current iteration. Prints a fallback message when no `.zapili/` directory exists. Frontmatter pins `claude-haiku-4-5` (cheap model — the command is pure read + tabular print) and restricts `allowed-tools` to `Bash(test:*)` + `Read` so the read-only contract is enforced at the tool layer. Honors ZAP-50 (orchestrator is the single writer to `state.json`) — this command MUST NOT write.
- **`/zapili:help` updated** to list the new `/zapili:status` command in its command index. Version string bumped from `v1.1.1` to `v1.1.2`.

## [1.1.1] - 2026-05-29

### Added

- **`/zapili:help` slash command** (`plugins/zapili/commands/help.md`) — usage index covering: command list, where TASK.md must live (project CWD), how to author a useful TASK.md (WHAT/WHY/STACK/CONSTRAINTS), prerequisites (codex CLI + auth, jq, perl), workflow stage breakdown, `.zapili/` state directory contents, crash-resume semantics, halt-diagnostic interpretation, and what zapili explicitly does NOT touch (global Claude Code config, git remote, paths outside CWD). Pinned to `claude-haiku-4-5` per the command's frontmatter — the help screen is a static print and does not warrant a heavier model. Auto-discovered by Claude Code from `commands/`; no `plugin.json` changes needed thanks to the v1.0 D-10/D-23/D-24 decision to leave the `commands` key unset.

## [1.1.0] - 2026-05-29

### Pre-release fixes (post-release-prep ultra-principal review, same date)

- **Russian text removed from production prompt scaffolds** (review P1-1) — a two-word Russian phrase was verbatim-copied from an external prompt template and shipped in the `<exhaustiveness>` block of all three validator scripts + `codex-prompts.md`. Violates the global `CLAUDE.md` rule "Never use Russian in code or tests for any purpose". Replaced with `(exhaustive coverage, not a targeted re-review)` in all four locations + the four `calibration-v1.1.0-attempt-1.prompt.txt` snapshots.
- **`phase-changes.schema.json` attempt cap raised to 10** (review P1-2) — `iteration_counters.maximum` in `state.schema.json` was raised to 10 during the B-3 fix, but `phase-changes.schema.json` `attempt` field still had `maximum: 3`. With `fix_loop_cap` default of 4, every attempt-4 engineer payload failed schema validation unconditionally, blocking the entire default workflow. Now `maximum: 10` matches `state.schema.json` parity.
- **Top-level `README.md` Status section updated** (review P1-3) — version line was still `v1.0.0 (2026-05-28)` with `43 of 43`. Now `v1.1.0 (2026-05-29)` with `49 of 49: 43 v1 + 6 v1.1`.
- **`validation-findings.schema.json` finding-ID uniqueness enforced** (review P2-1) — added `uniqueItems: true` to the `findings` array (catches whole-object duplicates) plus a runtime `jq` ID-uniqueness check in all three validator wrapper scripts after schema validation (catches duplicate-id-different-object cases that pass `uniqueItems`). Duplicate-id payloads now exit 3 instead of silently losing one finding from the orchestrator's prior-issue carry-forward set. `codex-prompts.md` documents the disambiguation rule: prefer the most specific category for the location and omit the duplicate; do NOT extend the SHA-256 digest input with `category` (would break back-compat with existing `expected-findings.json` fixtures).
- **Absolute build-machine paths removed from prompt heredocs** (review P2-2) — all four scripts (`codex-validate-research.sh`, `codex-validate-plan.sh`, `codex-review-phase.sh`, `codex-self-fix.sh`) used `$PROMPTS_REF` which expanded to the developer's `/home/norg/...` absolute path in the heredoc'd prompt. Replaced with the literal `${CLAUDE_PLUGIN_ROOT}/...` placeholder that codex sees as documentation, plus an in-place `sed` patch of the four `calibration-v1.1.0-attempt-1.prompt.txt` snapshots.
- **CALIBRATION-v1.1.0.md table accuracy** (review P2-3 + P2-4) — table claimed `tests_to_add: n/a` for plan_validator runs (false — codex does populate it opportunistically) and `not_fully_audited: TBD per attempt` for all f2..f5 (false — actual values are 0, 0, 2, 1 from the persisted JSONs). Updated table with real values + footnotes explaining the f4/f5 gaps.
- **SKILL.md hardcoded "3-attempt cap" diagnostics replaced** (review P2-5) — Stage 4 (research-validate), Stage 6 (plan-validate), and Stage 7c (per-phase) had `"after 3 iterations"` / `"3-attempt cap"` literals while `fix_loop_cap` defaults to 4 and is user-configurable. All three stages now read `cap=$(state_get '.fix_loop_cap // 4')` and use `${cap}` in diagnostic strings. Research-validate also moved off its independent hardcoded-3 cap to honor `fix_loop_cap` like the other two validators.

### Added

- **Review follow-ups cleanup (ZAP-55..59, Phase 7)** — planner `<file role="prior-findings">` input contract on fix iterations (ZAP-55); orchestrator Stage 5.5 routes planner `flagged_gaps` to the user via `AskUserQuestion` and appends answers to CONTEXT.md `## Gap Resolutions` before plan_validate (ZAP-56); `tests/fixtures/README.md` calibration loop uses real wrapper signatures + minimal `f3/PLAN.md`, `f4/TASK.md`, `f5/TASK.md` so all 5 fixtures runnable end-to-end (ZAP-57); `check-codex.sh` switches to `set -euo pipefail` while preserving SessionStart advisory exit-0 contract (ZAP-58); `check-wave-disjointness.sh` regex broadened to `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?` so f2 fixture detects the seeded overlap (ZAP-59).

### Added

- **Review follow-ups cleanup (ZAP-55..59, Phase 7)** — planner `<file role="prior-findings">` input contract on fix iterations (ZAP-55); orchestrator Stage 5.5 routes planner `flagged_gaps` to the user via `AskUserQuestion` and appends answers to CONTEXT.md `## Gap Resolutions` before plan_validate (ZAP-56); `tests/fixtures/README.md` calibration loop uses real wrapper signatures + minimal `f3/PLAN.md`, `f4/TASK.md`, `f5/TASK.md` so all 5 fixtures runnable end-to-end (ZAP-57); `check-codex.sh` switches to `set -euo pipefail` while preserving SessionStart advisory exit-0 contract (ZAP-58); `check-wave-disjointness.sh` regex broadened to `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?` so f2 fixture detects the seeded overlap (ZAP-59).
- **Codex self-fix fallback after iteration cap (ZAP-60, Phase 8)** — `plugins/zapili/scripts/codex-self-fix.sh` wrapper composes a "fixer" prompt (artifact + HIGH findings + remediation + worked unified-diff example) and invokes codex via the shared `codex-review.sh` bridge; extracts `<patch>...</patch>` via `perl -0777` (multi-line safe); persists each attempt under `.zapili/codex-self-fix-attempt-N.patch`; `--dry-run` validates via `git apply --check` and emits the patch file path on stdout (zero-impact mode); orchestrator Stage 6.1 (post-`plan_validate` cap-hit) and Stage 7c.1 (per-phase `phase_review` cap-hit) dispatch the fixer when the engineer/planner exhausts its iteration cap with persistent HIGH findings, then re-run the original validator on the patched artifact. Termination paths: clean → continue; empty patch → `## CODEX SELF-FIX EXHAUSTED — no diff produced`; post-fix re-review still HIGH → `## CODEX SELF-FIX EXHAUSTED` with unresolved IDs + patch path. `fixer` role documented in `references/codex-prompts.md` as the fourth codex role alongside the three validators. New `tests/fixtures/f6-fix-loop-exhausted/` fixture reproduces an engineer-stuck-but-codex-resolves scenario as integration acceptance.
- **Exhaustiveness contract for all codex validator prompts** — every validator (research_validate, plan_validate, phase_review) gains a verbatim `<exhaustiveness>` block (calibrated against codex-cli 0.133.0) that defeats codex's default targeted-review mode: explicit ban on top-N filtering, "treat prior_findings as hypotheses, re-validate from scratch", "return the maximum number of substantiated findings in a single pass", "if you run out of budget, declare it in `not_fully_audited[]` — silent gaps are worse than declared gaps". External P0/P1/P2/P3 severity scales mapped onto HIGH/MEDIUM/LOW in `codex-prompts.md` for prompt-portability.
- **Schema extension (back-compat, all optional)** — `validation-findings.schema.json` gains finding-level `why_real_risk`, `repro`, `tests_to_add` and top-level `not_fully_audited[]`. Old fixture files without the new fields continue to validate.

### Fixed

- **Codex JSONL extraction supports codex-cli 0.133.0 event shape (CB-02)** — `codex-review.sh` extractor adds branch for `{type:"item.completed", item:{type:"agent_message", text:"..."}}` (current codex) while preserving the legacy `{type:"message", role:"assistant", content:"..."}` branch as fallback. Pre-fix every codex-* wrapper returned empty string against live codex → schema validation always failed with exit 3.
- **Multi-line `<payload>` extraction (C-02)** — three validator wrappers switch from single-line `sed` (which silently returns empty on pretty-printed JSON spanning multiple lines) to `perl -0777 -ne 'print $1 if /<payload>(.*?)<\/payload>/s'`.
- **JSON array-typed content from OpenAI structured format (CB-01)** — `jq -rs` extractor branches on `content` type (string vs array of `{type,text}` items) and joins text parts before writing raw text.
- **SHA-256 finding-ID derivation documented (CALIB-01)** — `codex-prompts.md` adds explicit formula, edge cases for null `file`/`line_range`, worked example, and explicit ban on inventing IDs. Live calibration confirmed codex was emitting non-deterministic IDs without the formula.
- **`phase_id` schema pattern accepts single-phase naming (C-01)** — `phase-changes.schema.json` pattern relaxed from `^[0-9]{2}-[0-9]{2}$` to `^[0-9]{2}(-[0-9]{2})?$`. Engineer payloads emit `"01"` (production single-phase naming); old pattern required `"01-01"` and made every payload fail schema validation.
- **Orchestrator wave-counter advancement (SK-01)** — Stage 7c reads `current_wave` from state.json before arithmetic. Pre-fix `$((current_wave + 1))` expanded to 1 every wave boundary because `current_wave` was unset, blocking multi-wave plans from progressing past Wave 1.
- **Codex self-fix patch validate ≠ apply mismatch (post-review B-1)** — orchestrator was invoking `codex-self-fix.sh` twice (dry-run then real), causing two independent codex calls and applying a DIFFERENT patch than the one `git apply --check` validated. Now one invocation, captured patch file path, `git apply` directly on the persisted file.
- **`check-wave-disjointness.sh` false-positive on repeated phase ids (post-review B-2)** — added `sort -u` dedup on the per-wave pids array. PLAN.md prose that mentions a phase id more than once (e.g., in a Notes section) no longer triggers OVERLAP.
- **`state.schema.json` accepts `fix_loop_cap` (post-review B-3)** — schema gains `fix_loop_cap` property and raises `iteration_counters` maximum to 10, matching the SKILL.md default cap of 4 and the configurable range ZAP-60 promised.

### Documentation

- `CHANGELOG.md` adopted for the v1.1.0 release.
- `references/codex-prompts.md` extended with: exhaustiveness contract section, severity mapping table (P0/P1/P2/P3 → HIGH/MEDIUM/LOW), finding evidence requirements, `not_fully_audited[]` explanation, fixer role + halt-paths table + single-attempt rule.
- `.planning/v1.1-MILESTONE-AUDIT.md` records audit outcome + post-audit ultra-principal review + the three rounds of fixes (initial 4 blockers, post-review 3 blockers + 3 warnings, exhaustiveness contract).

## [1.0.0] - 2026-05-28

### Added

- **Marketplace skeleton (MKT-01..08, ZAP-03)** — `.claude-plugin/marketplace.json` with `oplya` catalog; `plugins/zapili/.claude-plugin/plugin.json`; top-level README + LICENSE (MIT) + curated `.gitignore` / `.gitattributes`; pre-commit `scripts/validate-manifests.sh` + `scripts/install-hooks.sh`.
- **Plugin packaging (ZAP-01, ZAP-02, ZAP-04, ZAP-05)** — `/zapili:zapili` slash command shell with strict `codex` pre-flight; advisory `SessionStart` hook (never bricks Claude Code); LF/`set -euo pipefail`/`${CLAUDE_PLUGIN_ROOT}` shell discipline; no global config writes.
- **Inter-agent contracts (ZAP-10..15)** — four JSON Schemas (draft 2020-12) for validation findings, research questions, phase changes, orchestrator state; XML envelope spec; stable issue-ID rule (`sha256(file|line_range|kind)` first-12 hex, `ISS-` prefix); 10,000-token soft budget; exhaustive-review prompt scaffold; task-sizing thresholds (small/medium/large/gigantic); 5 calibration fixtures.
- **Research + planning pipeline (ZAP-20..24, ZAP-30..35)** — read-only researcher subagent; planner subagent with mandatory `<files>` blocks per phase; codex research-validate + plan-validate wrappers with stable-ID prior-issue anchoring and ≤3 iteration caps; orchestrator skill body (`skills/orchestrator/SKILL.md`) wiring all stages.
- **State + resume (ZAP-50..53)** — `.zapili/state.json` single-writer cache; atomic temp-then-rename writes; completion sentinels (`<!-- <status>complete</status> -->`) on every artifact; `derive-stage.sh` artifact-first resume; chaos-rehearsal procedure documented.
- **Engineer round-trip + per-phase review + fix loop (ZAP-40, ZAP-43..45)** — engineer subagent with `<files>.writes` constraint; `codex-review-phase.sh` per-phase review wrapper; `PHASE-XX-attempt-N.md` reasoning-trace artifacts; fresh-engineer fix iteration with prior-attempt artifact + findings; ≤3 per-phase cap.
- **Wave parallel + summary (ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-54)** — `check-wave-disjointness.sh` mechanical pairwise verification; parallel engineer fan-out within a wave (single assistant turn); parallel per-phase review fan-out; per-wave fix-loop convergence; strict sequential waves; `summarize.sh` aggregator emits `SUMMARY.md` with files-touched + decisions + review outcomes.

### Documentation

- Top-level `README.md` with install + plugin index + Local development sections.
- `plugins/zapili/README.md` with prerequisites, usage, and the two-level codex pre-flight explanation.
- Reference docs under `plugins/zapili/skills/orchestrator/references/`: `contracts.md`, `task-sizing.md`, `codex-prompts.md`.
- Calibration fixtures under `plugins/zapili/tests/fixtures/`.
- Chaos rehearsal procedure under `plugins/zapili/tests/chaos/README.md`.
- Smoke-test fixture under `plugins/zapili/tests/fixtures/smoke-small-task/`.
