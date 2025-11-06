#!/usr/bin/env zsh

# Signal Desktop Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Signal Desktop session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Signal is running
is_signal_running() {
    if pgrep -x "signal-desktop" > /dev/null || pgrep -f "Signal" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Signal window class
get_signal_class() {
    # Signal Desktop window classes
    local signal_classes=("signal-desktop" "Signal" "signal")
    
    for class in "${signal_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "signal-desktop"
}

# Launch Signal Desktop
launch_signal() {
    log_info "Launching Signal Desktop..."
    
    # Check if Signal is available
    local signal_cmd=""
    if command -v signal-desktop > /dev/null; then
        signal_cmd="signal-desktop"
    elif command -v signal > /dev/null; then
        signal_cmd="signal"
    else
        log_error "No Signal Desktop executable found in PATH"
        return 1
    fi
    
    # Launch Signal (it auto-restores sessions from its configuration)
    $signal_cmd &
    
    local signal_pid=$!
    log_info "Signal Desktop launched with PID: $signal_pid"
    
    # Wait a moment for Signal to start
    sleep 3
    
    # Verify Signal started successfully
    if kill -0 $signal_pid 2>/dev/null; then
        log_success "Signal Desktop launched successfully"
        return 0
    else
        log_error "Signal Desktop failed to start"
        return 1
    fi
}

# Verify Signal configuration
verify_signal_config() {
    local signal_config="${HOME}/.config/Signal"
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    
    log_info "Verifying Signal configuration..."
    
    if [[ -d "$signal_config" ]]; then
        log_success "Signal configuration directory exists"
        
        # Check if key configuration files exist
        local key_files_exist=0
        local important_files=("config.json" "settings.json" "window-state.json")
        
        for file in "${important_files[@]}"; do
            if [[ -f "${signal_config}/${file}" ]]; then
                key_files_exist=$((key_files_exist + 1))
                log_info "Found configuration file: $file"
            fi
        done
        
        if [[ $key_files_exist -gt 0 ]]; then
            log_success "Found $key_files_exist key configuration files - Signal should restore sessions"
            return 0
        else
            log_warning "No key configuration files found - Signal may start fresh"
            return 1
        fi
    else
        log_warning "Signal configuration directory not found - Signal will start fresh"
        return 1
    fi
}

# Restore Signal configuration if needed
restore_signal_config() {
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    local signal_config="${HOME}/.config/Signal"
    
    if [[ ! -d "$signal_config" ]]; then
        log_warning "Signal configuration directory not found - cannot restore config"
        return 1
    fi
    
    # Check if we have backed up configuration files
    local restored_files=0
    local config_files=("config.json" "settings.json" "window-state.json")
    
    for file in "${config_files[@]}"; do
        if [[ -f "${app_state_dir}/${file}" ]]; then
            # Only restore if the file doesn't exist or is significantly different
            if [[ ! -f "${signal_config}/${file}" ]]; then
                log_info "Restoring Signal configuration file: $file"
                cp "${app_state_dir}/${file}" "${signal_config}/" 2>/dev/null || true
                restored_files=$((restored_files + 1))
            else
                log_info "Signal configuration file already exists: $file"
            fi
        fi
    done
    
    if [[ $restored_files -gt 0 ]]; then
        log_success "Restored $restored_files Signal configuration files"
        return 0
    else
        log_info "No Signal configuration files needed restoration"
        return 0
    fi
}

# Restore Signal session data
restore_signal_session() {
    local app_class="$(get_signal_class)"
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Signal Desktop session data to restore"
        return
    fi
    
    log_info "Restoring Signal Desktop session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Restore configuration files first
    restore_signal_config
    
    # Verify Signal configuration
    verify_signal_config
    
    # Launch Signal if not running
    if ! is_signal_running; then
        launch_signal
    else
        log_info "Signal Desktop already running - sessions should be preserved"
    fi
    
    # Note: Signal automatically handles session restoration from its configuration
    # The window positions and layouts are handled by Hyprland
    
    log_success "Signal Desktop session restoration initiated"
}

# Verify Signal session restoration
verify_signal_restoration() {
    local app_class="$(get_signal_class)"
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    
    log_info "Verifying Signal Desktop session restoration..."
    
    # Wait a bit for Signal to fully load
    sleep 5
    
    # Check if Signal windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Signal windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Signal Desktop restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Signal windows detected after restoration attempt"
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
    log_info "Starting Signal Desktop post-restore hook..."
    
    restore_signal_session
    
    # Give Signal time to restore, then verify
    sleep 8
    verify_signal_restoration
    
    log_success "Signal Desktop post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Signal pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac