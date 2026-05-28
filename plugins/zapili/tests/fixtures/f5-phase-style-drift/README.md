# Fixture f5 — Kotlin file with Java idioms (LOW)

**Role:** `phase_reviewer`
**Seeded issue:** Kotlin file uses Java `Optional<String>` and manual `if (x != null)` checks instead of Kotlin `String?` + idiomatic null-safety.
**Expected ID:** `ISS-4653b5e9bc97`
**Derivation:** `sha256("tests/fixtures/f5-phase-style-drift/engineer-payload.json|4-10|mixed-language-style")` → first-12 → `4653b5e9bc97`.
**Pass criterion:** Finding with that ID at severity `LOW`.
