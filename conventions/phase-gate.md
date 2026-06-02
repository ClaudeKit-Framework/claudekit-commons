# Phase Gate

The full compatibility and state audit that runs before any new phase begins.
More thorough than per-session pre-flight.

## When It Runs

At the boundary between phases, before the first session of the new phase opens.
A phase cannot begin until the gate passes or all blocking items are explicitly resolved.

## Checks

**Dependency tree**
- Full dependency tree checked for conflicts, including transitive dependencies
- All peer dependency requirements verified against installed versions
- Known incompatibilities checked against the entire stack via `known-incompatibilities.json`

**Deprecation escalation**
- Deprecated dependencies with no scheduled resolution are escalated from informational to required action
- Must be resolved or acknowledged before the phase can begin

**Stack manifest integrity**
- All entries in `stack-manifest.json` verified against the declared runtime
- Dependencies installed but not declared flagged as unknowns

**Open flags**
- Flags with `priority: phase_end` that remain unresolved are surfaced as blocking items
- Flags with `priority: launch` are surfaced as warnings if the new phase is the final phase

**Open assumptions**
- Assumptions with a review trigger matching this phase boundary are surfaced for confirmation

## Gate States

| State | Meaning |
|---|---|
| `pass` | All checks clear. Phase may begin. |
| `pass_with_warnings` | Non-blocking items noted. Phase may begin. |
| `blocked` | One or more blocking items unresolved. Phase cannot begin. |

## Resolving a Blocked Gate

Each blocking item must be either:
- **Resolved** — the issue is fixed and the check re-runs clean, or
- **Acknowledged** — the user explicitly accepts the risk with a recorded reason

Acknowledgements are written to `project-state.json` with a timestamp and reason.
Acknowledged items are not blocking but remain visible in subsequent pre-flight checks.

## Output

Gate results are written to `project-state.json` under the relevant session summary.
Blocking items that were acknowledged are retained in the divergence log for audit.
