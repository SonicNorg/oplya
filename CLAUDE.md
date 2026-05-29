<!-- GSD:project-start source:PROJECT.md -->
## Project

**oplya — Claude Code Plugin Marketplace**

A public Git-based marketplace (`oplya`) hosting personal Claude Code plugins for sharing with the team. The first plugin, `zapili`, packages a rigorous, multi-agent **development workflow** (research → validation → planning → validation → wave-based parallel implementation → review) driven entirely from a `TASK.md` in the working directory.

**Core Value:** **A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts.**

Everything else (marketplace polish, additional plugins, docs) can fail. The `zapili` workflow producing a high-quality implementation from a well-described task must work.

### Constraints

- **Tech stack**: Markdown + JSON config (marketplace + plugin manifests); Bash for hooks; the Claude Code plugin format is the only deployment target — no separate runtime, no package registry
- **Dependencies**: `codex` CLI must be installed on the user's machine for `zapili` to run; the start-up hook is the only enforcement point
- **Compatibility**: Plugin layout must satisfy `/plugin marketplace add` and `/plugin install` flows on current Claude Code
- **Process**: Light — manual versioning, no required CI, but `marketplace.json` and `plugin.json` MUST pass a local validation before any commit that touches them
- **Documentation**: English-only for `README.md`, plugin docs, and inter-agent prompts. User-facing conversation may be in any language
- **Scope discipline**: v1 ships exactly one plugin (`zapili`). Adding plugins is a future-milestone concern; do not prematurely abstract for "many plugins" beyond directory layout
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Executive Summary
## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Claude Code plugin spec** | current (live spec, docs at `code.claude.com/docs/en/plugins-reference`) | The only deployment target | The PROJECT explicitly fixes this: `/plugin marketplace add` + `/plugin install` flows. No alternative runtime exists for shipping into Claude Code. |
| **`.claude-plugin/marketplace.json`** | schema v1 (live) | Marketplace catalog at repo root | Required exact location; this is what `/plugin marketplace add owner/repo` looks for. |
| **`.claude-plugin/plugin.json`** | schema v1 (live) | Per-plugin manifest | Only `name` is strictly required; everything else (`version`, `description`, `author`, component paths) is opt-in. |
| **Markdown + YAML frontmatter** | CommonMark + YAML 1.2 | Agents, skills/commands, plugin docs | The loader is YAML-frontmatter-driven for every component definition; this is non-negotiable. |
| **JSON (RFC 8259)** | — | Manifests, hooks config, MCP config, on-disk state | The loader is JSON-only for configs; relaxed JSON (comments, trailing commas) is **not** supported. |
| **Bash** | POSIX-conformant; `/bin/bash` shebang | Hook scripts (`hooks/*.sh`), codex wrapper | PROJECT constraint locks this in. Hooks receive JSON on stdin → bash + `jq` is the idiomatic combo. |
| **`jq`** | ≥ 1.6 | Parsing hook stdin JSON, parsing codex `--json` JSONL stream | Universal on macOS/Linux developer machines; the official Anthropic docs use it in every hook example. |
| **OpenAI `codex` CLI** | `codex exec` mode (current; non-interactive subcommand is GA in 2026) | Independent reviewer for research/plan/code validation | PROJECT mandates codex (no Claude fallback) for cross-model review. `codex exec` is purpose-built for scripted invocation. |
| **Anthropic XML-tag prompt convention** | Anthropic prompt-engineering guidance, current | Inter-agent contracts | The PROJECT decision says English + XML structure + JSON inside dedicated tags. This matches the Anthropic prompt-engineering canon and is the most token-efficient machine-parseable form. |
### Plugin Components Used by `zapili`
| Component | Plugin Location | Purpose in `zapili` |
|-----------|-----------------|---------------------|
| **Slash command** (= Skill in the new spec) | `plugins/zapili/commands/zapili.md` *(flat-file form)* **or** `plugins/zapili/skills/zapili/SKILL.md` *(directory form)* | The single `/zapili:zapili` entry point that orchestrates the whole workflow. Use the **directory form** — it allows supporting files (`prompts/`, `templates/`) next to the entry skill. |
| **Subagent — researcher** | `plugins/zapili/agents/zapili-researcher.md` | ZAP-03: classifies task size, drafts the question list. |
| **Subagent — planner** | `plugins/zapili/agents/zapili-planner.md` | ZAP-06: produces `PLAN.md` + `PHASE-XX.md`. |
| **Subagent — ultra-principal-engineer** | `plugins/zapili/agents/zapili-engineer.md` | ZAP-08: per-phase implementation worker; spawned N-wide per wave. |
| **Hook — `SessionStart`** | `plugins/zapili/hooks/hooks.json` + `plugins/zapili/scripts/check-codex.sh` | ZAP-02: verifies `codex` is on PATH; emits remediation via `additionalContext` (non-blocking) or exits non-zero (blocking, when fail-fast is required). |
| **Codex wrapper script** | `plugins/zapili/scripts/codex-review.sh` | Standardizes `codex exec --json --sandbox read-only` invocation, parses JSONL stream, returns the final assistant message + exit code. |
### Supporting Tools
| Tool | Purpose | When to Use |
|------|---------|-------------|
| **`claude plugin validate`** | Validates `plugin.json`, `marketplace.json`, frontmatter, hooks JSON | Run on **every** commit that touches a manifest. PROJECT constraint MKT-06 requires it. |
| **`jq`** | Parse hook stdin, parse codex `--json` JSONL output | Inside every hook script and the codex wrapper. |
| **`tee` + `set -o pipefail`** | Capture codex stdout while also surfacing errors | Required for fail-fast inside `codex-review.sh` so an exit-1 codex run is not silently masked by `tee`. |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| **`claude --plugin-dir ./plugins/zapili`** | Load the local plugin without publishing | Primary dev loop. `/reload-plugins` picks up edits without restart. |
| **`claude plugin validate ./plugins/zapili`** | Validates plugin + every component file | Run before commit; pre-commit-style discipline without a hook. |
| **`claude plugin validate . --strict`** | Treats warnings (e.g. misspelled fields) as errors | Use at marketplace root before releasing. |
| **GitHub (public repo)** | Marketplace host | `/plugin marketplace add SonicNorg/oplya` resolves via the GitHub `owner/repo` shorthand. |
## Concrete File Examples
### `.claude-plugin/marketplace.json` (at `oplya` repo root)
- `metadata.pluginRoot: "./plugins"` lets the `source` shrink to `"zapili"` (without `./plugins/`) for later plugins; kept explicit above for clarity.
- `version` is **deliberately omitted** so the git commit SHA is the version; that matches the PROJECT decision "light publication process, manual semver bumps". For users on `main`, every commit is a fresh version. When you cut a real release, add `"version": "1.0.0"` to the plugin's `plugin.json` (NOT the marketplace entry — `plugin.json` always wins silently).
- `$schema` is ignored at load time but enables editor validation; cheap insurance.
### `plugins/zapili/.claude-plugin/plugin.json`
- **No `version` field** while iterating (commit-SHA versioning). Add `"version": "1.0.0"` only when you cut a real release; bump it on every subsequent release or users will not get updates.
- **No `commands`, `agents`, `hooks` keys** — they all live in their default folders (`commands/`, `agents/`, `hooks/hooks.json`) and are auto-discovered. Only declare these keys when you need a non-default location (don't).
- **No `mcpServers`** — `zapili` does not need a custom MCP server; codex is shelled out, not exposed as an MCP tool.
### `plugins/zapili/hooks/hooks.json`
- `matcher: "startup"` runs only at fresh-session start, not on resume/clear/compact. If you want it on resume too, use `"matcher": "startup|resume"` or omit `matcher` entirely.
- `${CLAUDE_PLUGIN_ROOT}` is mandatory: plugins are copied to `~/.claude/plugins/cache/...` at install time, so relative paths must go through this variable.
- `timeout: 5` (seconds) is plenty for a `command -v codex` check.
### `plugins/zapili/scripts/check-codex.sh`
#!/bin/bash
# SessionStart hook: verify codex CLI is available. Fail fast with remediation.
# Hook stdin is JSON; we don't need it here, but consume it to avoid SIGPIPE.
# Emit machine-readable context for the model: confirms codex is wired up.
- `set -euo pipefail` is mandatory in every hook script — silent failures are the primary bug source.
- `cat >/dev/null` drains the JSON payload Claude Code writes to stdin; if you skip this, hooks can hang or get SIGPIPE on later writes.
- The remediation block is multiline and printed once — this directly satisfies ZAP-02 ("fails fast with clear instruction").
### `plugins/zapili/commands/zapili.md` (the entry-point slash command)
# /zapili:zapili — multi-agent development workflow
## Step 0 — Preconditions
## Step 1 — Research
- The new spec **merges commands and skills**. The flat `commands/zapili.md` form still works and is the simplest layout for a single-file orchestrator. Use `skills/zapili/SKILL.md` (directory form) if you later need to bundle supporting prompts or templates.
- `allowed-tools: Agent(zapili-researcher, …)` is the **mechanism** for restricting which subagents the orchestrator can spawn. Without this allowlist, the orchestrator can spawn any agent (broad surface).
- Invocation path: `/zapili:zapili` (namespaced by the plugin's `name`). The user types this; the agent prefix is the plugin name.
### `plugins/zapili/agents/zapili-researcher.md` (subagent example)
- `tools` is a **read-only allowlist** — the researcher must not write. This enforces the contract structurally, not just by prompt.
- Plugin agents **cannot** use `hooks`, `mcpServers`, or `permissionMode` (security restriction). If you need any of those, copy the agent into `.claude/agents/` instead. For `zapili` this is fine; none of the three subagents needs them.
- The `<output_contract>` block matches the PROJECT decision: XML tags wrapping JSON blocks for machine-parseable payloads.
### `.zapili/state.json` (on-disk workflow state, gitignored or not at user discretion)
- **One file, plain JSON, schema versioned** (`$schema_version: 1` so a future format break is detectable). Survives restart per ZAP-13.
- Lives at `.zapili/state.json` under the repo where `TASK.md` lives (the workflow's `cwd`). This is *not* `${CLAUDE_PLUGIN_DATA}` because state is per-task, not per-plugin-install.
- The orchestrator slash command reads/writes this file directly via the `Read`/`Write` tools (no separate state library — KISS).
### Codex invocation pattern (inside a workflow step)
# Called via Bash tool from inside the orchestrator slash command.
- `codex exec` is the non-interactive subcommand; the prompt comes from stdin via `-`.
- `--json` emits JSONL events on stdout; **only the final agent message is the result**, progress goes to stderr. Parse with `jq -s 'last(.[])'` or stream-process.
- `--sandbox read-only` is the safest default for a reviewer (codex must not modify files). Use `workspace-write` only when codex is explicitly the implementer (not in `zapili`).
- `--skip-git-repo-check` avoids codex refusing to run outside a git repo, which can happen in clean test environments.
- `--ignore-user-config` keeps the run hermetic — no user-specific `~/.codex/config.toml` overrides leak into the validation pass. This is exactly the "independent reviewer" semantics the PROJECT wants.
- Set `CODEX_API_KEY` (or `OPENAI_API_KEY`) in the user's shell env; do not put it in `plugin.json`. If you need a per-plugin token, add it to `userConfig` with `sensitive: true` — it goes to the system keychain.
### Codex review wrapper (`scripts/codex-review.sh`)
#!/bin/bash
# Usage: codex-review.sh <prompt-file> <out-file>
# Exits non-zero on codex failure; writes the parsed final assistant message to <out-file>.
# Capture full JSONL stream; pipefail surfaces codex exit code.
- The exact event/field shape of `--json` JSONL stream varies across codex versions; the `jq` selector here is the canonical 2026 form (events with `type: "message"` and `role: "assistant"`). The wrapper isolates this so a future codex schema bump is one-file change.
- Storing `.raw.jsonl` next to the parsed message preserves the full audit trail for the validation-loop iteration counter.
## Stack Patterns by Variant
- Add a one-liner `.git/hooks/pre-commit` that runs `claude plugin validate . --strict` and `claude plugin validate ./plugins/zapili --strict`.
- No CI. The user opted out per MKT-06.
- Add another entry to `plugins` array in `marketplace.json`. The `metadata.pluginRoot: "./plugins"` already covers any sibling under `plugins/<new-name>/`.
- Do not abstract a "shared library" between plugins until you have ≥3 plugins. Plugin caching makes cross-plugin paths brittle (only symlinks within the same marketplace are dereferenced safely).
- Use `${CLAUDE_PLUGIN_DATA}` (resolves to `~/.claude/plugins/data/<plugin-id>/`). Survives updates. `.zapili/state.json` belongs to the task, not the plugin install, so it stays where it is.
- Two marketplaces pointing at different refs of the same repo (`stable` branch and `main`). Documented in the marketplace docs but **don't build this for v1** — PROJECT explicitly says light process.
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `commands/zapili.md` (flat-file slash command) | `skills/zapili/SKILL.md` (directory) | When `zapili` needs bundled supporting files (templates, sub-prompts). For v1 a flat file is fine; migrate to the directory form when the orchestrator prompt grows past ~500 lines. |
| Bash hook scripts | Python hook scripts | Python is supported (hooks just exec any command), but bash + `jq` is zero-install and is what the official docs assume. Switch to Python only if you need real JSON manipulation beyond `jq`'s reach. |
| `codex exec --json` | `codex exec` (plain text) | Plain text is shorter but loses the audit trail and breaks programmatic parsing. JSONL is non-negotiable for the validation-loop iteration counter. |
| Plain JSON `.zapili/state.json` | SQLite, TOML, YAML | JSON is the only format the agent can read/write with built-in tools (`Read`/`Write`) without spawning a parser. KISS. |
| Three named subagents (researcher/planner/engineer) | One generic agent with role passed as argument | Named subagents give you per-role tool restrictions (researcher = read-only) and per-role models. Generic-with-role-arg loses both. |
| Single `/zapili:zapili` slash command | Multiple commands (`/zapili-research`, `/zapili-plan`, …) | One command keeps the resume-from-`state.json` flow simple. Multiple commands would force the user to remember which phase they're in. |
| GitHub public repo + `/plugin marketplace add` | npm-published plugin | npm packaging adds tooling weight (`package.json`, publish workflow, registry credentials) that the PROJECT explicitly rejects (no required CI). GitHub is the documented zero-friction path. |
| Anthropic XML tags + embedded JSON | Pure JSON / pure prose | XML wraps each contract section so the model finds them reliably; JSON inside the relevant tag is what the orchestrator parses. Pure JSON loses the prose explanation; pure prose loses parseability. This is the Anthropic-canonical hybrid. |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Putting `commands/`, `agents/`, `hooks/` **inside** `.claude-plugin/` | The loader will silently not find them — `.claude-plugin/` is only for `plugin.json`. This is the #1 cited mistake in the official docs. | Plugin-root level (siblings of `.claude-plugin/`). |
| Relative paths with `../` in `marketplace.json` `source` fields | Rejected at validation (`Path contains ".."`); also doesn't work after caching. | `./plugins/<name>` (must start with `./`, no `../`). |
| Setting `"version"` in `plugin.json` while iterating | Users get no updates until you bump it. Pushing commits silently does nothing. | Omit `version` until cutting a release; the git commit SHA is the version. |
| Hardcoded absolute paths in hook commands | Plugins are copied to `~/.claude/plugins/cache/<...>/<sha>/`; absolute paths break instantly. | `${CLAUDE_PLUGIN_ROOT}` (always wrap in quotes: `"${CLAUDE_PLUGIN_ROOT}"`). |
| `codex` (interactive) inside scripts | Hangs forever waiting for a TTY. | `codex exec` (non-interactive subcommand, designed for scripting). |
| `--full-auto` flag on codex | Deprecated; prints a warning. | `--sandbox read-only` (for review) or `--sandbox workspace-write` (only for codex-as-implementer, not in `zapili`). |
| `--dangerously-bypass-approvals-and-sandbox` on codex | Designed for VMs, not developer machines. | Pair `--sandbox` with explicit scope. |
| Comments / trailing commas in `marketplace.json` / `plugin.json` | Strict JSON parser. | Plain RFC 8259 JSON. |
| Putting secrets in `plugin.json` | `plugin.json` is checked into the repo. | `userConfig` with `sensitive: true` (stored in system keychain) **or** environment variables (`OPENAI_API_KEY`). |
| MCP server for the codex bridge | Heavy weight for a one-call review; introduces a long-running subprocess and an MCP schema to maintain. | Shell out to `codex exec` via `Bash` tool. KISS. |
| `Task` tool references in new agent files | Renamed to `Agent` in Claude Code v2.1.63. Old `Task(...)` still works as an alias but is deprecated. | Write `Agent(zapili-researcher, …)` in `allowed-tools`. |
| Russian (or any non-English) in agent prompts / contracts | PROJECT decision: tokens balloon, parsing precision drops. | English everywhere in code/prompts. User chat is unconstrained. |
## Hook Event Map for `zapili`
| Event | Used For | Notes |
|-------|----------|-------|
| `SessionStart` (matcher: `startup`) | ZAP-02: verify `codex` CLI is installed | Fires once when a fresh Claude Code session starts. Use `matcher: "startup\|resume"` if you also want to verify on resume; usually overkill. Exit code 2 surfaces stderr as a blocking error. |
- `UserPromptSubmit` — could intercept `/zapili` invocations, but the slash command itself is the natural entry point.
- `PreToolUse` — could audit subagent tool usage, but per-agent `tools` allowlists already do this declaratively.
- `SubagentStop` — could write `state.json` automatically, but the orchestrator already owns state writes and explicit is better than magic.
## Version Compatibility
| Item | Compatible With | Notes |
|------|-----------------|-------|
| Marketplace schema (`marketplace.json` fields used above) | Claude Code current | All fields used (`name`, `owner`, `metadata.pluginRoot`, `plugins[*].source`, `plugins[*].keywords`, `plugins[*].category`) are stable / non-experimental. |
| Plugin manifest schema (`plugin.json` fields used above) | Claude Code current | `displayName` requires v2.1.143+; if you want to support older clients, drop `displayName` and rely on `name`. |
| `Agent(...)` allowlist syntax in `allowed-tools` | v2.1.63+ | Older sessions accept the old `Task(...)` alias; both keep working. |
| `--plugin-dir ./my-plugin.zip` (zip-based local load) | v2.1.128+ | Not needed for `zapili` dev loop; folder form is fine. |
| Plugin monitors | v2.1.105+ | Not used by `zapili`. |
| Single-skill auto-load at plugin root | v2.1.142+ | Not used; `zapili` uses `commands/` (or `skills/<name>/`) explicitly. |
| `codex exec --json` JSONL output | codex CLI current (2026) | Event/field shape can change; isolate parsing in `scripts/codex-review.sh`. |
## Installation (for end users — copy into README.md)
# Add the marketplace
# Install the workflow plugin
# (One-time) install codex CLI if you don't have it
# or: npm install -g @openai/codex
# Authenticate codex (ChatGPT sign-in or set OPENAI_API_KEY)
# Use
# In Claude Code:
# Edit, then /reload-plugins inside the session
## Sources
- **Plugins overview** — https://code.claude.com/docs/en/plugins — directory layout, manifest basics, `--plugin-dir`/`--plugin-url`, hooks/migration from `.claude/`.
- **Plugins reference** — https://code.claude.com/docs/en/plugins-reference — full `plugin.json` schema, all component path fields, hook event table, `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` / `${CLAUDE_PROJECT_DIR}`, caching/symlink behavior, version-resolution rules.
- **Plugin marketplaces** — https://code.claude.com/docs/en/plugin-marketplaces — `marketplace.json` schema, all source types (`github`, `url`, `git-subdir`, `npm`, relative path), strict mode, validation, hosting on GitHub, `metadata.pluginRoot`, release channels.
- **Hooks reference (live)** — every supported event with input/output schema, hook types (`command`, `http`, `mcp_tool`, `prompt`, `agent`), exit-code semantics, JSON-on-stdin contract.
- **Subagents** — https://code.claude.com/docs/en/sub-agents — agent frontmatter schema (`name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation`), `Agent(...)` allowlist, plugin-subagent security restrictions (no `hooks`/`mcpServers`/`permissionMode`).
- **Skills** — https://code.claude.com/docs/en/skills — `SKILL.md` frontmatter (`description`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context: fork`, `agent`, `paths`), `$ARGUMENTS` + `$N` + `$name` substitutions, command/skill merge note (`.claude/commands/foo.md` and `.claude/skills/foo/SKILL.md` are equivalent).
- **Codex CLI — Non-interactive mode** — https://developers.openai.com/codex/noninteractive — `codex exec` syntax, `--json`, `--sandbox`, `--skip-git-repo-check`, `--cd`, `--ignore-user-config`, `--ignore-rules`, `--ephemeral`, `--output-schema`, `-o`, stdin-as-prompt with `-`, `CODEX_API_KEY` env var.
- **Codex CLI — Features** — https://developers.openai.com/codex/cli/features — `codex exec` automation use cases, sandbox levels.
- **Codex CLI — Reference** — https://developers.openai.com/codex/cli/reference — global flags (`--sandbox`, `--ask-for-approval`, `--model`, `--cd`, `--config`, `--add-dir`).
- **Codex CLI repository** — https://github.com/openai/codex — installation (`curl … | sh`, `npm install -g @openai/codex`, `brew install --cask codex`), authentication options.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
