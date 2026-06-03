# Manifest File Entry Fields

Documents the fields recognised in the `files` array of a framework manifest.
There is no formal JSON Schema for manifests — this convention is the authoritative reference.

## Required fields

| Field | Type | Description |
|---|---|---|
| `source` | string | Path to the file in the framework source repo, relative to the repo root |
| `destination` | string | Destination path in the user's project, relative to the project root |
| `conflict_strategy` | string | How to handle a file that already exists — see below |

## Conflict strategies

| Value | Behaviour |
|---|---|
| `create_only` | Write the file only if it does not already exist — never overwrite |
| `merge` | Attempt to merge with the existing file — user reviews conflicts |
| `append` | Append the new content to the end of the existing file |
| `overwrite` | Replace the existing file without prompting |

## Optional fields

### `skip_if_framework_present`

Type: `string[]`

An array of framework IDs. When present, the init script skips installing this file
if any of the listed frameworks are also being installed in the same run.

Use this when two frameworks both ship the same file and the more specific framework's
version should take precedence. The framework that owns the command lists it normally;
the framework that defers lists it with `skip_if_framework_present`.

**Example:**

```json
{
  "source": ".claude/commands/create-adr.md",
  "destination": ".claude/commands/create-adr.md",
  "conflict_strategy": "create_only",
  "skip_if_framework_present": ["guardrails-solo", "guardrails-team"]
}
```

In this example, the runner framework includes a generic `create-adr.md` command,
but skips it when either guardrails variant is also being installed — because guardrails
ships its own version of the command and owns it.

**Evaluation:** the check runs at install time against the set of frameworks selected
in the current init run. It does not check what is already installed in the project.
