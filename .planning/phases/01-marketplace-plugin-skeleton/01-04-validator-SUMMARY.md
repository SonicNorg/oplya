---
phase: 01-marketplace-plugin-skeleton
plan: 04
subsystem: infra
tags: [bash, jq, git-hooks, validation, pre-commit]

requires:
  - phase: 01-01-manifests
    provides: real .claude-plugin/marketplace.json + plugins/zapili/.claude-plugin/plugin.json that the validator must accept
  - phase: 01-03-hygiene
    provides: .gitattributes enforcing LF on *.sh — guarantees scripts/*.sh ship with LF on first add (RESEARCH Pitfall 11)
provides:
  - bash + jq manifest validator (scripts/validate-manifests.sh) that surfaces ALL failures in one pass
  - fixture-driven test driver (scripts/test-validator.sh) that regression-guards RESEARCH Pitfall 7
  - three golden-bad fixtures (missing-name, trailing-comma, invalid-source) exercising distinct failure modes
  - opt-in idempotent installer (scripts/install-hooks.sh) that wires scripts/pre-commit into .git/hooks/pre-commit
  - pre-commit dispatcher template (scripts/pre-commit) gated to manifest-touching commits only
affects: [phase-02-hook-and-command, phase-03-schemas-and-contracts, future-TOOL-hardening]

tech-stack:
  added: [bash 5+, jq 1.7+, git-hook dispatch pattern]
  patterns:
    - "Validator loop: collect-then-report (NO set -e). errors counter incremented per failure; final exit code derived once."
    - "Idempotent install: cmp -s for byte-equality, diff + abort on divergence — never silently clobber."
    - "Gated hook: git diff --cached --diff-filter=ACMR | grep -qE '...manifest paths...' before invoking heavy work."
    - "Fixture-driven shell tests: mktemp -d shadow repo + EXIT trap cleanup + explicit Test A/B/C assertions."

key-files:
  created:
    - scripts/validate-manifests.sh
    - scripts/test-validator.sh
    - scripts/install-hooks.sh
    - scripts/pre-commit
    - scripts/fixtures/bad-missing-name.json
    - scripts/fixtures/bad-trailing-comma.json
    - scripts/fixtures/bad-invalid-source.json
  modified: []

key-decisions:
  - "Validator pragma set -uo pipefail only — DELIBERATELY omits -e so the validation loop surfaces every failure in one pass (RESEARCH Pitfall 7). test-validator.sh Test A regression-guards this with deliberately-double-broken fixtures and asserts grep -c FAIL: >= 2."
  - "Test driver uses set -euo pipefail (fail-fast on its own assertions). The set -e prohibition applies ONLY to validate-manifests.sh."
  - "bad-invalid-source.json is informational — current D-12 minimal validator does NOT check source-path safety; fixture documents the surface for future TOOL-* hardening. Driver explicitly comments this so future readers do not treat its presence as a missing check."
  - "Installer's idempotence smoke (install -> no-op -> divergence-abort -> restore) was run in-place against the real .git/hooks/pre-commit. The hook is currently INSTALLED — reversible by deleting .git/hooks/pre-commit. Verified one round-trip ended on byte-identical template."

patterns-established:
  - "Plan-04 Validator-NO-set-e pattern: any future shell script that must surface multiple failures in one pass uses set -uo pipefail + an errors counter + a fail() helper. Lock this in writing in CONTEXT for any future validator-style scripts."
  - "Plan-04 Install-without-clobber pattern: every installer script writing to dot-files MUST use cmp -s and abort with diff on divergence."
  - "Plan-04 Fixture-driver pattern: shell test drivers shadow the real layout in mktemp -d with EXIT-trap cleanup; assertions print which test failed and exit 1; happy path uses the real artifacts."

requirements-completed: [MKT-07, MKT-08]

duration: 6min
completed: 2026-05-28
---

# Phase 01 Plan 04: Validator Summary

**Bash + jq marketplace-manifest validator with `set -e`-free multi-failure surfacing, fixture-driven regression guard, and idempotent pre-commit installer that aborts on user-hook divergence.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-27T21:38:55Z
- **Completed:** 2026-05-27T21:44:57Z
- **Tasks:** 3 (sequential, all auto)
- **Files created:** 7

## Accomplishments

- `scripts/validate-manifests.sh` exits 0 against the real in-repo manifests; exits 1 with one `FAIL:` line per problem against broken inputs.
- `scripts/test-validator.sh` runs three test cases — A (Pitfall-7 multi-failure regression: `grep -c FAIL: == 2`), B (missing-`name` remediation string), C (real-manifest happy path) — all green.
- `scripts/install-hooks.sh` smoke-tested through the full idempotence cycle: install (exit 0, "installed") → byte-identical no-op (exit 0, "already installed (byte-identical)") → user-modified divergence (exit 1 with unified diff on stderr) → restore.
- Hook is currently installed at `.git/hooks/pre-commit` and is byte-identical to the committed template (reversible: `rm .git/hooks/pre-commit`).
- Phase-1 success criterion #4 satisfied: contributor workflow now has an automated per-commit gate that blocks malformed manifests before they reach `/plugin marketplace add`.

## Task Commits

1. **Task 1: Write `scripts/validate-manifests.sh`** — `78546c4` (feat)
2. **Task 2: Write fixtures + `scripts/test-validator.sh`** — `20aa56b` (test)
3. **Task 3: Write `scripts/install-hooks.sh` + `scripts/pre-commit`** — `f727da8` (feat)

**Plan metadata:** [to be added by final commit]

## Files Created/Modified

- `scripts/validate-manifests.sh` — bash+jq validator; `set -uo pipefail` only; jq probe with remediation; per-manifest loop with collected errors; exit 0/1.
- `scripts/test-validator.sh` — three-test fixture-driven driver; mktemp shadow repo; EXIT-trap cleanup; assertions per test case.
- `scripts/install-hooks.sh` — git-repo guard; template-existence guard; cmp -s idempotence; diff+abort on divergence; never clobbers.
- `scripts/pre-commit` — thin dispatcher: extracts staged files via `git diff --cached --name-only --diff-filter=ACMR`, regex-matches manifest paths, `exec`s validator only when needed (no-op otherwise).
- `scripts/fixtures/bad-missing-name.json` — valid JSON, missing required `.name` (asserts `require_field` fires).
- `scripts/fixtures/bad-trailing-comma.json` — invalid JSON (trailing comma) shaped like a marketplace.json (asserts `jq -e .` parse fails).
- `scripts/fixtures/bad-invalid-source.json` — valid JSON with `../bad/y` source path; informational — out of D-12 scope; fixture for future TOOL-* hardening.

## Decisions Made

- **Validator pragma is `set -uo pipefail` only.** The `e` flag is intentionally absent because the validation loop must surface ALL failures in one pass (RESEARCH Pitfall 7). The plan's acceptance criterion `! grep -qE '^set -[a-z]*e[a-z]*( |$)' scripts/validate-manifests.sh` guards this against future regressions.
- **Test driver uses `set -euo pipefail`.** The `e` ban applies only to `validate-manifests.sh`; the driver wants fail-fast on its own assertion errors.
- **`bad-invalid-source.json` is informational only.** The current validator (D-12 minimum) does not check source-path safety; this fixture is committed to document the future TOOL-* hardening surface. `test-validator.sh` explicitly prints a note that this fixture is informational, so a future reader does not treat its presence as a missing check.
- **Installer smoke run mutated `.git/hooks/pre-commit` on this developer machine (per CONSTRAINT 6 warning).** Mutation is intentional and reversible: the hook ended the smoke test byte-identical to the committed template (verified via `cmp -s scripts/pre-commit .git/hooks/pre-commit`). Reversible with `rm .git/hooks/pre-commit`. Side-effect was triggered by the Plan's acceptance-criteria smoke (install → no-op → divergence-abort) — not by SUMMARY/STATE commit hooks (no manifests staged).

## Deviations from Plan

None — plan executed exactly as written. Zero auto-fixes; zero blockers.

## Issues Encountered

None.

## User Setup Required

None — `bash` and `jq` are pre-existing host tools (jq 1.7 confirmed on the executor host).

To activate the per-commit gate on a fresh clone, contributors run once:

```bash
./scripts/install-hooks.sh
```

This is opt-in (D-19) and documented in the top-level `README.md` "Local development" section (Plan 01-02).

## Verification Block (from PLAN.md)

- [x] `bash scripts/validate-manifests.sh` exits 0 against the real repo manifests.
- [x] `bash scripts/test-validator.sh` exits 0 — Test A (Pitfall 7) sees exit=1 + `FAIL:` lines=2; Test B sees exit=1 + missing-field remediation string; Test C sees exit=0 + ok message.
- [x] `scripts/install-hooks.sh` idempotence: first run → exit 0 "installed"; second run → exit 0 "already installed (byte-identical)"; third run (after user mutation) → exit 1 with unified diff.
- [x] All four `scripts/*.sh` files: mode 0755, `#!/usr/bin/env bash` shebang, LF endings (no CRLF).
- [x] Three fixtures present in `scripts/fixtures/` exercising distinct failure modes.

## Threat Mitigations Honored

| Threat | Disposition | Implementation |
|---|---|---|
| T-04-01 (Code Execution via JSON) | mitigate | `jq -e .` parse-only; no `eval`; every `"$file"` / `"$manifest"` expansion double-quoted. |
| T-04-02 (Tampering: stop-at-first-failure) | mitigate | No `set -e` in validator loop; `test-validator.sh` Test A asserts `grep -c FAIL: >= 2`. |
| T-04-03 (Tampering: silent clobber) | mitigate | `cmp -s` byte-equality; diff + abort on divergence. |
| T-04-04 (DoS: installer outside git) | mitigate | `git rev-parse --git-dir` pre-flight guard. |
| T-04-05 (Repudiation: missing jq) | mitigate | Up-front `command -v jq`; exit 1 with install remediation. |
| T-04-06 (CRLF interpreter spoof) | mitigate | Plan 03's `.gitattributes` enforces LF on `*.sh` on add; no `file ... | grep CRLF` matches. |
| T-04-SC (npm/pip/cargo installs) | accept | Plan 04 adds zero package-manager dependencies. |

## Self-Check

Verified files exist:
- [x] scripts/validate-manifests.sh — FOUND
- [x] scripts/test-validator.sh — FOUND
- [x] scripts/install-hooks.sh — FOUND
- [x] scripts/pre-commit — FOUND
- [x] scripts/fixtures/bad-missing-name.json — FOUND
- [x] scripts/fixtures/bad-trailing-comma.json — FOUND
- [x] scripts/fixtures/bad-invalid-source.json — FOUND

Verified commits exist:
- [x] 78546c4 — FOUND
- [x] 20aa56b — FOUND
- [x] f727da8 — FOUND

## Self-Check: PASSED

## Next Phase Readiness

- Phase 1 only has one plan left (Plan 01-05, retrospective/handoff per ROADMAP). All static-skeleton requirements satisfied (manifests, READMEs, hygiene, validator); installable end-to-end via `/plugin marketplace add nepavel/oplya` + `/plugin install zapili@oplya`.
- Phase 2 will populate `plugins/zapili/hooks/` and `plugins/zapili/commands/`. The validator does not yet inspect those folders — D-12 keeps it strictly to manifest required-fields; Phase 2 will add a `claude plugin validate --strict` cross-check as documented in the top-level README.
- No blockers; no concerns.

---
*Phase: 01-marketplace-plugin-skeleton*
*Plan: 04-validator*
*Completed: 2026-05-28*
