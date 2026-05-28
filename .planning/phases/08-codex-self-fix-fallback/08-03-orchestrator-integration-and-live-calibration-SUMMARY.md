# Plan 08-03: orchestrator integration + live calibration — SUMMARY

**Completed:** 2026-05-28
**Status:** done
**Files touched:** 4 (+ 6 calibration-transcript artifacts)

## Changes

| File | Operation | Summary |
|------|-----------|---------|
| `plugins/zapili/skills/orchestrator/SKILL.md` | modify | Inserted "### 6.1. Cap-hit codex-self-fix fallback (ZAP-60)" inside Stage 6 (plan-validate) and "#### 7c.1. Cap-hit codex-self-fix fallback (ZAP-60)" inside Stage 7c (per-wave fix loop). Both sub-sections dispatch `codex-self-fix.sh --dry-run` first → inspect exit code → apply (no --dry-run) → re-run the original validator → on clean continue / on still-HIGH halt with `## CODEX SELF-FIX EXHAUSTED` + finding IDs + patch path. Single-attempt rule (D-12) noted in both sites. Stage 7c's halt diagnostic gains a `Codex self-fix transcript:` line pointing to `.zapili/codex-self-fix-attempt-*.patch`. (D-09, D-10, D-11, D-12) |
| `plugins/zapili/scripts/codex-self-fix.sh` | modify | Two calibration-driven hardening passes: (1) prompt tightened to require unified-diff context format with a worked example (codex was emitting zero-context hunks that `git apply` rejects); (2) AWK-based whitespace-line trim on patch extraction (codex pretty-prints the closing `</patch>` tag with indentation, which was being parsed as a phantom hunk line). Both fixes converged on a working live round-trip. |
| `plugins/zapili/scripts/codex-review-phase.sh` | modify | Broadened phase-id regex from `PHASE-[0-9]+(-[0-9]+)?` to `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?` to mirror Phase 7 D-12 / ZAP-59 fix in `check-wave-disjointness.sh`. Without this, `codex-review-phase.sh` exits 64 on fixture-style phase ids (PHASE-XX), and the post-fix re-review path in the f6 round-trip cannot run. (Calibration-driven find; same latent class as ZAP-59) |
| `.planning/phases/08-codex-self-fix-fallback/live-codex-calibration-LOG.md` | create | Full transcript of the 4-iteration f6 round-trip: each iteration's command, codex output excerpt, `git apply --check` result, the calibration-driven fix between iterations, and the final successful run's post-fix re-review findings. Documents the dual-outcome acceptance (best-case + clean-halt) and proves the seeded HIGH finding `ISS-23ba7d51473d` was resolved. |
| `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/.zapili/codex-self-fix-attempt-1.*` (6 files) | create (force-added; `.zapili/` is gitignored at the root) | Permanent calibration evidence: the final iteration's prompt, raw codex JSONL, parsed output, generated patch, and `git apply --check` log (empty — exit 0). Re-running the f6 round-trip will rotate the attempt counter, preserving these historical transcripts. |

## Live calibration outcome — TL;DR

**PASS** on all 5 ZAP-60 acceptance criteria. The final live codex run produced this patch:

```diff
--- a/plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md
+++ b/plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/PHASE-XX.md
@@ -1,7 +1,8 @@
 # PHASE-XX — implement cache

-<files>{"writes": ["src/cache.kt"], "reads": []}</files>
+<files>{"writes": ["src/cache.kt", "src/cache.test.kt"], "reads": []}</files>

 ## Tasks

-1. Implement an in-memory hash-table cache with `put(key, value)` and `get(key)` in `src/cache.kt`.
+1. Implement an in-memory hash-table cache with `put(id, value)` and `get(id)` in `src/cache.kt`.
+2. Author unit tests in `src/cache.test.kt` covering insertion, eviction, and overflow for `ISS-23ba7d51473d`.
```

- `git apply --check` exit 0.
- Codex preserved the seeded `ISS-23ba7d51473d` verbatim (CALIB-01 honored).
- Codex incidentally fixed forbidden-vocabulary use (`key` → `id`).
- Post-fix re-review: the seeded HIGH finding is RESOLVED. Remaining findings shift to engineer-payload-level (which the orchestrator's normal Stage 7c fix-loop re-engineers in a real workflow).

## Acceptance gate

- `grep -c 'codex-self-fix' plugins/zapili/skills/orchestrator/SKILL.md` → 12 (both Stage 6.1 and Stage 7c.1 wired).
- `grep -n 'CODEX SELF-FIX EXHAUSTED' plugins/zapili/skills/orchestrator/SKILL.md` → 6 occurrences (3 halt paths per stage).
- `live-codex-calibration-LOG.md` documents the round-trip outcome.
- `plugins/zapili/tests/fixtures/f6-fix-loop-exhausted/.zapili/codex-self-fix-attempt-1.patch` exists and applies cleanly via `git apply --check`.

## Requirements closed

- ZAP-60 (all 5 acceptance criteria): COMPLETE.

## Decisions cited

D-09, D-10, D-11, D-12 (orchestrator integration); D-14, D-15 (live calibration). Also citing all of 08-CONTEXT D-01..D-08 transitively because the live calibration forced refinements to D-05 (prompt composition — added the worked example + unified-diff requirements) which feeds back into 08-01's wrapper.

## Calibration-driven follow-ups noted

1. **Latent regex class in production scripts.** Both `codex-review-phase.sh` (fixed here) and `check-wave-disjointness.sh` (fixed in Phase 7) shared the same narrow `PHASE-[0-9]+(-[0-9]+)?` regex. Any future script that parses PHASE-XX.md filenames should use `PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?` from the start. Worth a documentation note in `references/contracts.md` (deferred to v1.1 audit follow-up backlog).
2. **Codex prompt sensitivity to negative framing.** Iteration 3 showed that codex abdicates (empty patch) when faced with too many "this will be REJECTED" warnings; the working prompt uses positive direction + a worked example. This is a useful guideline for any future codex prompt: prefer positive direction, supply concrete examples.

<!-- <status>complete</status> -->
