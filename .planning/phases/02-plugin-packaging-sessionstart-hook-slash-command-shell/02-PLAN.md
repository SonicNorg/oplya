---
phase: 02-plugin-packaging-sessionstart-hook-slash-command-shell
type: overview
plans: 2
waves: 1
requirements:
  - ZAP-01
  - ZAP-02
  - ZAP-04
  - ZAP-05
---

# Phase 2 Plan: Plugin packaging — SessionStart hook + slash command shell

**Created:** 2026-05-28
**Goal:** `/zapili:zapili` is discoverable after `/plugin install`; its strict pre-flight verifies codex at command time; the `SessionStart` hook is advisory-only and never bricks Claude Code; all `scripts/*.sh` follow LF-only / `set -euo pipefail` / `${CLAUDE_PLUGIN_ROOT}` discipline.

## Wave Structure

### Wave 1 (parallel-safe — disjoint file scopes)

- **02-01** — `hooks/hooks.json` + `scripts/check-codex.sh` (advisory side; ZAP-02)
- **02-02** — `scripts/preflight-codex.sh` + `commands/zapili.md` + README update (strict side + command shell + README; ZAP-01, ZAP-04, ZAP-05, ZAP-03 housekeeping)

Wave 1 is the only wave. The two plans touch disjoint file sets:

| Plan | Writes | Reads |
|------|--------|-------|
| 02-01 | `plugins/zapili/hooks/hooks.json`, `plugins/zapili/scripts/check-codex.sh` | `.planning/phases/02-.../02-CONTEXT.md`, `02-RESEARCH.md`, `CLAUDE.md` |
| 02-02 | `plugins/zapili/scripts/preflight-codex.sh`, `plugins/zapili/commands/zapili.md`, `plugins/zapili/README.md` | same |

Pairwise write-set intersection: ∅. Mechanical disjointness verified.

## Decision Coverage

Decisions D-01..D-24 from `02-CONTEXT.md` are covered as follows:

- **Plan 02-01 covers:** D-01, D-02, D-03, D-04, D-05, D-06, D-15, D-16, D-17, D-18, D-19, D-22 (advisory hook + script hygiene applied to `check-codex.sh`)
- **Plan 02-02 covers:** D-07, D-08, D-09, D-10, D-11, D-12, D-13, D-14, D-15, D-16, D-17, D-18, D-19, D-20, D-21 (strict preflight + command shell + README; script-hygiene D-15..D-18 reapplied to `preflight-codex.sh`)
- **Cross-cutting (both plans):** D-22 (README touched only by Plan 02-02; D-22's "no .gitkeep" rule applies trivially because both plans create only real files), D-23 (single-wave structure), D-24 (no install rehearsal in Phase 2)

All 24 D-IDs cited verbatim.

## Requirements Coverage

| REQ-ID | Plan | Notes |
|--------|------|-------|
| ZAP-01 | 02-02 | `/zapili:zapili` discoverable + strict preflight + stub body |
| ZAP-02 | 02-01 | SessionStart hook advisory-only (exit 0) |
| ZAP-04 | 02-01, 02-02 | LF + `#!/usr/bin/env bash` + `${CLAUDE_PLUGIN_ROOT}` + mode 0755 (every new script) |
| ZAP-05 | 02-01, 02-02 | No writes to `~/.claude/*` or `~/.config/codex/*` (probe via `--help` only) |

## Verification (phase-level)

After both plans complete:

1. `bash -n plugins/zapili/scripts/check-codex.sh` and `bash -n plugins/zapili/scripts/preflight-codex.sh` (syntax-only) exit 0.
2. `jq -e . plugins/zapili/hooks/hooks.json >/dev/null` exits 0.
3. `head -1 plugins/zapili/scripts/check-codex.sh` and `head -1 plugins/zapili/scripts/preflight-codex.sh` print `#!/usr/bin/env bash`.
4. `git ls-files --stage plugins/zapili/scripts/check-codex.sh plugins/zapili/scripts/preflight-codex.sh | awk '{print $1}'` prints `100755` on both lines.
5. `file plugins/zapili/scripts/*.sh | grep -v CRLF` shows no CRLF.
6. `grep -RIn 'CLAUDE_PLUGIN_ROOT' plugins/zapili/hooks plugins/zapili/scripts plugins/zapili/commands` shows the variable used (no relative `./` script invocations).
7. `grep -RIn '~/\.claude\|~/\.config/codex\|HOME/\.claude\|HOME/\.config/codex' plugins/zapili/scripts plugins/zapili/hooks` returns no matches (ZAP-05).
8. `bash plugins/zapili/scripts/check-codex.sh </dev/null` exits 0 even when CLAUDE_PLUGIN_ROOT is unset (advisory contract).
9. With codex on PATH: `CLAUDE_PLUGIN_ROOT=$(pwd)/plugins/zapili bash plugins/zapili/scripts/preflight-codex.sh` exits 0.
10. Slash command file parses as valid Markdown with YAML frontmatter (`head -1 plugins/zapili/commands/zapili.md` is `---`).
