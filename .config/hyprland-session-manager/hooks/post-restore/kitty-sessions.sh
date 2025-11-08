#!/usr/bin/env zsh

# Kitty Terminal Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Kitty terminal session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Kitty is running
is_kitty_running() {
    if pgrep -x "kitty" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Kitty window class
get_kitty_class() {
    # Kitty terminal window class
    echo "kitty"
}

# Create session file from saved Kitty state
create_kitty_session_file() {
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    local session_file="${app_state_dir}/restore.session"
    
    log_info "Creating Kitty session file for restoration..."
    
    if [[ ! -f "${app_state_dir}/kitty_session_state.json" ]]; then
        log_warning "No saved Kitty session state found"
        return 1
    fi
    
    # Create a basic session file that can be used with kitty --session
    echo "# Kitty session file - created by Hyprland Session Manager" > "$session_file"
    echo "# Restored on $(date)" >> "$session_file"
    echo "" >> "$session_file"
    
    # Extract window information from saved state
    if command -v jq > /dev/null && [[ -f "${app_state_dir}/kitty_windows.txt" ]]; then
        # Group windows by tab
        local current_tab=""
        while IFS=: read -r window_id title cwd; do
            # Extract tab ID from window ID (first part before dot)
            local tab_id="${window_id%%.*}"
            
            if [[ "$tab_id" != "$current_tab" ]]; then
                if [[ -n "$current_tab" ]]; then
                    echo "" >> "$session_file"
                fi
                echo "new_tab" >> "$session_file"
                echo "layout stack" >> "$session_file"
                current_tab="$tab_id"
            fi
            
            echo "new_window" >> "$session_file"
            if [[ -n "$title" && "$title" != "null" ]]; then
                echo "title \"$title\"" >> "$session_file"
            fi
            if [[ -n "$cwd" && "$cwd" != "null" && -d "$cwd" ]]; then
                echo "cd \"$cwd\"" >> "$session_file"
            fi
            echo "launch $SHELL" >> "$session_file"
        done < "${app_state_dir}/kitty_windows.txt"
    else
        # Fallback: create a simple session with one window
        echo "new_tab" >> "$session_file"
        echo "layout stack" >> "$session_file"
        echo "new_window" >> "$session_file"
        echo "launch $SHELL" >> "$session_file"
    fi
    
    log_success "Kitty session file created: $session_file"
    echo "$session_file"
}

# Launch Kitty with session restoration
launch_kitty_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    
    log_info "Launching Kitty terminal with session restoration..."
    
    # Check if Kitty is available
    if ! command -v kitty > /dev/null; then
        log_error "Kitty terminal not found in PATH"
        return 1
    fi
    
    # Create session file
    local session_file=$(create_kitty_session_file)
    
    if [[ -n "$session_file" && -f "$session_file" ]]; then
        # Launch Kitty with the session file
        kitty --session "$session_file" &
        
        local kitty_pid=$!
        log_info "Kitty terminal launched with PID: $kitty_pid and session file: $session_file"
        
        # Wait a moment for Kitty to start
        sleep 2
        
        # Verify Kitty started successfully
        if kill -0 $kitty_pid 2>/dev/null; then
            log_success "Kitty terminal launched successfully with session restoration"
            return 0
        else
            log_error "Kitty terminal failed to start"
            return 1
        fi
    else
        # Fallback: launch Kitty normally
        log_warning "Could not create session file - launching Kitty normally"
        kitty &
        local kitty_pid=$!
        
        sleep 2
        if kill -0 $kitty_pid 2>/dev/null; then
            log_success "Kitty terminal launched normally"
            return 0
        else
            log_error "Kitty terminal failed to start"
            return 1
        fi
    fi
}

# Restore Kitty session data
restore_kitty_session() {
    local app_class="$(get_kitty_class)"
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Kitty terminal session data to restore"
        return
    fi
    
    log_info "Restoring Kitty terminal session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Launch Kitty if not running
    if ! is_kitty_running; then
        launch_kitty_with_session
    else
        log_info "Kitty terminal already running - attempting to restore session state"
        
        # If Kitty is already running, we can try to send commands to restore state
        if command -v kitty > /dev/null && [[ -f "${app_state_dir}/kitty_session_state.json" ]]; then
            log_info "Kitty is running - session state may need manual restoration"
            # Note: Kitty doesn't have a direct way to restore full session state to running instances
            # Users may need to manually restore tabs/windows
        fi
    fi
    
    log_success "Kitty terminal session restoration initiated"
}

# Verify Kitty session restoration
verify_kitty_restoration() {
    local app_class="$(get_kitty_class)"
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    
    log_info "Verifying Kitty terminal session restoration..."
    
    # Wait a bit for Kitty to fully load
    sleep 3
    
    # Check if Kitty windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Kitty windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Kitty terminal restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Kitty windows detected after restoration attempt"
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
    log_info "Starting Kitty terminal post-restore hook..."
    
    restore_kitty_session
    
    # Give Kitty time to restore, then verify
    sleep 5
    verify_kitty_restoration
    
    log_success "Kitty terminal post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Kitty pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac