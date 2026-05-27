#!/usr/bin/env bash
# Driver for scripts/validate-manifests.sh — asserts behavior against
# golden-bad fixtures in scripts/fixtures/.
#
# This driver itself uses `set -e` because it WANTS to fail fast on its
# own assertion errors. Only validate-manifests.sh is forbidden from
# `set -e` (per RESEARCH Pitfall 7 — the validator must surface ALL
# failures in one pass; this driver does not have that constraint).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$REPO_ROOT/scripts/validate-manifests.sh"
FIXTURES="$REPO_ROOT/scripts/fixtures"
REAL_MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
REAL_PLUGIN="$REPO_ROOT/plugins/zapili/.claude-plugin/plugin.json"

TMP=""
cleanup() {
    if [ -n "$TMP" ] && [ -d "$TMP" ]; then
        rm -rf "$TMP"
    fi
}
trap cleanup EXIT

setup_shadow() {
    TMP="$(mktemp -d)"
    mkdir -p "$TMP/.claude-plugin" "$TMP/plugins/p1/.claude-plugin"
}

fail_test() {
    echo "FAIL: $*" >&2
    exit 1
}

# --- Test A: RESEARCH Pitfall 7 regression — TWO files broken at once.
#     Validator must surface ≥2 FAIL: lines and exit 1.
echo "Test A: multi-failure surfacing (Pitfall 7 regression)..."
setup_shadow
cp "$FIXTURES/bad-trailing-comma.json"  "$TMP/.claude-plugin/marketplace.json"
cp "$FIXTURES/bad-missing-name.json"    "$TMP/plugins/p1/.claude-plugin/plugin.json"

set +e
A_STDERR="$(cd "$TMP" && bash "$VALIDATOR" 2>&1 >/dev/null)"
A_EXIT=$?
set -e

[ "$A_EXIT" -eq 1 ] || fail_test "Test A: expected exit 1, got $A_EXIT"
A_FAIL_COUNT=$(printf '%s\n' "$A_STDERR" | grep -c '^FAIL:' || true)
[ "$A_FAIL_COUNT" -ge 2 ] || fail_test "Test A: expected ≥2 FAIL: lines (Pitfall 7 detection), got $A_FAIL_COUNT. stderr was: $A_STDERR"
rm -rf "$TMP"; TMP=""
echo "  ok (exit=$A_EXIT, FAIL lines=$A_FAIL_COUNT)"

# --- Test B: missing-name only — valid marketplace, broken plugin manifest.
echo "Test B: missing required field surfaces remediation..."
setup_shadow
cp "$REAL_MARKETPLACE"               "$TMP/.claude-plugin/marketplace.json"
cp "$FIXTURES/bad-missing-name.json" "$TMP/plugins/p1/.claude-plugin/plugin.json"

set +e
B_STDERR="$(cd "$TMP" && bash "$VALIDATOR" 2>&1 >/dev/null)"
B_EXIT=$?
set -e

[ "$B_EXIT" -eq 1 ] || fail_test "Test B: expected exit 1, got $B_EXIT"
printf '%s\n' "$B_STDERR" | grep -q 'missing required field .name' \
    || fail_test "Test B: expected stderr to contain 'missing required field .name'. stderr was: $B_STDERR"
rm -rf "$TMP"; TMP=""
echo "  ok (exit=$B_EXIT)"

# --- Test C: happy path — real manifests copied into shadow layout.
echo "Test C: happy path against real manifests..."
setup_shadow
cp "$REAL_MARKETPLACE" "$TMP/.claude-plugin/marketplace.json"
cp "$REAL_PLUGIN"      "$TMP/plugins/p1/.claude-plugin/plugin.json"

set +e
C_STDOUT="$(cd "$TMP" && bash "$VALIDATOR" 2>/dev/null)"
C_EXIT=$?
set -e

[ "$C_EXIT" -eq 0 ] || fail_test "Test C: expected exit 0, got $C_EXIT"
printf '%s\n' "$C_STDOUT" | grep -q 'ok: all manifests valid' \
    || fail_test "Test C: expected 'ok: all manifests valid' on stdout. stdout was: $C_STDOUT"
rm -rf "$TMP"; TMP=""
echo "  ok (exit=$C_EXIT)"

# --- Note: bad-invalid-source.json is INFORMATIONAL only.
#     The current validator (D-12 minimalism) does not check source paths;
#     this fixture documents the surface for future TOOL-* hardening.
echo "  (note: bad-invalid-source.json is INFORMATIONAL — future TOOL-* hardening)"

echo "ok: all fixture assertions passed"
exit 0
