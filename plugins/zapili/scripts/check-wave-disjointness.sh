#!/usr/bin/env bash
set -euo pipefail

# check-wave-disjointness.sh — mechanical pairwise <files>.writes verification.
# Usage: check-wave-disjointness.sh <plan_md>
# Exit codes:
#   0  every wave's phases have pairwise-disjoint writes
#   1  one or more waves have overlapping writes (diagnostic printed)
#   2  a PHASE-XX.md file has malformed or missing <files> block
#   64 usage error

if [ "$#" -lt 1 ]; then
  printf 'usage: %s <plan_md>\n' "$0" >&2
  exit 64
fi

PLAN_MD="$1"
PROJECT_ROOT="$(dirname "$PLAN_MD")"
[ "$PROJECT_ROOT" = "." ] && PROJECT_ROOT="$PWD"

if [ ! -f "$PLAN_MD" ]; then
  printf '[check-wave-disjointness] PLAN.md not found: %s\n' "$PLAN_MD" >&2
  exit 64
fi

# Parse "### Wave N" headings and the PHASE-XX ids that follow each.
# Tolerant of either "**Wave N**" (bold) or "### Wave N" (heading) styles.
declare -a WAVE_NAMES=()
declare -a WAVE_PHASES=()
current_wave=""
current_phases=""

while IFS= read -r line; do
  if printf '%s' "$line" | grep -qE '^(##+ *Wave |\*\*Wave )'; then
    if [ -n "$current_wave" ]; then
      WAVE_NAMES+=("$current_wave")
      WAVE_PHASES+=("$current_phases")
    fi
    current_wave=$(printf '%s' "$line" | sed -E 's/[^A-Za-z0-9 -]/ /g' | tr -s ' ')
    current_phases=""
    continue
  fi
  # Phase id pattern: production naming (PHASE-01, PHASE-01-02) AND fixture
  # naming (PHASE-XX, PHASE-XX-a, PHASE-XX-b). Character class broadened from
  # [0-9]+ to [A-Za-z0-9]+ per Phase 7 D-12 / ZAP-59. The phase_writes() lookup
  # below just appends `.md` to whatever id is captured, so the broader class
  # is sound.
  pids=$(printf '%s' "$line" | grep -oE 'PHASE-[A-Za-z0-9]+(-[A-Za-z0-9]+)?' || true)
  if [ -n "$pids" ]; then
    current_phases="$current_phases $pids"
  fi
done <"$PLAN_MD"

if [ -n "$current_wave" ]; then
  WAVE_NAMES+=("$current_wave")
  WAVE_PHASES+=("$current_phases")
fi

if [ "${#WAVE_NAMES[@]}" -eq 0 ]; then
  printf '[check-wave-disjointness] no waves found in %s; nothing to verify\n' "$PLAN_MD" >&2
  exit 0
fi

# Extract <files>.writes for a single PHASE-XX id.
phase_writes() {
  local pid="$1"
  local phase_md="$PROJECT_ROOT/$pid.md"
  if [ ! -f "$phase_md" ]; then
    printf '[check-wave-disjointness] missing phase file: %s\n' "$phase_md" >&2
    return 2
  fi
  local block
  block=$(grep -oE '<files>\{[^<]*\}</files>' "$phase_md" | head -n1 | sed -E 's|<files>||; s|</files>||')
  if [ -z "$block" ]; then
    printf '[check-wave-disjointness] no <files> block in %s\n' "$phase_md" >&2
    return 2
  fi
  if ! printf '%s' "$block" | jq -e '.writes | type == "array"' >/dev/null 2>&1; then
    printf '[check-wave-disjointness] malformed <files> JSON in %s\n' "$phase_md" >&2
    return 2
  fi
  printf '%s' "$block" | jq -r '.writes[]'
}

fail=0
for i in "${!WAVE_NAMES[@]}"; do
  wname="${WAVE_NAMES[$i]}"
  # Dedup phase ids per wave — PLAN.md prose may mention a phase id more than
  # once (e.g., in a Notes section) and the per-line grep above will capture
  # each occurrence. Without dedup, the overlap loop below would treat the
  # repeated id as two distinct phases writing the same files and emit a
  # false-positive OVERLAP. Bash's `sort -u` is the simplest dedup primitive.
  read -ra raw_pids <<<"${WAVE_PHASES[$i]}"
  mapfile -t pids < <(printf '%s\n' "${raw_pids[@]}" | awk 'NF' | sort -u)
  declare -A seen=()
  for p in "${pids[@]}"; do
    [ -n "$p" ] || continue
    if ! writes=$(phase_writes "$p"); then
      exit 2
    fi
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      if [ -n "${seen[$path]:-}" ]; then
        printf '[check-wave-disjointness] OVERLAP in %s: %s and %s both write %s\n' \
          "$wname" "${seen[$path]}" "$p" "$path" >&2
        fail=1
      else
        seen[$path]="$p"
      fi
    done <<<"$writes"
  done
  unset seen
done

if [ "$fail" -eq 0 ]; then
  printf '[check-wave-disjointness] ok: every wave has pairwise-disjoint writes\n'
fi
exit "$fail"
