---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: hardening + codex self-fix
status: in_progress
stopped_at: Phase 7 closed (review follow-ups landed); Phase 8 next (codex self-fix fallback)
last_updated: "2026-05-28T17:30:00.000Z"
last_activity: 2026-05-28
progress:
  total_phases: 8
  completed_phases: 7
  total_plans: 23
  completed_plans: 23
  percent: 87
---

# STATE — oplya (Claude Code Plugin Marketplace + zapili)

**Last updated:** 2026-05-28 (v1.1 milestone opened — Phases 7+8 added for review follow-ups + codex self-fix fallback; not yet planned)

## Project Reference

- **Project:** oplya — Claude Code Plugin Marketplace (with `zapili` as the seed plugin)
- **Core Value:** A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts.
- **Project doc:** [.planning/PROJECT.md](PROJECT.md)
- **Requirements:** [.planning/REQUIREMENTS.md](REQUIREMENTS.md) (43 v1 + 6 v1.1 = 49 requirements)
- **Roadmap:** [.planning/ROADMAP.md](ROADMAP.md) (8 phases — 6 complete in v1.0, 2 not yet planned in v1.1)
- **Research:** [.planning/research/SUMMARY.md](research/SUMMARY.md) + STACK / FEATURES / ARCHITECTURE / PITFALLS
- **Mode:** yolo
- **Granularity:** standard
- **Parallelization:** enabled

## Current Position

Milestone: v1.1 (hardening + codex self-fix) — IN PROGRESS
Phase: 07 (review-followups-cleanup) — NOT YET PLANNED

- **Milestone:** v1.1
- **Phase:** 7 — Review follow-ups cleanup
- **Status:** Ready to discuss/plan (run `/gsd-plan-phase 7`)
- **Last Activity:** 2026-05-28
- **Progress:** [███████░░░] 75% (6 of 8 phases complete; 2 v1.1 phases not yet planned)
- **Phases 1–6 complete (v1.0.0 shipped, audit gaps_found accepted, 4 blockers + 1 calibration finding fixed post-audit)**

## Phase Map

| Phase | Goal (one line) | Status |
|-------|-----------------|--------|
| 1 | Marketplace + plugin skeleton installable end-to-end | ✅ Complete |
| 2 | SessionStart hook (advisory) + `/zapili:zapili` command shell with strict pre-flight | ✅ Complete |
| 3 | JSON Schemas + contract reference docs (XML envelope, sizing, exhaustive-review scaffold) | ✅ Complete |
| 4 | Orchestrator skill: research + research-validate + plan + plan-validate (linear pipeline) | ✅ Complete |
| 5 | Engineer subagent + single-phase implementation + per-phase review + fix loop | ✅ Complete |
| 6 | Wave executor + final summary + resume hardening + publication polish | ✅ Complete |
| 7 | Review follow-ups cleanup (C-03/C-04/F-01/F-02/H-01/S-01 → ZAP-55..59) | ✅ Complete |
| 8 | Codex self-fix fallback after iteration cap (ZAP-60 — new capability) | ⏸ Not yet planned (next) |

## Roadmap Evolution

- 2026-05-28: v1.0 milestone closed at 6/6 phases complete; v1.0.0 published.
- 2026-05-28: v1.1 milestone opened; Phase 7 added (review follow-ups from v1.0.0 ultra-principal review — C-03, C-04, F-01/F-02, H-01, S-01); Phase 8 added (codex self-fix fallback after iteration cap — new capability per user request).

## Performance Metrics

- **Phases complete:** 0 / 6
- **Requirements complete:** 9 / 43 (MKT-01, MKT-02, MKT-03, MKT-04, MKT-05, MKT-06, MKT-07, MKT-08, ZAP-03)
- **Open blockers:** none
- **Iterations / retries:** Plan 01-01 first-pass clean (0 retries, 0 deviations); Plan 01-02 first-pass with one Rule 3 auto-fix (literal `/plugin install` added to plugin README to satisfy automated gate); Plan 01-03 first-pass clean (0 retries, 0 deviations); Plan 01-04 first-pass clean (0 retries, 0 deviations)

| Phase / Plan | Duration | Tasks | Files |
|--------------|----------|-------|-------|
| Phase 01 P01 (manifests) | 1 min | 2 tasks | 2 files |
| Phase 01 P02 (documentation) | 2 min | 2 tasks | 2 files |
| Phase 01 P03 (hygiene) | 1 min | 3 tasks | 3 files |
| Phase 01 P04 (validator) | 6 min | 3 tasks | 7 files |

## Accumulated Context

### Key Decisions (carried from PROJECT.md)

| Decision | Rationale |
|----------|-----------|
| Marketplace `oplya`, first plugin `zapili` | User-chosen project identity |
| Public GitHub repo | Team primary audience; external contributors welcome |
| Themed plugins (not micro-plugins) | Each plugin = one coherent workflow |
| `codex` CLI mandatory, no Claude fallback | Cross-model independent review is the design's load-bearing property |
| All prompts + agent responses in English with XML+JSON contracts | Anthropic prompt-engineering canon; machine-parseable payloads |
| On-disk artifacts as source of truth (`TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`, `PHASE-XX-attempt-N.md`); `.zapili/state.json` is a cache | Survives session loss; resumes deterministically; inspectable |
| Strictly sequential waves with parallel intra-wave phases | Maximum parallelism without write conflicts |
| Light publication process (no required CI) | Solo maintainer + small team; local JSON validation only |
| Task-size thresholds embedded in prompts | Removes researcher/planner ambiguity |
| Codex review prompts produce exhaustive HIGH/MEDIUM/LOW (no top-N filtering) | Each missed issue forces another iteration; full set up front converges fastest |
| Orchestrator-in-main-thread, workers-as-stateless-subagents (research finding) | Claude Code subagents cannot spawn subagents — forced architectural fact |
| "Same agent fixes review" is a category error; continuity by artifact (research finding) | Subagents are stateless; persist reasoning trace as `PHASE-XX-attempt-N.md` and feed to fresh spawn |
| Mechanical write-scope disjointness check before any wave spawn (research finding) | Never trust LLM-claimed parallel safety; orchestrator computes intersection |

### Decisions Made During Execution

- **[Phase 01 P01]** Pinned canonical `$schema` URLs (Anthropic marketplace schema + JSON Schema Store plugin schema) — editor-experience win; loader ignores `$schema` at load time.
- **[Phase 01 P01]** Applied RESEARCH drift fixes: dropped `owner.url` from marketplace.json (documented schema is `{name, email}` only); omitted `category` from plugin.json (category is a marketplace `plugins[]`-entry field only, not a plugin-manifest field).
- **[Phase 01 P01]** Zero component keys (`commands`/`agents`/`hooks`/`mcpServers`) in plugin.json — Phase 2+ default-folder auto-discovery picks up populated folders without manifest edits (D-10/D-23/D-24).
- **[Phase 01 P02]** Augmented plugin README's Install section with the literal `/plugin install zapili@oplya` text alongside the D-26 cross-link — required because Task 2's automated acceptance gate greps for the literal string which a pure cross-link would not produce. D-26 cross-link to `../../README.md#install` preserved verbatim.
- **[Phase 01 P02]** Top-level README's Local development section includes `claude plugin validate . --strict` as a clearly-optional supplementary check (per RESEARCH Open Question Q3) — framed so contributors without the `claude` CLI are not gated.
- **[Phase 01 P03]** LICENSE uses verbatim OSI MIT text (no paraphrase) so the SPDX `MIT` identifier matches and license-detection tools render correctly — RESEARCH "Don't Hand-Roll" warning honored.
- **[Phase 01 P03]** `.gitignore` ignores `.claude/cache/` only, NOT `.claude/` itself — project settings directory must remain tracked so contributors get the project-level Claude configuration on clone.
- **[Phase 01 P03]** `.gitattributes` includes discretionary `*.json` / `*.md` / `*.png` / `*.jpg` patterns on top of the mandatory `*.sh` / `*.bash` LF lines (D-22 explicitly permits planner discretion). Wave 1 ordering ensures `.gitattributes` is committed strictly before Plan 04's `scripts/*.sh` files (RESEARCH Pitfall 11).
- **[Phase 01 P04]** Validator uses `set -uo pipefail` only — DELIBERATELY omits `e` so the validation loop surfaces ALL failures in one pass (RESEARCH Pitfall 7). `test-validator.sh` Test A regression-guards this with deliberately-double-broken fixtures and asserts `grep -c FAIL: >= 2` (saw exit=1, FAIL lines=2 — exactly as expected).
- **[Phase 01 P04]** `test-validator.sh` itself uses `set -euo pipefail` (fail-fast on its own assertion errors); the `-e` ban applies ONLY to `validate-manifests.sh`.
- **[Phase 01 P04]** `bad-invalid-source.json` is committed as INFORMATIONAL — the current D-12 minimal validator does NOT check source-path safety; the fixture documents the surface for future TOOL-* hardening. Driver prints an explicit note so a future reader does not treat its presence as a missing check.
- **[Phase 01 P04]** Installer's idempotence smoke (install → no-op → divergence-abort) was run in-place against the real `.git/hooks/pre-commit`. Side-effect: the hook is now installed and byte-identical to the committed template (reversible with `rm .git/hooks/pre-commit`). The active hook gated the Plan 04 commits as a no-op (no manifest files staged).

### Open Todos (from roadmap)

- Phase 1: marketplace + plugin skeleton (installable end-to-end)
- Phase 2: SessionStart hook + slash command shell
- Phase 3: schemas + contract reference docs (with calibration corpus)
- Phase 4: orchestrator + research/plan + their codex validations
- Phase 5: engineer + single-phase + per-phase review + fix loop
- Phase 6: wave executor + final summary + resume hardening + publication polish

### Active Blockers

None.

### Research Flags (from SUMMARY.md)

- **Phase 3 calibration corpus** needs deliberate iteration: assemble 3–5 deliberately-flawed plans/diffs and tune the exhaustive-review prompt against them before launch (Pitfall 8 mitigation).
- **Phase 6 parallel `Agent(...)` dispatch syntax** should be confirmed against the live Claude Code v2.1+ docs at the start of Phase 6 planning.
- **Reserved plugin name check** for `oplya` and `zapili` — verify at Phase 1 start (free; clear on 2026-05-27).
- **Per-phase token budget threshold** (soft 10k tokens per engineer prompt) — tune during Phase 5 on real medium-task runs.

## Session Continuity

### Next Action

Execute Plan 01-05 (final plan of Phase 1 per ROADMAP — retrospective/handoff). All static-skeleton requirements satisfied; installable end-to-end via `/plugin marketplace add nepavel/oplya` + `/plugin install zapili@oplya`. Active `.git/hooks/pre-commit` will validate any future commit that touches a `.claude-plugin/*.json` manifest.

### How to Resume

1. Read `.planning/PROJECT.md` for vision and constraints.
2. Read `.planning/REQUIREMENTS.md` for the 43 v1 REQ-IDs and their phase mapping.
3. Read `.planning/ROADMAP.md` for the 6 phases, their success criteria, and the coverage map.
4. Read this file (`.planning/STATE.md`) for current position and accumulated context.
5. If a phase is in progress, also read the relevant `XX-PLAN.md` (created by `/gsd:plan-phase`) and any in-flight `PHASE-XX-attempt-N.md` artifacts.

### Last Session Summary

- 2026-05-28 — Completed Plan 01-04-validator-PLAN.md. Wrote `scripts/validate-manifests.sh` (commit `78546c4`, bash+jq, `set -uo pipefail` only, no `set -e` per RESEARCH Pitfall 7), `scripts/test-validator.sh` + 3 fixtures (commit `20aa56b`, all three test cases green — Test A regression-guards Pitfall 7 with `grep -c FAIL: >= 2`), `scripts/install-hooks.sh` + `scripts/pre-commit` (commit `f727da8`, idempotence smoke: install→no-op→divergence-abort exits 0/0/1 as designed). Zero deviations, zero retries. `.git/hooks/pre-commit` now installed and active (byte-identical to template; reversible). 2 requirements completed (MKT-07, MKT-08); cumulative 9 / 43. Ready for Plan 01-05.
- 2026-05-28 — Completed Plan 01-03-hygiene-PLAN.md. Wrote `LICENSE` (commit `7253f2e`, verbatim OSI MIT 2026 Pavel), `.gitignore` (commit `36a29b6`, 8 D-21 categories), `.gitattributes` (commit `7481500`, mandatory `*.sh` / `*.bash` LF + discretionary `*.json` / `*.md` LF + binary markers). All acceptance criteria passed first-pass; zero deviations. `.gitattributes` lands in Wave 1 strictly before Plan 04's `scripts/*.sh` files (RESEARCH Pitfall 11 honored). `.claude/cache/` ignored but `.claude/` itself stays tracked. T-03-01 (env secrets) and T-03-02 (CRLF interpreter spoofing) mitigations in place. 3 requirements completed (MKT-04, MKT-05, MKT-06); cumulative 7 / 43. Ready for Plan 01-04 (Validator).
- 2026-05-28 — Completed Plan 01-02-documentation-PLAN.md. Wrote `README.md` (commit `aef99ea`, 37 lines) and `plugins/zapili/README.md` (commit `73b7ae3`, 32 lines). All plan acceptance criteria + plan-level `<verification>` block pass. One Rule 3 auto-fix: literal `/plugin install zapili@oplya` text appended to the plugin README's Install cross-link to satisfy the plan's automated grep gate. English-only verified (zero Cyrillic), no badges/screenshots/TOC, plugin tree leaf count still exactly 2 (MKT-08/D-23 preserved). MKT-03 and ZAP-03 confirmed complete (already marked under P01). Ready for Plan 01-03 (Hygiene).
- 2026-05-28 — Completed Plan 01-01-manifests-PLAN.md. Wrote `.claude-plugin/marketplace.json` (commit `fd0d573`) and `plugins/zapili/.claude-plugin/plugin.json` (commit `c2d070b`). All plan acceptance criteria + `<verification>` block passed first-pass; zero deviations. Marketplace catalog now discoverable; plugin manifest now resolvable via `metadata.pluginRoot` → `./plugins/zapili`. RESEARCH drift fixes applied (no `owner.url`, no `category` on plugin.json). 4 requirements completed (MKT-01, MKT-02, MKT-03, ZAP-03). Ready for Plan 01-02 (Documentation).
- 2026-05-27 — Project initialized. PROJECT.md, REQUIREMENTS.md (43 v1 reqs), and the four research streams (STACK / FEATURES / ARCHITECTURE / PITFALLS) authored, then synthesized into research/SUMMARY.md. Roadmap (6 phases, horizontal-layers structure, 100% coverage) approved and persisted. Ready to plan Phase 1.
- **Stopped at:** Completed 01-04-validator-PLAN.md
- **Resume file:** None

---
*State file initialized: 2026-05-27 · Phase 01 Plan 04 complete: 2026-05-28*
