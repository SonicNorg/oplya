# Project Research Summary

**Project:** oplya — Claude Code Plugin Marketplace (with `zapili` as the seed plugin)
**Domain:** Claude Code plugin packaging + multi-agent, codex-validated development workflow
**Researched:** 2026-05-27
**Confidence:** HIGH (plugin / marketplace / hook / codex CLI mechanics verified against official Anthropic & OpenAI docs); MEDIUM (subagent identity continuity and exact parallel-Agent dispatch syntax rely on current Claude Code behaviour, not a formal spec)

## Executive Summary

`oplya` is not a runtime — it is a **convention stack**: a public Git repo whose root carries `.claude-plugin/marketplace.json`, with each plugin living as a sibling under `plugins/<name>/`. There is no build, no package registry, no CI. The "engineering" lives in three places only: (a) the shape of the manifests, (b) the on-disk artifacts that survive session loss, and (c) the prompts/schemas that define inter-agent contracts. The first plugin, `zapili`, ships a multi-agent development workflow (research → research-validate → plan → plan-validate → wave-based parallel implementation → per-phase review → fix loop → final summary) driven entirely from a user-authored `TASK.md`. Independent review is provided by the `codex` CLI invoked as a Bash subprocess — never as a Claude subagent or MCP tool — so that the cross-model-review property the workflow relies on is preserved.

The four research streams **converged on a single, coherent architecture**. There were no contradictions across STACK / FEATURES / ARCHITECTURE / PITFALLS. The load-bearing facts they jointly nail down: (1) the `zapili` orchestrator must run as a **skill loaded into the main thread by a slash command**, not as a subagent, because Claude Code subagents cannot spawn other subagents; (2) every inter-agent message is an **XML envelope with a JSON payload** validated against a JSON Schema in `schemas/`, with codex's `--output-schema` enforcing the same shape server-side; (3) wave-parallel safety is unsafe by default and must be **mechanically verified by the orchestrator** against per-phase write-scope declarations, not trusted to LLM judgement; (4) `.zapili/state.json` is **single-writer (orchestrator only)** and is a *cache* — on-disk artifacts (`TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`) are the source of truth on resume; (5) "same agent fixes the review" is a category error — subagents are stateless roles, continuity is achieved by **re-feeding the prior reasoning trace as an artifact** to a freshly spawned engineer.

The dominant risks are not technical packaging risks (those are well-documented and cheap to prevent) but **workflow-correctness risks**: silent file overlap between parallel phases, non-terminating validation loops driven by codex re-classifying severity across runs, top-N filtering despite "exhaustive" instructions, and contract drift where a subagent invents JSON fields the orchestrator doesn't parse. Each of these has a concrete mitigation that must be built in from day one — they are not v2 polish.

## Key Findings

### Recommended Stack

The whole stack is **manifest + Markdown + Bash + `jq` + `codex exec`**. No language runtime, no build pipeline. The only "version" decisions are (a) which Claude Code spec fields to use (all currently stable; `displayName` requires v2.1.143+) and (b) how to invoke `codex` (`exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config`, prompt fed via stdin, output parsed from JSONL). The orchestrator is a skill in `skills/orchestrator/`; the three worker subagents (researcher, planner, engineer) live in `agents/` and have explicit `tools` allowlists (researcher = read-only). JSON Schemas in `schemas/` are the load-bearing API artifact — every agent prompt and every codex invocation references one.

**Core technologies:**
- **Claude Code plugin spec (current)** — the only deployment target; `.claude-plugin/marketplace.json` at repo root, `.claude-plugin/plugin.json` per plugin
- **Markdown + YAML frontmatter** — all components (commands, skills, agents) are frontmatter-driven; non-negotiable
- **JSON (RFC 8259, strict)** — manifests, `hooks.json`, JSON Schemas, `.zapili/state.json`; no comments, no trailing commas
- **Bash + `jq` (≥1.6)** — `SessionStart` hook for codex pre-flight; `scripts/codex-*.sh` wrappers that separate stdout (final answer) from stderr (progress)
- **OpenAI `codex exec --json`** — the independent reviewer; invoked non-interactively, sandboxed read-only, prompt on stdin, JSONL parsed for the final assistant message; `--output-schema` enforces JSON shape
- **Anthropic XML-tag prompt convention** — every contract is `<request>...</request>` / `<response><payload>{...}</payload></response>`; English everywhere

See `.planning/research/STACK.md` for the full manifest examples, hook templates, and codex wrapper script.

### Expected Features

`zapili` matches the canonical multi-agent workflow pattern (GSD, ralph-loop, claude-code-workflow-orchestration, claude-review-loop) but differentiates on (a) two-tier validation (research **and** plan), (b) exhaustive HIGH/MEDIUM/LOW codex findings with no top-N filtering, (c) formal XML+JSON contracts with JSON Schema validation, (d) explicit task-size thresholds embedded in prompts, (e) automatic resume from artifact inspection, and (f) mandatory codex (no Claude fallback) for independent review.

**Must have (table stakes):**
- Valid `marketplace.json` + per-plugin `plugin.json` (without these, install fails)
- Top-level + per-plugin README with install instructions
- Single slash-command entry point (`/zapili:zapili`)
- File-based task input (`TASK.md`) and context capture (`CONTEXT.md`)
- Planning artifact split: `PLAN.md` + `PHASE-XX.md` (no duplication)
- Wave-based parallel execution with sequential wave ordering
- External reviewer LLM integration via `codex` CLI
- Validation loop until HIGH/MEDIUM = 0 (capped, not unbounded)
- Severity-graded findings (HIGH/MEDIUM/LOW), exhaustive (no summarization)
- File-based state that survives session restart (`.zapili/state.json` + artifacts)
- `SessionStart` hook for codex pre-flight (advisory only — must NOT brick Claude Code)
- Final summary on completion (files + key decisions)
- English-only prompts/contracts; MIT/Apache LICENSE; curated `.gitignore`; local JSON validation pre-commit

**Should have (competitive differentiators):**
- Exhaustive-review prompt design (drives loop count toward 1)
- Formal XML+JSON inter-agent contracts with JSON Schemas
- Embedded task-size policy with hard numeric caps
- Researcher subagent with size-bounded user Q&A
- Two-tier validation (research + plan, not just plan)
- Per-phase codex review with fresh-agent-plus-prior-attempt fix routing
- Automatic resume (no separate command)
- Mandatory codex (documented as a feature)
- `displayName`, `category`, `tags`, `$schema` on manifests

**Defer (v2+):**
- CI validation, alternative reviewer LLM, debug/test/hotfix sibling plugins
- Skill bundles for specific languages, telemetry, web listing page, Windows shim

See `.planning/research/FEATURES.md` for the full P1/P2/P3 matrix and competitor feature table.

### Architecture Approach

The architecture is **orchestrator-in-main-thread, workers-as-stateless-subagents, codex-as-Bash-subprocess**. The `/zapili:zapili` slash command loads a skill into the main session; that skill owns the control flow, the AskUserQuestion calls, the `.zapili/state.json` writes, and the codex invocations. Researcher / planner / engineer subagents are stateless one-shot workers that consume an XML+JSON envelope and return an XML+JSON payload. Within a wave, the orchestrator fans out N `Agent(engineer)` calls in a single assistant turn (Claude Code dispatches them in parallel) and then fans out N `Bash(codex-review-phase.sh)` calls in parallel for the review pass. Between waves the workflow is strictly sequential — the next wave never starts until the prior wave's fix loop has converged.

**Major components:**
1. **Marketplace root (`oplya/`)** — `.claude-plugin/marketplace.json` catalogs plugins; `plugins/<name>/` siblings
2. **`zapili` plugin skeleton** — `.claude-plugin/plugin.json`, `hooks/hooks.json`, `commands/zapili.md`
3. **`SessionStart` hook + `scripts/check-codex.sh`** — advisory codex presence + auth check; must NOT block session startup
4. **Orchestrator skill (`skills/orchestrator/SKILL.md`)** — runs in the main thread; owns control flow, state writes, codex invocations, AskUserQuestion, contract parsing
5. **Researcher subagent (`agents/researcher.md`, read-only tools)** — size-classifies TASK.md; produces bounded question batch
6. **Planner subagent (`agents/planner.md`)** — writes `PLAN.md` + per-phase `PHASE-XX.md` with explicit `<files>{writes, reads}</files>` blocks; bounded phase count by size class
7. **Engineer subagent (`agents/engineer.md`)** — one spawn per phase per wave; reads only its own `PHASE-XX.md` + scoped CONTEXT excerpt; returns compact `<payload>{files_touched, decisions, change_summary}`
8. **`scripts/codex-*.sh` wrappers** — `codex exec --json --output-schema <schema>` with separated stdout/stderr; one wrapper per validation step (research, plan, per-phase review)
9. **`schemas/`** — JSON Schemas for `validation-findings`, `research-questions`, `phase-changes`, `state` (the API contract for the whole system)
10. **On-disk artifacts in the user's project CWD** — `TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`, `.zapili/state.json`, optional `.zapili/agents/<phase>.json` per-attempt traces

See `.planning/research/ARCHITECTURE.md` for the system diagram, anti-patterns, and the canonical build-order dependency graph.

### Critical Pitfalls

The pitfalls research is uncharacteristically actionable — most have a one-line mechanical mitigation that must be built in from day one rather than retrofitted.

1. **Wave-parallel file overlap is unsafe by default** — two phases declared "parallel-safe" may both write the same file; last-write-wins silently corrupts. **Mitigation:** every `PHASE-XX.md` includes a JSON `<files>{writes, reads}</files>` block; orchestrator computes write-set intersection across a wave's phases *before* spawning any subagent and aborts on any overlap. Codex plan-validation also enumerates wave write-scopes and confirms pairwise disjointness.
2. **Validation loops can run forever** — codex re-classifies LOW as HIGH across runs because severity is fuzzy. **Mitigation:** (a) hard iteration cap (≤3); (b) pass prior issue list into next codex call with explicit "resolved must not reappear; reclassifications must be justified"; (c) stable issue IDs (hash of `{file, line-range, kind}`) so the same issue is detectable across iterations.
3. **"Exhaustive findings" defaults to top-N** — LLMs pareto-filter despite the instruction. **Mitigation:** prompt structure forces enumeration of categories first, then findings per category (including "no findings"); require a trailing `<coverage>{files_reviewed, categories_checked}</coverage>` block; forbid vocabulary like "key", "main", "top", "important"; calibrate on a reference corpus of deliberately-flawed samples before shipping.
4. **"Same agent fixes its review" is a category error** — Claude Code subagents are fresh contexts per spawn; there is no persistent agent process. **Mitigation:** persist the engineer's reasoning trace (decisions, key choices, files touched) as a sibling artifact (`PHASE-XX-attempt-N.md`); the fix-iteration spawn receives the original phase plan + prior attempt artifact + review findings. Continuity is by artifact, not by process identity. Document this explicitly in the contract spec.
5. **`SessionStart` hook hard-failing on missing codex bricks Claude Code** — exit code 2 at SessionStart aborts the session; user can't even `/plugin uninstall`. **Mitigation:** SessionStart exits 0 with a warning; the **slash command itself** does the strict pre-flight check, so an absent codex only refuses the `/zapili` invocation. Also: detect headless / no-TTY context and require `OPENAI_API_KEY` rather than ChatGPT OAuth.
6. **`state.json` and on-disk artifacts can disagree after a crash** — `state.json` is the obvious "what stage am I at?" answer but lies after a partial write. **Mitigation:** artifacts are the source of truth; orchestrator derives stage from artifact presence on resume and rewrites `state.json` if they disagree. Single-writer rule for `state.json` (orchestrator only). All artifact writes via temp-then-rename. Completion sentinels (`<status>complete</status>`) inside artifacts so half-written files are detectable.

See `.planning/research/PITFALLS.md` for all 20 critical/serious pitfalls, the technical-debt patterns table, the "Looks Done But Isn't" checklist, and the per-pitfall recovery strategies.

## Implications for Roadmap

All four reports converge on a **15-step build order** that decomposes cleanly into 6 implementation phases. The ordering principle is non-negotiable: contracts (schemas) before agents; one-phase plumbing before parallelism; resume hardening before publication polish. This matches the dependency graph in `ARCHITECTURE.md` § "Build Order" exactly.

### Phase 1: Marketplace + plugin skeleton (installable end-to-end)

**Rationale:** Nothing downstream is testable until `/plugin marketplace add` works and the plugin loads. This is the cheapest, highest-leverage de-risking step — and the only one that needs to be done by hand exactly once.
**Delivers:** `oplya/.claude-plugin/marketplace.json`, `plugins/zapili/.claude-plugin/plugin.json`, top-level + per-plugin `README.md`, `LICENSE`, `.gitignore` (covering `.zapili/`), `.gitattributes` (`*.sh text eol=lf`), JSON-schema local validation script, semver-bump pre-commit warning, `displayName` / `category` / `tags` / `$schema` polish.
**Addresses:** MKT-01..06; all P1 marketplace items from FEATURES.md.
**Avoids:** Pitfalls 1 (marketplace.json location), 2 (malformed manifest fields), 19 (global config writes), 20 (forgotten semver bumps).

### Phase 2: Plugin packaging — SessionStart hook + slash command shell

**Rationale:** Once the plugin loads, the very next concern is "does our pre-flight even run, on every OS, without bricking Claude Code?" — this is where most plugins die in the field. Wire the hook in early so every subsequent dev iteration verifies its own environment.
**Delivers:** `hooks/hooks.json`, `scripts/check-codex.sh` (advisory exit-0 mode), `commands/zapili.md` (delegating to the orchestrator skill, plus a strict pre-flight that gates the command — separate from the session hook), `.gitattributes` enforcement of LF line endings and `chmod +x` verification.
**Uses:** Bash + `jq`; `${CLAUDE_PLUGIN_ROOT}` substitution.
**Implements:** Component (3) — SessionStart hook — and the command shell of component (4).
**Avoids:** Pitfalls 3 (non-executable / CRLF hooks), 4 (relative paths in hooks), 5 (SessionStart hard-fail), 15 (codex headless auth failure), 19 (global config writes).

### Phase 3: Inter-agent contracts — JSON Schemas + contract reference doc

**Rationale:** Schemas are the API. Authoring them before any agent prevents three different prompts from drifting into three different shapes. This phase is a *single source of truth* phase — pure design, no agent runtime yet.
**Delivers:** `schemas/validation-findings.schema.json`, `schemas/research-questions.schema.json`, `schemas/phase-changes.schema.json`, `schemas/state.schema.json`, `skills/orchestrator/references/contracts.md` (XML envelope spec, stable-issue-ID rules, payload-size budgets), `skills/orchestrator/references/task-sizing.md` (ZAP-15 thresholds), `skills/orchestrator/references/codex-prompts.md` (ZAP-16 exhaustive-review prompt scaffold + forbidden vocabulary + category enumeration + `<coverage>` block + `<reclassification>` block).
**Implements:** Component (9) — `schemas/` — and the contract foundation that everything downstream consumes.
**Avoids:** Pitfalls 7 (loop non-termination — anchoring rules embedded), 8 (top-N findings — prompt scaffolding embedded), 9 (contract drift — schema enforcement), 12 (same-agent myth — explicit role-vs-process spec), 17 (codex output-shape drift), 18 (subagent context bloat — payload-size budget spec).

### Phase 4: Orchestrator skill + research + research-validate + plan + plan-validate

**Rationale:** End-to-end one-shot pipeline before introducing parallelism. Build the linear backbone: state.json bootstrap → researcher → user Q&A → CONTEXT.md → codex research-validate (with iteration cap + prior-issue anchoring) → planner → PLAN.md + PHASE-XX.md (with mandatory `<files>` blocks) → codex plan-validate. No engineers, no waves, no fan-out yet.
**Delivers:** `skills/orchestrator/SKILL.md` (research + research-validate + plan + plan-validate steps), `agents/researcher.md` (read-only tools, size-bounded question cap enforced by orchestrator on parse), `agents/planner.md` (mandatory `<files>` blocks, phase-count cap per size), `scripts/codex-validate-research.sh`, `scripts/codex-validate-plan.sh` (separated stdout/stderr, `--output-schema`, exit-code propagation, atomic state.json writes), `.zapili/state.json` bootstrap + resume-from-artifacts logic with completion sentinels.
**Implements:** Components (4), (5), (6), (8 — partial), (10 — partial).
**Avoids:** Pitfalls 7, 8 (validation loop hygiene), 10 (state-file race — single-writer), 11 (resume semantics — artifacts as truth), 13 (researcher question overflow), 14 (planner over-fragmentation), 16 (codex stdout/stderr mixing), 18 (subagent context bloat).

### Phase 5: Engineer subagent + single-phase implementation + per-phase review + fix loop (no parallelism yet)

**Rationale:** Parallelism is orthogonal to "does the engineer round-trip cleanly?" Get one phase end-to-end first: engineer reads its `PHASE-XX.md` + scoped context → edits source → returns compact payload → codex review → fresh-engineer-plus-prior-attempt fix iteration → converge. This is where the "agents are roles, continuity is artifact" pattern is implemented and stress-tested.
**Delivers:** `agents/engineer.md`, `scripts/codex-review-phase.sh`, per-attempt artifact persistence (`PHASE-XX-attempt-N.md` capturing the engineer's reasoning trace), fix-loop iteration cap + prior-issue anchoring, single-phase implementation path.
**Implements:** Components (7), (8 — completed), the per-phase fix loop of the orchestrator.
**Avoids:** Pitfalls 9 (contract drift on engineer payload), 12 (same-agent myth — artifact-based continuity), 18 (subagent context bloat — per-phase scoped context only), 17 (codex output-shape drift on review responses).

### Phase 6: Wave executor + final summary + resume hardening + publication polish

**Rationale:** Lift the single-phase path into wave-parallel execution; add the cross-cutting safety (mechanical write-scope disjointness check); add the final summary; harden resume by chaos-testing (kill -9 at every state boundary); then ship.
**Delivers:** Wave-parallel fan-out (single assistant turn issuing N `Agent(engineer)` calls), parallel codex review fan-out, per-wave fix convergence, **orchestrator-side mechanical write-scope intersection check before spawning any wave**, final summary aggregator (ZAP-12: files + decisions + rationale), resume-from-crash hardening (kill -9 tests at every state boundary), publication-polish (README install commands verified against a fresh clone, smoke-test instructions, CHANGELOG, semver bump discipline documented).
**Implements:** Wave-loop portion of the orchestrator; component (10 — completed); cross-cutting safety check.
**Avoids:** Pitfall 6 (wave file-scope overlap — the *single most catastrophic* failure mode; enforced mechanically here), Pitfall 11 (resume semantics under chaos), Pitfalls 1–5 + 19–20 verified end-to-end against the "Looks Done But Isn't" checklist.

### Phase Ordering Rationale

- **Schemas precede agents** (Phase 3 before Phases 4–5) because every agent prompt and every codex invocation references a schema. Authoring agents first would force schema-after-the-fact rewrites of every prompt.
- **Single-phase pipeline precedes parallelism** (Phase 5 before Phase 6) because file-scope overlap, payload bloat, and contract drift all manifest at the per-phase level; debugging them inside a wave fan-out is far harder.
- **Hook + slash-command shell precedes orchestrator logic** (Phase 2 before Phase 4) so the dev loop has fail-fast environment verification from day one — every subsequent `/zapili` invocation during development confirms its own preconditions.
- **Marketplace polish is split**: the minimum installable skeleton is Phase 1 (you cannot test anything without `/plugin install` working), while the README-polish / smoke-test / CHANGELOG hardening is Phase 6 (only meaningful once the workflow actually works).
- **Resume hardening is a Phase 6 verification, not a Phase 4 build**, because resume tests the union of all prior phases' state writes; bugs found by chaos-testing in Phase 6 must be fixed in whichever phase originally wrote the bad state — making resume "its own phase" would hide root causes.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 3 — Inter-agent contracts:** the JSON Schema design needs deliberate iteration. Plan-phase research should look at concrete `--output-schema` examples in codex documentation and at how other workflow plugins shape their per-phase change-list payloads. The exhaustive-review prompt also needs **calibration on a reference corpus** of deliberately-flawed plans/diffs before launch (Pitfall 8); plan a short calibration sub-step.
- **Phase 6 — Wave executor:** the exact mechanism for parallel `Agent(...)` dispatch in a single assistant turn is documented as the "split-and-merge" pattern but its current syntactic shape (multiple Agent tool invocations in one assistant response vs. a single Agent call returning multiple handles) should be confirmed against the live Claude Code v2.1+ docs. Also confirm whether `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` / `SendMessage` is reliable enough to use, **with the artifact-based fallback as the default** (per Pitfall 12 — same-agent identity is a myth, so the fallback is the canonical path regardless).

Phases with standard patterns (skip research-phase, proceed directly to atomic-plan):

- **Phase 1 — Marketplace + plugin skeleton:** schemas and conventions are exhaustively documented; canonical reference is `anthropics/claude-plugins-official`.
- **Phase 2 — Plugin packaging:** hook event semantics, `${CLAUDE_PLUGIN_ROOT}`, exit-code conventions all documented in the official Hooks reference.
- **Phase 4 — Orchestrator + research/plan loops:** all building blocks (skill loading, AskUserQuestion, Bash + jq, Write/Read tools) are standard; the only novelty is gluing them together, which is detailed in `ARCHITECTURE.md` Pattern 1 + Pattern 5.
- **Phase 5 — Single-phase engineer + review:** standard subagent pattern + codex wrapper script already designed in Phase 3.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All schemas and CLI flags verified live against official Anthropic (`code.claude.com`) and OpenAI (`developers.openai.com`) docs on 2026-05-27. Every command in the recommended workflow has a documented contract. |
| Features | HIGH | Multiple high-quality reference plugins (`anthropics/claude-plugins-official`, `ralph-loop`, `gsd-build/get-shit-done`, `claude-code-workflow-orchestration`, `claude-review-loop`, `adamsreview`) cover every feature decision; the differentiator surface is explicit and supported by competitor analysis. |
| Architecture | MEDIUM-HIGH | Marketplace + plugin layout HIGH (canonical). Orchestrator-skill-in-main-thread HIGH (forced by the "subagents cannot spawn subagents" rule). Parallel `Agent(...)` dispatch syntax MEDIUM — it's the well-known split-and-merge pattern but the precise current syntactic invocation should be confirmed in Phase 6 planning. Subagent identity continuity MEDIUM (Pattern 4 fallback is sound regardless — Pitfall 12 confirms there's no real "same agent" anyway). |
| Pitfalls | HIGH | Every catastrophic pitfall has a documented community/official source (GitHub issues for codex auth bugs and codex empty-output bug; official hooks docs for exit-code semantics; official subagents docs for the no-spawn rule). Mitigations are concrete and mechanical. |

**Overall confidence:** HIGH.

### Gaps to Address

- **Exact split-and-merge invocation syntax** for parallel `Agent(...)` calls in a single assistant turn — confirm against the live docs at the start of Phase 6 planning (the pattern is well-attested, only the exact invocation shape needs confirmation).
- **`SendMessage` / `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` stability** — irrelevant to the design (the artifact-based fallback is canonical per Pitfall 12) but worth noting at Phase 5 planning so the orchestrator does not depend on the flag.
- **Calibration corpus for the exhaustive-review prompt** — does not exist yet. Phase 3 must include a sub-step to assemble 3–5 deliberately-flawed reference plans/diffs and iterate the prompt against them until coverage is reliable (Pitfall 8 mitigation requires this).
- **Reserved plugin name check** — verify `oplya` and `zapili` are not on the current Claude Code reserved-names list at Phase 1 start (FEATURES.md notes they were clear on 2026-05-27, but this is a free check at scaffolding time).
- **Per-phase token-budget threshold** — the recommendation is a soft 10k-token cap per engineer prompt (Pitfall 18); the exact threshold should be tuned during Phase 5 against real medium-task runs and documented for the planner contract.

## Sources

### Primary (HIGH confidence)

- **Claude Code official docs** — `code.claude.com/docs/en/plugins`, `plugins-reference`, `plugin-marketplaces`, `hooks`, `sub-agents`, `skills`, `slash-commands` (manifest schemas, hook events, subagent rules, `${CLAUDE_PLUGIN_ROOT}` semantics)
- **OpenAI Codex CLI official docs** — `developers.openai.com/codex/noninteractive`, `cli/features`, `cli/reference`, `auth` (`codex exec`, `--json`, `--output-schema`, `--sandbox`, stdout/stderr separation, ChatGPT-vs-API-key auth paths)
- **`anthropics/claude-plugins-official`** — canonical layout, `category`/`tags`/`sha` conventions
- **GitHub issues `openai/codex#9091, #9253, #17041`** — confirmed silent-failure and headless-auth bugs that mitigations target

### Secondary (MEDIUM confidence)

- **`gsd-build/get-shit-done`** — `.planning/` artifact layout, wave coordination, atomic-plan heuristics
- **`anthropics/claude-code/plugins/ralph-wiggum`** — official loop-until-done reference
- **`barkain/claude-code-workflow-orchestration`** — parallel wave scheduling, task-completion verification
- **`hamelsmu/claude-review-loop`**, **`adamjgmiller/adamsreview`** — codex-as-reviewer integration patterns, severity grading
- **`hesreallyhim/claude-code-json-schema`** — community JSON Schemas for manifests
- **Anthropic prompt-engineering guidance** — XML-tag canon for structured prompts

### Tertiary (LOW confidence — informational only)

- Practitioner blogs on subagent orchestrator patterns (channel.tel, MindStudio, responseawareness, smartscope, claudefa.st) — useful for confirming community wisdom on parallel dispatch and resource isolation, but not load-bearing for any design decision
- Refactix on worktree-based isolation — informs the file-scope-overlap discussion but worktrees are not adopted (out of scope for v1)

---
*Research completed: 2026-05-27*
*Ready for roadmap: yes*
