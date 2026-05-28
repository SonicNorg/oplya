---
phase: 06-wave-executor-final-summary-resume-hardening-publication-polish
plan: 02
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/tests/chaos/README.md
  - .planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/chaos-rehearsal-LOG.md
  - .planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/reserved-name-check-LOG.md
autonomous: true
requirements: [ZAP-53]
must_haves:
  truths:
    - "tests/chaos/README.md documents the kill-9 chaos rehearsal procedure with one scenario per state boundary"
    - "chaos-rehearsal-LOG.md is a stamped acknowledgment that the procedure was either executed or explicitly deferred (autonomous mode → deferred for live rehearsal)"
    - "reserved-name-check-LOG.md is a stamped check confirming `oplya` and `zapili` are still clear on the Anthropic reserved-name list at release time"
    - "CONTEXT.md decisions implemented: D-11 (procedure), D-12 (rehearsal log), D-16 (reserved name)"
---
<objective>Document the chaos-test procedure and stamp the v1 release-time pre-flight checks.</objective>
<context>
@.planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/06-CONTEXT.md
</context>
<tasks>
<task type="auto"><name>Task 1: tests/chaos/README.md</name>
<action>Write `plugins/zapili/tests/chaos/README.md` documenting the kill-9 chaos-rehearsal procedure: one scenario per state boundary (research / research_validate / plan / plan_validate / mid-wave engineer / mid-wave review / fix-loop fresh spawn) — what to kill, what to inspect, what derive-stage.sh should print on resume.</action>
<acceptance_criteria>File exists; lists ≥7 scenarios; references derive-stage.sh and the completion sentinel rule.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: chaos-rehearsal-LOG.md</name>
<action>Stamp `.planning/phases/06-.../chaos-rehearsal-LOG.md` recording either (a) the live rehearsal outcome OR (b) explicit deferral with rationale (autonomous mode: live kill-9 not executed; manual rehearsal procedure is the contract; future smoke runs follow tests/chaos/README.md).</action>
<acceptance_criteria>File exists; mentions ≥1 of "deferred (autonomous mode)" or actual results.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: reserved-name-check-LOG.md</name>
<action>Stamp `.planning/phases/06-.../reserved-name-check-LOG.md` confirming `oplya` and `zapili` are clear on the Anthropic reserved-name list (per Phase 1 RESEARCH Pitfall 6 follow-up). Document date + method (manual review of the live spec or a one-line "no reserved-name conflict detected — release proceeds").</action>
<acceptance_criteria>File exists; mentions both names; mentions the date.</acceptance_criteria>
</task>
</tasks>
<output>Create 06-02-chaos-and-stamps-SUMMARY.md.</output>
