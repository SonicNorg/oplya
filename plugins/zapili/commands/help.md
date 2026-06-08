---
description: Show /zapili command index, prerequisites, TASK.md authoring guidance, and how state/resume work
model: claude-haiku-4-5
---

# /zapili:help — usage index

Print the following text verbatim to the user. Do NOT paraphrase, summarize, or reformat — operators rely on the exact wording for muscle-memory recognition across sessions.

```
zapili — multi-agent dev workflow plugin (v1.1.3)

================================================================
COMMANDS
================================================================

  /zapili:zapili [task | --resume]   Run the full workflow (TASK.md optional)
  /zapili:status                     Read-only snapshot of .zapili/state.json
  /zapili:help                       This help screen


================================================================
WHERE TO WRITE YOUR TASK
================================================================

A TASK.md is OPTIONAL. You can provide the task three ways:

  1. Inline:  /zapili:zapili "describe the change you want"
  2. A TASK.md file in the directory from which you opened the
     current Claude Code session (the "project CWD").
  3. Neither — the orchestrator prompts you to describe the change.

zapili reads TASK.md from the project CWD — not from your home
directory, not from the plugin's install location, not from any
global config.

Every path ends with a confirmed TASK.md on disk. If one already
exists, zapili asks whether to use it as-is, augment it with your
inline task, or replace it — it never adopts an existing TASK.md
silently. After the first Q&A, zapili captures a confirmed
Definition of Done and appends it to TASK.md.


================================================================
HOW TO WRITE A USEFUL TASK.md
================================================================

A good TASK.md is short (often <100 LOC of prose) and answers four
questions:

  1. WHAT — one paragraph: what change you want, in plain English.
  2. WHY  — one sentence: why this matters (the underlying problem).
  3. STACK — one line: language, framework, key libraries (e.g.
     "Node 20 + Express + Postgres", "Kotlin + Spring Boot 3").
  4. CONSTRAINTS — what you do NOT want changed. E.g.
       - "Must use jsonwebtoken@8.x, no new auth deps"
       - "Do not touch src/legacy/"
       - "Backward-compatible with v1 API"

Reference existing files by path (e.g. "see src/auth/ for current
shape") — the researcher subagent will follow those leads.

Task size determines workflow depth: small (≤100 LOC, 1–3 modules)
runs a single-phase pipeline; medium-to-gigantic tasks fan out into
multiple parallel waves. The researcher classifies your task and
asks 3–4 questions (small) up to 13–20 questions (gigantic) before
planning. Answer each one carefully — answers feed every downstream
stage and lock as decisions in CONTEXT.md.


================================================================
PREREQUISITES
================================================================

  - codex CLI installed AND authenticated.
    Install: `npm install -g @openai/codex`
         or: `curl -fsSL https://example.openai.com/codex/install.sh | sh`
    Auth:    `codex login`  OR  `export OPENAI_API_KEY=...`
    Without codex, the strict pre-flight check in /zapili:zapili will
    abort before any work runs. (The SessionStart hook also emits an
    advisory warning if codex is missing — it never blocks Claude Code,
    only nudges you.)
    When $CLAUDE_INSTANCE=work, zapili uses the `codex-work` binary
    instead of `codex` for every invocation and pre-flight check.

  - jq >= 1.6 (manifest validation + JSONL parsing). Pre-installed on
    most macOS/Linux dev machines.

  - perl (with -0777 slurp mode) — patch extraction inside the codex
    self-fix path. Pre-installed on macOS and almost every Linux distro.


================================================================
HOW IT WORKS (high-level)
================================================================

  /zapili:zapili goes through these stages (no human gate between them
  except the user-Q&A after research):

    Stage 1  Bootstrap state in .zapili/state.json
    Stage 2  Researcher subagent reads TASK.md, classifies size, asks
             you 3–20 questions
    Stage 3  Q&A loop — answers go into CONTEXT.md
    Stage 4  Codex research-validate loop (up to 4 iterations);
             on cap-hit with persistent HIGH findings, codex-self-fix
             fallback dispatches a fixer pass that patches CONTEXT.md
    Stage 5  Planner subagent emits PLAN.md + PHASE-XX.md per phase
    Stage 6  Codex plan-validate loop (same cap + self-fix mechanics)
    Stage 7  Wave-parallel engineer fan-out — phases inside one wave
             run in parallel iff their write-scopes are pairwise
             disjoint (orchestrator verifies mechanically); per-phase
             review + fix loop; same self-fix fallback per phase
    Stage 8  Final SUMMARY.md aggregating files touched + decisions

  Engineers commit each task atomically. The final SUMMARY.md lives
  in the project root alongside TASK.md.


================================================================
STATE, CRASH-RESUME, AND THE .zapili/ DIRECTORY
================================================================

  All workflow state lives under .zapili/ in your project CWD:

    .zapili/state.json                       — current stage cursor +
                                               iteration counters
    .zapili/research-validate-attempt-N.json — codex findings per attempt
    .zapili/plan-validate-attempt-N.json     — same, per plan iteration
    .zapili/phase-XX-review-attempt-N.json   — per-phase review output
    .zapili/codex-self-fix-attempt-N.patch   — codex-generated patches
    .zapili/codex-self-fix-attempt-N.raw     — raw codex JSONL streams

  If your session crashes, laptop sleeps, or you hit Ctrl-C mid-run,
  just re-run /zapili:zapili (no flags needed — `--resume` is the
  default behavior). Stage 0 derives the correct current stage from
  on-disk artifacts (not from state.json alone — artifacts win on
  conflict) and picks up where the previous session stopped.

  Add .zapili/ to your .gitignore if you don't want the workflow state
  tracked in version control.


================================================================
WHAT TO DO IF /zapili:zapili HALTS
================================================================

  Possible halt reasons + where to look:

    "No task provided and no TASK.md to resolve"
        → re-run with an inline task: /zapili:zapili "..." — or
          create a TASK.md in your project CWD; re-run.

    "codex (or codex-work) CLI not found / not authenticated"
        → install the binary the preflight names (codex, or codex-work
          when $CLAUDE_INSTANCE=work) and run `<binary> login`; re-run.

    "## CODEX SELF-FIX EXHAUSTED — no diff produced"
        → codex couldn't produce a patch for the persistent findings.
          Inspect the latest .zapili/*-validate-attempt-*.json for
          finding IDs, fix manually, re-run.

    "## CODEX SELF-FIX EXHAUSTED — post-fix re-review still HIGH"
        → codex's patch landed but the issue persists. Inspect the
          named patch file under .zapili/codex-self-fix-attempt-N.patch
          to see what was attempted, fix manually, re-run.

    "## OVERLAP in Wave N: ..." from check-wave-disjointness
        → planner produced phases that write the same files in one
          wave. Edit PLAN.md to split them across waves; re-run.


================================================================
WHAT zapili DOES NOT TOUCH
================================================================

  - Never modifies ~/.claude/settings.json, ~/.claude.json, or any
    other global Claude Code config (ZAP-05 contract).
  - Never modifies your git remote (no push, no force-push, no
    branch creation outside the workflow's per-attempt branches).
  - Never reads files outside the project CWD without explicit
    references in TASK.md.


================================================================
DEEPER DOCS
================================================================

  Plugin README:        ${CLAUDE_PLUGIN_ROOT}/README.md
  Inter-agent contracts: ${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/contracts.md
  Codex review prompts:  ${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/codex-prompts.md
  Task sizing rules:     ${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/task-sizing.md
  Schemas:               ${CLAUDE_PLUGIN_ROOT}/schemas/
  Test fixtures:         ${CLAUDE_PLUGIN_ROOT}/tests/fixtures/
```
