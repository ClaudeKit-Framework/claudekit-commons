# claudekit-commons — Session Context

Last updated: 11 June 2026
Stage: 4 — In progress
Status: In progress

## Always read first
/home/freyja/Documents/Dev/ClaudeKit/claudekit-commons/DESIGN.md

## What's been done
- All 7 schemas written (project-state, stack-manifest, session-contract, 
  task-record, handoff, flag, _defs)
- All 8 conventions written (manual-action-block, phase-gate, 
  session-boundary, documentation-requirements, dependency-policy,
  manifest-file-fields, chat-session-management, output-document-versioning)
- manifest-file-fields convention added — documents file entry fields including
  skip_if_framework_present (no formal manifest schema exists; this convention
  is the authoritative reference)
- chat-session-management convention added — save block triggers, new chat 
  triggers, context degradation (reactive + proactive), out-of-scope handover,
  framework handoff points; applies to chat-native frameworks only
- output-document-versioning convention added — semantic versioning for 
  user-facing output documents; patch/minor auto-applied, major requires 
  check-in; covers design docs, scope plans, handoffs, narratives, audit reports
- known-incompatibilities.json — structure defined, one example entry
- COMPATIBILITY.md — structure defined, placeholder rows
- Init tooling — init.sh, update.sh, lib scripts (detect, copy, output, audit)
  - audit.sh outputs explicit warning; states manual review required; 
    references SESSION-CONTEXT.md open flags for more information
  - init.sh respects skip_if_framework_present when listing and copying files
- Manifests — guardrails-solo (7 files), guardrails-team (16 files), runner
- Manifests corrected — source paths, file lists, org name, solo commands, 
  team-config.json reference removed
- runner manifest — create-adr.md entry added with 
  skip_if_framework_present: ["guardrails-solo", "guardrails-team"]
- runner manifest org name typo fixed (Claude-Kit-Framework → ClaudeKit-Framework)
- DESIGN.md committed as persistent build context
- All files committed and pushed to main
- claudekit-design repo created — project-design-v1.0.0.md
  prompt file built, reviewed, and committed to prompts/
- claudekit-scope repo created — scope-planner-v1.0.0.md
  prompt file built, reviewed, and committed to prompts/

## Open flags
- known-incompatibilities.schema.json referenced in known-incompatibilities.json 
  but not yet created — add in a future session
- Action IDs in manifests must be generated as unique IDs at runtime 
  by init.sh, not used as static values — address when init.sh is revised
- PowerShell equivalents of init.sh and update.sh — future session

## What's next
- Website
- DESIGN.md update to v0.9 now complete — committed
- Add known-incompatibilities.schema.json when convenient

## Notes
- Do not update DESIGN.md directly — all design changes go through 
  the Claude chat design session
- Org name is ClaudeKit-Framework (one hyphen, not three)