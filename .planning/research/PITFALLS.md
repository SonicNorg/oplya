# Pitfalls Research

**Domain:** Claude Code plugin marketplace + multi-agent development workflow plugin (`oplya` / `zapili`)
**Researched:** 2026-05-27
**Confidence:** HIGH for plugin spec / hook mechanics / codex CLI behavior (verified against official docs and GitHub issues); MEDIUM for multi-agent orchestration patterns (community wisdom + recent blogs, not formal spec)

> This file enumerates **only** failure modes specific to this domain — Claude Code plugin packaging, the codex CLI as an independent reviewer, and stateful multi-agent workflows driven from on-disk artifacts. Generic engineering pitfalls (don't hardcode secrets, write tests, etc.) are intentionally out of scope.

---

## Critical Pitfalls

### Pitfall 1: `marketplace.json` placed at repo root instead of `.claude-plugin/marketplace.json`

**Severity:** Catastrophic

**What goes wrong:**
`/plugin marketplace add <repo>` fails outright. Users see "marketplace not found" or "invalid marketplace" with no actionable diagnostic. The marketplace is unusable.

**Why it happens:**
The natural instinct is to put a top-level manifest at the repository root (like `package.json` or `Cargo.toml`). The Claude Code spec is unusual in that it requires the marketplace manifest at `.claude-plugin/marketplace.json` — a hidden directory most editors hide by default.

**How to avoid:**
- Mandate **two** distinct concepts in the layout doc: the marketplace's own `.claude-plugin/marketplace.json` lives at repo root, and **each plugin** has its own `.claude-plugin/plugin.json` inside its plugin directory.
- Add a local `scripts/validate-manifests.sh` (or a pre-commit hook) that asserts both files exist and parse as JSON before allowing a push.
- Pin the exact paths in the README's "Repository layout" section so contributors copy-paste correctly.

**Warning signs:**
- `find .claude-plugin -name marketplace.json` returns nothing at repo root.
- A fresh clone followed by `/plugin marketplace add .` fails to recognize the repo.

**Phase to address:**
Phase 1 — Marketplace scaffolding (MKT-01).

---

### Pitfall 2: Missing or malformed `owner` / `plugins` in `marketplace.json` (silent install failure)

**Severity:** Catastrophic

**What goes wrong:**
`marketplace.json` parses as valid JSON but Claude Code rejects it because required fields (`name`, `owner`, `plugins`) are missing or `plugins[].source` is omitted/wrong. Users see a generic error; the maintainer assumes the marketplace works because the JSON "looks fine."

**Why it happens:**
The schema is documented but not validated by `git push` — there is no central registry enforcing it. The required fields are not all obvious (e.g., `owner` is required, `metadata.pluginRoot` is a footgun if mis-set).

**How to avoid:**
- Adopt the unofficial JSON Schema (`hesreallyhim/claude-code-json-schema`) and run it locally in pre-commit (`ajv validate -s schema.json -d .claude-plugin/marketplace.json`).
- If using `metadata.pluginRoot: "plugins"`, then plugin entries must use `"source": "zapili"` (not `"./plugins/zapili"`). Pick **one** convention and document it.
- Reference the official `anthropics/claude-plugins-official` repo's `marketplace.json` as a known-good template — it is canonical.

**Warning signs:**
- The JSON Schema validator reports missing required keys.
- `/plugin install zapili@oplya` errors with "plugin not found" despite the marketplace loading.

**Phase to address:**
Phase 1 — Marketplace scaffolding (MKT-01, MKT-06).

---

### Pitfall 3: Hook scripts ship without executable bit (or with CRLF shebangs)

**Severity:** Catastrophic

**What goes wrong:**
The `codex`-presence hook never runs. Either `bash: ./hooks/check-codex.sh: Permission denied` or `bash: /usr/bin/env\r: No such file or directory`. The plugin loads, the workflow starts, and only crashes deep inside the validation phase when `codex exec` is invoked on a machine without it — exactly the failure the hook was supposed to prevent.

**Why it happens:**
1. Git can lose the executable bit if the file was created on Windows or via a web UI.
2. `core.autocrlf=true` (Windows default) rewrites LF to CRLF on checkout. Bash reads `#!/usr/bin/env bash\r` and looks for an interpreter literally named `bash\r`.

**How to avoid:**
- Add `*.sh text eol=lf` to a `.gitattributes` file at repo root. Non-negotiable for any plugin shipping shell hooks.
- Set `chmod +x` on every hook script before commit; verify with `git ls-files --stage hooks/` showing mode `100755`.
- Local validation script: `for f in plugins/*/hooks/*.sh; do test -x "$f" || die "not executable: $f"; head -c2 "$f" | grep -q '#!' || die "missing shebang: $f"; done`.

**Warning signs:**
- `git ls-files --stage plugins/zapili/hooks/` shows `100644` instead of `100755` for any `.sh` file.
- "bad interpreter" or "no such file or directory" errors at hook invocation.

**Phase to address:**
Phase 2 — `zapili` plugin packaging (ZAP-02).

---

### Pitfall 4: Hook uses relative paths assuming CWD = plugin dir

**Severity:** Serious

**What goes wrong:**
The hook calls `./scripts/check.sh` or sources `./lib/util.sh`, but Claude Code executes hooks with CWD set to the **user's project root**, not the plugin directory. The hook errors with "no such file" the first time a user runs it from any project except the plugin's own dev checkout.

**Why it happens:**
The plugin works flawlessly during local development (where CWD often is the plugin dir) and fails the moment it is installed and run elsewhere.

**How to avoid:**
- Always resolve script-internal paths via `${CLAUDE_PLUGIN_ROOT}` (substituted by Claude Code into hook command strings) — never via `$PWD`, never via relative `./`.
- In Bash hooks that need their own dir, use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` rather than relying on CWD.
- Test the plugin **from a separate scratch project**, not from inside its own repo, before publishing any version bump.

**Warning signs:**
- The hook command in `hooks.json` contains a bare `./` or `../` path.
- The plugin works during dev but breaks in CI or on a teammate's machine.

**Phase to address:**
Phase 2 — `zapili` plugin packaging (ZAP-02).

---

### Pitfall 5: SessionStart hook hard-fails Claude Code when `codex` is missing

**Severity:** Catastrophic (UX-wise) / Serious (technical)

**What goes wrong:**
The hook exits with code 2 to "block" startup when `codex` is absent. Claude Code refuses to start the session at all — not just `zapili`, but the entire editor experience. The user can't even run `/plugin uninstall` to remove the offending plugin without manually editing config files. The plugin has effectively bricked Claude Code for that user.

**Why it happens:**
Reasonable but wrong inference: "SessionStart should fail when the prerequisite is missing." But SessionStart hook semantics are advisory for the session, not gate-keeping for the editor. Exit code 2 in a PreToolUse blocks a tool; in SessionStart it's a session-level abort with no clean recovery path for the user.

**How to avoid:**
- Do **not** gate session startup. Instead, gate the `/zapili` slash command itself: the command's first action is a `command -v codex >/dev/null || { echo "<install instructions>"; exit 1; }` check.
- If a SessionStart hook is used, it must exit `0` and write a warning to stdout (which Claude Code surfaces as context) rather than failing.
- Document the failure mode in the plugin README: "If you uninstall codex while zapili is installed, the slash command will refuse to run with a clear message; Claude Code itself is unaffected."

**Warning signs:**
- Any hook in `hooks.json` exits non-zero outside of intentional PreToolUse blocking.
- Test: uninstall codex, then start Claude Code — does the editor work? Can the user still run `/plugin uninstall zapili`?

**Phase to address:**
Phase 2 — `zapili` plugin packaging (ZAP-02). Add as an explicit acceptance criterion: "Removing codex must not prevent Claude Code startup."

---

### Pitfall 6: Parallel implementation agents step on the same files (wave-safety lie)

**Severity:** Catastrophic

**What goes wrong:**
The planner declares two phases as "parallel-safe in wave 2," but their file scopes actually overlap — both touch `src/foo/bar.ts`. Two subagents edit the file concurrently; the last write wins. The losing agent's diff is silently discarded. The review phase passes (each agent's reported changes look reasonable in isolation), and the bug only surfaces at runtime in an unrelated phase.

**Why it happens:**
- The planner reasons about phases at a logical level ("add validation", "add caching") and misses that both phases touch the same controller.
- Subagents are isolated — there is no inter-agent lock; "last write wins" is the unavoidable semantic in plain filesystem edits without worktrees.
- The contract for phase plans does not force the planner to declare file scopes explicitly, so overlaps aren't detectable mechanically.

**How to avoid:**
- Make **file scope a required, machine-readable field** in every `PHASE-XX.md`. Embed a JSON block like `<files>{"writes": ["src/foo.ts"], "reads": ["src/bar.ts"]}</files>`.
- The orchestrator computes the intersection of `writes` sets across phases in a wave **before spawning** any subagent. Any overlap aborts the wave with a "planner contract violation" message and triggers a plan-validation re-run.
- The plan validator (codex) is instructed to explicitly verify wave safety: "For each wave, enumerate the write-scopes of its phases and confirm they are pairwise disjoint."

**Warning signs:**
- Two phases in the same wave list overlapping files in their `<files>` blocks.
- A reviewed change appears in the agent's output but is missing from `git diff` after the wave closes.
- Mysterious test failures right after a wave completes.

**Phase to address:**
Phase 3 — Planner agent design (ZAP-06); Phase 4 — Orchestrator/wave dispatch (ZAP-08, ZAP-11). The mechanical disjointness check must be enforced by the orchestrator code, not trusted to LLM judgement.

---

### Pitfall 7: Validation loops never terminate — codex re-classifies LOW as MEDIUM on the next pass

**Severity:** Catastrophic (loops forever; burns the user's session)

**What goes wrong:**
Iteration N's review reports 3 HIGH, 5 MEDIUM, 12 LOW issues. After fixes, iteration N+1 reports 1 HIGH (a previously LOW), 6 MEDIUM (some new, some recategorized), and 8 LOW. The loop exit condition ("no HIGH/MEDIUM remaining") is never met because codex is non-deterministic in classification.

**Why it happens:**
LLM-based reviewers are non-deterministic across runs. Severity is a fuzzy judgement, not a property of the issue. Without anchoring, every run feels like a fresh review.

**How to avoid:**
- Pass the **prior review's full issue list** into the next codex invocation with explicit instructions: "Issues marked RESOLVED in the previous run must not reappear. If you believe a previously-LOW issue is now HIGH, justify the change explicitly in a `<reclassification>` block." This anchors the model.
- Cap the loop. Hard limit of e.g. 3 validation iterations per phase; on the 4th attempt, present the residual issues to the user for manual judgement and exit the loop.
- Track issues by stable identifier (hash of `{file, line-range, kind}`) so "the same issue" can be detected across runs even if the wording shifts.
- Decision: a previously-resolved issue reappearing is a planner/implementation regression, not a re-review — surface it as such, don't loop silently.

**Warning signs:**
- Iteration count climbs past 2 without HIGH count strictly decreasing.
- The same line of code is flagged with different severities across iterations.

**Phase to address:**
Phase 3 — Validation loop design (ZAP-05, ZAP-07, ZAP-10, ZAP-16). Iteration cap and prior-issue anchoring are mandatory acceptance criteria.

---

### Pitfall 8: Codex review prompts produce top-N findings despite "all issues" instruction

**Severity:** Serious (drives loop count up)

**What goes wrong:**
The prompt says "report ALL HIGH/MEDIUM/LOW issues, no summarization." Codex returns 6 issues. After fixes, iteration 2 surfaces 4 *new* MEDIUM issues that were clearly present in iteration 1's code but not reported. Codex was self-prioritizing despite the instruction.

**Why it happens:**
LLMs default to producing readable, pareto-filtered output. "Exhaustive" is interpreted as "comprehensive on the most important" rather than literally "every instance." Output length limits also discourage long lists.

**How to avoid:**
- **Force enumeration of categories before reporting.** Prompt structure: "Step 1: list every category of issue you will look for (security, contract drift, dead code, naming, error handling, …). Step 2: for each category, report every instance found at any severity, or explicitly write 'no findings'." This breaks the pareto reflex.
- **Demand a coverage statement.** Require a trailing `<coverage>{"files_reviewed": [...], "categories_checked": [...]}</coverage>` block. Empty categories must be listed.
- **Forbid summarization vocabulary in the response** — instruct codex not to use phrases like "most important", "key issues", "top concerns", "in summary".
- **Sample-grade prompts before shipping.** Run the prompt against 3–5 deliberately-flawed reference plans/diffs and confirm codex finds the seeded issues. Refine the prompt until coverage is reliable.

**Warning signs:**
- Iteration 2 surfaces MEDIUM issues that existed unchanged in iteration 1.
- The response contains "key", "main", "important", or "top" near issue lists.
- The coverage block is missing or empty.

**Phase to address:**
Phase 3 — Codex prompt design (ZAP-16). Calibrate on a reference corpus before launch.

---

### Pitfall 9: Inter-agent contract drift — agent invents fields the orchestrator doesn't parse

**Severity:** Serious

**What goes wrong:**
The contract says the implementation agent returns `<files>[{"path": "...", "summary": "..."}]</files>`. The agent invents `<files>[{"path": "...", "summary": "...", "confidence": "high", "alternatives_considered": [...]}]</files>`. The orchestrator's strict parser either crashes or silently drops the extra fields, and the new "confidence" data is lost downstream. Worse: sometimes the agent omits required fields ("the summary was self-evident from the path").

**Why it happens:**
LLMs improvise structure. Without a hard schema and a self-check, agents drift toward what feels natural in context.

**How to avoid:**
- Specify a strict JSON schema in every contract prompt — list every field, mark required vs. forbidden, and explicitly say "no additional properties."
- Include a worked example in the prompt showing exactly the shape expected.
- Parse with a schema-validating library (e.g., `ajv`); on validation failure, return a structured error to the agent with the validator's diff and let it retry **once** before failing the phase.
- Wrap JSON in dedicated XML tags (e.g., `<file_changes>{...}</file_changes>`) so the parser does not have to find JSON in free-form Markdown.
- Forbid Markdown code fences inside the JSON block — fences are for humans, the orchestrator parses the raw tag content.

**Warning signs:**
- JSON parse errors logged at orchestrator boundary.
- Downstream code references fields that occasionally are `undefined`.
- Agent responses contain helpful prose outside the contract tags ("I also noticed…").

**Phase to address:**
Phase 3 — Contract design (ZAP-14); Phase 4 — Orchestrator parsing layer.

---

### Pitfall 10: State file race between orchestrator and subagent

**Severity:** Serious

**What goes wrong:**
The orchestrator writes `.zapili/state.json` to mark wave 2 as started. A subagent in wave 2 also writes to it (e.g., to checkpoint its own progress). Both processes do read-modify-write without coordination; one of the updates is lost. After resume, the workflow thinks it's mid-wave 1.

**Why it happens:**
JSON files are convenient and human-readable but provide no atomicity. The instinct to share one state file across all actors creates a multi-writer scenario.

**How to avoid:**
- **Single writer rule:** only the orchestrator writes `.zapili/state.json`. Subagents return their status in the contract response; the orchestrator merges and writes.
- For the orchestrator's own writes, use **write-temp-then-rename** (`write .zapili/state.json.tmp; fsync; mv -f .zapili/state.json.tmp .zapili/state.json`) — atomic on POSIX within the same filesystem.
- Optionally split: orchestrator owns `state.json`; each subagent gets its own `.zapili/agents/<phase-id>.json` that only that agent writes. Orchestrator reads them after the agent returns. No shared mutable file.
- Reject the temptation to use a lockfile (`flock`) — adds complexity for no win when the single-writer rule is enforceable by design.

**Warning signs:**
- `.zapili/state.json` ever appears in `git status` truncated or invalid mid-run.
- Resume picks up at the wrong phase.

**Phase to address:**
Phase 4 — Orchestrator state model (ZAP-13).

---

### Pitfall 11: Resume semantics rely on `state.json` alone — disagrees with on-disk artifacts

**Severity:** Serious

**What goes wrong:**
A crash mid-wave leaves `state.json` saying "wave 2, phase 2-B, iteration 1 in progress." But `PHASE-02-B.md` was not yet written when the crash hit. On resume, the orchestrator believes phase 2-B was in progress and tries to invoke its reviewer with no plan to review. Or the inverse: `PLAN.md` exists but `state.json` is missing — the resume logic restarts from scratch, overwriting prior work.

**Why it happens:**
Two sources of truth (state file + artifacts on disk) disagree after any non-graceful exit. The "what stage am I at" question has two answers.

**How to avoid:**
- **Artifacts are the source of truth.** `state.json` is a *cache* of derived facts. On resume, the orchestrator first re-derives the workflow stage from artifact presence:
  - `TASK.md` exists but no `CONTEXT.md` → research phase.
  - `CONTEXT.md` exists but no `PLAN.md` → planning phase.
  - `PLAN.md` exists, last wave-N `phase-XX.md` files present, no review markers → implementation phase, wave N.
  - etc.
- If `state.json` and the derived stage disagree, **trust the artifacts**, log the discrepancy, and rewrite `state.json` to match.
- Use small **completion sentinels** within artifacts (e.g., a trailing `<status>complete</status>` tag) rather than relying on file existence alone, so a half-written artifact is not mistaken for a complete one.
- Write every artifact via temp-then-rename; never partially-visible files.

**Warning signs:**
- Resume after a crash re-runs an already-completed phase, or skips a phase that wasn't done.
- `state.json` and artifact mtimes contradict each other.

**Phase to address:**
Phase 4 — Resume logic (ZAP-13).

---

### Pitfall 12: "Same agent fixes its own review" — agent identity lost across spawns

**Severity:** Serious

**What goes wrong:**
The design says "send review findings back to the same implementation agent to preserve context." But Claude Code subagents are **fresh contexts on every spawn** — there is no persistent agent process. The "same agent" doesn't exist; on the fix-loop iteration, a brand-new subagent is spawned with no memory of the prior implementation. It re-derives everything from artifacts, often making different decisions than the original agent.

**Why it happens:**
The mental model from human teams ("send it back to the developer who wrote it") doesn't translate to stateless subagent spawns. The "agent" is a role, not a process.

**How to avoid:**
- Drop the "same agent" framing. There is no such thing.
- Instead, **preserve the agent's prior context as an artifact**: when an implementation agent returns, persist its full reasoning trace (`<decisions>`, `<files_touched>`, `<key_choices>`) into the `PHASE-XX.md` or a sibling `PHASE-XX-attempt-N.md`.
- On the fix iteration, spawn a fresh agent and pass it (a) the original phase plan, (b) the prior attempt's reasoning artifact, (c) the review findings to address. The new agent gets enough context to behave continuously even though it is a new process.
- Document this clearly in the workflow design: "Agents are roles; continuity is achieved by artifact persistence, not by process identity."

**Warning signs:**
- Fix iterations rewrite code in styles inconsistent with the original (because each iteration is effectively a different developer).
- Decisions made in iteration 1 are silently reversed in iteration 2.

**Phase to address:**
Phase 3 — Workflow design (ZAP-08, ZAP-10). This needs to be reflected in the contract spec from day one.

---

### Pitfall 13: Researcher produces too many questions; user abandons mid-answer

**Severity:** Serious (UX failure)

**What goes wrong:**
For a small task, the researcher asks 12 questions because the prompt didn't bound it tightly. The user gives short answers to the first three, then loses patience and writes "you decide" for the rest. The "decided by you" answers degrade the rest of the workflow silently.

**Why it happens:**
LLMs default to thoroughness. Without explicit numeric ceilings tied to task size, "research thoroughly" produces a comprehensive but exhausting interview.

**How to avoid:**
- The size-class policy (ZAP-15) must be enforced **in the researcher's contract**, not just documented. The researcher must:
  1. First emit a `<size_classification>` block with justification.
  2. Then emit no more than the size-class-permitted number of questions.
- The orchestrator validates the question count against the size class before presenting to the user; if exceeded, the researcher's response is rejected and re-requested with the count constraint repeated.
- Encourage *batched* questions — one prompt with N numbered sub-questions presented as a single user-facing message — rather than N rounds of back-and-forth.

**Warning signs:**
- Question count exceeds the size-class cap.
- The user's answers degrade in quality through the batch ("idk", "you pick").

**Phase to address:**
Phase 3 — Researcher prompt + size policy (ZAP-03, ZAP-15).

---

### Pitfall 14: Planner over-fragments tasks into uselessly small phases

**Severity:** Serious

**What goes wrong:**
A medium task gets split into 9 phases (e.g., "Phase 1: add interface", "Phase 2: add stub implementation", "Phase 3: add real implementation"). Each phase has 10 LOC of effect. Wave dispatch overhead dominates real work; the workflow takes 4x longer than it should and burns tokens producing per-phase reviews of near-empty changes.

**Why it happens:**
LLMs over-decompose when given a "produce phases" instruction without cardinality bounds. Each step looks like a discrete unit of thought; the model produces a discrete phase per unit.

**How to avoid:**
- The size policy (ZAP-15) caps phase counts. Enforce mechanically: planner's response is rejected if phase count exceeds the cap for the declared size.
- In the planner prompt, give explicit guidance on phase granularity: "A phase must represent at least N hours of focused work / a meaningful slice of behavior / a coherent commit." Show one good and one bad example.
- Plan-validation pass instructs codex to flag over-fragmentation as a HIGH issue: "Are any phases trivially small or splittable-without-benefit? If so, propose merging."

**Warning signs:**
- A medium task produces > 4 phases.
- Average phase produces < 30 LOC of real change.

**Phase to address:**
Phase 3 — Planner prompt + plan validator (ZAP-06, ZAP-07, ZAP-15).

---

### Pitfall 15: Codex non-interactive mode fails on machines that authed via ChatGPT (not API key)

**Severity:** Serious

**What goes wrong:**
The user installed codex, logged in via "Sign in with ChatGPT" in interactive mode, and the workflow works locally. They share their setup with a teammate who runs in a headless / CI / SSH-without-TTY context. The `codex exec` invocation hangs or fails because the OAuth session can't refresh non-interactively in that environment.

**Why it happens:**
ChatGPT OAuth login requires a browser. In automated/headless contexts, it can't complete. The teammate's `codex login status` shows authenticated locally, but the underlying session token can fail to refresh. (See `openai/codex#9253`, `#17041`.)

**How to avoid:**
- The `zapili` README must distinguish two install paths:
  1. **Interactive workstation:** `codex login` (ChatGPT) is fine.
  2. **Headless / CI / shared dev box:** require `OPENAI_API_KEY` env var; document that ChatGPT login is unsupported.
- The pre-flight check (in the `/zapili` command, not the hook) verifies more than presence: run `codex exec --help` quickly; if it hangs or exits non-zero, surface a clear "codex is installed but not authenticated for non-interactive use — set `OPENAI_API_KEY` or run `codex login` and confirm `codex login status` works." Avoid runtime hangs by enforcing a timeout (e.g., 5s) on the pre-flight.
- Capture `codex exec` invocations behind a wrapper that enforces a timeout and fails loudly on auth-shaped errors (look for known marker strings in stderr).

**Warning signs:**
- `codex exec` hangs without output.
- Auth errors in stderr that the workflow swallows.

**Phase to address:**
Phase 2 — codex pre-flight (ZAP-02). Phase 3 — codex invocation wrapper (ZAP-05, ZAP-07, ZAP-09).

---

### Pitfall 16: Mixing codex stderr (progress noise) with stdout (final answer)

**Severity:** Serious

**What goes wrong:**
The orchestrator captures `codex exec ... 2>&1` and tries to parse the combined stream as JSON. Codex streams progress to **stderr** and the final agent message to **stdout** (this is by design). The combined output is unparseable; the orchestrator falls back to regex hacks; brittle.

**Why it happens:**
Bash defaults make `2>&1` the easy way to "see everything." It's the wrong default for parseable output.

**How to avoid:**
- Always invoke `codex exec` with **separated streams**: `codex exec ... > stdout.txt 2> stderr.txt`.
- Parse only stdout for the contract response.
- Log stderr to a debug file (`.zapili/logs/codex-<phase>-<iter>.log`) — useful for debugging without polluting the parser.
- If invoking via a wrapper script, that wrapper must preserve the separation; never collapse via pipes that merge.

**Warning signs:**
- JSON parse failures with "Codex CLI starting…" style preambles inside the JSON region.
- The orchestrator uses regex to strip leading lines before parsing — sign that streams were merged.

**Phase to address:**
Phase 3 — codex invocation wrapper.

---

### Pitfall 17: Codex non-determinism breaks the contract response shape

**Severity:** Serious

**What goes wrong:**
On one run codex returns the issue list wrapped in `<issues>[…]</issues>`. On the next run, codex wraps it in a Markdown code fence: ```` ```json\n[…]\n``` ````. The strict orchestrator parser fails. The workflow halts on what is essentially a stylistic variance.

**Why it happens:**
LLMs vary output shape across runs even with low temperature. The contract spec is "soft" enforcement — the model interprets it.

**How to avoid:**
- Make the contract prompt **end** with a literal template fragment: "Your response MUST end with this exact block, with no trailing text, no Markdown fences, no commentary: `<issues>[...]</issues>`."
- The orchestrator's parser tolerates **trivial cosmetic variance**: strips an outer ` ```json … ``` ` fence if present, trims whitespace, but otherwise insists on the XML envelope. One layer of forgiveness is enough; deeper forgiveness invites contract erosion.
- On parse failure, retry the codex call **once** with the prior response included and the instruction: "Your previous response was malformed (see below). Re-emit only the required `<…>` block."

**Warning signs:**
- The orchestrator's parser has more than two fallback layers — it's compensating for prompt weakness.
- Parse failures cluster on specific codex versions.

**Phase to address:**
Phase 3 — Contract design + parser strictness (ZAP-14).

---

### Pitfall 18: Subagent context bloat — orchestrator forwards everything "just in case"

**Severity:** Serious (token cost + slower responses)

**What goes wrong:**
Each implementation subagent receives `TASK.md` + `CONTEXT.md` + `PLAN.md` + **every** `PHASE-XX.md` + the full repo tree + the prior wave's outputs. Even small phases burn 30k+ tokens of prompt before any real thinking begins. Latency spikes, costs balloon, and the agent's attention is diluted across irrelevant context.

**Why it happens:**
Orchestrators err on the side of giving subagents more info because "the agent will know what to ignore." LLMs do not effectively ignore — every token in the prompt influences output.

**How to avoid:**
- The orchestrator passes each implementation subagent **only**: `TASK.md`, the agent's own `PHASE-XX.md`, a curated `<context_excerpt>` derived from `CONTEXT.md` (only sections referenced by this phase), and the agent's prior attempt + review findings on retry iterations.
- The planner is responsible for declaring which sections of `CONTEXT.md` each phase needs; this declaration is part of `PHASE-XX.md`.
- Set a soft prompt-size budget per phase (e.g., 10k tokens). On exceed, surface as a planner contract violation — the phase's scope is too broad and should be re-planned.

**Warning signs:**
- Average phase-spawn prompt size > 10k tokens.
- Subagent first-token latency > 5 seconds.
- Subagents mention details from sibling phases that they shouldn't know about.

**Phase to address:**
Phase 3 — Planner output spec (ZAP-06); Phase 4 — Orchestrator context-curation logic.

---

### Pitfall 19: Plugin mutates global Claude Code config

**Severity:** Catastrophic (for the user)

**What goes wrong:**
A hook script "helpfully" writes to `~/.claude/config.json` or `~/.claude/settings.json` to set a preference. Uninstalling the plugin leaves the mutation behind. Worse: two plugins write conflicting settings and silently clobber each other.

**Why it happens:**
Plugin authors think of the plugin as part of the user's environment and feel free to mutate it.

**How to avoid:**
- Hard rule: `zapili` writes **only** under `${CLAUDE_PLUGIN_ROOT}` (read-only at runtime) and the user's project directory (under `.zapili/` and the standard artifacts `TASK.md`, `CONTEXT.md`, `PLAN.md`, `PHASE-XX.md`).
- Never write to `$HOME/.claude/*`. Never set global git config. Never touch `$HOME/.config/codex/*`.
- Document this constraint in CONTRIBUTING for the marketplace as a cross-cutting rule for all plugins.

**Warning signs:**
- Any hook or script reads/writes a path under `$HOME` that isn't the user's project.

**Phase to address:**
Phase 2 — `zapili` packaging (cross-cutting acceptance criterion).

---

### Pitfall 20: Semver bumps forgotten; users get cached old plugin

**Severity:** Serious

**What goes wrong:**
Maintainer edits `commands/zapili.md` and `agents/researcher.md`, commits without bumping `plugin.json`'s version. Users who reinstall see no change because Claude Code caches by version. The maintainer thinks the fix shipped; user reports it as broken.

**Why it happens:**
Light publication process (MKT-06) leaves semver bumps manual. Easy to forget when the change feels small.

**How to avoid:**
- Pre-commit hook that warns when any file under `plugins/<name>/` changes without `plugins/<name>/.claude-plugin/plugin.json`'s `version` field changing.
- Document the convention: bump **patch** for prompt tweaks and bug fixes, **minor** for new commands/agents, **major** for breaking contract changes.
- A short `CHANGELOG.md` per plugin to force the maintainer to articulate what changed.

**Warning signs:**
- A user reports stale behavior right after a release.
- `git log plugins/zapili/.claude-plugin/plugin.json` is sparser than `git log plugins/zapili/`.

**Phase to address:**
Phase 1 — Marketplace publication process (MKT-06).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skipping the JSON-schema validation in pre-commit | Faster commits during early dev | Broken `marketplace.json` ships and the entire marketplace stops loading for all users | Never — JSON schema validation is the single cheapest insurance against catastrophic failure |
| Storing inter-agent payloads as free-form Markdown | Easy for the maintainer to read | Orchestrator needs regex hacks; contract drift goes undetected | Never for machine-parsed content. Free-form is fine only for fields the orchestrator displays to the user verbatim |
| Trusting the planner's "parallel-safe" claim without orchestrator-side file-scope check | Faster to ship the planner | Silent corruption in production workflows | Never. Mechanical disjointness check is the only safe gate |
| Not separating codex stdout/stderr (using `2>&1`) | One less flag to remember | Parsing every codex response is brittle; every codex version bump risks breakage | Never |
| Using a single shared `state.json` written by both orchestrator and subagents | Simpler conceptually | Race conditions corrupt workflow state | Never. Single-writer pattern is required |
| Hardcoded paths inside hook scripts (no `${CLAUDE_PLUGIN_ROOT}`) | Works during local dev | Breaks for every external user | Never |
| No iteration cap on validation loops | Loops "complete naturally" most of the time | One pathological codex run burns the user's entire session | Never. Cap is a hard requirement |
| Letting the researcher ask unlimited questions for "thoroughness" | Feels rigorous | Users abandon mid-interview; subsequent phases run on degraded inputs | Never. Size-class cardinality is mandatory |
| Bash-only hook scripts (no `.cmd` shim, no platform check) | Half the work | Windows users get cryptic failures | Acceptable for v1 if README explicitly states "Linux/macOS only"; document and ship a Windows shim in v2 |
| Manual semver bumping with no enforcement | Lightweight process | Stale-cache reports from users | Acceptable for v1 with a pre-commit warning; tighten if release cadence increases |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `codex exec` invocation | Capturing combined stdout+stderr | Always separate (`> out 2> err`); parse stdout only |
| `codex` authentication | Assuming `codex login` works headless | Detect non-interactive env (no TTY); require `OPENAI_API_KEY`; surface explicit error |
| `codex` non-determinism | Strict parsing of every variance | Strict envelope (XML tags) + one layer of cosmetic forgiveness (strip Markdown fences); retry-once on failure |
| Claude Code hook events | Using PreToolUse to gate codex availability | Wrong layer. Gate inside the `/zapili` command's first action; SessionStart is too coarse |
| Claude Code subagent spawn (Task tool) | Forwarding the whole world "for context" | Curate ruthlessly: TASK.md + the phase's PHASE-XX.md + selected CONTEXT.md sections only |
| Subagent return contracts | Free-form Markdown with JSON inside fences | XML envelope tags containing raw JSON; parser anchored on tags, not Markdown structure |
| `.claude-plugin/marketplace.json` source field | Inconsistent with `metadata.pluginRoot` setting | Pick one: either omit pluginRoot and use full paths, or set pluginRoot and use short names. Document and lint |
| `git push` of plugin updates | Forgetting to bump `version` in `plugin.json` | Pre-commit hook flags missing version bump when files change |
| `chmod +x` on hook scripts | Setting executable bit on Linux; Windows checkout loses it | `.gitattributes` plus pre-commit verification of `git ls-files --stage` mode |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded validation loops | Workflow runs for tens of minutes; no progress visible | Hard iteration cap (≤ 3) + escalation to user on cap reached | First pathological task (could be task #1) |
| Subagent prompt bloat | Slow time-to-first-token; high token cost per run | Per-phase context curation; soft prompt budget enforced at orchestrator | Medium tasks onward |
| Codex called sequentially per phase in a wave | Long wall-clock latency for review step | Spawn codex reviews in parallel (one per phase); merge results | Waves with ≥ 3 phases |
| Researcher reads entire codebase | Token cost; slow first phase | Researcher reads only files explicitly referenced in `TASK.md`; expansion requires user permission | Any repo >100 files |
| Diff size for review exceeds codex context | Review fails or summarizes pathologically | Constrain phase scope so any single phase's diff fits in codex's window; planner contract enforces | Large/gigantic tasks |
| All artifacts read on every resume | Slow startup of resumed sessions | Resume reads only the tail (`state.json` + latest wave's artifacts) | After many waves accumulate |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Hook script `eval`s content from `TASK.md` or `CONTEXT.md` | Arbitrary code execution from a malicious task description | Hooks never `eval`. Treat user-provided files as untrusted strings; quote rigorously in shell |
| Plugin invokes `codex` with `--yolo`/auto-approve and lets it modify files | Codex can modify the user's repo in unreviewed ways | Always use `codex exec` in **read-only** review mode; codex's output is *advice*, never direct edits |
| Logging `codex` stderr to a file that ends up in `git` | Leaks codex auth tokens / OpenAI org IDs if they appear in stderr | `.zapili/` is in `.gitignore` by default; verify in MKT-02 |
| Storing `OPENAI_API_KEY` in plugin config | Key checked into the marketplace repo | Plugin reads from env only; documented in README; pre-commit hook scans for `sk-` patterns in committed files |
| Hooks accept shell-injectable values from tool_input without quoting | Command injection via crafted tool arguments | All shell variables in hook scripts double-quoted; prefer Python/jq for parsing JSON |
| Plugin marketplace clones run on `/plugin marketplace add` execute hooks immediately | A malicious marketplace can run arbitrary code on `marketplace add` | Out of `oplya`'s control, but: review every contributor PR carefully; never accept hook changes from external contributors without read-through |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Researcher asks 12 questions for a 100-LOC task | User loses patience, gives degraded answers | Size-class caps enforced; questions batched in one message |
| Validation loop runs silently for 5 minutes | User can't tell if it crashed or is working | Per-iteration progress line: "Validation iteration 2/3: 1 HIGH, 3 MEDIUM remaining" |
| Workflow finishes with no summary | User unsure what was changed | ZAP-12 — final notification with file list and key decisions |
| Workflow fails mid-wave with cryptic error | User can't decide whether to resume or restart | All terminal errors include: which phase, which iteration, recovery suggestion (`/zapili resume` vs `/zapili reset`) |
| Resume picks up the wrong phase after a crash | User sees duplicated/missing work | Artifact-derived stage truth (see Pitfall 11) |
| All prompts in English when user wrote `TASK.md` in another language | User confused why responses are English | Documented up-front: contracts are English; user-facing messages may be in user's language |
| `TASK.md` requirements aren't echoed back during research | User unsure if the researcher read it correctly | Researcher's first output includes a `<task_understanding>` block summarizing what it parsed |
| No way to abort cleanly | User kills Claude Code session and finds half-written artifacts | Every artifact written via temp-then-rename so aborted writes don't leave half-files |

---

## "Looks Done But Isn't" Checklist

- [ ] **Marketplace structure:** `marketplace.json` at `.claude-plugin/`, not at repo root — verify `find . -path ./node_modules -prune -o -name marketplace.json -print` shows exactly the expected path.
- [ ] **Plugin manifest:** every plugin has its own `.claude-plugin/plugin.json` with `name` and `version` — verify by listing all `plugin.json` files and parsing each.
- [ ] **Hook scripts:** every `.sh` is executable in git — verify with `git ls-files --stage 'plugins/*/hooks/*.sh' | awk '$1 != "100755" {print "NOT EXEC: "$4; exit 1}'`.
- [ ] **Line endings:** `.gitattributes` enforces LF for `*.sh` — verify file exists and contains the rule; clone on Windows and confirm `od -c hook.sh | head` shows no `\r`.
- [ ] **codex pre-flight:** `/zapili` exits with a clear message when codex is missing OR is installed-but-unauthenticated — test both states.
- [ ] **codex pre-flight does not brick Claude Code:** uninstall codex, restart Claude Code, run `/plugin uninstall zapili` — must succeed.
- [ ] **Wave file-scope safety:** the orchestrator computes write-scope intersections; test with a deliberately-broken plan where two phases share a file — must abort before spawning.
- [ ] **Iteration cap:** validation loop terminates after N iterations even when codex keeps finding new issues — test with a prompt designed to drift.
- [ ] **Resume from crash:** kill the workflow mid-wave (`kill -9`), restart, verify it resumes from the correct phase based on artifact inspection (not `state.json` alone).
- [ ] **Contract strictness:** a malformed agent response (missing required field) is rejected and retried once before failing — verify the retry path executes.
- [ ] **Subagent prompt size:** instrument and log average prompt token count per spawn; assert it's under the soft budget on a real medium task.
- [ ] **codex stderr separation:** `codex exec` is never called with `2>&1`; verify with `rg '2>&1' plugins/zapili/`.
- [ ] **Final summary:** ZAP-12's summary lists every file touched in every wave, not just the last wave.
- [ ] **No global config writes:** `rg -e '~/.claude' -e '\$HOME/.claude' plugins/zapili/` returns nothing.
- [ ] **Semver bump enforcement:** modify a prompt, attempt to commit without bumping `plugin.json` version — pre-commit must warn.
- [ ] **Researcher question cap:** for each task size, the researcher's first response contains ≤ the documented cap of questions.
- [ ] **Planner phase cap:** for each task size, `PLAN.md` lists ≤ the documented cap of phases.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Broken `marketplace.json` already pushed | LOW | Push a fix commit; users re-run `/plugin marketplace update` |
| Hook scripts shipped non-executable | LOW | Push a fix with `chmod +x` and `.gitattributes` update; bump patch version |
| Plugin mutated user's global config | MEDIUM | Document affected paths; ship a `zapili cleanup` command in a follow-up patch; apologize in CHANGELOG |
| Validation loop spinning forever in a user session | LOW (runtime) / HIGH (trust) | User aborts; instrument the iteration cap immediately; ship a patch within hours |
| Parallel agents corrupted files due to overlap | HIGH | User reverts via git; ship orchestrator-side scope-overlap check before any further parallel runs; flag affected wave types in CHANGELOG |
| State file corrupted | LOW | Delete `.zapili/state.json`; resume rebuilds from artifacts (assuming Pitfall 11's resilience is in place) |
| codex auth broke mid-workflow | MEDIUM | Workflow exits cleanly with state preserved; user fixes auth; `/zapili resume` continues from last completed phase |
| Researcher / planner produced garbage for a specific task | LOW per-session | User deletes `CONTEXT.md` / `PLAN.md` and re-runs — artifact-driven resume picks up correctly |
| Contract drift caused parse failure | LOW per-session | Retry-once layer handles it; if it persists, flag the prompt for revision |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. `marketplace.json` location | Phase 1 (Marketplace scaffolding) | Local install test from a fresh clone succeeds |
| 2. Missing/malformed marketplace fields | Phase 1 | JSON schema validation passes in pre-commit |
| 3. Non-executable / CRLF hook scripts | Phase 2 (zapili packaging) | `git ls-files --stage` shows `100755`; `.gitattributes` present |
| 4. Relative paths in hooks | Phase 2 | Plugin works when run from a project directory different from the plugin's own checkout |
| 5. SessionStart bricking Claude Code | Phase 2 | Uninstalling codex doesn't prevent Claude Code startup or plugin uninstall |
| 6. Wave file-scope overlap | Phase 3 (planner) + Phase 4 (orchestrator) | Crafted bad plan triggers abort before subagent spawn |
| 7. Validation loops never terminate | Phase 3 (validation design) | Iteration counter exits at cap with structured handoff to user |
| 8. Top-N findings instead of exhaustive | Phase 3 (codex prompt engineering) | Reference-corpus test: seeded issues are all reported in iteration 1 |
| 9. Contract drift | Phase 3 (contract design) + Phase 4 (parser) | Schema-validation rejects extra fields; retry-once succeeds |
| 10. State file race | Phase 4 (state model) | Concurrent-write test: subagent's "write to state.json" attempt is mechanically impossible |
| 11. Resume semantics | Phase 4 (resume logic) | Kill-9 test resumes correctly from artifacts when state.json is stale or missing |
| 12. "Same agent" myth | Phase 3 (contract design) | Spec explicitly says agents are roles; prior-attempt artifact is part of retry input |
| 13. Researcher question overflow | Phase 3 (researcher prompt + size policy) | Per-size-class cap enforced mechanically |
| 14. Planner over-fragmentation | Phase 3 (planner prompt + size policy) | Per-size-class phase cap; plan validator flags small phases |
| 15. codex headless auth failure | Phase 2 (pre-flight) | Pre-flight detects no-TTY env and demands API key |
| 16. codex stdout/stderr mixing | Phase 3 (codex wrapper) | Wrapper always uses separated streams |
| 17. codex output shape drift | Phase 3 (contract envelope) | Strict tag-based parsing + cosmetic-forgiveness layer + retry-once |
| 18. Subagent context bloat | Phase 3 (planner) + Phase 4 (orchestrator) | Average prompt token count under budget on a real medium task |
| 19. Plugin mutates global config | Phase 2 | Audit `rg '\$HOME/.claude'` returns empty |
| 20. Semver bump forgotten | Phase 1 (publication process) | Pre-commit warning on plugin changes without version bump |

---

## Sources

- [Claude Code Plugin Marketplaces — official docs](https://code.claude.com/docs/en/plugin-marketplaces) (HIGH confidence — authoritative)
- [anthropics/claude-plugins-official marketplace.json](https://github.com/anthropics/claude-plugins-official/blob/main/.claude-plugin/marketplace.json) (HIGH — canonical reference)
- [hesreallyhim/claude-code-json-schema — unofficial schemas](https://github.com/hesreallyhim/claude-code-json-schema) (MEDIUM — community-maintained but tracks spec)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) (HIGH — authoritative on hook event names, exit codes, ${CLAUDE_PLUGIN_ROOT})
- [anthropics/claude-code issue #34573 — plugin hooks.json command hooks silently dropped for PreToolUse/PostToolUse events](https://github.com/anthropics/claude-code/issues/34573) (HIGH — known footgun in plugin hooks)
- [5 Claude Code Hook Mistakes That Silently Break Your Safety Net](https://dev.to/yurukusa/5-claude-code-hook-mistakes-that-silently-break-your-safety-net-58l3) (MEDIUM — practitioner observations on chmod, CRLF, exit codes)
- [OpenAI Codex CLI — Non-interactive mode](https://developers.openai.com/codex/noninteractive) (HIGH — confirms stderr=progress, stdout=final-answer separation)
- [OpenAI Codex CLI — Authentication](https://developers.openai.com/codex/auth) (HIGH — ChatGPT vs API key auth paths)
- [openai/codex issue #9253 — login fails on headless without device-code](https://github.com/openai/codex/issues/9253) (HIGH — confirmed headless auth pitfall)
- [openai/codex issue #17041 — auth refresh breaks live session](https://github.com/openai/codex/issues/17041) (HIGH — auth instability in long sessions)
- [openai/codex issue #9091 — codex exec sometimes returns empty stdout/stderr with exit 0](https://github.com/openai/codex/issues/9091) (HIGH — silent failure mode to handle)
- [Claude Code Sub-Agents: Parallel vs Sequential Patterns](https://claudefa.st/blog/guide/agents/sub-agent-best-practices) (MEDIUM — practitioner)
- [Inside Claude Code's Shared Task List: How Agents Avoid Conflicts (MindStudio)](https://www.mindstudio.ai/blog/claude-code-agent-teams-shared-task-list) (MEDIUM — practitioner; the "last write wins" race is well-known)
- [Claude Code worktrees: parallel agents without stepping on each other (Refactix)](https://refactix.com/ai-development-engineering/claude-code-worktrees-parallel-agents) (MEDIUM — alternative isolation pattern; informs scope-overlap discussion)
- [Claude Code Hooks: Complete Guide to All 12 Lifecycle Events](https://claudefa.st/blog/tools/hooks/hooks-guide) (MEDIUM — practitioner enumeration of events)

---

*Pitfalls research for: Claude Code plugin marketplace + multi-agent dev-workflow plugin*
*Researched: 2026-05-27*
