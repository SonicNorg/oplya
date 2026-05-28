# Phase 6: Wave executor + final summary + resume hardening + publication polish - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution

<domain>
Lift the single-phase pipeline (Phase 5) into wave-parallel execution with mechanical write-scope disjointness verification, parallel codex review fan-out, per-wave fix convergence, automatic artifact-derived resume, a final summary aggregator, and end-to-end publication polish so `oplya` v1 ships.

**In scope:**
- Mechanical write-scope disjointness pre-flight (ZAP-41) — implemented as a script `plugins/zapili/scripts/check-wave-disjointness.sh` invoked by the orchestrator before any wave fans out
- Wave parallel fan-out instructions in SKILL.md Stage 7 (ZAP-42, ZAP-43) — single assistant turn issuing N `Agent(engineer)` calls; matched single-turn N `Bash(codex-review-phase.sh)` calls after all engineers return
- Per-wave fix-loop convergence — every phase in the wave converges before the next wave starts; cap 3 per phase (ZAP-46, ZAP-47)
- Stage 8 final summary aggregator (ZAP-54) — implemented as a script `plugins/zapili/scripts/summarize.sh` that walks `PHASE-XX-attempt-N.md` files and emits a structured Markdown closing report (`SUMMARY.md` in the user's project root)
- Resume hardening (ZAP-53) — explicit resume protocol in SKILL.md: enumerate artifacts on disk, compute the canonical stage, rewrite state.json if it disagrees, document chaos-test scenarios
- Publication polish — `CHANGELOG.md` at marketplace root; top-level README updates that mention v1 status + acceptance criteria check-list reference; `plugin.json` gets its first `"version": "1.0.0"` field; reserved-name re-verification stamp in `.planning/phases/06-.../reserved-name-check-LOG.md`

**Out of scope (v2 / deferred):**
- Sibling plugins (PLG-01..03)
- CI / TOOL-02 semver-bump auto-checks
- REV-01 alternative reviewers
- UX-01 web listing
- Live chaos-test execution (documented + scripted; manual rehearsal stamp documents the procedure was followed at release time)

</domain>

<decisions>
### Disjointness pre-flight (ZAP-41)
- **D-01:** `plugins/zapili/scripts/check-wave-disjointness.sh` — reads PLAN.md to enumerate waves and phase ids; for each wave, parses every PHASE-XX.md `<files>{"writes":[...]}</files>` block; computes pairwise intersection of writes sets across phases in the wave. Exit 0 if all waves are disjoint; exit 1 with a finding listing overlapping (phase_id, phase_id, overlapping_paths) for the first offending wave.
- **D-02:** Parser uses jq for the JSON inside `<files>` blocks. Tolerates whitespace; rejects malformed `<files>` blocks with exit 2.
- **D-03:** Orchestrator invokes `check-wave-disjointness.sh` once at the START of Stage 7 before any wave fan-out. Failure aborts the workflow with the script's diagnostic.

### Wave parallel fan-out (ZAP-42, ZAP-43)
- **D-04:** SKILL.md Stage 7 (rewritten): for each wave, if size > 1, the orchestrator issues N `Agent(engineer, ...)` calls in a SINGLE assistant turn. After all engineers return, the orchestrator issues N `Bash(codex-review-phase.sh, ...)` calls in a SINGLE assistant turn. This is the only way Claude Code runs them concurrently.
- **D-05:** Single-phase waves still go through the same Stage 7 path (single Agent / single Bash); the single-vs-multi distinction is purely a runtime branch on `wave_size`.

### Per-wave fix-loop convergence (ZAP-46, ZAP-47)
- **D-06:** After the wave's parallel review fan-out, partition the results: phases whose review exits 0 are advanced; phases with HIGH/MEDIUM findings re-enter Stage 7a with the prior-attempt artifact + prior findings. The fix iteration is per-phase but the wave does not progress until every phase converges OR hits its cap.
- **D-07:** Per-phase cap = 3 (unchanged from Phase 5). Wave halts with a structured diagnostic naming the offending phase(s) on cap reach.
- **D-08:** Wave N+1 does NOT start until Wave N's fix loop has fully converged (ZAP-47). Strictly sequential waves.

### Final summary aggregator (ZAP-54)
- **D-09:** `plugins/zapili/scripts/summarize.sh` reads every `PHASE-XX-attempt-N.md` in the user's project root (only the LATEST attempt per phase id wins; earlier attempts are reasoning trace, not authoritative). Extracts `files_touched` (aggregated, deduplicated across phases) + `decisions[]` (kept per-phase with phase_id annotation). Emits `SUMMARY.md` in the user's project root with sections: Overview / Files Changed (by phase) / Decisions (by phase) / Review Outcomes / Open Items.
- **D-10:** SKILL.md Stage 8 invokes `summarize.sh` after Stage 7 wave loop terminates with all waves clean.

### Resume hardening (ZAP-53)
- **D-11:** SKILL.md gets a new top-level "Stage 0 — Resume protocol" section (inserted before Stage 1 bootstrap) that documents the artifact-first resume rule (ZAP-53):
  1. Enumerate artifacts on disk: TASK.md, CONTEXT.md, PLAN.md, PHASE-*.md, PHASE-*-attempt-*.md, .zapili/state.json, .zapili/*.json
  2. Check completion sentinels — a file without `<!-- <status>complete</status> -->` is treated as absent
  3. Derive the canonical stage from artifact presence (state machine encoded in the script `plugins/zapili/scripts/derive-stage.sh`)
  4. If state.json disagrees with the derived stage, rewrite state.json (single-writer rule preserved)
  5. Document the chaos-test scenarios that exercise every boundary (kill-9 during research, kill-9 during research-validate, kill-9 mid-wave engineer, kill-9 mid-wave review, kill-9 during fix-loop fresh spawn)
- **D-12:** Chaos tests are DOCUMENTED + SCRIPTED in `plugins/zapili/tests/chaos/README.md` as a manual rehearsal procedure (kill -9 of the claude process at each boundary, then re-run /zapili:zapili and verify the documented expected behavior). Not executed in autonomous Phase 6; rehearsal stamp lives in `.planning/phases/06-.../chaos-rehearsal-LOG.md`.

### Publication polish
- **D-13:** Top-level `CHANGELOG.md` — `[Unreleased]` section initially empty; `[1.0.0] - YYYY-MM-DD` section listing every requirement that landed across Phases 1–6.
- **D-14:** `plugins/zapili/.claude-plugin/plugin.json` gets `"version": "1.0.0"` field added per Phase 1 D-09 release-time rule. After this, every subsequent change MUST bump the version.
- **D-15:** Top-level `README.md` adds a `## Status` section noting v1.0.0 + the link to CHANGELOG.md + a one-line statement of which acceptance criteria the release satisfies (per REQUIREMENTS § "Release Criteria").
- **D-16:** Reserved-name re-verification: a brief check that `oplya` and `zapili` are still clear on the Anthropic reserved-name list. Outcome stamped in `.planning/phases/06-.../reserved-name-check-LOG.md`.

### Plan structure
- **D-17:** Phase 6 has 4 plans, organized as 2 waves:
  - **Wave 1 (parallel-safe):**
    - Plan 06-01 — check-wave-disjointness.sh + derive-stage.sh + summarize.sh (scripts)
    - Plan 06-02 — chaos tests README + chaos-rehearsal-LOG.md + reserved-name-check-LOG.md (test/docs)
    - Plan 06-03 — Publication polish: CHANGELOG.md + top-level README update + plugin.json version bump
  - **Wave 2 (depends on Wave 1):**
    - Plan 06-04 — SKILL.md Stage 0 + Stage 7 + Stage 8 rewrite (integrates the scripts from 06-01)

</decisions>

<canonical_refs>
- REQUIREMENTS ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54 + § "Acceptance Criteria" + § "Release Criteria"
- ROADMAP § "Phase 6"
- Phase 5 SKILL.md (Stage 7 single-phase implementation) + PHASE-6-STUB
- Phase 4 codex wrappers + state.sh
- Phase 3 contracts.md, codex-prompts.md
- Phase 1 plugin.json (D-09 version-bump rule — release time)

</canonical_refs>

<code_context>
- check-wave-disjointness.sh shares the LF/mode/${CLAUDE_PLUGIN_ROOT} discipline with all prior scripts.
- summarize.sh's output (`SUMMARY.md` in user CWD) is distinct from `.planning/phases/.../SUMMARY.md` (which is GSD workflow state). User CWD ≠ this repo's CWD when zapili runs against an external project.
- plugin.json version bump from absent → "1.0.0" matches Phase 1 D-09 explicitly: "Planner adds version: 1.0.0 only at the eventual release commit (Phase 6 concern)." This IS that commit.

</code_context>

<specifics>
- Wave parallel fan-out uses Claude Code's natural concurrency: multiple tool calls in a single assistant turn execute in parallel. Subagent calls work the same way.
- summarize.sh deduplicates `files_touched` paths across phases — useful for the user-facing release notes; the per-phase decision list keeps phase_id annotations so the reader can trace each decision to its source phase.
- The version bump in plugin.json is a one-line change but it's the single most-load-bearing release artifact — every user on `main` only sees updates AFTER this lands. So it must land in the v1.0.0 release commit (or the immediately preceding one).

</specifics>

<deferred>
- Live chaos test execution (documented + scripted; manual procedure)
- Auto-CI integration (TOOL-02)
- Auto semver-bump warnings (TOOL-02)
- Alternative reviewers (REV-01)

</deferred>
