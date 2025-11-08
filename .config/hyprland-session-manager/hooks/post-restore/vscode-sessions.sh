#!/usr/bin/env zsh

# VSCode Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for VSCode workspace and session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if VSCode is running
is_vscode_running() {
    # Support multiple VSCode variants
    if pgrep -x "code" > /dev/null || \
       pgrep -x "vscode" > /dev/null || \
       pgrep -x "codium" > /dev/null || \
       pgrep -f "code.*--type=renderer" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get VSCode window class
get_vscode_class() {
    # VSCode can have different window classes depending on the distribution and variant
    local vscode_classes=("code" "Code" "vscode" "VSCode" "codium" "VSCodium")
    
    for class in "${vscode_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "code"
}

# Find VSCode configuration directories
find_vscode_configs() {
    local config_dirs=()
    
    # Official VSCode
    if [[ -d "${HOME}/.config/Code" ]]; then
        config_dirs+=("${HOME}/.config/Code")
    fi
    
    # VSCodium
    if [[ -d "${HOME}/.config/VSCodium" ]]; then
        config_dirs+=("${HOME}/.config/VSCodium")
    fi
    
    # Alternative locations
    if [[ -d "${HOME}/.vscode" ]]; then
        config_dirs+=("${HOME}/.vscode")
    fi
    
    echo "${config_dirs[@]}"
}

# Get VSCode executable command
get_vscode_command() {
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    # Check saved variant first
    if [[ -f "${app_state_dir}/vscode_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/vscode_variant.txt")
        case "$saved_variant" in
            "code")
                if command -v code > /dev/null; then
                    echo "code"
                    return 0
                fi
                ;;
            "codium")
                if command -v codium > /dev/null; then
                    echo "codium"
                    return 0
                fi
                ;;
            "vscode")
                if command -v vscode > /dev/null; then
                    echo "vscode"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback to available variants
    if command -v code > /dev/null; then
        echo "code"
    elif command -v codium > /dev/null; then
        echo "codium"
    elif command -v vscode > /dev/null; then
        echo "vscode"
    else
        log_error "No VSCode variant found in PATH"
        return 1
    fi
}

# Launch VSCode with session restoration
launch_vscode_with_session() {
    local vscode_cmd=$(get_vscode_command)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    log_info "Launching VSCode ($vscode_cmd) for session restoration..."
    
    # VSCode automatically restores previous session by default
    # We launch it without specific files to let it restore automatically
    $vscode_cmd &
    
    local vscode_pid=$!
    log_info "VSCode launched with PID: $vscode_pid"
    
    # Wait a moment for VSCode to start
    sleep 3
    
    # Verify VSCode started successfully
    if kill -0 $vscode_pid 2>/dev/null; then
        log_success "VSCode launched successfully"
        return 0
    else
        log_error "VSCode failed to start"
        return 1
    fi
}

# Restore VSCode workspace storage data
restore_vscode_workspace_storage() {
    local app_state_dir="$1"
    local config_dirs=($(find_vscode_configs))
    
    log_info "Restoring VSCode workspace storage data..."
    
    # Note: VSCode workspace storage is complex and contains binary databases
    # We don't directly copy these files as they might be in use or corrupted
    # Instead, we rely on VSCode's built-in session restoration
    
    for config_dir in "${config_dirs[@]}"; do
        local user_config="${config_dir}/User"
        
        if [[ -d "$user_config" ]]; then
            log_info "Found VSCode config directory: $user_config"
            
            # VSCode will automatically restore workspaces from its internal state
            # We just ensure the directory structure exists
            mkdir -p "${user_config}/workspaceStorage"
            mkdir -p "${user_config}/globalStorage"
            
            log_info "VSCode workspace storage structure verified for $(basename "$config_dir")"
        fi
    done
}

# Restore VSCode session data
restore_vscode_session() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No VSCode session data to restore"
        return
    fi
    
    log_info "Restoring VSCode session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore workspace storage structure
    restore_vscode_workspace_storage "$app_state_dir"
    
    # Launch VSCode if not running
    if ! is_vscode_running; then
        launch_vscode_with_session
    else
        log_info "VSCode already running - session should auto-restore"
        
        # If VSCode is already running, we can try to trigger workspace restoration
        # by focusing the windows (Hyprland will handle window positioning)
        local vscode_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null)
        for window in $vscode_windows; do
            hyprctl dispatch focuswindow "address:$window" > /dev/null 2>&1
            sleep 0.5
        done
    fi
    
    log_success "VSCode session restoration initiated"
}

# Verify VSCode session restoration
verify_vscode_restoration() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    log_info "Verifying VSCode session restoration..."
    
    # Wait for VSCode to fully load and restore session
    sleep 5
    
    # Check if VSCode windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open VSCode windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "VSCode restoration verified - $current_windows windows detected"
            
            # Additional verification: check if windows have meaningful titles
            local window_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null)
            if [[ -n "$window_titles" ]]; then
                log_info "VSCode window titles:"
                echo "$window_titles" | head -5 | sed 's/^/  - /'
            fi
            
            return 0
        else
            log_warning "No VSCode windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "VSCode windows detected - restoration likely successful"
            return 0
        else
            log_warning "No VSCode windows detected"
            return 1
        fi
    fi
}

# Handle VSCode variant compatibility
ensure_vscode_compatibility() {
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    log_info "Ensuring VSCode variant compatibility..."
    
    # Check if saved variant matches available variant
    if [[ -f "${app_state_dir}/vscode_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/vscode_variant.txt")
        local current_variant=$(get_vscode_command 2>/dev/null || echo "unknown")
        
        if [[ "$saved_variant" != "$current_variant" ]]; then
            log_warning "VSCode variant mismatch: saved=$saved_variant, current=$current_variant"
            log_info "Session restoration might work differently between variants"
        else
            log_success "VSCode variant matches: $current_variant"
        fi
    else
        log_info "No saved VSCode variant information"
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting VSCode post-restore hook..."
    
    # Ensure compatibility between VSCode variants
    ensure_vscode_compatibility
    
    # Restore VSCode session
    restore_vscode_session
    
    # Give VSCode time to restore, then verify
    sleep 8
    verify_vscode_restoration
    
    log_success "VSCode post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "VSCode pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac