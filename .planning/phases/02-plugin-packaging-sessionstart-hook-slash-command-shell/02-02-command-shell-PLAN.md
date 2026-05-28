---
phase: 02-plugin-packaging-sessionstart-hook-slash-command-shell
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/scripts/preflight-codex.sh
  - plugins/zapili/commands/zapili.md
  - plugins/zapili/README.md
autonomous: true
requirements:
  - ZAP-01
  - ZAP-04
  - ZAP-05
must_haves:
  truths:
    - "preflight-codex.sh exits non-zero with distinct codes when codex is missing (2), --version fails (3), or exec subcommand unavailable (4)"
    - "preflight-codex.sh probes codex without consuming API tokens (uses exec --help only)"
    - "commands/zapili.md YAML frontmatter restricts allowed-tools to the preflight script Bash invocation"
    - "Slash command body runs preflight first, halts on non-zero, then prints Phase-2 stub on success"
    - "Updated README replaces the Phase-1 'not yet wired' line with usage + preflight notes"
    - "CONTEXT.md decisions implemented: D-07..D-14 (preflight + slash command); D-15..D-18 (script hygiene applied to preflight-codex.sh); D-19, D-20 (no global state mutation); D-21, D-22 (README + no .gitkeep)"
  artifacts:
    - path: "plugins/zapili/scripts/preflight-codex.sh"
      provides: "Strict codex pre-flight (exit 0 OK; 2/3/4 for distinct failures)"
      contains: "set -euo pipefail"
    - path: "plugins/zapili/commands/zapili.md"
      provides: "Slash command shell discoverable as /zapili:zapili"
      contains: "preflight-codex.sh"
    - path: "plugins/zapili/README.md"
      provides: "Updated user-facing docs (no 'not yet wired' line)"
      contains: "/zapili:zapili"
---

<objective>
Deliver the strict pre-flight script, the slash command shell that gates on it, and the README update that reflects the Phase-2 command surface.

Without this plan, the slash command does not exist (`/zapili:zapili` 404s); the README still tells users the command surface is unwired; and there is no way to fail-fast on missing/broken codex at command time.

Output:
- `plugins/zapili/scripts/preflight-codex.sh` — `set -euo pipefail`, distinct exit codes (2/3/4), no API token consumption.
- `plugins/zapili/commands/zapili.md` — YAML frontmatter + body that runs preflight then prints a stub message.
- `plugins/zapili/README.md` — updated Usage and Pre-flight sections; Phase-1 placeholder line removed.
</objective>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-CONTEXT.md
@.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-RESEARCH.md
@plugins/zapili/README.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write plugins/zapili/scripts/preflight-codex.sh</name>
  <files>plugins/zapili/scripts/preflight-codex.sh</files>
  <read_first>
    - 02-CONTEXT.md D-07, D-08, D-09 (preflight contract + detection logic + remediation), D-15..D-18 (script hygiene), D-20 (`codex exec --help`, no config touch)
    - 02-RESEARCH.md § "Code Examples" Snippet 3
  </read_first>
  <action>
    Write `plugins/zapili/scripts/preflight-codex.sh` with this body (LF endings, mode 0755):

    ```bash
    #!/usr/bin/env bash
    set -euo pipefail

    # Strict pre-flight invoked by /zapili:zapili.
    # Exit codes:
    #   0  codex is installed and the exec subcommand is reachable
    #   2  codex CLI not found on PATH
    #   3  codex --version failed
    #   4  codex exec subcommand unavailable (auth or install issue)

    REMEDIATION="See https://developers.openai.com/codex/cli/reference for install + auth."

    if ! command -v codex >/dev/null 2>&1; then
      printf '[zapili] preflight FAILED: codex CLI not found on PATH.\n%s\n' "$REMEDIATION" >&2
      exit 2
    fi

    VERSION_OUT=$(codex --version 2>&1) || {
      printf '[zapili] preflight FAILED: codex --version failed: %s\n%s\n' "$VERSION_OUT" "$REMEDIATION" >&2
      exit 3
    }

    if ! codex exec --help >/dev/null 2>&1; then
      printf '[zapili] preflight FAILED: codex exec subcommand unavailable (auth or install issue).\n%s\n' "$REMEDIATION" >&2
      exit 4
    fi

    printf '[zapili] codex preflight OK (%s)\n' "$VERSION_OUT" >&2
    exit 0
    ```

    Set executable bit and commit with mode 100755.
  </action>
  <verify>
    <automated>head -1 plugins/zapili/scripts/preflight-codex.sh | grep -q '^#!/usr/bin/env bash$' &amp;&amp; bash -n plugins/zapili/scripts/preflight-codex.sh &amp;&amp; grep -q '^set -euo pipefail$' plugins/zapili/scripts/preflight-codex.sh &amp;&amp; grep -q 'codex exec --help' plugins/zapili/scripts/preflight-codex.sh &amp;&amp; ! grep -nP '~/\\.claude|~/\\.config/codex' plugins/zapili/scripts/preflight-codex.sh</automated>
  </verify>
  <acceptance_criteria>
    - `head -1 plugins/zapili/scripts/preflight-codex.sh` is `#!/usr/bin/env bash`.
    - `bash -n plugins/zapili/scripts/preflight-codex.sh` exits 0.
    - `grep -q 'set -euo pipefail' plugins/zapili/scripts/preflight-codex.sh` (full strict mode).
    - Script uses `codex exec --help` (cheap, no API call) — not `codex exec "<prompt>"` and not `codex auth status`.
    - With codex on PATH: `bash plugins/zapili/scripts/preflight-codex.sh >/dev/null 2>&1; echo $?` prints `0`.
    - `git ls-files --stage plugins/zapili/scripts/preflight-codex.sh` shows mode `100755`.
    - LF only (no CRLF).
    - No references to `~/.claude/*` or `~/.config/codex/*` (ZAP-05).
  </acceptance_criteria>
  <done>Strict pre-flight script exists, is executable, and gates the slash command on codex availability with distinct exit codes for distinct failure modes.</done>
</task>

<task type="auto">
  <name>Task 2: Write plugins/zapili/commands/zapili.md</name>
  <files>plugins/zapili/commands/zapili.md</files>
  <read_first>
    - 02-CONTEXT.md D-11, D-12, D-13, D-14 (slash command shell decisions)
    - 02-RESEARCH.md § "Code Examples" Snippet 4
  </read_first>
  <action>
    Create `plugins/zapili/commands/` and write `zapili.md` with this exact content (LF endings):

    ```markdown
    ---
    description: Run the zapili multi-agent development workflow on TASK.md
    argument-hint: "[--resume]"
    allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:*)
    ---

    # /zapili:zapili — multi-agent development workflow

    Run the strict codex pre-flight, then (in this Phase-2 shell) print a stub message.
    The full orchestrator lands in Phase 4.

    ## Step 1 — Pre-flight (mandatory)

    Run `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
    If it exits non-zero, STOP and report the remediation printed by the script — do not continue.

    ## Step 2 — Phase-2 stub

    If pre-flight succeeded, print:

    > **zapili Phase 2 shell active.** Codex is available. The orchestrator (research → plan → wave-parallel implementation → review) is delivered in Phase 4. Until then `/zapili:zapili` only verifies pre-conditions.
    ```

    Frontmatter notes:
    - `description` is the one-line surface in the command picker.
    - `argument-hint` is a placeholder so Phase 6 can wire `--resume` without a frontmatter migration.
    - `allowed-tools` is a strict allowlist: only the preflight Bash invocation. Phase 4 will widen this.
  </action>
  <verify>
    <automated>head -1 plugins/zapili/commands/zapili.md | grep -q '^---$' &amp;&amp; grep -q '^description: Run the zapili multi-agent development workflow on TASK.md$' plugins/zapili/commands/zapili.md &amp;&amp; grep -q '^allowed-tools: Bash(\${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh:\*)$' plugins/zapili/commands/zapili.md &amp;&amp; grep -q '# /zapili:zapili' plugins/zapili/commands/zapili.md &amp;&amp; grep -q 'preflight-codex.sh' plugins/zapili/commands/zapili.md</automated>
  </verify>
  <acceptance_criteria>
    - `test -f plugins/zapili/commands/zapili.md` exits 0.
    - First line is `---` (YAML frontmatter start).
    - Frontmatter includes `description`, `argument-hint`, `allowed-tools` keys.
    - `allowed-tools` restricts to the preflight script's Bash invocation only.
    - Body references `${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`.
    - File is LF only.
  </acceptance_criteria>
  <done>Slash command shell exists at the spec-mandated path; default auto-discovery surfaces it as `/zapili:zapili` after `/plugin install zapili@oplya`.</done>
</task>

<task type="auto">
  <name>Task 3: Update plugins/zapili/README.md</name>
  <files>plugins/zapili/README.md</files>
  <read_first>
    - 02-CONTEXT.md D-21 (README update content)
    - Current `plugins/zapili/README.md` (find and remove the Phase-1 "not yet wired" line; add Usage + Pre-flight sections)
  </read_first>
  <action>
    Open `plugins/zapili/README.md` and:

    1. Locate the Phase-1 placeholder sentence (a line near the end stating the slash command surface is not yet wired) and DELETE it.
    2. Add a new `## Usage` section before the License footer:

       ```markdown
       ## Usage

       In a Claude Code session with this plugin installed:

       ```
       /zapili:zapili
       ```

       The command first runs a strict codex pre-flight; if codex is missing or unauthenticated it halts with a remediation message. In this Phase-2 release the command body is a stub — the full orchestrator (research → plan → wave-parallel implementation → review) lands in Phase 4.
       ```

    3. Add a new `## Pre-flight` section right after `## Usage`:

       ```markdown
       ## Pre-flight

       Two safety nets verify codex is ready:

       - **SessionStart hook** (`plugins/zapili/hooks/hooks.json`) — advisory only. If `codex` is missing, prints remediation to stderr and exits 0 so Claude Code starts normally.
       - **Command pre-flight** (`plugins/zapili/scripts/preflight-codex.sh`) — strict. Run from the slash command body; fails fast with distinct exit codes (2 = missing, 3 = `--version` broken, 4 = `exec` unreachable) and a remediation message.

       Both probes use `codex exec --help` for auth verification, which never consumes API tokens or writes to `~/.config/codex/*`.
       ```

    Keep the file under ~80 lines per Phase-1 D-27. Do not reorder unrelated sections. Do not touch the License footer.
  </action>
  <verify>
    <automated>! grep -qi 'not yet wired\|slash command surface is not\|command surface is not' plugins/zapili/README.md &amp;&amp; grep -q '## Usage' plugins/zapili/README.md &amp;&amp; grep -q '## Pre-flight' plugins/zapili/README.md &amp;&amp; grep -q '/zapili:zapili' plugins/zapili/README.md &amp;&amp; grep -q 'preflight-codex.sh' plugins/zapili/README.md</automated>
  </verify>
  <acceptance_criteria>
    - Phase-1 "not yet wired" line is absent (`grep -qi 'not yet wired' plugins/zapili/README.md` returns non-zero).
    - `## Usage` and `## Pre-flight` sections exist.
    - `/zapili:zapili` and `preflight-codex.sh` are mentioned.
    - File remains under ~100 lines (`wc -l plugins/zapili/README.md` returns a number ≤100).
    - License footer is untouched.
  </acceptance_criteria>
  <done>README reflects the Phase-2 command surface; users have authoritative docs for the slash command and the two-level codex check.</done>
</task>

</tasks>

<verification>
- All three files exist at the specified paths and pass the per-task automated checks.
- `plugins/zapili/scripts/preflight-codex.sh` is mode 0755, LF, `set -euo pipefail`, distinct exit codes.
- `plugins/zapili/commands/zapili.md` parses (frontmatter visible to a YAML parser).
- README contains Usage + Pre-flight sections; Phase-1 placeholder removed.
</verification>

<success_criteria>
- Phase-2 verification steps 9 and 10 from `02-PLAN.md` pass.
- With codex on PATH, the documented invocation pattern in the command body (`${CLAUDE_PLUGIN_ROOT}/scripts/preflight-codex.sh`) succeeds when CLAUDE_PLUGIN_ROOT is set to `plugins/zapili`.
- Manifests still validate via the Phase-1 `scripts/validate-manifests.sh` (no regressions).
</success_criteria>

<output>
Create `.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-02-command-shell-SUMMARY.md` when done, listing the three files written, the README diff summary, and the preflight exit-code observation under the current environment.
</output>
