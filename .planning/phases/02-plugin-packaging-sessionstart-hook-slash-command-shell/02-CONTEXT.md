# Phase 2: Plugin packaging — SessionStart hook + slash command shell - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution (smart-discuss skipped — decisions derived from ROADMAP success criteria + CLAUDE.md tech-stack canon + Phase 1 patterns)

<domain>
## Phase Boundary

`zapili` exposes a working `/zapili:zapili` slash command shell whose strict pre-flight verifies `codex` availability at command time, while the `SessionStart` hook is advisory-only and never bricks Claude Code. The orchestrator body remains a stub that delegates downstream (Phase 4 fills in real workflow). All `scripts/*.sh` files follow strict shell hygiene (`set -euo pipefail`, LF-only, `${CLAUDE_PLUGIN_ROOT}`, mode 0755).

**In scope:**
- `plugins/zapili/hooks/hooks.json` — `SessionStart` event registration
- `plugins/zapili/scripts/check-codex.sh` — advisory codex CLI presence + auth probe (exit 0 always)
- `plugins/zapili/scripts/preflight-codex.sh` — strict pre-flight used by slash command (exit non-zero on failure)
- `plugins/zapili/commands/zapili.md` — flat-file slash command shell (frontmatter + body) that runs preflight then prints a Phase-2 stub message ("orchestrator coming in Phase 4")
- Shared shell utilities if needed (only if reused — KISS)
- Documentation update to `plugins/zapili/README.md` removing the "command not yet wired" note from Phase 1 and replacing it with the actual command surface

**Out of scope (later phases):**
- Orchestrator skill body, researcher/planner/engineer agents (Phase 4+)
- JSON Schemas and contract reference docs (Phase 3)
- `.zapili/state.json` write logic (Phase 4)
- codex review wrappers (`codex-review.sh`, `codex-validate-*.sh`) — Phase 4+
- Reserved-name verification, CHANGELOG, semver bump checks (Phase 6 polish)

</domain>

<decisions>
## Implementation Decisions

### SessionStart hook — advisory only (ZAP-02)
- **D-01:** Hook file: `plugins/zapili/hooks/hooks.json` — exactly one `SessionStart` registration with `matcher: "startup"` (not `"startup|resume"` — startup-only keeps cost minimal and matches the CLAUDE.md Tech Stack guidance).
- **D-02:** Hook command: `"${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh"` (always quoted, single string — no `bash -c` wrapper).
- **D-03:** Hook timeout: `5` seconds — plenty for two `command -v` / `codex --version` probes.
- **D-04:** Hook script `check-codex.sh` ALWAYS exits 0. Failure modes (codex missing, codex not authenticated, codex version too old) print an advisory message to stderr via `>&2` and may emit `additionalContext` JSON on stdout for the model — but they NEVER set a non-zero exit code. Bricking Claude Code on a missing optional tool is a hard PROJECT rule.
- **D-05:** Detection logic in `check-codex.sh`:
  - `command -v codex` → if missing, print remediation and exit 0
  - If present, `codex --version` → if non-zero, print "codex is installed but failed to report version; check installation" and exit 0
  - Do NOT probe authentication (codex auth check would require a live API call, too slow for a startup hook; the strict preflight handles auth)
- **D-06:** `check-codex.sh` drains stdin with `cat >/dev/null 2>&1 || true` to prevent SIGPIPE when the hook framework writes hook context as JSON to stdin and the script does not consume it.

### Strict pre-flight — fail-fast (ZAP-01)
- **D-07:** Pre-flight script: `plugins/zapili/scripts/preflight-codex.sh` — separate from `check-codex.sh` because the contracts differ (advisory vs strict). Sharing code via a sourced helper is not worth the indirection at v1; both scripts are short.
- **D-08:** Pre-flight detection logic:
  - `command -v codex` → exit 2 with remediation if missing
  - `codex --version` → exit 3 if it fails
  - Authentication probe: `codex exec --help >/dev/null 2>&1` → exit 4 if it fails (cheap, does not consume API tokens)
  - On success: print one line "codex preflight: OK (version X.Y.Z)" to stderr and exit 0
- **D-09:** Remediation messages are multi-line, printed once, and include the canonical install command (`brew install --cask codex` OR `npm install -g @openai/codex` OR `curl ... | sh`) plus a link to the codex docs.
- **D-10:** Pre-flight is invoked from the slash command body via a Bash block; on non-zero exit the slash command prints "Pre-flight failed — see above for remediation" and stops. No retries, no fallback.

### Slash command shell (ZAP-01)
- **D-11:** File: `plugins/zapili/commands/zapili.md` — flat-file form (not `skills/zapili/SKILL.md` directory form). Per CLAUDE.md guidance, flat file is the v1 default; migrate to directory form only when supporting prompts are added (Phase 4+).
- **D-12:** YAML frontmatter fields:
  - `description: "Run the zapili multi-agent development workflow on TASK.md"`
  - `argument-hint: "[--resume]"` (placeholder for Phase 6 resume; no behavior change in Phase 2)
  - `allowed-tools: Bash(./scripts/preflight-codex.sh:*)` — restrictive so Phase 2 cannot accidentally do anything else
  - No `model`, no `effort` overrides — inherit caller's settings
- **D-13:** Command body (post-frontmatter Markdown):
  1. Brief one-paragraph header: "This is the `/zapili:zapili` command — see plugin README for the full workflow."
  2. Pre-flight step instruction: run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh` via Bash; on non-zero stop and print remediation
  3. Phase-2 stub: print "Phase 2 shell active — orchestrator implementation lands in Phase 4. Pre-flight passed; codex is available."
  4. NO real workflow logic — that is Phase 4's job
- **D-14:** Invocation path: `/zapili:zapili` (namespace = plugin name, command = file basename). Verified by ZAP-01 acceptance criterion #1.

### Shell hygiene (ZAP-04)
- **D-15:** Every `scripts/*.sh` file:
  - First line: `#!/usr/bin/env bash`
  - Second non-empty line: `set -euo pipefail`
  - LF line endings (enforced by Phase 1's `.gitattributes`)
  - Committed with mode `100755` (`git update-index --chmod=+x` if needed)
- **D-16:** All plugin-local paths reference `${CLAUDE_PLUGIN_ROOT}` exclusively. Forbidden: `./relative/path`, `$PWD`, `$(dirname "$0")`-based path tricks (cache layout breaks `dirname` resolution). Acceptable: `${CLAUDE_PLUGIN_ROOT}/scripts/foo.sh`, `${CLAUDE_PLUGIN_ROOT}/schemas/x.json`.
- **D-17:** Quoting: every variable expansion is double-quoted (`"${CLAUDE_PLUGIN_ROOT}"`, `"${VAR:-default}"`). ShellCheck-clean if a contributor runs it (not mandated in v1).
- **D-18:** No `bash` builtins that require non-POSIX bash where avoidable (e.g., prefer `[[ ]]` for `[ ]` where bash-specific is fine; both scripts are `#!/usr/bin/env bash` so bashisms are allowed).

### No global state mutation (ZAP-05)
- **D-19:** Neither `check-codex.sh` nor `preflight-codex.sh` writes to:
  - `~/.claude/*` (user Claude Code config)
  - `~/.config/codex/*` (codex config — codex itself may write here on first run; the scripts must not trigger that)
  - `~/.zapili/*` (no global zapili state — all state lives under `<cwd>/.zapili/`)
  - Any path outside the user's project CWD
- **D-20:** Pre-flight calls `codex exec --help` (read-only help text) instead of `codex login` or `codex exec <prompt>` precisely because help output never touches config files.

### README update (housekeeping)
- **D-21:** `plugins/zapili/README.md` is updated to:
  - Remove the Phase-1 placeholder line: "the slash command surface is not yet wired"
  - Add a "Usage" section: `/zapili:zapili` runs pre-flight then (in Phase 2) prints a stub message; full workflow lands in Phase 4
  - Add a "Pre-flight" section explaining codex is required at command invocation and the SessionStart hook is advisory
- **D-22:** No new files in the plugin root other than what is enumerated above. No `commands/.gitkeep`, no `hooks/.gitkeep`, no `scripts/.gitkeep` (Phase 1 D-23 carries: only create directories that contain real files).

### Plan structure
- **D-23:** Phase 2 is small (≤300 LOC across 4 files). Single-wave structure expected: 1 wave, 2–3 plans.
  - Plan A: hooks + check-codex.sh (advisory side)
  - Plan B: preflight-codex.sh + commands/zapili.md (strict side + command shell)
  - Plan C (optional): README update (can be folded into Plan B or kept separate)
- **D-24:** No live install rehearsal plan in Phase 2 (Phase 1 already covered the `/plugin install` flow; Phase 2's command discoverability is mechanically implied by the file layout and `plugin.json` default auto-discovery — manual rehearsal can be added retroactively if needed).

### Claude's Discretion
The planner may decide:
- Exact wording of remediation messages in both scripts (must satisfy D-05, D-08, D-09)
- Whether to fold Plan C (README) into Plan B
- Exact frontmatter ordering in `commands/zapili.md`
- Whether to share a tiny `lib/` helper between the two scripts (default: no — KISS)
- Exact wave structure (1 wave or 2 sequential waves) — file-scope disjointness across plans matters most

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning context (MANDATORY)
- `.planning/PROJECT.md` — vision, core value
- `.planning/REQUIREMENTS.md` — ZAP-01, ZAP-02, ZAP-04, ZAP-05
- `.planning/ROADMAP.md` § "Phase 2: Plugin packaging" — phase goal, success criteria
- `.planning/STATE.md` — accumulated decisions and Phase 1 outcomes
- `.planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md` — Phase 1 decisions (esp. D-23 "no empty component dirs", D-24 "no pre-declared component paths in plugin.json")

### Research summary (HIGH-confidence stack)
- `.planning/research/SUMMARY.md` § "Recommended Stack"
- `.planning/research/STACK.md` — full `hooks.json` examples, `${CLAUDE_PLUGIN_ROOT}` semantics
- `.planning/research/ARCHITECTURE.md` § "Hooks + commands"
- `.planning/research/PITFALLS.md` § 3 (non-executable / CRLF hooks), § 4 (absolute paths in hooks), § 19 (global config writes)

### Project-level instructions
- `CLAUDE.md` § "Project Skills", "Plugin Components Used by `zapili`", "Hook Event Map for `zapili`", "What NOT to Use"

### External (live spec)
- Claude Code plugins reference — `code.claude.com/docs/en/plugins-reference` — `${CLAUDE_PLUGIN_ROOT}`, hook event schema
- Claude Code hooks reference — exit-code semantics, JSON-on-stdin contract
- OpenAI codex CLI reference — `developers.openai.com/codex/cli/reference` (for `codex --version`, `codex exec --help`)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (from Phase 1)
- `scripts/validate-manifests.sh` (top-level marketplace scripts) is a working reference for `#!/usr/bin/env bash` + `set -euo pipefail` + `jq` discipline. Phase 2 mirrors its style but plugin-side scripts live under `plugins/zapili/scripts/`, NOT the top-level `scripts/`.
- `plugins/zapili/README.md` already exists and has the "command not yet wired" line that Phase 2 replaces.
- `plugins/zapili/.claude-plugin/plugin.json` is intentionally minimal (only `name` + polish fields, no `commands`/`hooks` keys) — Phase 2 must not add those keys; default auto-discovery picks up `commands/zapili.md` and `hooks/hooks.json` automatically.

### Established Patterns
- LF-only enforcement: `.gitattributes` already has `*.sh text eol=lf` and `*.bash text eol=lf`. New scripts inherit automatically.
- Pre-commit validator (`scripts/install-hooks.sh` + `.git/hooks/pre-commit`) only validates JSON files matching `.claude-plugin/marketplace.json` or `plugins/*/.claude-plugin/plugin.json` — Phase 2's new `hooks.json` falls OUTSIDE that pattern, so it is NOT auto-validated. Future hardening (Phase 6) can add it; not required for Phase 2 to ship.
- Phase 1 commit pattern: `feat(01-NN): ...` and `docs(01-NN): ...` — Phase 2 plans use `feat(02-NN): ...`.

### Integration Points
- New files under `plugins/zapili/`: `hooks/hooks.json`, `scripts/check-codex.sh`, `scripts/preflight-codex.sh`, `commands/zapili.md`. README is edited in place.
- No top-level files change. No `.planning/` files change beyond standard phase artifacts.
- `plugin.json` requires NO edits — default-folder auto-discovery handles new component folders.

</code_context>

<specifics>
## Specific Ideas

- The slash command body is intentionally a stub in Phase 2. It MUST NOT pretend to do orchestration work — pretending would invite users to file bugs against Phase-4 behavior that does not yet exist.
- Pre-flight script intentionally checks `codex exec --help` (not `codex auth status` or similar) because `--help` is universal across codex versions and never touches network/config.
- The `additionalContext` JSON emission from `check-codex.sh` is OPTIONAL — if implemented, it informs the model that codex is or is not available so the model can answer user questions about workflow readiness without re-probing. Implementation form: print a JSON object to stdout (per Claude Code hooks JSON output contract) only on the success path, or omit entirely on failure. The planner may defer this to a follow-up commit if the schema is unclear at planning time.

</specifics>

<deferred>
## Deferred Ideas

- Authentication-status probe in the SessionStart hook (defer to manual user check; expensive at startup)
- Windows shim (`*.cmd` wrappers) — tracked as TOOL-03 v2
- `/zapili:status` command for state inspection — tracked as UX-03 v2
- Pre-flight script reuse via sourced helper — revisit if Phase 4 adds a third script with overlapping logic
- Live install rehearsal stamp for Phase 2 (the visible-command-after-install check) — Phase 1's rehearsal stamp covers install; Phase 2's command discoverability is mechanically implied

</deferred>
