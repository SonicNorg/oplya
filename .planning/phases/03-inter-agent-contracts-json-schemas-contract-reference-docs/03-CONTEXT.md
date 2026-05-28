# Phase 3: Inter-agent contracts — JSON Schemas + contract reference docs - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning
**Mode:** Auto-generated for autonomous execution (smart-discuss skipped — decisions derived from ROADMAP success criteria + REQUIREMENTS ZAP-10..15 + CLAUDE.md canonical references)

<domain>
## Phase Boundary

Every machine-parseable payload exchanged between the orchestrator, subagents, and codex is defined by a JSON Schema (draft 2020-12). The XML envelope spec, task-sizing thresholds, and exhaustive-review prompt scaffold are authored as the single source of truth that all downstream phases (4, 5, 6) consume. A small calibration corpus of deliberately-flawed fixtures validates that the review prompt surfaces every seeded issue at first pass.

**In scope:**
- `plugins/zapili/schemas/` — four JSON Schemas:
  - `validation-findings.schema.json`
  - `research-questions.schema.json`
  - `phase-changes.schema.json`
  - `state.schema.json`
- `plugins/zapili/skills/orchestrator/references/` — three reference docs:
  - `contracts.md` (XML envelope, stable issue ID hashing, payload-size budget, forbidden vocabulary)
  - `task-sizing.md` (numeric thresholds verbatim per ZAP-13)
  - `codex-prompts.md` (exhaustive-review scaffold + reclassification block)
- `plugins/zapili/tests/fixtures/` — 3–5 deliberately-flawed sample plans/diffs (one fixture per seeded-issue category) + a matching "expected-findings" sidecar per fixture
- `plugins/zapili/tests/fixtures/README.md` — calibration usage notes

**Out of scope (later phases):**
- Orchestrator skill body, codex wrapper scripts, researcher/planner/engineer prompts (Phase 4+)
- Live codex invocations against the fixtures (calibration evidence is documented — actual run happens during Phase 4 development)
- Schema versioning beyond `$schema_version: 1` (no breaking-change machinery yet)

</domain>

<decisions>
## Implementation Decisions

### Schemas (ZAP-10)
- **D-01:** All schemas use JSON Schema draft 2020-12 (`"$schema": "https://json-schema.org/draft/2020-12/schema"`). Stable as of 2026; widely supported.
- **D-02:** Each schema has `$id` set to `https://oplya.dev/zapili/schemas/<name>.schema.json` (stable URI — does not need to resolve; identifies the schema).
- **D-03:** Each schema has `"type": "object"`, `"additionalProperties": false`, and an explicit `"required"` array — strict by default so contract violations crash early at validation time. No optional fields are silently allowed.
- **D-04:** Versioning: every schema includes `"schema_version": {"const": 1}` as a required property in the validated object (NOT at the schema root — `const` constraints on the data itself). This is the per-payload version tag agents must emit. Future breaks bump `const: 2` plus an `oneOf` over the version field.
- **D-05:** `validation-findings.schema.json` — payload shape:
  ```json
  {
    "schema_version": 1,
    "findings": [
      {
        "id": "<sha256-12-of-(file|line_range|kind)>",
        "severity": "HIGH" | "MEDIUM" | "LOW",
        "category": "<one of an enumerated list>",
        "file": "<repo-relative path or null>",
        "line_range": "<line or line-line>",
        "kind": "<short kind label>",
        "summary": "<one sentence>",
        "remediation": "<one-to-three sentences>",
        "prior_status": "new" | "carried" | "resolved" | "reclassified" | null
      }
    ],
    "coverage": {
      "files_reviewed": ["<repo-relative path>"],
      "categories_checked": ["<category>"]
    },
    "reclassification": [
      {
        "id": "<prior id>",
        "new_severity": "HIGH" | "MEDIUM" | "LOW" | "RESOLVED",
        "justification": "<one sentence>"
      }
    ]
  }
  ```
  Required at the payload root: `schema_version`, `findings`, `coverage`. `reclassification` is required only when a prior-issue list was provided to the reviewer (the schema enforces presence in that case via documentation; orchestrator-side check at runtime).
- **D-06:** `research-questions.schema.json` — payload shape:
  ```json
  {
    "schema_version": 1,
    "task_size": "small" | "medium" | "large" | "gigantic",
    "size_rationale": "<one to three sentences>",
    "questions": [
      {
        "id": "Q1" | "Q2" | ...,
        "topic": "<short label>",
        "question": "<the question itself>",
        "context": "<file references + line ranges that anchor the question>",
        "default_if_unanswered": "<the assumption the planner will make if the user does not answer>"
      }
    ]
  }
  ```
  Question count is bounded by `task_size` (per ZAP-13 thresholds) — small 3–4, medium 5–8, large 9–12, gigantic 13–20. Schema enforces `minItems`/`maxItems` via `oneOf` on `task_size`.
- **D-07:** `phase-changes.schema.json` — payload shape:
  ```json
  {
    "schema_version": 1,
    "phase_id": "<e.g. 03-01>",
    "attempt": <1, 2, or 3>,
    "files_touched": [
      {
        "path": "<repo-relative>",
        "operation": "create" | "modify" | "delete",
        "summary": "<one sentence>"
      }
    ],
    "decisions": [
      {
        "id": "DEC-<n>",
        "title": "<short label>",
        "rationale": "<one to three sentences>",
        "alternatives_considered": "<one to three sentences or null>"
      }
    ],
    "change_summary": "<one paragraph>"
  }
  ```
  Required: all five. `alternatives_considered` may be `null` explicitly.
- **D-08:** `state.schema.json` — payload shape (`.zapili/state.json`):
  ```json
  {
    "schema_version": 1,
    "task_path": "<repo-relative path to TASK.md>",
    "current_stage": "research" | "research_validate" | "plan" | "plan_validate" | "wave_execute" | "wave_review" | "wave_fix" | "summarize" | "complete",
    "current_wave": <int or null>,
    "current_phase": "<phase-id or null>",
    "iteration_counters": {
      "research_validate": <int>,
      "plan_validate": <int>,
      "per_phase_fix": {"<phase-id>": <int>}
    },
    "issue_ids": {
      "research_validate": ["<id>"],
      "plan_validate": ["<id>"],
      "per_phase_review": {"<phase-id>": ["<id>"]}
    },
    "started_at": "<ISO-8601 timestamp>",
    "updated_at": "<ISO-8601 timestamp>"
  }
  ```
  Required: `schema_version`, `task_path`, `current_stage`, `started_at`, `updated_at`. Other fields are required at the data level but may be empty arrays/objects.

### Schema self-tests (ZAP-10 acceptance)
- **D-09:** Each schema ships a sibling `<name>.valid.json` and `<name>.invalid.json` fixture alongside the schema (under `plugins/zapili/schemas/examples/`). A small `scripts/validate-schemas.sh` runs `ajv` if installed (graceful fallback to `python3 -c "import jsonschema; ..."` if ajv missing; final fallback: print a clear "no JSON Schema validator available, install ajv-cli or python jsonschema" message and exit 1). The script is invoked by the user during development — not pre-commit-gated in v1.
- **D-10:** The script's exit-zero is the calibration evidence — no live codex round-trip in Phase 3.

### XML envelope + contract reference (ZAP-11, ZAP-12)
- **D-11:** Envelope shape for orchestrator → subagent or orchestrator → codex:
  ```xml
  <request>
    <role>researcher | planner | engineer | research_validator | plan_validator | phase_reviewer</role>
    <task>...prose context, file refs, prior findings...</task>
    <expected_response_schema>https://oplya.dev/zapili/schemas/<name>.schema.json</expected_response_schema>
  </request>
  ```
  Envelope shape for the response:
  ```xml
  <response>
    <reasoning>...short prose explanation, one paragraph max...</reasoning>
    <payload>{ "schema_version": 1, ... }</payload>
  </response>
  ```
  Payload MUST be a single JSON object inside `<payload>` tags. Reasoning is prose; payload is machine-parseable.
- **D-12:** Stable issue ID rule (ZAP-12): `sha256(file + "|" + line_range + "|" + kind)`, take first 12 hex chars, prefix `ISS-`. So an issue at `src/auth.ts:42-58` with kind `null-dereference` has the same ID across iterations — this anchors prior-issue carry-forward.
- **D-13:** Payload-size budget (ZAP-12): soft cap of 10,000 tokens per engineer prompt. Orchestrator estimates token count via `len_chars / 4` heuristic (cheap, no tokenizer dependency) and warns the user if exceeded; does NOT hard-fail (would create infinite-loop hazards).
- **D-14:** Forbidden review-prompt vocabulary (ZAP-12): the literal strings `key`, `main`, `top`, `important` are forbidden in review prompts — they cue LLMs toward top-N filtering. The contract doc lists these verbatim and instructs prompt authors to use neutral phrasing ("all", "every category", "exhaustive coverage").

### Task-sizing reference (ZAP-13)
- **D-15:** Numeric thresholds verbatim:
  | Class | LOC | Modules | Questions | Phases |
  |-------|-----|---------|-----------|--------|
  | small | ≤100 | 1–3 | 3–4 | 1 (plan only) |
  | medium | ≤500 | 1–5 | 5–8 | plan + 3–4 phases |
  | large | ≤1000 | 2–8 | 9–12 | plan + 5–8 phases |
  | gigantic | >1000 | — | 13–20 | plan + 9–20 phases |
- **D-16:** "Modules" = top-level packages/directories (e.g. `src/auth/`, `plugins/zapili/scripts/`). LOC = additions + modifications (deletions don't count). The reference doc spells out both definitions.

### Codex review prompt scaffold (ZAP-14)
- **D-17:** Mandatory structure of every codex review prompt:
  1. `<role>` — one of the review roles (`research_validator`, `plan_validator`, `phase_reviewer`)
  2. `<inputs>` — list of files + their roles (TASK.md, CONTEXT.md, PLAN.md, PHASE-XX.md, prior findings)
  3. `<categories>` — explicit enumeration of categories to check (per review role). Reviewer MUST emit findings for every listed category, including "no findings" entries.
  4. `<output_contract>` — references `validation-findings.schema.json` and forbids the words `key`, `main`, `top`, `important`. Mandates trailing `<coverage>` block.
  5. `<prior_findings>` (optional) — when non-empty, mandates a `<reclassification>` block in the response.
- **D-18:** Per-role category lists:
  - `research_validator`: contradictions, missing context, hallucinated references, scope creep, ambiguity
  - `plan_validator`: contradictions, gaps, ambiguity, parallel-safety (write-scope disjointness), completeness vs phase goal, architectural fit, OOP/DRY/KISS adherence, professionalism
  - `phase_reviewer`: contradictions vs plan, missing tasks, code quality, edge cases, security/threat-model coverage, professionalism

### Fixtures (ZAP-15)
- **D-19:** Five fixtures (one per seeded-issue family):
  - `f1-research-contradiction/` — TASK.md vs CONTEXT.md contradiction (seeded HIGH)
  - `f2-plan-write-overlap/` — PHASE-XX-a writes `src/foo.ts`, PHASE-XX-b also writes `src/foo.ts` in same wave (seeded HIGH)
  - `f3-plan-ambiguity/` — PHASE-XX.md task description has two incompatible interpretations (seeded MEDIUM)
  - `f4-phase-missing-tests/` — engineer change_summary claims test coverage, files_touched has no test files (seeded MEDIUM)
  - `f5-phase-style-drift/` — code in `files_touched` summary describes Kotlin code with mixed Java/Kotlin conventions (seeded LOW)
- **D-20:** Each fixture directory contains: the input files (TASK.md / CONTEXT.md / PLAN.md / PHASE-XX.md / engineer payload), an `expected-findings.json` (the codex review should produce findings matching these IDs/categories), and a per-fixture `README.md` explaining the seeded issue.
- **D-21:** `tests/fixtures/README.md` documents the calibration workflow: how to run `codex` against each fixture during Phase 4 development and what counts as a passing calibration (every `expected-findings.json` entry must appear in the codex output).

### Skeleton minimalism (carry-forward from Phase 1 D-23)
- **D-22:** Phase 3 creates `plugins/zapili/schemas/`, `plugins/zapili/skills/orchestrator/references/`, and `plugins/zapili/tests/fixtures/` directory trees. No `.gitkeep` placeholders — every leaf is a real file.
- **D-23:** `plugin.json` is NOT edited. The `skills/orchestrator/SKILL.md` file is NOT created in Phase 3 (the directory exists only because `references/` is nested under it; Phase 4 creates `SKILL.md` when the orchestrator body is authored). Default auto-discovery only fires when `SKILL.md` exists.

### Plan structure
- **D-24:** Phase 3 is medium-sized (~600–1000 LOC across schemas, docs, and fixtures). Two-wave structure expected:
  - **Wave 1 (parallel-safe):**
    - Plan 03-01 — schemas + schema examples + validate-schemas.sh
    - Plan 03-02 — three reference docs (contracts/task-sizing/codex-prompts)
  - **Wave 2 (depends on Wave 1):**
    - Plan 03-03 — five fixtures + fixtures README (must reference schemas + reference docs)
  Wave 1 plans have disjoint file scopes (schemas vs reference docs); Wave 2 reads both.

### Claude's Discretion
- Exact wording inside reference docs (must satisfy D-11 envelope, D-12 ID rule, D-13 budget, D-14 forbidden words, D-15 thresholds, D-17/D-18 scaffold)
- Exact fixture content as long as each fixture seeds the issue family specified in D-19 and ships the three artifacts in D-20
- Whether `validate-schemas.sh` lives under `plugins/zapili/scripts/` or top-level `scripts/` (recommended: plugin-local `plugins/zapili/scripts/validate-schemas.sh` to preserve MKT-08)
- Exact category lists in `codex-prompts.md` may add categories beyond D-18; must not remove them

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning context (MANDATORY)
- `.planning/REQUIREMENTS.md` — ZAP-10..15 verbatim
- `.planning/ROADMAP.md` § "Phase 3: Inter-agent contracts" — phase goal, success criteria, dependencies
- `.planning/phases/02-.../02-CONTEXT.md` — Phase 2 outcomes (preflight + command shell + script hygiene)
- `.planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md` — manifest discipline (D-10 — no commands/agents/hooks/mcpServers keys to edit)

### Research summary (HIGH-confidence)
- `.planning/research/SUMMARY.md` § "Inter-agent contracts" + § "Codex review prompt scaffold"
- `.planning/research/STACK.md` — concrete XML+JSON snippets
- `.planning/research/PITFALLS.md` § "Top-N filtering" + § "Forbidden vocabulary"

### Project-level instructions
- `CLAUDE.md` § "Inter-agent contracts" + § "What NOT to Use" (Russian forbidden, top-N forbidden)

### External (live spec — planner re-fetches at planning time)
- JSON Schema draft 2020-12 — `https://json-schema.org/draft/2020-12/release-notes`
- Anthropic prompt-engineering guidance on XML tags — `docs.claude.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags`
- OpenAI codex exec `--output-schema` flag — `developers.openai.com/codex/noninteractive`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/validate-manifests.sh` (Phase 1) is the bash + jq pattern reference for `validate-schemas.sh` — same shebang, `set -euo pipefail`, jq/ajv discipline.
- `plugins/zapili/scripts/check-codex.sh` (Phase 2) shows the "graceful fallback when an external tool is missing" pattern — apply same idiom in `validate-schemas.sh` for ajv→python jsonschema→hard-fail fallback.

### Established Patterns
- LF + mode 0755 already enforced via `.gitattributes` + Phase 2 plan discipline.
- No `commands`/`hooks`/`agents`/`mcpServers` keys in `plugin.json` — default auto-discovery only fires when component files exist. Phase 3 creates `schemas/`, `tests/`, and `skills/orchestrator/references/` — none of these are auto-discovered loaders themselves (loader only discovers `commands/`, `agents/`, `hooks/`, `skills/<name>/SKILL.md`). Phase 3 ships zero new loadable components.

### Integration Points
- New trees under `plugins/zapili/`: `schemas/`, `tests/fixtures/`, `skills/orchestrator/references/`. None of these conflict with Phase 1 or Phase 2 outputs.
- `validate-schemas.sh` may live at `plugins/zapili/scripts/validate-schemas.sh` (sibling of `check-codex.sh` / `preflight-codex.sh`).

</code_context>

<specifics>
## Specific Ideas

- The fixtures' `expected-findings.json` files are themselves a contract — they enforce that future changes to the review prompt scaffold do not regress calibration. Phase 4's codex wrapper will use them as the smoke test.
- `state.schema.json` is intentionally rich (iteration_counters + issue_ids nested per phase/wave) because Phase 4 needs to persist exactly this shape; deferring fields creates a Phase-4 schema-rev churn risk.
- The forbidden-vocabulary list in `contracts.md` is the load-bearing piece of the entire exhaustive-coverage property — call it out in bold in the doc.

</specifics>

<deferred>
## Deferred Ideas

- JSON Schema breaking-change machinery (oneOf over `schema_version`) — defer until v2 contract change
- Pre-commit gate that runs `validate-schemas.sh` automatically — Phase 6 polish
- Auto-generated TypeScript types from the schemas — out of scope (no TS in v1)
- A web-rendered schema browser / docs site — UX-01 (v2)

</deferred>
