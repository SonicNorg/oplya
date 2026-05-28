# Fixture f6 plan — hash-table cache (engineer stuck, codex self-fix resolves)

## Goal

Implement a hash-table cache with unit tests covering insertion, eviction, and overflow.

## Wave 1

- PHASE-XX — implement cache

## Notes

The phase spec deliberately omits a unit-test task; the engineer cannot self-resolve
the resulting `missing-tasks` HIGH finding because the spec itself never asks for
tests. The codex-self-fix fallback (ZAP-60) is expected to revise the spec to add
the missing test task + extend the writes block to include the test file.

(Avoid repeating the literal phase id below — `check-wave-disjointness.sh` matches
PHASE-XX globally and dedup is per-occurrence, not per-unique-id; multiple mentions
in one wave's PLAN section produce a false-positive overlap.)

<!-- <status>complete</status> -->
