# Chat Session Management

Defines how chat-native frameworks manage session continuity, trigger new chats,
and handle context degradation. Applies to Project Design and Scope Planner only.
Claude Code session behaviour is governed by session-boundary.md.

## Overview

Chat frameworks have no memory between sessions. Continuity is maintained through
a portable save block produced at defined trigger points. This convention defines
when save blocks are produced, when a new chat is recommended, and how Claude
handles degraded or overloaded context.

## Save Block Triggers

A save block is produced:

- When a natural output document is ready (design document, scope plan)
- When the user requests one
- Before a framework handoff (see Framework Handoff Points)
- When the user indicates they need to pause

A save block is **not** produced after every topic. Save blocks mark meaningful
stopping points — not every exchange.

### Save Block Completeness

Save blocks must be written to be sufficient as the sole
input for document generation in a new chat. This is
especially important when a fresh chat is recommended due
to context degradation.

The "Captured so far" field must contain a complete record
of everything captured in the conversation — every confirmed
decision, assumption, risk, flag, and deferred decision.
Do not summarise. Record in full.

A save block that is too thin to stand alone as document
input is a failed save block.

## New Chat Triggers

A new chat is recommended in five cases:

1. **Framework transition** — moving from one chat framework to the next
   (Design → Scope Planner). Each framework starts fresh with its own starter
   prompt and save block.

2. **Context degradation detected** — Claude identifies that response quality
   is being affected by accumulated context. See Context Degradation.

3. **Out-of-scope item encountered** — a question or task falls outside the
   current framework's purpose. See Out-of-Scope and Context-Heavy Handover.

4. **Context-heavy task required mid-session** — a task would consume
   significant context that the current session needs for its primary work.
   See Out-of-Scope and Context-Heavy Handover.

5. **Explicit user request or failed resume** — user asks for a new chat,
   or a resume attempt fails to restore sufficient context.

## Context Degradation

Context degradation occurs when the accumulated conversation is long enough to
affect Claude's ability to hold earlier detail accurately. Two modes apply:

**Reactive** — Claude signals degradation when it is occurring:

```
I want to flag that this conversation is getting long enough that I may
be losing detail from earlier sections. If you'd like, I can produce a
save block now and you can continue in a fresh chat — that will give
the remaining work a clean context window to work in.

No pressure to do this now. If you'd prefer to keep going, we can, and
I'll flag again if it becomes more of a problem.
```

**Proactive** — if context is already long and a high-context phase is
approaching (for example, the design conversation has been extensive and
output document generation is next), Claude flags this *before* starting
that phase:

```
Starting a new chat to generate the document is a good
option here — your save block contains everything needed
and the document will have a clean context window to work
in. Or I can generate it now if you'd prefer to keep going.
→ Produce save block for a new chat / Generate here
```

**Tone guidance:** degradation signals are normalising, not alarming. The
framing is practical — more room produces better output — not a warning
that something has gone wrong.

## Out-of-Scope and Context-Heavy Handover

When a task falls outside the current framework's scope, or would consume
enough context to meaningfully dilute what remains for the session's primary
work, Claude flags it and offers a handover rather than proceeding:

```
That's worth looking at, but it's outside what this conversation is
set up to do well. If we go into it here, it'll take up context that
[this framework] still needs.

→ Start a new chat for this / Continue here
    # Continuing will use context this session still needs
```

Examples of items that trigger this:
- A new framework being introduced mid-conversation
- A question requiring extended research or deep technical investigation
- A task that belongs to a different framework or phase

**Before any handover**, Claude produces a save block for the current session
so context is not lost. The current session's purpose and remaining work are
preserved.

## Framework Handoff Points

Defined transitions between chat frameworks:

### Project Design → Scope Planner

- **Trigger:** design document is complete and user is ready to plan
- **Action:** save block produced for Project Design session; Scope Planner
  starter prompt and instructions provided
- **Save block carries:** completed design document, communication preferences,
  open assumptions, parked decisions, any flags raised during design

### Scope Planner → Session Runner (Claude Code)

- **Trigger:** scope plan is complete and user is ready to begin building
- **Action:** save block produced for Scope Planner session; Claude Code
  init instructions and runner handoff document provided
- **Save block carries:** completed scope plan, communication preferences,
  declared stack (or assumption flag), open flags, first session objectives

## User Guidance Language

Plain language descriptions for use in framework prompts and website content:

| Trigger | User-facing description |
|---|---|
| Save block at pause | "Save this to pick up where you left off" |
| Save block at document complete | "Your [document] is ready — save this to continue in a new chat" |
| Context degradation (reactive) | "This conversation is getting long — here's how to keep going in a fresh chat" |
| Context degradation (proactive) | "Starting a new chat to generate the document is a good option — your save block has everything needed" |
| Out-of-scope item | "That's worth exploring, but not in this conversation" |
| Framework handoff | "Time to move to the next step — here's what to do" |

## Relationship to Other Conventions

- Save block format and content are defined per framework, not here
- Session Runner session management is governed by session-boundary.md
- Version numbers carried in save blocks follow output-document-versioning.md
