#!/usr/bin/env zsh

# 🐬 Dolphin File Manager Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Dolphin file manager session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[DOLPHIN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[DOLPHIN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[DOLPHIN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[DOLPHIN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Dolphin is running
is_dolphin_running() {
    if pgrep -x "dolphin" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Dolphin window class
get_dolphin_class() {
    # Dolphin can have different window classes depending on the distribution
    local dolphin_classes=("dolphin" "org.kde.dolphin" "Dolphin")
    
    for class in "${dolphin_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "dolphin"
}

# Launch Dolphin with session restoration
launch_dolphin_with_session() {
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    
    log_info "Launching Dolphin with session restoration..."
    
    # Check which Dolphin variant is available
    local dolphin_cmd=""
    if command -v dolphin > /dev/null; then
        dolphin_cmd="dolphin"
    elif command -v flatpak > /dev/null && flatpak list --app | grep -q "org.kde.dolphin"; then
        dolphin_cmd="flatpak run org.kde.dolphin"
    else
        log_error "No Dolphin executable found in PATH or Flatpak"
        return 1
    fi
    
    # Check if we have saved session data
    if [[ ! -d "$app_state_dir" ]]; then
        log_warning "No saved Dolphin session data found - launching normally"
        $dolphin_cmd &
        return 0
    fi
    
    # Get the last opened directories from window titles
    local directories=()
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        # Extract directory paths from window titles
        # Dolphin window titles typically show "Directory Name - Dolphin"
        while IFS= read -r title; do
            # Extract directory path from title (remove " - Dolphin" suffix)
            local dir_path=$(echo "$title" | sed 's/ - Dolphin$//')
            if [[ -n "$dir_path" && "$dir_path" != "Dolphin" ]]; then
                directories+=("$dir_path")
            fi
        done < "${app_state_dir}/window_titles.txt"
    fi
    
    # Launch Dolphin with saved directories
    if [[ ${#directories[@]} -gt 0 ]]; then
        log_info "Restoring ${#directories[@]} directory sessions"
        for dir in "${directories[@]}"; do
            if [[ -d "$dir" ]]; then
                log_info "Opening directory: $dir"
                $dolphin_cmd "$dir" &
                # Small delay between launches to avoid overwhelming the system
                sleep 0.5
            else
                log_warning "Directory no longer exists: $dir"
            fi
        done
    else
        log_info "No specific directories to restore - launching default Dolphin"
        $dolphin_cmd &
    fi
    
    local dolphin_pid=$!
    log_info "Dolphin launched with PID: $dolphin_pid"
    
    # Wait a moment for Dolphin to start
    sleep 2
    
    # Verify Dolphin started successfully
    if kill -0 $dolphin_pid 2>/dev/null; then
        log_success "Dolphin launched successfully"
        return 0
    else
        log_error "Dolphin failed to start"
        return 1
    fi
}

# Restore Dolphin configuration
restore_dolphin_configuration() {
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Dolphin configuration to restore"
        return
    fi
    
    log_info "Restoring Dolphin configuration..."
    
    local dolphin_config="${HOME}/.config/dolphinrc"
    
    # Restore main configuration if it exists and Dolphin isn't running
    if [[ -f "${app_state_dir}/dolphinrc" ]] && ! is_dolphin_running; then
        log_info "Restoring dolphinrc configuration"
        cp "${app_state_dir}/dolphinrc" "$dolphin_config" 2>/dev/null || log_warning "Failed to restore dolphinrc"
    fi
    
    # Restore Flatpak configuration if available
    local flatpak_dolphin="${HOME}/.var/app/org.kde.dolphin"
    if [[ -f "${app_state_dir}/flatpak_dolphinrc" ]] && [[ -d "$flatpak_dolphin" ]]; then
        log_info "Restoring Flatpak Dolphin configuration"
        find "$flatpak_dolphin" -name "dolphinrc" -exec cp "${app_state_dir}/flatpak_dolphinrc" {} \; 2>/dev/null || log_warning "Failed to restore Flatpak dolphinrc"
    fi
    
    # Restore session files if they exist
    local dolphin_session_dir="${HOME}/.local/share/dolphin/sessions"
    if [[ -d "$dolphin_session_dir" ]] && [[ -f "${app_state_dir}/session_files.txt" ]]; then
        log_info "Checking for session file restoration"
        # Note: We don't automatically restore session files as they might conflict
        # with current state. This is more for reference.
    fi
    
    log_success "Dolphin configuration restoration completed"
}

# Restore Dolphin session data
restore_dolphin_session() {
    local app_class="$(get_dolphin_class)"
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Dolphin session data to restore"
        return
    fi
    
    log_info "Restoring Dolphin session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore configuration first
    restore_dolphin_configuration
    
    # Launch Dolphin if not running
    if ! is_dolphin_running; then
        launch_dolphin_with_session
    else
        log_info "Dolphin already running - focusing on session restoration"
        # If Dolphin is already running, we can't easily restore specific directories
        # without closing and reopening, which might disrupt user workflow
        log_info "Existing Dolphin instances will maintain their current state"
    fi
    
    # Note: Window positions and layouts are handled by Hyprland automatically
    
    log_success "Dolphin session restoration initiated"
}

# Verify Dolphin session restoration
verify_dolphin_restoration() {
    local app_class="$(get_dolphin_class)"
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    
    log_info "Verifying Dolphin session restoration..."
    
    # Wait a bit for Dolphin to fully load
    sleep 3
    
    # Check if Dolphin windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Dolphin windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Dolphin restoration verified - $current_windows windows detected"
            
            # Log the current window titles for verification
            hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" | while read -r title; do
                log_info "Active Dolphin window: $title"
            done 2>/dev/null
            
            return 0
        else
            log_warning "No Dolphin windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "Dolphin windows detected: $current_windows"
            return 0
        else
            log_warning "No Dolphin windows running"
            return 1
        fi
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Dolphin post-restore hook..."
    
    restore_dolphin_session
    
    # Give Dolphin time to restore, then verify
    sleep 5
    verify_dolphin_restoration
    
    log_success "Dolphin post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Dolphin pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac