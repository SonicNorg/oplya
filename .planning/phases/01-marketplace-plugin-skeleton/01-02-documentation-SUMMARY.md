---
phase: 01-marketplace-plugin-skeleton
plan: 02
subsystem: docs

# Dependency graph
requires:
  - phase: 01-marketplace-plugin-skeleton
    plan: 01
    provides: "Manifests exist at .claude-plugin/marketplace.json and plugins/zapili/.claude-plugin/plugin.json so the README can confidently document the install path"
  - phase: 00-bootstrap
    provides: "CONTEXT.md locked decisions D-25 (top-level README section list), D-26 (plugin README section list + codex prereq + TASK.md stub + Phase-1 status disclaimer), D-27 (formatting constraints), D-06 (SonicNorg/oplya slug)"
provides:
  - "Top-level README.md surfaced on GitHub repo landing — describes marketplace identity, plugin index, install commands, local-dev workflow, license"
  - "plugins/zapili/README.md surfaced when inspecting the plugin tree — describes what zapili does, codex prerequisite, TASK.md authoring stub, Phase-1 status disclaimer, install cross-link"
  - "Documentary contract that Plan 04's install-hooks.sh and validate-manifests.sh must satisfy at the exact paths referenced in the Local development section"
  - "MKT-08/D-23 minimalism preserved — plugin tree contains exactly two leaves (plugin.json + README.md)"
affects: ["01-03-hygiene", "01-04-validator", "01-05-install-rehearsal", "02-session-hook-and-command"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CommonMark + fenced code blocks only — no badges, no screenshots, no TOC (D-27)"
    - "Cross-linking by relative path: top README links to plugins/zapili/README.md; plugin README links to ../../README.md#install"
    - "Documentation-as-contract: README references Plan 04 deliverables (scripts/install-hooks.sh, scripts/validate-manifests.sh) before they exist; Plan 04 must satisfy these exact paths"
    - "Forward-only Phase-1 disclaimer: plugin README's Status block-quote ships ONLY on Phase 1 commits; Phase 2 replaces it with the real command surface description"

key-files:
  created:
    - "README.md"
    - "plugins/zapili/README.md"
  modified: []

key-decisions:
  - "Added literal `/plugin install zapili@oplya` text inside the plugin README's Install section (alongside the D-26 cross-link to ../../README.md#install) — required because the plan's `<verify>` + `<acceptance_criteria>` automated checks grep for the literal `/plugin install` string, which a pure cross-link would not satisfy. Cross-link target preserved verbatim per D-26."
  - "Top-level README uses [`zapili`](plugins/zapili/README.md) as the table cell rather than wrapping the description in a link, keeping the cross-link prominent and satisfying the `grep -q 'plugins/zapili/README.md'` acceptance check on a single short line."
  - "Local development section includes the `claude plugin validate . --strict` supplementary check as a separate fenced one-liner (per RESEARCH Open Question Q3 recommendation) — documented as optional so it does not become a hard prerequisite for contributors."

patterns-established:
  - "README authoring discipline: write to plan-mandated sections D-25/D-26 verbatim; verify every acceptance criterion before commit; English-only per project CLAUDE.md hard rule (zero Cyrillic, no emoji)"
  - "Reconciling plan inconsistencies in-line: when `<verify>` automated greps require a literal string the prose section description does not produce, augment the section minimally rather than reshaping its structure"

requirements-completed: [MKT-03, ZAP-03]

# Metrics
duration: ~2 min
completed: 2026-05-28
---

# Phase 1 Plan 2: Documentation Summary

**English-only top-level and plugin READMEs ship per D-25/D-26 — `oplya` is now self-documenting for first-time visitors, the install path `/plugin marketplace add SonicNorg/oplya` + `/plugin install zapili@oplya` is published in both files, the `codex` CLI prerequisite is surfaced on the plugin README, and the Phase-1 "slash command not yet wired" disclaimer sets correct user expectations.**

## Performance

- **Duration:** ~2 min (95s wall-clock from start probe to second-task commit)
- **Started:** 2026-05-27T21:32:42Z
- **Completed:** 2026-05-27T21:34:17Z
- **Tasks:** 2 (both `type="auto"`, no checkpoints)
- **Files modified:** 2 (both created)

## Accomplishments

- `README.md` — top-level marketplace README in English, 37 lines, covering all six D-25 sections (H1 + description, Plugins table, Install fenced block, Local development with two scripts + optional `claude plugin validate . --strict`, License line) plus the mandated cross-link to `plugins/zapili/README.md`.
- `plugins/zapili/README.md` — plugin-local README in English, 32 lines, covering all five D-26 sections (H1 + description, Prerequisites bullet list including `codex` CLI + Claude Code v2.1.143+, TASK.md authoring stub with verbatim minimal example, Install cross-link to top-level README, Status block-quote with the Phase-1 disclaimer).
- All plan `<acceptance_criteria>` and the plan-level `<verification>` checks pass: both files exist, line counts under 90, no badges/screenshots/TOC, English-only (zero Cyrillic), cross-links point at real files, plugin tree still contains exactly two leaves (MKT-08/D-23 minimalism preserved).

## Task Commits

Each task was committed atomically:

1. **Task 1: Write top-level README.md** — `aef99ea` (feat)
2. **Task 2: Write plugins/zapili/README.md** — `73b7ae3` (feat)

**Plan metadata commit:** pending (this commit, see "Final Commit" below)

## Files Created/Modified

- `README.md` — 37 lines; sections: H1 + paragraph; `## Plugins` (table with one row, plugin name links to `plugins/zapili/README.md`, description uses D-08 wording); `## Install` (fenced block with the two literal commands + codex callout); `## Local development` (fenced bash block with `git clone`, `cd`, `./scripts/install-hooks.sh`, `./scripts/validate-manifests.sh` plus optional `claude plugin validate . --strict` supplementary); `## License` (single MIT line).
- `plugins/zapili/README.md` — 32 lines; sections: H1 + paragraph (multi-agent workflow framing); `## Prerequisites` (codex CLI + auth, Claude Code v2.1.143+); `## How to author a TASK.md` (one paragraph + verbatim minimal example from RESEARCH Example 10 + "full schema ships later" line); `## Install` (cross-link to `../../README.md#install` plus literal `/plugin install zapili@oplya` reference); `## Status` (block-quote Phase-1 disclaimer).

## D-25 / D-26 Section Checklist

**Top-level README (D-25):**
- [x] (1) H1 `# oplya — Claude Code Plugin Marketplace` + one-paragraph description with the user-approved framing
- [x] (2) `## Plugins` table with one row for `zapili`, description matches D-08 wording, plugin name links to `plugins/zapili/README.md`
- [x] (3) `## Install` fenced block with EXACTLY `/plugin marketplace add SonicNorg/oplya` then `/plugin install zapili@oplya` + codex callout (no URL-based marketplace add per RESEARCH Pitfall 5)
- [x] (4) `## Local development` fenced bash block with `git clone`, `cd`, `./scripts/install-hooks.sh`, `./scripts/validate-manifests.sh` + optional `claude plugin validate . --strict` supplementary check
- [x] (5) `## License` single line `MIT — see [LICENSE](LICENSE).`
- [x] (6) Cross-link from the Plugins table cell to `plugins/zapili/README.md`

**Plugin README (D-26):**
- [x] (1) H1 `# zapili` + description paragraph (multi-agent workflow + TASK.md + codex review)
- [x] (2) `## Prerequisites` bullet list including codex CLI + auth (with `codex --version`/OPENAI_API_KEY guidance) and Claude Code v2.1.143+
- [x] (3) `## How to author a TASK.md` one paragraph + minimal fenced example + "full schema ships later" line
- [x] (4) `## Install` cross-link `See the [marketplace README](../../README.md#install)` (augmented with literal `/plugin install zapili@oplya` to satisfy automated grep)
- [x] (5) `## Status` block-quote: "The slash command surface is not yet wired in this release..." (Phase-1 only; Phase 2 replaces)

## Decisions Made

- **Augmented plugin README Install with literal install command** — the plan's `<verify>` and `<acceptance_criteria>` both require `grep -q "/plugin install"` to succeed on `plugins/zapili/README.md`, but a pure cross-link (as written in D-26) would not produce the string. Added a one-line tail to the cross-link: "— once the `oplya` marketplace is added, install with `/plugin install zapili@oplya`." This preserves the D-26 cross-link structure verbatim while satisfying the automated acceptance gate. The cross-link to `../../README.md#install` remains the primary navigation; the literal command is a small convenience.
- **Optional `claude plugin validate . --strict` placed as a separate fenced one-liner in Local development** — per RESEARCH Open Question Q3 recommendation, the official validator is a useful supplementary check but should not become a hard prerequisite. Framed with "If you have the `claude` CLI installed, you can also run a deeper supplementary check:" so contributors without it are not gated.
- **Table cell links plugin name only, not description** — keeps the row scannable and surfaces the cross-link prominently. Description column carries the D-08 framing verbatim; the linkable token is `zapili` itself.

## Deviations from Plan

**1. [Rule 3 - Blocking] Plan acceptance criterion required literal `/plugin install` in plugin README that the D-26 cross-link alone did not produce**
- **Found during:** Task 2 verification
- **Issue:** The plan's `<acceptance_criteria>` for Task 2 includes `grep -q "/plugin install" plugins/zapili/README.md` exits 0, but D-26 mandates the Install section be a cross-link only (`See the [marketplace README](../../README.md#install).`). A pure cross-link does not contain the literal `/plugin install` string.
- **Fix:** Appended a one-line tail to the cross-link sentence: "— once the `oplya` marketplace is added, install with `/plugin install zapili@oplya`." Both the D-26 cross-link and the literal install command now coexist in the Install section. No other section changed.
- **Files modified:** `plugins/zapili/README.md`
- **Commit:** `73b7ae3`
- **Rationale:** This is a Rule 3 fix — without it the plan's own acceptance gate would not pass. The plan author appears to have intended the cross-link to suffice (the link's `#install` anchor points to a section that contains `/plugin install`), but the gate is text-level not link-resolution-level. Minimally augmenting the prose was lower-risk than relaxing the gate.

## Issues Encountered

- One transient confusion during Task 1 verification: a chained `... && ! grep -qE ... && echo OK` step in a single bash invocation exited 1 even though every individual check printed OK. Re-running the negation checks as separate statements showed they pass. Cause: shell `&&` chains can short-circuit on the boolean of the final `grep -q` invocation in subtle ways. Resolution: verified each check independently before commit; no impact on the actual file content.

## User Setup Required

None — no external service configuration required by this plan. Documentation files only.

## Threat Surface Scan

Reviewed both new files against the plan's `<threat_model>` register:

- **T-02-01 (Information Disclosure — wrong slug)** — mitigated. `grep -q "/plugin marketplace add SonicNorg/oplya" README.md` and `grep -q "../../README.md" plugins/zapili/README.md` both pass. The canonical slug `SonicNorg/oplya` is the only marketplace identifier used.
- **T-02-02 (Tampering — URL-based marketplace add suggestion)** — mitigated. Top-level README documents only the GitHub-shorthand form `/plugin marketplace add SonicNorg/oplya`; no URL-based alternative present (would break relative `source` paths per RESEARCH Pitfall 5).
- **T-02-03 (Repudiation — deferred slash command surface)** — mitigated. Plugin README's `## Status` block-quote explicitly states "The slash command surface is not yet wired in this release" — `grep -qi "not yet wired"` passes. Users on the Phase-1 commit will not file false bug reports about a missing `/zapili:zapili` command.
- **T-02-SC (Supply chain — package installs)** — N/A. No package-manager installs in this plan; Markdown files only.

No NEW threat surface introduced beyond the plan's existing register. No Threat Flags to raise.

## Next Phase Readiness

**Plan 01-03 (Hygiene):** READMEs do not block hygiene work. `.gitattributes` (with `*.md text eol=lf`) is recommended to add BEFORE further `.md` files land (RESEARCH Pitfall 11), but the two existing READMEs were authored with LF endings; verify with `file README.md plugins/zapili/README.md` after Plan 03 lands `.gitattributes` and renormalize if needed.

**Plan 01-04 (Validator + install-hooks installer):** The top-level README's Local development section now documents the EXACT paths `scripts/install-hooks.sh` and `scripts/validate-manifests.sh` — Plan 04 MUST deliver these scripts at exactly these paths. The README also documents the optional `claude plugin validate . --strict` supplementary check; Plan 04 does not need to implement this — it is a user-facing recommendation only.

**Plan 01-05 (Install rehearsal):** Top-level README's Install section publishes the canonical commands `/plugin marketplace add SonicNorg/oplya` and `/plugin install zapili@oplya`. The rehearsal must execute these EXACT strings against the Phase-1 commit on `main`.

**Phase 2 (SessionStart hook + slash command):** Plugin README's `## Status` block-quote is the line Phase 2 must replace. The replacement should describe the real `/zapili:zapili` orchestrator surface and remove the "not yet wired" disclaimer entirely. Reference: D-26 explicitly notes "this note ships only on the Phase-1 commit; Phase 2 replaces the line with the real command surface description."

**Open concerns:** None for downstream plans.

## Self-Check: PASSED

- File `README.md` exists — FOUND.
- File `plugins/zapili/README.md` exists — FOUND.
- Commit `aef99ea` (Task 1) — FOUND in `git log` (see "git log --all" verification below).
- Commit `73b7ae3` (Task 2) — FOUND in `git log`.
- Plan-level `<verification>` block: both files non-empty, English-only (zero Cyrillic), under 80 lines (37 and 32), no badges/screenshots/TOC, cross-links resolve, plugin tree leaf count is exactly 2.
- Per-task `<acceptance_criteria>` (Task 1 + Task 2): all assertions exit 0.

---
*Phase: 01-marketplace-plugin-skeleton*
*Completed: 2026-05-28*
