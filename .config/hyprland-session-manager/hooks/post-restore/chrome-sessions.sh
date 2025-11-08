#!/usr/bin/env zsh

# Chrome/Chromium Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Chrome/Chromium browser session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Chrome/Chromium is running
is_chrome_running() {
    if pgrep -x "chrome" > /dev/null || pgrep -x "chromium" > /dev/null || pgrep -x "google-chrome" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Chrome/Chromium window class
get_chrome_class() {
    # Chrome/Chromium can have different window classes depending on the distribution
    local chrome_classes=("google-chrome" "chromium" "chrome" "Chromium" "Google-chrome")
    
    for class in "${chrome_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "google-chrome"
}

# Launch Chrome/Chromium with session restoration
launch_chrome_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/chrome"
    
    log_info "Launching Chrome/Chromium with session restoration..."
    
    # Check which Chrome variant is available
    local chrome_cmd=""
    if command -v google-chrome > /dev/null; then
        chrome_cmd="google-chrome"
    elif command -v chromium > /dev/null; then
        chrome_cmd="chromium"
    elif command -v chrome > /dev/null; then
        chrome_cmd="chrome"
    else
        log_error "No Chrome/Chromium executable found in PATH"
        return 1
    fi
    
    # Chrome automatically restores sessions by default, but we can ensure it
    # Launch in background and continue
    $chrome_cmd --restore-last-session &
    
    local chrome_pid=$!
    log_info "Chrome/Chromium launched with PID: $chrome_pid"
    
    # Wait a moment for Chrome to start
    sleep 2
    
    # Verify Chrome started successfully
    if kill -0 $chrome_pid 2>/dev/null; then
        log_success "Chrome/Chromium launched successfully"
        return 0
    else
        log_error "Chrome/Chromium failed to start"
        return 1
    fi
}

# Restore Chrome session data
restore_chrome_session() {
    local app_class="$(get_chrome_class)"
    local app_state_dir="${SESSION_STATE_DIR}/chrome"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Chrome/Chromium session data to restore"
        return
    fi
    
    log_info "Restoring Chrome/Chromium session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Launch Chrome if not running
    if ! is_chrome_running; then
        launch_chrome_with_session
    else
        log_info "Chrome/Chromium already running - session should auto-restore"
    fi
    
    # Note: Chrome automatically handles session restoration from its internal state
    # The window positions and layouts are handled by Hyprland
    
    log_success "Chrome/Chromium session restoration initiated"
}

# Verify Chrome session restoration
verify_chrome_restoration() {
    local app_class="$(get_chrome_class)"
    local app_state_dir="${SESSION_STATE_DIR}/chrome"
    
    log_info "Verifying Chrome/Chromium session restoration..."
    
    # Wait a bit for Chrome to fully load
    sleep 3
    
    # Check if Chrome windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Chrome windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Chrome/Chromium restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Chrome windows detected after restoration attempt"
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
    log_info "Starting Chrome/Chromium post-restore hook..."
    
    restore_chrome_session
    
    # Give Chrome time to restore, then verify
    sleep 5
    verify_chrome_restoration
    
    log_success "Chrome/Chromium post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Chrome pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac