---
phase: 08-codex-self-fix-fallback
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/scripts/codex-self-fix.sh
  - plugins/zapili/skills/orchestrator/references/codex-prompts.md
autonomous: true
requirements: [ZAP-60]
must_haves:
  truths:
    - "codex-self-fix.sh exists at plugins/zapili/scripts/, mode 0755, LF, set -euo pipefail, ${CLAUDE_PLUGIN_ROOT}-relative"
    - "Signature: [--dry-run] <artifact_path> <validator_role> <prior_findings_json>"
    - "Composes fixer prompt with artifact verbatim + HIGH+MEDIUM findings (jq-filtered) + instruction to emit <response><patch>...</patch></response>"
    - "Invokes codex via plugins/zapili/scripts/codex-review.sh; extracts <patch>...</patch> via perl -0777"
    - "Persists patch to .zapili/codex-self-fix-attempt-N.patch (auto-incremented N)"
    - "git apply --check before git apply; exit 4 on --check failure"
    - "Exit codes: 0 success, 1 empty patch, 2 codex failed, 4 git apply --check failed, 64 usage"
    - "codex-prompts.md gains a fourth role section (fixer) documenting prompt shape + output contract"
    - "SHA-256 ID derivation (CALIB-01) noted as applying to fixer ID references"
    - "D-NN decisions cited: D-01..D-08 (fixer prompt + wrapper)"
---
<objective>Ship the codex-self-fix wrapper + document the fourth codex role (fixer) so the orchestrator (Wave 2) can wire it into Stage 6 and Stage 7c.</objective>
<context>
@.planning/phases/08-codex-self-fix-fallback/08-CONTEXT.md
@plugins/zapili/scripts/codex-review.sh
@plugins/zapili/scripts/codex-review-phase.sh
@plugins/zapili/skills/orchestrator/references/codex-prompts.md
</context>
<tasks>
<task type="auto"><name>Task 1: codex-self-fix.sh wrapper</name>
<action>Write `plugins/zapili/scripts/codex-self-fix.sh`. Implements D-04..D-08:
- Args parsing: `--dry-run` optional first arg; then `<artifact_path> <validator_role> <prior_findings_json>`.
- Validates inputs (artifact + prior_findings_json exist; validator_role in {plan_validator, phase_reviewer, research_validator}).
- Composes fixer prompt: includes artifact verbatim, HIGH+MEDIUM findings extracted via `jq '.findings[] | select(.severity=="HIGH" or .severity=="MEDIUM")'`, and the `<output_contract>` directing codex to emit `<response><patch>...</patch></response>`.
- Persists prompt to `.zapili/codex-self-fix-attempt-N.prompt.txt`; auto-increments N from existing `.patch` files.
- Invokes codex via `${CLAUDE_PLUGIN_ROOT}/scripts/codex-review.sh`; exits 2 on codex failure.
- Extracts patch via `perl -0777 -ne 'print $1 if /<patch>(.*?)<\/patch>/s'`; persists raw patch to `.zapili/codex-self-fix-attempt-N.patch`.
- If patch is empty → exit 1 with `[codex-self-fix] empty patch from codex` diagnostic.
- `git apply --check <patch>` first; exit 4 if --check fails (capture stderr to log).
- If --dry-run mode → print patch to stdout, exit 0 (do NOT git apply).
- Else: `git apply <patch>`; on success exit 0; on failure exit 4 (should be impossible after --check passes; defensive).
- Mode 0755, LF line endings, `set -euo pipefail`.</action>
<acceptance_criteria>bash -n; mode 100755; head -2 shows `set -euo pipefail`; `--help` or missing-args invocation exits 64 with usage line; `--dry-run` with a known-broken prior_findings shows the prompt composition step on stderr.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: codex-prompts.md fixer-role section</name>
<action>Edit `plugins/zapili/skills/orchestrator/references/codex-prompts.md`. After the existing `### phase_reviewer` section (line ~108) and BEFORE the "## Reclassification rules" section, insert a new section "### fixer" that documents:
- Purpose: last-resort patch generator dispatched after the engineer/planner fix-loop exhausts its cap.
- Inputs block: exactly one `<file role="artifact">` + one `<file role="prior-findings">`.
- NO `<categories>` block (the fixer is single-purpose).
- `<task>` block: address every HIGH finding by ISS-id, never invent IDs (CALIB-01).
- `<output_contract>`: response shape `<response><patch>...</patch></response>` — unified diff applicable via `git apply` from the repo root (i.e. starts with `--- a/<path>` / `+++ b/<path>` headers).
- Halt path: empty patch → orchestrator emits `## CODEX SELF-FIX EXHAUSTED — no diff produced`.
- Cross-link to `plugins/zapili/scripts/codex-self-fix.sh` as the wrapper that uses this prompt.</action>
<acceptance_criteria>grep -q '### fixer' plugins/zapili/skills/orchestrator/references/codex-prompts.md; grep -q '<patch>' plugins/zapili/skills/orchestrator/references/codex-prompts.md; CALIB-01 cross-reference present.</acceptance_criteria>
</task>
</tasks>
<output>Create 08-01-fixer-script-and-prompt-SUMMARY.md.</output>
