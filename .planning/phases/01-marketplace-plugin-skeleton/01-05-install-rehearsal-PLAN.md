---
phase: 01-marketplace-plugin-skeleton
plan: 05
type: execute
wave: 3
depends_on:
  - 01-01
  - 01-02
  - 01-03
  - 01-04
files_modified:
  - .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md
autonomous: false
requirements:
  - MKT-07
must_haves:
  truths:
    - "In a fresh Claude Code session against the repo, `/plugin marketplace add` recognizes the marketplace with zero validation errors"
    - "`/plugin install zapili@oplya` resolves successfully and zapili appears in `/plugin list`"
    - "`claude plugin validate . --strict` and `claude plugin validate ./plugins/zapili --strict` both report zero warnings (supplementary check)"
    - "The deliberately-broken-manifest pre-commit rejection scenario works end-to-end against the installed hook"
  artifacts:
    - path: ".planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md"
      provides: "Stamped record of rehearsal results — what command was run, what the live Claude Code session reported, screenshots/transcripts if any"
      contains: "marketplace add"
  key_links:
    - from: ".claude-plugin/marketplace.json + plugins/zapili/.claude-plugin/plugin.json"
      to: "Claude Code /plugin marketplace add + /plugin install loader"
      via: "live session in a fresh clone"
      pattern: "live runtime — not scriptable"
---

<objective>
Run the live end-to-end install rehearsal — the only Phase 1 verification that requires a real Claude Code runtime and cannot be scripted offline. Stamp the result into a dated rehearsal log so future regressions are auditable.

Purpose: VALIDATION.md task 01-05-01 and Phase 1 success criteria 1 + 2 explicitly require this rehearsal. The offline validator (Plan 04) catches syntactic + required-field problems, but only the live `/plugin marketplace add` loader can confirm that the manifest's source-resolution, owner schema, and category placement actually satisfy the runtime (and that RESEARCH's `owner.url` / `category` drift fixes from Plan 01 land cleanly under `--strict`).

Output: a single dated log file documenting which commands ran, what the live session reported, and the supplementary `claude plugin validate --strict` results. No production code changed by this plan — its deliverable is the verified, dated audit trail.

Why `autonomous: false`: this plan requires a human operator with an active Claude Code session and a separate scratch directory for a fresh `git clone`. The executor pauses at the checkpoint, the operator runs the live commands, the operator stamps the log, the executor resumes to commit the log.
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
@.planning/phases/01-marketplace-plugin-skeleton/01-01-SUMMARY.md
@.planning/phases/01-marketplace-plugin-skeleton/01-02-SUMMARY.md
@.planning/phases/01-marketplace-plugin-skeleton/01-03-SUMMARY.md
@.planning/phases/01-marketplace-plugin-skeleton/01-04-SUMMARY.md
@README.md
@plugins/zapili/README.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Run offline pre-rehearsal preflight</name>
  <files>(no files written; this is a read-only sanity check that gates the human checkpoint)</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md § "Per-Task Verification Map" tasks 01-01-* through 01-04-* (every prior verification must be green before invoking the human)
  </read_first>
  <action>
    Before paging the human, re-run every offline acceptance command from Plans 01–04 in sequence to confirm the repo is in a rehearsal-ready state. If any check fails, abort this plan with a clear pointer to the failing prior plan — do NOT page the human for a rehearsal of a broken build.

    Commands to run in order (collect exit codes):
    1. `jq -e . .claude-plugin/marketplace.json` and `jq -e . plugins/zapili/.claude-plugin/plugin.json`
    2. `jq -e '.owner | has("url") | not' .claude-plugin/marketplace.json` (RESEARCH Pitfall 1 drift fix)
    3. `jq -e 'has("category") | not and (has("version") | not)' plugins/zapili/.claude-plugin/plugin.json` (RESEARCH Q2 drift fix + D-09 version omission)
    4. `bash scripts/validate-manifests.sh` (Plan 04 validator — must exit 0)
    5. `bash scripts/test-validator.sh` (Plan 04 driver — exercises Pitfall 7 regression)
    6. `test -f README.md && test -f plugins/zapili/README.md && test -f LICENSE && test -f .gitignore && test -f .gitattributes`
    7. `find plugins/zapili -type f | sort` — must list exactly `plugins/zapili/.claude-plugin/plugin.json` and `plugins/zapili/README.md` (MKT-08 / D-23 minimalism)

    If all 7 checks pass, proceed to Task 2 (the human checkpoint). If any fails, halt and report the failure to the orchestrator with the failing command + exit code.
  </action>
  <verify>
    <automated>jq -e . .claude-plugin/marketplace.json >/dev/null && jq -e . plugins/zapili/.claude-plugin/plugin.json >/dev/null && jq -e '.owner | has("url") | not' .claude-plugin/marketplace.json >/dev/null && jq -e '(has("category") | not) and (has("version") | not)' plugins/zapili/.claude-plugin/plugin.json >/dev/null && bash scripts/validate-manifests.sh && bash scripts/test-validator.sh && test -f README.md && test -f plugins/zapili/README.md && test -f LICENSE && test -f .gitignore && test -f .gitattributes && [ "$(find plugins/zapili -type f | sort | tr '\n' ' ')" = "plugins/zapili/.claude-plugin/plugin.json plugins/zapili/README.md " ]</automated>
  </verify>
  <acceptance_criteria>
    - All seven preflight commands exit 0.
    - `find plugins/zapili -type f` returns exactly the two expected leaves.
    - On any failure, the orchestrator is notified and Task 2 is NOT entered.
  </acceptance_criteria>
  <done>Offline state confirmed rehearsal-ready; safe to page the human operator.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: Human-driven live install rehearsal</name>
  <what-built>
    Repository skeleton: `.claude-plugin/marketplace.json` (Plan 01), `plugins/zapili/.claude-plugin/plugin.json` (Plan 01), top-level and plugin READMEs (Plan 02), `LICENSE` / `.gitignore` / `.gitattributes` (Plan 03), `scripts/validate-manifests.sh` + `scripts/install-hooks.sh` + `scripts/pre-commit` + `scripts/test-validator.sh` + three fixtures (Plan 04).

    All offline checks (Task 1 preflight) are green. The marketplace and plugin manifests have the RESEARCH-mandated drift fixes (`owner.url` absent from marketplace; `category` absent from plugin; no `version` in plugin per D-09).
  </what-built>
  <how-to-verify>
    Perform the live rehearsal in a SEPARATE working directory — do NOT add the marketplace from the dev repo itself (the symlink/in-place behavior of `/plugin marketplace add` from inside its own checkout is a known footgun; use a fresh clone to mirror the user's first-time experience).

    **Step 1 — Fresh-clone smoke test (VALIDATION.md Manual-Only row 1):**
    1. Open a terminal OUTSIDE the dev repo. Run: `git clone <path-to-dev-repo> /tmp/oplya-rehearsal && cd /tmp/oplya-rehearsal`. (If the repo is already pushed to `github.com/nepavel/oplya`, you may use `git clone https://github.com/nepavel/oplya /tmp/oplya-rehearsal` instead.)
    2. Start a fresh Claude Code session in `/tmp/oplya-rehearsal`.
    3. Inside the Claude Code session, run: `/plugin marketplace add .` (or `/plugin marketplace add nepavel/oplya` if testing the GitHub-shorthand path per README D-25). Expected: zero validation errors; `oplya` appears in `/plugin marketplace list`.
    4. Run: `/plugin install zapili@oplya`. Expected: "installed" confirmation; `zapili` appears in `/plugin list`.
    5. Run: `/plugin list` — confirm `zapili` is listed under the `oplya` marketplace.
    6. Phase 1 STOPS here. Do NOT attempt to invoke `/zapili:zapili` — Phase 2 wires the command surface.

    **Step 2 — Supplementary strict validation (RESEARCH Q3 recommendation):**
    1. From the rehearsal repo root, run: `claude plugin validate . --strict` and `claude plugin validate ./plugins/zapili --strict`. Expected: zero warnings, zero errors on both. If `owner.url` warnings appear, Plan 01 drift fix was not applied — escalate.

    **Step 3 — Pre-commit hook end-to-end (VALIDATION.md Manual-Only row 2 + Per-Task row 01-04-03):**
    1. Inside the rehearsal repo root, run: `./scripts/install-hooks.sh`. Expected: `ok: installed pre-commit at .git/hooks/pre-commit`.
    2. On a scratch branch (`git checkout -b rehearsal-broken-manifest`), deliberately introduce a trailing comma into `.claude-plugin/marketplace.json` (e.g., add `,` after the last `plugins[]` entry's closing brace).
    3. `git add .claude-plugin/marketplace.json && git commit -m "rehearsal: trailing comma"`. Expected: commit is REFUSED with the validator's `FAIL:` message on stderr.
    4. Restore the file (`git restore --staged --worktree .claude-plugin/marketplace.json`) and switch back to `main`. Delete the scratch branch.

    **Step 4 — Stamp the log file:**
    1. Return to the dev repo (NOT the rehearsal clone).
    2. Create `.planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md` with the following sections:
       - `## Rehearsal stamp` — date, operator name, Claude Code version (`claude --version`), git commit SHA of the dev repo at rehearsal time, path of the rehearsal clone.
       - `## Step 1 — Fresh-clone smoke` — paste the exact `/plugin marketplace list` and `/plugin list` outputs.
       - `## Step 2 — Strict validation` — paste both `claude plugin validate --strict` outputs.
       - `## Step 3 — Hook gate` — paste the `install-hooks.sh` output and the rejected-commit stderr.
       - `## Sign-off` — one line: `Phase 1 rehearsal: PASS / FAIL — <operator initials> — <date>`.
    3. Resume the executor (it commits the log file as the final Phase 1 artifact).
  </how-to-verify>
  <resume-signal>Type "approved" once the log file is stamped and saved, or paste the failure transcript (which becomes a gap-closure trigger).</resume-signal>
</task>

<task type="auto">
  <name>Task 3: Commit the rehearsal log</name>
  <files>.planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md (stamped by the operator in Task 2)
  </read_first>
  <action>
    After the human checkpoint returns "approved" with a stamped log, verify the log file exists, has all four required sections, and contains `PASS` on the sign-off line. Then commit the log file as part of the Phase 1 closing commit (the orchestrator's git_commit step handles the actual `git commit`; this task's job is to ensure the log is in place and well-formed).

    If the log contains `FAIL`, do NOT commit — return a structured failure report to the orchestrator listing which rehearsal step failed and which prior plan likely needs gap closure.
  </action>
  <verify>
    <automated>test -f .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "^## Rehearsal stamp" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "^## Step 1" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "^## Step 2" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "^## Step 3" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "^## Sign-off" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -qE "Phase 1 rehearsal: (PASS|FAIL)" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md && grep -q "Phase 1 rehearsal: PASS" .planning/phases/01-marketplace-plugin-skeleton/01-05-rehearsal-LOG.md</automated>
  </verify>
  <acceptance_criteria>
    - Log file exists with all four `##` section headers + a sign-off line.
    - Sign-off line contains `PASS` (FAIL halts the plan and triggers gap closure).
    - VALIDATION.map row 01-05-01 marked green in the orchestrator's STATE update.
  </acceptance_criteria>
  <done>Rehearsal log stamped, verified, and ready for the Phase 1 closing commit.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Dev repo → fresh-clone rehearsal directory | Operator clones into `/tmp/oplya-rehearsal` to avoid in-place self-referential install footguns. |
| Operator (human) → live Claude Code session | The only Phase 1 trust boundary that requires human-in-the-loop verification; everything else is offline-deterministic. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-05-01 | Tampering | Self-referential `/plugin marketplace add .` from inside the dev repo loads stale cache | mitigate | Step 1 explicitly performs the rehearsal in a FRESH clone at `/tmp/oplya-rehearsal`. |
| T-05-02 | Repudiation | Rehearsal claimed PASS without actually running | mitigate | Log file MUST include `claude --version` output, `git rev-parse HEAD` of dev repo, pasted `/plugin list` and `/plugin marketplace list` outputs, AND operator initials — every claim is grounded in pasted runtime evidence. |
| T-05-03 | Information Disclosure | Rehearsal log accidentally captures user-private paths | accept | The log path is `/tmp/oplya-rehearsal` (operator's machine); if operator's home path leaks via terminal prompt copy-paste, low-risk (committed only to the public repo's `.planning/` directory which already contains the operator's email per D-01). |
| T-05-04 | Tampering | Operator skips Step 3 (hook end-to-end) | mitigate | Task 3's verify command grep-asserts `## Step 3` section header presence; missing section blocks commit. |
| T-05-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan; rehearsal exercises pre-existing `claude` and `codex` CLIs only. |
</threat_model>

<verification>
- Task 1 preflight: all seven offline checks exit 0 BEFORE the human is paged.
- Task 2 human checkpoint: operator stamps the log with four sections + sign-off line.
- Task 3 commit gate: log file structure verified; `PASS` required.
- VALIDATION.md task 01-05-01 (manual install rehearsal) green.
- Both `claude plugin validate --strict` runs report zero warnings — confirms the RESEARCH `owner.url` and `category` drift fixes landed in Plan 01 actually satisfy the official validator.
</verification>

<success_criteria>
- Phase 1 success criteria 1 and 2 (from ROADMAP.md) confirmed end-to-end in a live session.
- VALIDATION.md "Validation Sign-Off" can be checked off: all tasks have an automated or explicit-manual verification; the manual install rehearsal is logged and stamped.
- The phase ships as a working installable marketplace + plugin pair with auditable rehearsal evidence.
</success_criteria>

<output>
Create `.planning/phases/01-marketplace-plugin-skeleton/01-05-SUMMARY.md` when done, recording the rehearsal log filename, the dev-repo SHA at rehearsal time, the Claude Code version used, and an explicit cross-link to VALIDATION.md row 01-05-01 (now green).
</output>
