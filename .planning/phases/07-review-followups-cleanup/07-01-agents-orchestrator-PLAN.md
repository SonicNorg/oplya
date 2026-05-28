---
phase: 07-review-followups-cleanup
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - plugins/zapili/agents/planner.md
  - plugins/zapili/skills/orchestrator/SKILL.md
autonomous: true
requirements: [ZAP-55, ZAP-56]
must_haves:
  truths:
    - "planner.md <inputs> declares <file role=\"prior-findings\" optional=\"true\"> mirroring engineer.md line 14"
    - "planner.md <task> includes an explicit step instructing the planner to address every prior HIGH/MEDIUM finding by ID and cite each addressed ID in flagged_gaps with topic prefix 'fix:'"
    - "SKILL.md Stage 5 gains Step 5.5 that parses flagged_gaps, surfaces non-empty entries via AskUserQuestion, appends answers to CONTEXT.md ## Gap Resolutions section"
    - "Empty flagged_gaps continues silently (no AskUserQuestion call, no CONTEXT.md modification)"
    - "D-NN decisions cited: D-01, D-02, D-03 (planner contract); D-04, D-05, D-06 (orchestrator routing)"
---
<objective>Make the planner fix-iteration contract symmetric with engineer and ensure planner-flagged gaps reach the user instead of being silently dropped.</objective>
<context>
@.planning/phases/07-review-followups-cleanup/07-CONTEXT.md
@plugins/zapili/agents/engineer.md
@plugins/zapili/agents/planner.md
@plugins/zapili/skills/orchestrator/SKILL.md
</context>
<tasks>
<task type="auto"><name>Task 1: planner.md prior-findings input + task instruction</name>
<action>Edit `plugins/zapili/agents/planner.md`. Add `<file role="prior-findings" optional="true">codex review findings from the prior planner attempt (only on fix iterations)</file>` to the `<inputs>` block (after the `task-sizing.md` reference). Insert a new numbered step at position 2 in `<task>`: "On a fix iteration, the prior-findings JSON is your ground truth — address every HIGH/MEDIUM finding by ID, cite each addressed ID in this revision's `flagged_gaps` entry (use `topic: \"fix:ISS-...\"` form for traceability), and never remove phases to hide gaps." Renumber subsequent steps (1, 2-new, 3-was-2, ...).</action>
<acceptance_criteria>grep "prior-findings" plugins/zapili/agents/planner.md returns the new line; grep -c "^[0-9]\\." in &lt;task&gt; section shows one extra numbered step; bash -n plugins/zapili/agents/planner.md not applicable (markdown) but file YAML frontmatter still parses (head shows --- ... ---).</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: SKILL.md Stage 5 Step 5.5 (flagged_gaps routing)</name>
<action>Edit `plugins/zapili/skills/orchestrator/SKILL.md`. Between current Stage 5's planner-artifact-verification block and `state_advance_stage "plan_validate"`, insert a new sub-section "### 5.5. Route planner-flagged gaps to the user (ZAP-56)" that: (a) extracts `flagged_gaps` from the planner response payload via jq, (b) on non-empty array, loops AskUserQuestion per `{topic, context}`, (c) appends `## Gap Resolutions` Markdown section to CONTEXT.md with one `**GAP-N (topic):** answer` line per resolved gap, (d) silently no-ops on empty array. The new Markdown block uses literal `## Gap Resolutions` heading per D-05.</action>
<acceptance_criteria>grep -q "Gap Resolutions" plugins/zapili/skills/orchestrator/SKILL.md; grep -q "flagged_gaps" plugins/zapili/skills/orchestrator/SKILL.md; the inserted section appears before the existing `state_advance_stage "plan_validate"` line of Stage 5.</acceptance_criteria>
</task>
</tasks>
<output>Create 07-01-agents-orchestrator-SUMMARY.md.</output>
