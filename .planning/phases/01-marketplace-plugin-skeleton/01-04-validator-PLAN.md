---
phase: 01-marketplace-plugin-skeleton
plan: 04
type: execute
wave: 2
depends_on:
  - 01-01
  - 01-02
  - 01-03
files_modified:
  - scripts/validate-manifests.sh
  - scripts/install-hooks.sh
  - scripts/pre-commit
  - scripts/test-validator.sh
  - scripts/fixtures/bad-missing-name.json
  - scripts/fixtures/bad-trailing-comma.json
  - scripts/fixtures/bad-invalid-source.json
autonomous: true
requirements:
  - MKT-07
  - MKT-08
must_haves:
  truths:
    - "scripts/validate-manifests.sh exits 0 against the manifests delivered by Plan 01"
    - "Validator surfaces ALL failures in one pass — no `set -e` in the validation loop (RESEARCH Pitfall 7)"
    - "Validator exits 1 with clear remediation when jq is missing on the host (D-15)"
    - "scripts/install-hooks.sh is idempotent: byte-identical hook → no-op; differing hook → diff + abort (D-18)"
    - "scripts/pre-commit only runs the validator when staged files include a .claude-plugin/*.json manifest (D-17)"
    - "scripts/test-validator.sh asserts the validator reports ≥2 failures against fixtures that break 2 fields (RESEARCH Pitfall 7 detection)"
    - "Validator lives at marketplace top-level (scripts/), not inside plugins/zapili/ (D-11 — preserves MKT-08)"
    - "CONTEXT.md decisions implemented by this plan: D-12 (validator scope — minimal required-field checks only), D-13 (exit code 0=ok / 1=fail), D-14 (shell discipline: bash shebang, `set -uo pipefail`, mode 0755, LF endings), D-16 (installer dispatches scripts/pre-commit into .git/hooks/), D-19 (installer is opt-in, discovered through Plan 02's README)"
  artifacts:
    - path: "scripts/validate-manifests.sh"
      provides: "Bash + jq validator for marketplace.json + every plugins/*/.claude-plugin/plugin.json"
      contains: "jq -e"
    - path: "scripts/install-hooks.sh"
      provides: "Idempotent installer that wires scripts/pre-commit into .git/hooks/pre-commit"
      contains: "cmp -s"
    - path: "scripts/pre-commit"
      provides: "Template hook copied into .git/hooks/ — invokes validator only when manifests are staged"
      contains: "git diff --cached --name-only"
    - path: "scripts/test-validator.sh"
      provides: "Driver that asserts the validator reports the expected number of failures against fixtures"
      contains: "scripts/fixtures/bad-"
    - path: "scripts/fixtures/bad-missing-name.json"
      provides: "Golden-bad fixture: plugin.json without a name field"
    - path: "scripts/fixtures/bad-trailing-comma.json"
      provides: "Golden-bad fixture: marketplace.json with trailing comma (jq parse fails)"
    - path: "scripts/fixtures/bad-invalid-source.json"
      provides: "Golden-bad fixture: marketplace.json plugin entry with `../` in source"
  key_links:
    - from: "scripts/pre-commit"
      to: "scripts/validate-manifests.sh"
      via: "exec invocation when manifest files staged"
      pattern: "exec \\./scripts/validate-manifests\\.sh"
    - from: "scripts/install-hooks.sh"
      to: "scripts/pre-commit"
      via: "cp + chmod into .git/hooks/pre-commit"
      pattern: "cp \"\\$SRC\" \"\\$DST\""
    - from: "scripts/test-validator.sh"
      to: "scripts/validate-manifests.sh"
      via: "invokes validator against fixtures, counts failure lines"
      pattern: "scripts/validate-manifests\\.sh"
---

<objective>
Deliver the marketplace-level validation infrastructure: a bash + jq validator, a fixture-driven test driver, an idempotent pre-commit installer, and the hook template. This is Phase 1's only required "automated gate" per CONTEXT.md and the only deliverable that produces runnable code (everything else is static JSON/Markdown).

Purpose: Without this plan, every other plan's manifest-quality claims are unverified. The validator IS the per-commit gate that catches malformed manifests before they reach `/plugin marketplace add`. The installer + hook template are the opt-in dev-loop wiring documented in Plan 02's `README.md`.

Output:
- `scripts/validate-manifests.sh` — parse + required-field check, surfaces ALL failures in one pass, exit 0/1.
- `scripts/install-hooks.sh` — idempotent installer that refuses to clobber a user-customized hook.
- `scripts/pre-commit` — hook template invoked from `.git/hooks/pre-commit` (only runs validator when manifests are staged).
- `scripts/test-validator.sh` — driver that asserts the validator reports ≥1 failure per broken fixture.
- `scripts/fixtures/bad-*.json` — three golden-bad fixtures exercising distinct failure modes (parse, missing field, invalid source).

Sequencing: this plan is Wave 2 (depends on Plans 01–03). Plan 03's `.gitattributes` MUST be in place before any `.sh` is committed here (RESEARCH Pitfall 11).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md
@.planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md
@.planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md
@.planning/phases/01-marketplace-plugin-skeleton/01-01-SUMMARY.md
@.planning/phases/01-marketplace-plugin-skeleton/01-03-SUMMARY.md
@CLAUDE.md
@.claude-plugin/marketplace.json
@plugins/zapili/.claude-plugin/plugin.json
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write scripts/validate-manifests.sh</name>
  <files>scripts/validate-manifests.sh</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-11 through D-15 — validator location, checks, exit codes, shell discipline, jq-missing remediation)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 6 (canonical implementation to follow line-for-line)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Common Pitfalls" Pitfall 7 (no `set -e` in validation loop) and Pitfall 10 (jq missing → exit 1 with remediation)
    - .planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md § "Per-Task Verification Map" task 01-04-01 (verify command to satisfy)
  </read_first>
  <action>
    Create the `scripts/` directory and write `scripts/validate-manifests.sh` following RESEARCH Example 6 verbatim shape. After writing, set executable bit with `chmod +x scripts/validate-manifests.sh`.

    Shell discipline (D-14):
    - Shebang: `#!/usr/bin/env bash`
    - Pragmas: `set -uo pipefail` — explicitly NOT `set -e` per RESEARCH Pitfall 7 (the validation loop MUST surface all failures, not abort at first).
    - LF line endings (`.gitattributes` from Plan 03 enforces this on add).
    - Mode: 0755.

    Behavior (D-12, D-13, D-15):
    1. Up-front `command -v jq` check; if missing, print to stderr `error: jq is required (install: 'brew install jq' / 'apt install jq' / 'dnf install jq')` and `exit 1` (NOT exit 2 — D-15 — and not silently skip).
    2. Define an `errors=0` counter and a `fail()` function that prints `FAIL: $*` to stderr and increments the counter.
    3. Define `check_json <file>` that returns nonzero (and increments errors via `fail`) if file is missing or `jq -e . <file>` fails.
    4. Define `require_field <file> <jq-path>` that fails if `jq -e <jq-path> <file>` returns nonzero.
    5. Marketplace validation: `MARKETPLACE=".claude-plugin/marketplace.json"`; if `check_json` passes, run `require_field` for `.name`, `.owner.name`, `.plugins`, then verify `.plugins | type == "array"`.
    6. Per-plugin validation: `shopt -s nullglob; for manifest in plugins/*/.claude-plugin/plugin.json; do check_json "$manifest" && require_field "$manifest" '.name'; done; shopt -u nullglob`.
    7. Final: if `errors -gt 0`, print `validation failed: $errors error(s)` to stderr and `exit 1`; else print `ok: all manifests valid` and `exit 0`.

    Quote every `"$file"` / `"$manifest"` expansion to handle paths with spaces. Do NOT use `eval`. Do NOT call out to network. Do NOT validate fields beyond `name`, `owner.name`, `plugins[]`-as-array on marketplace.json and `.name` on each plugin.json — D-12 explicitly scopes the validator to minimal required-field checks; deeper validation is the `claude plugin validate --strict` supplementary check (mentioned in Plan 02's README).
  </action>
  <verify>
    <automated>test -x scripts/validate-manifests.sh && bash scripts/validate-manifests.sh && grep -qE '^set -uo pipefail' scripts/validate-manifests.sh && ! grep -qE '^set -[a-z]*e[a-z]*' scripts/validate-manifests.sh && grep -q 'command -v jq' scripts/validate-manifests.sh && grep -q 'errors=$((errors + 1))' scripts/validate-manifests.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f scripts/validate-manifests.sh && test -x scripts/validate-manifests.sh` exits 0 (D-14 mode 0755).
    - `bash scripts/validate-manifests.sh; test $? -eq 0` (VALIDATION map task 01-04-01 — passes against Plan 01's good manifests).
    - `head -1 scripts/validate-manifests.sh | grep -qE '^#!/usr/bin/env bash'` exits 0 (D-14 shebang).
    - `grep -qE '^set -uo pipefail' scripts/validate-manifests.sh` exits 0 (D-14 pragmas).
    - `! grep -qE '^set -[a-z]*e[a-z]*( |$)' scripts/validate-manifests.sh` (RESEARCH Pitfall 7 — no `set -e` that would short-circuit the loop).
    - `grep -q 'command -v jq' scripts/validate-manifests.sh` exits 0 (D-15 jq probe).
    - `grep -q 'plugins/\*/\.claude-plugin/plugin\.json' scripts/validate-manifests.sh || grep -q 'plugins/\*/.claude-plugin/plugin.json' scripts/validate-manifests.sh` exits 0 (per-plugin loop present).
    - `file scripts/validate-manifests.sh | grep -qv CRLF` (LF endings — Plan 03's `.gitattributes` enforces this on add).
  </acceptance_criteria>
  <done>Validator script exists, is executable, exits 0 against the in-repo manifests, follows D-14 shell discipline, and avoids `set -e` in the validation loop per Pitfall 7.</done>
</task>

<task type="auto">
  <name>Task 2: Write fixtures and scripts/test-validator.sh</name>
  <files>scripts/fixtures/bad-missing-name.json, scripts/fixtures/bad-trailing-comma.json, scripts/fixtures/bad-invalid-source.json, scripts/test-validator.sh</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md § "Wave 0 Requirements" (fixture file list)
    - .planning/phases/01-marketplace-plugin-skeleton/01-VALIDATION.md § "Per-Task Verification Map" task 01-04-02 (driver invocation)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Common Pitfalls" Pitfall 7 (Pitfall 7 detection — deliberately break TWO fields, count error lines, expect ≥2)
    - scripts/validate-manifests.sh (Task 1 — defines what failure messages look like)
  </read_first>
  <action>
    Create `scripts/fixtures/` and write three golden-bad fixtures exercising distinct failure modes:

    1. `scripts/fixtures/bad-missing-name.json` — valid JSON shaped like a plugin.json BUT with `name` field absent. Minimal content: `{"displayName": "broken"}`. Tests: `require_field` for `.name` fires.
    2. `scripts/fixtures/bad-trailing-comma.json` — INVALID JSON (trailing comma) shaped like a marketplace.json. Content: `{"name": "broken", "owner": {"name": "x"}, "plugins": [{"name": "y", "source": "./y"},],}`. Tests: `jq -e .` parse fails.
    3. `scripts/fixtures/bad-invalid-source.json` — valid JSON BUT contains a `plugins[].source` starting with `../` (RESEARCH Pitfall 4 — explicitly forbidden by spec). Content: `{"name": "broken", "owner": {"name": "x"}, "plugins": [{"name": "y", "source": "../bad/y"}]}`. NOTE: the project validator (D-12) does NOT check source-path safety (out of scope per D-12 minimalism); this fixture exists to document the surface for future hardening and is asserted by `test-validator.sh` to be valid JSON but flagged separately. Mark it INFORMATIONAL in the driver — it should be counted as "future TOOL-* hardening", not a current failure mode.

    Then write `scripts/test-validator.sh` (executable, `#!/usr/bin/env bash`, `set -euo pipefail` — the driver itself MAY use `set -e` because it does want to fail fast on its own assertion errors; ONLY `validate-manifests.sh` is forbidden from `set -e` per Pitfall 7).

    Driver behavior:
    1. Create a temporary working directory (mktemp -d) with a shadow repo layout: `.claude-plugin/marketplace.json`, `plugins/p1/.claude-plugin/plugin.json`.
    2. Test A — RESEARCH Pitfall 7 regression: copy `scripts/fixtures/bad-trailing-comma.json` over `.claude-plugin/marketplace.json` AND `scripts/fixtures/bad-missing-name.json` over `plugins/p1/.claude-plugin/plugin.json` so TWO files are broken simultaneously. From the temp dir, run `bash <abs-path-to>/scripts/validate-manifests.sh` and capture stderr. Assert exit code is 1 AND stderr contains `FAIL:` at least 2 times (`grep -c FAIL: <stderr> | awk '{exit ($1 >= 2) ? 0 : 1}'`). This proves the validator surfaces ALL failures in one pass.
    3. Test B — missing-name only: copy `bad-missing-name.json` to `plugins/p1/.claude-plugin/plugin.json` and put a valid marketplace.json (copy from the real one). Assert exit code 1, stderr contains `missing required field .name`.
    4. Test C — happy path: copy real `.claude-plugin/marketplace.json` and real `plugins/zapili/.claude-plugin/plugin.json` from repo into the temp shadow. Assert exit code 0, stdout contains `ok: all manifests valid`.
    5. On any assertion failure, print which test failed and exit 1. On all pass, print `ok: all fixture assertions passed` and exit 0.
    6. Clean up the temp dir on EXIT trap.

    `chmod +x scripts/test-validator.sh`.
  </action>
  <verify>
    <automated>test -x scripts/test-validator.sh && test -f scripts/fixtures/bad-missing-name.json && test -f scripts/fixtures/bad-trailing-comma.json && test -f scripts/fixtures/bad-invalid-source.json && jq -e . scripts/fixtures/bad-missing-name.json >/dev/null && ! jq -e . scripts/fixtures/bad-trailing-comma.json >/dev/null 2>&1 && jq -e . scripts/fixtures/bad-invalid-source.json >/dev/null && bash scripts/test-validator.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f scripts/fixtures/bad-missing-name.json && test -f scripts/fixtures/bad-trailing-comma.json && test -f scripts/fixtures/bad-invalid-source.json` exits 0.
    - `jq -e . scripts/fixtures/bad-missing-name.json >/dev/null` exits 0 (valid JSON; missing field is the failure mode, not parse).
    - `! jq -e . scripts/fixtures/bad-trailing-comma.json >/dev/null 2>&1` exits 0 (INVALID JSON — parse fails as designed).
    - `jq -e . scripts/fixtures/bad-invalid-source.json >/dev/null` exits 0 (valid JSON; informational fixture).
    - `test -x scripts/test-validator.sh` exits 0.
    - `bash scripts/test-validator.sh; test $? -eq 0` exits 0 (VALIDATION map task 01-04-02 — all three test cases pass, including Pitfall 7 regression).
    - The driver's Test A internally asserts `grep -c FAIL: <stderr>` ≥ 2 (Pitfall 7 detection — multi-error surfacing).
  </acceptance_criteria>
  <done>Three fixtures cover distinct failure modes; driver script runs all three test cases including the Pitfall 7 multi-failure regression and exits 0 when validator behaves correctly.</done>
</task>

<task type="auto">
  <name>Task 3: Write scripts/install-hooks.sh + scripts/pre-commit</name>
  <files>scripts/install-hooks.sh, scripts/pre-commit</files>
  <read_first>
    - .planning/phases/01-marketplace-plugin-skeleton/01-CONTEXT.md (D-16, D-17, D-18, D-19 — installer behavior, gated invocation, idempotence, opt-in discovery)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Code Examples" Example 7 (install-hooks.sh) and Example 8 (pre-commit template)
    - .planning/phases/01-marketplace-plugin-skeleton/01-RESEARCH.md § "Common Pitfalls" Pitfall 8 (silent-clobber prevention) and Pitfall 9 (not-a-git-repo guard)
    - README.md (Plan 02 — Local development section references `./scripts/install-hooks.sh` as the documented one-liner; D-19 — opt-in discovery via README)
  </read_first>
  <action>
    Write TWO files, both `chmod +x` after creation.

    **File A — `scripts/pre-commit` (the hook template that gets copied into `.git/hooks/pre-commit`):**

    Follow RESEARCH Example 8 verbatim.
    - Shebang: `#!/usr/bin/env bash`
    - Pragmas: `set -euo pipefail` (the hook is allowed `set -e` — it's a thin dispatcher, not the validation loop itself).
    - Body: capture staged files with `STAGED=$(git diff --cached --name-only --diff-filter=ACMR)`. If `STAGED` matches the regex `^(\.claude-plugin/marketplace\.json|plugins/[^/]+/\.claude-plugin/plugin\.json)$` on any line, `exec ./scripts/validate-manifests.sh`. Else `exit 0`.
    - LF endings, mode 0755.

    Per D-17: hook is gated — fast no-op for commits that don't touch manifests.

    **File B — `scripts/install-hooks.sh` (the idempotent installer):**

    Follow RESEARCH Example 7 verbatim. Per D-16, the installer is the marketplace-level wrapper that wires `scripts/pre-commit` into `.git/hooks/pre-commit`; per D-19, this is opt-in (the contributor runs it once after cloning — documented in Plan 02's README, never auto-invoked).
    - Shebang: `#!/usr/bin/env bash`
    - Pragmas: `set -euo pipefail`.
    - Body steps:
      1. Guard: `git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: not inside a git repository" >&2; exit 1; }` (RESEARCH Pitfall 9).
      2. Compute `GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"`, `SRC="scripts/pre-commit"`, `DST="$GIT_HOOKS_DIR/pre-commit"`.
      3. Guard: `test -f "$SRC"` else error `template not found at $SRC (run from repo root)` and exit 1.
      4. `mkdir -p "$GIT_HOOKS_DIR"`.
      5. If `-e "$DST"`: `cmp -s "$SRC" "$DST"` → echo `ok: pre-commit already installed (byte-identical)` and exit 0; else echo `error: $DST already exists and differs from $SRC`, echo `diff (expected vs current):`, run `diff -u "$SRC" "$DST" >&2 || true`, echo remediation `to overwrite, remove $DST manually first, then re-run.`, and exit 1 (RESEARCH Pitfall 8 — never silently clobber).
      6. Else: `cp "$SRC" "$DST" && chmod +x "$DST" && echo "ok: installed pre-commit at $DST"`.
    - LF endings, mode 0755.

    Per D-18 / Pitfall 8: never silently overwrite a user's existing hook.
  </action>
  <verify>
    <automated>test -x scripts/pre-commit && test -x scripts/install-hooks.sh && head -1 scripts/pre-commit | grep -qE '^#!/usr/bin/env bash' && head -1 scripts/install-hooks.sh | grep -qE '^#!/usr/bin/env bash' && grep -q 'git diff --cached --name-only' scripts/pre-commit && grep -q 'exec ./scripts/validate-manifests.sh' scripts/pre-commit && grep -q 'cmp -s' scripts/install-hooks.sh && grep -q 'git rev-parse --git-dir' scripts/install-hooks.sh</automated>
  </verify>
  <acceptance_criteria>
    - `test -f scripts/pre-commit && test -x scripts/pre-commit` exits 0 (mode 0755).
    - `test -f scripts/install-hooks.sh && test -x scripts/install-hooks.sh` exits 0.
    - `head -1 scripts/pre-commit | grep -qE '^#!/usr/bin/env bash'` and same for `install-hooks.sh` (ZAP-04 / MKT-06 shebang).
    - `grep -q 'git diff --cached --name-only' scripts/pre-commit` exits 0 (D-17 gating).
    - `grep -q 'exec ./scripts/validate-manifests.sh' scripts/pre-commit` exits 0 (key-link from pre-commit to validator).
    - `grep -q 'cmp -s' scripts/install-hooks.sh` exits 0 (D-18 byte-equality check via Pitfall 8 mitigation).
    - `grep -q 'git rev-parse --git-dir' scripts/install-hooks.sh` exits 0 (Pitfall 9 guard).
    - Idempotence smoke (executor runs in clean git checkout): `bash scripts/install-hooks.sh` → exit 0 with `installed`; second run → exit 0 with `byte-identical`; manually `echo "x" >> .git/hooks/pre-commit` then third run → exit 1 with diff output on stderr.
    - File line endings: `file scripts/pre-commit scripts/install-hooks.sh | grep -qv CRLF` (Plan 03's `.gitattributes` enforces this).
  </acceptance_criteria>
  <done>Hook template invokes validator only when manifests are staged; installer is idempotent and refuses to clobber a differing user hook; both scripts are LF-only and 0755.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Contributor's working tree → git pre-commit | Validator runs locally before any commit lands; the only "input" it parses is JSON via `jq` (hardened parser). |
| `scripts/install-hooks.sh` → `.git/hooks/pre-commit` | Installer modifies the contributor's `.git/hooks/` directory — direct trust boundary into the local git toolchain. |
| `scripts/test-validator.sh` → temp dir → validator | Driver shadows the real layout in a `mktemp -d` sandbox; never mutates real repo files. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-01 | Code Execution | Malicious JSON content triggering arbitrary execution in validator | mitigate | `jq -e .` is parse-only; no `eval`; every shell variable expansion is double-quoted (`"$file"`, `"$manifest"`); RESEARCH § "Don't Hand-Roll" → "Validator runs arbitrary code via JSON content" line. |
| T-04-02 | Tampering | Validator stops at first failure → contributors fix-one-commit-at-a-time | mitigate | Pitfall 7 mitigation: no `set -e` in the validation loop; `test-validator.sh` Test A asserts `grep -c FAIL: ≥ 2` against deliberately-double-broken fixtures. |
| T-04-03 | Tampering | Silent clobber of contributor's custom `.git/hooks/pre-commit` | mitigate | `install-hooks.sh` uses `cmp -s` for byte-equality check and aborts with diff if different; never silently overwrites (Pitfall 8 + D-18). |
| T-04-04 | DoS | Installer crashes when not inside a git repo | mitigate | Pre-flight `git rev-parse --git-dir` guard (Pitfall 9). |
| T-04-05 | Repudiation | jq missing on host → validator silently passes | mitigate | D-15 / Pitfall 10: explicit `command -v jq` probe at top of validator; clear remediation message and `exit 1`. |
| T-04-06 | Tampering / DoS | CRLF on `scripts/*.sh` causing `bash\r` interpreter spoof | mitigate | Plan 03's `.gitattributes` (committed Wave 1) enforces LF on `*.sh` on add; this plan is Wave 2 so files commit as LF on first add — `file ... | grep -qv CRLF` acceptance gate verifies. |
| T-04-SC | Tampering | npm/pip/cargo installs | accept | No package-manager installs in this plan (bash + jq only, both pre-existing host tools per RESEARCH § "Package Legitimacy Audit"); no `[ASSUMED]`/`[SUS]` packages to gate. |
</threat_model>

<verification>
- `bash scripts/validate-manifests.sh` against the real repo exits 0.
- `bash scripts/test-validator.sh` exits 0 (covers Pitfall 7 multi-failure regression).
- `bash scripts/install-hooks.sh` is idempotent: first run installs, second run no-ops byte-identical, third run aborts on user-modified hook.
- All four `scripts/*.sh` files have mode 0755, `#!/usr/bin/env bash` shebang, and LF endings.
- Three fixtures present in `scripts/fixtures/` exercising distinct failure modes.
- VALIDATION map tasks 01-04-01, 01-04-02, and 01-04-03 (manual: commit a deliberately-broken manifest on a scratch branch → hook blocks) all green.
</verification>

<success_criteria>
- Phase 1 success criterion 4 satisfied: `scripts/validate-manifests.sh` parses both manifests, exits 0 on valid, non-zero on malformed.
- A contributor running `./scripts/install-hooks.sh` once on a fresh clone gets manifest validation on every future commit that touches `*.claude-plugin/*.json`.
- The Pitfall 7 regression is automated — future edits to the validator that introduce `set -e` will fail `test-validator.sh`.
</success_criteria>

<output>
Create `.planning/phases/01-marketplace-plugin-skeleton/01-04-SUMMARY.md` when done, recording: (a) exit codes from the three `test-validator.sh` test cases, (b) confirmation that the validator does NOT contain `set -e`, (c) idempotence run output (install → no-op → abort-on-divergence).
</output>
