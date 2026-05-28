# Fixture f2 — plan write-scope overlap (HIGH)

**Role:** `plan_validator`
**Seeded issue:** Both PHASE-XX-a and PHASE-XX-b list `src/auth/login.ts` in their `<files>` writes block and sit in the same wave.
**Expected ID:** `ISS-da83a9a75c86`
**Derivation:** `sha256("tests/fixtures/f2-plan-write-overlap/PLAN.md|8-25|write-scope-overlap")` → first-12 → `da83a9a75c86`.
**Pass criterion:** Codex output contains a finding with `id == "ISS-da83a9a75c86"` and severity `HIGH`.
