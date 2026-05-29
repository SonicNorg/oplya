# oplya — Claude Code Plugin Marketplace

## Current State

- **Shipped:** `oplya` v1.1.0 (plugin tag `v1.1`, 2026-05-29).
- **Plugin version:** `plugins/zapili/.claude-plugin/plugin.json` = `1.1.0`.
- **Phases shipped:** 8 (v1.0 = 1–6 marketplace + plugin foundation; v1.1 = 7–8 review-follow-ups + codex self-fix fallback).
- **Requirements complete:** 49/49 (43 v1 + 6 v1.1).
- **Milestone archives:** [`milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md), [`milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md).
- **Maintainer-owned release activities** (inherited from v1.0): live install rehearsal post-push, live smoke-test round-trip, live chaos rehearsal — pending.

## Next Milestone Goals

No v1.2 scope locked yet. Candidate areas surfaced by v1.0/v1.1 review backlog (not blocking, not yet planned):

- **Polish carry-over** (v1.2.0 candidate): NIT-2 stale `f2/PLAN.md` comment; P2-6 `state.schema.json` `current_phase` pattern relaxation; P2-7 audit Gaps section consistency; misc cosmetic items from the three v1.0/v1.1 review rounds.
- **Release engineering** (separate milestone candidate): CI gate that enforces `plugin.json` version bump on every change to `plugins/zapili/*`; auto-bump command in `gsd-sdk`; reserved-name re-check automation; signed releases.
- **TOOL-** hardening: path-safety + manifest semantics checks in `validate-manifests.sh` (bad-invalid-source.json fixture already exists but is INFORMATIONAL today).
- **Additional plugins**: marketplace currently ships exactly one plugin (`zapili`). Adding a second plugin would exercise the multi-plugin layout for the first time and validate the marketplace's `metadata.pluginRoot` mechanism end-to-end.

Run `/gsd-new-milestone` to start v1.2 scoping.

## What This Is

A public Git-based marketplace (`oplya`) hosting personal Claude Code plugins for sharing with the team. The first plugin, `zapili`, packages a rigorous, multi-agent **development workflow** (research → validation → planning → validation → wave-based parallel implementation → review) driven entirely from a `TASK.md` in the working directory.

## Core Value

**A single command turns a `TASK.md` into a shipped change through a formalized, validation-looped, parallel multi-agent pipeline — with zero ambiguity in inter-agent contracts.**

Everything else (marketplace polish, additional plugins, docs) can fail. The `zapili` workflow producing a high-quality implementation from a well-described task must work.

## Requirements

### Validated

(None yet — ship to validate)

### Active

**Marketplace (oplya):**
- [ ] **MKT-01**: Repository structure follows Claude Code marketplace spec — `.claude-plugin/marketplace.json` at repo root listing all plugins
- [ ] **MKT-02**: Curated `.gitignore` (Node/Python/IDE/OS noise + plugin-local state dirs)
- [ ] **MKT-03**: Directory layout supports multiple themed plugins as siblings under `plugins/<plugin-name>/`
- [ ] **MKT-04**: Top-level `README.md` (English) describes the marketplace, install instructions (`/plugin marketplace add`), and lists plugins
- [ ] **MKT-05**: Each plugin self-contained with its own `.claude-plugin/plugin.json` and `README.md`
- [ ] **MKT-06**: Light publication process — manual semver bumps, no required tests/CI gates, but JSON files validated locally before commit

**zapili plugin (development workflow):**
- [ ] **ZAP-01**: Single entry-point slash command (e.g., `/zapili`) that drives the entire workflow from `TASK.md` in the current working directory
- [ ] **ZAP-02**: Plugin start-up hook verifies `codex` CLI is available; fails fast with a clear instruction if missing
- [ ] **ZAP-03**: **Research phase** — researcher subagent reads `TASK.md` + referenced code/files, classifies task size (small / medium / large / gigantic), and produces a sized question list with relevant context per question
- [ ] **ZAP-04**: Main session asks the researcher's questions to the user and writes consolidated answers + researcher findings + relevant code references into `CONTEXT.md`
- [ ] **ZAP-05**: **Research validation phase** — invokes `codex` to audit `TASK.md` + `CONTEXT.md` for contradictions, gaps, missing context; returns HIGH/MEDIUM/LOW issues with remediation hints. Loops (additional research + user questions) until no HIGH/MEDIUM issues remain
- [ ] **ZAP-06**: **Planning phase** — planner subagent reads `TASK.md` + `CONTEXT.md` and produces `PLAN.md` (overall plan with wave structure and phase references) plus zero or more `PHASE-XX.md` files (one per phase). No duplicated content between documents. Plan organizes phases into **waves** — strictly sequential groups in which intra-wave phases can run in parallel iff their file scopes do not overlap
- [ ] **ZAP-07**: **Plan validation phase** — invokes `codex` for an ultra-principal review of `PLAN.md` + all `PHASE-XX.md` files + referenced sources, checking contradictions, gaps, ambiguity, parallelization safety, completeness, architectural fit, OOP/DRY/KISS, professionalism. Returns HIGH/MEDIUM/LOW with fixes. Loops until no HIGH/MEDIUM issues remain
- [ ] **ZAP-08**: **Implementation phase (per wave)** — spawns one ultra-principal-engineer subagent per phase in the wave, in parallel; each receives `TASK.md`, scoped context, its `PHASE-XX.md`, and the formalized contract. Each returns a formalized, compact list of touched files with key changes
- [ ] **ZAP-09**: **Per-wave review** — implementation results from each phase agent are sent to `codex` in parallel for review (one review per phase). Codex receives `TASK.md`, the phase plan, and the agent's change list, returning HIGH/MEDIUM/LOW issues
- [ ] **ZAP-10**: **Per-wave fix loop** — review findings are routed back to the implementation agents (same agent where possible, to preserve in-context memory). Loop continues until no HIGH/MEDIUM issues remain across all phases in the wave
- [ ] **ZAP-11**: Waves execute strictly sequentially; each wave fully closes (review + fixes) before the next starts
- [ ] **ZAP-12**: **Final notification** — on workflow completion, user receives a summary of all modified files and the key decisions (with justifications) made by implementation agents
- [ ] **ZAP-13**: **State persistence** — workflow progress survives session/restart via on-disk artifacts (`TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`) plus a `.zapili/state.json` capturing current phase, wave, and validation-loop iteration; resume is automatic from artifact inspection
- [ ] **ZAP-14**: **Formalized inter-agent contracts** — every prompt and every expected response is English, structured with Anthropic-style XML tags, with embedded JSON blocks for machine-parseable lists (issues, file changes, question batches, size classification). Strict, unambiguous, professional tone
- [ ] **ZAP-15**: Task-size policy embedded in prompts — small (≤100 LOC, 1–3 modules, 3–4 questions, plan only); medium (≤500 LOC, 1–5 modules, 5–8 questions, plan + 3–4 phases); large (≤1000 LOC, 2–8 modules, 9–12 questions, plan + 5–8 phases); gigantic (>1000 LOC, 13–20 questions, plan + 9–20 phases)
- [ ] **ZAP-16**: **Codex review prompts are exhaustive by design** — every codex invocation (research validation, plan validation, per-phase implementation review) explicitly instructs codex to report **all** findings at every severity (HIGH/MEDIUM/LOW), not just the top few. Prompts forbid summarization, "the most important", or pareto-style filtering. Goal: drive iteration count down by surfacing the full issue set in one pass instead of discovering new HIGH/MEDIUM problems after the previous batch is fixed

### Out of Scope

- **Debugging / testing / hotfix workflows** — `zapili` is explicitly for **new development** work; debug/test/exploration belong to future plugins
- **Private/self-hosted marketplace** — public GitHub only for v1; corporate Git hosts can be added later
- **Sharing existing personal plugins** — none ready yet; starting from scratch
- **Strict CI/automated validation** — out of v1 (light process). Optional semver/JSON-lint may live in a later phase
- **Built-in fallback to a non-codex LLM** for validation — codex is mandatory; alternative validators are a v2 concern
- **GUI / web UI for the marketplace** — Git + Claude Code `/plugin` commands are the entire interface

## Context

- **Author:** Pavel (pavel.proger@gmail.com); solo maintainer publishing to a small team
- **Audience:** Team members install via `/plugin marketplace add <oplya-repo>` then `/plugin install <name>@oplya`; repo is public so external developers can use plugins too
- **Runtime targets:** Claude Code (primary). Plugin file structure follows the official Claude Code plugin spec: `.claude-plugin/plugin.json`, plus `commands/`, `agents/`, `skills/`, `hooks/`, `mcp/` subdirectories as needed
- **Inter-agent communication style:** Anthropic-recommended XML tags for prompt structure; JSON blocks (wrapped inside dedicated XML tags) for any list/status/metric payload that the orchestrator must parse. All prompt/response content in English regardless of human conversation language
- **External tools used by `zapili`:**
  - `codex` (OpenAI Codex CLI) — used as an independent reviewer for both research validation and plan validation; presence verified by start-up hook
  - Claude subagents — used for researcher, planner, and ultra-principal-engineer roles
- **Authoring language for code/comments/contracts:** English (project audience is multinational; the team's working language for tooling will be English)

## Constraints

- **Tech stack**: Markdown + JSON config (marketplace + plugin manifests); Bash for hooks; the Claude Code plugin format is the only deployment target — no separate runtime, no package registry
- **Dependencies**: `codex` CLI must be installed on the user's machine for `zapili` to run; the start-up hook is the only enforcement point
- **Compatibility**: Plugin layout must satisfy `/plugin marketplace add` and `/plugin install` flows on current Claude Code
- **Process**: Light — manual versioning, no required CI, but `marketplace.json` and `plugin.json` MUST pass a local validation before any commit that touches them
- **Documentation**: English-only for `README.md`, plugin docs, and inter-agent prompts. User-facing conversation may be in any language
- **Scope discipline**: v1 ships exactly one plugin (`zapili`). Adding plugins is a future-milestone concern; do not prematurely abstract for "many plugins" beyond directory layout

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Marketplace name `oplya`, first plugin `zapili` | User-chosen; project identity | — Pending |
| Public GitHub repo (vs. private/self-hosted) | Team primary audience, but no reason to gate; lets external contributors benefit | — Pending |
| Themed plugins (not many-small, not monolith) | Each plugin = one coherent workflow; easy to install only what you need without explosion of micro-plugins | — Pending |
| Start from scratch (no migration of existing plugins) | No mature personal plugins exist yet; `zapili` is the seed plugin | — Pending |
| `codex` CLI mandatory; verify via plugin start-up hook (no Claude fallback) | The whole point of the validation phases is **independent** review by a different model family. Falling back to Claude defeats the design | — Pending |
| All prompts and agent responses in English with XML+JSON contracts | Anthropic prompt-engineering guidance recommends XML; JSON inside dedicated tags gives machine-parseable payloads. Russian-language responses lose precision and bloat tokens | — Pending |
| State persisted as on-disk artifacts (`TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`, `.zapili/state.json`) | Survives session loss; resumes deterministically; inspectable by humans without any tooling | — Pending |
| Strictly sequential waves with parallel intra-wave phases | Maximum parallelism without write conflicts; matches the user's "wave" model exactly | — Pending |
| Light publication process for v1 (no CI gates) | Solo maintainer + small team; ceremony slows iteration. JSON manifests still locally validated to prevent broken installs | — Pending |
| Task-size thresholds (LOC / modules / question count / phase count) defined explicitly in prompts | Removes researcher/planner ambiguity; gives the workflow predictable shape across task sizes | — Pending |
| Codex review prompts must produce **exhaustive** findings (full HIGH/MEDIUM/LOW set), no top-N filtering | Each missed issue forces another full review iteration. Asking codex for the complete set up front minimizes the loop count — fewer wasted runs, faster convergence | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-27 after initialization*
