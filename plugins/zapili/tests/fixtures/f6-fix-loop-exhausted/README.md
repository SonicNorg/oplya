# Fixture f6 — codex self-fix fallback (engineer stuck → codex resolves)

**Role:** `fixer` (driven via `plugins/zapili/scripts/codex-self-fix.sh`)
**Seeded scenario:** the engineer cannot self-resolve a HIGH `missing-tasks`
finding because the phase spec itself is what's wrong (PHASE-XX.md never asks
for tests). After 4 engineer attempts the fix loop hits the cap, the
orchestrator dispatches `codex-self-fix.sh`, codex revises PHASE-XX.md to add
the missing test task + extend `<files>.writes`, the orchestrator re-runs the
phase reviewer, and the HIGH finding is resolved.

## Files

| File | Purpose |
|------|---------|
| `TASK.md` | The user-facing task description (justifies why tests are required). |
| `PLAN.md` | Single-phase wave. |
| `PHASE-XX.md` | Phase plan with DELIBERATELY omitted test task. Subject of the fix. |
| `engineer-payload.json` | 4th-attempt engineer output: stays in scope per PHASE-XX.md and never authors tests. |
| `prior-findings.json` | The persistent HIGH `missing-tasks` finding (`ISS-23ba7d51473d`) the engineer cannot resolve. |

## Seeded finding ID derivation (CALIB-01)

```
digest_input = "plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md|null|missing-tasks"
sha256       = 23ba7d51473d... (first 12 hex)
id           = "ISS-23ba7d51473d"
```

Reproduce with:

```bash
printf '%s' "plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md|null|missing-tasks" \
  | sha256sum | cut -c1-12
```

## Live-codex round-trip (informational; actually executed in Plan 08-03)

```bash
cd plugins/zapili/tests/fixtures/f6-fix-loop-exhausted
bash ../../../scripts/codex-self-fix.sh --dry-run \
  PHASE-XX.md phase_reviewer prior-findings.json
```

## Pass criterion (dual-outcome)

- **Best case:** codex emits a non-empty patch; `git apply --check` succeeds;
  re-running `codex-review-phase.sh` against the patched PHASE-XX.md returns
  no HIGH finding for the `missing-tasks` category.
- **Acceptable case:** codex emits an empty patch (exit 1) OR a malformed diff
  (exit 4); the wrapper halts cleanly with the documented exit code, and the
  orchestrator surfaces `## CODEX SELF-FIX EXHAUSTED` to the user.

The acceptance contract is "the round-trip executes end-to-end with a clean
exit code", not "codex always solves the seeded problem". The latter depends on
the live codex's reasoning and is documented for each calibration run.
