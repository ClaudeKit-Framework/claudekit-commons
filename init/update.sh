#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
MANIFESTS_DIR="$(dirname "$SCRIPT_DIR")/manifests"
PROJECT_DIR="${1:-.}"

source "$LIB_DIR/detect.sh"
source "$LIB_DIR/copy.sh"
source "$LIB_DIR/output.sh"

divider() { echo "────────────────────────────────────────"; }

require_dependency() {
    local cmd="$1" install_hint="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required but not installed."
        echo "Install with: $install_hint"
        exit 1
    fi
}

# ── Version utilities ─────────────────────────────────────────────────────

# version_gt A B
# Returns 0 (true) if A is greater than B, 1 otherwise.
version_gt() {
    local a="$1" b="$2"
    if [[ "$a" == "$b" ]]; then return 1; fi

    local IFS='.'
    local -a va=($a) vb=($b)

    for i in 0 1 2; do
        local na="${va[$i]:-0}" nb="${vb[$i]:-0}"
        if [[ "$na" -gt "$nb" ]]; then return 0; fi
        if [[ "$na" -lt "$nb" ]]; then return 1; fi
    done

    return 1
}

# classify_update INSTALLED NEW
# Prints: "none" | "non_breaking" | "soft_breaking" | "hard_breaking"
classify_update() {
    local installed="$1" new="$2"

    if ! version_gt "$new" "$installed"; then
        echo "none"
        return 0
    fi

    local IFS='.'
    local -a vi=($installed) vn=($new)
    local major_i="${vi[0]:-0}" major_n="${vn[0]:-0}"
    local minor_i="${vi[1]:-0}" minor_n="${vn[1]:-0}"

    if [[ "$major_n" -gt "$major_i" ]]; then
        echo "hard_breaking"
    elif [[ "$minor_n" -gt "$minor_i" ]]; then
        echo "soft_breaking"
    else
        echo "non_breaking"
    fi
}

# ── Update flows ──────────────────────────────────────────────────────────

apply_non_breaking() {
    local fw="$1" repo_dir="$2"
    local manifest="$MANIFESTS_DIR/${fw}.json"

    echo ""
    echo "ℹ Non-breaking update for $fw — applying automatically."
    echo ""

    local file_count
    file_count=$(jq '.files | length' "$manifest")

    for ((i=0; i<file_count; i++)); do
        local src dest strategy
        src=$(jq -r ".files[$i].source" "$manifest")
        dest=$(jq -r ".files[$i].destination" "$manifest")
        strategy=$(jq -r ".files[$i].conflict_strategy" "$manifest")

        # Non-breaking updates only touch non-customisable files
        if [[ "$strategy" == "always_overwrite" || "$strategy" == "create_only" ]]; then
            copy_file "$repo_dir/$src" "$PROJECT_DIR/$dest" "$strategy"
        fi
    done
}

apply_soft_breaking() {
    local fw="$1" repo_dir="$2" installed="$3" new="$4"
    local manifest="$MANIFESTS_DIR/${fw}.json"

    echo ""
    echo "⚠ Soft breaking update for $fw ($installed → $new)."
    echo "  Changes affect files you may have customised."
    echo "  You will be shown each conflict and asked what to keep."
    echo ""
    printf "  Proceed with merge review? (y/n): "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "  Skipped. $fw remains at $installed."
        return 0
    fi

    local file_count
    file_count=$(jq '.files | length' "$manifest")

    for ((i=0; i<file_count; i++)); do
        local src dest strategy
        src=$(jq -r ".files[$i].source" "$manifest")
        dest=$(jq -r ".files[$i].destination" "$manifest")
        strategy=$(jq -r ".files[$i].conflict_strategy" "$manifest")
        copy_file "$repo_dir/$src" "$PROJECT_DIR/$dest" "$strategy"
    done

    write_merge_report "$PROJECT_DIR"
}

notify_hard_breaking() {
    local fw="$1" installed="$2" new="$3"

    echo ""
    echo "✗ Hard breaking update for $fw ($installed → $new)."
    echo "  This update changes the schema or contract layer and requires"
    echo "  a migration session before it can be applied."
    echo ""
    echo "  Continuing on $installed is recommended until you are ready."
    echo ""
    echo "  To apply when ready:"
    echo "  1. Run /check-updates in Claude Code"
    echo "  2. Follow the migration session instructions"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────

require_dependency jq "sudo apt install jq"
require_dependency git "sudo apt install git"

PROJECT_STATE=$(detect_project_state "$PROJECT_DIR")

if [[ "$PROJECT_STATE" == "clean" ]]; then
    echo "No ClaudeKit installation found in $PROJECT_DIR."
    echo "Run init.sh to install ClaudeKit."
    exit 1
fi

STATE_FILE="$PROJECT_DIR/project-state.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "Error: project-state.json not found."
    echo "Cannot determine installed versions. Aborting."
    exit 1
fi

echo ""
echo "ClaudeKit Update"
divider
echo ""

INSTALLED_FRAMEWORKS=$(get_installed_frameworks "$PROJECT_DIR")

if [[ -z "$INSTALLED_FRAMEWORKS" ]]; then
    echo "No installed frameworks found in project-state.json."
    exit 0
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

updates_applied=0
updates_skipped=0

while IFS= read -r fw; do
    manifest="$MANIFESTS_DIR/${fw}.json"

    if [[ ! -f "$manifest" ]]; then
        echo "  warning: no manifest found for $fw — skipping"
        continue
    fi

    installed_version=$(jq -r ".framework_versions.\"$fw\".version // \"0.0.0\"" "$STATE_FILE")
    available_version=$(jq -r '.version' "$manifest")
    update_type=$(classify_update "$installed_version" "$available_version")

    case "$update_type" in
        none)
            echo "  ✓ $fw $installed_version — up to date"
            ;;
        non_breaking|soft_breaking|hard_breaking)
            source_repo=$(jq -r '.source_repo' "$manifest")
            source_ref=$(jq -r '.source_ref' "$manifest")
            repo_dir="$tmp_dir/$fw"

            echo "  Fetching $fw $available_version..."
            git clone --depth=1 --branch "$source_ref" \
                "https://$source_repo" "$repo_dir" \
                --quiet 2>&1 || {
                echo "  Error: failed to fetch $source_repo — skipping $fw"
                updates_skipped=$((updates_skipped + 1))
                continue
            }

            case "$update_type" in
                non_breaking)
                    apply_non_breaking "$fw" "$repo_dir"
                    updates_applied=$((updates_applied + 1))
                    ;;
                soft_breaking)
                    apply_soft_breaking "$fw" "$repo_dir" "$installed_version" "$available_version"
                    updates_applied=$((updates_applied + 1))
                    ;;
                hard_breaking)
                    notify_hard_breaking "$fw" "$installed_version" "$available_version"
                    updates_skipped=$((updates_skipped + 1))
                    ;;
            esac
            ;;
    esac

done <<< "$INSTALLED_FRAMEWORKS"

echo ""
divider

if [[ "$updates_applied" -gt 0 ]]; then
    # Regenerate COMMANDS.md from current installed frameworks
    mapfile -t fw_list <<< "$INSTALLED_FRAMEWORKS"
    generate_commands_md "$MANIFESTS_DIR" "${fw_list[@]}" > "$PROJECT_DIR/COMMANDS.md"
    echo "COMMANDS.md regenerated."
    echo ""
fi

if [[ "$updates_applied" -eq 0 && "$updates_skipped" -eq 0 ]]; then
    echo "All frameworks up to date."
elif [[ "$updates_applied" -gt 0 ]]; then
    echo "Update complete. $updates_applied framework(s) updated."
fi

if [[ "$updates_skipped" -gt 0 ]]; then
    echo "$updates_skipped framework(s) skipped — see above for details."
fi

echo ""
