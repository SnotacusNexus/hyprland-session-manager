#!/usr/bin/env zsh

# Firefox Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Firefox browser session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Firefox is running
is_firefox_running() {
    if pgrep -x "firefox" > /dev/null || pgrep -f "firefox-bin" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Firefox window class
get_firefox_class() {
    # Firefox can have different window classes depending on the distribution
    local firefox_classes=("firefox" "Firefox" "firefox-esr" "Firefox-esr")
    
    for class in "${firefox_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "firefox"
}

# Launch Firefox with session restoration
launch_firefox_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/firefox"
    
    log_info "Launching Firefox with session restoration..."
    
    # Check if Firefox executable is available
    local firefox_cmd=""
    if command -v firefox > /dev/null; then
        firefox_cmd="firefox"
    elif command -v firefox-esr > /dev/null; then
        firefox_cmd="firefox-esr"
    else
        log_error "No Firefox executable found in PATH"
        return 1
    fi
    
    # Firefox automatically restores sessions by default when launched normally
    # We don't need special flags as Firefox handles session restoration internally
    # Launch in background and continue
    $firefox_cmd &
    
    local firefox_pid=$!
    log_info "Firefox launched with PID: $firefox_pid"
    
    # Wait a moment for Firefox to start
    sleep 3
    
    # Verify Firefox started successfully
    if kill -0 $firefox_pid 2>/dev/null; then
        log_success "Firefox launched successfully"
        return 0
    else
        log_error "Firefox failed to start"
        return 1
    fi
}

# Restore Firefox session data
restore_firefox_session() {
    local app_class="$(get_firefox_class)"
    local app_state_dir="${SESSION_STATE_DIR}/firefox"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Firefox session data to restore"
        return
    fi
    
    log_info "Restoring Firefox session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Launch Firefox if not running
    if ! is_firefox_running; then
        launch_firefox_with_session
    else
        log_info "Firefox already running - session should auto-restore"
        
        # If Firefox is already running, we can try to trigger session restoration
        # by sending a signal or using Firefox's internal mechanisms
        # Note: Firefox typically auto-restores sessions on startup
        log_info "Firefox session restoration relies on Firefox's built-in session management"
    fi
    
    # Note: Firefox automatically handles session restoration from its internal state
    # The window positions and layouts are handled by Hyprland
    # Firefox stores session data in ~/.mozilla/firefox/[profile]/sessionstore-backups/
    
    log_success "Firefox session restoration initiated"
}

# Verify Firefox session restoration
verify_firefox_restoration() {
    local app_class="$(get_firefox_class)"
    local app_state_dir="${SESSION_STATE_DIR}/firefox"
    
    log_info "Verifying Firefox session restoration..."
    
    # Wait a bit for Firefox to fully load and restore session
    sleep 5
    
    # Check if Firefox windows are present
    local current_windows=0
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    fi
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Firefox windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Firefox restoration verified - $current_windows windows detected"
            
            # Compare with saved window count if available
            if [[ $saved_windows -gt 0 ]] && [[ $current_windows -lt $saved_windows ]]; then
                log_warning "Fewer windows restored ($current_windows) than saved ($saved_windows)"
            elif [[ $current_windows -eq $saved_windows ]]; then
                log_success "Perfect match: $current_windows windows restored"
            fi
            
            return 0
        else
            log_warning "No Firefox windows detected after restoration attempt"
            return 1
        fi
    else
        if [[ $current_windows -gt 0 ]]; then
            log_success "Firefox windows detected - restoration appears successful"
            return 0
        else
            log_warning "No Firefox windows detected and no saved session summary for comparison"
            return 0  # Don't fail if we can't verify
        fi
    fi
}

# Check Firefox session state
check_firefox_session_state() {
    local firefox_config="${HOME}/.mozilla/firefox"
    
    if [[ ! -d "$firefox_config" ]]; then
        log_warning "Firefox configuration directory not found"
        return 1
    fi
    
    log_info "Checking Firefox session state..."
    
    # Look for active session files
    local session_files=$(find "$firefox_config" -name "recovery.jsonlz4" -o -name "sessionstore.jsonlz4" 2>/dev/null | head -5)
    
    if [[ -n "$session_files" ]]; then
        log_success "Firefox session files found - session restoration should work"
        return 0
    else
        log_warning "No Firefox session files found - session may not restore properly"
        return 1
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Firefox post-restore hook..."
    
    restore_firefox_session
    
    # Give Firefox time to restore, then verify
    sleep 8  # Firefox can take longer to restore complex sessions
    verify_firefox_restoration
    
    # Additional session state check
    check_firefox_session_state
    
    log_success "Firefox post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Firefox pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac