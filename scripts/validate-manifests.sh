#!/usr/bin/env bash
# Validate marketplace.json and every plugins/*/.claude-plugin/plugin.json.
#
# Discipline (CONTEXT D-14):
#   - bash shebang, set -uo pipefail (DELIBERATELY NOT `set -e`)
#   - The validation loop MUST surface ALL failures in one pass.
#     `set -e` would abort at the first failure — see RESEARCH Pitfall 7.
#
# Exit codes (D-13):
#   0 = all manifests valid
#   1 = any validation failure OR jq missing on host (D-15)

set -uo pipefail

if ! command -v jq >/dev/null 2>&1; then
    echo "error: jq is required (install: 'brew install jq' / 'apt install jq' / 'dnf install jq')" >&2
    exit 1
fi

errors=0

fail() {
    echo "FAIL: $*" >&2
    errors=$((errors + 1))
}

check_json() {
    local file="$1"
    if [ ! -f "$file" ]; then
        fail "$file: not found"
        return 1
    fi
    if ! jq -e . "$file" >/dev/null 2>&1; then
        fail "$file: invalid JSON (jq parse failed)"
        return 1
    fi
    return 0
}

require_field() {
    local file="$1"
    local path="$2"
    if ! jq -e "$path" "$file" >/dev/null 2>&1; then
        fail "$file: missing required field $path"
        return 1
    fi
    return 0
}

# --- Marketplace manifest ---
MARKETPLACE=".claude-plugin/marketplace.json"
if check_json "$MARKETPLACE"; then
    require_field "$MARKETPLACE" '.name'
    require_field "$MARKETPLACE" '.owner.name'
    require_field "$MARKETPLACE" '.plugins'
    if ! jq -e '.plugins | type == "array"' "$MARKETPLACE" >/dev/null 2>&1; then
        fail "$MARKETPLACE: .plugins must be an array"
    fi
fi

# --- Per-plugin manifests ---
shopt -s nullglob
for manifest in plugins/*/.claude-plugin/plugin.json; do
    if check_json "$manifest"; then
        require_field "$manifest" '.name'
    fi
done
shopt -u nullglob

if [ "$errors" -gt 0 ]; then
    echo "validation failed: $errors error(s)" >&2
    exit 1
fi

echo "ok: all manifests valid"
exit 0
