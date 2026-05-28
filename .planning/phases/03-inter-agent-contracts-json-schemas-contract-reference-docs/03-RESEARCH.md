# Phase 3: Inter-agent contracts - Research

**Researched:** 2026-05-28
**Domain:** JSON Schema draft 2020-12 authoring + Anthropic XML envelope conventions + exhaustive-review prompt design + codex `--output-schema` compatibility
**Confidence:** HIGH (all answers anchored in CONTEXT D-01..D-23 + CLAUDE.md + REQUIREMENTS ZAP-10..15)

<user_constraints>
All 23 decisions in 03-CONTEXT.md are locked. This research surfaces the live-spec details the planner needs to author the files.
</user_constraints>

<recommended_approach>
## Stack

| Element | Choice | Rationale |
|---------|--------|-----------|
| JSON Schema dialect | draft 2020-12 | Stable, ajv-supported, codex `--output-schema` understands it |
| Schema location | `plugins/zapili/schemas/` | Default discovery (Phase 1 D-22 — no manifest edits needed) |
| Reference doc location | `plugins/zapili/skills/orchestrator/references/` | Co-located with future orchestrator SKILL.md (Phase 4) |
| Fixture location | `plugins/zapili/tests/fixtures/` | Spec-mandated (ZAP-15) |
| Stable issue ID | `ISS-` + first-12 hex of `sha256(file + "\|" + line_range + "\|" + kind)` | Reproducible across iterations; collision-resistant in scope |
| Token estimator | `len(chars) / 4` | Cheap heuristic; no tokenizer dependency |
| Schema validator | `ajv` (preferred) → python `jsonschema` (fallback) → hard-fail | Mirrors check-codex.sh graceful-fallback pattern |

</recommended_approach>

<code_examples>

### 1. `validation-findings.schema.json` skeleton (key portion)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://oplya.dev/zapili/schemas/validation-findings.schema.json",
  "title": "Validation Findings",
  "type": "object",
  "additionalProperties": false,
  "required": ["schema_version", "findings", "coverage"],
  "properties": {
    "schema_version": { "const": 1 },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "severity", "category", "summary", "remediation"],
        "properties": {
          "id":   { "type": "string", "pattern": "^ISS-[0-9a-f]{12}$" },
          "severity":  { "enum": ["HIGH", "MEDIUM", "LOW"] },
          "category":  { "type": "string", "minLength": 1 },
          "file":      { "type": ["string", "null"] },
          "line_range":{ "type": ["string", "null"] },
          "kind":      { "type": "string", "minLength": 1 },
          "summary":   { "type": "string", "minLength": 1 },
          "remediation":{ "type": "string", "minLength": 1 },
          "prior_status": { "enum": ["new", "carried", "resolved", "reclassified", null] }
        }
      }
    },
    "coverage": {
      "type": "object",
      "additionalProperties": false,
      "required": ["files_reviewed", "categories_checked"],
      "properties": {
        "files_reviewed":    { "type": "array", "items": { "type": "string" } },
        "categories_checked":{ "type": "array", "items": { "type": "string" } }
      }
    },
    "reclassification": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "new_severity", "justification"],
        "properties": {
          "id":            { "type": "string", "pattern": "^ISS-[0-9a-f]{12}$" },
          "new_severity":  { "enum": ["HIGH", "MEDIUM", "LOW", "RESOLVED"] },
          "justification": { "type": "string", "minLength": 1 }
        }
      }
    }
  }
}
```

### 2. `research-questions.schema.json` size-aware item count

Use `oneOf` keyed on `task_size`:

```json
{
  "oneOf": [
    { "properties": { "task_size": {"const": "small"},    "questions": {"minItems": 3, "maxItems": 4 } } },
    { "properties": { "task_size": {"const": "medium"},   "questions": {"minItems": 5, "maxItems": 8 } } },
    { "properties": { "task_size": {"const": "large"},    "questions": {"minItems": 9, "maxItems": 12} } },
    { "properties": { "task_size": {"const": "gigantic"}, "questions": {"minItems": 13,"maxItems": 20} } }
  ]
}
```

### 3. `validate-schemas.sh` skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

SCHEMAS_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}/schemas"
EXAMPLES_DIR="$SCHEMAS_DIR/examples"

if command -v ajv >/dev/null 2>&1; then
  VALIDATOR=ajv
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' 2>/dev/null; then
  VALIDATOR=python
else
  printf '[validate-schemas] no validator available. Install one of:\n  npm install -g ajv-cli\n  pip install jsonschema\n' >&2
  exit 1
fi

fail=0
for s in "$SCHEMAS_DIR"/*.schema.json; do
  base=$(basename "$s" .schema.json)
  valid="$EXAMPLES_DIR/$base.valid.json"
  invalid="$EXAMPLES_DIR/$base.invalid.json"
  for kind in valid invalid; do
    file="$EXAMPLES_DIR/$base.$kind.json"
    [ -f "$file" ] || { printf '[validate-schemas] missing: %s\n' "$file" >&2; fail=1; continue; }
    case "$VALIDATOR" in
      ajv)
        if ajv validate -s "$s" -d "$file" >/dev/null 2>&1; then result=valid; else result=invalid; fi ;;
      python)
        if python3 -c "import json,sys,jsonschema; jsonschema.validate(json.load(open(sys.argv[1])), json.load(open(sys.argv[2])))" "$file" "$s" 2>/dev/null; then result=valid; else result=invalid; fi ;;
    esac
    expected=$kind
    if [ "$result" != "$expected" ]; then
      printf '[validate-schemas] FAIL: %s expected=%s got=%s\n' "$file" "$expected" "$result" >&2
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then printf '[validate-schemas] ok: all schemas + examples pass\n'; fi
exit "$fail"
```

### 4. Forbidden-vocabulary check (one-liner)

```bash
grep -nP '\b(key|main|top|important)\b' plugins/zapili/skills/orchestrator/references/codex-prompts.md && exit 1 || exit 0
```

This is a planner-side guardrail — `codex-prompts.md` itself must NOT contain those literal words anywhere in its prose (the doc explains they are forbidden via alternative phrasing).

</code_examples>

<common_pitfalls>
1. **`additionalProperties: true` by default** — JSON Schema's default permissiveness leaks fields silently. ALL schemas MUST set `additionalProperties: false` (D-03).
2. **`"$id"` resolving to a 404** — `$id` is a logical identifier, not a URL. The URI `https://oplya.dev/zapili/schemas/...` need not exist; tooling does not fetch it unless you ask.
3. **`oneOf` without exclusivity** — for the size-aware question-count rule, `oneOf` only works because the `task_size` `const` values are mutually exclusive. Using `anyOf` would silently accept overlapping branches.
4. **Hashing line ranges as integers** — the issue ID hash MUST treat `line_range` as a string (`"42-58"`, not `42`/`58`). Otherwise re-spaced changes shift IDs and break carry-forward.
5. **Counting deletions in LOC** — task-sizing LOC is additions+modifications only (D-16). Counting deletions inflates trivial refactors into "large".
6. **Including forbidden vocabulary in the doc that forbids it** — `codex-prompts.md` itself must avoid the literal words `key/main/top/important` outside the explicit "forbidden words: ..." enumeration (use backticks around them when listing).
7. **Storing fixtures as a single JSON blob per fixture** — directory-per-fixture (D-19/D-20) keeps each input file separately diffable; a single blob hides intent.

</common_pitfalls>

<open_questions>
1. **Q1: Should the engineer subagent's payload include the diff itself?** — NO. `phase-changes.schema.json` carries `files_touched` + `summary` only. The full diff is observable via `git diff` after the engineer's edits land; embedding it in the payload doubles token cost. Decided in D-07.
2. **Q2: Should category lists in `codex-prompts.md` be locked or extensible?** — LOCKED for v1. D-18 names them; downstream phases may add categories ONLY by editing this doc (which is itself the contract). No per-invocation overrides.
3. **Q3: Are fixtures committed or generated?** — COMMITTED. Each fixture lives at `plugins/zapili/tests/fixtures/f<N>-<slug>/` as static files plus `expected-findings.json`. Generation introduces an extra dependency and removes the human-inspectability requirement.

</open_questions>

<sources>
- CONTEXT.md D-01..D-23 (locked)
- JSON Schema draft 2020-12 release notes
- Anthropic prompt-engineering — XML tags
- OpenAI codex CLI noninteractive reference (`--output-schema`)
- Phase 2 `scripts/preflight-codex.sh` (graceful fallback idiom)
</sources>
