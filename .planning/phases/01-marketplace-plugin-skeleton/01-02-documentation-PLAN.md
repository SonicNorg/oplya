---
phase: 01-marketplace-plugin-skeleton
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - README.md
  - plugins/zapili/README.md
autonomous: true
requirements:
  - MKT-03
  - ZAP-03
must_haves:
  truths:
    - "Top-level README documents marketplace identity, install commands, plugin index, local-dev workflow, and license line in English"
    - "Plugin README documents what zapili does, the codex CLI prerequisite, TASK.md authoring stub, and the Phase 1 'slash command not yet wired' note"
    - "Both READMEs use the exact install commands `/plugin marketplace add SonicNorg/oplya` and `/plugin install zapili@oplya`"
    - "Neither README exceeds ~80 lines and neither contains badges/screenshots/TOC (D-27)"
    - "CONTEXT.md decisions implemented by this plan: D-25 (top-level README section list), D-26 (plugin README section list + codex prereq + TASK.md stub + Phase-1 status disclaimer)"
  artifacts:
    - path: "README.md"
      provides: "Top-level marketplace documentation surfaced on GitHub repo landing"
      contains: "/plugin marketplace add SonicNorg/oplya"
    - path: "plugins/zapili/README.md"
      provides: "Plugin-local documentation surfaced when inspecting the plugin tree"
      contains: "codex"
  key_links:
    - from: "README.md"
      to: "plugins/zapili/README.md"
      via: "markdown link in Plugins table"
      pattern: "plugins/zapili/README\\.md"
    - from: "plugins/zapili/README.md"
      to: "README.md"
      via: "markdown link in Install section"
      pattern: "\\.\\./\\.\\./README\\.md"
---

<objective>
Author the two English READMEs that document what `oplya` and `zapili` are, how to install them, and what prerequisites the plugin needs.

Purpose: Without these, a fresh visitor cannot find the install commands or the codex prerequisite (Phase-1 success criterion 3 + MKT-03 + ZAP-03). The READMEs are also the authoritative description of the local-dev workflow that Plan 04's validator + Plan 04's install-hooks installer feed into.

Output:
- `README.md` (top-level) — marketplace pitch, plugin index, install commands, local-dev section, license line.
- `plugins/zapili/README.md` — plugin pitch, codex prerequisite callout, TASK.md authoring stub, cross-link to top-level README, Phase-1 status disclaimer.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md
@.planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md
@.planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write top-level README.md</name>
  <files>README.md</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-25 — section list; D-27 — formatting constraints; D-06 — `SonicNorg/oplya` slug)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 9 (skeleton structure to follow)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Common Pitfalls" Pitfall 5 (do NOT suggest URL-based marketplace add) and Pitfall 12 (install commands are valid as of THIS commit)
  </read_first>
  <action>
    Write `README.md` at repo root in English, plain prose + fenced code blocks only (D-27 — no badges, no screenshots, no TOC, under ~80 lines).

    Required sections in order (D-25):
    1. H1 title `# oplya — Claude Code Plugin Marketplace` followed by a one-paragraph description using the user-approved framing `Personal plugin marketplace — multi-agent dev workflows` (D-03).
    2. `## Plugins` — a markdown table with one row for `zapili`. Description column uses the user-approved framing `Multi-agent dev workflow: research → plan → wave-parallel implementation with codex review` (D-08). Plugin name links to `plugins/zapili/README.md`.
    3. `## Install` — fenced code block with EXACTLY these two commands on separate lines: `/plugin marketplace add SonicNorg/oplya` then `/plugin install zapili@oplya`. Below the fence, a one-line callout that `zapili` requires the `codex` CLI and that the plugin README has full prerequisites. DO NOT mention URL-based marketplace add (RESEARCH Pitfall 5 — breaks relative source paths).
    4. `## Local development` — fenced bash block with: `git clone https://github.com/SonicNorg/oplya`, `cd oplya`, `./scripts/install-hooks.sh` (with comment: `# one-time: enables manifest validation on commit`), `./scripts/validate-manifests.sh` (with comment: `# run anytime to check manifests`). Below, a one-line optional supplementary check: `If you have the claude CLI installed, you can also run` followed by a fenced one-liner `claude plugin validate . --strict` for deeper checks (per RESEARCH Open Question Q3 recommendation).
    5. `## License` — single line `MIT — see [LICENSE](LICENSE).`

    Language: English ONLY (project CLAUDE.md constraint). No emoji.

    Reference Plan 04's deliverables in the Local development section by their final paths (`scripts/install-hooks.sh`, `scripts/validate-manifests.sh`) — Plan 04 will deliver these; the README is the user-facing contract that Plan 04 must satisfy.
  </action>
  <verify>
    <automated>test -f README.md &amp;&amp; grep -q "^# oplya" README.md &amp;&amp; grep -q "/plugin marketplace add SonicNorg/oplya" README.md &amp;&amp; grep -q "/plugin install zapili@oplya" README.md &amp;&amp; grep -qi "codex" README.md &amp;&amp; grep -q "scripts/validate-manifests.sh" README.md &amp;&amp; grep -q "scripts/install-hooks.sh" README.md &amp;&amp; grep -q "plugins/zapili/README.md" README.md &amp;&amp; grep -q "MIT" README.md &amp;&amp; test $(wc -l &lt; README.md) -le 80</automated>
  </verify>
  <acceptance_criteria>
    - `test -f README.md` exits 0 (VALIDATION map task 01-02-01: file exists).
    - `grep -q "/plugin marketplace add" README.md` exits 0 (VALIDATION map task 01-02-01).
    - `grep -qi "codex" README.md` exits 0 (VALIDATION map task 01-02-01).
    - `grep -q "/plugin install zapili@oplya" README.md` exits 0.
    - `grep -q "plugins/zapili/README.md" README.md` exits 0 (cross-link present per D-25).
    - `grep -q "scripts/validate-manifests.sh" README.md && grep -q "scripts/install-hooks.sh" README.md` exits 0 (Local development section present).
    - `! grep -qE "(badge|shield|screenshot)" README.md` (D-27 — no badges/screenshots).
    - `! grep -qE "^## Table of [Cc]ontents" README.md` (D-27 — no TOC).
    - `test $(wc -l &lt; README.md) -le 90` (≈80-line ceiling per D-27 with small slack).
    - `LC_ALL=C grep -Pq '[^\x00-\x7F]' README.md && echo "non-ASCII OK (em-dashes allowed)" || true` (non-blocking; em-dashes from user-approved wording are acceptable).
  </acceptance_criteria>
  <done>Top-level README exists with all six D-25 sections in English, install commands match D-06, line count under 90, no badges/screenshots/TOC.</done>
</task>

<task type="auto">
  <name>Task 2: Write plugins/zapili/README.md</name>
  <files>plugins/zapili/README.md</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-26 — section list; D-27 — formatting constraints)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 10 (skeleton + TASK.md stub)
    - README.md (top-level, written in Task 1 — for the cross-link target)
  </read_first>
  <action>
    Write `plugins/zapili/README.md` in English, plain prose + fenced code blocks (D-27 — no badges/screenshots/TOC, under ~80 lines).

    Required sections in order (D-26):
    1. H1 title `# zapili` followed by a one-paragraph description: `A multi-agent development workflow plugin for Claude Code. Drop a TASK.md into your working directory, run /zapili:zapili, and zapili drives research → plan → wave-parallel implementation, with each stage independently reviewed by the codex CLI.`
    2. `## Prerequisites` — bulleted list including: (a) `codex` CLI installed AND authenticated (with parenthetical `codex --version should succeed; sign in via ChatGPT or set OPENAI_API_KEY`), (b) Claude Code v2.1.143 or later. The prereq callout is mandatory per D-26.
    3. `## How to author a TASK.md` — one short paragraph explaining: create a `TASK.md` in the directory where you want changes to land; describe the change, constraints, context links; researcher reads it, classifies size, asks focused follow-ups. Then a single fenced markdown code block showing a minimal example (use the example body from RESEARCH Example 10 verbatim — `# Add JWT auth to the /login endpoint` with the three lines of stack/constraints/references). Close with one line: `The full TASK.md schema and worked examples ship in a later release.`
    4. `## Install` — single line cross-link: `See the [marketplace README](../../README.md#install).`
    5. `## Status` — block-quote: `> The slash command surface is not yet wired in this release. This plugin's manifest is published so the marketplace install path is testable end-to-end; the orchestrator slash command lands in the next release.` (D-26 — this line ships ONLY on the Phase-1 commit; Phase 2 will replace it with the real command surface description.)

    Language: English ONLY. No emoji. No badges. No TOC.
  </action>
  <verify>
    <automated>test -f plugins/zapili/README.md &amp;&amp; grep -q "^# zapili" plugins/zapili/README.md &amp;&amp; grep -qi "codex" plugins/zapili/README.md &amp;&amp; grep -q "TASK.md" plugins/zapili/README.md &amp;&amp; grep -q "/plugin install" plugins/zapili/README.md &amp;&amp; grep -q "../../README.md" plugins/zapili/README.md &amp;&amp; grep -qi "not yet wired" plugins/zapili/README.md &amp;&amp; test $(wc -l &lt; plugins/zapili/README.md) -le 90</automated>
  </verify>
  <acceptance_criteria>
    - `test -f plugins/zapili/README.md` exits 0 (VALIDATION map task 01-02-02).
    - `grep -q "/plugin install" plugins/zapili/README.md` exits 0 (VALIDATION map task 01-02-02 — cross-link to install path).
    - `grep -qi "codex" plugins/zapili/README.md` exits 0 (ZAP-03 prereq mention).
    - `grep -q "TASK.md" plugins/zapili/README.md` exits 0 (D-26 TASK.md authoring stub).
    - `grep -q "../../README.md" plugins/zapili/README.md` exits 0 (D-26 cross-link to top-level README).
    - `grep -qi "not yet wired" plugins/zapili/README.md` exits 0 (D-26 Phase-1 status disclaimer).
    - `test $(wc -l &lt; plugins/zapili/README.md) -le 90` (D-27 line ceiling).
    - `! grep -qE "(badge|shield|screenshot|^## Table of)" plugins/zapili/README.md`.
    - MKT-08 leaf check (with Plan 01 having written plugin.json): `find plugins/zapili -type f | sort` returns exactly two paths — `plugins/zapili/.claude-plugin/plugin.json` and `plugins/zapili/README.md` (D-23 minimalism).
  </acceptance_criteria>
  <done>Plugin README exists with all five D-26 sections in English, cross-links to top-level README, codex prereq callout present, Phase-1 status disclaimer present.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Repo → public GitHub viewers | READMEs are public-facing documentation rendered by GitHub. No untrusted input; the only "data" is prose authored deterministically by the planner/executor. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-02-01 | Information Disclosure | README install instructions exposing wrong slug | mitigate | Both READMEs are checked against the canonical `SonicNorg/oplya` slug (D-06) via `grep -q "/plugin marketplace add SonicNorg/oplya" README.md` and the cross-link `../../README.md` is checked in the plugin README. |
| T-02-02 | Tampering | URL-based marketplace add suggestion would break relative `source` paths (RESEARCH Pitfall 5) | mitigate | Top-level README explicitly uses GitHub-shorthand `SonicNorg/oplya` only; no URL-based alternative is documented. |
| T-02-03 | Repudiation | Status disclaimer about deferred slash command surface | mitigate | Plugin README's `## Status` block-quote sets expectations explicitly so users on the Phase-1 commit do not file false bug reports about a non-existent `/zapili:zapili` command. |
| T-02-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan (Markdown files only); no `[ASSUMED]`/`[SUS]` packages to gate. |
</threat_model>

<verification>
- Both README files exist, are non-empty, and contain the mandated D-25 / D-26 section keywords (`Install`, `Local development`, `Prerequisites`, `Status`, etc.) detectable via `grep`.
- Both files are under ~80 lines (allowing small slack to 90).
- No badges, screenshots, or TOC sections present (D-27).
- Cross-links resolve: `plugins/zapili/README.md` exists from the top-level link; `../../README.md` exists from the plugin link.
- Plugin tree contains exactly two leaves after this plan + Plan 01: `.claude-plugin/plugin.json` and `README.md` (MKT-08, D-23).
</verification>

<success_criteria>
- A first-time visitor cloning the repo can read `README.md` and run the install commands without consulting any other file.
- A user inspecting `plugins/zapili/` finds the README explaining the codex prerequisite and the Phase-1 status disclaimer.
- Plan 05's live install rehearsal verifies the install commands in `README.md` match the actual `/plugin marketplace add` + `/plugin install` flow exactly.
</success_criteria>

<output>
Create `.planning/phases/01-marketplace-plugin-skeleton/01-02-SUMMARY.md` when done, recording line counts and a checklist confirming each D-25 / D-26 section landed.
</output>
