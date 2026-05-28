# Calibration Fixtures

Five deliberately-flawed fixtures used to verify the exhaustive-review prompt scaffold (`plugins/zapili/skills/orchestrator/references/codex-prompts.md`) actually surfaces every seeded issue at first pass.

## Fixtures

| Fixture | Seeded severity | Issue category | Expected ID |
|---------|-----------------|----------------|-------------|
| `f1-research-contradiction/` | HIGH | `contradictions` (research_validator) | `ISS-cc94a3aa8710` |
| `f2-plan-write-overlap/` | HIGH | `parallel-safety` (plan_validator) | `ISS-da83a9a75c86` |
| `f3-plan-ambiguity/` | MEDIUM | `ambiguity` (plan_validator) | `ISS-a5efb5f14a26` |
| `f4-phase-missing-tests/` | MEDIUM | `missing-tasks` (phase_reviewer) | `ISS-3c9a191be875` |
| `f5-phase-style-drift/` | LOW | `code-quality` (phase_reviewer) | `ISS-4653b5e9bc97` |

## Layout convention

Each fixture directory contains:

- The input artifacts the reviewer reads (TASK.md, CONTEXT.md, PLAN.md, PHASE-XX.md, engineer-payload.json — whichever apply to that reviewer role)
- `expected-findings.json` — a `validation-findings` payload that the codex output MUST be a superset of (every ID in this file MUST appear in the codex output; extra findings are allowed and expected as LOW)
- `README.md` — describes the seeded issue and which reviewer role applies

## How Phase 4+ uses these

Once `plugins/zapili/scripts/codex-review.sh` exists (Phase 4):

```bash
for fixture in plugins/zapili/tests/fixtures/f*/; do
  bash plugins/zapili/scripts/codex-review.sh \
    --role "$(jq -r '.role' "$fixture/expected-findings.json")" \
    --inputs "$fixture" \
    --out /tmp/out.json
  expected=$(jq -r '.findings[].id' "$fixture/expected-findings.json" | sort -u)
  actual=$(jq -r '.findings[].id' /tmp/out.json | sort -u)
  missing=$(comm -23 <(echo "$expected") <(echo "$actual"))
  [ -z "$missing" ] || { echo "FAIL $fixture: missing IDs: $missing"; exit 1; }
done
```

## Calibration pass criterion

Every ID in `expected-findings.json` MUST appear in the codex output. Extra findings (especially LOW-severity ones) are acceptable — the contract is *exhaustive coverage*, not *minimum noise*. A failing calibration means the prompt scaffold or the reviewer prompts under `codex-prompts.md` need revision.

## Stable ID derivation

IDs are computed via the formula in `plugins/zapili/skills/orchestrator/references/contracts.md`:

```
ISS- + first-12-hex of sha256(file + "|" + line_range + "|" + kind)
```

The `file`, `line_range`, `kind` values used for each fixture's expected ID are documented inside the fixture's `README.md` so the calibration script can recompute IDs after any fixture relocation.

## Upstream contracts

- `plugins/zapili/schemas/validation-findings.schema.json` — every `expected-findings.json` validates against this.
- `plugins/zapili/skills/orchestrator/references/codex-prompts.md` — defines the reviewer roles, category lists, and the exhaustive-coverage contract.
