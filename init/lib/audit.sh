#!/usr/bin/env bash
# Security audit stub.
# Full implementation requires a dedicated design session.

# run_security_audit DIR
# Scans existing project files, directories, and git history for security issues.
# Critical findings gate the merge. Full scope to be defined in a future session.
run_security_audit() {
    local dir="${1:-.}"

    echo ""
    echo "────────────────────────────────────────"
    echo "⚠ SECURITY AUDIT — NOT YET IMPLEMENTED"
    echo "────────────────────────────────────────"
    echo ""
    echo "  The automated security audit has not been built yet."
    echo "  Manual review is required before proceeding."
    echo ""
    echo "  Review the following before continuing:"
    echo "    - Check for credentials or secrets in existing files"
    echo "    - Confirm .gitignore covers sensitive file patterns"
    echo "    - Review git history for accidentally committed secrets"
    echo ""
    echo "  For more information, see the open flags in SESSION-CONTEXT.md"
    echo "  (security audit scope is tracked there as a future design session)."
    echo ""
}
