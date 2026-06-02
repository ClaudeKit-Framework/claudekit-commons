# Manual Action Block

The canonical format for any step that requires a human to act outside the AI conversation.
Used consistently from the first user interaction through every session.

## Format

```
⚠ MANUAL ACTION REQUIRED — [action_id]
Action: description in plain language
Why: reason this needs a human
Estimated time: x minutes
→ Do you need step-by-step instructions? (y/n)
→ Type 'done' when complete, or 'skip' to flag and continue
```

## Fields

| Field | Required | Description |
|---|---|---|
| `action_id` | Yes | Unique ID matching the record in `project-state.json` |
| `Action` | Yes | Plain language description of what the human must do |
| `Why` | Yes | Reason this step cannot be completed by the AI |
| `Estimated time` | Yes | Best estimate in minutes |

## Behaviour Rules

**On `done`:** Mark the action `complete` in `project-state.json` with a timestamp. Continue.

**On `skip`:** Mark the action `skipped` in `project-state.json`. The action resurfaces in pre-flight at every subsequent session start until resolved or explicitly dismissed. Never disappears silently.

**Step-by-step instructions:** Always available on request. Asking for them does not change the action's status or ID.

**Assigned actions:** Manual actions may be assigned to a named person (`assigned_to` in `project-state.json`). The format is unchanged — the assignee field is metadata only.

**Network unavailable:** If a dependency verification cannot run because there is no network, the install is deferred as a manual action with the information available at the time. The session continues without the unverified dependency. Claude never guesses or proceeds unverified.

## ID Format

Action IDs follow the pattern `action-NNN` (e.g. `action-001`). IDs are assigned sequentially and never reused. The ID is the permanent link between the displayed block and the record in `project-state.json`.
