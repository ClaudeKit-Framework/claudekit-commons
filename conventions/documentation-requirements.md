# Documentation Requirements

A task is not marked complete until its documentation requirements are met.
Documentation depth is set per-session in the session contract.

## Per-Task Requirements (Default)

**Functions and methods**
Every function or method must have a docstring or inline comment explaining its purpose
and parameters. The explanation must be specific enough that a reader can understand
the function's role without reading its body.

**Non-obvious decisions**
Any implementation choice that is not the obvious default must have an inline comment
explaining why it was made, not just what it does. This includes algorithm choices,
workarounds, constraints from external systems, and anything that would surprise a reader.

**Temporary workarounds**
Any code that is intentionally incomplete or known to need replacement must be marked:
```
# TODO [flag-NNN]: [brief description of what needs to change and why]
```
The flag ID links the workaround to its resolution record in `project-state.json`.
A TODO without a flag ID is not acceptable.

**User-facing changes**
If a change affects how the project is used — commands, APIs, configuration, behaviour —
the relevant README or documentation file must be updated in the same task.

## Session Contract Overrides

The session contract may specify a documentation level for the session:

| Level | Meaning |
|---|---|
| `full` | All requirements above apply (default) |
| `prototype` | Functions require purpose comments only. Decision comments and README updates may be deferred as flagged TODOs. |

Prototype-level documentation creates a flag for each deferred item so nothing is lost.

## Completion Gate

Claude Code checks documentation requirements before marking a task `complete`.
If requirements are unmet, the task stays `incomplete` and the gap is listed explicitly.
The user may override and mark the task complete anyway — this is recorded in `project-state.json`.
