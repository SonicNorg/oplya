---
phase: 02-plugin-packaging-sessionstart-hook-slash-command-shell
plan: 01
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/hooks/hooks.json
  - plugins/zapili/scripts/check-codex.sh
requirements_satisfied:
  - ZAP-02
  - ZAP-04 (partial — applied to check-codex.sh)
  - ZAP-05 (partial — applied to check-codex.sh)
---

# Plan 02-01 Summary — SessionStart advisory hook

## What was done

- Created `plugins/zapili/hooks/hooks.json` with a single `SessionStart` registration, `matcher: "startup"`, `timeout: 5`, command string `"${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh"` (quoted so spaces in CLAUDE_PLUGIN_ROOT do not break invocation).
- Created `plugins/zapili/scripts/check-codex.sh` — `#!/usr/bin/env bash`, `set -uo pipefail` (no `-e` — every failure path is handled), stdin drain, two probes (`command -v codex` then `codex --version`), ALWAYS exits 0. Remediation message printed to stderr on failure. Mode `100755` in the git index.

## Verification

- `jq -e . plugins/zapili/hooks/hooks.json` → OK
- `bash -n plugins/zapili/scripts/check-codex.sh` → OK
- `bash plugins/zapili/scripts/check-codex.sh </dev/null` → exit 0 in current env (codex on PATH; silent success path)
- `git ls-files --stage plugins/zapili/scripts/check-codex.sh` → mode `100755`
- LF only (`file` reports `ASCII text executable`, no CRLF)
- No references to `~/.claude/*` or `~/.config/codex/*` (ZAP-05)

## Decisions implemented

D-01..D-06 (hook config + advisory contract), D-15..D-18 (script hygiene applied to `check-codex.sh`), D-19 (no global state mutation).

## Deviations

None.
