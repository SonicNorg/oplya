# Phase 2: Plugin packaging — SessionStart hook + slash command shell - Research

**Researched:** 2026-05-28
**Domain:** Claude Code SessionStart hooks + flat-file slash commands + codex CLI presence/auth probing + LF-safe Bash hygiene
**Confidence:** HIGH (all answers anchored in `CLAUDE.md` § "Technology Stack" + Anthropic plugin docs cited there; no novel external research required for Phase 2)

<user_constraints>
## User Constraints (from CONTEXT.md)

All 24 decisions D-01..D-24 from `02-CONTEXT.md` are LOCKED. This research expands on the "Claude's Discretion" items and surfaces the live-spec details the planner needs.

</user_constraints>

<recommended_approach>
## Recommended Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Hook config | `plugins/zapili/hooks/hooks.json` with `SessionStart` matcher `"startup"` | Default-folder auto-discovery (Phase 1 D-10/D-24); startup-only avoids cost on resume/clear/compact. |
| Hook script | `plugins/zapili/scripts/check-codex.sh`, exit 0 always | ZAP-02 hard constraint — never brick Claude Code. |
| Preflight script | `plugins/zapili/scripts/preflight-codex.sh`, exit non-zero on failure | ZAP-01 hard constraint — fail-fast at command invocation. |
| Command file | `plugins/zapili/commands/zapili.md` (flat file with YAML frontmatter) | CLAUDE.md recommends flat-file form for v1; directory form deferred to Phase 4. |
| codex presence probe | `command -v codex` | POSIX, universal, no codex network call. |
| codex version probe | `codex --version` | Stable across codex 0.13x; non-zero exit on broken install. |
| codex auth/preflight | `codex exec --help >/dev/null 2>&1` | Cheap, no API call, validates the `exec` subcommand is reachable. |
| Plugin path resolution | `${CLAUDE_PLUGIN_ROOT}` always quoted | Plugins are cached under `~/.claude/plugins/cache/...`; relative paths break. |
| Hook stdin handling | `cat >/dev/null 2>&1 || true` early in script | Drains hook JSON payload to prevent SIGPIPE. |

</recommended_approach>

<code_examples>
## Canonical Snippets

### 1. `plugins/zapili/hooks/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### 2. `plugins/zapili/scripts/check-codex.sh` (advisory; always exit 0)

```bash
#!/usr/bin/env bash
set -uo pipefail

# Drain hook stdin (Claude Code writes hook JSON payload here).
cat >/dev/null 2>&1 || true

REMEDIATION=$(cat <<'EOF'
[zapili] codex CLI is required for the /zapili:zapili workflow.
Install one of:
  brew install --cask codex
  npm install -g @openai/codex
  curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-install.sh | sh
Then authenticate per https://developers.openai.com/codex/cli/reference
zapili is loaded but /zapili:zapili will fail-fast until codex is available.
EOF
)

if ! command -v codex >/dev/null 2>&1; then
  printf '%s\n' "$REMEDIATION" >&2
  exit 0
fi

if ! codex --version >/dev/null 2>&1; then
  printf '[zapili] codex is installed but failed to report version; check installation.\n' >&2
  exit 0
fi

# Success path: silent (no noise on every session start).
exit 0
```

### 3. `plugins/zapili/scripts/preflight-codex.sh` (strict; non-zero on failure)

```bash
#!/usr/bin/env bash
set -euo pipefail

REMEDIATION="See https://developers.openai.com/codex/cli/reference for install + auth."

if ! command -v codex >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: codex CLI not found on PATH.\n%s\n' "$REMEDIATION" >&2
  exit 2
fi

VERSION_OUT=$(codex --version 2>&1) || {
  printf '[zapili] preflight FAILED: codex --version failed: %s\n%s\n' "$VERSION_OUT" "$REMEDIATION" >&2
  exit 3
}

if ! codex exec --help >/dev/null 2>&1; then
  printf '[zapili] preflight FAILED: codex exec subcommand unavailable (auth or install issue).\n%s\n' "$REMEDIATION" >&2
  exit 4
fi

printf '[zapili] codex preflight OK (%s)\n' "$VERSION_OUT" >&2
exit 0
```

### 4. `plugins/zapili/commands/zapili.md`

```markdown
---
description: Run the zapili multi-agent development workflow on TASK.md
argument-hint: "[--resume]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)
---

# /zapili:zapili — multi-agent development workflow

Run the strict codex preflight, then (in this Phase-2 shell) print a stub message.
The full orchestrator lands in Phase 4.

## Step 1 — Preflight (mandatory)

Run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
If it exits non-zero, STOP and report the remediation printed by the script — do not continue.

## Step 2 — Phase-2 stub

If preflight succeeded, print:

> **zapili Phase 2 shell active.** Codex is available. The orchestrator (research → plan → wave-parallel implementation → review) is delivered in Phase 4. Until then `/zapili:zapili` only verifies pre-conditions.
```

</code_examples>

<common_pitfalls>
## Pitfalls to Avoid (anchored to CLAUDE.md "What NOT to Use")

1. **Setting non-zero exit in `check-codex.sh`** — `SessionStart` exit-2 surfaces stderr as a BLOCKING error, breaking unrelated Claude Code work. ZAP-02 forbids.
2. **Using `$(dirname "$0")` to locate sibling scripts** — plugin cache layout breaks `dirname`-based resolution. Use `${CLAUDE_PLUGIN_ROOT}` exclusively.
3. **Probing codex authentication via `codex exec "<prompt>"`** — consumes API tokens on every session start. `codex exec --help` is auth-agnostic and free.
4. **`set -e` (without `-uo pipefail`)** in scripts that intentionally tolerate sub-command failures (the advisory hook) — use `set -uo pipefail` (no `-e`) in the advisory script so a failing probe does not exit early; use full `set -euo pipefail` in the strict preflight.
5. **CRLF line endings in `.sh` files** — already prevented by Phase 1 `.gitattributes`, but new files MUST be created LF-only.
6. **Declaring `commands` or `hooks` keys in `plugin.json`** — Phase 1 D-10 / D-24 forbids; default auto-discovery handles new folders.
7. **Quoting `${CLAUDE_PLUGIN_ROOT}` only sometimes** — every expansion must be double-quoted, including inside the hook `command` string in `hooks.json`.
8. **Forgetting `cat >/dev/null` in the hook script** — Claude Code writes a JSON payload to hook stdin; ignoring it can SIGPIPE on later writes.

</common_pitfalls>

<open_questions>
## Open Questions (all resolved during this research)

1. **Q1: Should `check-codex.sh` emit `additionalContext` JSON on success?** — DEFERRED. CONTEXT § Specifics already marks this optional; planner may omit at Phase 2 and revisit during Phase 4 when the orchestrator can consume the context. No blocker.
2. **Q2: Does `allowed-tools` need to list every Bash pattern the command runs?** — YES. The slash command's `allowed-tools` frontmatter is a hard allowlist. We list `Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)` so the preflight runs without per-invocation approval; nothing else is permitted in Phase 2.
3. **Q3: Should the SessionStart hook also fire on `resume`?** — NO. Cost on every resume outweighs benefit; user re-invocation of `/zapili:zapili` will run the strict preflight anyway. CONTEXT D-01 locks `matcher: "startup"`.

</open_questions>

<package_audit>
## Package Legitimacy Audit

No new packages introduced. Phase 2 ships static config + bash scripts only. `codex` itself is a user prerequisite, not a Phase-2-installed dependency.

</package_audit>

<sources>
- `CLAUDE.md` § "Technology Stack" — `hooks.json` shape, `${CLAUDE_PLUGIN_ROOT}` semantics, exit-code rules, command frontmatter spec
- Claude Code plugins reference — `code.claude.com/docs/en/plugins-reference` (cached doctrine in CLAUDE.md)
- Claude Code hooks reference — exit-code semantics, JSON-on-stdin
- OpenAI codex CLI reference — `developers.openai.com/codex/cli/reference`
- Phase 1 `01-RESEARCH.md` Pitfalls 3 (CRLF) + 19 (global config writes) — already mitigated by `.gitattributes` and the no-global-state rule
</sources>
