# Inter-Agent Contracts

> Source of truth for every machine-parseable exchange between the zapili orchestrator, its subagents, and codex. Phase 4+ prompts and wrappers MUST cite this document.

## XML envelope

Every prompt the orchestrator sends to a subagent or to codex uses this shape:

```xml
<request>
  <role>researcher | planner | engineer | research_validator | plan_validator | phase_reviewer</role>
  <task>
    Free-form prose: context, file references, prior findings (if any).
  </task>
  <expected_response_schema>https://oplya.dev/zapili/schemas/&lt;name&gt;.schema.json</expected_response_schema>
</request>
```

Every response MUST conform to:

```xml
<response>
  <reasoning>
    One paragraph (≤200 words). Prose explanation of how the payload was derived.
  </reasoning>
  <payload>{ "schema_version": 1, ... JSON object matching the schema referenced in &lt;expected_response_schema&gt; ... }</payload>
</response>
```

- `<payload>` MUST be a single JSON object — not an array, not multiple objects, not a wrapper.
- `<reasoning>` is informational. The orchestrator parses `<payload>` only.
- All text is English. Other languages are forbidden in contracts (CLAUDE.md).

## Stable issue IDs

Every finding emitted by any reviewer (research_validator, plan_validator, phase_reviewer) carries a stable, reproducible ID so prior-issue carry-forward (ZAP-24) works.

**Formula (verbatim):**

```
ISS- + first-12-hex-chars-of   sha256(file + "|" + line_range + "|" + kind)
```

Where:
- `file` is the repo-relative path the issue points at, or the string `null` when the issue is global.
- `line_range` is a string like `"42"` or `"42-58"` — never an integer, never a structured object.
- `kind` is a short, stable label (e.g. `null-dereference`, `write-scope-overlap`, `missing-test`).

Example: an issue at `src/auth.ts:42-58` with kind `null-dereference` always hashes to the same `ISS-...` ID. Re-running the reviewer on the same input MUST emit the same ID.

Reference shell snippet:

```bash
printf '%s|%s|%s' "$file" "$line_range" "$kind" \
  | sha256sum | awk '{print "ISS-" substr($1,1,12)}'
```

## Payload-size soft budget

Each engineer prompt has a **soft** cap of **10,000 tokens** (also written **10000 tokens** in machine contexts). The orchestrator estimates token count via the cheap heuristic:

```
estimated_tokens = floor(len(prompt_chars) / 4)
```

- If `estimated_tokens > 10000`: emit a WARNING to the user and proceed.
- Never hard-fail on budget. Hard-failing would create infinite loops when a phase legitimately needs more context.

## Forbidden review-prompt vocabulary

Review prompts MUST NOT use these literal words (they cue LLMs toward top-N filtering and break the exhaustive-coverage property):

```
key
main
top
important
```

Use these neutral replacements instead:

| Forbidden | Replacement |
|-----------|-------------|
| `key` findings | `all` findings / `every` finding |
| `main` issues | `all` issues across `every` category |
| `top` priorities | `all priorities (HIGH+MEDIUM+LOW)` |
| `important` items | `all` items / `exhaustive coverage` |

The list above is the only place in `contracts.md` and `codex-prompts.md` where the forbidden words may appear in prose — and they are always quoted in code-fence syntax to make their forbidden-list status mechanical.

## Schema registry

The four schemas governed by this document:

| Purpose | `$id` |
|---------|-------|
| Codex review payload | `https://oplya.dev/zapili/schemas/validation-findings.schema.json` |
| Researcher question batch | `https://oplya.dev/zapili/schemas/research-questions.schema.json` |
| Engineer change payload | `https://oplya.dev/zapili/schemas/phase-changes.schema.json` |
| Orchestrator state cache | `https://oplya.dev/zapili/schemas/state.schema.json` |

Self-test: `bash plugins/zapili/scripts/validate-schemas.sh` exits 0 iff every schema validates its `.valid.json` and rejects its `.invalid.json`.

## Versioning

- Each payload carries `"schema_version": 1`.
- Schemas enforce the version via `"const": 1`.
- A breaking change bumps `const` to 2 and extends each schema with `oneOf` over the version field (deferred — not implemented in v1).
