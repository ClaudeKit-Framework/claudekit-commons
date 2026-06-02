#!/usr/bin/env bash
# Detects the state of the target project directory.

# detect_project_state DIR
# Prints: "clean" | "update" | "merge"
detect_project_state() {
    local dir="${1:-.}"

    # project-state.json is the definitive ClaudeKit marker
    if [[ -f "$dir/project-state.json" ]]; then
        echo "update"
        return 0
    fi

    # CLAUDE.md with a ClaudeKit signature is also a marker
    if [[ -f "$dir/CLAUDE.md" ]] && grep -q "claudekit" "$dir/CLAUDE.md" 2>/dev/null; then
        echo "update"
        return 0
    fi

    # Any non-git files indicate an existing project
    local count
    count=$(find "$dir" -maxdepth 3 -type f \
        ! -path "*/.git/*" \
        ! -name ".gitkeep" \
        2>/dev/null | wc -l)

    if [[ "$count" -gt 0 ]]; then
        echo "merge"
        return 0
    fi

    echo "clean"
}

# get_installed_frameworks DIR
# Prints one framework id per line. Prints nothing if none found.
get_installed_frameworks() {
    local dir="${1:-.}"
    local state_file="$dir/project-state.json"

    if [[ ! -f "$state_file" ]]; then
        return 0
    fi

    if ! command -v jq &>/dev/null; then
        echo "warning: jq not found, cannot read installed frameworks" >&2
        return 0
    fi

    jq -r '.framework_versions | keys[]' "$state_file" 2>/dev/null || true
}
