---
phase: 06-wave-executor-final-summary-resume-hardening-publication-polish
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - CHANGELOG.md
  - README.md
  - plugins/zapili/.claude-plugin/plugin.json
autonomous: true
requirements: []
must_haves:
  truths:
    - "CHANGELOG.md root file at marketplace root with [Unreleased] (empty) and [1.0.0] - 2026-05-28 sections; [1.0.0] lists every requirement family Phases 1-6 covered"
    - "Top-level README.md gets a ## Status section noting v1.0.0 + CHANGELOG link + acceptance-criteria reference"
    - "plugins/zapili/.claude-plugin/plugin.json adds `\"version\": \"1.0.0\"` (only field added; no other changes)"
    - "validate-manifests.sh still passes after the version bump"
    - "CONTEXT.md decisions implemented: D-13, D-14, D-15"
---
<objective>v1 release-polish artifacts so the marketplace ships.</objective>
<context>
@.planning/phases/06-wave-executor-final-summary-resume-hardening-publication-polish/06-CONTEXT.md
@README.md
@plugins/zapili/.claude-plugin/plugin.json
</context>
<tasks>
<task type="auto"><name>Task 1: CHANGELOG.md</name>
<action>Create top-level CHANGELOG.md following Keep-A-Changelog format. Two sections: `## [Unreleased]` (empty) and `## [1.0.0] - 2026-05-28` listing under Added: each requirement family delivered (MKT-01..08, ZAP-01..05, ZAP-10..15, ZAP-20..24, ZAP-30..35, ZAP-40, ZAP-41..47, ZAP-50..54).</action>
<acceptance_criteria>File exists at repo root; contains `[Unreleased]` and `[1.0.0]`; lists ≥6 Added bullet groups.</acceptance_criteria>
</task>
<task type="auto"><name>Task 2: README.md ## Status</name>
<action>Edit `README.md` to add a `## Status` section near the bottom (before any License footer): one paragraph noting v1.0.0, link to CHANGELOG.md, link to REQUIREMENTS.md § "Acceptance Criteria" + "Release Criteria".</action>
<acceptance_criteria>`grep '## Status' README.md` matches; mentions `1.0.0` and `CHANGELOG.md`.</acceptance_criteria>
</task>
<task type="auto"><name>Task 3: plugin.json version bump</name>
<action>Edit `plugins/zapili/.claude-plugin/plugin.json` to add `"version": "1.0.0"` after `"name"` (preserving all other fields). Re-run validate-manifests.sh to confirm.</action>
<acceptance_criteria>`jq -e '.version == "1.0.0"' plugins/zapili/.claude-plugin/plugin.json`; `./scripts/validate-manifests.sh` exits 0.</acceptance_criteria>
</task>
</tasks>
<output>Create 06-03-publication-polish-SUMMARY.md.</output>
