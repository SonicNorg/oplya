#!/usr/bin/env bash
set -euo pipefail

# Self-test for plugins/zapili/schemas/*.schema.json against examples/.
# Prefers ajv; falls back to python jsonschema; hard-fails with remediation if neither is available.

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SCHEMAS_DIR="$ROOT/schemas"
EXAMPLES_DIR="$SCHEMAS_DIR/examples"

if [ ! -d "$SCHEMAS_DIR" ]; then
  printf '[validate-schemas] schemas dir not found: %s\n' "$SCHEMAS_DIR" >&2
  exit 1
fi

VALIDATOR=""
if command -v ajv >/dev/null 2>&1; then
  VALIDATOR=ajv
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import jsonschema' >/dev/null 2>&1; then
  VALIDATOR=python
else
  printf '[validate-schemas] no JSON Schema validator available.\nInstall one of:\n  npm install -g ajv-cli\n  pip install jsonschema\n' >&2
  exit 1
fi

validate_one() {
  local schema="$1" data="$2"
  case "$VALIDATOR" in
    ajv)
      ajv validate -s "$schema" -d "$data" --spec=draft2020 --strict=false >/dev/null 2>&1
      ;;
    python)
      python3 - "$data" "$schema" <<'PY' >/dev/null 2>&1
import json, sys
import jsonschema
data = json.load(open(sys.argv[1]))
schema = json.load(open(sys.argv[2]))
jsonschema.validate(data, schema)
PY
      ;;
  esac
}

fail=0
for s in "$SCHEMAS_DIR"/*.schema.json; do
  base=$(basename "$s" .schema.json)
  for kind in valid invalid; do
    file="$EXAMPLES_DIR/$base.$kind.json"
    if [ ! -f "$file" ]; then
      printf '[validate-schemas] FAIL: missing example: %s\n' "$file" >&2
      fail=1
      continue
    fi
    if validate_one "$s" "$file"; then
      result=valid
    else
      result=invalid
    fi
    if [ "$result" != "$kind" ]; then
      printf '[validate-schemas] FAIL: %s expected=%s got=%s\n' "$file" "$kind" "$result" >&2
      fail=1
    fi
  done
done

if [ "$fail" -eq 0 ]; then
  printf '[validate-schemas] ok: all schemas + examples pass (%s)\n' "$VALIDATOR"
fi
exit "$fail"
