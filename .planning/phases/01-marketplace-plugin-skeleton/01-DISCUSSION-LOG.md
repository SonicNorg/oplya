# Phase 1: Marketplace + plugin skeleton - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 1-marketplace-plugin-skeleton
**Areas discussed:** License choice, Manifest metadata, Pre-commit wiring, Reserved-names check, Empty component dirs

---

## License Choice

| Option | Description | Selected |
|--------|-------------|----------|
| MIT (Recommended) | Short, permissive, ecosystem default for Claude Code plugins. No patent grant, lowest friction. | ✓ |
| Apache 2.0 | Permissive + explicit patent grant + NOTICE file convention. More formal. | |

**User's choice:** MIT (Recommended).
**Notes:** Aligns with anthropics/claude-plugins-official convention and project's "light process" principle.

---

## Manifest Metadata — Owner Identity

| Option | Description | Selected |
|--------|-------------|----------|
| Pavel + email + GitHub URL | `owner: { name: "Pavel", email: "pavel.proger@gmail.com", url: "https://github.com/SonicNorg" }`. Most discoverable; email visible in public repo. | ✓ |
| Pavel + GitHub URL only | Hide email from manifest. Lower spam surface. | |
| GitHub handle only | Minimal; GitHub handle as canonical identity. | |

**User's choice:** Pavel + email + GitHub URL.
**Notes:** User explicitly opted into the maximum-discoverability variant despite public-repo email exposure.

---

## Manifest Metadata — Repo Slug

| Option | Description | Selected |
|--------|-------------|----------|
| SonicNorg/oplya | Already used in CLAUDE.md tech-stack snippets. | ✓ |
| Other GitHub slug | Different owner / org / repo name. | |

**User's choice:** SonicNorg/oplya.

---

## Manifest Metadata — Marketplace `category`

| Option | Description | Selected |
|--------|-------------|----------|
| workflow (Recommended) | Matches the marketplace's actual theme. | ✓ |
| development | Broader; less specific. | |
| Omit category at marketplace level | Only set per-plugin. | |

**User's choice:** workflow (Recommended).

---

## Manifest Metadata — Plugin `category` + `keywords`

| Option | Description | Selected |
|--------|-------------|----------|
| `category=workflow`, `keywords=[workflow, multi-agent, codex, planning, parallel]` (Recommended) | Sharp keyword set matching README pitch. | ✓ |
| `category=development`, `keywords=[orchestration, review, codex, task-md]` | Generic dev tool framing. | |
| You decide | Pick wording when README is drafted. | |

**User's choice:** category=workflow, keywords=[workflow, multi-agent, codex, planning, parallel].

---

## Manifest Metadata — Marketplace `displayName` + `description`

| Option | Description | Selected |
|--------|-------------|----------|
| `displayName="oplya"`, `description="Personal plugin marketplace — multi-agent dev workflows"` (Recommended) | Lowercase name matches slug; description hooks on workflow angle. | ✓ |
| Longer `displayName="oplya — Claude Code Plugin Marketplace"` + formal description | More descriptive header-style framing. | |
| You decide | Compose once README is drafted. | |

**User's choice:** Recommended option.

---

## Manifest Metadata — Plugin `displayName` + `description`

| Option | Description | Selected |
|--------|-------------|----------|
| `displayName="zapili"`, `description="Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review"` (Recommended) | Matches MKT-03 README pitch. | ✓ |
| `displayName="zapili — Development Workflow"`, `description="Drop a TASK.md, run /zapili:zapili, get a shipped change."` | More user-facing pitch. | |
| You decide | Compose once README is drafted. | |

**User's choice:** Recommended option.

---

## Pre-commit Wiring — MKT-07 Realization

| Option | Description | Selected |
|--------|-------------|----------|
| Only script + README instruction | Validator exists; manual invocation. No git hooks. | |
| Script + optional pre-commit hook | Ship `install-hooks.sh` for opt-in `.git/hooks/pre-commit` setup. | ✓ |
| Drop MKT-07 entirely | Treat as over-engineering. | |

**User's choice:** Script + auto-setup of pre-commit hook + README instruction.
**Notes:** User initially questioned the framing (pre-commit hook felt orthogonal to the `/zapili` workflow). After explanation that MKT-07 is about protecting `marketplace.json` / `plugin.json` from accidental broken commits (which would break downstream `/plugin install`), user chose the option that provides both manual fallback and one-command auto-install.

---

## Pre-commit Wiring — Validator Depth

| Option | Description | Selected |
|--------|-------------|----------|
| JSON parse + required fields (Recommended) | `jq -e .` + check `name`/`owner`/`plugins[]` etc. | ✓ |
| Pure JSON parse only | `jq -e .` and nothing more. | |
| Full JSON Schema via `ajv-cli` | Strongest, but adds npm dependency. | |

**User's choice:** JSON parse + required fields (Recommended).
**Notes:** Required-fields catches the realistic class of errors (`owner.name` missing breaks marketplace install). Pure-JSON-parse would silently pass those.

---

## Reserved-names Check Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Manual check at Phase 1 start (Recommended) | One-shot verify before scaffolding manifests. | |
| Automated check in validator | Validator queries reserved-names list. Network/staleness concern. | |
| Not a Phase 1 blocker; defer to Phase 6 polish | Trust research finding (clear on 2026-05-27); re-verify at release. | ✓ |

**User's choice:** Defer to Phase 6.

---

## Empty Component Dirs

| Option | Description | Selected |
|--------|-------------|----------|
| Don't create empty dirs (Recommended) | Phase 1 ships only `.claude-plugin/plugin.json` + `README.md` inside `plugins/zapili/`. | ✓ |
| Create all with `.gitkeep` | `commands/`, `agents/`, `hooks/`, `scripts/`, `schemas/`, `skills/`, `tests/fixtures/` upfront. | |
| Only `scripts/` upfront | Add `scripts/` now; rest later. | |

**User's choice:** Don't create empty dirs (Recommended).
**Notes:** Follows the "no design for hypothetical future requirements" principle from CLAUDE.md. Component dirs appear in the phase that populates them.

---

## Validator + Hook Scripts Location

| Option | Description | Selected |
|--------|-------------|----------|
| `scripts/` at marketplace top-level (Recommended) | Marketplace-level infrastructure; validates ALL plugins. Preserves MKT-08. | ✓ |
| Inside `plugins/zapili/scripts/` | Inside the plugin. Logically not a plugin function. | |

**User's choice:** Top-level `scripts/`.

---

## Claude's Discretion

- Exact `$schema` URL pinning (planner picks the current stable URL at planning time).
- Exact `.gitignore` pattern wording (categories from D-21 are mandatory; specific patterns flexible).
- Whether `.gitattributes` adds `*.json text eol=lf` / `*.md text eol=lf` beyond the mandated `*.sh` / `*.bash`.
- Exact README section wording (high-level scope from D-25 / D-26 is mandatory).
- Exact validator error-message wording (must satisfy D-13: one line per problem, surfaces all failures).

## Deferred Ideas

- **Reserved-name verification** — deferred to Phase 6 (publication polish).
- **CHANGELOG + semver bump policy** — Phase 6 polish.
- **GitHub Actions CI** — explicitly v2 (TOOL-01).
- **`ajv-cli` / full JSON Schema validation** — rejected, conflicts with "no language runtime" constraint.
- **Web listing page / shields / badges** — v2 (UX-01 / UX-02).
- **Empty component-directory stubs** — rejected (D-23 lock).
- **Auto-installing pre-commit hook on first validator run** — rejected as magical.
