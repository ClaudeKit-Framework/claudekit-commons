# Output Document Versioning

Defines the versioning standard for user-facing ClaudeKit output documents.
Applies to documents users produce and carry with their projects.
Framework source files (conventions, schemas, DESIGN.md) are versioned
through git and the release process — this convention does not apply to them.

## Scope — Documents This Applies To

- Design documents (Project Design output)
- Scope plans (Scope Planner output)
- Handoff documents (Session Runner output)
- Session change narratives (Session Runner output)
- Security audit reports (Guardrails output)

## Version Format

Semantic versioning: `vMAJOR.MINOR.PATCH`

Version appears in two places:
- The document filename: `design-document-v1.2.0.md`
- The document header: `Version: v1.2.0`

Both must match. If they differ, the header is authoritative.

## Increment Rules

**Patch** (`x.x.1`) — minor corrections, wording fixes, small additions that
do not change meaning or structure. Applied automatically with a note:

```
Version updated: v1.0.0 → v1.0.1
Change: corrected wording in constraints section
```

**Minor** (`x.1.x`) — new content added, sections expanded, assumptions
resolved, deferred decisions filled in. Applied automatically with a note:

```
Version updated: v1.0.1 → v1.1.0
Change: database section completed; caching assumption resolved
```

**Major** (`x.0.0`) — structural changes, fundamental pivot, significant
sections added or removed, document purpose or scope changes. Claude checks
in with the user before incrementing:

```
This looks like a major version change — the authentication section has been
restructured and two sections removed. I'd normally increment to v2.0.0 here.

→ Proceed with v2.0.0 / Keep as minor (v1.2.0) / Decide later
```

## Starting Version

New documents start at `v1.0.0`. Draft documents produced before the first
complete version may use `v0.x.x` at the author's discretion, but this is
not required.

## Version in Save Blocks

Save blocks carry the current document version so resume sessions know which
version they are continuing from:

```
Document: design-document-v1.2.0.md
Version: v1.2.0
```

When a resume session produces an updated document, the version is incremented
before the save block is produced again.

## Relationship to Other Conventions

- Save block format is defined per framework, not here
- Version numbers carried in save blocks follow this convention
- chat-session-management.md references this convention for save block version fields
