---
phase: 03-inter-agent-contracts-json-schemas-contract-reference-docs
type: overview
plans: 3
waves: 2
requirements:
  - ZAP-10
  - ZAP-11
  - ZAP-12
  - ZAP-13
  - ZAP-14
  - ZAP-15
---

# Phase 3 Plan: Inter-agent contracts — JSON Schemas + contract reference docs

**Created:** 2026-05-28
**Goal:** Every machine-parseable payload has a strict JSON Schema; XML envelope, stable issue ID rule, payload-size budget, forbidden vocabulary, task-sizing thresholds, and exhaustive-review prompt scaffold are authored as the single source of truth for Phase 4+. Calibration fixtures seeded with HIGH/MEDIUM/LOW issues confirm the exhaustive-review prompt surfaces every category.

## Wave Structure

### Wave 1 (parallel-safe — disjoint file scopes)

- **03-01** — Four JSON Schemas + valid/invalid examples + `validate-schemas.sh` (ZAP-10)
- **03-02** — Three reference docs: `contracts.md`, `task-sizing.md`, `codex-prompts.md` (ZAP-11, ZAP-12, ZAP-13, ZAP-14)

### Wave 2 (depends on Wave 1)

- **03-03** — Five calibration fixtures + fixtures README (ZAP-15) — reads schemas + reference docs

### Disjointness verification

| Plan | Writes |
|------|--------|
| 03-01 | `plugins/zapili/schemas/**`, `plugins/zapili/scripts/validate-schemas.sh` |
| 03-02 | `plugins/zapili/skills/orchestrator/references/contracts.md`, `task-sizing.md`, `codex-prompts.md` |
| 03-03 | `plugins/zapili/tests/fixtures/**` |

Pairwise intersection across all three: ∅. Wave 1 plans (03-01, 03-02) safely parallel.

## Decision Coverage

Decisions D-01..D-23 from `03-CONTEXT.md`:
- **Plan 03-01:** D-01..D-10 (schemas + validator + examples), D-22 (no .gitkeep), D-23 (no SKILL.md yet)
- **Plan 03-02:** D-11..D-18 (envelope + ID rule + budget + forbidden words + sizing + scaffold), D-22, D-23
- **Plan 03-03:** D-19..D-21 (fixtures), D-22, D-23
- **Cross-cutting:** D-24 (two-wave structure)

All 23 D-IDs cited verbatim across the three plan files.

## Requirements Coverage

| REQ-ID | Plan | Notes |
|--------|------|-------|
| ZAP-10 | 03-01 | Four schemas + self-test script + examples |
| ZAP-11 | 03-02 | XML envelope in contracts.md (English everywhere) |
| ZAP-12 | 03-02 | Stable ID rule + 10k-token budget + forbidden vocab in contracts.md |
| ZAP-13 | 03-02 | Numeric thresholds in task-sizing.md |
| ZAP-14 | 03-02 | Exhaustive-review scaffold in codex-prompts.md |
| ZAP-15 | 03-03 | Five fixtures + expected-findings + calibration README |

## Verification (phase-level)

1. `bash plugins/zapili/scripts/validate-schemas.sh` exits 0 (every schema validates its `.valid.json` and rejects its `.invalid.json`).
2. Every schema has `additionalProperties: false`, `$schema` set to draft 2020-12, `$id` matching `https://oplya.dev/zapili/schemas/<name>.schema.json`.
3. `grep -nP '\b(key|main|top|important)\b' plugins/zapili/skills/orchestrator/references/codex-prompts.md` returns ONLY matches that are inside the explicit forbidden-vocabulary enumeration (backtick-quoted).
4. `task-sizing.md` contains the verbatim numeric table (small/medium/large/gigantic rows).
5. `contracts.md` contains the literal stable-ID formula `sha256(file + "|" + line_range + "|" + kind)`.
6. Each fixture directory contains `expected-findings.json` matching `validation-findings.schema.json` (`bash scripts/validate-schemas.sh` exercise this via examples; fixtures use the same schema).
7. `plugin.json` is unchanged (`git diff plugins/zapili/.claude-plugin/plugin.json` empty).
8. No `.gitkeep` files (`find plugins/zapili -name .gitkeep` returns nothing).
9. Phase-1 validator (`scripts/validate-manifests.sh`) still passes.
