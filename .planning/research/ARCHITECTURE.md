# Architecture Research

**Domain:** Claude Code plugin marketplace + multi-agent development-workflow plugin
**Researched:** 2026-05-27
**Confidence:** HIGH (marketplace + plugin layout, subagent semantics, codex CLI), MEDIUM (parallel-Agent execution, agent identity across review/fix cycles — both rely on Claude Code's current Agent-tool behaviour rather than a formal spec)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            oplya (marketplace repo)                           │
│  .claude-plugin/marketplace.json  ──►  catalogs plugins/* as siblings         │
└───────────────┬──────────────────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                         plugins/zapili (the plugin)                           │
│                                                                                │
│  .claude-plugin/plugin.json    hooks/        commands/         skills/         │
│  └ manifest                    └ codex-check └ /zapili         └ orchestrator  │
│                                  (SessionStart)                                │
│                                                                                │
│                                ┌──────────────────────┐                        │
│                                │  agents/             │                        │
│                                │  ├ researcher.md     │                        │
│                                │  ├ planner.md        │                        │
│                                │  └ engineer.md       │                        │
│                                └──────────────────────┘                        │
└───────────────┬──────────────────────────────────────────────────────────────┘
                │ enabled in a user's Claude Code session
                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│              User Claude Code session (in target project's CWD)               │
│                                                                                │
│   /zapili command  ──►  loads orchestrator skill (workflow control flow)      │
│                                                                                │
│        ┌────────────────────── Orchestrator (main thread) ──────────────────┐ │
│        │                                                                    │ │
│        │  reads .planning/PROJECT.md style TASK.md + .zapili/state.json     │ │
│        │  drives the 6 phases, owns AskUserQuestion, owns state.json writes │ │
│        │                                                                    │ │
│        │   ┌─ Agent(researcher) ─┐   ┌─ Bash(codex exec) ─┐                 │ │
│        │   │ produces questions  │   │ research validate  │                 │ │
│        │   │ + findings          │   │ → HIGH/MED/LOW     │                 │ │
│        │   └─────────────────────┘   └────────────────────┘                 │ │
│        │                                                                    │ │
│        │   ┌─ Agent(planner) ────┐   ┌─ Bash(codex exec) ─┐                 │ │
│        │   │ PLAN.md +           │   │ plan validate      │                 │ │
│        │   │ PHASE-XX.md files   │   │ → HIGH/MED/LOW     │                 │ │
│        │   └─────────────────────┘   └────────────────────┘                 │ │
│        │                                                                    │ │
│        │   ┌── Wave executor ─────────────────────────────────────────────┐ │ │
│        │   │  parallel: Agent(engineer #1..n)  ── one per phase in wave   │ │ │
│        │   │  parallel: Bash(codex exec)       ── one review per phase    │ │ │
│        │   │  fix loop: Agent(engineer #i)     ── same i for that phase   │ │ │
│        │   └──────────────────────────────────────────────────────────────┘ │ │
│        │                                                                    │ │
│        └────────────────────────────────────────────────────────────────────┘ │
│                                                                                │
│   On-disk artifacts in CWD:                                                    │
│   TASK.md  CONTEXT.md  PLAN.md  PHASE-01.md … PHASE-NN.md  .zapili/state.json │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `oplya` marketplace repo | Catalogs plugins; exposed via `/plugin marketplace add` | `.claude-plugin/marketplace.json` + `plugins/<name>/` siblings |
| `zapili` plugin manifest | Declares plugin identity & version | `.claude-plugin/plugin.json` |
| `SessionStart` hook | Fail-fast verification that `codex` CLI is available | Bash script wired through `hooks/` |
| `/zapili` slash command | Workflow entry point; loads orchestrator instructions | `commands/zapili.md` |
| Orchestrator skill | Owns the control flow: research → validate → plan → validate → wave loop → finalize. Owns `state.json` writes. Owns `AskUserQuestion`. Owns codex invocations. | `skills/orchestrator/SKILL.md` (+ reference files) |
| Researcher subagent | Classifies task size, produces question list + findings + code refs | `agents/researcher.md` (read-only tools) |
| Planner subagent | Produces `PLAN.md` + `PHASE-XX.md` with wave structure | `agents/planner.md` |
| Engineer subagent | One per phase per wave; implements; returns formal change list; re-invoked for fix loop with same identity | `agents/engineer.md` (full tools) |
| Codex CLI (external) | Independent reviewer for research validation, plan validation, per-phase implementation review | `codex exec` invoked via Bash with `--output-schema` / `-o` |
| State file | Resume + iteration tracking | `.zapili/state.json` in CWD |
| Plan artifacts | Durable, human-inspectable plan + phase docs | `PLAN.md`, `PHASE-XX.md` in CWD |

**Critical separation of concerns:**

- **Orchestrator (main thread)** holds the control flow because subagents *cannot spawn other subagents* in Claude Code ([sub-agents docs](https://code.claude.com/docs/en/sub-agents)). The orchestrator must be a **skill loaded in the main session by the `/zapili` command**, not a subagent. This is the load-bearing architectural fact.
- **Subagents** are workers with isolated context — they receive a single prompt string and return a single text result.
- **Codex** is invoked as a plain Bash subprocess (`codex exec`) from the orchestrator — it is not a Claude subagent. This preserves the "independent reviewer" property the project relies on.

## Recommended Project Structure

```
oplya/                                          # marketplace repo root
├── .claude-plugin/
│   └── marketplace.json                        # MKT-01: catalog manifest
├── .gitignore                                  # MKT-02: Node/Python/IDE/OS + .zapili/
├── README.md                                   # MKT-04: install + plugin list
├── LICENSE
└── plugins/
    └── zapili/                                 # MKT-03 sibling pattern
        ├── .claude-plugin/
        │   └── plugin.json                     # MKT-05 / plugin manifest
        ├── README.md                           # plugin-local docs
        ├── CHANGELOG.md
        ├── hooks/
        │   └── hooks.json                      # SessionStart → check-codex.sh
        ├── scripts/
        │   ├── check-codex.sh                  # ZAP-02 fail-fast
        │   ├── codex-validate-research.sh      # codex exec wrapper, schema-bound
        │   ├── codex-validate-plan.sh
        │   └── codex-review-phase.sh
        ├── schemas/                            # JSON Schemas for codex output
        │   ├── validation-findings.schema.json # HIGH/MED/LOW issues
        │   ├── research-questions.schema.json  # researcher output shape
        │   ├── phase-changes.schema.json       # engineer change list
        │   └── state.schema.json               # .zapili/state.json shape
        ├── commands/
        │   └── zapili.md                       # /zapili entry point
        ├── skills/
        │   └── orchestrator/
        │       ├── SKILL.md                    # main control flow
        │       └── references/
        │           ├── contracts.md            # XML envelope + JSON spec
        │           ├── task-sizing.md          # ZAP-15 thresholds
        │           ├── codex-prompts.md        # ZAP-16 exhaustive review
        │           └── state-machine.md        # resume semantics
        └── agents/
            ├── researcher.md                   # ZAP-03
            ├── planner.md                      # ZAP-06
            └── engineer.md                     # ZAP-08/10
```

### Structure Rationale

- **`oplya/` is the marketplace root** because `.claude-plugin/marketplace.json` must live at the repo root for `/plugin marketplace add <repo>` to discover it ([plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces)).
- **`plugins/<name>/` siblings** match the official layout ([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)) and let `marketplace.json` reference each plugin with `"source": "./plugins/zapili"`. Relative paths are resolved from the marketplace root, not from `.claude-plugin/`.
- **No top-level `shared/` or `lib/`**: Claude Code copies the plugin directory into `~/.claude/plugins/cache` on install; files outside the plugin directory (e.g. `../shared-utils`) are not copied. Anything `zapili` needs must live under `plugins/zapili/`. Future cross-plugin sharing would use symlinks, but v1 has one plugin so this is moot.
- **`commands/` holds the single entry point** `zapili.md`. Plugin commands are namespaced; users will invoke `/zapili:zapili` (or just `/zapili` if it's the only command in the plugin — both forms appear in the docs depending on naming). Keep the command body minimal: load the orchestrator skill, hand off control.
- **`skills/orchestrator/` is where the control flow lives.** A skill loads into the main session's context and can drive multi-step flows that spawn subagents. Subagents cannot spawn subagents, so the orchestrator cannot itself be a subagent — it must run in the main thread. `references/` carries the bulky contract / sizing / prompt material so `SKILL.md` stays under the 500-line guideline.
- **`agents/` flat** (no subfolders) for v1 — plugin agents in subfolders get colon-scoped names like `zapili:engineer`, which is fine but unnecessary for three agents. Identifier comes from the `name:` frontmatter, not the filename.
- **`hooks/hooks.json` + `scripts/`** separation: `hooks.json` is the declarative manifest Claude Code reads; the actual logic is Bash in `scripts/` for transparency, debuggability, and reuse from the orchestrator.
- **`schemas/`** is the linchpin of "formalized inter-agent contracts" (ZAP-14). Every codex invocation passes `--output-schema schemas/<name>.json`, every subagent prompt embeds the relevant schema. This is what turns "Anthropic-style XML+JSON" from vibes into a contract.
- **No `mcp/`** — `zapili` doesn't need MCP servers in v1; codex is invoked as a subprocess, not an MCP server.

## Architectural Patterns

### Pattern 1: Orchestrator-in-Main-Thread, Workers-as-Subagents

**What:** The slash command loads an orchestrator skill into the main Claude session. The main thread (orchestrator) drives the workflow, spawning researcher/planner/engineer subagents and Bash-invoking codex. Subagents are stateless workers that return a single structured result.

**When to use:** Multi-phase workflows with loops, branching, parallel fan-out — anything that requires *control flow* across many agent invocations.

**Trade-offs:**
- **Pro:** Only architecture compatible with Claude Code's constraint that subagents cannot spawn subagents. Keeps `state.json` writes in one place (the orchestrator). Single source of truth for "where are we in the workflow".
- **Con:** The orchestrator's context grows over a long workflow because every subagent's return text lands back in the main conversation. Mitigation: keep subagent returns formal and compact (a JSON change-list, not file diffs); push detail into on-disk artifacts.

**Example skeleton (orchestrator SKILL.md pseudocode):**
```markdown
# Orchestrator workflow
1. Read TASK.md, .zapili/state.json
2. If state.phase == "init":
   - Spawn @researcher with the contract prompt (XML+JSON envelope)
   - Parse JSON block from response; write CONTEXT.md candidate
   - AskUserQuestion for each researcher question
   - Merge answers → CONTEXT.md; set state.phase = "research-validate"
3. If state.phase == "research-validate":
   - Bash: codex-validate-research.sh → validation.json
   - If HIGH/MEDIUM present: loop back to research with the findings
   - Else: state.phase = "plan"
4. ... (same shape for plan / wave loops)
```

### Pattern 2: Schema-First Inter-Agent Contracts (XML envelope + JSON payload)

**What:** Every prompt sent to a subagent or to codex follows a fixed XML envelope. Every response carries a `<payload>` containing a JSON block validated against a schema in `schemas/`. The orchestrator parses only the JSON; prose lives outside `<payload>` for the human reader.

**When to use:** Any agent-to-agent call where the orchestrator must make a decision based on the response. Mandatory in `zapili` for: researcher question list, codex validation findings, planner phase list, engineer change list, codex per-phase review findings.

**Trade-offs:**
- **Pro:** Deterministic parsing; codex's `--output-schema` flag enforces the JSON shape server-side ([codex non-interactive docs](https://developers.openai.com/codex/noninteractive)); subagent drift is caught at parse time, not at decision time.
- **Con:** Schema authoring overhead. Mitigation: there are only ~5 schemas total and they share primitives (a `Finding` with `severity ∈ HIGH|MEDIUM|LOW`, `location`, `remediation`).

**Example envelope:**
```xml
<request>
  <role>research-validator</role>
  <inputs>
    <file path="TASK.md">...</file>
    <file path="CONTEXT.md">...</file>
  </inputs>
  <instructions>
    Audit for contradictions, gaps, missing context. Report EVERY finding
    at HIGH, MEDIUM, and LOW severity. Do not summarize. Do not pareto-filter.
  </instructions>
  <output-schema>schemas/validation-findings.schema.json</output-schema>
</request>
```

```xml
<response>
  <summary>Found 3 HIGH, 5 MEDIUM, 12 LOW.</summary>
  <payload>
  {"findings":[{"severity":"HIGH","location":"CONTEXT.md:42","issue":"...","remediation":"..."}]}
  </payload>
</response>
```

### Pattern 3: Wave-Scoped Parallel Fan-Out, Strictly Sequential Across Waves

**What:** Within a wave, the orchestrator issues N `Agent(engineer)` calls in a single assistant message — Claude Code dispatches them in parallel ([orchestrator pattern](https://www.channel.tel/blog/claude-code-subagents-orchestrator-pattern), [parallel patterns](https://www.mindstudio.ai/blog/claude-code-split-and-merge-pattern-sub-agents)). After all return, the orchestrator issues N `Bash(codex exec ...)` calls in parallel for per-phase review. Between waves, work is strictly sequential — the next wave is not started until the prior wave's review/fix loop has converged.

**When to use:** Any time the planner has produced multiple phases whose file scopes do not overlap (planner's job is to guarantee this; ZAP-06).

**Trade-offs:**
- **Pro:** Maximises throughput without write conflicts. Maps cleanly to the user's "wave" mental model.
- **Con:** Token-cost spike during a wide wave. Mitigation: planner is instructed in ZAP-15 to cap wave width at the size class (small=1, medium≤2, large≤3, gigantic≤4 is a sensible default — tune in implementation phase).

### Pattern 4: Agent-Identity Continuity via Forked Subagents

**What:** When a phase's codex review returns findings, the orchestrator must route fixes back to the *same engineer that produced the work*, so it retains in-context memory of decisions and files touched. Claude Code supports this via subagent resume: when a subagent finishes, the orchestrator receives its agent ID, and can `SendMessage` to that ID to resume it with full prior conversation history ([sub-agents docs — "Resume subagents"](https://code.claude.com/docs/en/sub-agents)). This requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.

**When to use:** Per-phase fix loop (ZAP-10). Each engineer subagent in the wave has an ID; the orchestrator stores `{phase_id → agent_id}` in `state.json` and resumes the matching engineer with the review's findings.

**Trade-offs:**
- **Pro:** Engineer keeps memory of "I chose X because Y" — the fix doesn't have to be re-justified from scratch. Solves the project's "same agent that did the work also fixes the review" requirement.
- **Con:** Depends on an experimental flag. **Fallback if the flag is unavailable:** the orchestrator passes the engineer's original `<payload>` (the formal change list, plus any decision rationale the engineer was instructed to emit) back into a fresh `Agent(engineer)` invocation as `<prior-work>`. Continuity is degraded but workable.
- **Risk flag:** Confirm the `SendMessage` / agent-teams flag is stable enough to depend on during the implementation phase. If not, plan around the fallback from day one.

### Pattern 5: Resume-from-Artifacts State Machine

**What:** `.zapili/state.json` is the *primary* resume index — phase, wave, iteration counter, engineer agent IDs, last codex finding set. On `/zapili` re-invocation, the orchestrator reads `state.json` first, then sanity-checks against on-disk artifacts (does `PLAN.md` exist? do `PHASE-XX.md` files match the wave manifest?). If `state.json` is missing or stale, the orchestrator infers state from artifacts (e.g. `PLAN.md` present + no `state.json` → resume at wave 1).

**When to use:** Every entry into the workflow (`/zapili` always reads state before doing anything).

**Trade-offs:**
- **Pro:** Survives session loss, terminal restarts, and `Ctrl+C`. Human-inspectable. No bespoke database.
- **Con:** Two sources of truth (state file + artifacts) can drift. Mitigation: artifacts are authoritative for *content*; `state.json` is authoritative for *position* and *non-content metadata* (agent IDs, iteration counters). Conflict resolution rule: trust artifacts for "did this phase happen", trust state for "what iteration are we on".

## Data Flow

### End-to-end workflow

```
TASK.md (user-authored, pre-existing)
   │
   ▼
/zapili invocation
   │
   ▼
Orchestrator skill loaded into main thread
   │
   ▼
state.json bootstrap (read or create with phase="research")
   │
   ▼
┌─────────────── PHASE: RESEARCH ────────────────┐
│                                                │
│  Orchestrator                                  │
│      │  Agent(researcher) with TASK.md         │
│      ▼                                         │
│  Researcher subagent (read-only)               │
│      │  returns <payload>{questions,findings, │
│      │  task_size, code_refs}</payload>        │
│      ▼                                         │
│  Orchestrator                                  │
│      │  AskUserQuestion(question[i])  ×N       │
│      ▼                                         │
│  CONTEXT.md written (answers + findings +     │
│  code refs)                                    │
│      │                                         │
└──────┼─────────────────────────────────────────┘
       ▼
┌─────────────── PHASE: RESEARCH VALIDATE ───────┐
│                                                │
│  Orchestrator                                  │
│      │  Bash: codex exec --output-schema       │
│      │       schemas/validation-findings ...   │
│      ▼                                         │
│  validation-findings.json                      │
│      │                                         │
│      ▼ if HIGH|MEDIUM > 0                     │
│  Loop back to RESEARCH with findings as       │
│  additional context                            │
│      │ else                                    │
│      ▼                                         │
└──────┼─────────────────────────────────────────┘
       ▼
┌─────────────── PHASE: PLAN ────────────────────┐
│  Agent(planner) with TASK.md + CONTEXT.md     │
│  returns PLAN.md + PHASE-01.md … PHASE-NN.md  │
│  (planner writes files directly with Write)    │
└──────┼─────────────────────────────────────────┘
       ▼
┌─────────────── PHASE: PLAN VALIDATE ───────────┐
│  Bash: codex exec ... → validation-findings   │
│  Loop until HIGH|MEDIUM = 0                    │
└──────┼─────────────────────────────────────────┘
       ▼
┌─────────────── WAVE LOOP ──────────────────────┐
│  For each wave W in PLAN.md.waves:             │
│                                                │
│    PARALLEL fan-out (single assistant turn):   │
│      Agent(engineer) for phase 1 in W ─┐      │
│      Agent(engineer) for phase 2 in W  ├─→    │
│      Agent(engineer) for phase 3 in W ─┘      │
│                                                │
│    Each engineer returns                       │
│      <payload>{files_touched, decisions,      │
│      change_summary}</payload>                 │
│      orchestrator stores {phase → agent_id}   │
│                                                │
│    PARALLEL review:                            │
│      Bash: codex-review-phase.sh × N           │
│      → review-findings-{phase}.json each       │
│                                                │
│    PER-PHASE FIX LOOP:                         │
│      For phases with HIGH|MEDIUM findings:     │
│        Resume engineer (via SendMessage if     │
│        available, else fresh + prior-work)    │
│        engineer fixes, returns updated payload│
│        Re-review with codex                    │
│      Repeat until wave is clean.               │
│                                                │
│    state.json: wave = W+1                      │
└──────┼─────────────────────────────────────────┘
       ▼
┌─────────────── PHASE: FINALIZE ────────────────┐
│  Orchestrator aggregates all engineer payloads│
│  Renders final summary: files modified +      │
│  decisions + rationale → user                  │
│  state.json: phase = "done"                   │
└────────────────────────────────────────────────┘
```

### Key Data Flows

1. **TASK.md → researcher → CONTEXT.md:** User-authored TASK plus orchestrator-mediated user answers are persisted to CONTEXT.md. Researcher returns its findings as a JSON payload; orchestrator merges with user answers and writes the artifact. CONTEXT.md is the only thing the planner needs from the research phase.

2. **CONTEXT.md → planner → PLAN.md + PHASE-XX.md:** Planner writes plan files directly (it has Write tool). Returns a compact JSON payload describing the wave/phase structure for the orchestrator to walk; the artifacts themselves are read off disk by codex and by engineers.

3. **PHASE-XX.md → engineer → source files + change-list payload:** Engineer reads its assigned phase doc plus TASK.md and CONTEXT.md (everything else is scoped out by the orchestrator's prompt), edits source files, and returns a formal `<payload>{files_touched: [...], decisions: [...], change_summary: "..."}`. The diff is on disk; the payload is the orchestrator's machine-readable summary.

4. **engineer change-list → codex → review-findings:** Codex review prompt explicitly references TASK.md, PHASE-XX.md, and the engineer's payload (passed via stdin or temp file). Output is schema-validated JSON. Codex is invoked once per phase per wave, in parallel.

5. **review-findings → orchestrator → engineer (resumed):** Findings JSON is reformatted into the engineer's prompt envelope and sent back via `SendMessage` (preferred) or a fresh `Agent(engineer)` with the prior payload attached (fallback). The engineer mutates source files; cycle repeats.

6. **state.json everywhere:** Written by the orchestrator at every state transition. Never written by subagents. Never written by codex. Single-writer invariant simplifies resume.

## Scaling Considerations

Scale here is **per-task size**, not per-user.

| Scale (task size) | Architecture Adjustments |
|-------|--------------------------|
| Small (≤100 LOC, plan only) | Skip wave loop entirely if plan has 1 phase; collapse into single engineer + single review. State machine has the same shape; some phases just have zero iterations. |
| Medium (≤500 LOC, 3-4 phases) | Standard flow. Typically 1-2 waves with 1-3 phases each. |
| Large (≤1000 LOC, 5-8 phases) | Wave width matters. Planner constrained to ≤3 parallel engineers per wave to keep token cost predictable. |
| Gigantic (>1000 LOC, 9-20 phases) | Wave width still capped (≤4). Consider intermediate state checkpoints: write `.zapili/state-wave-{N}.snapshot.json` so a botched fix loop can be rolled back without redoing earlier waves. |

### Scaling Priorities (when something breaks first)

1. **First bottleneck: orchestrator context bloat over long workflows.** Every subagent return text re-enters the main thread. Mitigation: enforce strict payload size in subagent prompts ("change_summary ≤ 400 words"), push detail to on-disk artifacts. Codex outputs go to files via `-o` rather than being inlined.
2. **Second bottleneck: codex CLI latency dominating wave time.** Per-phase parallel review helps. If codex becomes a hot path, the per-wave fix loop can run review and engineer fix in lockstep rather than strictly serial (engineer keeps working on lower-severity findings while codex re-reviews HIGHs).
3. **Third bottleneck: subagent identity loss on resume.** If `SendMessage` becomes unreliable, the orchestrator's `prior-work` fallback grows to include increasingly larger context dumps, which inflates per-fix-iteration token cost. Mitigation: tighter engineer payload schema with explicit `decisions[]` field captured up front.

## Anti-Patterns

### Anti-Pattern 1: Putting the orchestrator in a subagent

**What people do:** Define `agents/orchestrator.md` and let it spawn researcher/planner/engineers.
**Why it's wrong:** Claude Code subagents **cannot spawn other subagents** — full stop. The Agent tool is not available inside a subagent's tool set ([sub-agents docs — "subagents cannot spawn other subagents"](https://code.claude.com/docs/en/sub-agents)). The workflow would die on the first researcher invocation.
**Do this instead:** Put the orchestrator in a **skill** loaded into the main session by the `/zapili` slash command. Skills run in the main thread; main thread has the Agent tool.

### Anti-Pattern 2: Free-form text contracts between agents

**What people do:** Researcher returns "Here are some questions: 1. ... 2. ...". Orchestrator regex-parses.
**Why it's wrong:** Drift is silent and catastrophic. A researcher that decides to return 2 questions instead of "the size-classified question count" cannot be detected without parsing prose. Fixes cascade into more prose-parsing logic.
**Do this instead:** XML envelope, JSON payload, JSON Schema validation. Codex's `--output-schema` enforces server-side; subagent payloads validated in the orchestrator with `jq` against a schema.

### Anti-Pattern 3: Codex as a Claude subagent

**What people do:** Wrap codex as if it were another Claude agent or an MCP tool.
**Why it's wrong:** The project's design relies on codex being a *different model family* providing *independent* review. Wrapping it inside a Claude tool layer doesn't change that, but it hides codex behind interfaces that make the "independent reviewer" property fragile (e.g. errors get swallowed, output gets reformatted, schema enforcement becomes harder).
**Do this instead:** `codex exec` invoked as a Bash subprocess from the orchestrator, with `--output-schema` and `-o` for structured output and exit-code checking. Treat it as a peer system, not a subordinate tool.

### Anti-Pattern 4: Letting subagents write state.json

**What people do:** Engineer writes "I finished phase 3" to state.json on its own.
**Why it's wrong:** Multi-writer to state.json with no locking. Engineers running in parallel will clobber each other.
**Do this instead:** Single-writer invariant — only the orchestrator writes `.zapili/state.json`. Subagents return their status in the response payload; the orchestrator translates that to a state mutation.

### Anti-Pattern 5: Cross-plugin file references

**What people do:** Put shared prompt templates in a top-level `oplya/shared/` and reference them from `plugins/zapili/skills/orchestrator/SKILL.md` via `../../shared/...`.
**Why it's wrong:** Claude Code copies each plugin into `~/.claude/plugins/cache` on install; anything outside the plugin's directory is not copied ([plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces)). The references break at install time.
**Do this instead:** Every file `zapili` needs lives under `plugins/zapili/`. For a future second plugin, duplicate or symlink — never path-traverse out of the plugin root.

### Anti-Pattern 6: Implicit task sizing

**What people do:** Researcher decides on its own how many questions to ask.
**Why it's wrong:** ZAP-15 defines explicit thresholds. Without enforcing them in the contract, behaviour drifts across runs and is unpredictable.
**Do this instead:** Researcher's prompt embeds the size policy table; researcher's JSON payload includes `task_size: "small"|"medium"|"large"|"gigantic"`; orchestrator validates that the returned question count matches the size class, and re-prompts if not.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| `codex` CLI | Bash subprocess via `codex exec --output-schema <schema> -o <out.json>` | Stream stderr for progress; final JSON to file. Exit code non-zero means failure — orchestrator must handle (retry once, then surface to user). Verify presence in `SessionStart` hook (ZAP-02). |
| GitHub (marketplace host) | Plain git remote — users run `/plugin marketplace add <github-url>` | Public repo; relative plugin paths work because users add via Git source ([plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces)). |
| Claude Code plugin runtime | Declarative: `plugin.json`, `hooks.json`, `commands/*.md`, `skills/*/SKILL.md`, `agents/*.md` | No code dependency — purely manifest-driven. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Orchestrator ↔ Researcher / Planner / Engineer | `Agent` tool with XML+JSON envelope prompt; subagent returns `<response><payload>{...}</payload></response>` | Parser is `jq` against schema. Reject malformed responses fast (no fallback parsing). |
| Orchestrator ↔ Codex | `Bash` tool calling `scripts/codex-*.sh`; scripts pass schema, inputs, capture JSON to file | All codex scripts share a common harness that exits non-zero on schema validation failure. |
| Orchestrator ↔ User | `AskUserQuestion` for research questions; final notification via main-thread message (ZAP-12) | `AskUserQuestion` not available inside subagents — another reason the orchestrator must be in the main thread. |
| Orchestrator ↔ State file | Read at entry; write at every transition; atomic write (write `.tmp` then rename) | Single-writer invariant. |
| Plugin ↔ Project files (`TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`, `.zapili/`) | Direct file I/O from main thread and from subagents in the CWD | Subagent CWD is inherited from main session; engineers edit project source files directly. |

## Build Order (Dependency Graph for Roadmap)

This is the suggested phase ordering for the roadmap — each row depends on rows above. Phases ① and ② are the marketplace skeleton; ③–⑩ are the plugin proper.

```
① Marketplace skeleton (oplya/.claude-plugin/marketplace.json, README, .gitignore)
        │
        ▼
② Plugin skeleton (plugins/zapili/.claude-plugin/plugin.json, README, empty hooks/commands/skills/agents)
        │   ┌───── must be installable end-to-end before any logic ─────┐
        ▼
③ SessionStart hook + codex-check.sh (ZAP-02) — fail fast wired in early so all subsequent dev runs verify their own env
        │
        ▼
④ Inter-agent contract foundations: schemas/ + skills/orchestrator/references/contracts.md (ZAP-14)
        │   ▲
        │   │ schemas authored first because every later component depends on them
        ▼
⑤ Slash command /zapili + minimal orchestrator skill (state.json read/write, phase dispatch stub) (ZAP-01, ZAP-13)
        │
        ▼
⑥ Researcher subagent + research phase wiring + CONTEXT.md write (ZAP-03, ZAP-04, ZAP-15)
        │
        ▼
⑦ codex research validation script + research-validate loop in orchestrator (ZAP-05, ZAP-16)
        │
        ▼
⑧ Planner subagent + plan phase wiring (PLAN.md / PHASE-XX.md) (ZAP-06)
        │
        ▼
⑨ codex plan validation script + plan-validate loop (ZAP-07, ZAP-16)
        │
        ▼
⑩ Engineer subagent + single-phase implementation (no parallelism yet) (ZAP-08)
        │
        ▼
⑪ codex per-phase review + same-phase fix loop (ZAP-09, ZAP-10)
        │
        ▼
⑫ Wave executor: parallel fan-out across phases in a wave + per-wave fix convergence (ZAP-08, ZAP-09, ZAP-10, ZAP-11)
        │
        ▼
⑬ Final notification / summary aggregator (ZAP-12)
        │
        ▼
⑭ Resume-from-state hardening (kill workflow mid-wave, re-invoke /zapili, verify clean recovery) (ZAP-13)
        │
        ▼
⑮ Light publication process (manifest validators, README polish) (MKT-04, MKT-06)
```

**Critical-path observations:**

- **Contracts (④) come before any agent.** Schemas are the API; agents and codex scripts are implementations of that API. Authoring schemas first prevents three different prompts from drifting into three different shapes.
- **Single-phase implementation (⑩) before parallel waves (⑫).** Parallelism is an orthogonal concern to "does the engineer work at all". Get one phase round-tripping cleanly first; then fan out.
- **Resume (⑭) is hardening, not new behaviour.** It validates that every earlier phase wrote state correctly. If resume breaks, the bug is in an earlier phase's state.json write.
- **Marketplace polish (⑮) is last.** The plugin must work end-to-end before its README is worth writing.

## Sources

- [Create and distribute a plugin marketplace (Claude Code docs)](https://code.claude.com/docs/en/plugin-marketplaces) — authoritative on `marketplace.json` schema, relative-path resolution, install-time caching
- [Create custom subagents (Claude Code docs)](https://code.claude.com/docs/en/sub-agents) — authoritative on subagent frontmatter, parallel/foreground/background, subagent-cannot-spawn-subagent rule, `SendMessage`/resume
- [Extend Claude with skills (Claude Code docs)](https://code.claude.com/docs/en/skills) — skills as in-main-thread orchestration; SKILL.md format
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — reference layout of `plugins/<name>/` sibling pattern
- [Non-interactive mode — Codex CLI (OpenAI)](https://developers.openai.com/codex/noninteractive) — `codex exec`, `--json`, `--output-schema`, `-o`, sandbox flags
- [Codex CLI features](https://developers.openai.com/codex/cli/features) — exec-mode behaviour, stderr/stdout split
- [Claude Code Subagents: The Orchestrator's Dilemma](https://responseawareness.substack.com/p/claude-code-subagents-the-orchestrators) — context-isolation tradeoffs
- [Claude Code subagents and the orchestrator pattern (channel.tel)](https://www.channel.tel/blog/claude-code-subagents-orchestrator-pattern) — dependency-driven parallel dispatch
- [Claude Code Split-and-Merge Pattern (MindStudio)](https://www.mindstudio.ai/blog/claude-code-split-and-merge-pattern-sub-agents) — parallel-in-single-turn dispatch mechanics
- [Slash commands (Claude Code docs)](https://code.claude.com/docs/en/slash-commands) — `commands/*.md` format and frontmatter

---
*Architecture research for: Claude Code plugin marketplace + multi-agent development-workflow plugin*
*Researched: 2026-05-27*
