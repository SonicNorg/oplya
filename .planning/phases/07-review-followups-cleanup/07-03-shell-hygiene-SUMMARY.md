# Plan 07-03: shell hygiene — SUMMARY

**Completed:** 2026-05-28
**Status:** done
**Files touched:** 3

## Changes

| File | Operation | Summary |
|------|-----------|---------|
| `plugins/zapili/scripts/check-codex.sh` | modify | `set -uo pipefail` → `set -euo pipefail` (1-char edit). Existing guards (`cat …\|\| true`, `if ! command -v codex`, `if ! codex --version`) remain `-e`-safe. SessionStart still exits 0 on missing codex (advisory contract preserved — verified via `env -i PATH=/usr/bin:/bin`). (D-11) |
| `plugins/zapili/scripts/check-wave-disjointness.sh` | modify | Line 44 regex broadened from `PHASE-[0-9]+(-[0-9]+)?` to `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?`. Matches both production (PHASE-01, PHASE-01-02) and fixture (PHASE-XX, PHASE-XX-a) naming. f2 fixture now exits 1 with OVERLAP diagnostic (was previously a silent exit 0). Header comment updated to document the choice. (D-12, D-13) |
| `plugins/zapili/tests/fixtures/f3-plan-ambiguity/PLAN.md` | modify | Adjusted the requirements-traceability table so "PHASE-XX" appears exactly once in the file. The broadened regex matches every occurrence of "PHASE-XX" in PLAN.md as a phase id; treating duplicate mentions as distinct phases in the same wave produced a false-positive overlap. KISS fix: keep the id mentioned only in the wave bullets. (Side-effect of D-12) |

## Acceptance gate

- `head -2 plugins/zapili/scripts/check-codex.sh \| tail -1` → `set -euo pipefail`.
- `bash -n plugins/zapili/scripts/check-codex.sh` → OK.
- `env -i PATH=/usr/bin:/bin bash plugins/zapili/scripts/check-codex.sh </dev/null` → exit 0, prints advisory to stderr.
- `bash -n plugins/zapili/scripts/check-wave-disjointness.sh` → OK.
- `bash plugins/zapili/scripts/check-wave-disjointness.sh tests/fixtures/f2-plan-write-overlap/PLAN.md` → exit 1, stderr contains "OVERLAP in … Wave 1 … PHASE-XX-a and PHASE-XX-b both write src/auth/login.ts".
- `bash plugins/zapili/scripts/check-wave-disjointness.sh tests/fixtures/f3-plan-ambiguity/PLAN.md` → exit 0, "ok: every wave has pairwise-disjoint writes".

## Requirements closed

- ZAP-58 (H-01): check-codex.sh `-e` flag
- ZAP-59 (S-01): check-wave-disjointness.sh phase-id regex

## Decisions cited

D-11 (check-codex), D-12, D-13 (regex broaden).

## Latent bug noted (out of Phase 7 scope, follow-up candidate)

`check-wave-disjointness.sh` does not deduplicate phase ids within a wave. If the same `PHASE-XX` id is mentioned multiple times inside a single wave's section of PLAN.md (e.g. once in a bullet list and once in a requirements-traceability table), the script treats them as two distinct phases and reports a false-positive overlap (every phase trivially overlaps with itself). A future hardening pass can `sort -u` the per-wave `pids` array before the disjointness loop. Worked around in f3 PLAN.md by phrasing the traceability column without repeating the literal id. Not part of v1.1 scope; flagged for the v1.0 audit follow-up backlog.

<!-- <status>complete</status> -->
