# Feature Research

**Domain:** Claude Code plugin marketplace + multi-agent development-workflow plugin
**Researched:** 2026-05-27
**Confidence:** HIGH (official Anthropic docs for marketplace schema; multiple independent reference plugins for workflow patterns — ralph-loop, GSD, claude-code-workflow-orchestration, claude-review-loop)

Two sub-domains researched. Each feature is tagged `[MKT]` (marketplace `oplya`) or `[ZAP]` (workflow plugin `zapili`). Some apply to both `[BOTH]`.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing any of these makes the project feel broken to users coming from `claude-plugins-official`, `ralph-loop`, GSD, or `claude-code-workflow-orchestration`.

| Feature | Sub-domain | Why Expected | Complexity | Notes |
|---------|-----------|--------------|------------|-------|
| `.claude-plugin/marketplace.json` at repo root with `name` + `owner` + `plugins[]` | [MKT] | Hard requirement of Claude Code `/plugin marketplace add`; install fails without it | **S** | Schema enforced by Claude Code loader; `name` must be kebab-case and not collide with reserved names |
| Per-plugin `.claude-plugin/plugin.json` with `name`, `version`, `description` | [MKT] | Required by spec; `version` drives update detection | **S** | Semver string; omitting `version` makes every commit a "new version" (bad UX) |
| `plugins/<name>/` subdirectory layout under marketplace root | [MKT] | Standard convention in `claude-plugins-official`, `cc-marketplace`, hyperskill, etc. | **S** | Matches PROJECT.md MKT-03 |
| Top-level `README.md` with marketplace add command + plugin list | [MKT] | First file viewers see on GitHub; install instructions live here because the marketplace UI in Claude Code has no rich rendering | **S** | Include `/plugin marketplace add <repo>` + per-plugin `/plugin install <name>@oplya` |
| Per-plugin `README.md` with usage examples | [MKT] | Official guidance ("Read the plugin README before installing"); community evaluates plugin safety from README | **S** | Should cover: what it does, install, the slash command(s), required external deps (codex CLI for zapili) |
| Single-command entry point | [ZAP] | All comparable workflow plugins expose one slash command (`/ralph-loop`, `/gsd:*`, `/workflow`) | **S** | Already specified as `/zapili` in ZAP-01 |
| Task input as a file in CWD (`TASK.md`) | [ZAP] | GSD uses `REQUIREMENTS.md`/`PROJECT.md`, ralph-loop accepts prompt-args; file-based is the dominant pattern for non-trivial tasks (avoids re-typing on resume) | **S** | Already specified |
| Context capture artifact (`CONTEXT.md`) | [ZAP] | GSD uses `CONTEXT.md`; the externalize-state-to-files pattern is the canonical answer to context rot | **S** | Already specified |
| Planning artifact (`PLAN.md`) | [ZAP] | Every reviewed plugin produces a plan-document before implementation; this is the canonical spec-driven development pattern | **S** | Already specified |
| Per-phase planning artifacts (`PHASE-XX.md`) | [ZAP] | GSD uses `XX-YY-PLAN.md`; per-phase splitting is required so each implementer subagent gets a focused 200K context | **M** | Naming convention: zero-padded indices, ordering reflects waves |
| Wave-based parallel execution of independent phases | [ZAP] | Universal pattern in GSD, claude-code-workflow-orchestration, multi-agent-ralph-loop; explicitly chosen in PROJECT.md | **L** | Wave = sequential group; intra-wave phases must not overlap on file scope |
| Sequential wave ordering | [ZAP] | Same as above; dependent work must wait for prior waves | **S** | Already specified in ZAP-11 |
| External reviewer LLM integration (codex CLI) | [ZAP] | Cross-provider review is the well-known multi-model pattern (claude-review-loop, openai/codex-plugin-cc, adamsreview); using same family for review-of-self is the failure mode it solves | **M** | Already specified; mandatory in PROJECT.md |
| Validation loop until clean (research / plan / per-phase review) | [ZAP] | All review-loop plugins implement this; ralph-loop's defining trait is loop-until-done | **M** | Loop until no HIGH/MEDIUM findings remain |
| Severity-graded review findings (HIGH/MEDIUM/LOW) | [ZAP] | Standard in claude-review-loop, adamsreview, codex-review; users expect a triage tier on review output | **S** | JSON-structured findings inside XML tags |
| File-based state survives session restart | [ZAP] | Claude Code session crashes & context-rot are well-known failure modes; resume from on-disk artifacts is table stakes for any multi-phase workflow | **M** | Already specified — `.zapili/state.json` + the markdown artifacts |
| Hook-driven dependency verification | [ZAP] | Hook docs explicitly recommend `SessionStart` for dependency checks; codex is the critical external dep | **S** | Already specified as ZAP-02 |
| Final summary report on completion | [ZAP] | Every workflow plugin notifies the user; bare "done" is unacceptable for a multi-hour run | **S** | Files modified + key decisions, per ZAP-12 |
| English-only prompts and artifacts | [BOTH] | Anthropic XML-tag guidance is English-centric; consistency matters more than language preference | **S** | Already a project constraint |
| MIT or Apache-2.0 license file in repo | [MKT] | Public OSS convention; absence blocks corporate adoption | **S** | SPDX-style; not in marketplace.json (not used by official plugins) but visible at repo root |
| `.gitignore` covering Node/Python/IDE/OS noise + `.zapili/` state | [MKT] | Standard hygiene; without it `.zapili/state.json` leaks into the marketplace repo from local testing | **S** | Already specified as MKT-02 |
| JSON manifest local validation before commit | [MKT] | Bad manifests break install for everyone; community plugins all do this even without CI | **S** | `python -m json.tool` or `jq` check is sufficient; explicit in MKT-06 |

### Differentiators (Competitive Advantage)

These would set `oplya`+`zapili` apart from the existing ecosystem. Not required to ship, but powerful.

| Feature | Sub-domain | Value Proposition | Complexity | Notes |
|---------|-----------|-------------------|------------|-------|
| **Exhaustive-review prompt design (HIGH/MEDIUM/LOW must be complete)** | [ZAP] | Existing review loops (claude-review-loop, adamsreview) ask for "top issues" or rank-and-filter, which forces extra iterations. PROJECT.md ZAP-16 explicitly forbids summarization — drives loop count toward 1 | **S** | Pure prompt-engineering win, low cost, big throughput improvement. Make it a documented selling point |
| **Formalized XML+JSON inter-agent contracts** | [ZAP] | Most workflow plugins use loose prose prompts; structured contracts give deterministic parsing of issues, file-change lists, question batches, size classification | **M** | Anthropic-recommended pattern; ZAP-14 codifies it. Worth a public schema doc |
| **Task-size classification with embedded thresholds** | [ZAP] | GSD uses ad-hoc plan splitting; ralph-loop uses iteration caps. ZAP-15 encodes explicit LOC/module/question/phase thresholds → predictable workflow shape across task sizes | **S** | Pure prompt addition; high signal to users |
| **Researcher subagent (Q&A round before planning)** | [ZAP] | GSD has a "discuss phase"; most plugins skip this entirely. Asking the user clarifying questions before writing PLAN.md is the single biggest quality win for greenfield work | **M** | Already specified ZAP-03/ZAP-04 |
| **Two-tier validation (research-validation AND plan-validation)** | [ZAP] | Most plugins validate code or final plan only. Validating the research+context BEFORE planning catches contradictions early when fixing them is cheap | **M** | Already specified ZAP-05/ZAP-07; differentiator vs GSD which validates only the plan |
| **Per-phase review with same-agent fix loop** | [ZAP] | claude-review-loop reviews the full PR; ZAP-09/ZAP-10 routes fixes back to the same implementation agent for in-context memory — saves re-establishing context | **M** | Already specified |
| **Automatic resume from artifact inspection** | [ZAP] | GSD requires `/gsd-resume-work`; ralph-loop restarts via the loop. ZAP-13 says resume is automatic from artifact inspection (no extra command) — better UX | **M** | Already specified |
| **Mandatory external reviewer (no fallback to Claude)** | [ZAP] | claude-review-loop and adamsreview support fallback; PROJECT.md decision: failing fast on missing codex preserves cross-model-review value | **S** | Differentiator only if documented as a feature, not a limitation |
| **`displayName` for human-readable plugin titles** | [MKT] | Claude Code 2.1.143+ supports it; lets `zapili` show as "Zapili — Multi-Agent Dev Workflow" in the UI while keeping kebab-case internally | **S** | Trivial to add; most plugins skip it |
| **`category` + `tags` in marketplace entry** | [MKT] | Official marketplace uses `category`; `tags` are used for "community-managed". Improves discoverability even though no rich filtering UI exists yet | **S** | Categories from official set: `development` fits zapili; `tags: ["multi-agent", "workflow", "spec-driven", "codex"]` |
| **Repository pinned via `sha`/`ref` in marketplace.json** | [MKT] | Official plugins pin to commit SHA. Even with relative-path sourcing, allows reproducible installs for the team | **S** | Optional for relative paths but recommended once stable |
| **Versioning convention documented (semver bump on every release)** | [MKT] | Omitting `version` makes every commit a release; users get update prompts constantly. Explicit semver discipline is a meaningful polish item | **S** | Document in CONTRIBUTING.md or README |
| **CONTRIBUTING.md describing add-a-plugin flow** | [MKT] | Empty repo today, but team-shared marketplace will accumulate plugins. Lightweight contributor doc avoids ad-hoc layout drift | **S** | Light process per PROJECT.md MKT-06 — no CI gates, just conventions |
| **JSON Schema `$schema` field in marketplace.json + plugin.json** | [MKT] | hesreallyhim/claude-code-json-schema provides community schemas; enables IDE autocomplete for editors. Claude Code ignores `$schema` so no risk | **S** | Pure ergonomic improvement |
| **Single source of truth: no duplicated content between PLAN.md and PHASE-XX.md** | [ZAP] | Explicit project decision (ZAP-06). Common anti-pattern in spec-driven setups: planner restates phase details in both files, drift inevitable | **M** | Requires care in planner-subagent prompt design |
| **Strictly file-scope-checked parallelization** | [ZAP] | Intra-wave parallel safety is asserted via "file scopes do not overlap" rather than "we hope". Auditable and overrideable | **M** | Planner must emit a `files` block per phase; codex plan-validation checks overlap |
| **Compact, formalized implementer return contract** | [ZAP] | ZAP-08 specifies a "compact list of touched files with key changes" — gives the orchestrator a machine-parseable record without re-reading the diff | **S** | Prompt-engineering work; produces input for ZAP-12 summary |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Sub-domain | Why Requested | Why Problematic | Alternative |
|---------|-----------|---------------|-----------------|-------------|
| **Debugging / testing / hotfix workflow** in `zapili` | [ZAP] | Users will ask for "fix this bug" mode | Different task shape (root-cause-first vs design-first); different validation needs (regression vs spec-adherence); muddles the single-responsibility design | Already excluded in PROJECT.md Out of Scope; future sibling plugin |
| **GUI / web UI for the marketplace** | [MKT] | Other tool ecosystems have package-manager UIs | Claude Code's `/plugin` is the only sanctioned interface; building a web UI duplicates effort with no install path | Already excluded; rely on README + GitHub browsing |
| **CI/automated marketplace validation gates** | [MKT] | OSS convention | Solo maintainer + small team; ceremony slows iteration; manifest issues caught locally before commit | MKT-06: local validation only; CI is a future concern |
| **Built-in Claude fallback when codex is unavailable** | [ZAP] | Sounds friendly | Defeats cross-model-review purpose (claude-reviewing-claude has overlapping blind spots) | Fail-fast hook (ZAP-02) with clear install instruction |
| **Many small plugins** ("micro-plugins") | [MKT] | Single-responsibility extremism | Marketplace UI has no filters/categorization beyond `category`; each plugin install is friction; users want themed bundles | Themed plugins per PROJECT.md key decision |
| **Auto-detected task type** (skip TASK.md and infer from chat) | [ZAP] | Convenience | Loses persistence-on-restart property; loses auditability; encourages vague tasks → worse plans | TASK.md is a feature, not a limitation; resume depends on it |
| **"Auto-approve" / silent question rounds** | [ZAP] | Faster runs | Researcher questions exist precisely because pre-flight clarification has the highest ROI; auto-answering them with assumptions reintroduces the bug they prevent | Keep user-in-loop for research Q&A; could add per-question timeout default in v2 |
| **In-place edits without per-phase scopes** | [ZAP] | "Just let the agent figure it out" | Eliminates parallel-safety guarantee; collisions cause merge headaches | File-scoped phases enforced by planner contract |
| **Aggregated single-pass codex review** (one review for the whole change) | [ZAP] | Fewer codex calls | Loses per-phase targetability; can't route HIGH issues back to specific agent; one giant review is harder to act on | Per-phase reviews routed back to per-phase agents (ZAP-09/ZAP-10) |
| **Filtered / top-N codex findings** | [ZAP] | Less noise | ZAP-16 directly: each missed issue forces another iteration; full set up front converges faster | Exhaustive findings, explicitly required in prompt |
| **License-in-marketplace.json** field | [MKT] | OSS hygiene | Official marketplace does NOT use it (licensing lives in source repos). Adding it diverges from the convention with no benefit | LICENSE file at repo root; SPDX identifier in plugin.json if needed |
| **Built-in update notifications / changelog feed** | [MKT] | Modern package-manager UX | `/plugin marketplace update` already handles version-bump detection; building anything else is redundant work | Trust the Claude Code mechanism |
| **Interactive marketplace browser TUI** | [MKT] | "Like brew" | `/plugin` already provides this. Reinventing it adds maintenance and breaks the spec's distribution model | None — use what's there |

---

## Feature Dependencies

```
[marketplace.json valid] ──required for──> [/plugin marketplace add] ──required for──> [any user install]
        │
        └──prerequisite for──> [plugin.json valid] ──required for──> [zapili install]

[SessionStart hook: codex check] ──required for──> [/zapili command]

[TASK.md] ──input to──> [Research phase] ──produces──> [Researcher questions]
                                    │
                                    └──input to──> [User Q&A] ──produces──> [CONTEXT.md]
                                                                                  │
[TASK.md] + [CONTEXT.md] ─────────────────────────────────────────input to──> [Research validation]
                                                                                  │
                                                                       (loop until clean)
                                                                                  │
                                                                                  ▼
                                                                       [Planning phase]
                                                                                  │
                                                                                  ▼
                                                                  [PLAN.md] + [PHASE-XX.md*]
                                                                                  │
                                                                                  ▼
                                                                       [Plan validation (codex)]
                                                                                  │
                                                                       (loop until clean)
                                                                                  │
                                                                                  ▼
                          ┌──────────────────────[Wave 1: parallel phase agents]──────────────────────┐
                          │                                  │                                        │
                          ▼                                  ▼                                        ▼
                   [PHASE-01 agent]                   [PHASE-02 agent]                        [PHASE-NN agent]
                          │                                  │                                        │
                          ▼                                  ▼                                        ▼
                  [Codex review 01]                 [Codex review 02]                       [Codex review NN]
                          │                                  │                                        │
                          └────────────── (fix loop per phase, same-agent routing) ──────────────────┘
                                                              │
                                                              ▼
                                                      [Wave 2 ... Wave M]
                                                              │
                                                              ▼
                                                      [Final summary]

[.zapili/state.json] ──enables──> [Auto-resume on restart]
                          │
                          └──cross-references──> [TASK.md, CONTEXT.md, PLAN.md, PHASE-XX.md]
```

### Dependency Notes

- **`plugin.json` requires `marketplace.json`** — Without a marketplace catalog entry, the plugin is invisible to `/plugin install`. The two manifests must agree on plugin `name` and (if set) `version`.
- **Codex check (hook) gates every `/zapili` invocation** — Without ZAP-02, downstream validation phases (ZAP-05/07/09) silently degrade. Fail-fast at the boundary.
- **`CONTEXT.md` requires the Research phase output** — Researcher's question list is the schema for `CONTEXT.md`'s answer sections. Skipping research = empty/malformed `CONTEXT.md`.
- **Plan validation requires Research validation to have closed** — A plan built on contradictory context can't be saved by plan review. ZAP-05 must converge before ZAP-07 begins.
- **Wave N requires Wave N-1 fully closed (review + fixes)** — Sequential wave ordering is a non-negotiable safety property; otherwise downstream phases plan against unstable upstream artifacts (ZAP-11).
- **Same-agent fix routing requires the orchestrator to keep subagent handles** — If the orchestrator can't return to the same subagent, fixes lose in-context memory, which forces re-establishing context. Engineering constraint on the subagent invocation model.
- **State persistence depends on all markdown artifacts being self-sufficient** — `.zapili/state.json` is metadata only; the artifacts must be readable in isolation for resume to work (and for human inspection).
- **Exhaustive-review prompt design (ZAP-16) reduces loop count for every validation phase** — Cross-cutting differentiator that improves ZAP-05, ZAP-07, and ZAP-09 simultaneously.
- **File-scope-checked parallelization requires the planner to emit per-phase `files` blocks** — Without this, the codex plan-validation step (ZAP-07) cannot assert intra-wave safety. The planner contract is upstream of the safety property.

---

## MVP Definition

### Launch With (v1) — what `oplya` v1 + `zapili` v1 must ship

**Marketplace polish (`oplya`):**
- [ ] **MKT-01..06** as written in PROJECT.md — marketplace.json + plugins/ layout + READMEs + .gitignore + local JSON validation
- [ ] Repo `LICENSE` file (MIT or Apache-2.0)
- [ ] `displayName`, `category`, and `tags` on the `zapili` entry — cheap polish, official convention
- [ ] `$schema` field on both manifests — IDE ergonomics, no runtime cost

**zapili workflow (`zapili`):**
- [ ] **ZAP-01..16** as written in PROJECT.md — complete pipeline including SessionStart codex check, research + research validation, planning + plan validation, wave-based implementation with per-phase codex review and same-agent fix loops, auto-resume, formalized XML+JSON contracts, exhaustive-review prompts, embedded task-size policy

The MVP is essentially "ship PROJECT.md verbatim plus four polish items on the marketplace." Each project requirement maps to either a table-stakes or differentiator entry above; nothing in the research surfaces a missing must-have.

### Add After Validation (v1.x)

- [ ] **CONTRIBUTING.md with add-a-plugin checklist** — trigger: second plugin gets proposed (no abstraction for "many plugins" before then per PROJECT.md scope discipline)
- [ ] **`/plugin marketplace add` smoke-test script** — trigger: first install failure reported by a teammate
- [ ] **Configurable codex model / args via plugin userConfig** — trigger: codex defaults stop suiting some tasks
- [ ] **Optional per-question default timeout in research Q&A** — trigger: users report long question rounds; preserve user-in-loop default
- [ ] **Plan-validation cache for unchanged phases** — trigger: large/gigantic-class tasks taking too many iterations
- [ ] **JSON-schema file shipped in repo for marketplace.json/plugin.json** — trigger: second plugin author joins and tooling pays off

### Future Consideration (v2+)

- [ ] **CI validation** (manifest schema + minimal smoke) — defer until plugin count or contributor count justifies the ceremony
- [ ] **Alternative reviewer LLM** (Gemini, GPT-4 family, etc.) — codex is mandatory in v1 by explicit decision; revisit only if codex becomes unavailable
- [ ] **Sibling plugins for debug / test / hotfix** — separate plugins per PROJECT.md scope discipline
- [ ] **Skill bundles for common languages** — only if a clear pattern emerges across users' `TASK.md` files
- [ ] **Telemetry / iteration-count analytics** — defer until there's a need to tune validation prompts based on data
- [ ] **Web/static page listing of plugins** — only if discoverability becomes a real complaint

---

## Feature Prioritization Matrix

| Feature | Sub-domain | User Value | Implementation Cost | Priority |
|---------|-----------|------------|---------------------|----------|
| marketplace.json + plugin.json valid | [MKT] | HIGH | LOW | P1 |
| Per-plugin README + top-level README | [MKT] | HIGH | LOW | P1 |
| /zapili single entry point | [ZAP] | HIGH | LOW | P1 |
| codex SessionStart hook | [ZAP] | HIGH | LOW | P1 |
| Research phase + CONTEXT.md | [ZAP] | HIGH | MEDIUM | P1 |
| Research validation loop | [ZAP] | HIGH | MEDIUM | P1 |
| Planning phase + PLAN.md + PHASE-XX.md | [ZAP] | HIGH | MEDIUM | P1 |
| Plan validation loop | [ZAP] | HIGH | MEDIUM | P1 |
| Wave-based parallel implementation | [ZAP] | HIGH | HIGH | P1 |
| Per-phase codex review + same-agent fix loop | [ZAP] | HIGH | HIGH | P1 |
| State persistence + auto-resume | [ZAP] | HIGH | MEDIUM | P1 |
| Formalized XML+JSON contracts | [ZAP] | HIGH | MEDIUM | P1 |
| Exhaustive-review prompt design (HIGH/MED/LOW) | [ZAP] | HIGH | LOW | P1 |
| Task-size classification thresholds | [ZAP] | MEDIUM | LOW | P1 |
| Final summary on completion | [ZAP] | HIGH | LOW | P1 |
| `displayName`, `category`, `tags` on marketplace entry | [MKT] | MEDIUM | LOW | P1 |
| `$schema` field on manifests | [MKT] | LOW | LOW | P1 |
| LICENSE file | [MKT] | MEDIUM | LOW | P1 |
| .gitignore curation | [MKT] | MEDIUM | LOW | P1 |
| Local JSON validation pre-commit | [MKT] | MEDIUM | LOW | P1 |
| CONTRIBUTING.md | [MKT] | LOW | LOW | P2 |
| Smoke-test install script | [MKT] | MEDIUM | MEDIUM | P2 |
| Configurable codex model via userConfig | [ZAP] | MEDIUM | LOW | P2 |
| Per-question Q&A timeout default | [ZAP] | LOW | LOW | P2 |
| Plan-validation cache for unchanged phases | [ZAP] | MEDIUM | MEDIUM | P2 |
| Ship JSON schema for manifests | [MKT] | LOW | MEDIUM | P2 |
| CI validation | [MKT] | LOW | MEDIUM | P3 |
| Alternative reviewer LLM | [ZAP] | LOW | HIGH | P3 |
| Debug/test/hotfix sibling plugin | [ZAP] | MEDIUM | HIGH | P3 |
| Telemetry / analytics | [BOTH] | LOW | MEDIUM | P3 |
| Web/static plugin listing page | [MKT] | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

### Marketplace polish (oplya)

| Feature | anthropics/claude-plugins-official | hyperskill/claude-code-marketplace | wshobson/agents | mrlm-xyz demo | Our Approach (oplya) |
|---------|-----------------------------------|-----------------------------------|-----------------|---------------|---------------------|
| marketplace.json schema | Full (`owner`, `plugins[]`, per-plugin `category`, `tags`, `sha`-pinned) | Standard, kebab-case names | Multi-host with custom routing | Minimal demo | Full official-style: kebab-case, `displayName`, `category=development`, `tags=["multi-agent","workflow","codex","spec-driven"]` |
| LICENSE in repo | MIT | MIT | MIT | MIT | MIT (TBD; align with team policy) |
| Per-plugin README | Yes, every plugin | Yes | Yes | Minimal | Full README with usage + codex dep callout |
| Top-level README install commands | Yes | Yes | Yes | Yes | Yes (`/plugin marketplace add github:<user>/oplya`) |
| CONTRIBUTING.md | Yes | No | Yes | No | Defer to v1.x |
| CI validation | Yes | No | No | No | Defer to v2 |
| Versioning convention documented | Implicit (SHA-pinned) | Semver in plugin.json | Semver | None | Explicit semver bump per release; documented in README |
| `$schema` field | No (uses convention) | No | No | No | **Add** — IDE ergonomics, claude-code ignores it |
| Reserved name awareness | N/A (they ARE the official one) | Checked | Checked | N/A | Verify `oplya` is not a reserved name (it isn't on the current list) |

### Multi-agent workflow plugin (zapili)

| Feature | gsd-build/get-shit-done | anthropics/ralph-loop | barkain/workflow-orchestration | hamelsmu/claude-review-loop | adamjgmiller/adamsreview | Our Approach (zapili) |
|---------|------------------------|----------------------|-------------------------------|---------------------------|--------------------------|---------------------|
| Task input | PROJECT.md + REQUIREMENTS.md | Slash-command argument | Native plan mode + decomposition | Implicit (current branch diff) | Implicit (current change) | **TASK.md** (file-based; survives restart) |
| Context capture | CONTEXT.md per phase + RESEARCH.md | None (loop is the context) | Scratchpad files | None | None | **CONTEXT.md** consolidated from researcher + user Q&A |
| Plan artifact | `XX-YY-PLAN.md` per atomic task | None | Native plan mode rendering | None | None | **PLAN.md + PHASE-XX.md** (no duplication) |
| Pre-plan research/Q&A | "Discuss phase" before planning | None | Pattern-match decomposition | None | None | **Dedicated researcher subagent with question batch + user Q&A** |
| Research validation | No | No | No | No | No | **Yes — codex-validated CONTEXT.md before planning (differentiator)** |
| Plan validation | "plan-checker" (Claude-side) | No | No | No | No | **Yes — codex-validated PLAN.md before implementation (cross-model)** |
| Wave/parallel execution | Yes, dependency-grouped | No (single loop) | Yes, native plan mode | No | No | Yes — sequential waves, parallel intra-wave phases, file-scope-disjoint |
| External reviewer LLM | No (Claude only) | No | No | **Codex (full diff review)** | Codex optional in ensemble | **Codex mandatory at three points (research val, plan val, per-phase review)** |
| Per-phase review | Verifier checks phase goals (Claude) | N/A | task-completion-verifier agent | Full PR review only | Multi-lens but PR-level | **Per-phase codex review with same-agent fix routing** |
| Severity grades | Implicit | N/A | N/A | Yes (HIGH/MED/LOW) | Yes (multi-lens severity) | **HIGH/MED/LOW, exhaustive (no top-N filtering)** |
| Same-agent fix loop | Fresh agent per re-run | Same context (loop) | Sequential agent reuse | Claude rewrites, re-submits | Auto-fix loop | **Same agent per phase preserves in-context memory** |
| State persistence | STATE.md + per-phase MD files | None (stateless loop) | `.claude/state/*.json` | None | None | **`.zapili/state.json` + all markdown artifacts; auto-resume from inspection** |
| Resume mechanism | `/gsd-resume-work` command | Restart the loop | Manual | N/A | N/A | **Automatic on `/zapili` invocation** |
| Inter-agent contract format | Markdown + JSON in places | Free-form prompt | Custom JSON return | Free-form review prose | Free-form per lens | **XML tags + embedded JSON blocks, strict and uniform** |
| Task-size policy | Atomic-plan heuristic (~50% context) | iteration cap | Adaptive | N/A | N/A | **Explicit LOC/module/question/phase thresholds (small/med/large/gigantic)** |
| Final summary | VERIFICATION.md | None | None | Review report | Report doc | **Files modified + key decisions with justifications** |
| Scope discipline | Greenfield + brownfield | Any | Any | Review-only | Review-only | **Greenfield development only (debug/test/hotfix excluded)** |

---

## Sources

- [Claude Code: Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces) — authoritative schema for `marketplace.json` (HIGH)
- [Claude Code: Plugins reference](https://code.claude.com/docs/en/plugins-reference) — `plugin.json` schema, hook events, userConfig (HIGH)
- [Claude Code: Hooks reference](https://code.claude.com/docs/en/hooks) — SessionStart, PreToolUse, dependency verification patterns (HIGH)
- [anthropics/claude-plugins-official — marketplace.json](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json) — real-world conventions: `category`, `tags`, source pinning (HIGH)
- [anthropics/claude-code — ralph-wiggum plugin](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md) — official loop-until-done pattern (HIGH)
- [Claude.com — Ralph Loop plugin page](https://claude.com/plugins/ralph-loop) — productized iteration-loop reference (MEDIUM)
- [gsd-build/get-shit-done USER-GUIDE.md](https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md) — `.planning/` artifact layout, wave coordination, resume model (HIGH)
- [GSD spec-driven dev deep dive (Codecentric)](https://www.codecentric.de/en/knowledge-hub/blog/the-anatomy-of-claude-code-workflows-turning-slash-commands-into-an-ai-development-system) — workflow phases, atomicity heuristics (MEDIUM)
- [barkain/claude-code-workflow-orchestration](https://github.com/barkain/claude-code-workflow-orchestration) — task decomposition, wave scheduling, dual execution modes (HIGH)
- [hamelsmu/claude-review-loop](https://github.com/hamelsmu/claude-review-loop) — automated codex review loop, severity grading, active-revision pattern (HIGH)
- [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) — official Codex-in-Claude-Code integration (HIGH)
- [adamjgmiller/adamsreview](https://github.com/adamjgmiller/adamsreview) — multi-lens review pipeline, ensemble pattern (MEDIUM)
- [smartscope: Automating the Claude Code × Codex Review Loop](https://smartscope.blog/en/blog/claude-code-codex-review-loop-automation-2026/) — three-level review-loop automation analysis (MEDIUM)
- [Anthropic: Prompting best practices — XML tags](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags) — canonical XML-tag prompt structure (HIGH)
- [hesreallyhim/claude-code-json-schema](https://github.com/hesreallyhim/claude-code-json-schema) — community JSON Schemas for manifests (MEDIUM)
- [Claude Code marketplace deep dive (ice-ice-bear)](https://ice-ice-bear.github.io/posts/2026-04-03-claude-code-plugin-marketplace/) — practical examples and conventions (MEDIUM)
- [Claude Code Plugin Marketplace categorization analysis (knightli.com)](https://knightli.com/en/2026/05/23/claude-plugins-official-claude-code-plugin-directory/) — discovery UX limitations, trust signals (MEDIUM)
- [mrlm-xyz/demo-claude-marketplace](https://github.com/mrlm-xyz/demo-claude-marketplace) — minimal marketplace template reference (MEDIUM)
- [hyperskill/claude-code-marketplace](https://github.com/hyperskill/claude-code-marketplace) — team-shared marketplace example (MEDIUM)

---
*Feature research for: Claude Code plugin marketplace + multi-agent development-workflow plugin*
*Researched: 2026-05-27*
