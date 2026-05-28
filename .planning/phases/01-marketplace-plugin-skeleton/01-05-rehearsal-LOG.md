# Phase 01 Plan 05 — Install Rehearsal Log

## Rehearsal stamp

- Date: 2026-05-28
- Operator: Pavel
- Operator initials: PP
- Dev repo SHA at rehearsal: `61f769407606720d7adce20eb099ec8b42a16cc4` (`61f7694`)
- Rehearsal clone path: `/tmp/oplya-rehearsal`
- Log mode: **minimal stamp** — operator confirmed end-to-end PASS verbally (`approved`); full transcripts not captured. Per `01-VALIDATION.md` manual-only-verifications policy, sign-off is the load-bearing record; transcripts are evidentiary backup.

## Preflight gate matrix (recorded by automated executor at 2026-05-28T06:02Z)

| # | Check | Result |
|---|---|---|
| 1 | `jq -e .` on both manifests | PASS |
| 2 | `owner.url` absent from `marketplace.json` (RESEARCH Pitfall 1 drift fix) | PASS |
| 3 | `category` and `version` absent from `plugin.json` (Q2 + D-09) | PASS |
| 4 | `bash scripts/validate-manifests.sh` | PASS (`ok: all manifests valid`) |
| 5 | `bash scripts/test-validator.sh` | PASS (Tests A/B/C green; Pitfall-7 multi-failure proven by `grep -c FAIL: ≥ 2`) |
| 6 | `README.md`, `plugins/zapili/README.md`, `LICENSE`, `.gitignore`, `.gitattributes` present | PASS |
| 7 | `plugins/zapili/` leaf count == exactly 2 (`.claude-plugin/plugin.json` + `README.md`) — D-23 minimalism | PASS |
| S1 | `.git/hooks/pre-commit` installed, byte-identical to `scripts/pre-commit` | PASS |
| S2 | Pre-commit refuses a deliberately broken manifest end-to-end | PASS |

## Live rehearsal — operator attestation

Operator (PP) ran the following in a fresh Claude Code session against a clean clone at `/tmp/oplya-rehearsal` and reports all expected outcomes were observed:

### Step 1 — `/plugin marketplace add .`, `/plugin marketplace list`, `/plugin install zapili@oplya`, `/plugin list`

Outcome: PASS — `oplya` recognized with zero validation errors; `zapili@oplya` resolved and installed; appears in `/plugin list` under the `oplya` marketplace. `/zapili:zapili` invocation deliberately NOT attempted (Phase 2 surface).

### Step 2 — `claude plugin validate . --strict` and `claude plugin validate ./plugins/zapili --strict`

Outcome: PASS — marketplace strict-validation clean; plugin strict-validation emits exactly one expected warning (`No version specified`) per D-09 commit-SHA versioning. No `owner.url`, no `category`, no other unrecognized-field warnings.

### Step 3 — Pre-commit hook end-to-end (deliberately broken manifest)

Outcome: PASS — `./scripts/install-hooks.sh` installs; `git commit` against a trailing-comma-corrupted `marketplace.json` is refused with `FAIL: .claude-plugin/marketplace.json: invalid JSON (jq parse failed)` on stderr, exit code 1; clean-up restores the manifest.

## Sign-off

Phase 1 rehearsal: **PASS** — PP — 2026-05-28

> Minimal-stamp mode: full transcripts not retained per operator decision. The preflight gate matrix above + operator attestation constitute the audit record. If full transcripts are needed for compliance or post-mortem, rerun the rehearsal against any subsequent commit and capture verbatim outputs into Step 1 / Step 2 / Step 3 sections.
