# Changelog

All notable changes to the `oplya` marketplace and the `zapili` plugin are documented here.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Versions live on the `zapili` plugin (`plugins/zapili/.claude-plugin/plugin.json`); the marketplace itself is commit-SHA-versioned.

## [Unreleased]

(Nothing yet — next changes land here.)

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
