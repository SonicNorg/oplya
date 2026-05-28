---
phase: 02-plugin-packaging-sessionstart-hook-slash-command-shell
plan: 02
status: complete
completed: 2026-05-28
files_modified:
  - plugins/zapili/scripts/preflight-codex.sh
  - plugins/zapili/commands/zapili.md
  - plugins/zapili/README.md
requirements_satisfied:
  - ZAP-01
  - ZAP-04 (preflight-codex.sh hygiene)
  - ZAP-05 (no global state mutation)
---

# Plan 02-02 Summary — preflight + slash command shell + README update

## What was done

- Created `plugins/zapili/scripts/preflight-codex.sh` — `#!/usr/bin/env bash`, `set -euo pipefail`, distinct exit codes (2 = missing, 3 = `--version` broken, 4 = `exec` subcommand unavailable). Uses `codex exec --help` for auth verification — cheap and free. Mode `100755` in the git index.
- Created `plugins/zapili/commands/zapili.md` — flat-file slash command with YAML frontmatter (`description`, `argument-hint: "[--resume]"`, `allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)`). Body runs the strict pre-flight, halts on non-zero, and prints a Phase-2 stub on success.
- Updated `plugins/zapili/README.md` — removed Phase-1 placeholder ("slash command surface is not yet wired"); added `## Usage` and `## Pre-flight` sections describing the two-level codex check. File is now 47 lines (under the ≤100 cap).

## Verification

- `bash -n plugins/zapili/scripts/preflight-codex.sh` → OK
- `CLAUDE_PLUGIN_ROOT="$(pwd)/plugins/zapili" bash plugins/zapili/scripts/preflight-codex.sh` → exit 0 (codex 0.133.0 on PATH)
- Slash command frontmatter parses (first line `---`, `description`/`argument-hint`/`allowed-tools` keys present)
- README "not yet wired" line absent; `## Usage` and `## Pre-flight` present
- Phase-1 validator (`./scripts/validate-manifests.sh`) still passes (no manifest regressions)

## Decisions implemented

D-07..D-14 (preflight + slash command), D-15..D-18 (script hygiene applied to `preflight-codex.sh`), D-19, D-20 (no global config touches), D-21, D-22 (README + no `.gitkeep`).

## Deviations

None.
