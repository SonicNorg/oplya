---
phase: 01-marketplace-plugin-skeleton
plan: 03
subsystem: infra
tags: [license, mit, gitignore, gitattributes, hygiene, line-endings, spdx]

# Dependency graph
requires:
  - phase: 01-marketplace-plugin-skeleton
    provides: "Manifests (Plan 01) and READMEs (Plan 02) — LICENSE referenced by `license: MIT` field in plugin.json and by the README license line"
provides:
  - "LICENSE (MIT, 2026, Pavel <pavel.proger@gmail.com>) — verbatim OSI text; SPDX `MIT` identifier matches"
  - ".gitignore covering eight D-21 categories (zapili runtime, Claude cache, OS, IDE, Node, Python, env)"
  - ".gitattributes enforcing LF endings on *.sh / *.bash (mandatory) and *.json / *.md (consistency); binary markers for *.png / *.jpg"
affects: [01-04-validator, 01-05-pre-commit, 02-session-hook, all-future-shell-scripts]

# Tech tracking
tech-stack:
  added:
    - "MIT License (OSI canonical template)"
    - ".gitignore (curated D-21 categories)"
    - ".gitattributes (LF normalization on text formats)"
  patterns:
    - "Verbatim OSI license text — preserves SPDX detector matching"
    - "`.gitattributes` lands BEFORE any *.sh file (RESEARCH Pitfall 11 — attributes only normalize on future commits)"
    - "Top-level LICENSE only — no per-plugin duplication (D-20)"

key-files:
  created:
    - "LICENSE — MIT 2026 Pavel <pavel.proger@gmail.com>, verbatim OSI text"
    - ".gitignore — 8 D-21 categories, 38 patterns total"
    - ".gitattributes — 6 LF-text patterns + 2 binary markers"
  modified: []

key-decisions:
  - "LICENSE uses verbatim OSI MIT text (no paraphrase) so SPDX `MIT` identifier matches and license-detection tools render correctly"
  - "`.claude/` directory itself stays tracked (project settings); only `.claude/cache/` is ignored — prevents accidentally hiding the .claude-plugin manifests on contributor machines"
  - "Discretionary `.gitattributes` additions (`*.json`, `*.md`, `*.png`, `*.jpg`) included for cross-platform consistency on top of the mandatory `*.sh` / `*.bash` lines"
  - "All three files committed in a single Wave 1 ahead of Plan 04 — `.gitattributes` lands before any `scripts/*.sh` is added to avoid CRLF lock-in"

patterns-established:
  - "Hygiene-file ordering: license → ignore → attributes, then everything else"
  - "Pure ASCII / UTF-8 / LF for every text file in the marketplace; no BOM"
  - "Security mitigations encoded as filesystem invariants (T-03-01 via `.env` ignore; T-03-02 via `*.sh eol=lf`)"

requirements-completed: [MKT-04, MKT-05, MKT-06]

# Metrics
duration: 1min
completed: 2026-05-28
---

# Phase 1 Plan 3: Hygiene Summary

**MIT LICENSE (verbatim OSI, 2026, Pavel), `.gitignore` covering eight D-21 categories, and `.gitattributes` enforcing LF on `*.sh` / `*.bash` — committed in that order before any shell scripts land (RESEARCH Pitfall 11).**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-05-27T21:38:14Z
- **Completed:** 2026-05-27T21:39:11Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments

- MIT license established at the canonical top-level path with the exact OSI template, year 2026, holder `Pavel <pavel.proger@gmail.com>` — SPDX `MIT` identifier and `license: "MIT"` in `plugin.json` now match a detectable source.
- `.gitignore` covers all eight D-21 categories: zapili runtime state, Claude Code per-plugin cache, OS noise, editor/IDE noise, Node, Python, and env files (including `.env*` patterns that mitigate accidental secret commits, T-03-01).
- `.gitattributes` locks `*.sh` and `*.bash` to LF endings — committed in Wave 1, strictly before Plan 04's `scripts/*.sh` files land, so the first add normalizes correctly with no later `git add --renormalize` ceremony required (T-03-02 mitigation; RESEARCH Pitfall 11).

## Task Commits

Each task was committed atomically:

1. **Task 1: Write LICENSE (MIT verbatim)** — `7253f2e` (feat)
2. **Task 2: Write .gitignore** — `36a29b6` (feat)
3. **Task 3: Write .gitattributes** — `7481500` (feat)

**Plan metadata commit:** pending (final commit with this SUMMARY + STATE + ROADMAP).

## Files Created/Modified

- `LICENSE` — Verbatim OSI MIT license text, year 2026, holder `Pavel <pavel.proger@gmail.com>` (D-01)
- `.gitignore` — 38 patterns across 8 sectioned categories (D-21); `.claude/` itself stays tracked
- `.gitattributes` — Mandatory `*.sh` / `*.bash` LF (D-22), discretionary `*.json` / `*.md` LF, binary markers for `*.png` / `*.jpg`

## Decisions Made

- **Discretionary LF additions in `.gitattributes`:** Added `*.json text eol=lf` and `*.md text eol=lf` (D-22 explicitly permits planner discretion). Rationale — every text file in the marketplace is committed by exactly one author working on Linux/macOS; explicit LF on the format-stable files prevents accidental CRLF drift if a contributor ever uses a Windows editor. Cost: two lines.
- **Binary markers (`*.png binary`, `*.jpg binary`):** Included per RESEARCH Example 5. No binary assets ship in v1, but the markers cost nothing and prevent git from attempting text-merge on any future screenshot or icon (deferred UX-01 idea).
- **`.claude/cache/` not `.claude/`:** Verified via the explicit negative acceptance criterion (`! grep -q "^\.claude/$"`). The `.claude/` directory at repo root carries project-level Claude settings that downstream contributors need.
- **No duplicate LICENSE in `plugins/zapili/`:** Verified via the negative acceptance check (`! test -f plugins/zapili/LICENSE`). D-20 keeps MKT-08 (no cross-plugin reuse) orthogonal from license placement.

## Deviations from Plan

None — plan executed exactly as written. All three tasks passed their `<automated>` verify blocks and `<acceptance_criteria>` on first attempt. Zero auto-fixes, zero blocked tasks.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 04 (validator) unblocked:** `.gitattributes` is in place, so the upcoming `scripts/validate-manifests.sh` and `scripts/install-hooks.sh` will be added with LF endings on first commit (no `--renormalize` ceremony needed).
- **Plan 05 (`claude plugin validate --strict`) unblocked:** LICENSE file with verbatim OSI text will satisfy license-detection without warnings.
- **Phase 1 success criterion 5 satisfied:** `LICENSE`, `.gitignore`, `.gitattributes` are present and enforced.
- **Requirements completed:** MKT-04 (LICENSE), MKT-05 (.gitignore), MKT-06 (.gitattributes + LF enforcement).

## Self-Check: PASSED

Verified:
- `LICENSE` exists, non-empty, matches all acceptance criteria (MIT, 2026 Pavel, OSI verbatim, AS IS clause, no plugin duplicate, LF).
- `.gitignore` exists, all 8 D-21 categories present, `.claude/` itself not ignored.
- `.gitattributes` exists, mandatory `*.sh` / `*.bash` LF patterns present, file itself is LF.
- Commits `7253f2e`, `36a29b6`, `7481500` present in `git log`.

---
*Phase: 01-marketplace-plugin-skeleton*
*Completed: 2026-05-28*
