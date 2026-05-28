---
phase: 02-plugin-packaging-sessionstart-hook-slash-command-shell
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/hooks/hooks.json
  - plugins/zapili/scripts/check-codex.sh
autonomous: true
requirements:
  - ZAP-02
  - ZAP-04
  - ZAP-05
must_haves:
  truths:
    - "SessionStart hook is registered with matcher 'startup' only"
    - "Hook command path resolves via ${CLAUDE_PLUGIN_ROOT} (no relative ./, no $PWD)"
    - "check-codex.sh ALWAYS exits 0 even when codex is missing"
    - "check-codex.sh drains stdin via cat >/dev/null"
    - "check-codex.sh shebang is #!/usr/bin/env bash and committed mode is 100755"
    - "CONTEXT.md decisions implemented: D-01..D-06 (hook config + advisory contract); D-15..D-18 (script hygiene applied to check-codex.sh); D-19 (no global state mutation)"
  artifacts:
    - path: "plugins/zapili/hooks/hooks.json"
      provides: "SessionStart hook registration"
      contains: "\"matcher\": \"startup\""
    - path: "plugins/zapili/scripts/check-codex.sh"
      provides: "Advisory codex presence probe (exit 0 always)"
      contains: "exit 0"
---

<objective>
Wire the advisory `SessionStart` codex presence check.

Without this, the user has no signal that codex is missing until they try `/zapili:zapili`. With this, the user sees a remediation message at every fresh session — and Claude Code itself remains fully operational because the hook never exits non-zero.

Output:
- `plugins/zapili/hooks/hooks.json` — single `SessionStart` registration pointing at `check-codex.sh` via `${CLAUDE_PLUGIN_ROOT}`.
- `plugins/zapili/scripts/check-codex.sh` — drains stdin, probes `command -v codex` and `codex --version`, prints remediation to stderr on failure, ALWAYS exits 0.
</objective>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-CONTEXT.md
@.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-RESEARCH.md
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write plugins/zapili/hooks/hooks.json</name>
  <files>plugins/zapili/hooks/hooks.json</files>
  <read_first>
    - 02-CONTEXT.md D-01 (matcher startup), D-02 (command path via CLAUDE_PLUGIN_ROOT), D-03 (timeout 5)
    - 02-RESEARCH.md § "Code Examples" Snippet 1
  </read_first>
  <action>
    Create `plugins/zapili/hooks/` and write `hooks.json` with valid JSON (no comments, no trailing commas, no BOM, LF endings):

    ```json
    {
      "hooks": {
        "SessionStart": [
          {
            "matcher": "startup",
            "hooks": [
              {
                "type": "command",
                "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh\"",
                "timeout": 5
              }
            ]
          }
        ]
      }
    }
    ```

    Single SessionStart registration. Timeout is 5 seconds. Command string is itself quoted so spaces in CLAUDE_PLUGIN_ROOT do not break invocation.
  </action>
  <verify>
    <automated>jq -e . plugins/zapili/hooks/hooks.json &gt;/dev/null &amp;&amp; jq -e '.hooks.SessionStart | type == "array" and length == 1' plugins/zapili/hooks/hooks.json &gt;/dev/null &amp;&amp; jq -e '.hooks.SessionStart[0].matcher == "startup"' plugins/zapili/hooks/hooks.json &gt;/dev/null &amp;&amp; jq -e '.hooks.SessionStart[0].hooks[0].type == "command" and .hooks.SessionStart[0].hooks[0].timeout == 5' plugins/zapili/hooks/hooks.json &gt;/dev/null &amp;&amp; jq -e '.hooks.SessionStart[0].hooks[0].command | contains("${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh")' plugins/zapili/hooks/hooks.json &gt;/dev/null</automated>
  </verify>
  <acceptance_criteria>
    - `test -f plugins/zapili/hooks/hooks.json` exits 0.
    - `jq -e . plugins/zapili/hooks/hooks.json &gt;/dev/null` exits 0.
    - `jq -e '.hooks.SessionStart[0].matcher == "startup"' plugins/zapili/hooks/hooks.json &gt;/dev/null` exits 0.
    - The hook `command` string contains `${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh` literally (verified by jq contains).
    - File is LF-only (no CRLF).
  </acceptance_criteria>
  <done>Hook file is registered and parseable; Claude Code will execute the advisory script at every fresh session startup.</done>
</task>

<task type="auto">
  <name>Task 2: Write plugins/zapili/scripts/check-codex.sh</name>
  <files>plugins/zapili/scripts/check-codex.sh</files>
  <read_first>
    - 02-CONTEXT.md D-04, D-05, D-06 (always-exit-0 contract, detection logic, stdin drain), D-15..D-18 (shell hygiene)
    - 02-RESEARCH.md § "Code Examples" Snippet 2
  </read_first>
  <action>
    Create `plugins/zapili/scripts/` and write `check-codex.sh` with exactly this body (LF endings, mode 0755):

    ```bash
    #!/usr/bin/env bash
    set -uo pipefail

    # SessionStart advisory hook: verify codex CLI is available.
    # Contract: NEVER exit non-zero (would brick Claude Code per ZAP-02).

    # Drain hook stdin (Claude Code writes hook JSON payload here).
    cat >/dev/null 2>&1 || true

    REMEDIATION=$(cat <<'EOF'
    [zapili] codex CLI is required for the /zapili:zapili workflow.
    Install one of:
      brew install --cask codex
      npm install -g @openai/codex
      curl -fsSL https://github.com/openai/codex/releases/latest/download/codex-install.sh | sh
    Then authenticate per https://developers.openai.com/codex/cli/reference
    zapili is loaded but /zapili:zapili will fail-fast until codex is available.
    EOF
    )

    if ! command -v codex >/dev/null 2>&1; then
      printf '%s\n' "$REMEDIATION" >&2
      exit 0
    fi

    if ! codex --version >/dev/null 2>&1; then
      printf '[zapili] codex is installed but failed to report version; check installation.\n' >&2
      exit 0
    fi

    # Success: silent (no noise on every session start).
    exit 0
    ```

    After writing, set executable bit: `chmod 0755 plugins/zapili/scripts/check-codex.sh` AND stage the mode via `git update-index --chmod=+x` (if not already 0755 in the index).

    Note: `set -uo pipefail` (no `-e`) is intentional — every failure path is explicitly handled with `exit 0`, and we never want early-exit on a probe failure.
  </action>
  <verify>
    <automated>test -x plugins/zapili/scripts/check-codex.sh &amp;&amp; head -1 plugins/zapili/scripts/check-codex.sh | grep -q '^#!/usr/bin/env bash$' &amp;&amp; bash -n plugins/zapili/scripts/check-codex.sh &amp;&amp; bash plugins/zapili/scripts/check-codex.sh &lt;/dev/null &gt;/dev/null 2&gt;&amp;1; echo "EXIT=$?" | grep -q 'EXIT=0' &amp;&amp; ! grep -qP '\r' plugins/zapili/scripts/check-codex.sh</automated>
  </verify>
  <acceptance_criteria>
    - `head -1 plugins/zapili/scripts/check-codex.sh` is `#!/usr/bin/env bash` exactly.
    - `bash -n plugins/zapili/scripts/check-codex.sh` exits 0 (no syntax errors).
    - `bash plugins/zapili/scripts/check-codex.sh </dev/null >/dev/null 2>&1; echo $?` prints `0` (exit code is 0 regardless of codex presence — must work even if codex is uninstalled).
    - `git ls-files --stage plugins/zapili/scripts/check-codex.sh` shows mode `100755`.
    - `file plugins/zapili/scripts/check-codex.sh | grep -v CRLF` succeeds (LF only).
    - `grep -q 'cat >/dev/null' plugins/zapili/scripts/check-codex.sh` (stdin drain present).
    - `grep -q 'exit 0' plugins/zapili/scripts/check-codex.sh` (exit-0 contract).
    - `grep -nP '~/\\.claude|~/\\.config/codex' plugins/zapili/scripts/check-codex.sh` returns no matches (ZAP-05).
  </acceptance_criteria>
  <done>Advisory hook script exists, is executable, never exits non-zero, drains stdin, and prints helpful remediation when codex is absent.</done>
</task>

</tasks>

<verification>
- Both files exist at the specified paths.
- `hooks.json` parses cleanly and contains the SessionStart/startup registration.
- `check-codex.sh` is mode 0755, LF-only, `set -uo pipefail`, and exits 0 in every code path.
- No references to global config paths (`~/.claude/*`, `~/.config/codex/*`).
</verification>

<success_criteria>
- Phase-2 verification step 1, 2, 3, 4, 5, 6, 7, 8 from `02-PLAN.md` pass.
- A Claude Code session starting with this plugin installed and codex MISSING from PATH continues normally (does NOT show a blocking error).
</success_criteria>

<output>
Create `.planning/phases/02-plugin-packaging-sessionstart-hook-slash-command-shell/02-01-advisory-hook-SUMMARY.md` when done, listing the exact hook config + script body, and recording the exit-0-on-missing-codex verification result.
</output>
