---
phase: 01
slug: marketplace-plugin-skeleton
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `scripts/validate-manifests.sh` (bash + `jq`) — no JS/Python test runner for v1 |
| **Config file** | `scripts/validate-manifests.sh` (the validator itself) |
| **Quick run command** | `bash scripts/validate-manifests.sh` |
| **Full suite command** | `bash scripts/validate-manifests.sh && bash scripts/test-validator.sh` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/validate-manifests.sh`
- **After every plan wave:** Run `bash scripts/validate-manifests.sh && bash scripts/test-validator.sh`
- **Before `/gsd:verify-work`:** Full suite must be green; perform live install rehearsal in a fresh clone
- **Max feedback latency:** ~3 seconds (offline JSON validation), ~30 seconds (full suite incl. malformed-input fixtures)

---

## Per-Task Verification Map

> The Phase 1 deliverables are static artifacts (JSON manifests, README files, license, hygiene files, validator script). Each task is verified by a deterministic shell command — no application runtime to mock.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | MKT-01 | — | `.claude-plugin/marketplace.json` is strict RFC 8259 JSON, validates against schema | unit | `jq -e . .claude-plugin/marketplace.json >/dev/null` | ❌ W0 | ⬜ pending |
| 01-01-02 | 01 | 1 | MKT-02 | — | Marketplace contains one plugin entry `zapili` with `source: ./plugins/zapili` | unit | `jq -e '.plugins[] \| select(.name=="zapili") \| .source == "./plugins/zapili"' .claude-plugin/marketplace.json` | ❌ W0 | ⬜ pending |
| 01-01-03 | 01 | 1 | MKT-03 | — | `plugins/zapili/.claude-plugin/plugin.json` is valid JSON with `name == "zapili"` and no `version` field (commit-SHA versioning) | unit | `jq -e '.name == "zapili" and (has("version") \| not)' plugins/zapili/.claude-plugin/plugin.json` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | MKT-04 | — | Top-level `README.md` exists, English, contains marketplace install + codex prerequisite | unit | `test -f README.md && grep -q "/plugin marketplace add" README.md && grep -qi "codex" README.md` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | MKT-04 | — | `plugins/zapili/README.md` exists, English, mentions `/zapili` slash command surface deferred to Phase 2 | unit | `test -f plugins/zapili/README.md && grep -q "/plugin install" plugins/zapili/README.md` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 1 | MKT-05 | — | `LICENSE` file at repo root (single SPDX-recognizable text) | unit | `test -f LICENSE && test -s LICENSE` | ❌ W0 | ⬜ pending |
| 01-03-02 | 03 | 1 | MKT-05 | — | `.gitignore` covers `.zapili/`, `.claude/cache/`, Node/Python/IDE/OS noise | unit | `grep -q "^\\.zapili/" .gitignore && grep -q "^\\.claude/cache/" .gitignore && grep -q "node_modules" .gitignore` | ❌ W0 | ⬜ pending |
| 01-03-03 | 03 | 1 | MKT-05 | — | `.gitattributes` enforces LF line endings for `*.sh`, `*.bash` | unit | `grep -qE '^\\*\\.sh[[:space:]]+text[[:space:]]+eol=lf' .gitattributes && grep -qE '^\\*\\.bash[[:space:]]+text[[:space:]]+eol=lf' .gitattributes` | ❌ W0 | ⬜ pending |
| 01-04-01 | 04 | 2 | MKT-06, MKT-08 | — | `scripts/validate-manifests.sh` exists, is executable, parses both manifests, exits 0 on valid input, surfaces ALL failures in a single pass (no `set -e` in the validation loop — Pitfall 7) | unit | `bash scripts/validate-manifests.sh; test $? -eq 0` | ❌ W0 | ⬜ pending |
| 01-04-02 | 04 | 2 | MKT-06 | — | Validator exits non-zero on malformed manifest (golden-bad fixture) | unit | `bash scripts/test-validator.sh` (uses fixtures from `scripts/fixtures/bad-*.json`) | ❌ W0 | ⬜ pending |
| 01-04-03 | 04 | 2 | MKT-08 | — | Pre-commit gate: `.git/hooks/pre-commit` (or documented opt-in command) invokes `scripts/validate-manifests.sh`; staged but malformed manifest blocks commit | manual+script | Documented in README "Local development" section; verified by running `git commit` with a deliberately broken manifest in a scratch branch | ❌ W0 | ⬜ pending |
| 01-05-01 | 05 | 3 | MKT-07, ZAP-03 | — | Live install rehearsal: `/plugin marketplace add <local-path-or-https>` succeeds with zero validation errors; `/plugin install zapili@oplya` resolves; `zapili` appears in `/plugin list` | manual | Manual rehearsal in a fresh Claude Code session (see Manual-Only Verifications below) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Phase 1 has no test framework to install — validation infrastructure IS the deliverable. Wave 0 here means "scaffolding required before the per-task verification commands can run":

- [ ] `scripts/validate-manifests.sh` — the validator itself (task 01-04-01); every JSON-validation row above depends on this script existing
- [ ] `scripts/test-validator.sh` — driver that runs the validator against `scripts/fixtures/bad-*.json` (golden-bad cases) and asserts non-zero exit (task 01-04-02)
- [ ] `scripts/fixtures/bad-missing-name.json`, `scripts/fixtures/bad-trailing-comma.json`, `scripts/fixtures/bad-invalid-source.json` — minimal malformed inputs
- [ ] `jq >= 1.6` — already present locally per research env probe; documented as prerequisite in README

*All Wave 0 items are explicit tasks in PLAN.md (04), not deferred work.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh-clone install via `/plugin marketplace add` succeeds in a real Claude Code session | MKT-07 | Requires a live Claude Code runtime; loader behavior cannot be faithfully scripted without invoking the real client | 1. `git clone <oplya-repo> /tmp/oplya-rehearsal && cd /tmp/oplya-rehearsal` <br> 2. Start fresh Claude Code session in that directory <br> 3. `/plugin marketplace add .` (or GitHub `owner/repo` shorthand) — expect zero errors, marketplace appears in `/plugin marketplace list` <br> 4. `/plugin install zapili@oplya` — expect "installed" confirmation, `zapili` appears in `/plugin list` <br> 5. (Phase 1 stops here — `/zapili:zapili` invocation deferred to Phase 2) |
| Pre-commit gate actually blocks malformed manifests | MKT-08 | Pre-commit hooks run in the user's local git environment; verifying the wiring requires an actual `git commit` against a real staged change | 1. On a scratch branch, deliberately corrupt `.claude-plugin/marketplace.json` (e.g., add trailing comma) <br> 2. `git add .claude-plugin/marketplace.json && git commit -m "test"` <br> 3. Expect commit refused with validator error message on stderr <br> 4. Restore original manifest |
| `claude plugin validate --strict` passes on the assembled marketplace | MKT-01, MKT-03 | Cross-check against the live Claude Code validator surfaces schema drifts (e.g., `owner.url` warning flagged in research) that the project's offline validator may not catch | `claude plugin validate . --strict` from repo root; `claude plugin validate ./plugins/zapili --strict` from repo root — both must report no warnings |

---

## Validation Sign-Off

- [ ] All tasks have an automated `jq` / `test` / `grep` verification command OR an explicit Manual-Only entry above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (all automated except the two manual install-rehearsal items, both isolated to Wave 3)
- [ ] Wave 0 covers all MISSING references (validator + fixtures + driver script)
- [ ] No watch-mode flags (validator is single-shot exit-code-driven by contract — D-13)
- [ ] Feedback latency < 5s (quick run); < 30s (full suite)
- [ ] `nyquist_compliant: true` set in frontmatter once all tasks land green

**Approval:** pending
