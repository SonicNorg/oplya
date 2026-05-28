# Plan 08-01: fixer script + fixer-role prompt — SUMMARY

**Completed:** 2026-05-28
**Status:** done
**Files touched:** 2

## Changes

| File | Operation | Summary |
|------|-----------|---------|
| `plugins/zapili/scripts/codex-self-fix.sh` | create | New 0755 LF bash wrapper implementing D-04..D-08. Signature `[--dry-run] <artifact_path> <validator_role> <prior_findings_json>`. Composes a fixer-role prompt (artifact verbatim + HIGH/MEDIUM findings jq-filtered with full remediation text + `<response><patch>...</patch></response>` output contract), invokes codex via `codex-review.sh`, extracts the patch via `perl -0777`, persists to `.zapili/codex-self-fix-attempt-N.patch`, runs `git apply --check` first then `git apply` (skipping the apply in `--dry-run` mode). Exit codes: 0 success, 1 empty patch, 2 codex failed, 4 git apply --check failed, 64 usage. (D-04..D-08) |
| `plugins/zapili/skills/orchestrator/references/codex-prompts.md` | modify | Added `### fixer` section after `### phase_reviewer` and before `## Reclassification rules`. Documents the fourth role's prompt shape, halt paths (table of exit codes), and the single-attempt rule. Cross-links to `codex-self-fix.sh`. CALIB-01 (SHA-256 ID derivation) explicitly noted as applying to fixer prior-id references. (D-01, D-02, D-03) |

## Acceptance gate

- `bash -n plugins/zapili/scripts/codex-self-fix.sh` → OK.
- `stat -c '%a' plugins/zapili/scripts/codex-self-fix.sh` → 755.
- `bash plugins/zapili/scripts/codex-self-fix.sh` → exit 64 with usage line.
- `head -2 plugins/zapili/scripts/codex-self-fix.sh | tail -1` → `set -euo pipefail`.
- `grep -q '### fixer' plugins/zapili/skills/orchestrator/references/codex-prompts.md` → match.
- `grep -q '<patch>' plugins/zapili/skills/orchestrator/references/codex-prompts.md` → match.
- `grep -q 'CALIB-01' plugins/zapili/skills/orchestrator/references/codex-prompts.md` → match.

## Requirements progressed

- ZAP-60 acceptance #1 (codex-self-fix.sh wrapper signature + exit codes + dry-run): COMPLETE for this plan's scope.
- ZAP-60 acceptance #4 (fixer documented as fourth role; SHA-256 ID rule applies): COMPLETE.

(ZAP-60 acceptance #2 — orchestrator wiring — and #3 — dry-run-before-apply discipline — and #5 — f6 fixture round-trip — are handled in plans 08-02 and 08-03.)

## Decisions cited

D-01, D-02, D-03 (fixer prompt + ID rule); D-04, D-05, D-06, D-07, D-08 (wrapper signature, prompt composition, attempt counter, git apply gating, exit codes).

<!-- <status>complete</status> -->
