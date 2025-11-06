#!/usr/bin/env zsh

# Terminator Terminal Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Terminator terminal session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TERMINATOR HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TERMINATOR HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TERMINATOR HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[TERMINATOR HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Terminator is running
is_terminator_running() {
    if pgrep -x "terminator" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Terminator window class
get_terminator_class() {
    # Terminator terminal window class
    echo "terminator"
}

# Determine which layout to use for restoration
get_restore_layout() {
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    
    # Check if we have saved layout information
    if [[ -f "${app_state_dir}/available_layouts.txt" ]]; then
        # Use the first available layout, or a default one
        local first_layout=$(head -1 "${app_state_dir}/available_layouts.txt" 2>/dev/null)
        if [[ -n "$first_layout" ]]; then
            echo "$first_layout"
            return 0
        fi
    fi
    
    # Fallback to default layout
    echo "default"
}

# Launch Terminator with layout restoration
launch_terminator_with_layout() {
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    
    log_info "Launching Terminator terminal with layout restoration..."
    
    # Check if Terminator is available
    if ! command -v terminator > /dev/null; then
        log_error "Terminator terminal not found in PATH"
        return 1
    fi
    
    # Determine which layout to use
    local restore_layout=$(get_restore_layout)
    
    log_info "Using layout: $restore_layout"
    
    # Launch Terminator with the specified layout
    terminator -l "$restore_layout" &
    
    local terminator_pid=$!
    log_info "Terminator terminal launched with PID: $terminator_pid and layout: $restore_layout"
    
    # Wait a moment for Terminator to start
    sleep 2
    
    # Verify Terminator started successfully
    if kill -0 $terminator_pid 2>/dev/null; then
        log_success "Terminator terminal launched successfully with layout restoration"
        return 0
    else
        log_error "Terminator terminal failed to start"
        return 1
    fi
}

# Restore Terminator configuration if needed
restore_terminator_config() {
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    local terminator_config="${HOME}/.config/terminator"
    
    if [[ ! -d "$terminator_config" ]]; then
        log_warning "Terminator configuration directory not found - cannot restore config"
        return 1
    fi
    
    # Check if we have a backed up config
    if [[ -f "${app_state_dir}/terminator_config.backup" ]]; then
        log_info "Found saved Terminator configuration - checking if restoration is needed..."
        
        # Only restore if the current config is missing or significantly different
        if [[ ! -f "${terminator_config}/config" ]]; then
            log_info "Restoring Terminator configuration..."
            cp "${app_state_dir}/terminator_config.backup" "${terminator_config}/config" 2>/dev/null || true
            log_success "Terminator configuration restored"
        else
            log_info "Terminator configuration already exists - keeping current version"
        fi
    fi
    
    # Restore layout files if they exist in backup
    if [[ -d "${app_state_dir}/layouts" ]]; then
        local layout_count=$(find "${app_state_dir}/layouts" -name "*.layout" | wc -l 2>/dev/null || echo "0")
        if [[ $layout_count -gt 0 ]]; then
            log_info "Found $layout_count layout files in backup"
            # Copy layout files back if they don't exist
            for layout_file in "${app_state_dir}/layouts"/*.layout; do
                local layout_name=$(basename "$layout_file")
                if [[ ! -f "${terminator_config}/${layout_name}" ]]; then
                    cp "$layout_file" "${terminator_config}/" 2>/dev/null || true
                    log_info "Restored layout: $layout_name"
                fi
            done
        fi
    fi
}

# Restore Terminator session data
restore_terminator_session() {
    local app_class="$(get_terminator_class)"
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Terminator terminal session data to restore"
        return
    fi
    
    log_info "Restoring Terminator terminal session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Restore configuration first
    restore_terminator_config
    
    # Launch Terminator if not running
    if ! is_terminator_running; then
        launch_terminator_with_layout
    else
        log_info "Terminator terminal already running - layout may need manual application"
        log_info "You can manually apply layouts using: terminator -l <layout_name>"
    fi
    
    log_success "Terminator terminal session restoration initiated"
}

# Verify Terminator session restoration
verify_terminator_restoration() {
    local app_class="$(get_terminator_class)"
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    
    log_info "Verifying Terminator terminal session restoration..."
    
    # Wait a bit for Terminator to fully load
    sleep 3
    
    # Check if Terminator windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Terminator windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Terminator terminal restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Terminator windows detected after restoration attempt"
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
    log_info "Starting Terminator terminal post-restore hook..."
    
    restore_terminator_session
    
    # Give Terminator time to restore, then verify
    sleep 5
    verify_terminator_restoration
    
    log_success "Terminator terminal post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Terminator pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac