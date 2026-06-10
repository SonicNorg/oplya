# Codex Review Prompt Scaffold

> Source of truth for every codex review invocation in zapili — research_validate, plan_validate, phase_review. The scaffold guarantees **exhaustive HIGH/MEDIUM/LOW coverage** and produces a payload that conforms to `validation-findings.schema.json`.

## Exhaustiveness contract (load-bearing for attempt N=1; see "Attempts N≥2" for regression reviews)

This contract governs the FIRST validator pass (attempt N=1). Attempts N≥2 are regression reviews that intentionally narrow scope — see the regression note below; do NOT apply the exhaustiveness framing to a regression pass.

Without an explicit anti-targeting instruction, codex defaults to a narrow targeted review — it picks the most salient issue, emits ~3 findings, and stops. This wastes every iteration of the fix-loop on partial coverage and is the single most expensive failure mode of the whole pipeline. The scaffold below was calibrated to defeat that default; the instructions are not advisory.

Every validator prompt MUST contain this paragraph verbatim (the exact wording matters — calibrated against codex-cli 0.133.0; the "FULL review (exhaustive coverage, not a targeted re-review)" framing was tuned against live codex behavior — milder substitutions like "comprehensive" or "thorough" alone do not produce the same coverage):

```
This is a FULL review (exhaustive coverage, not a targeted re-review). Do NOT limit yourself to
previously-discussed findings, do NOT pick a top-N subset, do NOT stop at the first
clear issue. Audit the ENTIRE artifact end-to-end across every category listed in
<categories>. Treat any prior_findings as hypotheses to re-verify from scratch — they
do NOT define your scope.

Return the maximum number of SUBSTANTIATED findings in a single pass. Substantiated
means each finding has: a real risk (not a stylistic preference), a concrete reproduction
or breaking scenario, and a remediation an engineer can act on. Speculative or aesthetic
notes belong in `tests_to_add` or a LOW finding with kind="no-findings", not as a
fabricated HIGH.

If you run out of budget before completing a category or a file, add an entry to
`not_fully_audited[]` naming the scope and the reason. Do NOT silently skip — silent
gaps are worse than declared gaps because the orchestrator cannot route around them.
```

### Severity mapping (HIGH/MEDIUM/LOW)

External P0/P1/P2/P3 schemes map onto zapili's three-level scale as follows. Use this mapping when adapting prompts from other review traditions:

| External | zapili severity | Meaning |
|----------|-----------------|---------|
| P0       | HIGH            | Blocker — data loss, security breach, contract violation, parallel-safety failure, build-broken |
| P1       | HIGH            | Correctness defect that ships if not fixed — wrong behavior under documented scenarios |
| P2       | MEDIUM          | Latent risk, missing edge-case handling, weak test, ambiguity that will cause future bugs |
| P3       | LOW             | Stylistic or nit-level; tone, naming, comment density. Also `kind: "no-findings"` confirmations. |

**HIGH is reserved** for issues that make the downstream artifact objectively wrong, unbuildable, or unsafe: a contradiction that breaks the plan, a hallucinated reference to something that does not exist, or missing context without which a required decision is impossible. Anything that is merely "could be clearer / more complete / could be improved" is at MOST MEDIUM — it does not block the loop the way a HIGH does. Over-classifying improvement notes as HIGH is the single most common cause of a non-converging fix-loop.

**Attempts N≥2 are REGRESSION reviews, not fresh audits.** On a retry the validator scripts emit a `<regression>` block instead of the exhaustive block: verify whether each prior finding is now resolved and inspect ONLY the regions changed since the previous attempt for NEW blocking issues — do not re-audit the whole artifact and do not introduce findings unrelated to the prior set or the changed regions. User-confirmed decisions are authoritative: the CONTEXT.md `<decisions>` and the TASK.md `## Definition of Done` items are settled and MUST NOT be re-raised as ambiguity / scope / missing-context findings.

LOW with `kind: "no-findings"` is the explicit "I checked this category and found nothing" entry — required for every listed `<category>` that produces no real finding, so the orchestrator can mechanically verify exhaustive coverage from the schema-shaped output.

### Finding evidence requirements

Each substantive finding (HIGH or MEDIUM — not no-findings placeholders) MUST include:

1. **`file` + `line_range`** — exact location. If the finding is cross-file (e.g. parallel-safety overlap), pick the primary artifact and name the second one in `summary`.
2. **`summary`** — one sentence stating what is wrong.
3. **`why_real_risk`** (optional but strongly encouraged) — substantiation. Why this is a real production/correctness risk, not a stylistic preference. Filters substantiated findings from noise. Skip only when the risk is self-evident from `summary` (e.g. obvious null-pointer).
4. **`repro`** (optional but strongly encouraged for HIGH) — the concrete scenario that breaks OR reproduction steps. Examples: "two phases in Wave 1 both write src/auth.ts → second engineer overwrites first", "POST /api/auth with empty body returns 500 instead of 400". Without this, "real risk" is just an assertion.
5. **`remediation`** — what the engineer/planner should do. Concrete: name files, fields, functions. "Improve security" is not remediation; "validate request body against the auth.LoginRequest schema before issuing the JWT" is.
6. **`tests_to_add`** (optional, array) — specific tests (unit/integration/property/manual) that would catch this issue going forward. One item per test, prose not code. Especially valuable for phase_reviewer findings where tests are part of the deliverable.

### `not_fully_audited[]` — explicit honesty

Top-level array. Each entry: `{scope, reason, recommended_followup?}`.

- `scope` — what was not audited. Examples: `"src/legacy/"` (file/dir), `"security category against PHASE-03.md"` (category × artifact), `"cross-phase invariants between Wave 2 and Wave 3"`.
- `reason` — why it was skipped. Examples: `"context budget exhausted at 87 percent"`, `"PHASE-03.md references a schema not provided in <inputs>"`, `"requires runtime evidence not available in static review"`.
- `recommended_followup` — optional concrete action to close the gap.

An empty `not_fully_audited: []` means the reviewer claims full coverage of every category and every file in `<inputs>`. The orchestrator surfaces non-empty entries to the user instead of treating them as silently OK.

## Mandatory prompt structure

Every codex review prompt MUST contain these XML blocks in order:

```xml
<role>research_validator | plan_validator | phase_reviewer</role>

<inputs>
  <file role="task">TASK.md</file>
  <file role="context">CONTEXT.md</file>
  <file role="plan">PLAN.md</file>
  <!-- include PHASE-XX.md and engineer payload as roles when applicable -->
</inputs>

<categories>
  <!-- per-role enumeration, verbatim from the per-role lists below -->
  <category>category-1</category>
  <category>category-2</category>
  ...
</categories>

<output_contract>
  Respond inside &lt;response&gt;&lt;payload&gt;{ ... }&lt;/payload&gt;&lt;/response&gt;.
  Payload MUST conform to https://oplya.dev/zapili/schemas/validation-findings.schema.json.
  Emit a finding for EVERY listed category. When a category has no finding, emit a finding of severity LOW with kind "no-findings" and remediation "category audited; no issues detected".
  Trailing &lt;coverage&gt; block lists files_reviewed and categories_checked.
  Forbidden vocabulary (never use these literal words in your response): `key`, `main`, `top`, `important`. Use neutral phrasing — see contracts.md.
</output_contract>

<prior_findings>
  <!-- present only when the orchestrator anchors prior issues -->
  <!-- when present, response MUST include a <reclassification> block per validation-findings schema -->
  <finding id="ISS-..." severity="HIGH" status="open" />
  ...
</prior_findings>
```

The `<prior_findings>` block triggers the reclassification rule: every prior ID must appear in the response either as a carried-forward finding (with `prior_status: "carried"`), a resolved finding (omitted from `findings` array, listed in `reclassification` with `new_severity: "RESOLVED"`), or a reclassified finding (listed in `reclassification` with the new severity + justification).

## Finding ID derivation (mandatory, deterministic)

Every finding's `id` MUST be derived from the triple `(file, line_range, kind)` via SHA-256, taking the first 12 hex characters and prefixing with `ISS-`. This is **non-negotiable** — without it, the same underlying issue produces a different ID on every attempt, the orchestrator cannot match prior findings, the reclassification rule above breaks, and the fix-loop loses the ability to track whether the engineer's revision actually closed the issue.

**Formula:**
```
id = "ISS-" + first_12_hex( SHA-256( file + "|" + line_range + "|" + kind ) )
```

**Edge cases (apply verbatim):**
- If `file` is `null` (e.g. a `no-findings` placeholder), use the literal string `"null"` in the digest input.
- If `line_range` is `null`, use the literal string `"null"` in the digest input.
- `file` is always the path **as it appears in the `<inputs>` block** (no normalization, no leading `./`, no absolute paths).
- `line_range` is the exact string written to the `line_range` field (e.g. `"12-15"`, `"8"`, `null`).

**Worked example:**
```
file       = "CONTEXT.md"
line_range = "8-9"
kind       = "context-task-contradiction"

digest_input = "CONTEXT.md|8-9|context-task-contradiction"
sha256       = cc94a3aa8710e3cd... (first 12 hex)
id           = "ISS-cc94a3aa8710"
```

**Duplicate-ID disambiguation** (added 2026-05-29): a single `(file, line_range, kind)` location can legitimately surface under two distinct categories (e.g. a missing API uncovered by the goal under both `gaps` and `completeness`). The base formula produces the same `id` for both, but the schema now enforces `uniqueItems: true` on `findings` — so emitting two entries with identical `id` will fail validation. When this collision occurs, pick ONE category per location: choose the most specific category that describes the issue and omit the duplicate. If you genuinely need both findings (different root cause), use distinct `kind` values per category to disambiguate the digest input. Do NOT append `category` to the digest input — that breaks back-compat with `expected-findings.json` fixtures derived from the 3-tuple formula.

**Forbidden:** inventing IDs such as `ISS-a1b2c3d4e5f6`, `ISS-d4e5f6a7b8c9`, or any incrementing-hex sequence. Findings with non-deterministic IDs are treated as malformed output and force the orchestrator to retry the codex call.

If you cannot compute SHA-256 inline, emit the digest input on a comment line above the finding so the orchestrator can re-derive — but compute it whenever the runtime allows.

## Per-role category lists (verbatim)

### research_validator

Review `TASK.md` + `CONTEXT.md` for:

1. `contradictions` — TASK and CONTEXT disagree on facts, scope, or constraints
2. `missing-context` — Decisions reference files, libraries, or systems not introduced in CONTEXT
3. `hallucinated-references` — CONTEXT cites files/APIs that do not exist
4. `scope-creep` — CONTEXT introduces work beyond what TASK requested
5. `ambiguity` — Wording admits multiple incompatible interpretations

### plan_validator

Review `PLAN.md` + every `PHASE-XX.md` + the canonical references for:

1. `contradictions` — Plan contradicts CONTEXT or TASK
2. `gaps` — Required outputs from the phase goal are not covered by any task
3. `ambiguity` — Tasks admit multiple incompatible implementations
4. `parallel-safety` — Pairwise write-set intersection across phases in a wave is non-empty (cross-check every wave)
5. `completeness` — All listed requirements have at least one task that satisfies them
6. `dod-coverage` — Every `DoD-NN` in TASK.md's `## Definition of Done` section is covered by at least one phase; an uncovered `DoD-NN` is a finding
7. `architectural-fit` — Plan violates the project's stack or established patterns
8. `dry-kiss` — Plan duplicates code/effort or introduces gratuitous abstraction
9. `professionalism` — Tone, naming, comment density, security awareness all meet professional bar

### phase_reviewer

Review the engineer payload + `PHASE-XX.md` + the touched files for:

1. `plan-contradiction` — Engineer's changes contradict the phase plan
2. `missing-tasks` — Phase tasks the engineer did not complete
3. `dod-conformance` — The phase's changes satisfy every `DoD-NN` the phase claims to cover (per the phase→DoD trace in PLAN.md); an unmet claimed `DoD-NN` is a finding
4. `code-quality` — Style violations, readability issues, dead code
5. `edge-cases` — Boundary conditions or error paths not handled
6. `security` — Newly-introduced threats not covered by the phase plan's threat model
7. `professionalism` — Same bar as plan_validator

### fixer

The fixer is the codex role dispatched after the planner or per-phase fix-loop
hits its iteration cap (`fix_loop_cap`, default 4 — enforced by the validator
script via exit 6) or stalls (exit 7) with persistent HIGH/MEDIUM findings.
Unlike the three validator roles above, the fixer does NOT emit findings — it
emits a **unified-diff patch** that revises the offending artifact
(`PHASE-XX.md` or `PLAN.md`) to address every prior HIGH (and MEDIUM) finding.
It runs inside the bounded self-fix loop (up to `self_fix_cap` rounds, default 2;
see "Bounded self-fix loop" below). The research role does NOT use the fixer — a
research cap/stall halts to the user.

The wrapper that drives this role is `plugins/zapili/scripts/codex-self-fix.sh`
(ZAP-60). See that script's header for the exit-code contract.

#### Prompt shape

```xml
<role>fixer</role>

<inputs>
  <file role="artifact"><path to the file to fix></file>
  <file role="prior-findings"><path to the validator's JSON output></file>
</inputs>

<task>
Revise the artifact to address every HIGH (and MEDIUM) finding listed in
<prior_findings>. Do not invent new ISS-... ids — reference the existing ids
from the findings block when explaining your changes (SHA-256 ID derivation
rule, CALIB-01).

Emit a single unified-diff patch applicable from the repo root via:
  git apply <patch>

REQUIREMENTS for the patch (`git apply` will reject the patch otherwise — all
three constraints below were calibrated against live codex-cli 0.133.0; omitting
any of them reproduces a documented failure mode from the live LOG):

1. The --- a/ and +++ b/ headers MUST use the artifact path EXACTLY as it
   appears in the <inputs> block — no normalization, no leading `./`, no
   absolute paths. Several `PHASE-XX.md` files can co-exist in the same repo;
   path drift sends the patch at the wrong file.

2. Include three lines of UNCHANGED CONTEXT around each change (the standard
   `diff -u` format). Zero-context hunks (`@@ -3 +3 @@` without surrounding
   context) are rejected by `git apply` even though looser tools like `patch`
   accept them.

3. Use the standard `@@ -OLD_START,OLD_COUNT +NEW_START,NEW_COUNT @@` hunk
   header form with explicit comma-separated counts.

Frame your work as positive requirements ("the patch MUST …") rather than
negative warnings ("the patch will be REJECTED unless …"). Negative framing
causes codex to abdicate with an empty <patch></patch> block under uncertainty.

Worked example (a fictional 4-line file that adds a new line after the last):

  --- a/example.md
  +++ b/example.md
  @@ -1,4 +1,5 @@
   # title

   ## section
   first line
  +second line

If no valid patch can address every HIGH finding, emit an empty
<patch></patch> block — do NOT emit a partial or speculative patch.
</task>

<output_contract>
Respond ONLY inside this envelope, nothing before or after:

<response>
  <patch>
... unified diff here ...
  </patch>
</response>

Forbidden vocabulary: `key`, `main`, `top`, `important`.
</output_contract>

<prior_findings>
  <!-- HIGH + MEDIUM findings, one per <finding> child, with full remediation -->
  <finding id="ISS-..." severity="HIGH" kind="..." file="..." line_range="...">
    <remediation text>
  </finding>
  ...
</prior_findings>
```

#### Halt paths

| Condition | Wrapper exit | Orchestrator response |
|-----------|--------------|------------------------|
| Patch generated, dry-run + apply clean, Claude post-fix review clean | 0 | Advance the stage |
| Patch generated + applied, Claude post-fix review still HIGH, rounds remain | 0 (from script) | Run another self-fix round against Claude's residual findings |
| Patch generated + applied, Claude post-fix review still HIGH, `self_fix_cap` exhausted | 8 (next call) | Halt with `## CODEX SELF-FIX EXHAUSTED` + finding IDs + patch paths |
| Codex emitted an empty `<patch></patch>` block | 1 | Halt with `## CODEX SELF-FIX EXHAUSTED — no diff produced` |
| Codex invocation failed | 2 | Halt with codex-side diagnostic |
| `git apply --check` rejected the patch | 4 | Halt with patch path + `git apply --check` stderr |

#### Bounded self-fix loop (supersedes the former single-attempt rule)

On a plan or phase cap-hit (validator exit 6) or stall (exit 7), the orchestrator
runs a BOUNDED `codex-self-fix → Claude-review` loop, up to `state.json
.self_fix_cap` (default 2) rounds. Each round: codex emits a patch, the
orchestrator applies the SAME validated patch, then **Claude (not codex)** reviews
the patched artifact. Codex never grades its own fix. If Claude judges the artifact
clean the stage advances; if it is still blocking and rounds remain, another round
runs against Claude's residual findings; once `self_fix_cap` rounds are exhausted
(`codex-self-fix.sh` returns exit 8) the workflow halts for a human.

The round counter is per-role and scoped on disk
(`.zapili/codex-self-fix-<role>-attempt-N.patch`), so a plan escalation and a
phase escalation keep independent counters. Re-running `/zapili:zapili` does NOT
reset the counter (Stage 0b preserves it from on-disk artifacts). For the
research role there is NO self-fix — a research cap/stall HALTS to the user, who
must supply the missing intent (Stage 4). Inspect the applied patches before
re-running so you do not stack speculative patches on top of each other.

## Reclassification rules

When `<prior_findings>` is present:

- Each prior `id` MUST appear EITHER in the new `findings` array (with `prior_status: "carried"` or `prior_status: "reclassified"`) OR in the `reclassification` array.
- A prior finding marked `RESOLVED` in the reclassification array MUST NOT reappear in the new `findings` array. This is the "resolved must not reappear" rule (ZAP-24).
- Justifications for severity changes are required — schema enforces non-empty `justification`.
- **Prior findings do NOT define your scope.** The exhaustiveness contract above still applies in full. Re-validate the entire artifact from scratch, treating prior findings as hypotheses to verify or refute. Adding NEW findings on a re-validation iteration is correct and expected — it means the engineer's fix introduced a regression OR the prior pass missed an issue. Targeted re-review that only checks prior findings (a default codex tendency on retry calls) is a contract violation; the response MUST include the full category coverage with `kind: "no-findings"` placeholders just like a first-pass call.

## Why this scaffold

- **Explicit category enumeration** is the load-bearing mechanism for exhaustive coverage. Without it, LLM reviewers default to `top`-N filtering even when prompted not to.
- **"No-findings" entries** force the reviewer to actively confirm absence rather than silently omit.
- **Trailing `<coverage>` block** lets the orchestrator detect missed categories mechanically.
- **Schema-anchored output** means the orchestrator never has to parse natural language to count findings.

## Calibration

The reference fixtures under `plugins/zapili/tests/fixtures/` seed one issue per family and document expected IDs/categories. Phase 4 development MUST run codex against every fixture before shipping any codex wrapper change; calibration passes when every fixture's `expected-findings.json` IDs all appear in the codex output.

**Note on ID determinism:** live calibration against codex-cli 0.133.0 (2026-05-28) confirmed that without the explicit SHA-256 formula above, the model invents non-deterministic IDs (incrementing hex sequences like `ISS-a1b2c3d4e5f6`, `ISS-b2c3d4e5f6a7`, ...) even when shown placeholder `ISS-...` examples. Fixture `f2-plan-write-overlap` reproduced this: codex correctly identified the `write-scope-overlap` issue but emitted `ISS-d4e5f6a7b8c9` instead of the expected `ISS-da83a9a75c86`. The "Finding ID derivation" section above was added to close that gap. Re-run calibration after any change to that section.
