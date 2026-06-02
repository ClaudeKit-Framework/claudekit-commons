# ClaudeKit — Design Summary

> **Status:** Pre-build design review document  
> **Version:** 0.7  
> **Last updated:** June 2026

---

## What It Is

ClaudeKit is an open source ecosystem of frameworks that guide anyone — from complete beginner to experienced developer — through the full process of designing, planning, building, and securing software projects using AI. It is built for Claude initially, with architecture that supports other AI tools in future.

---

## The Ecosystem

### Name
**ClaudeKit** — working name, subject to change as the project grows beyond Claude.

### Home
- **GitHub organisation:** ClaudeKit-Framework (github.com/ClaudeKit-Framework)
- **Website:** hosted, beginner-friendly human layer, primary entry point for non-technical users. Mobile interface required.
- **GitHub Discussions:** community Q&A, show and tell, ideas — linked from website and all READMEs

---

## Repository Structure

```
github.com/ClaudeKit-Framework/
├── claudekit-commons/          ← shared contracts, schemas, init tooling
├── claudekit-guardrails/       ← rebuilt from local files, integrated into ecosystem
├── claudekit-design/           ← new: project design framework
├── claudekit-scope/            ← new: scope and session planning
└── claudekit-runner/           ← new: runtime engine
```

---

## The Frameworks

### 1. Guardrails
*Rebuilt from local files of the deleted Claude-Code-Guardrails repo, integrated into ClaudeKit ecosystem under ClaudeKit-Framework org*

Security, compliance and privacy controls for AI-assisted coding. Prevents credential leaks, enforces governance, creates audit records. Existing solo and team variants retained.

- **Interface:** Claude Code only
- **Users:** developers adding governance to existing or new projects
- **Existing content:** local files preserved, extended, and recommitted to new repo

---

### 2. Project Design
Structured discovery conversation that helps users articulate what they're building — goals, constraints, stakeholders, tech decisions, risk flags, assumptions.

- **Interface:** Claude chat (primary) or Claude Code
- **Users:** anyone starting a new project, beginner to experienced
- **Output:** design document with confirmed decisions, flagged assumptions, deferred decisions, and unknowns clearly labelled
- **Note:** status counts in output are normalised explicitly so users don't feel incomplete documents are failures

---

### 3. Scope Planner
Converts the design document into a structured AI execution plan. Phases, sessions, dependencies, version pre-flight, manual action identification.

- **Interface:** Claude chat (primary) or Claude Code
- **Users:** anyone moving from design into build planning
- **Output:** scope plan with phases, sessions, sequencing, declared stack, and identified manual actions
- **Stack declaration:** confirmed or flagged as assumption, never a hard gate
- **Flag integration:** open flags surface as candidate session objectives during planning

---

### 4. Session Runner (Runtime Engine)
The execution layer. Manages sessions, tracks progress, enforces session scope, records all changes and decisions, verifies dependencies at action time, handles manual action prompts, detects and manages divergence, handles errors and failures.

- **Interface:** Claude Code only
- **Users:** anyone in active build phase
- **Output:** continuously updated project-state.json, per-task records, session change narrative, updated stack-manifest.json, session handoff documents

---

### 5. Commons
Not a user-facing framework — the shared contract layer that all other frameworks reference.

**Contains:**
- **Schemas:** project-state, stack-manifest, handoff, session-contract, task-record, flag
- **Conventions:** manual action block format, phase gate spec, session boundary rules, documentation requirements, dependency policy
- **Init tooling:** setup script, update script, framework manifests
- **known-incompatibilities.json:** curated list of version combinations known to cause issues, maintained alongside framework updates
- **COMPATIBILITY.md:** framework version matrix

---

## Development Environment

| Tool | Detail |
|------|--------|
| OS | Linux Mint |
| IDE | VS Code with Claude Code |
| GitHub org | github.com/ClaudeKit-Framework |
| Local Guardrails files | Preserved locally, to be committed to new claudekit-guardrails repo |

---

## Key Design Elements

### User Profile and Communication Preferences

Captured at three points: website Before You Start guide (sets expectations), init script (recorded in project-state.json, governs Claude Code behaviour), and chat starter prompts (asked at the start of each conversation, carried in the save block).

**Three independent questions:**

```
How familiar are you with software development?
  [ ] New to this entirely
  [ ] Some experience
  [ ] Experienced developer

How do you prefer explanations?
  [ ] Plain language — avoid jargon, explain the why
  [ ] Balanced — clear but don't over-explain
  [ ] Technical — precise language, skip the basics

For instructions, do you want:
  [ ] Step by step — every action spelled out explicitly
  [ ] Outcomes only — tell me what to achieve, I'll figure out how
```

**Stored in project-state.json:**
```json
"user_profile": {
  "experience_level": "new | some | experienced",
  "explanation_depth": "plain | balanced | technical",
  "instruction_detail": "step_by_step | outcomes_only"
}
```

**How it flows through the frameworks:**
- Claude Code reads these fields via CLAUDE.md at the start of every session and adjusts tone, depth, and context accordingly
- Chat starter prompts ask the questions directly; save block carries answers forward so they're never asked twice
- Revisited as a soft prompt at the start of each new phase — not every session
- Changeable anytime via `/set-communication` command

```
You're starting Phase 2. Your current preferences are:
Plain language · Step by step
→ Would you like to keep these or adjust them? (keep/change)
```

---

### The Manual Action System
Consistent format used from the very first user interaction through every session:

```
⚠ MANUAL ACTION REQUIRED — [action_id]
Action: description in plain language
Why: reason this needs a human
Estimated time: x minutes
→ Do you need step-by-step instructions? (y/n)
→ Type 'done' when complete, or 'skip' to flag and continue
```

- Action IDs tie to project-state.json
- Skipped actions resurface in pre-flight rather than disappearing
- Step-by-step instructions always available on request
- If a dependency check cannot be completed (no network), the install is deferred as a manual action rather than proceeding unverified

---

### Progress Tracking and Change Documentation

Keeping Claude Code on track and ensuring complete records of everything done is critical. Two distinct mechanisms address this — scope containment (preventative) and progress and change documentation (generative).

#### Scope Containment

**The session contract**

Every session opens with a `session-contract.json` — an explicit, machine-readable boundary document generated from the scope plan and read by Claude Code at session start and at every task boundary:

```json
{
  "session_id": "session-005",
  "phase": "2",
  "scope": {
    "permitted_files": ["src/auth/", "src/middleware/auth.js"],
    "permitted_actions": ["create", "edit"],
    "explicitly_excluded": ["src/database/", "tests/"],
    "decision_authority": "implementation only — no architectural decisions"
  },
  "objectives": [
    "Implement JWT middleware",
    "Add token validation to auth routes"
  ],
  "stop_conditions": [
    "Any file outside permitted_files needs modification",
    "A dependency not in stack-manifest needs adding",
    "An architectural decision is required"
  ],
  "depth_limit": {
    "investigate": "surface only — flag for dedicated session if deeper investigation needed",
    "optimise": "not in scope unless explicitly listed in objectives",
    "refactor": "not in scope unless explicitly listed in objectives"
  },
  "dependency_policy": {
    "version_pinning": "exact",
    "auto_update_patch": false,
    "require_lock_file_commit": true
  }
}
```

Claude Code never silently expands scope. Every boundary crossing is a deliberate decision made by the user and recorded in project-state.json.

**Stop condition behaviour**

When a stop condition triggers mid-session:

```
⚠ STOP CONDITION TRIGGERED — [stop-001]
  Reason: File outside session scope requires modification
  File: src/database/connection.js

  Options:
  [ ] Pause and discuss — should this session scope expand?
  [ ] Note and continue without touching out-of-scope file
      # A stub or placeholder will be used instead
  [ ] End session and replan
      # Recommended if this changes the session significantly
```

**Depth limiting**

When Claude Code encounters something that would benefit from deeper investigation, it flags and moves on rather than digging in:

```
ℹ Noted for later — [flag-023]
  Potential race condition in token refresh. Flagged for 
  investigation in a future session. Continuing with 
  current objective.
```

---

#### Progress and Change Documentation

**Per-task records**

Documentation happens at the task level, not session level. After every completed task, Claude Code writes a task record to project-state.json before moving to the next task:

```json
{
  "task_id": "task-005-003",
  "session_id": "session-005",
  "objective": "Add token validation to auth routes",
  "status": "complete",
  "completed_at": "timestamp",
  "files_modified": [
    {
      "path": "src/middleware/auth.js",
      "change_summary": "Added validateToken() middleware function",
      "lines_added": 47,
      "lines_removed": 3
    }
  ],
  "decisions_made": [
    {
      "decision": "Used RS256 algorithm instead of HS256",
      "reason": "Scope plan specified asymmetric keys for service-to-service auth",
      "reference": "scope-plan section 3.1"
    }
  ],
  "dependencies_added": [
    {
      "package": "jsonwebtoken",
      "version": "9.0.2",
      "pinned": true,
      "verified_at": "timestamp",
      "licence": "MIT"
    }
  ],
  "flags_raised": ["flag-023"],
  "next_task_notes": "Token validation complete. Route integration next."
}
```

If a session is interrupted after a task completes, the record is already written — nothing is lost.

**The session change narrative**

At session end, Claude Code produces a plain language summary written to project-state.json and surfaced at the next session's pre-flight:

```
SESSION 005 — COMPLETE

What was done:
JWT middleware implemented with RS256 token validation.
Auth routes now validate tokens before passing to handlers.
Token refresh logic deferred — requires database session
handling which is out of scope for this session.

Key decisions:
RS256 chosen over HS256 per scope plan (asymmetric keys
required for service-to-service auth).
Token expiry set to 15 minutes — matches security
requirements in design document section 4.2.

Dependencies added:
jsonwebtoken 9.0.2 (pinned, MIT licence, verified clean)

What the next session needs to know:
Token refresh not implemented. src/auth/refresh.js is a stub.
Flag flag-023 covers race condition risk — address before
refresh is implemented.

Flags raised this session:
flag-023 — potential race condition in token refresh
flag-024 — database connection pooling may need review
           before load testing
```

**Code documentation as a session requirement**

A task is not marked complete until:
- Functions have docstrings or inline comments explaining purpose and parameters
- Non-obvious decisions have inline comments explaining why, not just what
- Temporary workarounds are marked with a `TODO` and a flag reference
- README or relevant documentation updated if the change affects how the project is used

Documentation depth is specified in the session contract — prototype sessions may require lighter documentation than production sessions.

---

### The Flags System

Flags are first-class objects — not notes, but deferred decisions and risks with resolution paths. Each flag has:

- Unique ID tied to the session it was raised in
- Description of what was noticed
- Priority: address before next task / address before phase end / address before launch
- Suggested session type for resolution: investigation / implementation / review
- Status: open / scheduled / resolved

**Flag integration:**
- Raised automatically by Claude Code when depth limits are triggered or stop conditions are noted without action
- Raised manually by the user via `/report-error` or during session review
- Surface in pre-flight at every session start
- Open flags with "address before phase end" priority automatically surface as candidate session objectives when the Scope Planner plans the next phase
- Resolved flags retained in project-state.json for audit trail

---

### Dependency and Compatibility Verification

Accurate dependency management is critical. Claude Code's training data has a knowledge cutoff — it cannot be trusted to know current versions, recent breaking changes, or live compatibility matrices. Two layers of verification prevent this from causing build failures.

#### Layer 1 — Pre-Session Stack Verification

Runs at session start as part of pre-flight. Checks the declared stack against reality before any code is touched.

**Runtime version check**
```
⚠ Runtime mismatch detected
  Declared in stack-manifest: Node.js 20.x
  Installed on this machine:  Node.js 18.14.0

  → Update Node.js to 20.x / Continue anyway / Update stack-manifest
```

**Dependency tree integrity**
Undeclared dependencies — installed but not in stack-manifest — flagged as unknowns:
```
⚠ Undeclared dependency detected
  Found in package.json but not in stack-manifest: axios 1.6.2
  Likely added outside a ClaudeKit session.
  → Add to stack-manifest / Flag for review / Skip
```

**Known incompatibility check**
Stack checked against `known-incompatibilities.json` in commons:
```
⚠ Known incompatibility detected
  react 18.x + react-router 5.x
  React Router 5 does not support React 18's concurrent features.
  Suggested: upgrade to React Router 6.x
  → View details / Flag for later / Acknowledge
```

**Deprecation warnings**
Deprecated packages flagged with suggested migration path:
```
ℹ Deprecation notice
  request 2.88.2 is deprecated and unmaintained.
  Suggested replacement: node-fetch or axios
  → Flag for migration session / Acknowledge
```

**Verification cadence**
- Per-session: direct dependencies and runtime
- Per-phase: full dependency tree including transitive dependencies
- `last_verified` field in stack-manifest tracks when each dependency was last checked
- Dependencies not verified in several sessions surface in pre-flight as due for review

---

#### Layer 2 — At-Action Dependency Verification

Every time Claude Code wants to add, upgrade, or remove a dependency during a session, it verifies against the live registry before executing. Claude Code never assumes a version is current.

**Before adding a new dependency:**
```
DEPENDENCY CHECK — before installing uuid 9.0.0
─────────────────────────────────────────────────
Latest stable version:    9.0.1
Version to be installed:  9.0.0
Runtime compatibility:    ✓ requires >=12, installed 20
Peer dependencies:        none required
Known issues at 9.0.0:    none
Licence:                  MIT ✓
Last published:           3 months ago ✓
Weekly downloads:         45M ✓

Recommendation: install 9.0.1 instead of 9.0.0
→ Install 9.0.1 / Install 9.0.0 as specified / Cancel
```

**Before upgrading an existing dependency:**
```
UPGRADE CHECK — react-query 4.x → 5.x
─────────────────────────────────────────────────
This is a major version upgrade. Breaking changes detected:

  - useQuery API signature changed
    v4: useQuery(key, fn, options)
    v5: useQuery({ queryKey, queryFn, ...options })

  - onSuccess/onError callbacks removed from useQuery
    Migration: use mutation callbacks or useEffect

  Affected files in this project: 7 files detected

This upgrade requires code changes beyond dependency install.
→ Proceed with awareness / Abort / Schedule as dedicated migration session
```

**Before removing a dependency:**
```
REMOVAL CHECK — lodash
─────────────────────────────────────────────────
Lodash is imported in 12 files in this project.
Removing it without updating those imports will break the build.

Affected files: src/utils/format.js (4 imports), src/utils/array.js (7 imports)...

→ View all affected files / Abort / Proceed anyway (will break build)
```

**If verification cannot run (no network):**
Claude Code does not guess. The install is deferred as a manual action with the information it does have, and the session continues without the unverified dependency.

---

#### Version Pinning as Default Behaviour

All dependencies pinned to exact versions by default — not ranges:
- `"react": "18.2.0"` not `"react": "^18.2.0"`
- Documented in CLAUDE.md as a non-negotiable default
- Lock files committed alongside every dependency change
- Pinning behaviour configurable per-session in the session contract if ranges are explicitly required

---

#### The Stack Manifest as a Living Document

`stack-manifest.json` is continuously maintained — updated after every session that touches dependencies:

```json
{
  "runtime": {
    "node": "20.11.0",
    "npm": "10.2.4"
  },
  "dependencies": {
    "react": {
      "version": "18.2.0",
      "installed": "18.2.0",
      "declared_at": "session-002",
      "last_verified": "session-006",
      "licence": "MIT",
      "known_issues": [],
      "peer_requirements": {
        "react-dom": "18.x"
      }
    }
  },
  "last_full_audit": "session-006",
  "next_audit_due": "session-010"
}
```

---

#### Compatibility Gates at Phase Boundaries

Before a new phase begins, a full compatibility audit runs as part of the phase gate — more thorough than per-session pre-flight:

- Full dependency tree checked for conflicts including transitive dependencies
- All peer dependency requirements verified against installed versions
- Known incompatibilities checked against the entire stack
- Deprecated dependencies with no scheduled resolution escalated from informational to required action
- Phase cannot begin until all escalated items are resolved or acknowledged

---

### project-state.json
Travels with the user's project. Single source of truth across all frameworks and sessions.

**Contains:**
- User profile: experience level, explanation depth, instruction detail
- Session history: planned, completed, skipped, blocked
- Session change narratives: plain language summary from each completed session
- Per-task records: files modified, decisions made, dependencies added, flags raised
- Flags: open, scheduled, resolved — with priority and resolution path
- Assumptions: flagged unknowns with resolution triggers
- Manual action status: completed, skipped, pending
- Divergence log: every divergence, decision, and replan with timestamp and reason
- Stack declaration: confirmed or undecided
- Framework versions: what was installed and when
- Session lock: prevents simultaneous session conflicts
- Ownership: framework owner identifier
- Security audit status: findings summary, unresolved items, acknowledgements
- Backup: automatic copy before every write

---

### Pre-Flight Check

The pre-flight check at session start is a full context restoration and stack verification:

```
SESSION 006 PRE-FLIGHT
─────────────────────────────────────────
✓ Runtime versions — Node 20.11.0 matches stack-manifest
✓ Dependency tree integrity — all dependencies declared
✓ Known incompatibilities — none detected
✓ project-state.json — valid
✓ No interrupted sessions

DEPRECATION NOTICES (non-blocking):
ℹ request 2.88.2 — deprecated, no migration scheduled

CONTEXT FROM LAST SESSION (005):
JWT middleware complete. jsonwebtoken 9.0.2 added (pinned).
Token refresh not implemented (stub in place). Two flags raised.

UNRESOLVED FLAGS:
⚠ flag-023 — race condition risk in token refresh
   Priority: address before refresh implemented
⚠ flag-024 — database connection pooling review needed
   Priority: before load testing

UNRESOLVED ASSUMPTIONS:
ℹ assumption-003 — expected user volume unconfirmed
   Review trigger: before load testing phase

THIS SESSION SCOPE (006):
Objectives: Implement token refresh, integrate auth routes
Permitted files: src/auth/, src/routes/auth.js
Stop conditions: [3 conditions]
Dependency policy: exact pinning, lock file commit required

Ready to begin? (y/n)
```

---

### Divergence System

**Five types, identified by Claude where possible, confirmed with user before action:**

| Type | Description | Response |
|------|-------------|----------|
| Approach isn't working | Implementation problem | Replan at session level |
| Scope change | Feature added, cut or restructured | Replan at phase level |
| Fundamental pivot | Design-level problem | Return to Project Design |
| External blocker | Obstacle outside the project | Park and resequence |
| Manual action failed | Dependency failure | Assess impact, resequence or replan |

**Detection:**
- Claude identifies automatically: manual action failed, external blocker, approach isn't working
- Claude asks to confirm: scope change, fundamental pivot

**Diagnostic conversation — two questions maximum:**
```
Is this about what you want to build, or how you're building it?
Has the core purpose changed, or just the features and approach?
```

**Confirmation before any action:**
```
It sounds like [description of what changed].
I'd treat this as [divergence type] — that means [plain 
language explanation of what happens next].

Does that sound right, or is something else going on?
```

**Feedback prompted by:** fundamental pivot resolution and external blocker resolution only.

---

### Error and Failure Handling

**Five failure types with distinct responses:**

**Session interrupted**
- project-state.json and per-task records written continuously — not just at session end
- Pre-flight detects interrupted state on restart
- Default: resume from interruption
- Options: restart session, mark complete (with warning)

**Partial completion**
- Audited at session close
- Default: carry remainder into next session
- Options: create new session for incomplete items, mark as intentionally skipped
- Skipped items tracked and resurface in pre-flight

**Claude made an error**
- Post-task validation against scope plan acceptance criteria after each task
- `/report-error` command for user-reported errors
- Structured conversation to identify scope of problem before any remediation
- Three options: fix now, continue and fix later, update scope plan if scope was wrong

**State file corruption**
- Validated against commons schema at session start
- Session blocked until resolved
- Options: automatic repair, manual review, restore from backup
- Automatic backup kept after every session write

**Unrecoverable state**
- Framework acknowledges when human judgment is required
- Clear summary of what's known and what's unclear
- `/resume-session` to continue after user decision
- Option to think through the problem with Claude's help

---

### Update System

**Three update types:**

| Type | Definition | Behaviour |
|------|------------|-----------|
| Non-breaking (patch/minor) | New files, improved non-custom files | Applied automatically with notification |
| Soft breaking (major) | Changes to user-customisable files | Merge conversation required |
| Hard breaking (commons change) | Schema or contract layer changes | Migration session required |

**Security fixes** are always flagged as strongly recommended regardless of update preferences, using patch version bumps (x.x.1) to signal priority.

**Version check mechanism:**
- Lightweight GitHub API call at session start
- Fails silently if offline (3 second timeout)
- Results cached to avoid rate limiting
- `api.github.com` must be in `.claude/settings.json` allowed list

**Update notification proportional to severity:**
```
ℹ Non-breaking — apply now or later
⚠ Soft breaking — merge review required
✗ Hard breaking — migration session required, continue on current version recommended
```

**User control:**
- Skip version entirely
- Remind at end of current phase
- Don't check until asked (`/check-updates`)

---

### Multi-Person Projects

**Current support:**
- One active session at a time: reliable
- Manual actions assignable to specific people: supported
- Framework owner / contributor split: documented convention
- Simultaneous sessions: causes state conflicts — not supported
- Access control / permissions: not in scope for this version

**Session lock:** `project-state.json` records open session with identifier and timestamp. Second user attempting to open a session sees a warning with options to wait, override (explicit choice only), or check with collaborator.

**Two roles:**
- Framework owner: runs init, applies updates, manages state, makes scope decisions
- Session contributor: runs sessions, completes manual actions, reports errors

**Git as mitigation:** committing `project-state.json` and `stack-manifest.json` after every session surfaces conflicts as merge conflicts rather than silent overwrites. Recommended practice for all team projects.

**Full team support:** future update. GitHub Discussions is the feedback channel for team usage edge cases.

---

### Resume and Continuity in Chat

Chat frameworks (Project Design, Scope Planner) have no memory between sessions. Handled by a portable context block produced at every natural pause point:

```
── SAVE THIS TO RESUME ──────────────────────────────
Framework: Project Design
Status: In progress
Completed: Problem statement, target users, success criteria
Parked: Data sensitivity (user unsure — flagged for later)
Next: Constraints and timeline
Communication preferences: Plain language · Step by step
Last updated: [date]

[structured summary of everything captured so far]
── END SAVE BLOCK ───────────────────────────────────
```

- Human-readable — user can recognise their own project in it
- Saved to notes app, Google Doc, or text file
- Resume starter prompt variant reads save block and continues from next item
- Communication preferences carried forward — never asked twice
- Resume flow: new chat → paste resume prompt → paste save block → continue

---

### The "I Don't Know" System

**Five types with distinct responses:**

| Type | Description | Response |
|------|-------------|----------|
| Genuinely undecided | Could decide with guidance | One simpler question to help decide |
| Outside their knowledge | Lacks information to answer | Plain language explanation, flag for later option always available |
| Doesn't matter yet | Premature question | Acknowledge and move on, note as build-time decision |
| Genuinely unknowable | Depends on future events | Record as assumption, confirm with user, flag in document |
| Avoidance | Overwhelmed or anxious | Step back, reframe with simpler human-centred question |

**Assumptions as first-class citizens:**
- Clearly labelled in design document
- Flagged in project-state.json
- Review trigger attached — specific session or pre-flight reminder
- Design document status summary normalises assumptions explicitly

---

### Security Audit on Merge *(scoped, detail to be designed)*

When Guardrails is selected and an existing project is detected, a security audit runs before any framework files are copied. The audit reviews existing files, directories, and git history for current and historical security issues.

**Key decisions:**
- Audit runs as part of the Guardrails merge flow, before file installation
- Scans existing project files, directory structure, and full git history
- Covers a broad range of security concerns including but not limited to secrets, exposed credentials, unsafe files, dependency vulnerabilities, and historical commits — full scope to be defined in a dedicated future design session
- Findings categorised by severity with appropriate response paths per category
- Critical findings gate the merge — must be resolved or explicitly acknowledged with a recorded reason before proceeding
- Acknowledgements recorded in project-state.json with reason and timestamp
- Full findings written to `SECURITY-AUDIT.md` in the project root
- Unresolved findings carried as manual actions in project-state.json and surfaced in pre-flight

---

## User Journey

```
WEBSITE
└── Before You Start guide
    └── What you need, what to expect, plain language intro
    └── Communication preferences captured (sets expectations)

CLAUDE CHAT
└── Project Design conversation
    │   Communication preferences asked first
    │   Starter prompt → guided interview → design document
    │   Save block produced at every pause point (includes preferences)
    └── Scope Planner conversation
        │   Starter prompt + design document → scope plan
        │   Stack declared or flagged as assumption
        │   Open flags surface as candidate session objectives
        └── Handoff to Claude Code instructions produced

CLAUDE CODE
└── Init script
    │   Framework selection (Guardrails, Session Runner) → variant → stack
    │   Security audit (existing projects with Guardrails selected)
    │   Communication preferences captured → stored in project-state.json
    │   Confirmation → copy files
    └── Session Runner
        │   /start-session → pre-flight (context restoration + stack verification)
        │   Session contract loaded → scope and dependency policy enforced
        │   Session execution → per-task records written continuously
        │   At-action dependency verification before every install/upgrade/removal
        │   Stop conditions enforced → flags raised → manual action prompts
        │   Divergence handling → error handling
        └── /end-session → change narrative written → stack-manifest updated → state updated → handoff produced
```

---

## Init Script Flow

**Step 1a — Project detection**
- Empty / git only → clean init
- Framework markers found → update / merge mode
- Code but no framework files → merge mode with conflict handling

**Step 1b — Security audit** *(existing projects with Guardrails selected only)*
- Scans existing files, directories, and git history
- Findings presented by severity
- Critical findings resolved or acknowledged before proceeding
- SECURITY-AUDIT.md written to project root
- Unresolved findings recorded in project-state.json

**Merge handling:**
- Diff each file before writing
- Three options per conflict: keep yours, use framework, show diff
- merge-report.md written after completion
- Merge report recorded as manual action in project-state.json

**Step 2 — Framework selection**
Project Design and Scope Planner are chat-native frameworks accessed via the website and starter prompts — they install no files into the project and are not selectable here.

```
  [x] Guardrails
      # Security, compliance and privacy controls for AI coding.
        Prevents credential leaks, enforces governance, creates audit records.

  [x] Session Runner
      # Runtime engine for executing sessions safely.
        Progress tracking, manual action prompts, handoff validation.
```

Incompatible or dependent combinations flagged before proceeding.

**Step 3 — Variant selection** (frameworks with variants only)

**Step 4 — Stack declaration**
```
  [ ] Node.js / TypeScript
  [ ] Python
  [ ] Go
  [ ] Ruby
  [ ] Other (configure manually)
  [ ] Not decided yet (pre-flight version checks skipped until set)
  [ ] I'm not sure what this means
```
"Not sure what this means" explains in plain language before asking again. "Not decided yet" records as assumption, never blocks init.

**Step 5 — Communication preferences**
```
How familiar are you with software development?
  [ ] New to this entirely
  [ ] Some experience
  [ ] Experienced developer

How do you prefer explanations?
  [ ] Plain language — avoid jargon, explain the why
  [ ] Balanced — clear but don't over-explain
  [ ] Technical — precise language, skip the basics

For instructions, do you want:
  [ ] Step by step — every action spelled out explicitly
  [ ] Outcomes only — tell me what to achieve, I'll figure out how
```

**Step 6 — Confirmation**
Full file list shown before anything is written. No existing files overwritten without confirmation.

**Step 7 — Fetch and copy**
Shallow clone to temp directory, copy selected files only, clean up. User project contains files only — no live framework repo dependency.

**Step 8 — Post-init**
COMMANDS.md written to project. Manual actions for required setup steps produced. Full command reference printed.

---

## Commands

**In Claude Code:**

| Command | When to use |
|---------|-------------|
| `/help` | Any time — full command reference |
| `/start-session` | Begin or resume a working session |
| `/end-session` | Close a session and save progress |
| `/resume-session` | Continue after an interruption |
| `/report-error` | Flag something that went wrong |
| `/revise-scope` | Trigger a replanning conversation |
| `/set-stack` | Declare or update tech stack |
| `/set-communication` | Update communication preferences |
| `/check-updates` | Manually check for framework updates |
| `/check-dependencies` | Run a manual dependency verification pass |
| `/security-review` | OWASP checklist review |
| `/compliance-check` | Regulatory assessment |
| `/create-adr` | Record an architectural decision |
| `/view-flags` | Review all open flags and their priority |
| `/resolve-flag` | Mark a flag as resolved with reason |

**In Claude Chat:**
Starter prompts linked from website and READMEs — Project Design, Scope Planner, Scope Revision, Resume variants for each.

**Terminology note:** "commands" used consistently in all user-facing content rather than "slash commands."

---

## Onboarding and Website

**Website purpose:** human-friendly entry point for complete beginners. Mobile interface required. GitHub repos are the technical reference layer. Website is the human layer.

**Before You Start guide covers:**
- What ClaudeKit is in plain language
- What Claude chat and Claude Code are, when each is used
- What to expect — conversational, guided, step by step
- What it costs
- Communication preferences introduction — helps users self-identify before they start
- Prerequisites checklist with manual action blocks
- One clear call to action

**Plain language terminology established before any content is written:**

| Term | Plain language definition |
|------|--------------------------|
| Claude chat | A conversation interface at claude.ai |
| Claude Code | A tool that works alongside your code editor |
| Framework | A set of guides and templates that structure the process |
| Session | A focused working period with a clear goal |
| Manual action | A step you complete yourself outside the AI conversation |
| Phase | A stage of your project with related sessions grouped together |
| Flag | A noted risk or deferred decision that needs attention later |
| Dependency | An external package or library your project relies on |
| Stack | The combination of languages, frameworks and tools your project uses |

**Emotional journey designed explicitly:**
- First encounter with technical language — terms introduced slowly, in context
- First "I don't know" moment — primed for in Before You Start guide
- First manual action — simplest possible action first
- First technical install — deferred until after design and planning complete
- First session in Claude Code — "what to expect" section in scope plan output
- First error or failure — tone explicitly reassuring throughout

---

## Community

**GitHub Discussions categories:**
- Q&A — got stuck, ask here
- Show and tell — built with ClaudeKit
- Ideas — roadmap input

---

## Build Sequence (Bootstrap Resolution)

ClaudeKit is built using ClaudeKit where possible. The bootstrap problem — frameworks don't exist when you start building them — resolves in stages:

**Stage 1 — Design and planning in chat** *(in progress)*
This document is the evolving output. Equivalent to Project Design and Scope Planner artifacts produced manually.

**Stage 2 — Build commons and guardrails**
- Original Claude-Code-Guardrails GitHub repo deleted — local files preserved and will be used to seed claudekit-guardrails
- Commons has no dependencies on other ClaudeKit frameworks
- Manual session tracking using this document as persistent context
- GitHub org created: github.com/ClaudeKit-Framework
- Org settings configured — repos not yet created

**Stage 3 — Build Session Runner**
Manual state tracking until functional. Switch to using Session Runner for remaining build work as soon as viable.

**Stage 4 — Build remaining frameworks using ClaudeKit**
Project Design, Scope Planner, and website built using functional ClaudeKit. Full dogfooding begins. Real gaps between design and reality surface here.

---

## Risk Register

### Technical Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Schema drift between repos | High | Commons update required in every PR template |
| Shell script portability across OS | High | Primary dev environment is Linux Mint — test on Mac and Windows before release |
| GitHub API dependency for version checks | Medium | Fail silently, 3s timeout, cache results |
| project-state.json as single point of failure | High | Automatic backup before every write, validation on every read, clear recovery path |
| Claude Code permission changes breaking hooks | Medium | Keeping Current checklist, monitor Claude Code releases |
| Init script network dependency | Medium | Clear error messaging, network requirement in Before You Start, downloadable bundle as future option |
| Out of date COMMANDS.md after framework update | Low | Framework updates that change commands include COMMANDS.md update in update script |
| Security audit false negatives | High | Audit scope designed conservatively, findings err toward flagging, full scope designed in dedicated future session |
| Session contract becoming out of sync with scope plan | Medium | Session contract generated from scope plan at session start, not manually authored |
| Flag accumulation without resolution | Medium | Flags with phase-end priority surface automatically in Scope Planner before phase closes |
| known-incompatibilities.json becoming stale | High | Reviewed and updated on same cadence as framework releases, community issues feed new entries |
| Registry API unavailable during at-action verification | Medium | Deferred as manual action when network unavailable, never skipped silently |
| Transitive dependency conflicts not caught per-session | Medium | Full tree audit at phase boundaries catches accumulated drift |
| Local guardrails files diverging from intended design | Medium | Review all local files against design summary before committing to new repo |

### User Experience Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Beginner abandonment at Claude Code install | High | Exceptional website install guidance, scope plan prepares user, step-by-step always available |
| Chat session loss without save block | Medium | Save block at every pause point, website explains memory limitations upfront |
| Framework version confusion mid-project | Medium | Version visible in pre-flight, documentation versioned, older versions remain accessible |
| Divergence handling overwhelm | Medium | Tone explicitly normalising throughout, website addresses in "what to expect" |
| Manual action fatigue | Medium | Reserved for genuinely necessary steps, consistent scannable format, skip always available |
| Weak design document flowing into weak scope plan | Medium | Scope Planner starter prompt includes lightweight validation of design document before proceeding |
| Communication preferences not reflecting reality mid-project | Low | Soft prompt to review at each phase boundary, changeable anytime via /set-communication |
| Security audit overwhelming a beginner with findings | Medium | Findings presented one severity level at a time, plain language explanations, step-by-step resolution always available |
| Stop conditions feeling punitive rather than helpful | Medium | Tone of stop condition prompts is collaborative not blocking, user always has options including scope expansion |
| Pre-flight context becoming too long to read | Medium | Pre-flight output structured with most critical items first, collapsible detail for flags and assumptions |
| Dependency check interruptions feeling disruptive | Medium | Checks presented as a natural part of the workflow, plain language output, recommendation always provided |

### Maintenance Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Single maintainer dependency | High (long term) | Contribution guide from day one, clear issue templates, open source community |
| Starter prompt degradation across Claude model updates | High | Prompts treated as first-class deliverables, versioned, tested across model versions, in Keeping Current checklist |
| Claude model behaviour differences between chat and Code | Medium | Prompts tested across model versions, noted in Keeping Current checklist |
| Scope creep in ClaudeKit itself | Medium | Use ClaudeKit frameworks to build ClaudeKit — dogfooding enforces discipline |
| Legal and compliance reference accuracy | High (regulated environments) | Existing disclaimer carried forward, standards accuracy issue template, periodic review |
| Security audit coverage becoming outdated | High | Audit scope versioned and reviewed on same cadence as Guardrails, new threat patterns added via standard update process |

### AI-Assisted Development Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Context window loss between build sessions | High | This document is persistent context, key decisions recorded explicitly, each session reviews prior decisions |
| Inconsistency across frameworks built in separate sessions | Medium | Commons conventions written first, terminology glossary established before building |
| Subtle bugs in AI-generated shell scripts | High | Highest review priority, manual testing across environments, kept as simple as possible |
| Starter prompt quality as a hidden dependency | High | Starter prompts treated as first-class deliverables, reviewed and tested before release, versioned explicitly |
| Assumption rot in long projects | Medium | Pre-flight checker surfaces unreviewed assumptions at phase boundaries, not just when directly triggered |
| Website as critical path dependency for beginners | Medium | GitHub READMEs remain functional fallbacks, Before You Start content duplicated there |
| Claude Code ignoring session contract boundaries | High | Session contract read at start and every task boundary, stop conditions explicit and machine-readable, CLAUDE.md reinforces boundary compliance |
| Per-task documentation becoming boilerplate | Medium | Documentation requirements scaled to session type in session contract, reviewed for quality not just presence |
| Claude Code using outdated version knowledge | High | At-action verification against live registry mandatory, never assumes version currency, defers to manual action when offline |

---

## Open Questions

| Question | Resolution |
|----------|------------|
| Full team / multi-person collaboration support | Future update |
| Feedback mechanism | Future update, after real users exist |
| Dedicated docs site | Built into website as a future project |
| Full security audit scope | Dedicated future design session |

---

## What Is Not In Scope (This Version)

| Item | Note |
|------|------|
| Support for AI tools other than Claude | Future update |
| Full multi-person collaboration with access control | Future update |
| Automated compliance auditing beyond guardrails | Future hopeful update |
| Billing, authentication, or user accounts | Not applicable |
| Full security audit implementation | Scoped, detail to be designed in dedicated future session |

---

*This document serves as both the design review artifact and the persistent build context for ClaudeKit development. It should be referenced at the start of every build session until project-state.json exists and takes over that role.*
