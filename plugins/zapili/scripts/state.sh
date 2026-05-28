#!/usr/bin/env bash
# state.sh — zapili orchestrator state helpers.
# This file is a sourced library. Do not execute directly.
#
# Functions:
#   state_bootstrap [task_path]      — create .zapili/state.json if missing
#   state_get <jq_path>              — print value at .zapili/state.json:<jq_path>
#   state_set <jq_path> <jq_value>   — atomic temp-then-rename update
#   state_advance_stage <stage>      — convenience for current_stage updates
#   state_iter_inc <jq_path>         — atomic +1 on an integer counter
#
# Single-writer invariant: only the orchestrator skill body sources this file.
# Subagents and codex MUST NOT touch .zapili/state.json (per ZAP-51).

set -uo pipefail

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf 'state.sh is a sourced library, not an executable script. Use: source state.sh\n' >&2
  exit 1
fi

ZAPILI_DIR="${ZAPILI_DIR:-.zapili}"
STATE_FILE="${ZAPILI_DIR}/state.json"

# Default schema_version is 1; bump in lockstep with state.schema.json.
ZAPILI_STATE_VERSION=1

_state_atomic_write() {
  # Args: <jq_filter>
  # Reads current STATE_FILE, applies jq filter, writes to temp in same dir, mv.
  local filter="$1"
  local tmp
  tmp=$(mktemp "${STATE_FILE}.XXXXXX")
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  if ! jq "$filter" "$STATE_FILE" >"$tmp"; then
    printf '[state.sh] jq filter failed: %s\n' "$filter" >&2
    return 1
  fi
  mv "$tmp" "$STATE_FILE"
}

state_bootstrap() {
  local task_path="${1:-TASK.md}"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  mkdir -p "$ZAPILI_DIR"
  if [ -f "$STATE_FILE" ]; then
    return 0
  fi
  cat >"${STATE_FILE}.tmp" <<EOF
{
  "schema_version": ${ZAPILI_STATE_VERSION},
  "task_path": "${task_path}",
  "current_stage": "research",
  "current_wave": null,
  "current_phase": null,
  "iteration_counters": {
    "research_validate": 0,
    "plan_validate": 0,
    "per_phase_fix": {}
  },
  "issue_ids": {
    "research_validate": [],
    "plan_validate": [],
    "per_phase_review": {}
  },
  "started_at": "${now}",
  "updated_at": "${now}"
}
EOF
  mv "${STATE_FILE}.tmp" "$STATE_FILE"
}

state_get() {
  local path="$1"
  jq -r "$path" "$STATE_FILE"
}

state_set() {
  local path="$1" value="$2"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  _state_atomic_write "$path = $value | .updated_at = \"$now\""
}

state_advance_stage() {
  local stage="$1"
  state_set ".current_stage" "\"$stage\""
}

state_iter_inc() {
  local path="$1"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  _state_atomic_write "$path = ($path // 0) + 1 | .updated_at = \"$now\""
}
