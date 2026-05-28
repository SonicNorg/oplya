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

## How the calibration loop runs

The Phase 4 wrappers (`codex-validate-research.sh`, `codex-validate-plan.sh`,
`codex-review-phase.sh`) have role-specific signatures — there is no generic
`--role`/`--inputs`/`--out` driver. The loop below dispatches each fixture to
its matching wrapper, lets the wrapper persist its `.zapili/<role>-attempt-N.json`
output, then asserts every expected `ISS-...` id appears in the actual output.

```bash
set -euo pipefail
FIX=plugins/zapili/tests/fixtures
fail=0

run() {
  # $1 = fixture dir, $2 = absolute path to wrapper output the last invocation produced
  expected=$(jq -r '.findings[].id' "$1/expected-findings.json" | sort -u)
  actual=$(jq -r '.findings[].id' "$2" | sort -u)
  missing=$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true)
  if [ -n "$missing" ]; then
    printf 'FAIL %s: missing IDs:\n%s\n' "$1" "$missing"
    fail=1
  else
    printf 'PASS %s\n' "$1"
  fi
}

# Wrappers append .zapili/<role>-attempt-N.json; we capture the latest after each invocation.
latest() { ls -1t "$1"/*.json 2>/dev/null | head -n1; }

# f1 — research_validator: codex-validate-research.sh <task_md> <context_md>
( cd "$FIX/f1-research-contradiction" \
  && bash ../../../scripts/codex-validate-research.sh TASK.md CONTEXT.md )
run "$FIX/f1-research-contradiction" "$(latest "$FIX/f1-research-contradiction/.zapili")"

# f2, f3 — plan_validator: codex-validate-plan.sh <plan_md> <phase_glob>
for f in f2-plan-write-overlap f3-plan-ambiguity; do
  ( cd "$FIX/$f" \
    && bash ../../../scripts/codex-validate-plan.sh PLAN.md 'PHASE-*.md' )
  run "$FIX/$f" "$(latest "$FIX/$f/.zapili")"
done

# f4, f5 — phase_reviewer: codex-review-phase.sh <task_md> <phase_md> <engineer_payload>
for f in f4-phase-missing-tests f5-phase-style-drift; do
  ( cd "$FIX/$f" \
    && bash ../../../scripts/codex-review-phase.sh TASK.md PHASE-XX.md engineer-payload.json )
  run "$FIX/$f" "$(latest "$FIX/$f/.zapili")"
done

exit "$fail"
```

The `smoke-small-task` fixture is exercised end-to-end via the orchestrator skill
(`/zapili:zapili`), not via the per-role wrappers — see `smoke-small-task/README.md`
for that procedure.

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
