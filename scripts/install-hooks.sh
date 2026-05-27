#!/usr/bin/env bash
# Idempotent installer — wires scripts/pre-commit into .git/hooks/pre-commit.
#
# Behavior (CONTEXT D-16, D-18, D-19):
#   - Opt-in: contributor runs this once after cloning (documented in README).
#   - Idempotent: byte-identical existing hook → no-op success.
#   - Safe: differing existing hook → diff + abort (NEVER silently clobber).
#
# Pitfall 9 (RESEARCH): pre-flight git-repo guard so the script does not
# crash with a confusing rev-parse error when run outside a checkout.

set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: not inside a git repository" >&2
    exit 1
fi

GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
SRC="scripts/pre-commit"
DST="$GIT_HOOKS_DIR/pre-commit"

if [ ! -f "$SRC" ]; then
    echo "error: template not found at $SRC (run from repo root)" >&2
    exit 1
fi

mkdir -p "$GIT_HOOKS_DIR"

if [ -e "$DST" ]; then
    if cmp -s "$SRC" "$DST"; then
        echo "ok: pre-commit already installed (byte-identical)"
        exit 0
    fi
    echo "error: $DST already exists and differs from $SRC" >&2
    echo "diff (expected vs current):" >&2
    diff -u "$SRC" "$DST" >&2 || true
    echo "to overwrite, remove $DST manually first, then re-run." >&2
    exit 1
fi

cp "$SRC" "$DST"
chmod +x "$DST"
echo "ok: installed pre-commit at $DST"
