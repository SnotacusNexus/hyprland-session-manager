#!/usr/bin/env zsh
#
# Slack Session Hook - Pre-Save
# Preserves Slack workspace state, open channels, and window configurations
#
# Session Data Captured:
# - Open Slack workspaces and channels
# - Window positions and workspace assignments
# - Configuration files and preferences
# - Recent conversations and threads
#

set -euo pipefail

# Hook metadata
HOOK_NAME="slack-sessions"
HOOK_VERSION="1.0.0"
HOOK_DESCRIPTION="Preserves Slack workspace state and open channels"

# Session state directory
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
SLACK_SESSION_DIR="$SESSION_STATE_DIR/slack"

# Logging setup
LOG_FILE="${SESSION_DIR}/hooks.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [PRE-SAVE] [$HOOK_NAME]: $1" >> "$LOG_FILE"
}

# Check if required tools are available
check_dependencies() {
    local missing_tools=()
    
    if ! command -v hyprctl >/dev/null 2>&1; then
        missing_tools+=("hyprctl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_tools+=("jq")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log "WARNING: Missing tools: ${missing_tools[*]} - some functionality may be limited"
        return 1
    fi
    
    return 0
}

# Detect Slack variants
detect_slack_variants() {
    local variants=()
    
    # Check for different Slack variants
    if pgrep -x "slack" >/dev/null 2>&1; then
        variants+=("slack")
    fi
    
    if pgrep -f "slack.*--enable-features" >/dev/null 2>&1; then
        variants+=("slack-beta")
    fi
    
    echo "${variants[@]}"
}

# Get Slack window information
get_slack_windows() {
    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        log "WARNING: hyprctl or jq not available, skipping window detection"
        return
    fi
    
    local slack_windows
    slack_windows=$(hyprctl clients -j | jq -r '.[] | select(.class | test("slack", "i")) | {
        address: .address,
        title: .title,
        class: .class,
        workspace: .workspace.name,
        floating: .floating,
        fullscreen: .fullscreen,
        pinned: .pinned,
        focusHistoryID: .focusHistoryID,
        at: [.at[0], .at[1]],
        size: [.size[0], .size[1]]
    }' | jq -s .)
    
    if [[ -n "$slack_windows" && "$slack_windows" != "[]" ]]; then
        echo "$slack_windows" > "$SLACK_SESSION_DIR/windows.json"
        log "Saved Slack window information: $(echo "$slack_windows" | jq length) windows"
    else
        log "No Slack windows detected"
    fi
}

# Extract workspace and channel information from window titles
extract_slack_state() {
    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return
    fi
    
    local slack_state
    slack_state=$(hyprctl clients -j | jq -r '.[] | select(.class | test("slack", "i")) | {
        title: .title,
        workspace: (.title | capture("(?<workspace>[^-|—]+)(?:[-|—]|$)") | .workspace // "unknown"),
        channel: (.title | capture("(?:[-|—]\\s*)(?<channel>.+)$") | .channel // "general")
    }' | jq -s 'group_by(.workspace) | map({
        workspace: .[0].workspace,
        channels: map(.channel) | unique,
        window_count: length
    })')
    
    if [[ -n "$slack_state" && "$slack_state" != "[]" ]]; then
        echo "$slack_state" > "$SLACK_SESSION_DIR/workspaces.json"
        log "Extracted Slack workspace state: $(echo "$slack_state" | jq length) workspaces"
    fi
}

# Backup Slack configuration files
backup_slack_config() {
    local config_dirs=(
        "$HOME/.config/Slack"
        "$HOME/.config/slack"
        "$HOME/.local/share/Slack"
        "$HOME/snap/slack/current/.config/Slack"
    )
    
    local backed_up=0
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            local config_backup_dir="$SLACK_SESSION_DIR/config/$(basename "$config_dir")"
            mkdir -p "$config_backup_dir"
            
            # Copy key configuration files
            local config_files=(
                "Local Storage"
                "Session Storage"
                "IndexedDB"
                "local-settings.json"
                "settings.json"
                "preferences"
            )
            
            for config_file in "${config_files[@]}"; do
                local source_path="$config_dir/$config_file"
                if [[ -e "$source_path" ]]; then
                    cp -r "$source_path" "$config_backup_dir/" 2>/dev/null || true
                    ((backed_up++))
                fi
            done
            
            log "Backed up Slack configuration from: $config_dir"
        fi
    done
    
    if [[ $backed_up -eq 0 ]]; then
        log "No Slack configuration directories found"
    fi
}

# Save Slack process information
save_slack_processes() {
    local slack_processes
    slack_processes=$(ps aux | grep -i "slack" | grep -v grep | awk '{
        printf "{\"user\": \"%s\", \"pid\": %s, \"cpu\": \"%s\", \"mem\": \"%s\", \"command\": \"%s\"}\n", 
        $1, $2, $3, $4, $11
    }' | jq -s .)
    
    if [[ -n "$slack_processes" && "$slack_processes" != "[]" ]]; then
        echo "$slack_processes" > "$SLACK_SESSION_DIR/processes.json"
        log "Saved Slack process information: $(echo "$slack_processes" | jq length) processes"
    fi
}

# Main hook execution
main() {
    log "Starting Slack pre-save hook"
    
    # Create session directory
    mkdir -p "$SLACK_SESSION_DIR"
    mkdir -p "$SLACK_SESSION_DIR/config"
    
    # Check dependencies
    check_dependencies
    
    # Detect running Slack variants
    local variants
    variants=($(detect_slack_variants))
    
    if [[ ${#variants[@]} -eq 0 ]]; then
        log "No running Slack instances detected"
        echo "[]" > "$SLACK_SESSION_DIR/variants.json"
        return 0
    fi
    
    # Save variant information
    printf '%s\n' "${variants[@]}" | jq -R -s 'split("\n") | map(select(. != ""))' > "$SLACK_SESSION_DIR/variants.json"
    log "Detected Slack variants: ${variants[*]}"
    
    # Capture Slack state
    get_slack_windows
    extract_slack_state
    backup_slack_config
    save_slack_processes
    
    # Create session summary
    local summary
    summary=$(jq -n --arg variants "$(echo "${variants[@]}")" \
        --argjson windows "$(cat "$SLACK_SESSION_DIR/windows.json" 2>/dev/null || echo '[]')" \
        --argjson workspaces "$(cat "$SLACK_SESSION_DIR/workspaces.json" 2>/dev/null || echo '[]')" \
        '{
            variants: $variants | split(" "),
            window_count: ($windows | length),
            workspace_count: ($workspaces | length),
            timestamp: (now | strftime("%Y-%m-%d %H:%M:%S")),
            hook_version: "1.0.0"
        }')
    
    echo "$summary" > "$SLACK_SESSION_DIR/summary.json"
    
    log "Slack pre-save hook completed successfully"
    log "Summary: $(echo "$summary" | jq -r '.window_count') windows, $(echo "$summary" | jq -r '.workspace_count') workspaces"
}

# Error handling
trap 'log "ERROR: Hook failed at line $LINENO"; exit 1' ERR

# Execute main function
main "$@"