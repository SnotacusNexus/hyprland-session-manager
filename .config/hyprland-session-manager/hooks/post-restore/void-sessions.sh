#!/usr/bin/env zsh

# Void IDE Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Void IDE workspace and session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Void IDE is running
is_void_running() {
    if pgrep -x "void" > /dev/null || pgrep -f "Void" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Void IDE window class
get_void_class() {
    # Void IDE window classes
    local void_classes=("void" "Void" "void-ide")
    
    for class in "${void_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "void"
}

# Find Void IDE configuration directories
find_void_configs() {
    local config_dirs=()
    
    # Primary Void IDE configuration
    if [[ -d "${HOME}/.config/Void" ]]; then
        config_dirs+=("${HOME}/.config/Void")
    fi
    
    # Alternative locations
    if [[ -d "${HOME}/.void" ]]; then
        config_dirs+=("${HOME}/.void")
    fi
    
    # Flatpak locations
    if [[ -d "${HOME}/.var/app/com.void.ide" ]]; then
        config_dirs+=("${HOME}/.var/app/com.void.ide")
    fi
    
    echo "${config_dirs[@]}"
}

# Get Void IDE executable command
get_void_command() {
    local app_state_dir="${SESSION_STATE_DIR}/void"
    
    # Check saved variant first
    if [[ -f "${app_state_dir}/void_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/void_variant.txt")
        case "$saved_variant" in
            "void")
                if command -v void > /dev/null; then
                    echo "void"
                    return 0
                fi
                ;;
            "void-ide")
                if command -v void-ide > /dev/null; then
                    echo "void-ide"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback to available variants
    if command -v void > /dev/null; then
        echo "void"
    elif command -v void-ide > /dev/null; then
        echo "void-ide"
    else
        log_error "No Void IDE variant found in PATH"
        return 1
    fi
}

# Launch Void IDE with session restoration
launch_void_with_session() {
    local void_cmd=$(get_void_command)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    log_info "Launching Void IDE ($void_cmd) for session restoration..."
    
    # Void IDE automatically restores previous session by default
    # We launch it without specific files to let it restore automatically
    $void_cmd &
    
    local void_pid=$!
    log_info "Void IDE launched with PID: $void_pid"
    
    # Wait a moment for Void IDE to start
    sleep 3
    
    # Verify Void IDE started successfully
    if kill -0 $void_pid 2>/dev/null; then
        log_success "Void IDE launched successfully"
        return 0
    else
        log_error "Void IDE failed to start"
        return 1
    fi
}

# Restore Void IDE workspace storage data
restore_void_workspace_storage() {
    local app_state_dir="$1"
    local config_dirs=($(find_void_configs))
    
    log_info "Restoring Void IDE workspace storage data..."
    
    # Note: Void IDE workspace storage is complex and contains binary databases
    # We don't directly copy these files as they might be in use or corrupted
    # Instead, we rely on Void IDE's built-in session restoration
    
    for config_dir in "${config_dirs[@]}"; do
        local user_config="${config_dir}/User"
        
        if [[ -d "$user_config" ]]; then
            log_info "Found Void IDE config directory: $user_config"
            
            # Void IDE will automatically restore workspaces from its internal state
            # We just ensure the directory structure exists
            mkdir -p "${user_config}/workspaceStorage"
            mkdir -p "${user_config}/globalStorage"
            
            log_info "Void IDE workspace storage structure verified for $(basename "$config_dir")"
        fi
    done
}

# Restore Void IDE session data
restore_void_session() {
    local app_class="$(get_void_class)"
    local app_state_dir="${SESSION_STATE_DIR}/void"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Void IDE session data to restore"
        return
    fi
    
    log_info "Restoring Void IDE session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore workspace storage structure
    restore_void_workspace_storage "$app_state_dir"
    
    # Launch Void IDE if not running
    if ! is_void_running; then
        launch_void_with_session
    else
        log_info "Void IDE already running - session should auto-restore"
        
        # If Void IDE is already running, we can try to trigger workspace restoration
        # by focusing the windows (Hyprland will handle window positioning)
        local void_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null)
        for window in $void_windows; do
            hyprctl dispatch focuswindow "address:$window" > /dev/null 2>&1
            sleep 0.5
        done
    fi
    
    log_success "Void IDE session restoration initiated"
}

# Verify Void IDE session restoration
verify_void_restoration() {
    local app_class="$(get_void_class)"
    local app_state_dir="${SESSION_STATE_DIR}/void"
    
    log_info "Verifying Void IDE session restoration..."
    
    # Wait for Void IDE to fully load and restore session
    sleep 5
    
    # Check if Void IDE windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Void IDE windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Void IDE restoration verified - $current_windows windows detected"
            
            # Additional verification: check if windows have meaningful titles
            local window_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null)
            if [[ -n "$window_titles" ]]; then
                log_info "Void IDE window titles:"
                echo "$window_titles" | head -5 | sed 's/^/  - /'
            fi
            
            return 0
        else
            log_warning "No Void IDE windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "Void IDE windows detected - restoration likely successful"
            return 0
        else
            log_warning "No Void IDE windows detected"
            return 1
        fi
    fi
}

# Handle Void IDE variant compatibility
ensure_void_compatibility() {
    local app_state_dir="${SESSION_STATE_DIR}/void"
    
    log_info "Ensuring Void IDE variant compatibility..."
    
    # Check if saved variant matches available variant
    if [[ -f "${app_state_dir}/void_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/void_variant.txt")
        local current_variant=$(get_void_command 2>/dev/null || echo "unknown")
        
        if [[ "$saved_variant" != "$current_variant" ]]; then
            log_warning "Void IDE variant mismatch: saved=$saved_variant, current=$current_variant"
            log_info "Session restoration might work differently between variants"
        else
            log_success "Void IDE variant matches: $current_variant"
        fi
    else
        log_info "No saved Void IDE variant information"
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Void IDE post-restore hook..."
    
    # Ensure compatibility between Void IDE variants
    ensure_void_compatibility
    
    # Restore Void IDE session
    restore_void_session
    
    # Give Void IDE time to restore, then verify
    sleep 8
    verify_void_restoration
    
    log_success "Void IDE post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Void IDE pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac