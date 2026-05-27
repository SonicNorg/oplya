# Phase 1: Marketplace + plugin skeleton - Research

**Researched:** 2026-05-27
**Domain:** Claude Code plugin marketplace authoring + repo hygiene + local pre-commit manifest validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**License (MKT-04)**
- **D-01:** MIT license. Single-paragraph LICENSE text with current year (2026) and copyright holder `Pavel <pavel.proger@gmail.com>`. No NOTICE file. No patent grant required.

**Manifest metadata — `.claude-plugin/marketplace.json` (MKT-01)**
- **D-02:** Required fields: `name: "oplya"`, `owner: { name: "Pavel", email: "pavel.proger@gmail.com", url: "https://github.com/nepavel" }`, `plugins: [...]`.
- **D-03:** Polish fields: `displayName: "oplya"`, `description: "Personal plugin marketplace — multi-agent dev workflows"`, `category: "workflow"`, `$schema` link (planner: pin to the latest stable Claude Code marketplace-schema URL from the official docs at planning time).
- **D-04:** `metadata.pluginRoot: "./plugins"` so each plugins[].source can be the short form `"./plugins/zapili"`.
- **D-05:** `plugins[]` array contains exactly one entry for `zapili` in v1. No `version` field on the marketplace entry — commit-SHA versioning.
- **D-06:** Repository slug for install instructions: `nepavel/oplya`.

**Manifest metadata — `plugins/zapili/.claude-plugin/plugin.json` (MKT-02, ZAP-03)**
- **D-07:** Required field: `name: "zapili"`.
- **D-08:** Polish fields: `displayName: "zapili"`, `description: "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review"`, `category: "workflow"`, `keywords: ["workflow", "multi-agent", "codex", "planning", "parallel"]`, `author: { name: "Pavel", email: "pavel.proger@gmail.com", url: "https://github.com/nepavel" }`.
- **D-09:** NO `version` field while iterating (commit-SHA versioning). Planner adds `"version": "1.0.0"` only at the eventual release commit (Phase 6 concern, not Phase 1).
- **D-10:** NO `commands`, `agents`, `hooks`, `mcpServers` keys — Phase 1 ships zero components.

**Validator — `scripts/validate-manifests.sh` (MKT-07)**
- **D-11:** Lives at marketplace top-level (`scripts/validate-manifests.sh`), NOT inside `plugins/zapili/`. Validates ALL plugins in the repo, not just zapili. Preserves MKT-08.
- **D-12:** Script does TWO checks: (a) `jq -e . <file>` proves valid JSON for marketplace.json and every `plugins/*/.claude-plugin/plugin.json`; (b) required-fields check — marketplace.json must have `name`, `owner`, `plugins`; each `plugin.json` must have `name`. Pure bash + `jq` only; no npm, no Python, no `ajv`.
- **D-13:** Exit codes: 0 = all valid; 1 = any validation failure. Prints which file failed and which required field is missing (one line per problem; do NOT stop at first failure).
- **D-14:** Standard shell discipline: `#!/usr/bin/env bash`, `set -euo pipefail`, LF line endings, mode 0755.
- **D-15:** If `jq` is missing on the host, the script exits with a clear remediation message (exit 1, not 2). Do not silently skip validation.

**Pre-commit wiring (MKT-07)**
- **D-16:** Ship `scripts/install-hooks.sh` (marketplace top-level) — a one-time idempotent installer that writes `.git/hooks/pre-commit` calling `./scripts/validate-manifests.sh`.
- **D-17:** The installed `.git/hooks/pre-commit` runs the validator ONLY when staged files include `.claude-plugin/marketplace.json` or any `plugins/*/.claude-plugin/plugin.json`. Detection via `git diff --cached --name-only`.
- **D-18:** `install-hooks.sh` is idempotent: byte-identical → no-op; differs → prints diff and aborts (exit 1) — never silently overwrite user-modified hooks.
- **D-19:** Hook is opt-in (user runs `install-hooks.sh` once). README documents the workflow.

**Hygiene files (MKT-05, MKT-06)**
- **D-20:** `LICENSE` at top-level only. Plugin directory does NOT carry a duplicate LICENSE.
- **D-21:** `.gitignore` at top-level: covers `.zapili/`, `.claude/cache/`, OS noise (`.DS_Store`, `Thumbs.db`), editor/IDE noise (`.idea/`, `.vscode/`, `*.swp`), Node noise (`node_modules/`, `dist/`, `*.log`), Python noise (`__pycache__/`, `*.pyc`, `.venv/`, `venv/`), env files (`.env`, `.env.local`).
- **D-22:** `.gitattributes` at top-level enforces `*.sh text eol=lf` and `*.bash text eol=lf`. Planner may add `*.json text eol=lf` and `*.md text eol=lf`; `*.sh` / `*.bash` lines are non-negotiable.

**Skeleton minimalism (MKT-08)**
- **D-23:** Phase 1 does NOT create empty component directories. No `.gitkeep` placeholders. Phase 1 ships exactly four leaves under `plugins/zapili/`: `.claude-plugin/plugin.json` and `README.md`.
- **D-24:** Component-directory paths in `plugin.json` are NOT pre-declared.

**READMEs (MKT-03, ZAP-03)**
- **D-25:** Top-level `README.md` (English): (1) what `oplya` is; (2) plugin index (one row for `zapili`); (3) install instructions verbatim — `/plugin marketplace add nepavel/oplya` then `/plugin install zapili@oplya`; (4) "Local development" section pointing at `scripts/validate-manifests.sh` and `scripts/install-hooks.sh`; (5) License line; (6) link to `plugins/zapili/README.md`.
- **D-26:** `plugins/zapili/README.md` (English): (1) what `zapili` does; (2) prerequisites — `codex` CLI installed AND authenticated; (3) "How to author a TASK.md" stub (one paragraph); (4) install cross-link to top-level README; (5) one-line note that slash command surface is not yet wired (Phase 2 replaces this line).
- **D-27:** No badges, no screenshots, no TOC in v1 READMEs. Plain prose + fenced code blocks. Under ~80 lines each.

### Claude's Discretion
- Exact `$schema` URL value in marketplace.json (pin the latest stable URL from current Claude Code docs at planning time).
- Exact wording of `.gitignore` pattern lines as long as D-21 categories are covered.
- Whether `.gitattributes` includes `*.json text eol=lf` / `*.md text eol=lf` on top of the mandated `*.sh` / `*.bash` lines.
- Exact wording of README sections as long as D-25 / D-26 / D-27 are satisfied.
- Exact wording of validator error messages (must satisfy D-13).

### Deferred Ideas (OUT OF SCOPE)
- **Reserved-name verification for `oplya` and `zapili`** — deferred to Phase 6. (CONFIRMED CLEAR by this research — see Reserved-name check below; both names absent from the live Anthropic reserved list as of 2026-05-27.)
- **CHANGELOG + semver bump policy** — Phase 6.
- **GitHub Actions CI** — explicitly out of v1 scope (TOOL-01 for v2).
- **`ajv-cli` / full JSON Schema validation** — rejected.
- **Web listing page / shields / badges in README** — UX-02 / UX-01, v2.
- **Empty component-directory stubs (`.gitkeep`)** — rejected per D-23.
- **Auto-installing the pre-commit hook on first validator run** — rejected; opt-in `install-hooks.sh` is canonical.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MKT-01 | `.claude-plugin/marketplace.json` at repo root listing all plugins | Schema verified live (code.claude.com/docs/en/plugin-marketplaces) — `name`, `owner`, `plugins` required; `$schema`, `description`, `version`, `metadata.pluginRoot` optional. See `## Standard Stack` and `## Code Examples`. |
| MKT-02 | Each plugin lives at `plugins/<plugin-name>/.claude-plugin/plugin.json` (`name` required) | Schema verified live (code.claude.com/docs/en/plugins-reference) — only `name` strictly required; `version` omission triggers commit-SHA versioning. See `## Code Examples`. |
| MKT-03 | Top-level `README.md` (English) documents marketplace + install instructions + plugin list | D-25 wording covered in `## Code Examples`. |
| MKT-04 | Top-level `LICENSE` (MIT or Apache 2.0) | D-01 locks MIT. Canonical MIT text in `## Code Examples`. |
| MKT-05 | Curated top-level `.gitignore` covering Node/Python/IDE/OS noise + `.zapili/` + `.claude/cache/` | `github/gitignore` patterns in `## Code Examples`. |
| MKT-06 | Top-level `.gitattributes` with `*.sh text eol=lf` and `*.bash text eol=lf` (CRLF prevention) | Pitfall 3 mitigation; pattern in `## Code Examples`. |
| MKT-07 | Local `scripts/validate-manifests.sh` parses `marketplace.json` + each `plugin.json` | Two-pass `jq -e` + required-fields check; full script in `## Code Examples`. |
| MKT-08 | Each plugin self-contained — no cross-plugin file references | D-11 locates validator at marketplace top-level (infrastructure, not `zapili`-internal). Plugin tree ships only `plugin.json` + `README.md`. |
| ZAP-03 | Plugin-local `README.md` explains what `zapili` does, prerequisites (codex CLI + auth), how to author a TASK.md | D-26 wording covered in `## Code Examples`. |
</phase_requirements>

## Summary

Phase 1 is a **pure-static repo-scaffolding phase** with zero runtime behavior. Every artifact is either a JSON manifest, a Markdown doc, or a Bash script — no language runtime, no build pipeline, no CI. The official Claude Code plugin spec is unusually well-documented (`code.claude.com/docs/en/plugins-reference` and `…/plugin-marketplaces`) and the schemas are stable; the entire risk surface is therefore (a) **mechanical** (`.claude-plugin/` placement, CRLF/exec-bit on `.sh` files, no `../` in `source` paths) and (b) **documentary** (READMEs accurately describe an install path that does not yet have a working slash command body).

The four research streams (STACK / FEATURES / ARCHITECTURE / PITFALLS in `.planning/research/`) already authored a HIGH-confidence Phase-1 stack pinned by `CLAUDE.md § "Technology Stack"`. This research re-verifies the live spec against the current `code.claude.com` docs and the canonical reference repo (`anthropics/claude-plugins-official`), flags one drift from CONTEXT.md (`owner.url` is not in the documented `marketplace.json` schema and is absent from the official reference repo — it will load fine but will trigger a `claude plugin validate --strict` warning), confirms the canonical `$schema` URLs to pin, and emits the exact files the planner must write.

**Primary recommendation:** Implement Phase 1 as a single linear sequence of file creations — manifests → hygiene files → scripts → READMEs → smoke validation — with the project-owned `scripts/validate-manifests.sh` as the **only** required pre-commit gate (per D-12). Reuse the verbatim snippets from `.planning/research/STACK.md` and `CLAUDE.md § "Technology Stack"` for manifest shapes; do not reinvent. Pin `$schema` to the official `https://anthropic.com/claude-code/marketplace.schema.json` (marketplace) and `https://json.schemastore.org/claude-code-plugin-manifest.json` (plugin) — both confirmed live against the canonical reference repo and JSON Schema Store on 2026-05-27.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Marketplace catalog discovery (`marketplace.json`) | Repo root (`.claude-plugin/`) | — | Hard-coded path the `/plugin marketplace add` flow probes; nothing else owns this location. |
| Per-plugin manifest (`plugin.json`) | Plugin root (`plugins/zapili/.claude-plugin/`) | — | Hard-coded location for each plugin; auto-discovered when the plugin is installed. |
| Repo hygiene (`LICENSE`, `.gitignore`, `.gitattributes`) | Repo root | — | Git-level concerns; one set per repository, not per plugin. |
| Manifest validation (`validate-manifests.sh`) | Marketplace-level (`scripts/`) | — | Per D-11/D-12, this validates ALL plugins in the marketplace — it is marketplace infrastructure, not a `zapili`-internal asset. Keeps MKT-08 (zapili self-contained) intact. |
| Pre-commit hook installer (`install-hooks.sh`) | Marketplace-level (`scripts/`) | — | Same reasoning as the validator — repo-level dev workflow, not plugin-internal. |
| User-facing documentation (top-level `README.md`) | Repo root | — | First file a visitor sees on GitHub; describes the marketplace and indexes plugins. |
| Plugin-specific documentation (`plugins/zapili/README.md`) | Plugin root | — | Surfaced when a user inspects the plugin directory or follows the link from the top-level README. |

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Claude Code plugin spec | current (live spec at `code.claude.com/docs/en/plugins-reference`) | The only deployment target | [VERIFIED: code.claude.com/docs/en/plugin-marketplaces] [VERIFIED: code.claude.com/docs/en/plugins-reference] No alternative runtime exists. |
| `.claude-plugin/marketplace.json` | schema v1 (live) | Marketplace catalog at repo root | [VERIFIED: code.claude.com/docs/en/plugin-marketplaces] `/plugin marketplace add owner/repo` looks for this exact path. |
| `.claude-plugin/plugin.json` | schema v1 (live) | Per-plugin manifest | [VERIFIED: code.claude.com/docs/en/plugins-reference] Only `name` strictly required. |
| Markdown + YAML 1.2 frontmatter | CommonMark | READMEs (no frontmatter in Phase 1 — pure prose) | [VERIFIED: code.claude.com/docs/en/plugins-reference] Standard for all plugin documentation. |
| JSON (RFC 8259, strict) | — | Manifests | [VERIFIED: code.claude.com/docs/en/plugins-reference] No comments, no trailing commas — strict parser. |
| Bash (POSIX with bashisms) | `/usr/bin/env bash`, ≥4.0 | `scripts/*.sh` | [VERIFIED: env probe — 5.2.21 on this host] Project locks Bash per CLAUDE.md § "Technology Stack". |
| `jq` | ≥ 1.6 | JSON validation in `validate-manifests.sh` | [VERIFIED: env probe — `jq-1.7` on this host] Universal on macOS/Linux dev machines; idiomatic per Anthropic docs. |
| `git` | ≥ 2.30 | Repo state inspection in `install-hooks.sh` and the installed pre-commit | [VERIFIED: env probe — `git 2.43.0` on this host] Required for `git diff --cached --name-only` in the installed hook. |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `claude plugin validate <path>` | Official validator for `plugin.json` / `marketplace.json` / frontmatter / hooks JSON | [VERIFIED: `claude plugin validate --help` on this host] **Optional supplementary check.** Project validator (D-12) is the required gate. Run this as a developer-side spot-check or before tagging a release (Phase 6 concern). The `--strict` flag treats unrecognized fields as errors. |
| `claude --plugin-dir ./plugins/zapili` | Load the plugin locally without publishing | [VERIFIED: `claude --help` on this host] Primary dev-loop tool. `/reload-plugins` inside the session picks up edits. |
| `claude plugin marketplace add <source>` | Smoke-test marketplace registration on a fresh clone | [VERIFIED: `claude plugin marketplace --help` on this host] Required to satisfy Phase 1 success criterion 1. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure bash + `jq` validator (D-12) | `ajv-cli` (npm) with full JSON Schema | Stronger validation (every field type-checked against the spec) but introduces an `npm` dependency, conflicting with the "no language runtime" PROJECT constraint. Explicitly rejected in CONTEXT.md Deferred Ideas. |
| Pure bash + `jq` validator | `claude plugin validate --strict` | The official validator is more thorough but is a runtime tool not guaranteed to be in CI environments and not required by the PROJECT for pre-commit. Document it as a supplementary check; do not depend on it. |
| `nepavel/oplya` GitHub shorthand for `/plugin marketplace add` | Direct URL to raw `marketplace.json` | Relative-path `source` fields in `marketplace.json` only resolve when added via Git (GitHub shorthand or git URL). URL-based marketplace add breaks the `./plugins/zapili` source — see Pitfall "URL-based marketplace breaks relative paths" below. GitHub shorthand is the only correct path for this design. |

**Installation:**
```bash
# Verify dev environment (Phase 1 has no install step — only repo files are created)
command -v jq && jq --version    # required by validate-manifests.sh
command -v git && git --version  # required by install-hooks.sh and pre-commit
command -v bash && bash --version
command -v claude && claude --version  # for local plugin testing
```

**Version verification (re-verified for Phase 1 — 2026-05-27):**
- `jq` 1.7 installed locally [VERIFIED: env probe]
- `git` 2.43.0 installed locally [VERIFIED: env probe]
- `bash` 5.2.21 installed locally [VERIFIED: env probe]
- `claude` CLI present (with `plugin validate` / `plugin marketplace add` subcommands) [VERIFIED: env probe]

## Package Legitimacy Audit

> Phase 1 installs **no external packages** — every dependency (`bash`, `jq`, `git`, `claude`) is a host tool the user already has. This audit table is therefore minimal.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `jq` | OS package manager (apt / brew / etc.) | ≥10 years | universal | [github.com/jqlang/jq](https://github.com/jqlang/jq) | N/A — OS-level | Approved |
| `bash` | OS package manager | ≥30 years | universal | [git.savannah.gnu.org/cgit/bash.git](https://git.savannah.gnu.org/cgit/bash.git) | N/A — OS-level | Approved |
| `git` | OS package manager | ≥20 years | universal | [github.com/git/git](https://github.com/git/git) | N/A — OS-level | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
**Note:** slopcheck not applicable — Phase 1 does not run `npm install`, `pip install`, or `cargo add`. The only files written are project source files in the user's repo.

## Architecture Patterns

### System Architecture Diagram

Phase 1 produces a static directory tree consumed by Claude Code's `/plugin marketplace add` + `/plugin install` flow at install time.

```
User                                                 GitHub                  Claude Code
 │                                                     │                         │
 │ /plugin marketplace add nepavel/oplya               │                         │
 ├────────────────────────────────────────────────────►│                         │
 │                                                     │ clone repo              │
 │                                                     ├────────────────────────►│
 │                                                     │                         │ probe .claude-plugin/marketplace.json
 │                                                     │                         │ parse + validate (name, owner, plugins)
 │                                                     │                         │ register marketplace as "oplya"
 │ /plugin install zapili@oplya                        │                         │
 ├─────────────────────────────────────────────────────────────────────────────►│
 │                                                     │                         │ resolve plugins[name=zapili]
 │                                                     │                         │ apply metadata.pluginRoot
 │                                                     │                         │ resolve source: ./plugins/zapili
 │                                                     │                         │ copy to ~/.claude/plugins/cache/<sha>/
 │                                                     │                         │ probe plugin/.claude-plugin/plugin.json
 │                                                     │                         │ parse + validate (name required)
 │                                                     │                         │ register plugin "zapili"
 │                                                     │                         │ NOTE: no commands/agents/hooks dirs exist;
 │                                                     │                         │       auto-discovery yields zero components
 │                                                     │                         │       (Phase 2 adds them)
 │
Developer-side pre-commit (opt-in, after install-hooks.sh):
 │
 │ git commit -m "..."                                 git pre-commit hook
 ├────────────────────────────────────────────────────►│
 │                                                     │ git diff --cached --name-only
 │                                                     │ if any *.claude-plugin/*.json staged:
 │                                                     │   ./scripts/validate-manifests.sh
 │                                                     │   ├── jq -e . marketplace.json
 │                                                     │   ├── for each plugins/*/plugin.json: jq -e .
 │                                                     │   └── required-field check (name/owner/plugins, plugin name)
 │                                                     │ exit 0/1
```

### Recommended Project Structure

After Phase 1 ships, the repo looks like this (only the items Phase 1 creates are listed; `.planning/`, `.claude/`, `CLAUDE.md` already exist and are untouched):

```
oplya/
├── .claude-plugin/
│   └── marketplace.json            # marketplace catalog (MKT-01)
├── plugins/
│   └── zapili/
│       ├── .claude-plugin/
│       │   └── plugin.json         # plugin manifest (MKT-02, ZAP-03)
│       └── README.md               # plugin-local README (MKT-03, ZAP-03)
├── scripts/
│   ├── validate-manifests.sh       # local pre-commit validator (MKT-07)
│   ├── install-hooks.sh            # one-time idempotent installer (MKT-07)
│   └── pre-commit                  # hook template that install-hooks.sh copies into .git/hooks/
├── .gitattributes                  # CRLF / LF discipline (MKT-06)
├── .gitignore                      # curated noise list (MKT-05)
├── LICENSE                         # MIT (MKT-04)
└── README.md                       # marketplace-level README (MKT-03)
```

**Component Responsibilities**

| File | Responsibility | Phase 1 owner |
|------|----------------|---------------|
| `.claude-plugin/marketplace.json` | Lists `zapili` as the sole plugin; pins `metadata.pluginRoot`; supplies marketplace identity | MKT-01 |
| `plugins/zapili/.claude-plugin/plugin.json` | Declares plugin name + polish metadata; zero component keys | MKT-02, ZAP-03 |
| `plugins/zapili/README.md` | What `zapili` does + prerequisites + TASK.md stub + cross-link | MKT-03, ZAP-03 |
| `README.md` (top-level) | Marketplace pitch + plugin index + install commands + dev-loop pointer | MKT-03 |
| `LICENSE` | MIT text with 2026 + `Pavel <pavel.proger@gmail.com>` | MKT-04 |
| `.gitignore` | Suppresses noise + `.zapili/` + `.claude/cache/` | MKT-05 |
| `.gitattributes` | Forces LF on `*.sh` / `*.bash` | MKT-06 |
| `scripts/validate-manifests.sh` | bash + jq validator (parse + required fields), exit 0/1, surfaces all failures | MKT-07 |
| `scripts/install-hooks.sh` | Idempotent one-time installer of `.git/hooks/pre-commit` | MKT-07 |
| `scripts/pre-commit` | Template copied into `.git/hooks/pre-commit` by `install-hooks.sh` | MKT-07 |

### Pattern 1: Stable scaffold with auto-discoverable plugin folders

**What:** Ship the absolute minimum that lets `/plugin install` succeed; rely on default-folder auto-discovery for later phases.
**When to use:** Always, for any first-phase plugin skeleton.
**Why:** Declaring `commands: …`, `agents: …`, `hooks: …` keys in `plugin.json` for non-existent folders is a footgun — when later phases populate the default folders (`commands/`, `agents/`, `hooks/`), auto-discovery picks them up without a manifest edit. Explicit declarations would either need editing (extra coupling) or would mis-point at a non-existent path (load warning).
**Source:** [VERIFIED: code.claude.com/docs/en/plugins-reference § "Component path fields"] — keys are only needed for non-default locations.

### Pattern 2: Project-owned validator + opt-in pre-commit wiring

**What:** A self-contained `scripts/validate-manifests.sh` is the single source of validation truth; `scripts/install-hooks.sh` is a separate idempotent installer the user runs once.
**When to use:** When the project explicitly opts out of CI (per MKT-06) but wants light pre-commit hygiene.
**Why:** Decouples validation logic from git-hook plumbing. The validator works as a standalone CLI (`./scripts/validate-manifests.sh`) for ad-hoc inspection or future CI re-use; the installer can be re-run safely (idempotent) and refuses to clobber a user-customized hook (D-18). Avoids "magic" auto-install.
**Source:** Direct extension of project decision (CONTEXT.md D-11..D-19); pattern matches `pre-commit`-framework conventions without taking the npm/Python dep.

### Pattern 3: Single-source-of-truth schema URLs in `$schema`

**What:** Pin `$schema` in each manifest to a stable, publicly fetchable JSON Schema URL.
**When to use:** Whenever editors / IDEs would benefit from inline schema-aware autocomplete (always — costs nothing).
**Why:** Claude Code itself ignores `$schema` at load time, so this is purely an editor-experience win. VS Code / IntelliJ JSON tooling fetches the schema and provides field hints + validation in the editor.
**Source:** [VERIFIED: code.claude.com/docs/en/plugins-reference table] [VERIFIED: schemastore.org catalog] [VERIFIED: anthropics/claude-plugins-official `marketplace.json`]

### Anti-Patterns to Avoid

- **Putting `commands/`, `agents/`, `hooks/` inside `.claude-plugin/`** — the loader will silently not find them. `.claude-plugin/` is only for `plugin.json`. [VERIFIED: code.claude.com/docs/en/plugins-reference § "Plugin directory layout"]
- **Relative paths with `../` in `marketplace.json` `source` fields** — rejected at validation; also doesn't work after the cache copy. Use `./plugins/<name>` (must start with `./`). [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Plugin sources"]
- **Setting `"version"` in `plugin.json` while iterating** — users get no updates until you bump it. PROJECT mandates commit-SHA versioning (D-09). [VERIFIED: code.claude.com/docs/en/plugins-reference § "Version management"]
- **Comments / trailing commas in `marketplace.json` / `plugin.json`** — strict RFC 8259 JSON parser; both cause load failure. [VERIFIED: code.claude.com/docs/en/plugins-reference]
- **Putting any secret in `plugin.json`** — file is committed publicly. (Not a Phase 1 risk since Phase 1 ships no secrets; flagged for downstream phases.)
- **Hardcoded absolute paths in scripts/manifests** — plugins get copied into `~/.claude/plugins/cache/<sha>/` at install time; absolute repo-paths instantly break for users. (Not a Phase 1 risk — scripts run only from the source repo, never from the cached plugin install — but flagged for Phase 2.)
- **CRLF line endings on `.sh` files** — bash reads `#!/usr/bin/env bash\r` and tries to invoke a literal `bash\r` interpreter. MKT-06 `.gitattributes` mitigates this, but only if the file is added correctly the first time.
- **Missing executable bit on `scripts/*.sh`** — `git ls-files --stage` must show `100755`, not `100644`. Run `chmod +x scripts/*.sh` before `git add`. [VERIFIED: PITFALLS.md § Pitfall 3]
- **Trailing/embedded BOM in JSON files** — strict JSON parsers reject UTF-8 BOM. Write manifests in plain UTF-8 with no BOM.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON parse / well-formedness check | Custom regex or sed-based JSON inspector | `jq -e . <file>` | jq is the de facto standard for JSON in shell, handles every edge case, exit code 0/non-zero is the test. |
| JSON field presence check | hand-rolled grep on `"name":` | `jq -e '.name // error("missing name")'` | grep matches inside strings, comments, nested values. jq queries are structural. |
| Manifest schema validation | Hand-rolled type checks for every field | `jq -e 'type == "string"'` patterns OR `claude plugin validate` as supplementary | The project's required validator (D-12) is intentionally minimal (parse + required-name fields). For deeper checks, defer to the official validator. |
| Pre-commit framework | Building a generic pre-commit dispatch loop | Plain `.git/hooks/pre-commit` shell script (per D-17) | The single check needed is per-file gated; a full framework is over-engineering for one validator. PROJECT mandates "no language runtime"; pre-commit-framework requires Python. |
| Idempotent installer | Custom file-equality + diff logic from scratch | `cmp -s "$src" "$dst"` for byte-equality and `diff -u "$src" "$dst"` for display | Standard POSIX tools; cmp returns 0/1 cleanly for byte-identical detection. |
| MIT LICENSE text | Custom paraphrase of the MIT license | Verbatim text from the OSI canonical MIT-License template | Variation in license text invalidates SPDX `MIT` identifier matching and can cause license-detection tools to flag the repo as non-standard. Copy verbatim. |
| `.gitignore` patterns | Hand-collected list | `github/gitignore` curated patterns (Node, Python, Global/macOS, Global/Windows, Global/Linux, JetBrains, VisualStudioCode) — copy relevant lines verbatim | The canonical patterns cover edge cases (e.g., `.pnp.*`, `pip-wheel-metadata/`) a hand-rolled list would miss. |

**Key insight:** This phase is small enough that the temptation to hand-roll is real, but every "small" custom solution above has a one-line stdlib answer that's both shorter and more robust.

## Common Pitfalls

### Pitfall 1: `owner.url` field in `marketplace.json` (CONTEXT.md drift)

**What goes wrong:** CONTEXT.md D-02 specifies `owner: { name, email, url }`. The live spec at `code.claude.com/docs/en/plugin-marketplaces § "Owner fields"` documents only `name` (required) + `email` (optional). The canonical reference repo `anthropics/claude-plugins-official` uses only `{ name, email }` — no `url`.
**Why it happens:** `author` (in `plugin.json`) DOES officially support `url` (official docs example: `{"name": "Dev Team", "email": "dev@company.com"}` plus reference examples with `url`). It's natural to assume the marketplace-level `owner` mirrors the plugin-level `author`. It does not — they are different schemas.
**Impact:** Loads fine at runtime — Claude Code ignores unrecognized fields ([VERIFIED: code.claude.com/docs/en/plugins-reference § "Unrecognized fields"]) — but `claude plugin validate --strict` will emit a warning treated as an error.
**How to avoid:** Two options, both safe:
  1. **Drop `owner.url`** — match the documented schema and the canonical example. Lose nothing (the URL adds no UX value at the `owner` level).
  2. **Keep `owner.url`** — accept the `--strict` warning. The PROJECT does not require `--strict`-clean; D-12's validator only checks `name`, `owner`, `plugins` presence, not unknown-field rejection.
**Recommendation:** **Drop `owner.url` for the marketplace** (deviates from D-02). Move the GitHub URL to the `plugin.json` `author.url` (which IS officially supported per D-08) and the `marketplace.json` per-plugin entry's `repository` field (officially supported per the plugin-manifest schema, which the marketplace entry inherits). This satisfies the user's intent (provide GitHub link) without drifting from the spec. **The planner must surface this to the user as a confirmation prompt** before locking it.
**Warning signs:** `claude plugin validate --strict .` emits "unrecognized field: owner.url".
**Source:** [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Owner fields"] [VERIFIED: anthropics/claude-plugins-official marketplace.json]

### Pitfall 2: `marketplace.json` placed at repo root instead of `.claude-plugin/marketplace.json`

**What goes wrong:** `/plugin marketplace add nepavel/oplya` fails with "marketplace not found" or "invalid marketplace".
**Why it happens:** Natural instinct from `package.json` / `Cargo.toml` is to put the catalog at repo root. The Claude Code spec requires `.claude-plugin/marketplace.json` — a hidden directory many editors hide by default.
**How to avoid:** Pin the exact path in the README's "Repository layout" section; the project validator (D-12) checks the exact path `.claude-plugin/marketplace.json` exists and parses.
**Warning signs:** `find .claude-plugin -name marketplace.json -maxdepth 2` returns nothing; fresh-clone smoke test of `/plugin marketplace add` fails.
**Source:** [CITED: .planning/research/PITFALLS.md § Pitfall 1] [VERIFIED: code.claude.com/docs/en/plugin-marketplaces]

### Pitfall 3: Per-plugin manifest path is `plugins/zapili/.claude-plugin/plugin.json`, NOT `plugins/zapili/plugin.json`

**What goes wrong:** Plugin loader silently doesn't find the manifest; the plugin is treated as "no manifest" (which technically loads in v2.1.142+ for single-skill plugins, but without metadata).
**Why it happens:** Same instinct as Pitfall 2 — the `.claude-plugin/` directory feels redundant inside each plugin folder.
**How to avoid:** The project validator (D-12) scans for `plugins/*/.claude-plugin/plugin.json` exactly — getting the path wrong is detected.
**Warning signs:** `plugins/zapili/plugin.json` exists at the wrong level; `claude plugin validate ./plugins/zapili` reports missing manifest.
**Source:** [VERIFIED: code.claude.com/docs/en/plugins-reference § "Plugin directory layout"]

### Pitfall 4: `source` field in `marketplace.json` contains `../` or doesn't start with `./`

**What goes wrong:** Validation rejects the manifest at marketplace-add time with "Path contains '..'" or "invalid relative path".
**Why it happens:** Path-walking conventions from other ecosystems.
**How to avoid:** With `metadata.pluginRoot: "./plugins"` (D-04), `source` can be either `"zapili"` (resolved against `pluginRoot`) or `"./plugins/zapili"` (absolute-from-repo-root). CONTEXT.md D-04 commentary picks the explicit form for clarity.
**Source:** [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Plugin sources"]

### Pitfall 5: URL-based marketplace add breaks relative `source` paths

**What goes wrong:** If a user adds the marketplace via a direct URL to the raw `marketplace.json` (instead of the GitHub `owner/repo` shorthand), relative `source` paths like `./plugins/zapili` cannot resolve.
**Why it happens:** The marketplace's `source` paths are relative to the marketplace repo's git root; URL-based add fetches only the JSON file with no surrounding git context.
**Impact for Phase 1:** None directly — D-06 mandates `nepavel/oplya` (GitHub shorthand) as the canonical install instruction in the README. But: the top-level README MUST NOT suggest a URL-based add as an alternative; users who try it will hit this exact failure.
**How to avoid:** README install instructions specify GitHub shorthand only: `/plugin marketplace add nepavel/oplya`. Do not include a URL-based alternative in v1.
**Source:** [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Plugin sources" note]

### Pitfall 6: Reserved marketplace name collision

**What goes wrong:** If `oplya` or `zapili` were on the official reserved-names list, marketplace registration would fail with a name-collision error and require a rename.
**Why it happens:** Anthropic reserves a set of names for official marketplaces (e.g., `claude-code-plugins`, `anthropic-plugins`, `claude-plugins-official`, `agent-skills`, etc.) and blocks impersonation (`official-*`, `anthropic-*-v2`).
**Status:** [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Reserved names" Note as of 2026-05-27] Neither `oplya` (marketplace name) nor `zapili` (plugin name) appears on the published list of reserved or blocked names. The reserved list covers marketplace names; per-plugin name reservation is not currently enforced separately. The phase is therefore safe to proceed with the current names. (CONTEXT.md "Deferred Ideas" notes the Phase 6 re-check, which this research already preempts.)
**How to avoid:** No action required for Phase 1; planner should still re-verify at Phase 6 release time per the existing schedule.
**Source:** [VERIFIED: code.claude.com/docs/en/plugin-marketplaces § "Reserved names" Note]

### Pitfall 7: `scripts/validate-manifests.sh` stops at first failure

**What goes wrong:** Multi-file errors get reported one-at-a-time across multiple commit attempts.
**Why it happens:** Naive bash uses `set -e` which exits on the first nonzero command.
**How to avoid:** D-13 mandates surfacing ALL failures in one pass. Implementation pattern: collect failures into a counter (e.g., `errors=0`), increment on each problem, return `$((errors == 0 ? 0 : 1))` at the end. Do NOT use `set -e` for the validation loop (use it for setup, then disable around the loop with `set +e` and restore).
**Warning signs:** Validator output shows exactly one error per run despite two known-broken files staged.
**How to detect:** Test fixture — deliberately break TWO manifest fields, run validator, count the error lines (should be ≥2).

### Pitfall 8: `install-hooks.sh` silently clobbers a user-customized hook

**What goes wrong:** A contributor has their own `.git/hooks/pre-commit` (e.g., a personal linter). `install-hooks.sh` overwrites it without warning, breaking their workflow.
**Why it happens:** Naive `cp scripts/pre-commit .git/hooks/pre-commit` does no comparison.
**How to avoid:** Per D-18 — if `.git/hooks/pre-commit` exists AND `cmp -s` says it is byte-identical to the template, no-op (silent OK); if it exists and differs, print `diff -u`, print remediation instructions, exit 1.
**Warning signs:** Contributors report "my pre-commit was deleted after running install-hooks.sh".

### Pitfall 9: `git diff --cached --name-only` returns no output when called outside a repo

**What goes wrong:** If `install-hooks.sh` is run from outside a git repo (or the user has not initialized git yet), `git rev-parse --git-dir` fails and `.git/hooks/` doesn't exist.
**Why it happens:** Shipping a hook installer that assumes a git repo without checking.
**How to avoid:** `install-hooks.sh` begins with `git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo"; exit 1; }`. The installed pre-commit hook itself can safely assume it's inside `.git/hooks/`, so it's already in a git context — no additional guard needed there.

### Pitfall 10: `jq` not installed on the host

**What goes wrong:** Validator dies with `command not found: jq` and a generic stderr — user doesn't know what to install.
**How to avoid:** Per D-15 — explicit `command -v jq >/dev/null 2>&1 || { echo "jq required: install via 'brew install jq' / 'apt install jq' / 'sudo dnf install jq'"; exit 1; }` as the first check inside the validator.
**Source:** [CITED: CONTEXT.md D-15]

### Pitfall 11: `.gitattributes` set AFTER `.sh` files are already committed with CRLF

**What goes wrong:** `.gitattributes` only normalizes on future checkouts/commits; existing committed-with-CRLF files stay CRLF until `git add --renormalize .` is run.
**Why it happens:** Adding `.gitattributes` is conceptually "fix from now on", but git's working-tree normalization is lazy.
**How to avoid:** For a greenfield Phase 1, this is not a risk — `.gitattributes` is created BEFORE any `.sh` file is committed. The planner should sequence: `.gitattributes` first, scripts second. If for any reason scripts get committed first, follow up with `git add --renormalize . && git commit -m "normalize line endings"`.

### Pitfall 12: README install commands documented before the install path works

**What goes wrong:** Phase 1 README says `/plugin install zapili@oplya`; if the user runs this before Phase 1 lands on `main`, they get a confusing error.
**Why it happens:** Documentation describes the desired state, not the current commit's state.
**Impact for Phase 1:** Real but contained — the README is correct as of the commit that lands Phase 1; nothing earlier exists publicly. Documented in the success criterion that this READme works against the Phase-1 commit specifically.
**How to avoid:** Smoke-test the install commands against the Phase-1 commit on a fresh clone before merging the phase.

## Code Examples

Verified patterns from official sources and from CLAUDE.md § "Technology Stack". All shapes verified live on 2026-05-27.

### Example 1: `.claude-plugin/marketplace.json` (after Pitfall 1 mitigation)

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "oplya",
  "description": "Personal plugin marketplace — multi-agent dev workflows",
  "owner": {
    "name": "Pavel",
    "email": "pavel.proger@gmail.com"
  },
  "metadata": {
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "zapili",
      "source": "./plugins/zapili",
      "displayName": "zapili",
      "description": "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review",
      "category": "workflow",
      "repository": "https://github.com/nepavel/oplya"
    }
  ]
}
```

Notes:
- `$schema` uses the official Anthropic URL (verified against `anthropics/claude-plugins-official`). The schemastore equivalent (`https://www.schemastore.org/claude-code-marketplace.json`) also works.
- `owner.url` is **omitted** per Pitfall 1 — confirm with user.
- `displayName` and `repository` at the plugin-entry level are inherited from the plugin-manifest schema per the marketplace docs.

### Example 2: `plugins/zapili/.claude-plugin/plugin.json`

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "zapili",
  "displayName": "zapili",
  "description": "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review",
  "author": {
    "name": "Pavel",
    "email": "pavel.proger@gmail.com",
    "url": "https://github.com/nepavel"
  },
  "homepage": "https://github.com/nepavel/oplya",
  "repository": "https://github.com/nepavel/oplya",
  "license": "MIT",
  "keywords": ["workflow", "multi-agent", "codex", "planning", "parallel"]
}
```

Notes:
- `$schema` from JSON Schema Store as documented in the official Claude Code plugins reference.
- `author.url` IS officially supported (verified via `code.claude.com/docs/en/plugins-reference` table example).
- No `version` (commit-SHA versioning per D-09).
- No `category` here — `category` is a marketplace-entry field, not a plugin-manifest field (verified via the plugin-marketplaces docs: `category` listed under "marketplace-specific fields"). Putting it here is unrecognized-field territory. CONTEXT.md D-08 incorrectly lists it here; it belongs in the marketplace entry instead (already added there in Example 1). **Confirm with user before locking.**
- No `commands`, `agents`, `hooks`, `mcpServers` keys (D-10).

### Example 3: `LICENSE` (MIT, verbatim OSI template, year + holder filled)

```
MIT License

Copyright (c) 2026 Pavel <pavel.proger@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Example 4: `.gitignore`

```gitignore
# zapili runtime state (per-task working-dir cache)
.zapili/

# Claude Code per-plugin cache
.claude/cache/

# OS noise
.DS_Store
Thumbs.db
ehthumbs.db
Desktop.ini

# Editor / IDE
.idea/
.vscode/
*.swp
*.swo
*~
.project
.settings/

# Node
node_modules/
dist/
build/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnp.*

# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
.venv/
venv/
env/
.pytest_cache/

# Env files
.env
.env.local
.env.*.local
```

### Example 5: `.gitattributes`

```gitattributes
# LF line endings on shell scripts — non-negotiable (MKT-06)
*.sh   text eol=lf
*.bash text eol=lf

# Consistency for the rest of the text formats we author
*.json text eol=lf
*.md   text eol=lf

# Mark generated/binary types so git doesn't try to diff them
*.png binary
*.jpg binary
```

### Example 6: `scripts/validate-manifests.sh`

```bash
#!/usr/bin/env bash
# Validate marketplace.json and every per-plugin plugin.json.
# Surfaces every error in one pass (D-13). Exit 0 on success, 1 on any failure.

set -uo pipefail   # NOT -e: we want to surface ALL failures, not stop at first

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (install: 'brew install jq' / 'apt install jq' / 'dnf install jq')" >&2
  exit 1
fi

errors=0
fail() {
  echo "FAIL: $*" >&2
  errors=$((errors + 1))
}

check_json() {
  local file="$1"
  if [ ! -f "$file" ]; then
    fail "$file: not found"
    return 1
  fi
  if ! jq -e . "$file" >/dev/null 2>&1; then
    fail "$file: invalid JSON"
    return 1
  fi
  return 0
}

require_field() {
  local file="$1" path="$2"
  if ! jq -e "$path" "$file" >/dev/null 2>&1; then
    fail "$file: missing required field $path"
  fi
}

# Marketplace
MARKETPLACE=".claude-plugin/marketplace.json"
if check_json "$MARKETPLACE"; then
  require_field "$MARKETPLACE" '.name'
  require_field "$MARKETPLACE" '.owner.name'
  require_field "$MARKETPLACE" '.plugins'
  # plugins must be an array
  if ! jq -e '.plugins | type == "array"' "$MARKETPLACE" >/dev/null 2>&1; then
    fail "$MARKETPLACE: .plugins must be an array"
  fi
fi

# Per-plugin manifests
shopt -s nullglob
for manifest in plugins/*/.claude-plugin/plugin.json; do
  if check_json "$manifest"; then
    require_field "$manifest" '.name'
  fi
done
shopt -u nullglob

if [ "$errors" -gt 0 ]; then
  echo "validation failed: $errors error(s)" >&2
  exit 1
fi
echo "ok: all manifests valid"
exit 0
```

### Example 7: `scripts/install-hooks.sh`

```bash
#!/usr/bin/env bash
# Idempotent installer for the pre-commit hook.
# - byte-identical hook → no-op
# - differing existing hook → diff + abort (do not overwrite)
# - no hook → install
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 1
fi

GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
SRC="scripts/pre-commit"
DST="$GIT_HOOKS_DIR/pre-commit"

if [ ! -f "$SRC" ]; then
  echo "error: template not found at $SRC (run from repo root)" >&2
  exit 1
fi

mkdir -p "$GIT_HOOKS_DIR"

if [ -e "$DST" ]; then
  if cmp -s "$SRC" "$DST"; then
    echo "ok: pre-commit already installed (byte-identical)"
    exit 0
  fi
  echo "error: $DST already exists and differs from $SRC" >&2
  echo "diff (expected vs current):" >&2
  diff -u "$SRC" "$DST" >&2 || true
  echo >&2
  echo "to overwrite, remove $DST manually first, then re-run." >&2
  exit 1
fi

cp "$SRC" "$DST"
chmod +x "$DST"
echo "ok: installed pre-commit at $DST"
```

### Example 8: `scripts/pre-commit` (the template installed into `.git/hooks/`)

```bash
#!/usr/bin/env bash
# Pre-commit hook: only validate when manifest files are staged.
set -euo pipefail

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)

if echo "$STAGED" | grep -Eq '^(\.claude-plugin/marketplace\.json|plugins/[^/]+/\.claude-plugin/plugin\.json)$'; then
  exec ./scripts/validate-manifests.sh
fi

exit 0
```

### Example 9: Top-level `README.md` (skeleton — planner fills the prose)

```markdown
# oplya — Claude Code Plugin Marketplace

A personal plugin marketplace for multi-agent dev workflows.

## Plugins

| Plugin | Description |
|--------|-------------|
| `zapili` | Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review. See [`plugins/zapili/README.md`](plugins/zapili/README.md). |

## Install

```bash
/plugin marketplace add nepavel/oplya
/plugin install zapili@oplya
```

`zapili` requires the [`codex` CLI](https://github.com/openai/codex). See the plugin README for prerequisites.

## Local development

```bash
git clone https://github.com/nepavel/oplya
cd oplya
./scripts/install-hooks.sh        # one-time: enables manifest validation on commit
./scripts/validate-manifests.sh   # run anytime to check manifests
claude --plugin-dir ./plugins/zapili  # load the plugin locally for testing
```

## License

MIT — see [LICENSE](LICENSE).
```

### Example 10: `plugins/zapili/README.md` (skeleton)

```markdown
# zapili

A multi-agent development workflow plugin for Claude Code. Drop a `TASK.md` into your working directory, run `/zapili:zapili`, and `zapili` drives research → plan → wave-parallel implementation, with each stage independently reviewed by the `codex` CLI.

## Prerequisites

- The [`codex` CLI](https://github.com/openai/codex) installed and authenticated (`codex --version` should succeed; sign in via ChatGPT or set `OPENAI_API_KEY`).
- Claude Code v2.1.143 or later.

## How to author a `TASK.md`

Create a `TASK.md` in the directory where you want changes to land. Describe the change you want, the constraints you care about, and any context links. `zapili`'s researcher will read it, classify the task size, and ask focused follow-up questions before any code is written.

A minimal `TASK.md` looks like:

```markdown
# Add JWT auth to the /login endpoint

Stack: Node 20 + Express + Postgres.
Constraints: backward-compatible with existing session cookie clients for ≥1 release.
References: see src/auth/ for current shape.
```

The full TASK.md schema and worked examples ship in a later release.

## Install

See the [marketplace README](../../README.md#install).

## Status

> The slash command surface is not yet wired in this release. This plugin's manifest is published so the marketplace install path is testable end-to-end; the orchestrator slash command lands in the next release.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Task(...)` tool reference in agent allowed-tools | `Agent(...)` syntax | Claude Code v2.1.63 | Not Phase 1 concern (no agents in Phase 1), but flagged for Phase 4/5 planners. |
| `--full-auto` flag on codex | `--sandbox <level>` explicit | codex CLI 2026 | Not Phase 1 concern (no codex invocations), flagged for Phase 4. |
| Single-skill plugin via `"skills": ["./"]` | Auto-load when `SKILL.md` is at plugin root | Claude Code v2.1.142+ | Not Phase 1 concern (no skills shipped). |

**Deprecated / outdated:**
- nothing relevant to Phase 1 — Phase 1 only touches manifests, hygiene files, and bash scripts.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `category` is a marketplace-entry field, not a plugin-manifest field — placing it in `plugin.json` is "unrecognized field" territory | Pitfall 1 / Example 2 | LOW — Claude Code ignores unrecognized fields. The risk is a `--strict` validator warning. Mitigation: move `category` to the marketplace entry per Example 1 + 2. |
| A2 | The schemastore.org URL `https://json.schemastore.org/claude-code-plugin-manifest.json` resolves to the same content as `https://www.schemastore.org/claude-code-plugin-manifest.json` | Example 2 | LOW — Both work; if the `json.` subdomain is decommissioned, editors lose autocomplete but Claude Code still loads (it ignores `$schema`). |
| A3 | `claude plugin validate` exists and the CLI flags shown are stable | Standard Stack table | VERIFIED on local host — `claude plugin validate --help` confirmed. |

**No claims tagged `[ASSUMED]` carry HIGH risk.** Pitfall 1 (`owner.url`) and Example 2 (`category` in plugin.json) are flagged for user confirmation but are non-blocking — the worst-case is a `--strict` validator warning.

## Open Questions

1. **`owner.url` in `marketplace.json` — keep or drop?**
   - What we know: CONTEXT.md D-02 specifies it; official spec does not document it; canonical reference repo doesn't use it; runtime accepts it; `--strict` flags it.
   - What's unclear: whether the user prefers spec-purity (drop) vs. discoverability (keep + accept the lint warning).
   - Recommendation: **drop from `owner`, move the GitHub URL to `plugin.json` `author.url` and `marketplace.json` plugin-entry `repository`** — both officially supported. Surface this to the user as a one-line confirmation; default to drop.

2. **`category` in `plugin.json` — drop or relocate?**
   - What we know: CONTEXT.md D-08 lists it in `plugin.json`; the documented `plugin.json` schema does NOT list `category`; the marketplace-entry schema DOES (and the value is shown there in Example 1).
   - What's unclear: whether D-08 intentionally puts it in both places or whether it's a documentation drift.
   - Recommendation: **keep `category` ONLY in the marketplace entry (Example 1); remove from `plugin.json` (Example 2).** Same reasoning as A1.

3. **Does the project want `claude plugin validate --strict` as an optional supplementary check documented in the README?**
   - What we know: D-12 explicitly scopes the required validator to bash+jq + required-field checks.
   - What's unclear: whether to recommend `claude plugin validate --strict` in the README as a developer-side spot-check.
   - Recommendation: mention it in the top-level README's "Local development" section as optional ("If you have `claude` installed, you can also run `claude plugin validate . --strict` for deeper checks."). Adds zero install cost; benefits power users.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `bash` | All `scripts/*.sh` | ✓ | 5.2.21 | — |
| `jq` | `scripts/validate-manifests.sh` | ✓ | 1.7 | — (script exits with remediation per D-15) |
| `git` | `scripts/install-hooks.sh`, installed pre-commit | ✓ | 2.43.0 | — |
| `claude` CLI | Optional supplementary `claude plugin validate` | ✓ | present (subcommands verified) | — (project validator is the required gate) |
| `codex` CLI | Not used in Phase 1 (only referenced in plugin README as a future runtime requirement) | ✓ | present | — |
| `cmp`, `diff`, `cat`, `find` | POSIX utilities used in `install-hooks.sh` and `validate-manifests.sh` | ✓ | system | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash test scripts (no formal harness) — Phase 1 has no production code to unit-test; verification is shell-based smoke tests |
| Config file | none — see Wave 0 |
| Quick run command | `./scripts/validate-manifests.sh` |
| Full suite command | `./scripts/validate-manifests.sh && /plugin marketplace add ./ && /plugin install zapili@oplya` (the marketplace-add + install steps are manual smoke tests in a Claude Code session) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| MKT-01 | `marketplace.json` parses + has required fields | smoke | `jq -e . .claude-plugin/marketplace.json && jq -e '.name, .owner.name, .plugins' .claude-plugin/marketplace.json` | ❌ Wave 0 |
| MKT-02 | `plugin.json` parses + has `name` | smoke | `jq -e . plugins/zapili/.claude-plugin/plugin.json && jq -e '.name' plugins/zapili/.claude-plugin/plugin.json` | ❌ Wave 0 |
| MKT-03 | Top-level + plugin READMEs present + non-empty + English | manual | `test -s README.md && test -s plugins/zapili/README.md` (manual eyeball for English + D-25/D-26 sections) | ❌ Wave 0 |
| MKT-04 | LICENSE present + parses as MIT | smoke | `test -f LICENSE && grep -q "MIT License" LICENSE` | ❌ Wave 0 |
| MKT-05 | `.gitignore` covers `.zapili/`, `.claude/cache/`, `node_modules/`, `__pycache__/`, `.DS_Store` | smoke | `for p in .zapili/ .claude/cache/ node_modules/ __pycache__/ .DS_Store; do grep -q "^$p\$\|^$p" .gitignore || echo "missing: $p"; done` | ❌ Wave 0 |
| MKT-06 | `.gitattributes` enforces LF on `.sh`/`.bash` | smoke | `grep -q "^\*\.sh.*eol=lf" .gitattributes && grep -q "^\*\.bash.*eol=lf" .gitattributes` | ❌ Wave 0 |
| MKT-07 | Validator exits 0 on good manifests, 1 on broken, reports ALL failures | smoke | `./scripts/validate-manifests.sh` (positive); deliberately break a field and re-run, count failure lines (negative) | ❌ Wave 0 |
| MKT-08 | No cross-plugin file references; plugin tree contains only `.claude-plugin/plugin.json` + `README.md` | smoke | `find plugins/zapili -type f \| grep -vE '\\.claude-plugin/plugin\\.json\|README\\.md' && exit 1` (should produce no extra files) | ❌ Wave 0 |
| ZAP-03 | Plugin README mentions codex CLI prerequisite | smoke | `grep -qi "codex" plugins/zapili/README.md` | ❌ Wave 0 |
| (composite) | Fresh-clone install round-trip | manual | `/plugin marketplace add nepavel/oplya` then `/plugin install zapili@oplya` in a Claude Code session — verify both succeed without errors | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `./scripts/validate-manifests.sh` (runs automatically via the installed pre-commit hook when manifests are staged)
- **Per wave merge:** all smoke-test commands above (Phase 1 has effectively one wave)
- **Phase gate:** the composite fresh-clone install round-trip is run manually in a Claude Code session before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No formal test harness needed — Phase 1 verification is purely shell + manual install smoke test.
- [ ] `tests/` directory is intentionally NOT created in Phase 1 per D-23. Phase 3 owns `plugins/zapili/tests/fixtures/`.
- [ ] One optional addition: a `scripts/test-validator.sh` that creates a temp directory with deliberately-broken manifests and asserts the validator reports the expected number of failures. **Recommendation:** add this; it's a 30-line script and it catches Pitfall 7 (single-failure-only validator) directly. Planner should decide whether this is in-scope for Phase 1 or deferred.

## Security Domain

Phase 1 has minimal security surface — no runtime code, no network calls, no user input parsing. The relevant ASVS categories are:

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | partial | The validator parses JSON with `jq` (a hardened parser); shell scripts don't accept untrusted input. |
| V6 Cryptography | no | — |
| V8 Data Protection | partial | `.gitignore` includes `.env`, `.env.local`, etc. to prevent accidental secret commits. |
| V14 Configuration | yes | `.gitattributes` enforces LF on shell scripts (prevents interpreter-name injection via CRLF artefacts); LICENSE clearly states MIT terms; manifests do not embed secrets. |

### Known Threat Patterns for static-repo-skeleton phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental secret commit via missing `.gitignore` entry | Information Disclosure | `.gitignore` includes `.env`, `.env.local`, `.env.*.local` per D-21 |
| CRLF-induced shell interpreter spoofing | Tampering / DoS | `.gitattributes` `*.sh text eol=lf` per D-22 + `chmod +x` discipline |
| Malicious clobber of user's pre-commit hook | Tampering | `install-hooks.sh` idempotence + diff-on-conflict per D-18 |
| Validator runs arbitrary code via JSON content | Code Execution | `jq -e .` only parses; no `eval`; bash quotes `$file` everywhere |
| Reserved/blocked marketplace name registration | Repudiation / Naming | Pre-checked against the live reserved-names list (Pitfall 6) — clear as of 2026-05-27 |

## Sources

### Primary (HIGH confidence)
- [VERIFIED: code.claude.com/docs/en/plugin-marketplaces] — live `marketplace.json` schema; required/optional fields; owner schema; `metadata.pluginRoot`; plugin-source rules; reserved names; strict mode (re-fetched 2026-05-27).
- [VERIFIED: code.claude.com/docs/en/plugins-reference] — live `plugin.json` schema; required (`name`) + optional fields; component path fields; `$schema` URL; `--strict` semantics; unrecognized-field policy (re-fetched 2026-05-27).
- [VERIFIED: anthropics/claude-plugins-official `marketplace.json`] — canonical reference repo; owner shape confirmation (no `url`); `$schema` URL confirmation.
- [VERIFIED: schemastore.org catalog] — canonical `$schema` URLs for both marketplace and plugin manifests.
- [VERIFIED: env probe on this host] — `jq 1.7`, `git 2.43.0`, `bash 5.2.21`, `claude plugin validate --help`, `claude plugin marketplace --help`.

### Secondary (MEDIUM confidence)
- [CITED: .planning/research/STACK.md] — full project-level stack research, Pitfall list, manifest snippets reused verbatim where they match the live spec.
- [CITED: .planning/research/PITFALLS.md] — pre-existing project-level Phase 1 pitfalls (1–5, 19–20) — all verified against live docs in this research.
- [CITED: CLAUDE.md § "Technology Stack"] — locked tech stack treated as ground truth per project instructions.

### Tertiary (LOW confidence — informational only)
- none — Phase 1 is well-documented; no LOW-confidence claims in this research.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all schemas, fields, and tools verified against live official docs and local env on 2026-05-27.
- Architecture: HIGH — pure static layout, directly dictated by the Claude Code spec; no design freedom to get wrong.
- Pitfalls: HIGH — every catastrophic pitfall has either an official docs source (Pitfalls 2, 3, 4, 5, 6) or a direct mechanical detection method (Pitfalls 7–12).

**Research date:** 2026-05-27
**Valid until:** ~2026-06-27 (stable manifest schema; re-verify only if Claude Code rev-bumps the marketplace or plugin schema).

**Re-verification triggers (re-run a quick check if):**
- Claude Code major version bump (currently stable; field additions are backward-compatible).
- `anthropics/claude-plugins-official` repository structure changes.
- A new reserved-name is added to the `code.claude.com/docs/en/plugin-marketplaces` reserved list (re-verify at Phase 6 release time per existing schedule).
