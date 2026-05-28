# Phase 8 Verification

**Verified:** 2026-05-28
**Outcome:** PASS — live codex round-trip against f6 fixture resolved the seeded HIGH finding `ISS-23ba7d51473d` end-to-end.

## Per-plan verification

### 08-01 — fixer script + fixer-role prompt
- `plugins/zapili/scripts/codex-self-fix.sh` exists, mode 0755, `set -euo pipefail`, signature `[--dry-run] <artifact> <validator_role> <prior_findings_json>`.
- Composes fixer prompt with artifact + HIGH+MEDIUM findings + worked-example unified-diff contract.
- Extracts `<patch>` via perl -0777 + AWK whitespace-trim; persists to `.zapili/codex-self-fix-attempt-N.patch`.
- `git apply --check` before `git apply`; --dry-run skips apply.
- Exit codes 0, 1, 2, 4, 64 all exercised in the live calibration runs.
- `references/codex-prompts.md` has `### fixer` section with prompt shape, halt-paths table, single-attempt rule, CALIB-01 cross-link.

### 08-02 — f6 fixture
- 6 files committed under `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/`.
- `jq .` succeeds on engineer-payload.json (attempt=4) and prior-findings.json (one HIGH finding ISS-23ba7d51473d).
- ID derivation reproducible: `printf '%s' "plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md|null|missing-tasks" | sha256sum | cut -c1-12` → `23ba7d51473d`.

### 08-03 — orchestrator integration + live calibration
- SKILL.md Stage 6.1 + Stage 7c.1 both wired with codex-self-fix dispatch + dry-run-then-apply + post-fix re-validate + `## CODEX SELF-FIX EXHAUSTED` halt diagnostics.
- Live round-trip transcript persisted at `live-codex-calibration-LOG.md` (full 4-iteration narrative) + `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/.zapili/codex-self-fix-attempt-1.*` (the final iteration's working artifacts).
- `git apply --check` exit 0 on the final patch.
- Seeded `ISS-23ba7d51473d` is NOT in the post-fix re-review output (proves the spec-level finding is resolved).
- Calibration-driven side-fix to `codex-review-phase.sh` regex (mirrors Phase 7 ZAP-59) committed in 08-03.

## Cross-phase regression

- No existing wrapper or schema modified beyond Plan 08-03's explicit edits.
- SKILL.md's existing Stage 6 and Stage 7c semantics preserved — the new 6.1 and 7c.1 sub-sections are FALLBACK paths that only fire on cap-hit; the happy path is unchanged.
- `.zapili/` gitignore rule preserved at the repo root; the fixture's `.zapili/` is force-added as calibration evidence.

## Requirements closed

- ZAP-60: COMPLETE (all 5 acceptance criteria PASS, see live-codex-calibration-LOG.md).

## Latent issues surfaced (out of Phase 8 scope, follow-up backlog)

1. Same `PHASE-[0-9]+(-[0-9]+)?` regex pattern in `check-wave-disjointness.sh` (Phase 7) and `codex-review-phase.sh` (Phase 8) — worth a contracts.md note that any future PHASE-id parser MUST use `[A-Za-z0-9]+`.
2. Codex prompt sensitivity to negative framing — iteration 3 showed empty-patch abdication under "this will be REJECTED" warnings; the working prompt uses positive direction. Worth a `references/codex-prompts.md` advisory note for future codex prompts.

<!-- <status>complete</status> -->
