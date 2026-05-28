# Add a /health endpoint to the API

**Stack:** Node 20 + Express + TypeScript.
**Constraint:** Must not pull in any new dependencies.
**Reference:** see `src/api/server.ts` for the existing router shape.

## Acceptance

1. `GET /health` returns 200 with `{ "ok": true }`.
2. The endpoint is registered before the catch-all 404 handler.
3. The new route file is `src/api/routes/health.ts` and is exported from `src/api/routes/index.ts`.
4. Add one unit test in `src/api/routes/health.test.ts` covering the happy path.

That's the entire scope. Estimated change: ≤30 LOC across 3 files (small class per `task-sizing.md`).
