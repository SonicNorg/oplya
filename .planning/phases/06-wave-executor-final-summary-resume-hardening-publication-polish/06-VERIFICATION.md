---
phase: 06
status: passed
verified: 2026-05-28
mode: autonomous
---

# Phase 6 Verification

| # | Check | Result |
|---|-------|--------|
| 1 | All 3 new scripts bash -n clean, mode 0755 LF, set -euo pipefail | PASS |
| 2 | plugin.json has `"version": "1.0.0"`; validate-manifests.sh passes | PASS |
| 3 | validate-schemas.sh still passes | PASS |
| 4 | SKILL.md PHASE-6-STUB removed; Stage 0 + Stage 7 + Stage 8 wired | PASS |
| 5 | CHANGELOG.md exists with [1.0.0] section listing every requirement family | PASS |
| 6 | README.md `## Status` section mentions v1.0.0 + CHANGELOG link | PASS |
| 7 | chaos-rehearsal-LOG.md + reserved-name-check-LOG.md present | PASS |
| 8 | check-wave-disjointness.sh smoke-tests OK/FAIL on synthetic fixtures | PASS |
| 9 | summarize.sh generates SUMMARY.md with completion sentinel from synthetic phase artifacts | PASS |
| 10 | Forbidden vocab grep clean across all new files | PASS |

## Requirements coverage (v1 closure)

| REQ-ID | Status | Evidence |
|--------|--------|----------|
| ZAP-41 | Complete | check-wave-disjointness.sh + SKILL.md Stage 7.0 invocation |
| ZAP-42 | Complete | SKILL.md Stage 7a "single assistant turn" parallel Agent fan-out |
| ZAP-46 | Complete | SKILL.md Stage 7c per-wave fix loop with per-phase cap 3 |
| ZAP-47 | Complete | SKILL.md Stage 7d strict sequential waves |
| ZAP-53 | Complete | derive-stage.sh + SKILL.md Stage 0 reconciliation + tests/chaos/README.md |
| ZAP-54 | Complete | summarize.sh + SKILL.md Stage 8 invocation |

## Human verification

- Live chaos rehearsal: DEFERRED for release-time manual procedure (see `chaos-rehearsal-LOG.md`).
- Live codex calibration against fixtures: not run during autonomous Phase 6 (consistent with Phase 3 D-10 — dev-time).
- Live smoke-test round-trip: documented in `plugins/zapili/tests/fixtures/smoke-small-task/README.md`; for the maintainer to execute before tagging v1.0.0.

## Open items at v1.0.0

- Manual chaos rehearsal (11 boundaries) — stamped in `chaos-rehearsal-LOG.md` as TODO.
- Manual smoke-test round-trip — procedure documented.
- Pre-commit gate that runs `validate-schemas.sh` automatically — deferred to v2 polish.
- CI/TOOL-02 / REV-01 / UX-01 — v2 backlog.

## Notes

- All 43 v1 requirements are now traceable to a Phase 1–6 plan with at least one SUMMARY.md citing the requirement.
- `oplya` v1.0.0 is the first release where users on `main` receive the version bump — `plugins/zapili/.claude-plugin/plugin.json` now carries `"version": "1.0.0"` per Phase 1 D-09.
