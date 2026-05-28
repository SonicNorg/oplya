---
phase: 01-marketplace-plugin-skeleton
plan: 05
subsystem: infra
tags: [marketplace, install, rehearsal, manual-verify, claude-code]

requires:
  - phase: 01-01
    provides: marketplace.json + plugin.json manifests under test
  - phase: 01-02
    provides: top-level + plugin README install instructions referenced in rehearsal
  - phase: 01-03
    provides: LICENSE / .gitignore / .gitattributes (clone hygiene)
  - phase: 01-04
    provides: validate-manifests.sh, test-validator.sh, install-hooks.sh, pre-commit hook used in Step 3
provides:
  - Live end-to-end attestation that `/plugin marketplace add` + `/plugin install zapili@oplya` succeed in a fresh clone
  - Dated rehearsal log establishing the auditable Phase-1-shipped baseline for future regressions
affects: [phase-02-orchestrator, phase-06-release]

tech-stack:
  added: []
  patterns:
    - manual-rehearsal-with-log-stamp — human verification recorded in a dated `*-rehearsal-LOG.md`, paired with an automated preflight matrix run by the executor right before the human gate

key-files:
  created:
    - .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md
  modified: []

key-decisions:
  - "Minimal-stamp mode accepted for v1 — operator (PP) verbally confirmed PASS without pasting full transcripts; preflight gate matrix + sign-off line are the audit record. Risk explicitly accepted (success criteria 1+2 attested, not transcript-proven). Future rehearsals on subsequent commits may re-run with full transcript capture if needed."
  - "The single `--strict` warning on `plugins/zapili/.claude-plugin/plugin.json` (`No version specified`) is acknowledged as expected per D-09 (commit-SHA versioning) and is NOT treated as a rehearsal failure. The `must_haves.truths[2]` plan-level claim of `zero warnings` is in known tension with D-09; D-09 wins as the older, project-level decision."

patterns-established:
  - "Plan pattern: autonomous preflight task → human-checkpoint task → autonomous log-commit task. The preflight catches everything scriptable so the human only ever runs the genuinely-non-scriptable steps; the log commit is data-only so it can resume cleanly after an arbitrary delay at the checkpoint."

requirements-completed:
  - MKT-07

duration: ~8min
completed: 2026-05-28
---

# Phase 01 Plan 05: Install Rehearsal Summary

**Phase 1's only live-runtime verification — `/plugin marketplace add nepavel/oplya` + `/plugin install zapili@oplya` confirmed to resolve end-to-end in a fresh Claude Code session; supplementary `claude plugin validate --strict` and pre-commit hook rejection both verified.**

## Performance

- **Duration:** ~8 min (preflight ~2 min auto, human rehearsal ~5 min, log commit ~1 min)
- **Started:** 2026-05-28T06:00:00Z (preflight dispatch)
- **Completed:** 2026-05-28T06:05:00Z (operator `approved`)
- **Tasks:** 3 / 3 (1 preflight, 1 human checkpoint, 1 log commit)
- **Files modified:** 1 created (rehearsal log)

## Accomplishments

1. **Preflight gate matrix — 9/9 PASS** (executed by automated preflight task before the human gate):
   - Both manifests parse as strict JSON.
   - `owner.url` absent from `marketplace.json` (RESEARCH Pitfall 1 drift fix verified).
   - `category` AND `version` absent from `plugin.json` (Q2 + D-09 drift fixes verified).
   - `bash scripts/validate-manifests.sh` exits 0 (`ok: all manifests valid`).
   - `bash scripts/test-validator.sh` Tests A/B/C green; Pitfall-7 multi-failure proven by `grep -c FAIL: ≥ 2` against deliberately-double-broken fixtures.
   - All 6 hygiene/doc files present.
   - `plugins/zapili/` leaf count == exactly 2 (D-23 minimalism — no `commands/`, `agents/`, `hooks/`, `mcpServers/`, `schemas/`, `skills/`, `tests/` directories).
   - `.git/hooks/pre-commit` installed byte-identical to `scripts/pre-commit`.
   - Pre-commit refuses a deliberately broken manifest with the expected `FAIL: ... invalid JSON` message + exit 1.

2. **Live rehearsal in fresh Claude Code session — PASS** (operator attested):
   - `/plugin marketplace add .` succeeded with zero validation errors against a fresh `/tmp/oplya-rehearsal` clone of dev SHA `61f7694`.
   - `/plugin marketplace list` showed `oplya`.
   - `/plugin install zapili@oplya` resolved successfully.
   - `/plugin list` showed `zapili` under `oplya`.
   - `/zapili:zapili` deliberately not invoked (Phase 2 surface).

3. **Strict validation — PASS** (operator attested):
   - `claude plugin validate . --strict` clean.
   - `claude plugin validate ./plugins/zapili --strict` emitted exactly one expected warning (`No version specified`) per D-09; no `owner.url`, no `category`, no other drift warnings.

4. **Pre-commit hook end-to-end — PASS** (operator attested):
   - `./scripts/install-hooks.sh` installed cleanly.
   - `git commit` against a trailing-comma-corrupted manifest refused with the validator's `FAIL:` message + exit 1.

5. **Audit log written:** `.planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md` stamped `Phase 1 rehearsal: PASS — PP — 2026-05-28`.

## Deviations

- **Minimal-stamp mode** (operator decision via AskUserQuestion answer): full session transcripts were not captured into the log. The preflight gate matrix + operator attestation are the audit record. This is documented at the top of the LOG file and in `key-decisions` above. Acceptable for v1 of a personal marketplace; not recommended for compliance contexts.

## Phase 1 success criteria coverage

| # | Criterion | Status |
|---|---|---|
| 1 | `/plugin marketplace add <oplya-repo>` recognized, zero validation errors | ✅ attested |
| 2 | `/plugin install zapili@oplya` resolves; `zapili` visible to Claude Code | ✅ attested |
| 3 | Top-level README + plugin README (English) describe marketplace + install + codex prereq | ✅ via Plan 01-02 |
| 4 | `scripts/validate-manifests.sh` parses both manifests; exit 0/1; only required pre-commit gate | ✅ via Plan 01-04 |
| 5 | `LICENSE` + curated `.gitignore` + `.gitattributes` (`*.sh`/`*.bash` LF) present | ✅ via Plan 01-03 |

## Handoff

Phase 1 is shippable. Next phase (02) handles the `zapili` slash-command surface (`commands/`, `agents/`, `hooks/` get populated). The pre-commit hook is now installed on the dev repo (`.git/hooks/pre-commit`) and will gate every commit going forward.
