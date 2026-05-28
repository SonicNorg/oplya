# Fixture f1 — research contradiction (HIGH)

**Role:** `research_validator`
**Seeded issue:** TASK.md mandates `jsonwebtoken@8.x` and forbids new auth deps; CONTEXT.md introduces `jose@5.x`. Hard contradiction.
**Expected ID:** `ISS-cc94a3aa8710`
**Derivation:**

```
sha256("tests/fixtures/f1-research-contradiction/CONTEXT.md|12-15|context-task-contradiction")
  → first 12 hex → cc94a3aa8710
```

**Pass criterion:** Codex output contains a finding with `id == "ISS-cc94a3aa8710"` and severity `HIGH`.
