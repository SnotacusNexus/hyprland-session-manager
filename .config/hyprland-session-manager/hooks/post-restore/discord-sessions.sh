#!/usr/bin/env zsh

# Discord Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Discord chat session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Discord is running
is_discord_running() {
    if pgrep -x "discord" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Discord window class
get_discord_class() {
    # Discord can have different window classes depending on the distribution
    local discord_classes=("discord" "Discord" "discord-ptb" "discord-canary")
    
    for class in "${discord_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "discord"
}

# Launch Discord with session restoration
launch_discord_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    
    log_info "Launching Discord with session restoration..."
    
    # Check which Discord variant is available
    local discord_cmd=""
    if command -v discord > /dev/null; then
        discord_cmd="discord"
    elif command -v discord-ptb > /dev/null; then
        discord_cmd="discord-ptb"
    elif command -v discord-canary > /dev/null; then
        discord_cmd="discord-canary"
    else
        log_error "No Discord executable found in PATH"
        return 1
    fi
    
    # Discord automatically restores sessions by default
    # Launch in background and continue
    $discord_cmd &
    
    local discord_pid=$!
    log_info "Discord launched with PID: $discord_pid"
    
    # Wait a moment for Discord to start
    sleep 3
    
    # Verify Discord started successfully
    if kill -0 $discord_pid 2>/dev/null; then
        log_success "Discord launched successfully"
        return 0
    else
        log_error "Discord failed to start"
        return 1
    fi
}

# Restore Discord configuration if needed
restore_discord_config() {
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    local discord_config="${HOME}/.config/discord"
    
    if [[ ! -f "${app_state_dir}/settings.json" ]]; then
        log_info "No Discord settings to restore"
        return
    fi
    
    log_info "Checking Discord configuration restoration..."
    
    # Only restore settings if they don't exist or if we have a backup
    if [[ -d "$discord_config" ]]; then
        # Check if current settings exist
        if [[ ! -f "${discord_config}/settings.json" ]]; then
            log_info "Restoring Discord settings..."
            cp "${app_state_dir}/settings.json" "${discord_config}/settings.json" 2>/dev/null || \
            log_warning "Could not restore Discord settings"
        else
            log_info "Discord settings already exist - preserving current configuration"
        fi
    else
        log_warning "Discord configuration directory not found - settings not restored"
    fi
}

# Restore Discord session data
restore_discord_session() {
    local app_class="$(get_discord_class)"
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Discord session data to restore"
        return
    fi
    
    log_info "Restoring Discord session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore configuration if needed
    restore_discord_config
    
    # Launch Discord if not running
    if ! is_discord_running; then
        launch_discord_with_session
    else
        log_info "Discord already running - session should auto-restore"
    fi
    
    # Note: Discord automatically handles session restoration from its internal state
    # The window positions and layouts are handled by Hyprland
    
    log_success "Discord session restoration initiated"
}

# Verify Discord session restoration
verify_discord_restoration() {
    local app_class="$(get_discord_class)"
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    
    log_info "Verifying Discord session restoration..."
    
    # Wait a bit for Discord to fully load
    sleep 5
    
    # Check if Discord windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Discord windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Discord restoration verified - $current_windows windows detected"
            
            # Check if we can detect channel information
            local current_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null | head -1)
            if [[ -n "$current_titles" ]]; then
                log_info "Current Discord window: $current_titles"
            fi
            
            return 0
        else
            log_warning "No Discord windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        return 0
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Discord post-restore hook..."
    
    restore_discord_session
    
    # Give Discord time to restore, then verify
    sleep 8
    verify_discord_restoration
    
    log_success "Discord post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Discord pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac