#!/usr/bin/env bash
# Handles file copying with conflict detection.
# Populates COPY_LOG and MERGE_REPORT arrays used by write_merge_report.

COPY_LOG=()
MERGE_REPORT=()

# copy_file SOURCE DESTINATION STRATEGY
# STRATEGY: create_only | always_overwrite | append | merge
copy_file() {
    local source="$1"
    local destination="$2"
    local strategy="$3"

    if [[ ! -f "$source" ]]; then
        echo "  error    $destination (source not found: $source)" >&2
        return 1
    fi

    if [[ ! -f "$destination" ]]; then
        mkdir -p "$(dirname "$destination")"
        cp "$source" "$destination"
        COPY_LOG+=("created  $destination")
        echo "  created  $destination"
        return 0
    fi

    case "$strategy" in
        create_only)
            COPY_LOG+=("skipped  $destination")
            echo "  skipped  $destination"
            ;;
        always_overwrite)
            cp "$source" "$destination"
            COPY_LOG+=("updated  $destination")
            echo "  updated  $destination"
            ;;
        append)
            cat "$source" >> "$destination"
            COPY_LOG+=("appended $destination")
            echo "  appended $destination"
            ;;
        merge)
            _resolve_merge_conflict "$source" "$destination"
            ;;
        *)
            echo "  error    unknown strategy '$strategy' for $destination" >&2
            return 1
            ;;
    esac
}

_resolve_merge_conflict() {
    local source="$1"
    local destination="$2"
    local choice

    echo ""
    echo "  Conflict: $destination already exists."
    echo "  [k] Keep yours   [f] Use framework version   [d] Show diff"
    printf "  Choice: "
    read -r choice

    case "$choice" in
        f|F)
            cp "$source" "$destination"
            COPY_LOG+=("replaced $destination")
            MERGE_REPORT+=("replaced: $destination")
            echo "  replaced $destination"
            ;;
        d|D)
            echo ""
            diff --unified "$destination" "$source" || true
            echo ""
            echo "  [k] Keep yours   [f] Use framework version"
            printf "  Choice: "
            read -r choice
            if [[ "$choice" == "f" || "$choice" == "F" ]]; then
                cp "$source" "$destination"
                COPY_LOG+=("replaced $destination")
                MERGE_REPORT+=("replaced: $destination")
                echo "  replaced $destination"
            else
                COPY_LOG+=("kept     $destination")
                MERGE_REPORT+=("kept:     $destination")
                echo "  kept     $destination"
            fi
            ;;
        *)
            COPY_LOG+=("kept     $destination")
            MERGE_REPORT+=("kept:     $destination")
            echo "  kept     $destination"
            ;;
    esac
}

# write_merge_report DIR
# Writes merge-report.md if any conflicts were resolved.
write_merge_report() {
    local dir="${1:-.}"

    if [[ "${#MERGE_REPORT[@]}" -eq 0 ]]; then
        return 0
    fi

    local report_file="$dir/merge-report.md"
    {
        echo "# Merge Report"
        echo ""
        echo "Files with conflicts resolved during ClaudeKit init:"
        echo ""
        for entry in "${MERGE_REPORT[@]}"; do
            echo "- $entry"
        done
    } > "$report_file"

    echo ""
    echo "  Merge report written to merge-report.md"
}
