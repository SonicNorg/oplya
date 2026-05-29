---
phase: 01-marketplace-plugin-skeleton
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .claude-plugin/marketplace.json
  - plugins/zapili/.claude-plugin/plugin.json
autonomous: true
requirements:
  - MKT-01
  - MKT-02
  - MKT-03
  - ZAP-03
must_haves:
  truths:
    - "Marketplace JSON parses and lists exactly one plugin entry named zapili"
    - "Plugin manifest parses and identifies the plugin as zapili"
    - "Neither manifest contains owner.url (marketplace) nor category (plugin) per RESEARCH drift fixes"
    - "Plugin manifest omits the version field (commit-SHA versioning per D-09)"
    - "Source path for the zapili plugin entry is ./plugins/zapili (explicit form, no ../)"
    - "CONTEXT.md decisions implemented by this plan: D-02, D-03, D-04, D-05, D-06 (marketplace.json identity + SonicNorg/oplya slug + pluginRoot + single zapili entry); D-07, D-08, D-10 (plugin.json name + metadata + zero component keys); D-23, D-24 (Phase-1 skeleton minimalism — no commands/agents/hooks shipped)"
  artifacts:
    - path: ".claude-plugin/marketplace.json"
      provides: "Marketplace catalog discovered by /plugin marketplace add"
      contains: "\"name\": \"oplya\""
    - path: "plugins/zapili/.claude-plugin/plugin.json"
      provides: "Per-plugin manifest discovered by /plugin install zapili@oplya"
      contains: "\"name\": \"zapili\""
  key_links:
    - from: ".claude-plugin/marketplace.json"
      to: "plugins/zapili/.claude-plugin/plugin.json"
      via: "plugins[].source resolves via metadata.pluginRoot to ./plugins/zapili"
      pattern: "\"source\":\\s*\"\\./plugins/zapili\""
---

<objective>
Author the two JSON manifests that make `oplya` a discoverable marketplace and `zapili` an installable plugin.

Purpose: Without these files at their exact spec-mandated paths, `/plugin marketplace add` and `/plugin install` cannot resolve the plugin. This plan is the load-bearing foundation of Phase 1 — every other plan (READMEs that reference the install path, the validator that scans these files, the install rehearsal) depends on these existing and being well-formed.

Output:
- `.claude-plugin/marketplace.json` — marketplace catalog at the spec-mandated repo-root location with `metadata.pluginRoot: "./plugins"` and one plugin entry for `zapili`.
- `plugins/zapili/.claude-plugin/plugin.json` — per-plugin manifest with `name: "zapili"`, no `version`, no `category` (category lives in the marketplace entry).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md
@.planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md
@.planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write .claude-plugin/marketplace.json</name>
  <files>.claude-plugin/marketplace.json</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-02, D-03, D-04, D-05, D-06 — locked field decisions)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 1 (canonical shape) and § "Common Pitfalls" Pitfall 1 (owner.url drift)
    - CLAUDE.md § "Technology Stack" (verified field list for marketplace.json)
  </read_first>
  <action>
    Create the directory `.claude-plugin/` at repo root and write `marketplace.json` (strict RFC 8259, no comments, no trailing commas, no BOM, LF line endings). Use the exact field set from RESEARCH.md Example 1.

    Required top-level fields with exact values:
    - `$schema`: `"https://anthropic.com/claude-code/marketplace.schema.json"`
    - `name`: `"oplya"` (D-02)
    - `description`: `"Personal plugin marketplace — multi-agent dev workflows"` (D-03)
    - `owner`: object with `name: "Pavel"` and `email: "pavel.proger@gmail.com"` ONLY. DROP `owner.url` per RESEARCH Pitfall 1 — the documented marketplace owner schema is `{name, email}` only; `url` triggers `--strict` warnings and is absent from the canonical reference repo. The GitHub URL belongs on the plugin entry's `repository` field (below) and on `author.url` in plugin.json.
    - `metadata.pluginRoot`: `"./plugins"` (D-04 — enables short-form `source` and clarity).
    - `plugins`: array with exactly ONE entry (D-05) for zapili containing: `name: "zapili"`, `source: "./plugins/zapili"` (explicit form per D-04 — never `../`, must start with `./`), `displayName: "zapili"` (D-03 / D-08), `description: "Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review"`, `category: "workflow"` (category lives HERE per RESEARCH Example 1, NOT in plugin.json), `repository: "https://github.com/SonicNorg/oplya"` (officially supported on plugin entries, carries the GitHub link that was originally proposed for owner.url; D-06 — slug `SonicNorg/oplya`).

    Do NOT include: `version` on the plugin entry (D-05 — commit-SHA versioning); any keys with `null`; trailing commas; comments.
  </action>
  <verify>
    <automated>jq -e . .claude-plugin/marketplace.json &gt;/dev/null &amp;&amp; jq -e '.name == "oplya"' .claude-plugin/marketplace.json &gt;/dev/null &amp;&amp; jq -e '.owner.name == "Pavel" and .owner.email == "pavel.proger@gmail.com" and (.owner | has("url") | not)' .claude-plugin/marketplace.json &gt;/dev/null &amp;&amp; jq -e '.metadata.pluginRoot == "./plugins"' .claude-plugin/marketplace.json &gt;/dev/null &amp;&amp; jq -e '.plugins | type == "array" and length == 1' .claude-plugin/marketplace.json &gt;/dev/null &amp;&amp; jq -e '.plugins[0] | .name == "zapili" and .source == "./plugins/zapili" and .category == "workflow" and .repository == "https://github.com/SonicNorg/oplya"' .claude-plugin/marketplace.json &gt;/dev/null</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .claude-plugin/marketplace.json` exits 0.
    - `jq -e . .claude-plugin/marketplace.json &gt;/dev/null` exits 0 (valid JSON, no BOM).
    - `jq -e '.name == "oplya"' .claude-plugin/marketplace.json &gt;/dev/null` exits 0.
    - `jq -e '.owner | has("url") | not' .claude-plugin/marketplace.json &gt;/dev/null` exits 0 (owner.url is absent — RESEARCH Pitfall 1).
    - `jq -e '.plugins[] | select(.name=="zapili") | .source == "./plugins/zapili"' .claude-plugin/marketplace.json &gt;/dev/null` exits 0 (VALIDATION map task 01-01-02).
    - `jq -e '.metadata.pluginRoot == "./plugins"' .claude-plugin/marketplace.json &gt;/dev/null` exits 0.
    - `file .claude-plugin/marketplace.json | grep -qv "BOM"` (no UTF-8 BOM).
  </acceptance_criteria>
  <done>Marketplace catalog exists at the spec-mandated path with valid JSON, listing zapili as the sole plugin via the short `./plugins/zapili` source.</done>
</task>

<task type="auto">
  <name>Task 2: Write plugins/zapili/.claude-plugin/plugin.json</name>
  <files>plugins/zapili/.claude-plugin/plugin.json</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-07, D-08, D-09, D-10, D-23, D-24 — plugin-manifest decisions)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 2 (canonical shape) and § "Open Questions" Q1+Q2 (category/owner.url drifts)
    - .claude-plugin/marketplace.json (already written by Task 1 — cross-check that `category` is in the marketplace entry, not duplicated here)
    - CLAUDE.md § "Technology Stack" — `plugin.json` field guidance
  </read_first>
  <action>
    Create directories `plugins/zapili/.claude-plugin/` and write `plugin.json` (strict RFC 8259, no comments/trailing commas/BOM, LF endings). Use RESEARCH.md Example 2 verbatim shape.

    Required top-level fields with exact values:
    - `$schema`: `"https://json.schemastore.org/claude-code-plugin-manifest.json"`
    - `name`: `"zapili"` (D-07 — only strictly required field per spec)
    - `displayName`: `"zapili"` (D-08)
    - `description`: `"Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review"` (D-08)
    - `author`: object with `name: "Pavel"`, `email: "pavel.proger@gmail.com"`, `url: "https://github.com/SonicNorg"` (D-08 — `author.url` IS officially supported on plugin.json, unlike `owner.url` on marketplace.json).
    - `homepage`: `"https://github.com/SonicNorg/oplya"`
    - `repository`: `"https://github.com/SonicNorg/oplya"`
    - `license`: `"MIT"` (matches LICENSE delivered by Plan 03)
    - `keywords`: array `["workflow", "multi-agent", "codex", "planning", "parallel"]` (D-08)

    EXPLICITLY FORBIDDEN keys (must be absent):
    - `version` — D-09 mandates commit-SHA versioning; adding `version` silently breaks update propagation for users on `main` until the next bump (PROJECT decision, RESEARCH-confirmed). Phase 6 may add `"version": "1.0.0"` at release; NOT here.
    - `category` — RESEARCH Open Question Q2: category is a marketplace-entry field, not a plugin-manifest field; it already lives in the marketplace entry (Task 1). Including here is unrecognized-field territory and triggers `--strict` warnings.
    - `commands`, `agents`, `hooks`, `mcpServers` — D-10 / D-23 / D-24: Phase 1 ships zero components (skeleton minimalism); default-folder auto-discovery picks them up in Phase 2+ without manifest edits.
  </action>
  <verify>
    <automated>jq -e . plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null &amp;&amp; jq -e '.name == "zapili" and (has("version") | not) and (has("category") | not) and (has("commands") | not) and (has("agents") | not) and (has("hooks") | not) and (has("mcpServers") | not)' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null &amp;&amp; jq -e '.author.name == "Pavel" and .author.email == "pavel.proger@gmail.com" and .author.url == "https://github.com/SonicNorg"' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null &amp;&amp; jq -e '.keywords | type == "array" and length == 5' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null &amp;&amp; jq -e '.license == "MIT"' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null</automated>
  </verify>
  <acceptance_criteria>
    - `test -f plugins/zapili/.claude-plugin/plugin.json` exits 0.
    - `jq -e . plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null` exits 0.
    - `jq -e '.name == "zapili" and (has("version") | not)' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null` exits 0 (VALIDATION map task 01-01-03).
    - `jq -e 'has("category") | not' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null` exits 0 (RESEARCH Q2 drift fix).
    - `jq -e '(has("commands") | not) and (has("agents") | not) and (has("hooks") | not) and (has("mcpServers") | not)' plugins/zapili/.claude-plugin/plugin.json &gt;/dev/null` exits 0 (D-10 — no component keys).
    - MKT-08 minimal-leaf check: `find plugins/zapili -mindepth 1 -maxdepth 2 -type f | sort` returns exactly `plugins/zapili/.claude-plugin/plugin.json` (after Plan 02 lands `plugins/zapili/README.md`, also that file — verified together in Plan 02).
  </acceptance_criteria>
  <done>Per-plugin manifest exists at the spec-mandated path, identifies the plugin as `zapili`, and contains zero forbidden fields.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Repo → Claude Code loader | Static JSON files are read by Claude Code at `/plugin marketplace add` and `/plugin install` time; the loader is the only consumer. No network input, no user-supplied data parsed here. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-01-01 | Tampering | `.claude-plugin/marketplace.json` | mitigate | Pre-commit validator (Plan 04) parses JSON with `jq -e .` and asserts required fields before any commit lands; CRLF-induced malformation prevented by Plan 03's `.gitattributes`. |
| T-01-02 | Information Disclosure | author.email / owner.email in committed manifests | accept | Email `pavel.proger@gmail.com` is intentionally public per CONTEXT.md Specific Ideas — user explicitly opted in to the discoverable variant. |
| T-01-03 | Repudiation | Reserved-name collision (`oplya` / `zapili`) | accept | RESEARCH Pitfall 6 verified both names are clear on the live Anthropic reserved list as of 2026-05-27; re-verification deferred to Phase 6 per CONTEXT Deferred Ideas. |
| T-01-04 | Tampering | Unrecognized field injection (`owner.url`, `category` in plugin.json) | mitigate | Plan explicitly forbids these fields and verifies absence with `jq -e 'has("x") | not'`; aligns manifest with documented schema per RESEARCH Pitfall 1 + Q2. |
| T-01-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan (Phase 1 ships only static files + bash scripts); no `[ASSUMED]`/`[SUS]` packages to gate. RESEARCH § "Package Legitimacy Audit" confirms zero external packages. |
</threat_model>

<verification>
- Both manifests parse with `jq -e .` exit 0.
- Marketplace's `plugins[]` has exactly one entry with `name == "zapili"` and `source == "./plugins/zapili"`.
- Plugin manifest's `name == "zapili"` and `version`/`category`/`commands`/`agents`/`hooks`/`mcpServers` keys are all absent.
- `owner` in marketplace.json contains only `{name, email}` — no `url`.
- File line endings are LF (`file .claude-plugin/marketplace.json plugins/zapili/.claude-plugin/plugin.json | grep -v CRLF`).
</verification>

<success_criteria>
- Plan 04's validator (when delivered) exits 0 against these two manifests.
- `claude plugin validate ./plugins/zapili --strict` (supplementary check, run during Plan 05 rehearsal) reports zero warnings on these manifests.
- Plan 05's live install rehearsal recognizes `oplya` as a marketplace and resolves `zapili@oplya` for install.
</success_criteria>

<output>
Create `.planning/phases/01-marketplace-plugin-skeleton/01-01-SUMMARY.md` when done, recording the exact JSON shapes written and confirming `owner.url` (marketplace) + `category` (plugin) absence per RESEARCH drift fixes.
</output>
