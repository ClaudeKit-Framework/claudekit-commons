# Session Boundary Rules

Defines how Claude Code enforces session scope. Scope never expands silently.
Every boundary crossing is a deliberate user decision, recorded in `project-state.json`.

## Session Contract

Every session opens with a `session-contract.json` generated from the scope plan.
Claude Code reads it at session start and at every task boundary.

The contract defines:
- `permitted_files` — paths Claude Code may read or modify
- `permitted_actions` — operations allowed (`create`, `edit`, `delete`, `run`)
- `explicitly_excluded` — paths Claude Code must not touch under any circumstances
- `decision_authority` — scope of decisions Claude Code may make without stopping

## Stop Conditions

Stop conditions are listed explicitly in the session contract. When one triggers mid-session:

```
⚠ STOP CONDITION TRIGGERED — [stop-NNN]
  Reason: [description]
  File/context: [detail]

  Options:
  [ ] Pause and discuss — should this session scope expand?
  [ ] Note and continue without touching out-of-scope file
      # A stub or placeholder will be used instead
  [ ] End session and replan
      # Recommended if this changes the session significantly
```

The user chooses. Claude Code does not proceed past a stop condition unilaterally.
The decision and its reason are recorded in `project-state.json`.

## Depth Limiting

When Claude Code encounters something that would benefit from deeper investigation,
it flags and moves on rather than digging in:

```
ℹ Noted for later — [flag-NNN]
  [description of what was noticed]
  Flagged for a future session. Continuing with current objective.
```

Depth limits are set per-session in the session contract:

| Area | Default behaviour |
|---|---|
| `investigate` | Surface only — flag for dedicated session if deeper work is needed |
| `optimise` | Not in scope unless explicitly listed in objectives |
| `refactor` | Not in scope unless explicitly listed in objectives |

## Scope Expansion

If a stop condition triggers and the user chooses to expand scope:
1. The expansion is confirmed explicitly in plain language before any work proceeds
2. The expanded scope is recorded in `project-state.json` with a timestamp and reason
3. The session contract is not rewritten mid-session — the record in `project-state.json` is the authoritative log of what actually happened

## Architectural Decisions

Claude Code may not make architectural decisions within a session unless `decision_authority`
in the session contract explicitly permits it. When an architectural decision is required
and not permitted, it is a stop condition.
