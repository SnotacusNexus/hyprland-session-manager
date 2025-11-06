#!/usr/bin/env zsh
#
# Slack Session Hook - Post-Restore
# Restores Slack workspace state, open channels, and window configurations
#
# Session Data Restored:
# - Slack application instances
# - Workspace and channel navigation
# - Window positions and workspace assignments
# - Configuration files and preferences
#

set -euo pipefail

# Hook metadata
HOOK_NAME="slack-sessions"
HOOK_VERSION="1.0.0"
HOOK_DESCRIPTION="Restores Slack workspace state and open channels"

# Session state directory
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
SLACK_SESSION_DIR="$SESSION_STATE_DIR/slack"

# Logging setup
LOG_FILE="${SESSION_DIR}/hooks.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [POST-RESTORE] [$HOOK_NAME]: $1" >> "$LOG_FILE"
}

# Check if session data exists
check_session_data() {
    if [[ ! -d "$SLACK_SESSION_DIR" ]]; then
        log "No Slack session data found"
        return 1
    fi
    
    if [[ ! -f "$SLACK_SESSION_DIR/summary.json" ]]; then
        log "No Slack session summary found"
        return 1
    fi
    
    return 0
}

# Wait for Slack to be available
wait_for_slack() {
    local max_attempts=30
    local attempt=0
    
    log "Waiting for Slack to become available..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if pgrep -x "slack" >/dev/null 2>&1; then
            log "Slack process detected"
            return 0
        fi
        
        ((attempt++))
        sleep 1
    done
    
    log "WARNING: Slack not detected after $max_attempts seconds"
    return 1
}

# Launch Slack instances
launch_slack_instances() {
    local variants_file="$SLACK_SESSION_DIR/variants.json"
    
    if [[ ! -f "$variants_file" ]]; then
        log "No Slack variant information found, launching default Slack"
        slack >/dev/null 2>&1 &
        return 0
    fi
    
    local variants
    variants=$(jq -r '.[]' "$variants_file" 2>/dev/null || echo "slack")
    
    for variant in $variants; do
        case "$variant" in
            "slack")
                log "Launching Slack"
                slack >/dev/null 2>&1 &
                ;;
            "slack-beta")
                log "Launching Slack Beta"
                slack --enable-features=SlackBeta >/dev/null 2>&1 &
                ;;
            *)
                log "Launching default Slack"
                slack >/dev/null 2>&1 &
                ;;
        esac
    done
}

# Restore Slack configuration
restore_slack_config() {
    local config_backup_dir="$SLACK_SESSION_DIR/config"
    
    if [[ ! -d "$config_backup_dir" ]]; then
        log "No Slack configuration backup found"
        return 0
    fi
    
    local config_dirs=(
        "$HOME/.config/Slack"
        "$HOME/.config/slack"
        "$HOME/.local/share/Slack"
        "$HOME/snap/slack/current/.config/Slack"
    )
    
    local restored=0
    
    for config_dir in "${config_dirs[@]}"; do
        if [[ -d "$config_dir" ]]; then
            local backup_subdir="$config_backup_dir/$(basename "$config_dir")"
            
            if [[ -d "$backup_subdir" ]]; then
                # Restore key configuration files
                local config_files=(
                    "Local Storage"
                    "Session Storage"
                    "IndexedDB"
                    "local-settings.json"
                    "settings.json"
                    "preferences"
                )
                
                for config_file in "${config_files[@]}"; do
                    local backup_path="$backup_subdir/$config_file"
                    local target_path="$config_dir/$config_file"
                    
                    if [[ -e "$backup_path" ]]; then
                        # Create backup of existing files
                        if [[ -e "$target_path" ]]; then
                            mv "$target_path" "$target_path.bak" 2>/dev/null || true
                        fi
                        
                        cp -r "$backup_path" "$target_path" 2>/dev/null || true
                        ((restored++))
                    fi
                done
                
                log "Restored Slack configuration to: $config_dir"
            fi
        fi
    done
    
    if [[ $restored -eq 0 ]]; then
        log "No Slack configuration files restored"
    else
        log "Restored $restored Slack configuration files"
    fi
}

# Verify Slack restoration
verify_slack_restoration() {
    local max_attempts=60
    local attempt=0
    local expected_workspaces=0
    
    # Get expected workspace count from session data
    if [[ -f "$SLACK_SESSION_DIR/summary.json" ]]; then
        expected_workspaces=$(jq -r '.workspace_count // 0' "$SLACK_SESSION_DIR/summary.json")
    fi
    
    log "Waiting for Slack to restore workspaces (expected: $expected_workspaces)..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        local current_windows
        current_windows=$(hyprctl clients -j 2>/dev/null | jq '.[] | select(.class | test("slack", "i"))' 2>/dev/null | jq -s length 2>/dev/null || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log "Slack restoration verified: $current_windows windows detected"
            return 0
        fi
        
        ((attempt++))
        sleep 2
    done
    
    log "WARNING: Slack restoration verification timeout after $max_attempts attempts"
    return 1
}

# Apply window management (if hyprctl available)
apply_window_management() {
    if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        log "WARNING: hyprctl or jq not available, skipping window management"
        return
    fi
    
    local windows_file="$SLACK_SESSION_DIR/windows.json"
    
    if [[ ! -f "$windows_file" ]]; then
        log "No window configuration found"
        return
    fi
    
    local windows
    windows=$(jq -c '.[]' "$windows_file" 2>/dev/null)
    
    if [[ -z "$windows" ]]; then
        log "No window data to restore"
        return
    fi
    
    local managed_windows=0
    
    while IFS= read -r window; do
        local address title class workspace floating fullscreen pinned focus_history_id at size
        
        address=$(echo "$window" | jq -r '.address // empty')
        title=$(echo "$window" | jq -r '.title // empty')
        class=$(echo "$window" | jq -r '.class // empty')
        workspace=$(echo "$window" | jq -r '.workspace // empty')
        floating=$(echo "$window" | jq -r '.floating // false')
        fullscreen=$(echo "$window" | jq -r '.fullscreen // false')
        pinned=$(echo "$window" | jq -r '.pinned // false')
        focus_history_id=$(echo "$window" | jq -r '.focusHistoryID // empty')
        at=$(echo "$window" | jq -r '.at | join(",") // empty')
        size=$(echo "$window" | jq -r '.size | join(",") // empty')
        
        # Find current Slack window with similar title
        local current_window
        current_window=$(hyprctl clients -j | jq -r ".[] | select(.class | test(\"$class\", \"i\")) | .address" | head -1)
        
        if [[ -n "$current_window" ]]; then
            # Move to target workspace
            if [[ -n "$workspace" && "$workspace" != "null" ]]; then
                hyprctl dispatch movetoworkspace "$workspace,address:$current_window" >/dev/null 2>&1 || true
            fi
            
            # Apply floating state
            if [[ "$floating" == "true" ]]; then
                hyprctl dispatch togglefloating "address:$current_window" >/dev/null 2>&1 || true
            fi
            
            # Apply fullscreen state
            if [[ "$fullscreen" == "true" ]]; then
                hyprctl dispatch fullscreen "1,address:$current_window" >/dev/null 2>&1 || true
            fi
            
            # Apply pinned state
            if [[ "$pinned" == "true" ]]; then
                hyprctl dispatch pin "address:$current_window" >/dev/null 2>&1 || true
            fi
            
            ((managed_windows++))
        fi
        
    done <<< "$windows"
    
    if [[ $managed_windows -gt 0 ]]; then
        log "Applied window management to $managed_windows Slack windows"
    else
        log "No Slack windows managed"
    fi
}

# Clean up session data
cleanup_session_data() {
    if [[ -d "$SLACK_SESSION_DIR" ]]; then
        # Keep summary for reference, remove detailed data
        rm -rf "$SLACK_SESSION_DIR/config" 2>/dev/null || true
        rm -f "$SLACK_SESSION_DIR/windows.json" 2>/dev/null || true
        rm -f "$SLACK_SESSION_DIR/processes.json" 2>/dev/null || true
        log "Cleaned up Slack session data"
    fi
}

# Main hook execution
main() {
    log "Starting Slack post-restore hook"
    
    # Check if session data exists
    if ! check_session_data; then
        log "No Slack session data to restore"
        return 0
    fi
    
    # Read session summary
    local summary
    summary=$(cat "$SLACK_SESSION_DIR/summary.json")
    local window_count workspace_count
    
    window_count=$(echo "$summary" | jq -r '.window_count // 0')
    workspace_count=$(echo "$summary" | jq -r '.workspace_count // 0')
    
    log "Restoring Slack session: $window_count windows, $workspace_count workspaces"
    
    # Launch Slack instances
    launch_slack_instances
    
    # Wait for Slack to start
    if wait_for_slack; then
        # Restore configuration
        restore_slack_config
        
        # Apply window management
        sleep 3  # Give Slack time to initialize
        apply_window_management
        
        # Verify restoration
        verify_slack_restoration
    else
        log "WARNING: Slack may not have started properly"
    fi
    
    # Clean up session data
    cleanup_session_data
    
    log "Slack post-restore hook completed"
}

# Error handling
trap 'log "ERROR: Hook failed at line $LINENO"; exit 1' ERR

# Execute main function
main "$@"