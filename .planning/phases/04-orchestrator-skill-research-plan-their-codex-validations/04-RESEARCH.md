# Phase 4: Orchestrator + research + plan + codex validations - Research

**Confidence:** HIGH (anchored in CONTEXT D-01..D-19 + CLAUDE.md + codex CLI docs).

## Stack

| Choice | Rationale |
|--------|-----------|
| Skill directory form (`skills/orchestrator/SKILL.md`) | Bundled `references/` already lives there (Phase 3) |
| Subagents under `plugins/zapili/agents/` | Default auto-discovery |
| `codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config` | Documented script-friendly invocation; hermetic; safe |
| jq for JSONL parsing | Universal; codex docs use jq |
| `.zapili/state.json` atomic via mv | POSIX rename guarantees atomicity on same filesystem |

## Key snippets

### codex-review.sh skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
prompt_file="${1:?prompt file required}"
out_file="${2:?out file required}"
raw_file="${out_file}.raw.jsonl"
codex exec --json --sandbox read-only --skip-git-repo-check --ignore-user-config - < "$prompt_file" > "$raw_file" 2>&1 || rc=$?
rc=${rc:-0}
jq -s 'map(select(.type=="message" and .role=="assistant")) | last | (.content // .text // .message)' "$raw_file" > "$out_file" 2>/dev/null || true
exit "$rc"
```

### Stable issue ID (bash)
```bash
sha=$(printf '%s|%s|%s' "$file" "$line_range" "$kind" | sha256sum | awk '{print substr($1,1,12)}')
echo "ISS-$sha"
```

### Atomic state write
```bash
tmp=$(mktemp "${STATE_FILE}.XXXXXX")
trap 'rm -f "$tmp"' EXIT
jq "$jq_filter" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
```

## Pitfalls

1. `codex exec` without `-` consumes prompt as positional arg — use `-` and pipe stdin.
2. JSONL parsing: codex's event schema varies by version; isolate to one file (`codex-review.sh`).
3. Subagent allowlist must use `Agent(researcher, planner)` (Claude Code v2.1.63+); old `Task(...)` is deprecated alias.
4. SKILL.md `context: fork` is required so the references don't bloat the orchestrator's parent thread.
5. State writes MUST be on same filesystem as `.zapili/state.json` (use mktemp in same dir).

## Sources
- CONTEXT.md D-01..D-19
- CLAUDE.md § "Plugin Components" + § "Codex invocation pattern" + § "What NOT to Use"
- developers.openai.com/codex/noninteractive
- code.claude.com/docs/en/sub-agents (`tools` allowlist, plugin restrictions)
