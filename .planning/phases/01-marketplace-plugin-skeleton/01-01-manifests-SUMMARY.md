---
phase: 01-marketplace-plugin-skeleton
plan: 01
subsystem: infra
tags: [claude-code-plugins, marketplace, manifest, json, jq]

# Dependency graph
requires:
  - phase: 00-bootstrap
    provides: PROJECT.md vision (oplya/zapili identity, MIT license, English-only contracts, commit-SHA versioning), REQUIREMENTS.md MKT-01..08 + ZAP-03, ROADMAP.md Phase 1 boundary, RESEARCH.md drift fixes (drop owner.url, drop category from plugin.json), CONTEXT.md locked decisions D-02..D-10 + D-23/D-24
provides:
  - "Discoverable marketplace catalog at .claude-plugin/marketplace.json (name=oplya, owner={name,email}, metadata.pluginRoot=./plugins, one zapili entry)"
  - "Per-plugin manifest at plugins/zapili/.claude-plugin/plugin.json (name=zapili, zero component keys, no version, no category)"
  - "Resolution path: /plugin marketplace add SonicNorg/oplya → /plugin install zapili@oplya can now locate both manifests"
  - "Authoritative install target referenced by Plans 02 (READMEs), 04 (validator scans these exact paths), 05 (live install rehearsal)"
affects: ["01-02-documentation", "01-03-hygiene", "01-04-validator", "01-05-install-rehearsal", "02-session-hook-and-command", "03-schemas-and-contracts", "06-publication-polish"]

# Tech tracking
tech-stack:
  added:
    - "Claude Code marketplace.json schema v1 (Anthropic schema URL)"
    - "Claude Code plugin.json schema v1 (JSON Schema Store URL)"
  patterns:
    - "Strict RFC 8259 JSON manifests (no comments, no trailing commas, LF endings, no BOM)"
    - "Skeleton-minimalism: zero component keys in plugin.json → default-folder auto-discovery owns wiring in Phase 2+"
    - "Commit-SHA versioning: omit `version` field while iterating; add only at release commit (Phase 6)"
    - "Drift-aware authoring: drop owner.url from marketplace.json (mitigates --strict warning), drop category from plugin.json (category lives on marketplace plugins[] entry only)"

key-files:
  created:
    - ".claude-plugin/marketplace.json"
    - "plugins/zapili/.claude-plugin/plugin.json"
  modified: []

key-decisions:
  - "Pinned $schema to https://anthropic.com/claude-code/marketplace.schema.json (marketplace) and https://json.schemastore.org/claude-code-plugin-manifest.json (plugin) — editor-experience win, ignored by loader"
  - "owner contains only {name, email} per RESEARCH Pitfall 1 (documented schema); GitHub URL surfaces via plugin entry's repository field and plugin.json author.url instead"
  - "category lives ONLY in the marketplace plugins[] entry, NOT in plugin.json (RESEARCH Open Question Q2 — category is a marketplace-entry field)"
  - "Zero component keys (commands/agents/hooks/mcpServers) in plugin.json — Phase 1 ships no behavior; default-folder auto-discovery picks up Phase 2+ additions without manifest edits (D-10/D-23/D-24)"
  - "source uses the explicit ./plugins/zapili form (must start with ./, no ../) — clearer than the short form even with metadata.pluginRoot set (D-04)"

patterns-established:
  - "Manifest authoring: strict JSON, LF endings, no BOM, no trailing commas — verified with `file` + `jq -e`"
  - "Per-task acceptance verification: every plan task's `<acceptance_criteria>` block ran as a single bash chain before commit; commit happens only after ALL OK"
  - "Atomic per-task commits: one feat() per manifest file with rationale citing CONTEXT decisions + RESEARCH drift fixes"

requirements-completed: [MKT-01, MKT-02, MKT-03, ZAP-03]

# Metrics
duration: ~1 min
completed: 2026-05-28
---

# Phase 1 Plan 1: Manifests Summary

**Discoverable marketplace + plugin manifests at spec-mandated paths — `oplya` is registrable via `/plugin marketplace add SonicNorg/oplya` and `zapili` resolves via `metadata.pluginRoot`-anchored `./plugins/zapili` source, both with RESEARCH-driven drift fixes (no `owner.url`, no `category` on plugin.json) applied.**

## Performance

- **Duration:** ~1 min (69s wall-clock from start probe to plan-verify pass)
- **Started:** 2026-05-27T21:26:41Z
- **Completed:** 2026-05-27T21:27:50Z
- **Tasks:** 2 (both `type="auto"`, no checkpoints, no deviations)
- **Files modified:** 2 (both created)

## Accomplishments

- `.claude-plugin/marketplace.json` — the marketplace catalog at the exact spec-mandated location, listing `zapili` as the sole plugin via the explicit `./plugins/zapili` source (anchored by `metadata.pluginRoot: "./plugins"`).
- `plugins/zapili/.claude-plugin/plugin.json` — the per-plugin manifest with `name: "zapili"` plus polish metadata (displayName, description, author, homepage, repository, license, keywords) and zero component keys / zero forbidden fields.
- All four RESEARCH drift fixes applied: dropped `owner.url` from marketplace, dropped `category` from plugin.json, omitted `version` (commit-SHA versioning), kept `source` in the explicit `./plugins/zapili` form (never `../`, always starts with `./`).
- All plan `<acceptance_criteria>` and `<verification>` `jq -e` assertions pass — including the positive absence checks (`(.owner | has("url") | not)`, `(has("version") | not)`, `(has("category") | not)`, etc.).

## Task Commits

Each task was committed atomically:

1. **Task 1: Write .claude-plugin/marketplace.json** — `fd0d573` (feat)
2. **Task 2: Write plugins/zapili/.claude-plugin/plugin.json** — `c2d070b` (feat)

**Plan metadata:** pending (this commit, see "Final Commit" below)

## Files Created/Modified

- `.claude-plugin/marketplace.json` — Marketplace catalog (`name: "oplya"`); 1 plugin entry for `zapili` with source `./plugins/zapili`, category `workflow`, repository `https://github.com/SonicNorg/oplya`; pluginRoot `./plugins`; owner `{name: "Pavel", email: "pavel.proger@gmail.com"}` — no `url`.
- `plugins/zapili/.claude-plugin/plugin.json` — Plugin manifest (`name: "zapili"`); author with `url`; license MIT; 5 keywords; absent: `version`, `category`, `commands`, `agents`, `hooks`, `mcpServers`.

## Decisions Made

- **`$schema` pinning** — chose the Anthropic-canonical URL for the marketplace schema and JSON Schema Store URL for the plugin manifest, both confirmed live by RESEARCH on 2026-05-27. Editor-tooling win at zero load-time cost (Claude Code ignores `$schema`).
- **owner drift mitigation** — followed RESEARCH Pitfall 1 recommendation and CONTEXT decision (no `owner.url`); GitHub identity now lives only on the plugin entry's `repository` field and on `plugin.json`'s `author.url` (both officially supported per spec).
- **category placement** — followed RESEARCH Open Question Q2 and CONTEXT D-08 implementation: `category: "workflow"` appears exclusively in the marketplace `plugins[]` entry, not duplicated into `plugin.json` where it would become an unrecognized field triggering `--strict` warnings.
- **Skeleton minimalism** — strictly honored D-10/D-23/D-24: no component keys in `plugin.json`. Phase 2 will add the `commands/`, `hooks/`, etc. folders and default auto-discovery will pick them up without further manifest edits.

## Deviations from Plan

None — plan executed exactly as written. No bugs to fix, no missing critical functionality discovered, no blocking issues, no architectural surprises. All plan `<acceptance_criteria>` passed on first execution for both tasks.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required by this plan. Phase 1 ships static repo files only.

## Threat Surface Scan

Reviewed both new files against the plan's `<threat_model>` register:

- **T-01-01 (Tampering, marketplace.json)** — mitigated by RFC 8259 strict JSON + `jq -e` verification at commit time; line-endings forced LF (`file` reports `JSON text data`, not `with CRLF`); no BOM. Plan 03's `.gitattributes` will provide permanent enforcement; Plan 04's validator will gate future commits.
- **T-01-04 (Tampering, unrecognized fields)** — mitigated by explicit absence checks (`has("url") | not`, `has("category") | not`); both manifests are documented-schema-clean.
- **T-01-SC (Supply chain)** — N/A; no package-manager installs in this plan, only static file authoring.
- **T-01-02 (Information Disclosure)** — accepted: `pavel.proger@gmail.com` is intentionally public per CONTEXT.md Specific Ideas.
- **T-01-03 (Reserved-name collision)** — accepted: RESEARCH Pitfall 6 confirms both `oplya` and `zapili` are clear on the live Anthropic reserved-names list as of 2026-05-27.

No NEW threat surface introduced beyond the plan's existing register. No Threat Flags to raise.

## Next Phase Readiness

**Plan 01-02 (Documentation):** Both manifest files exist; READMEs can now confidently reference the install path `/plugin marketplace add SonicNorg/oplya` + `/plugin install zapili@oplya` and the repo layout (`.claude-plugin/marketplace.json`, `plugins/zapili/.claude-plugin/plugin.json`).

**Plan 01-03 (Hygiene):** `.gitattributes` should be added BEFORE any additional `.sh` files land (RESEARCH Pitfall 11) — the JSON files are not at CRLF risk now (verified LF), but future shell scripts in Plan 04 need the protection in place first.

**Plan 01-04 (Validator):** `scripts/validate-manifests.sh` will scan exactly these two manifest paths; the validator's required-field checks (`.name`, `.owner.name`, `.plugins` for marketplace; `.name` for plugin) will pass against these files on first run.

**Plan 01-05 (Install rehearsal):** Live `/plugin marketplace add` + `/plugin install zapili@oplya` against the eventual Phase-1 commit on `main` will resolve both manifests; nothing further is needed from this plan to unblock the rehearsal.

**Open concerns:** None for downstream plans. Note for Phase 6 release work: when cutting a real release, add `"version": "1.0.0"` to `plugins/zapili/.claude-plugin/plugin.json` (NOT to the marketplace entry) — per CONTEXT D-09 and RESEARCH "What NOT to Use" guidance.

## Self-Check: PASSED

- File `.claude-plugin/marketplace.json` exists — FOUND.
- File `plugins/zapili/.claude-plugin/plugin.json` exists — FOUND.
- Commit `fd0d573` (Task 1) — FOUND in `git log`.
- Commit `c2d070b` (Task 2) — FOUND in `git log`.
- Both plan-level `<verification>` assertions pass (`jq -e` chain).
- Both plan-level `<acceptance_criteria>` (per task) pass.

---
*Phase: 01-marketplace-plugin-skeleton*
*Completed: 2026-05-28*
