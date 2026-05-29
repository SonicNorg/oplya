# Phase 1: Marketplace + plugin skeleton - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

A fresh clone of `oplya` installs end-to-end via `/plugin marketplace add SonicNorg/oplya` + `/plugin install zapili@oplya`, with valid manifests, hygiene files (LICENSE, .gitignore, .gitattributes), top-level + plugin-level READMEs, and a local pre-commit manifest validator. This phase delivers the static repository skeleton ONLY — no slash command behavior, no hook scripts, no agent logic. Plugin file `zapili` must be visible to Claude Code after install; making `/zapili:zapili` actually runnable is Phase 2's job.

**In scope:** repository layout; `.claude-plugin/marketplace.json`; `plugins/zapili/.claude-plugin/plugin.json`; top-level `README.md`; `plugins/zapili/README.md`; `LICENSE`; `.gitignore`; `.gitattributes`; `scripts/validate-manifests.sh`; `scripts/install-hooks.sh`; pre-commit hook template; documentation of pre-commit setup.

**Out of scope (belongs to later phases):** SessionStart hook, `check-codex.sh`, `commands/zapili.md` body, orchestrator skill, agents, schemas, codex wrappers, reserved-name verification (Phase 6), `displayName` field-version compatibility checks (Phase 6 polish).

</domain>

<decisions>
## Implementation Decisions

### License (MKT-04)
- **D-01:** MIT license. Single-paragraph LICENSE text with current year (2026) and copyright holder `Pavel <pavel.proger@gmail.com>`. No NOTICE file. No patent grant required.

### Manifest metadata — `.claude-plugin/marketplace.json` (MKT-01)
- **D-02:** Required fields: `name: "oplya"`, `owner: { name: "Pavel", email: "pavel.proger@gmail.com", url: "https://github.com/SonicNorg" }`, `plugins: [...]`.
- **D-03:** Polish fields: `displayName: "oplya"`, `description: "Personal plugin marketplace — multi-agent dev workflows"`, `category: "workflow"`, `$schema` link (planner: pin to the latest stable Claude Code marketplace-schema URL from the official docs at planning time).
- **D-04:** `metadata.pluginRoot: "./plugins"` so each plugins[].source can be the short form `"./plugins/zapili"`.
- **D-05:** `plugins[]` array contains exactly one entry for `zapili` in v1. No `version` field on the marketplace entry — commit-SHA versioning.
- **D-06:** Repository slug for install instructions: `SonicNorg/oplya`.

### Manifest metadata — `plugins/zapili/.claude-plugin/plugin.json` (MKT-02, ZAP-03)
- **D-07:** Required field: `name: "zapili"`.
- **D-08:** Polish fields: `displayName: "zapili"`, `description: "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review"`, `category: "workflow"`, `keywords: ["workflow", "multi-agent", "codex", "planning", "parallel"]`, `author: { name: "Pavel", email: "pavel.proger@gmail.com", url: "https://github.com/SonicNorg" }`.
- **D-09:** NO `version` field while iterating (commit-SHA versioning — PROJECT.md decision). Planner adds `"version": "1.0.0"` only at the eventual release commit (Phase 6 concern, not Phase 1).
- **D-10:** NO `commands`, `agents`, `hooks`, `mcpServers` keys — Phase 1 ships zero components. Default-folder auto-discovery is irrelevant when the folders themselves are absent.

### Validator — `scripts/validate-manifests.sh` (MKT-07)
- **D-11:** Lives at marketplace top-level (`scripts/validate-manifests.sh`), NOT inside `plugins/zapili/`. This is marketplace-level infrastructure; it validates ALL plugins in the repo, not just zapili. Preserves MKT-08 (zapili imports nothing from marketplace-scripts).
- **D-12:** Script does TWO checks: (a) `jq -e . <file>` proves valid JSON for `.claude-plugin/marketplace.json` and every `plugins/*/.claude-plugin/plugin.json`; (b) required-fields check — marketplace.json must have `name`, `owner`, `plugins`; each `plugin.json` must have `name`. Implementation: pure bash + `jq` only; no npm, no Python, no `ajv`.
- **D-13:** Exit codes: 0 = all valid; 1 = any validation failure. On failure, prints which file failed and which required field is missing (one line per problem; do NOT stop at first failure — surface them all in one pass).
- **D-14:** Standard shell discipline: `#!/usr/bin/env bash`, `set -euo pipefail`, LF line endings, mode 0755.
- **D-15:** If `jq` is missing on the host, the script exits with a clear remediation message (1, not 2). Do not silently skip validation.

### Pre-commit wiring (MKT-07)
- **D-16:** Ship `scripts/install-hooks.sh` (marketplace top-level) — a one-time idempotent installer that writes `.git/hooks/pre-commit` calling `./scripts/validate-manifests.sh`. README documents the one-line command `./scripts/install-hooks.sh`.
- **D-17:** The installed `.git/hooks/pre-commit` script runs the validator ONLY when staged files include `.claude-plugin/marketplace.json` or any `plugins/*/.claude-plugin/plugin.json` — fast path / no-op for unrelated commits. Detection via `git diff --cached --name-only`.
- **D-18:** `install-hooks.sh` is idempotent: if `.git/hooks/pre-commit` already exists and is byte-identical to the template, it's a no-op. If it exists and DIFFERS, the installer prints a diff and aborts (exit 1) — never silently overwrite user-modified hooks. README documents the manual override path.
- **D-19:** Hook is opt-in (user runs `install-hooks.sh` once). Discovery: top-level README has a "Local development" section explaining the validator + installer, plus a callout that fresh clones should run `./scripts/install-hooks.sh` before contributing.

### Hygiene files (MKT-05, MKT-06)
- **D-20:** `LICENSE` at top-level only. Plugin directory does NOT carry a duplicate LICENSE — `MKT-08` is about no cross-plugin code reuse, not about license duplication.
- **D-21:** `.gitignore` at top-level: covers `.zapili/` (zapili runtime state in user CWDs — but also for repo-local dev runs), `.claude/cache/`, OS noise (`.DS_Store`, `Thumbs.db`), editor/IDE noise (`.idea/`, `.vscode/`, `*.swp`), Node noise (`node_modules/`, `dist/`, `*.log`), Python noise (`__pycache__/`, `*.pyc`, `.venv/`, `venv/`), env files (`.env`, `.env.local`). Planner picks the exact pattern list using `github/gitignore` curated patterns as reference.
- **D-22:** `.gitattributes` at top-level enforces `*.sh text eol=lf` and `*.bash text eol=lf`. Planner may also add `*.json text eol=lf` and `*.md text eol=lf` for consistency, but the `*.sh` / `*.bash` lines are non-negotiable (per ZAP-04 / MKT-06).

### Skeleton minimalism (MKT-08)
- **D-23:** Phase 1 does NOT create empty component directories (`commands/`, `agents/`, `hooks/`, `schemas/`, `skills/`, `tests/`) inside `plugins/zapili/`. They are created in the phases that actually populate them (Phase 2 makes `hooks/` and `commands/`; Phase 3 makes `schemas/` and `skills/orchestrator/references/` and `tests/fixtures/`; Phases 4–5 add `agents/`). No `.gitkeep` placeholders. Phase 1 ships exactly four leaves under `plugins/zapili/`: `.claude-plugin/plugin.json` and `README.md`.
- **D-24:** Component-directory paths in `plugin.json` are NOT pre-declared (no `commands`, `agents`, `hooks`, `mcpServers` keys). When Phase 2+ adds the folders, default auto-discovery picks them up — no manifest edits required.

### READMEs (MKT-03, ZAP-03)
- **D-25:** Top-level `README.md` (English) MUST include: (1) one-paragraph what `oplya` is; (2) plugin index (currently one row for `zapili` with its one-line description); (3) install instructions verbatim — `/plugin marketplace add SonicNorg/oplya` then `/plugin install zapili@oplya`; (4) "Local development" section pointing at `scripts/validate-manifests.sh` and `scripts/install-hooks.sh`; (5) License line ("MIT — see LICENSE"); (6) link to `plugins/zapili/README.md` for details.
- **D-26:** `plugins/zapili/README.md` (English) MUST include: (1) one-paragraph what `zapili` does (multi-agent workflow from `TASK.md` to shipped change); (2) prerequisites callout — `codex` CLI installed AND authenticated; (3) "How to author a TASK.md" stub (the actual schema lives in Phase 3, but a one-paragraph high-level explanation lands in Phase 1 so the README is self-contained for v1); (4) install instructions cross-link to the top-level README; (5) one-line note that the slash command surface is not yet wired (planner: this note ships only on the Phase-1 commit; Phase 2 replaces the line with the real command surface description).
- **D-27:** No badges, no screenshots, no TOC in v1 READMEs. Plain prose + fenced code blocks for commands. Keep both READMEs under ~80 lines each.

### Claude's Discretion
The planner has freedom to choose:
- Exact `$schema` URL value in marketplace.json (pin the latest stable URL from current Claude Code docs at planning time).
- Exact wording of `.gitignore` pattern lines as long as the categories in D-21 are covered (canonical `github/gitignore` Node/Python entries are fine reference).
- Whether `.gitattributes` includes `*.json text eol=lf` / `*.md text eol=lf` on top of the mandated `*.sh` / `*.bash` lines.
- Exact wording of README sections as long as D-25 / D-26 / D-27 are satisfied.
- Exact wording of validator error messages (must satisfy D-13 — one line per problem, surfaces all failures).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning context (MANDATORY)
- `.planning/PROJECT.md` — vision, core value, key decisions (LICENSE choice, English-only contracts, manifest field policy)
- `.planning/REQUIREMENTS.md` — REQ-IDs MKT-01..08 and ZAP-03 covered by this phase, plus Out of Scope and Acceptance Criteria
- `.planning/ROADMAP.md` § "Phase 1: Marketplace + plugin skeleton" — phase goal, success criteria, dependencies
- `.planning/STATE.md` — accumulated key decisions, research flags (reserved-name check noted but deferred to Phase 6)

### Research summary (HIGH-confidence stack + architecture decisions)
- `.planning/research/SUMMARY.md` § "Recommended Stack" + § "Architecture Approach" — the manifest+Markdown+Bash+jq stack and orchestrator-skill-in-main-thread architecture
- `.planning/research/STACK.md` (read in full when stubbing manifests) — concrete `marketplace.json` and `plugin.json` examples, field-version compatibility table, "What NOT to Use" list
- `.planning/research/ARCHITECTURE.md` § "Marketplace root + plugin skeleton" — directory layout invariants
- `.planning/research/PITFALLS.md` § 1 (marketplace.json location), § 2 (malformed manifest fields), § 3 (non-executable / CRLF hooks), § 19 (global config writes), § 20 (forgotten semver bumps) — Phase 1 mitigations are exactly these

### Project-level instructions
- `CLAUDE.md` § "Project" + § "Technology Stack" — locked tech stack and "What NOT to Use" list relevant to manifest authoring

### External (live spec — planner re-fetches at planning time)
- Claude Code plugins reference — `code.claude.com/docs/en/plugins-reference` — authoritative `plugin.json` field list, `${CLAUDE_PLUGIN_ROOT}` semantics (Phase 2 concern but worth confirming field shapes now)
- Claude Code marketplaces docs — `code.claude.com/docs/en/plugin-marketplaces` — authoritative `marketplace.json` schema, `metadata.pluginRoot`, source-path rules (no `../`, must start with `./`)
- `github/gitignore` curated patterns — reference for `.gitignore` Node/Python entries (D-21)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — Phase 1 is greenfield. The repository currently contains only `.planning/`, `.claude/`, and `CLAUDE.md`. No existing code to reuse.

### Established Patterns
- `.planning/` directory is the canonical artifact location for GSD workflow state — Phase 1 must NOT touch it.
- `CLAUDE.md` § "Technology Stack" already documents the recommended `marketplace.json` and `plugin.json` shape; planner reuses those snippets verbatim rather than reinventing.

### Integration Points
- New top-level files (`README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `.claude-plugin/marketplace.json`, `scripts/*.sh`) are siblings of `.planning/` and `.claude/` — no overlap.
- New plugin tree (`plugins/zapili/.claude-plugin/plugin.json`, `plugins/zapili/README.md`) is a brand-new top-level directory.

</code_context>

<specifics>
## Specific Ideas

- Repository slug `SonicNorg/oplya` is the canonical install identifier — bake this string into both READMEs and into commit-message references.
- Owner identity uses the user's real email (`pavel.proger@gmail.com`) in the manifest — user explicitly opted in to the most-discoverable variant despite the email being visible in a public repo.
- README pitch for the marketplace leans on "personal plugin marketplace — multi-agent dev workflows" framing (user-approved wording from D-03).
- README pitch for `zapili` leans on "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review" framing (user-approved wording from D-08).

</specifics>

<deferred>
## Deferred Ideas

- **Reserved-name verification for `oplya` and `zapili`** — research flag from STATE.md. User chose to defer to Phase 6 (publication polish) rather than block Phase 1. Risk: if names turn out to be reserved at release time, rename is painful, but `.planning/research/SUMMARY.md` notes they were clear on 2026-05-27.
- **CHANGELOG + semver bump policy** — Phase 6 polish concern; not authored in Phase 1.
- **GitHub Actions CI** — explicitly out of v1 scope (REQUIREMENTS.md Out of Scope; tracked as TOOL-01 for v2).
- **`ajv-cli` / full JSON Schema validation** — considered for the validator depth, rejected (npm dep would conflict with the "no language runtime" PROJECT constraint).
- **Web listing page / shields / badges in README** — UX-02 / UX-01, v2 concerns.
- **Empty component-directory stubs (`.gitkeep`)** — rejected per D-23; folders appear in the phase that populates them.
- **Auto-installing the pre-commit hook on first validator run** — considered, rejected (magic). Opt-in `install-hooks.sh` is canonical.

</deferred>

---

*Phase: 1-Marketplace + plugin skeleton*
*Context gathered: 2026-05-27*
