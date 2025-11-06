#!/usr/bin/env zsh

# Thorium Browser Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Thorium browser session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Thorium is running
is_thorium_running() {
    if pgrep -x "thorium" > /dev/null || pgrep -f "thorium-browser" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Thorium window class
get_thorium_class() {
    # Thorium can have different window classes
    local thorium_classes=("thorium-browser" "Thorium" "thorium")
    
    for class in "${thorium_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "thorium-browser"
}

# Launch Thorium with session restoration
launch_thorium_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/thorium"
    
    log_info "Launching Thorium browser with session restoration..."
    
    # Check if Thorium is available
    local thorium_cmd=""
    if command -v thorium-browser > /dev/null; then
        thorium_cmd="thorium-browser"
    elif command -v thorium > /dev/null; then
        thorium_cmd="thorium"
    else
        log_error "No Thorium browser executable found in PATH"
        return 1
    fi
    
    # Thorium automatically restores sessions by default, but we can ensure it
    # Launch with session restoration flag
    $thorium_cmd --restore-last-session &
    
    local thorium_pid=$!
    log_info "Thorium browser launched with PID: $thorium_pid"
    
    # Wait a moment for Thorium to start
    sleep 2
    
    # Verify Thorium started successfully
    if kill -0 $thorium_pid 2>/dev/null; then
        log_success "Thorium browser launched successfully"
        return 0
    else
        log_error "Thorium browser failed to start"
        return 1
    fi
}

# Restore Thorium session data
restore_thorium_session() {
    local app_class="$(get_thorium_class)"
    local app_state_dir="${SESSION_STATE_DIR}/thorium"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Thorium browser session data to restore"
        return
    fi
    
    log_info "Restoring Thorium browser session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Launch Thorium if not running
    if ! is_thorium_running; then
        launch_thorium_with_session
    else
        log_info "Thorium browser already running - session should auto-restore"
    fi
    
    # Note: Thorium automatically handles session restoration from its internal state
    # The window positions and layouts are handled by Hyprland
    
    log_success "Thorium browser session restoration initiated"
}

# Verify Thorium session restoration
verify_thorium_restoration() {
    local app_class="$(get_thorium_class)"
    local app_state_dir="${SESSION_STATE_DIR}/thorium"
    
    log_info "Verifying Thorium browser session restoration..."
    
    # Wait a bit for Thorium to fully load
    sleep 3
    
    # Check if Thorium windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Thorium windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Thorium browser restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Thorium windows detected after restoration attempt"
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
    log_info "Starting Thorium browser post-restore hook..."
    
    restore_thorium_session
    
    # Give Thorium time to restore, then verify
    sleep 5
    verify_thorium_restoration
    
    log_success "Thorium browser post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Thorium pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac