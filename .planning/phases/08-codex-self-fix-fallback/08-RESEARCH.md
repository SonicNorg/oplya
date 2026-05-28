# Phase 8 Research

**Compiled:** 2026-05-28
**Novelty:** MEDIUM — new codex role (`fixer`) + unified-diff contract are new surfaces. Wave 2 orchestrator wiring + live calibration is a known pattern (mirrors Phase 5 wrapper integration + Phase 7 v1.0 audit calibration).

## Surface map

| Surface | Reference | New work |
|---------|-----------|----------|
| `codex-self-fix.sh` | `codex-review-phase.sh` (prompt + prior-findings interpolation pattern) | `<patch>...</patch>` extraction (perl -0777); `git apply --check` pre-flight; `--dry-run` flag; attempt-N auto-counter for `.patch` files |
| `fixer` role in `codex-prompts.md` | `phase_reviewer` section as the closest sibling | Single-purpose contract — no `<categories>`, response shape is a unified diff not a findings JSON |
| Orchestrator Stage 6 + Stage 7c | Phase 7's Stage 5.5 insertion pattern (Markdown sub-section) | Cap-hit detection + self-fix dispatch + post-fix re-validate + halt diagnostic |
| f6 fixture | `f4-phase-missing-tests/` (closest content-shape sibling) | First fixture with a `prior-findings.json` input (not `expected-findings.json` output) — drives the fixer, doesn't validate it |

## Risk areas

1. **Unified-diff path stability.** Codex 0.133.0 may emit diffs with absolute paths, with mismatched context, with trailing-whitespace damage, or in `--git` style vs. plain `diff -u` style. The `git apply --check` pre-flight catches all of these and forces a clean exit-4. The live calibration run in Plan 08-03 documents the actual shape codex emits.
2. **Single-attempt cap (D-12).** Self-fix is dispatched ONCE per validator cap-hit. If it fails to produce a clean re-validate, the workflow halts. This is intentional: the human inspects before any further automation runs.
3. **f6 acceptance is dual-outcome.** "Codex solves it" and "codex can't solve it, script halts cleanly" are BOTH passing outcomes. The script's halt-on-empty-patch path (exit 1) and halt-on-malformed-diff path (exit 4) are equally valuable proofs of contract; the LOG records which one fired.
4. **Cross-fixture file references in the patch.** The fixer prompt includes the artifact's verbatim path as it appears in `<inputs>`. For f6 the artifact path is `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md`. The patch must use that exact path in its `--- a/` / `+++ b/` headers. Mitigation: run the round-trip from inside the fixture dir so codex sees a short relative path, and apply via `git apply --directory=` or in a tmpdir copy.

## Calibration approach (Plan 08-03)

The full transcript (prompt, raw JSONL, parsed patch, dry-run output, post-fix re-review) lives in `live-codex-calibration-LOG.md`. Persistence of EVERY artifact is the discipline established in the v1.0 audit (CB-02 codex JSONL shape discovery) — re-running calibration is cheap when the prior transcript is on disk.

## Termination contract recap

| Condition | Exit code (script) | Orchestrator response |
|-----------|--------------------|------------------------|
| Patch generated, dry-run passes, apply succeeds, re-validate clean | 0 | Continue workflow |
| Patch generated, re-validate still HIGH | 0 (from script) | Halt with `## CODEX SELF-FIX EXHAUSTED` + finding IDs |
| Empty patch from codex | 1 | Halt with `## CODEX SELF-FIX EXHAUSTED — no diff produced` |
| Codex invocation failed | 2 | Halt with codex-side diagnostic |
| `git apply --check` rejected the patch | 4 | Halt with patch path + `git apply --check` stderr |

<!-- <status>complete</status> -->
