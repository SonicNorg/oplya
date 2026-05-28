# Smoke test — small-class TASK.md round-trip

This fixture exercises the full single-phase zapili pipeline manually. Use it whenever you change anything in `skills/orchestrator/SKILL.md`, the codex wrappers, or the engineer / researcher / planner subagent prompts.

## Procedure

1. **Sandbox:** create a scratch git repo somewhere outside this project (`mkdir /tmp/zapili-smoke && cd /tmp/zapili-smoke && git init`). Drop a stub `src/api/server.ts` with an Express router (the TASK.md treats it as pre-existing context).
2. **Install zapili in that sandbox:** `/plugin marketplace add <path-or-github-slug>` then `/plugin install zapili@oplya`.
3. **Drop the TASK.md:** copy this directory's `TASK.md` into the sandbox root.
4. **Run:** `/zapili:zapili`.
5. **Answer researcher questions:** there should be 3–4 questions (small class). Answer each one; the orchestrator writes `CONTEXT.md`.
6. **Wait for plan-validate:** codex reviews PLAN.md + PHASE-01.md. Should produce ≤2 LOW findings on first pass.
7. **Phase 5 engineer round-trip:** engineer creates `src/api/routes/health.ts`, `src/api/routes/index.ts` (if missing), `src/api/routes/health.test.ts`. The orchestrator writes `PHASE-01-attempt-1.md` next to PHASE-01.md.
8. **Per-phase review:** codex reviews the attempt; on clean, the workflow advances. On HIGH/MEDIUM, a fresh engineer spawn iterates with the prior attempt + findings.

## Expected on-disk after a successful run

- `CONTEXT.md` — researcher findings + user answers, sentinel present
- `PLAN.md` — wave structure, sentinel present
- `PHASE-01.md` — single phase with `<files>{"writes": ["src/api/routes/health.ts", "src/api/routes/index.ts", "src/api/routes/health.test.ts"], "reads": ["src/api/server.ts"]}</files>`
- `PHASE-01-attempt-1.md` — engineer envelope + payload, sentinel present
- `src/api/routes/health.ts`, `src/api/routes/index.ts`, `src/api/routes/health.test.ts` — actual code changes
- `.zapili/state.json` — `current_stage` advanced (Phase 5 halt: `"summarize"` once Phase 5/6 fully wired; in this release: still reflects the latest completed stage)
- `.zapili/researcher-output.json`, `.zapili/research-validate-attempt-1.json`, `.zapili/plan-validate-attempt-1.json`, `.zapili/phase-01-review-attempt-1.json`

## Expected halt message in this release

After the per-phase review converges, the orchestrator prints the Phase-6 halt diagnostic (wave parallel fan-out + summary aggregator + resume hardening are Phase 6 work).

## Calibration crosscheck

Use this fixture before merging anything that touches `skills/orchestrator/` or `agents/`. If the round-trip diverges from the above expectations, treat that as a regression to fix before the change ships.
