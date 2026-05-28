#!/usr/bin/env bash
set -euo pipefail

# summarize.sh — aggregate PHASE-XX-attempt-N.md files into SUMMARY.md.
# No args. Run from the user's project CWD.
# Latest attempt per phase id wins; earlier attempts are reasoning trace only.

OUT="SUMMARY.md"

shopt -s nullglob
attempts=(PHASE-*-attempt-*.md)
if [ "${#attempts[@]}" -eq 0 ]; then
  printf '[summarize] no PHASE-*-attempt-*.md files in %s\n' "$PWD" >&2
  exit 1
fi

# Group by phase id, keep latest attempt per id.
declare -A latest
for f in "${attempts[@]}"; do
  pid=$(printf '%s' "$f" | sed -E 's/^PHASE-([0-9]+(-[0-9]+)?)-attempt-[0-9]+\.md$/\1/')
  n=$(printf '%s' "$f" | sed -E 's/^PHASE-[0-9]+(-[0-9]+)?-attempt-([0-9]+)\.md$/\2/')
  prior_n=0
  if [ -n "${latest[$pid]:-}" ]; then
    prior_n=$(printf '%s' "${latest[$pid]}" | sed -E 's/^PHASE-[0-9]+(-[0-9]+)?-attempt-([0-9]+)\.md$/\2/')
  fi
  if [ "$n" -gt "$prior_n" ]; then
    latest[$pid]="$f"
  fi
done

# Extract payload JSON from each latest file.
extract_payload() {
  sed -n 's/.*<payload>\(.*\)<\/payload>.*/\1/p' "$1" | head -n1
}

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tmp=$(mktemp "${OUT}.XXXXXX")
trap 'rm -f "$tmp"' EXIT

{
  printf '# Workflow summary\n\n'
  printf '**Generated:** %s\n\n' "$now"
  printf '## Overview\n\n'
  printf 'Total phases: %d\n\n' "${#latest[@]}"

  printf '## Files changed (deduplicated across phases)\n\n'
  {
    for pid in "${!latest[@]}"; do
      payload=$(extract_payload "${latest[$pid]}")
      [ -n "$payload" ] || continue
      printf '%s' "$payload" | jq -r --arg pid "$pid" '.files_touched[]? | "- `\(.path)` (\(.operation)) — phase \($pid)"' 2>/dev/null || true
    done
  } | sort -u
  printf '\n## Decisions (per phase)\n\n'
  for pid in $(printf '%s\n' "${!latest[@]}" | sort); do
    payload=$(extract_payload "${latest[$pid]}")
    [ -n "$payload" ] || continue
    printf '### Phase %s\n\n' "$pid"
    printf '%s' "$payload" | jq -r '.decisions[]? | "- **\(.id) — \(.title)**: \(.rationale)"' 2>/dev/null || true
    printf '\n'
  done

  printf '## Review outcomes\n\n'
  shopt -s nullglob
  for r in .zapili/phase-*-review-attempt-*.json; do
    pid_attempt=$(printf '%s' "$r" | sed -E 's|.*phase-(.*)-review-attempt-([0-9]+)\.json|\1 attempt \2|')
    severe=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$r" 2>/dev/null || echo "?")
    printf -- '- phase %s — HIGH/MEDIUM findings: %s\n' "$pid_attempt" "$severe"
  done

  printf '\n## Open items\n\n'
  open_count=0
  for r in .zapili/phase-*-review-attempt-*.json; do
    severe=$(jq '[.findings[]? | select(.severity=="HIGH" or .severity=="MEDIUM")] | length' "$r" 2>/dev/null || echo 0)
    if [ "$severe" != "0" ]; then
      open_count=$((open_count + 1))
      printf -- '- See %s\n' "$r"
    fi
  done
  if [ "$open_count" -eq 0 ]; then
    printf 'None — every phase converged with no HIGH or MEDIUM findings.\n'
  fi

  printf '\n<!-- <status>complete</status> -->\n'
} >"$tmp"

mv "$tmp" "$OUT"
trap - EXIT
printf '[summarize] wrote %s (%d phases)\n' "$OUT" "${#latest[@]}"
exit 0
