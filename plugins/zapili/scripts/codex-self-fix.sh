#!/usr/bin/env bash
set -euo pipefail

# codex fixer wrapper (ZAP-60).
# Usage: codex-self-fix.sh [--dry-run] <artifact_path> <validator_role> <prior_findings_json>
#
# Composes a "fixer-role" prompt per references/codex-prompts.md instructing
# codex to revise <artifact_path> to address every HIGH (and MEDIUM) finding
# in <prior_findings_json>. Codex emits a unified-diff patch wrapped in
#   <response><patch>...</patch></response>
# which this wrapper extracts and persists to
# .zapili/codex-self-fix-<role>-attempt-N.patch. Attempt files are SCOPED by the
# <validator_role> slug so a plan escalation and a phase escalation keep
# independent per-cap-hit counters (a shared global counter would let one
# escalation's count bleed into the other and break the self_fix_cap bound).
#
# Dry-run mode (--dry-run as the FIRST arg) prints the patch to stdout and
# verifies it via `git apply --check` but does NOT modify the working tree.
# Apply mode runs `git apply --check` then `git apply`.
#
# Exit codes:
#   0   success (patch generated + applied / dry-run validated)
#   1   codex emitted an empty patch (orchestrator halts with "no diff produced")
#   2   codex invocation failed
#   4   `git apply --check` rejected the patch (malformed diff or context mismatch)
#   8   self-fix cap exhausted (round N > self_fix_cap) — codex NOT invoked
#   64  usage error
#
# Stdout: the patch file path (both modes). Orchestrator captures this and
# applies the SAME persisted patch — never re-invokes codex for the apply step.
# Stderr: codex progress + this script's diagnostics.

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

if [ "$#" -lt 3 ]; then
  printf 'usage: %s [--dry-run] <artifact_path> <validator_role> <prior_findings_json>\n' "$0" >&2
  exit 64
fi

ARTIFACT="$1"
VALIDATOR_ROLE="$2"
PRIOR_FINDINGS="$3"

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROMPTS_REF="$ROOT/skills/orchestrator/references/codex-prompts.md"
STATE_DIR=".zapili"
mkdir -p "$STATE_DIR"

if [ ! -f "$ARTIFACT" ]; then
  printf '[codex-self-fix] artifact not found: %s\n' "$ARTIFACT" >&2
  exit 64
fi
if [ ! -f "$PRIOR_FINDINGS" ]; then
  printf '[codex-self-fix] prior_findings not found: %s\n' "$PRIOR_FINDINGS" >&2
  exit 64
fi
case "$VALIDATOR_ROLE" in
  plan_validator|phase_reviewer|research_validator) ;;
  *)
    printf '[codex-self-fix] unknown validator_role: %s (expected plan_validator|phase_reviewer|research_validator)\n' "$VALIDATOR_ROLE" >&2
    exit 64
    ;;
esac

# Derive a filesystem-safe slug from the role so attempt files are per-role.
# Underscore is kept (filesystem-safe) so the slug equals the role name for the
# three known roles (plan_validator / phase_reviewer / research_validator).
ROLE_SLUG=$(printf '%s' "$VALIDATOR_ROLE" | tr -c 'A-Za-z0-9_' '-')
BASE="$STATE_DIR/codex-self-fix-$ROLE_SLUG"

N=1
while [ -f "$BASE-attempt-$N.patch" ]; do
  N=$((N + 1))
done

# Enforce self_fix_cap (exit 8) BEFORE invoking codex. Reading state.json is
# allowed; only WRITING it is the orchestrator's exclusive right. Fall back to 2.
self_fix_cap=$(jq -r '.self_fix_cap // 2' "$STATE_DIR/state.json" 2>/dev/null || echo 2)
case "$self_fix_cap" in (*[!0-9]*|'') self_fix_cap=2 ;; esac
if [ "$N" -gt "$self_fix_cap" ]; then
  printf '[codex-self-fix] self-fix exhausted: round N=%d > self_fix_cap=%d for role %s\n' \
    "$N" "$self_fix_cap" "$VALIDATOR_ROLE" >&2
  exit 8
fi

PATCH_FILE="$BASE-attempt-$N.patch"
PROMPT_FILE="$BASE-attempt-$N.prompt.txt"
RAW_OUT_FILE="$BASE-attempt-$N.raw"

# Extract HIGH + MEDIUM findings as a structured block for the fixer prompt.
# Each finding line contains id, severity, kind, file, line_range, and remediation
# so codex has every signal needed to author a targeted diff.
FINDINGS_BLOCK=$(jq -r '
  .findings[]
  | select(.severity == "HIGH" or .severity == "MEDIUM")
  | "<finding id=\"\(.id)\" severity=\"\(.severity)\" kind=\"\(.kind)\" file=\"\(.file // "null")\" line_range=\"\(.line_range // "null")\">\n  \(.remediation)\n</finding>"
' "$PRIOR_FINDINGS" 2>/dev/null || true)

if [ -z "$FINDINGS_BLOCK" ]; then
  printf '[codex-self-fix] no HIGH/MEDIUM findings in %s; nothing to fix\n' "$PRIOR_FINDINGS" >&2
  exit 1
fi

cat >"$PROMPT_FILE" <<EOF
<role>fixer</role>

<inputs>
  <file role="artifact">$ARTIFACT</file>
  <file role="prior-findings">$PRIOR_FINDINGS</file>
</inputs>

<task>
You are the last-resort fixer dispatched after the engineer (or planner) for
role "$VALIDATOR_ROLE" exhausted its iteration cap with persistent findings.
Your single job: revise the artifact above to address every HIGH (and MEDIUM)
finding listed in &lt;prior_findings&gt;. Do not invent new ISS-... ids — reference
the existing ids from the findings block when explaining your changes (per the
SHA-256 ID derivation rule, CALIB-01, documented in \${CLAUDE_PLUGIN_ROOT}/skills/orchestrator/references/codex-prompts.md).

Emit a single unified-diff patch applicable from the repo root via:
  git apply &lt;patch&gt;

REQUIREMENTS for the patch (git apply will reject the patch otherwise):
- The --- a/ and +++ b/ headers MUST use the artifact path EXACTLY as it
  appears in the &lt;inputs&gt; block (no normalization, no leading ./, no absolute
  paths).
- Include UNCHANGED CONTEXT lines around each change — the standard "diff -u"
  three-line context format. Append lines by including the last existing line
  as context. Modify lines by including the lines above and below as context.
- Use the standard "@@ -OLD_START,OLD_COUNT +NEW_START,NEW_COUNT @@" hunk
  header form with explicit comma-separated counts.

Worked example (a fictional 4-line file that adds a new line after the last):

  --- a/example.md
  +++ b/example.md
  @@ -1,4 +1,5 @@
   # title

   ## section
   first line
  +second line

If no valid patch can address every HIGH finding, emit an empty
&lt;patch&gt;&lt;/patch&gt; block — do NOT emit a partial or speculative patch.
</task>

<output_contract>
Respond ONLY inside this envelope, nothing before or after:

&lt;response&gt;
  &lt;patch&gt;
... unified diff here ...
  &lt;/patch&gt;
&lt;/response&gt;

Forbidden vocabulary in your response and in any modified line: \`key\`, \`main\`, \`top\`, \`important\`.
</output_contract>

<prior_findings>
$FINDINGS_BLOCK
</prior_findings>

Artifact content ($ARTIFACT):
$(cat "$ARTIFACT")
EOF

# Invoke codex via the generic wrapper. RAW_OUT_FILE holds the final assistant message.
if ! bash "$ROOT/scripts/codex-review.sh" "$PROMPT_FILE" "$RAW_OUT_FILE"; then
  printf '[codex-self-fix] codex invocation failed (attempt %d)\n' "$N" >&2
  exit 2
fi

# Extract <patch>...</patch> from the response. perl -0777 + /s handles
# multi-line patches (typical: hunk bodies span many lines).
PATCH_BODY=$(perl -0777 -ne 'print $1 if /<patch>(.*?)<\/patch>/s' "$RAW_OUT_FILE" 2>/dev/null || true)

# Trim leading/trailing whitespace-only lines (codex often pretty-prints the
# closing </patch> tag with indentation, which gets parsed as a phantom hunk
# line by git apply). Awk strips fully-blank lines at both ends but preserves
# blank lines inside the patch body (some hunks legitimately contain empty
# context lines).
PATCH_BODY=$(printf '%s' "$PATCH_BODY" | awk '
  /^[[:space:]]*$/ && !started { next }
  { started=1; lines[++n]=$0 }
  END {
    while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
    for (i=1; i<=n; i++) print lines[i]
  }
')

# Empty-patch detection: literal empty, whitespace-only, or just a few stray bytes.
if [ -z "$(printf '%s' "$PATCH_BODY" | tr -d '[:space:]')" ]; then
  printf '[codex-self-fix] empty patch from codex (attempt %d)\n' "$N" >&2
  # Persist the (empty) patch + raw output for forensics.
  : >"$PATCH_FILE"
  exit 1
fi

printf '%s\n' "$PATCH_BODY" >"$PATCH_FILE"

# Verify the patch is applicable BEFORE touching the tree (defensive even in dry-run).
APPLY_CHECK_LOG="$BASE-attempt-$N.apply-check.log"
if ! git apply --check "$PATCH_FILE" 2>"$APPLY_CHECK_LOG"; then
  printf '[codex-self-fix] git apply --check rejected patch (attempt %d); see %s\n' "$N" "$APPLY_CHECK_LOG" >&2
  exit 4
fi

if [ "$DRY_RUN" -eq 1 ]; then
  # Dry-run: emit the patch FILE PATH on stdout (not content) so the orchestrator
  # can `git apply` exactly the patch that was just validated by `git apply --check`.
  # This is the load-bearing guarantee of ZAP-60: "validate then apply the SAME
  # patch". Re-invoking the script for the apply would re-call codex (codex output
  # is non-deterministic) and bump the attempt counter, breaking the guarantee.
  printf '%s\n' "$PATCH_FILE"
  printf '[codex-self-fix] dry-run ok: patch persisted at %s\n' "$PATCH_FILE" >&2
  exit 0
fi

# Apply for real.
if ! git apply "$PATCH_FILE" 2>>"$APPLY_CHECK_LOG"; then
  printf '[codex-self-fix] git apply failed after --check passed (attempt %d); see %s\n' "$N" "$APPLY_CHECK_LOG" >&2
  exit 4
fi

printf '%s\n' "$PATCH_FILE"
printf '[codex-self-fix] applied %s\n' "$PATCH_FILE" >&2
exit 0
