---
phase: 01-marketplace-plugin-skeleton
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - LICENSE
  - .gitignore
  - .gitattributes
autonomous: true
requirements:
  - MKT-04
  - MKT-05
  - MKT-06
must_haves:
  truths:
    - "LICENSE present at repo root, MIT, with 2026 year and `Pavel <pavel.proger@gmail.com>` copyright holder"
    - ".gitignore covers .zapili/, .claude/cache/, OS noise, IDE noise, Node noise, Python noise, env files"
    - ".gitattributes enforces LF on *.sh and *.bash files (non-negotiable per ZAP-04 / MKT-06)"
    - "No duplicate LICENSE inside plugins/zapili/ (D-20)"
    - ".gitattributes is committed BEFORE any *.sh files (RESEARCH Pitfall 11) — sequencing handled by Wave 1 ordering"
    - "CONTEXT.md decisions implemented by this plan: D-01 (LICENSE: MIT, 2026, `Pavel <pavel.proger@gmail.com>`, no NOTICE, no patent grant), D-21 (.gitignore mandatory category list), D-22 (.gitattributes LF enforcement on `*.sh` / `*.bash`)"
  artifacts:
    - path: "LICENSE"
      provides: "MIT license terms for the repository"
      contains: "MIT License"
    - path: ".gitignore"
      provides: "Suppression of noise + plugin-local state directories"
      contains: ".zapili/"
    - path: ".gitattributes"
      provides: "LF-only enforcement for shell scripts to prevent CRLF interpreter spoofing"
      contains: "*.sh"
  key_links:
    - from: ".gitattributes"
      to: "scripts/*.sh (delivered by Plan 04)"
      via: "LF normalization on first add"
      pattern: "\\*\\.sh[[:space:]]+text[[:space:]]+eol=lf"
---

<objective>
Author the three repo-hygiene files (`LICENSE`, `.gitignore`, `.gitattributes`) that satisfy MKT-04, MKT-05, MKT-06.

Purpose: `.gitattributes` MUST land before Plan 04's `scripts/*.sh` files are committed (RESEARCH Pitfall 11 — `.gitattributes` only normalizes on future commits; pre-existing CRLF files stay CRLF until `git add --renormalize .`). LICENSE establishes the legal posture referenced by the READMEs and the `plugin.json` `license: "MIT"` field. `.gitignore` prevents accidental commits of `.zapili/` runtime state and secret env files.

Output:
- `LICENSE` — MIT verbatim from OSI canonical template, year 2026, holder `Pavel <pavel.proger@gmail.com>`.
- `.gitignore` — curated list covering all D-21 categories.
- `.gitattributes` — LF enforcement on `*.sh` and `*.bash` (mandatory), plus `*.json` and `*.md` (planner discretion per D-22).
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
  <name>Task 1: Write LICENSE (MIT verbatim)</name>
  <files>LICENSE</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-01 — MIT, 2026, `Pavel <pavel.proger@gmail.com>`, no NOTICE, no patent grant; D-20 — top-level only, no plugin duplicate)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 3 (canonical OSI MIT verbatim)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Don't Hand-Roll" (verbatim OSI text only — variation breaks SPDX detection)
  </read_first>
  <action>
    Write `LICENSE` at repo root using the canonical OSI MIT License text VERBATIM (no paraphrase — RESEARCH "Don't Hand-Roll" warns variation breaks SPDX `MIT` identifier matching).

    Required content (use RESEARCH Example 3 verbatim):
    - Line 1: `MIT License`
    - Line 3: `Copyright (c) 2026 Pavel <pavel.proger@gmail.com>` (year 2026 per D-01, holder per D-01).
    - Remaining: standard OSI MIT permission paragraph + AS-IS warranty disclaimer, exactly as in RESEARCH Example 3.

    Plain UTF-8, LF line endings, no BOM, no trailing whitespace, terminating newline.

    DO NOT create a duplicate `LICENSE` inside `plugins/zapili/` (D-20 — MKT-08 is about no cross-plugin code reuse, not license duplication; one LICENSE at top-level is correct).
  </action>
  <verify>
    <automated>test -f LICENSE && test -s LICENSE && grep -q "^MIT License$" LICENSE && grep -q "Copyright (c) 2026 Pavel" LICENSE && grep -q 'THE SOFTWARE IS PROVIDED "AS IS"' LICENSE && ! test -f plugins/zapili/LICENSE</automated>
  </verify>
  <acceptance_criteria>
    - `test -f LICENSE && test -s LICENSE` exits 0 (VALIDATION map task 01-03-01).
    - `grep -q "^MIT License$" LICENSE` exits 0.
    - `grep -q "Copyright (c) 2026 Pavel" LICENSE` exits 0 (D-01 year + holder).
    - `grep -q "pavel.proger@gmail.com" LICENSE` exits 0 (D-01 email — explicitly opted-in public per CONTEXT Specific Ideas).
    - `grep -q 'AS IS' LICENSE` exits 0 (warranty disclaimer present — proves the full template landed, not a stub).
    - `! test -f plugins/zapili/LICENSE` (D-20 — no duplicate inside plugin).
    - `file LICENSE | grep -qv "CRLF"` (LF endings).
  </acceptance_criteria>
  <done>MIT LICENSE present at repo root with correct year, holder, and verbatim OSI text; no duplicate inside `plugins/zapili/`.</done>
</task>

<task type="auto">
  <name>Task 2: Write .gitignore</name>
  <files>.gitignore</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-21 — mandatory category list)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 4 (canonical entry list)
  </read_first>
  <action>
    Write `.gitignore` at repo root using RESEARCH Example 4 as the source list, grouped by section comment header.

    Required categories (D-21) — each MUST appear as a literal pattern at the start of a line:
    - zapili runtime state: `.zapili/`
    - Claude Code per-plugin cache: `.claude/cache/`
    - OS noise: `.DS_Store`, `Thumbs.db`, `ehthumbs.db`, `Desktop.ini`
    - Editor / IDE: `.idea/`, `.vscode/`, `*.swp`, `*.swo`, `*~`, `.project`, `.settings/`
    - Node: `node_modules/`, `dist/`, `build/`, `*.log`, `npm-debug.log*`, `yarn-debug.log*`, `yarn-error.log*`, `.pnp.*`
    - Python: `__pycache__/`, `*.pyc`, `*.pyo`, `*.egg-info/`, `.venv/`, `venv/`, `env/`, `.pytest_cache/`
    - Env files: `.env`, `.env.local`, `.env.*.local`

    Use `# section header` comments grouping each category for readability. LF line endings. Terminating newline.

    DO NOT ignore `.claude/` itself (that directory holds project settings for this repo — only the `cache/` subdirectory is noise).
  </action>
  <verify>
    <automated>test -f .gitignore && grep -q "^\.zapili/$" .gitignore && grep -q "^\.claude/cache/$" .gitignore && grep -q "^node_modules/$" .gitignore && grep -q "^__pycache__/$" .gitignore && grep -q "^\.DS_Store$" .gitignore && grep -q "^\.idea/$" .gitignore && grep -q "^\.vscode/$" .gitignore && grep -q "^\.env$" .gitignore && grep -q "^\.venv/$" .gitignore && ! grep -q "^\.claude/$" .gitignore</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .gitignore` exits 0.
    - `grep -q "^\.zapili/$" .gitignore` exits 0 (VALIDATION map task 01-03-02 — zapili runtime state).
    - `grep -q "^\.claude/cache/$" .gitignore` exits 0 (VALIDATION map task 01-03-02 — Claude Code per-plugin cache).
    - `grep -q "node_modules" .gitignore` exits 0 (VALIDATION map task 01-03-02 — Node noise).
    - `grep -q "^__pycache__/$" .gitignore` exits 0 (Python noise per D-21).
    - `grep -q "^\.DS_Store$" .gitignore && grep -q "^Thumbs\.db$" .gitignore` exits 0 (OS noise per D-21).
    - `grep -q "^\.idea/$" .gitignore && grep -q "^\.vscode/$" .gitignore && grep -q "^\*\.swp$" .gitignore` exits 0 (IDE noise per D-21).
    - `grep -q "^\.env$" .gitignore && grep -q "^\.env\.local$" .gitignore` exits 0 (env files per D-21 — prevents accidental secret commits, T-03-01 mitigation).
    - `! grep -q "^\.claude/$" .gitignore` (project settings directory must remain tracked).
  </acceptance_criteria>
  <done>`.gitignore` exists at repo root covering all eight D-21 categories with the exact patterns listed in RESEARCH Example 4.</done>
</task>

<task type="auto">
  <name>Task 3: Write .gitattributes</name>
  <files>.gitattributes</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-22 — `*.sh` / `*.bash` non-negotiable; `*.json` / `*.md` discretionary)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 5 (canonical entries)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Common Pitfalls" Pitfall 11 (`.gitattributes` only normalizes on future commits — must land BEFORE any `*.sh` file is added)
  </read_first>
  <action>
    Write `.gitattributes` at repo root with the exact pattern lines from RESEARCH Example 5.

    Mandatory pattern lines (D-22 — non-negotiable per MKT-06 + ZAP-04):
    - `*.sh   text eol=lf`
    - `*.bash text eol=lf`

    Discretionary additions (D-22 permits — planner chooses to include them for consistency):
    - `*.json text eol=lf`
    - `*.md   text eol=lf`

    Binary markers (RESEARCH Example 5 — prevents git from trying to diff binary types if any ever land):
    - `*.png binary`
    - `*.jpg binary`

    Use `# comment` headers grouping the sections. LF line endings on `.gitattributes` itself. Terminating newline.

    SEQUENCING NOTE for executor: this file MUST be committed BEFORE any `scripts/*.sh` is added (Plan 04 work). The wave ordering already enforces this — Plan 03 is Wave 1, Plan 04 is Wave 2. If for any reason a `.sh` file is added before this file lands, follow up with `git add --renormalize . && git commit -m "normalize line endings"` (RESEARCH Pitfall 11 remediation).
  </action>
  <verify>
    <automated>test -f .gitattributes && grep -qE '^\*\.sh[[:space:]]+text[[:space:]]+eol=lf' .gitattributes && grep -qE '^\*\.bash[[:space:]]+text[[:space:]]+eol=lf' .gitattributes</automated>
  </verify>
  <acceptance_criteria>
    - `test -f .gitattributes` exits 0.
    - `grep -qE '^\*\.sh[[:space:]]+text[[:space:]]+eol=lf' .gitattributes` exits 0 (VALIDATION map task 01-03-03 — non-negotiable).
    - `grep -qE '^\*\.bash[[:space:]]+text[[:space:]]+eol=lf' .gitattributes` exits 0 (VALIDATION map task 01-03-03 — non-negotiable).
    - `file .gitattributes | grep -qv "CRLF"` (the attributes file itself is LF).
    - Sequencing check (run by executor before Plan 04): `git log --diff-filter=A --name-only --pretty=format: | grep -F .gitattributes` returns a hash earlier than (or equal to commit of) any `scripts/*.sh` addition — enforces Pitfall 11.
  </acceptance_criteria>
  <done>`.gitattributes` exists with mandatory LF enforcement for `*.sh` and `*.bash`, ready before Plan 04's shell scripts are added.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Repo → git working tree → Claude Code loader | Git-level configuration files affect every future commit. `.gitignore` prevents secret leakage; `.gitattributes` prevents CRLF-induced interpreter spoofing on Plan 04's `.sh` files. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-01 | Information Disclosure | Accidental secret commit (`.env` files) | mitigate | `.gitignore` includes `.env`, `.env.local`, `.env.*.local` per D-21; verified by `grep -q "^\.env$" .gitignore`. |
| T-03-02 | Tampering / DoS | CRLF-induced shell interpreter spoofing on `scripts/*.sh` (Plan 04) | mitigate | `.gitattributes` `*.sh text eol=lf` (D-22) committed BEFORE any `.sh` files; sequencing enforced by Wave 1 (this plan) → Wave 2 (Plan 04). |
| T-03-03 | Information Disclosure | License ambiguity → cannot reuse code legally | mitigate | LICENSE uses verbatim OSI MIT text (RESEARCH "Don't Hand-Roll") so SPDX `MIT` identifier matches and license-detection tools render correctly. |
| T-03-04 | Tampering | `.claude/` (project settings) accidentally ignored | mitigate | Task 2 acceptance criteria asserts `! grep -q "^\.claude/$"` — only the `cache/` subdirectory is ignored. |
| T-03-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan (static text files only); no `[ASSUMED]`/`[SUS]` packages to gate. |
</threat_model>

<verification>
- All three files exist at repo root and are non-empty.
- `LICENSE` contains verbatim OSI MIT text with year 2026 and holder `Pavel <pavel.proger@gmail.com>`.
- `.gitignore` covers all eight D-21 categories.
- `.gitattributes` contains the two mandatory `eol=lf` patterns.
- No duplicate `LICENSE` inside `plugins/zapili/` (MKT-08 / D-20).
- Sequencing constraint: this plan completes BEFORE Plan 04 adds any `scripts/*.sh` files (RESEARCH Pitfall 11). Wave 1 → Wave 2 ordering enforces this.
</verification>

<success_criteria>
- Phase 1 success criterion 5 is satisfied: `LICENSE`, `.gitignore`, `.gitattributes` present and enforced.
- Plan 04's `scripts/*.sh` files are committed with LF endings on first add (no later `--renormalize` needed).
- `claude plugin validate --strict` (Plan 05 supplementary check) reports no license-detection warning.
</success_criteria>

<output>
Create `.planning/phases/01-marketplace-plugin-skeleton/01-03-SUMMARY.md` when done, recording the verbatim MIT text confirmation, the eight `.gitignore` category groups landed, and the explicit confirmation that `.gitattributes` was committed before any `scripts/*.sh` from Plan 04.
</output>
