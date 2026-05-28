# Codex Review Prompt Scaffold

> Source of truth for every codex review invocation in zapili — research_validate, plan_validate, phase_review. The scaffold guarantees **exhaustive HIGH/MEDIUM/LOW coverage** and produces a payload that conforms to `validation-findings.schema.json`.

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
6. `architectural-fit` — Plan violates the project's stack or established patterns
7. `dry-kiss` — Plan duplicates code/effort or introduces gratuitous abstraction
8. `professionalism` — Tone, naming, comment density, security awareness all meet professional bar

### phase_reviewer

Review the engineer payload + `PHASE-XX.md` + the touched files for:

1. `plan-contradiction` — Engineer's changes contradict the phase plan
2. `missing-tasks` — Phase tasks the engineer did not complete
3. `code-quality` — Style violations, readability issues, dead code
4. `edge-cases` — Boundary conditions or error paths not handled
5. `security` — Newly-introduced threats not covered by the phase plan's threat model
6. `professionalism` — Same bar as plan_validator

## Reclassification rules

When `<prior_findings>` is present:

- Each prior `id` MUST appear EITHER in the new `findings` array (with `prior_status: "carried"` or `prior_status: "reclassified"`) OR in the `reclassification` array.
- A prior finding marked `RESOLVED` in the reclassification array MUST NOT reappear in the new `findings` array. This is the "resolved must not reappear" rule (ZAP-24).
- Justifications for severity changes are required — schema enforces non-empty `justification`.

## Why this scaffold

- **Explicit category enumeration** is the load-bearing mechanism for exhaustive coverage. Without it, LLM reviewers default to `top`-N filtering even when prompted not to.
- **"No-findings" entries** force the reviewer to actively confirm absence rather than silently omit.
- **Trailing `<coverage>` block** lets the orchestrator detect missed categories mechanically.
- **Schema-anchored output** means the orchestrator never has to parse natural language to count findings.

## Calibration

The reference fixtures under `plugins/zapili/tests/fixtures/` seed one issue per family and document expected IDs/categories. Phase 4 development MUST run codex against every fixture before shipping any codex wrapper change; calibration passes when every fixture's `expected-findings.json` IDs all appear in the codex output.

**Note on ID determinism:** live calibration against codex-cli 0.133.0 (2026-05-28) confirmed that without the explicit SHA-256 formula above, the model invents non-deterministic IDs (incrementing hex sequences like `ISS-a1b2c3d4e5f6`, `ISS-b2c3d4e5f6a7`, ...) even when shown placeholder `ISS-...` examples. Fixture `f2-plan-write-overlap` reproduced this: codex correctly identified the `write-scope-overlap` issue but emitted `ISS-d4e5f6a7b8c9` instead of the expected `ISS-da83a9a75c86`. The "Finding ID derivation" section above was added to close that gap. Re-run calibration after any change to that section.
