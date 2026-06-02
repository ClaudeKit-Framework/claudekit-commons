# Compatibility Matrix

Tracks version compatibility across ClaudeKit frameworks.
Populated as framework releases are tagged.

## Framework Version Matrix

Which version of each framework is compatible with which version of commons.
A commons schema change (hard breaking) requires a new row.

| commons | guardrails | design | scope | runner |
|---------|------------|--------|-------|--------|
| —       | —          | —      | —     | —      |

## Update Classification

| Type | Definition | Commons impact |
|------|------------|----------------|
| Non-breaking | New files, improved non-custom files | No commons change required |
| Soft breaking | Changes to user-customisable files | No commons change required |
| Hard breaking | Schema or contract layer changes | New commons version required, migration session required for all dependents |

## Minimum Runtime Requirements

Populated when init tooling is built.

| Framework | Node.js | npm | Notes |
|-----------|---------|-----|-------|
| —         | —       | —   | —     |
