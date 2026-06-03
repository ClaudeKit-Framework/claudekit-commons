#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
MANIFESTS_DIR="$(dirname "$SCRIPT_DIR")/manifests"
PROJECT_DIR="${1:-.}"

source "$LIB_DIR/detect.sh"
source "$LIB_DIR/copy.sh"
source "$LIB_DIR/output.sh"
source "$LIB_DIR/audit.sh"

divider() { echo "────────────────────────────────────────"; }

require_dependency() {
    local cmd="$1" install_hint="$2"
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: $cmd is required but not installed."
        echo "Install with: $install_hint"
        exit 1
    fi
}

# ── Step 1: Project detection ─────────────────────────────────────────────

echo ""
echo "ClaudeKit Init"
divider
echo ""

require_dependency jq "sudo apt install jq"
require_dependency git "sudo apt install git"

PROJECT_STATE=$(detect_project_state "$PROJECT_DIR")

case "$PROJECT_STATE" in
    update)
        echo "Existing ClaudeKit installation detected."
        echo "To update an existing installation, use update.sh instead."
        echo ""
        printf "Continue with init anyway? (y/n): "
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Exiting. Run update.sh to update your installation."
            exit 0
        fi
        echo ""
        ;;
    merge)
        echo "Existing project detected."
        echo "Files will be added alongside your existing code."
        echo "You will be shown any conflicts before anything is written."
        echo ""
        ;;
    clean)
        echo "No existing files detected. Clean installation."
        echo ""
        ;;
esac

# ── Step 3: Framework selection ───────────────────────────────────────────
# (Step 2 — security audit — runs after selection, before copy)

echo "Select frameworks to install:"
echo ""
echo "  [1] Guardrails (Solo)"
echo "      Security, compliance and privacy controls for solo development."
echo ""
echo "  [2] Guardrails (Team)"
echo "      Security, compliance and privacy controls for team development."
echo ""
echo "  [3] Session Runner"
echo "      Runtime engine for executing sessions safely."
echo ""
printf "Enter numbers separated by spaces (e.g. 1 3): "
read -r raw_selection

SELECTED_FRAMEWORKS=()
GUARDRAILS_SELECTED=false

for num in $raw_selection; do
    case "$num" in
        1)
            if [[ " ${SELECTED_FRAMEWORKS[*]} " == *" guardrails-team "* ]]; then
                echo "Error: Guardrails Solo and Team cannot be installed together."
                exit 1
            fi
            SELECTED_FRAMEWORKS+=("guardrails-solo")
            GUARDRAILS_SELECTED=true
            ;;
        2)
            if [[ " ${SELECTED_FRAMEWORKS[*]} " == *" guardrails-solo "* ]]; then
                echo "Error: Guardrails Solo and Team cannot be installed together."
                exit 1
            fi
            SELECTED_FRAMEWORKS+=("guardrails-team")
            GUARDRAILS_SELECTED=true
            ;;
        3)
            SELECTED_FRAMEWORKS+=("runner")
            ;;
        *)
            echo "Unknown selection: $num — skipping."
            ;;
    esac
done

if [[ "${#SELECTED_FRAMEWORKS[@]}" -eq 0 ]]; then
    echo "No frameworks selected. Exiting."
    exit 0
fi

echo ""
echo "Selected: ${SELECTED_FRAMEWORKS[*]}"
echo ""

# ── Step 2: Security audit ────────────────────────────────────────────────
# Runs after framework selection. Only for Guardrails on existing projects.

if [[ "$GUARDRAILS_SELECTED" == true && "$PROJECT_STATE" != "clean" ]]; then
    run_security_audit "$PROJECT_DIR"
fi

# ── Step 4: Stack declaration ─────────────────────────────────────────────

_ask_stack() {
    echo "Declare your tech stack:"
    echo ""
    echo "  [1] Node.js / TypeScript"
    echo "  [2] Python"
    echo "  [3] Go"
    echo "  [4] Ruby"
    echo "  [5] Other (configure manually after init)"
    echo "  [6] Not decided yet"
    echo "  [7] I'm not sure what this means"
    echo ""
    printf "Choice: "
    read -r choice

    case "$choice" in
        1) STACK="node" ;;
        2) STACK="python" ;;
        3) STACK="go" ;;
        4) STACK="ruby" ;;
        5) STACK="other" ;;
        6) STACK="undecided" ;;
        7)
            echo ""
            echo "  Your tech stack is the combination of languages, frameworks and tools"
            echo "  your project uses — for example, Node.js, or Python with Django."
            echo ""
            echo "  ClaudeKit uses this to check your dependencies are compatible"
            echo "  before each session. Choose 'Not decided yet' if you're unsure —"
            echo "  this will never block you from continuing."
            echo ""
            _ask_stack
            return
            ;;
        *) STACK="undecided" ;;
    esac
}

STACK=""
_ask_stack
echo ""

# ── Step 5: Communication preferences ────────────────────────────────────

echo "Communication preferences:"
echo ""
echo "How familiar are you with software development?"
echo "  [1] New to this entirely"
echo "  [2] Some experience"
echo "  [3] Experienced developer"
printf "  Choice: "
read -r choice
case "$choice" in
    1) EXPERIENCE_LEVEL="new" ;;
    2) EXPERIENCE_LEVEL="some" ;;
    3) EXPERIENCE_LEVEL="experienced" ;;
    *) EXPERIENCE_LEVEL="some" ;;
esac

echo ""
echo "How do you prefer explanations?"
echo "  [1] Plain language — avoid jargon, explain the why"
echo "  [2] Balanced — clear but don't over-explain"
echo "  [3] Technical — precise language, skip the basics"
printf "  Choice: "
read -r choice
case "$choice" in
    1) EXPLANATION_DEPTH="plain" ;;
    2) EXPLANATION_DEPTH="balanced" ;;
    3) EXPLANATION_DEPTH="technical" ;;
    *) EXPLANATION_DEPTH="balanced" ;;
esac

echo ""
echo "For instructions, do you want:"
echo "  [1] Step by step — every action spelled out explicitly"
echo "  [2] Outcomes only — tell me what to achieve, I'll figure out how"
printf "  Choice: "
read -r choice
case "$choice" in
    1) INSTRUCTION_DETAIL="step_by_step" ;;
    2) INSTRUCTION_DETAIL="outcomes_only" ;;
    *) INSTRUCTION_DETAIL="step_by_step" ;;
esac

echo ""

# ── Step 6: Confirmation ──────────────────────────────────────────────────

divider
echo "Ready to install. Files to be written:"
echo ""

for fw in "${SELECTED_FRAMEWORKS[@]}"; do
    manifest="$MANIFESTS_DIR/${fw}.json"
    echo "  $fw:"
    file_count=$(jq '.files | length' "$manifest")
    for ((i=0; i<file_count; i++)); do
        dest=$(jq -r ".files[$i].destination" "$manifest")
        skip=false
        while IFS= read -r skip_fw; do
            [[ -z "$skip_fw" ]] && continue
            if [[ " ${SELECTED_FRAMEWORKS[*]} " == *" $skip_fw "* ]]; then
                skip=true; break
            fi
        done < <(jq -r ".files[$i].skip_if_framework_present // [] | .[]" "$manifest")
        [[ "$skip" == true ]] && continue
        echo "    $PROJECT_DIR/$dest"
    done
done

echo ""
printf "Proceed? (y/n): "
read -r confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# ── Step 7: Fetch and copy ────────────────────────────────────────────────

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

for fw in "${SELECTED_FRAMEWORKS[@]}"; do
    manifest="$MANIFESTS_DIR/${fw}.json"
    source_repo=$(jq -r '.source_repo' "$manifest")
    source_ref=$(jq -r '.source_ref' "$manifest")
    repo_dir="$tmp_dir/$fw"

    echo "Fetching $fw..."
    git clone --depth=1 --branch "$source_ref" \
        "https://$source_repo" "$repo_dir" \
        --quiet 2>&1 || {
        echo "Error: failed to fetch $source_repo"
        exit 1
    }

    echo "Installing $fw..."
    file_count=$(jq '.files | length' "$manifest")

    for ((i=0; i<file_count; i++)); do
        src=$(jq -r ".files[$i].source" "$manifest")
        dest=$(jq -r ".files[$i].destination" "$manifest")
        strategy=$(jq -r ".files[$i].conflict_strategy" "$manifest")

        skip=false
        while IFS= read -r skip_fw; do
            [[ -z "$skip_fw" ]] && continue
            if [[ " ${SELECTED_FRAMEWORKS[*]} " == *" $skip_fw "* ]]; then
                skip=true; break
            fi
        done < <(jq -r ".files[$i].skip_if_framework_present // [] | .[]" "$manifest")

        if [[ "$skip" == true ]]; then
            echo "  skipped  $dest (provided by another selected framework)"
            continue
        fi

        copy_file "$repo_dir/$src" "$PROJECT_DIR/$dest" "$strategy"
    done
done

write_merge_report "$PROJECT_DIR"

# ── Step 8: Post-init ─────────────────────────────────────────────────────

generate_commands_md "$MANIFESTS_DIR" "${SELECTED_FRAMEWORKS[@]}" \
    > "$PROJECT_DIR/COMMANDS.md"
echo "  created  COMMANDS.md"

echo ""
divider
echo "ClaudeKit installed."
echo ""
echo "Frameworks: ${SELECTED_FRAMEWORKS[*]}"
echo ""

has_actions=false
for fw in "${SELECTED_FRAMEWORKS[@]}"; do
    count=$(jq '.post_install_actions | length' "$MANIFESTS_DIR/${fw}.json")
    if [[ "$count" -gt 0 ]]; then
        has_actions=true
        break
    fi
done

if [[ "$has_actions" == true ]]; then
    echo "Required manual actions:"
    print_manual_actions "$MANIFESTS_DIR" "${SELECTED_FRAMEWORKS[@]}"
fi

echo ""
echo "Full command reference: see COMMANDS.md"
echo ""
