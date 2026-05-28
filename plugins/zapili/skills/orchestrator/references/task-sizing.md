# Task Sizing

> Source of truth for task-size classification and the resulting question-batch + phase-count caps. The researcher subagent classifies every incoming TASK.md against this table and emits `task_size` in its `research-questions` payload.

## Thresholds (verbatim — do not paraphrase)

| Class | LOC | Modules | Questions | Phases |
|-------|-----|---------|-----------|--------|
| `small` | ≤ 100 | 1–3 | 3–4 | 1 (plan only, no phase files) |
| `medium` | ≤ 500 | 1–5 | 5–8 | plan + 3–4 phases |
| `large` | ≤ 1000 | 2–8 | 9–12 | plan + 5–8 phases |
| `gigantic` | > 1000 | — | 13–20 | plan + 9–20 phases |

These thresholds are also encoded mechanically in `research-questions.schema.json` (`oneOf` per `task_size`) so a researcher emitting an out-of-range question count fails schema validation.

## Definitions

- **LOC**: counts **additions + modifications** only. Pure deletions (e.g. removing dead code) do not contribute to the LOC count, since the cognitive load of designing a deletion is decoupled from line-count magnitude.
- **Modules**: top-level packages/directories that contain code or config the task will touch. Examples: `src/auth/`, `plugins/zapili/scripts/`, `apps/web/components/`. Counting one module per file inflates trivial multi-file edits into "medium" — use the package-level granularity instead.

## Classification procedure (researcher's playbook)

1. Read `TASK.md` and any referenced source files / docs.
2. Estimate LOC delta and the set of modules likely to be touched.
3. Choose the smallest class whose LOC and modules columns BOTH accommodate the estimate. When in doubt between two adjacent classes, pick the smaller one — the orchestrator can re-classify upward if codex research-validation flags scope creep.
4. Emit `task_size` plus a `size_rationale` (≤3 sentences) so the user can sanity-check the call.

## Why these specific numbers

- **100 LOC / 4 questions (small)**: matches a typical single-endpoint or single-component change; 3–4 questions is the threshold above which user fatigue costs more than the additional precision.
- **500 LOC / 8 questions (medium)**: matches a multi-file feature within one bounded context; phase split into 3–4 phases keeps each phase under ~150 LOC.
- **1000 LOC / 12 questions (large)**: matches a multi-module feature crossing 2+ bounded contexts; 5–8 phases enables parallel waves.
- **>1000 LOC / 20 questions (gigantic)**: matches a milestone-sized change; phases proliferate but each phase still under ~120 LOC by construction. Above 20 questions, the task should be split externally (multiple TASK.md files) — the researcher SHOULD recommend a split in its `size_rationale`.

## Phases per class — wave structure consequences

| Class | Typical wave count | Notes |
|-------|--------------------|-------|
| small | 1 wave, 1 plan | No `PHASE-XX.md` files; PLAN.md alone is sufficient. |
| medium | 1–2 waves | Wave 2 only if a phase depends on Wave-1 output. |
| large | 2–3 waves | Parallel waves only when write-scopes are mechanically disjoint (ZAP-41). |
| gigantic | 3+ waves | Always re-validate disjointness; consider splitting into milestones. |
