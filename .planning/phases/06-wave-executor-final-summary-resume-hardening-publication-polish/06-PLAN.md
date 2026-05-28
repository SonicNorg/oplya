---
phase: 06-wave-executor-final-summary-resume-hardening-publication-polish
type: overview
plans: 4
waves: 2
requirements: [ZAP-41, ZAP-42, ZAP-46, ZAP-47, ZAP-53, ZAP-54]
---

# Phase 6 Plan

## Waves

### Wave 1 (parallel-safe)
- **06-01** — scripts: check-wave-disjointness.sh + derive-stage.sh + summarize.sh (ZAP-41 mechanical, ZAP-53 derive, ZAP-54 aggregate)
- **06-02** — chaos test docs + chaos-rehearsal-LOG.md stamp + reserved-name-check-LOG.md stamp (ZAP-53 documented)
- **06-03** — Publication polish: CHANGELOG.md + top-level README v1 status + plugin.json version bump

### Wave 2 (depends on Wave 1)
- **06-04** — SKILL.md Stage 0 resume + Stage 7 wave parallel + Stage 8 summary integration (ZAP-42, ZAP-46, ZAP-47)

## Disjointness

| Plan | Writes |
|------|--------|
| 06-01 | `plugins/zapili/scripts/check-wave-disjointness.sh`, `derive-stage.sh`, `summarize.sh` |
| 06-02 | `plugins/zapili/tests/chaos/README.md`, `.planning/phases/06-.../chaos-rehearsal-LOG.md`, `.planning/phases/06-.../reserved-name-check-LOG.md` |
| 06-03 | `CHANGELOG.md`, `README.md`, `plugins/zapili/.claude-plugin/plugin.json` |
| 06-04 | `plugins/zapili/skills/orchestrator/SKILL.md` |

Pairwise: ∅.

## Decision coverage
D-01..D-17 cited across plans: D-01..D-03 + D-09 in 06-01; D-11..D-12 + D-16 in 06-02; D-13..D-15 in 06-03; D-04..D-08 + D-10 in 06-04; D-17 cross-cutting.

## Requirements coverage
| REQ | Plan |
|-----|------|
| ZAP-41 | 06-01 (script) + 06-04 (orchestrator invocation) |
| ZAP-42 | 06-04 (parallel fan-out in single assistant turn) |
| ZAP-46 | 06-04 (per-wave fix loop with cap 3) |
| ZAP-47 | 06-04 (strict sequential waves) |
| ZAP-53 | 06-01 (derive-stage.sh) + 06-02 (chaos docs) + 06-04 (Stage 0 in SKILL.md) |
| ZAP-54 | 06-01 (summarize.sh) + 06-04 (Stage 8 invocation) |

## Phase-level verification
1. All new scripts pass `bash -n`, mode 0755, LF, `set -euo pipefail`.
2. `validate-manifests.sh` passes after plugin.json gets `"version": "1.0.0"`.
3. `validate-schemas.sh` still passes.
4. SKILL.md PHASE-6-STUB block is REPLACED with working Stage 7 wave parallel + Stage 8 summary; new Stage 0 resume section present.
5. CHANGELOG.md exists with `[1.0.0]` section listing every Phase 1–6 requirement family.
6. README.md `## Status` section mentions v1.0.0 + CHANGELOG link.
7. Reserved-name check + chaos-rehearsal stamp files exist.
8. plugin.json now has `"version": "1.0.0"` (no other field changes).
