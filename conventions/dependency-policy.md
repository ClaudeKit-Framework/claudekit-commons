# Dependency Policy

Defines how dependencies are declared, verified, and maintained across all sessions.
Claude Code's training data has a knowledge cutoff — it cannot be trusted to know current
versions or recent breaking changes. Verification against the live registry is mandatory.

## Version Pinning

All dependencies are pinned to exact versions by default.

```
"react": "18.2.0"    ✓
"react": "^18.2.0"   ✗
```

This is a non-negotiable default. It may be changed to `range` per-session only via an
explicit `version_pinning` setting in the session contract, with a recorded reason.

Lock files must be committed alongside every dependency change, without exception.

## At-Action Verification

Every time a dependency is added, upgraded, or removed during a session, Claude Code
verifies against the live registry before executing. It never assumes a version is current.

**Adding a dependency** — checks latest stable version, runtime compatibility,
peer dependencies, known issues, licence, and publish recency before proceeding.
Recommends the latest stable version if the requested version is not current.

**Upgrading a dependency** — identifies breaking changes, lists affected files in the
project, and requires explicit confirmation before proceeding with a major version change.

**Removing a dependency** — checks for imports across the project before executing.
Does not remove a dependency that is still imported without explicit confirmation.

**No network** — if verification cannot run, the action is deferred as a manual action.
Claude Code never guesses or proceeds with an unverified dependency.

## Verification Cadence

| Scope | When |
|---|---|
| Direct dependencies + runtime | Every session pre-flight |
| Full tree including transitive dependencies | Every phase gate |

The `last_verified` field in `stack-manifest.json` tracks when each dependency was last
checked. Dependencies not verified within a configurable number of sessions surface in
pre-flight as due for review.

## Undeclared Dependencies

Dependencies found in the project's package manifest but not in `stack-manifest.json`
are flagged as unknowns at session pre-flight:

```
⚠ Undeclared dependency detected
  Found in package.json but not in stack-manifest: [package] [version]
  Likely added outside a ClaudeKit session.
  → Add to stack-manifest / Flag for review / Skip
```

## Stack Manifest as Source of Truth

`stack-manifest.json` is the authoritative record of the declared stack.
It is updated after every session that touches dependencies.
It is never modified mid-session without a corresponding at-action verification record.
