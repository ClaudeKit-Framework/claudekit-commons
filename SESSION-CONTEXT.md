# claudekit-commons — Session Context

Last updated: June 2026
Stage: 2 — Complete
Status: Done, pushed to main

## Always read first
/home/freyja/Documents/Dev/ClaudeKit/claudekit-commons/DESIGN.md

## What's been done
- All 7 schemas written (project-state, stack-manifest, session-contract, 
  task-record, handoff, flag, _defs)
- All 5 conventions written (manual-action-block, phase-gate, 
  session-boundary, documentation-requirements, dependency-policy)
- manifest-file-fields convention added — documents file entry fields including
  skip_if_framework_present (no formal manifest schema exists; this convention
  is the authoritative reference)
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
- DESIGN.md committed as persistent build context
- All files committed and pushed to main

## Open flags
- known-incompatibilities.schema.json referenced in known-incompatibilities.json 
  but not yet created — add in a future session
- Action IDs in manifests must be generated as unique IDs at runtime 
  by init.sh, not used as static values — address when init.sh is revised
- PowerShell equivalents of init.sh and update.sh — future session
- Runner manifest source paths will need updating once claudekit-runner 
  file structure is confirmed (same issue as guardrails manifests had)

## What's next
- No further Stage 2 work
- Update runner manifest after Stage 3 (claudekit-runner) is complete
- Add known-incompatibilities.schema.json when convenient

## Notes
- Do not update DESIGN.md directly — all design changes go through 
  the Claude chat design session
- Org name is ClaudeKit-Framework (one hyphen, not three)