#!/usr/bin/env zsh

# Krita Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Krita document and session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Krita is running
is_krita_running() {
    # Support multiple Krita variants and installation methods
    if pgrep -x "krita" > /dev/null || \
       pgrep -f "krita-bin" > /dev/null || \
       pgrep -f "org.kde.krita" > /dev/null || \
       pgrep -f "flatpak.*krita" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Krita window class
get_krita_class() {
    # Krita can have different window classes depending on the distribution and installation method
    local krita_classes=("krita" "Krita" "org.kde.krita")
    
    for class in "${krita_classes[@]}"; do
        if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
            if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
                echo "$class"
                return 0
            fi
        fi
    done
    
    # Default fallback
    echo "krita"
}

# Find Krita configuration and data directories
find_krita_dirs() {
    local krita_dirs=()
    
    # Standard XDG locations
    if [[ -d "${HOME}/.config/krita" ]]; then
        krita_dirs+=("${HOME}/.config/krita")
    fi
    
    if [[ -d "${HOME}/.local/share/krita" ]]; then
        krita_dirs+=("${HOME}/.local/share/krita")
    fi
    
    # Flatpak installation
    if [[ -d "${HOME}/.var/app/org.kde.krita" ]]; then
        krita_dirs+=("${HOME}/.var/app/org.kde.krita")
    fi
    
    # Snap installation
    if [[ -d "${HOME}/snap/krita" ]]; then
        krita_dirs+=("${HOME}/snap/krita")
    fi
    
    echo "${krita_dirs[@]}"
}

# Get Krita executable command
get_krita_command() {
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    
    # Check saved variant first
    if [[ -f "${app_state_dir}/krita_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/krita_variant.txt")
        case "$saved_variant" in
            "system")
                if command -v krita > /dev/null; then
                    echo "krita"
                    return 0
                fi
                ;;
            "flatpak")
                if command -v flatpak > /dev/null && flatpak list --app | grep -q "org.kde.krita"; then
                    echo "flatpak run org.kde.krita"
                    return 0
                fi
                ;;
            "snap")
                if command -v snap > /dev/null && snap list | grep -q "krita"; then
                    echo "krita"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback to available variants
    if command -v krita > /dev/null; then
        echo "krita"
    elif command -v flatpak > /dev/null && flatpak list --app | grep -q "org.kde.krita"; then
        echo "flatpak run org.kde.krita"
    elif command -v snap > /dev/null && snap list | grep -q "krita"; then
        echo "krita"
    else
        log_error "No Krita installation found"
        return 1
    fi
}

# Launch Krita for session restoration
launch_krita_with_session() {
    local krita_cmd=$(get_krita_command)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    log_info "Launching Krita ($krita_cmd) for session restoration..."
    
    # Krita automatically restores documents from autosave on startup
    # We launch it without specific files to let it restore automatically
    $krita_cmd &
    
    local krita_pid=$!
    log_info "Krita launched with PID: $krita_pid"
    
    # Wait a moment for Krita to start
    sleep 3
    
    # Verify Krita started successfully
    if kill -0 $krita_pid 2>/dev/null; then
        log_success "Krita launched successfully"
        return 0
    else
        log_error "Krita failed to start"
        return 1
    fi
}

# Restore Krita configuration
restore_krita_config() {
    local app_state_dir="$1"
    
    log_info "Restoring Krita configuration..."
    
    # Note: We don't directly overwrite kritarc as it might contain user preferences
    # Instead, we focus on ensuring Krita can restore its session properly
    
    local krita_config="${HOME}/.config/krita"
    if [[ -d "$krita_config" ]]; then
        log_info "Found Krita config directory: $krita_config"
        
        # Ensure recent documents file exists
        mkdir -p "$krita_config"
        touch "${krita_config}/recentdocuments"
        
        log_info "Krita configuration structure verified"
    fi
}

# Restore Krita document session
restore_krita_documents() {
    local app_state_dir="$1"
    
    log_info "Preparing Krita document restoration..."
    
    local krita_data="${HOME}/.local/share/krita"
    if [[ -d "$krita_data" ]]; then
        # Ensure autosave directory exists
        local autosave_dir="${krita_data}/autosave"
        mkdir -p "$autosave_dir"
        
        # Krita will automatically detect and restore autosave files on startup
        # We just ensure the directory structure is intact
        log_info "Krita autosave directory ready: $autosave_dir"
        
        # Ensure recent documents directory exists
        local recent_docs="${krita_data}/recentdocuments"
        mkdir -p "$recent_docs"
        
        log_info "Krita document directories prepared for restoration"
    else
        log_warning "Krita data directory not found: $krita_data"
    fi
}

# Restore Krita session data
restore_krita_session() {
    local app_class="$(get_krita_class)"
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Krita session data to restore"
        return
    fi
    
    log_info "Restoring Krita session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore configuration structure
    restore_krita_config "$app_state_dir"
    
    # Prepare document restoration
    restore_krita_documents "$app_state_dir"
    
    # Launch Krita if not running
    if ! is_krita_running; then
        launch_krita_with_session
    else
        log_info "Krita already running - session should auto-restore"
        
        # If Krita is already running, we can try to trigger document restoration
        # by focusing the windows (Hyprland will handle window positioning)
        local krita_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null)
        for window in $krita_windows; do
            hyprctl dispatch focuswindow "address:$window" > /dev/null 2>&1
            sleep 0.5
        done
    fi
    
    log_success "Krita session restoration initiated"
}

# Verify Krita session restoration
verify_krita_restoration() {
    local app_class="$(get_krita_class)"
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    
    log_info "Verifying Krita session restoration..."
    
    # Wait for Krita to fully load and restore session
    sleep 5
    
    # Check if Krita windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Krita windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Krita restoration verified - $current_windows windows detected"
            
            # Additional verification: check if windows have meaningful titles
            local window_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null)
            if [[ -n "$window_titles" ]]; then
                log_info "Krita window titles:"
                echo "$window_titles" | head -5 | sed 's/^/  - /'
            fi
            
            return 0
        else
            log_warning "No Krita windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "Krita windows detected - restoration likely successful"
            return 0
        else
            log_warning "No Krita windows detected"
            return 1
        fi
    fi
}

# Handle Krita variant compatibility
ensure_krita_compatibility() {
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    
    log_info "Ensuring Krita variant compatibility..."
    
    # Check if saved variant matches available variant
    if [[ -f "${app_state_dir}/krita_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/krita_variant.txt")
        local current_variant=$(get_krita_command 2>/dev/null | grep -q "flatpak" && echo "flatpak" || \
                               get_krita_command 2>/dev/null | grep -q "snap" && echo "snap" || \
                               echo "system")
        
        if [[ "$saved_variant" != "$current_variant" ]]; then
            log_warning "Krita variant mismatch: saved=$saved_variant, current=$current_variant"
            log_info "Session restoration might work differently between variants"
        else
            log_success "Krita variant matches: $current_variant"
        fi
    else
        log_info "No saved Krita variant information"
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Krita post-restore hook..."
    
    # Ensure compatibility between Krita variants
    ensure_krita_compatibility
    
    # Restore Krita session
    restore_krita_session
    
    # Give Krita time to restore, then verify
    sleep 8
    verify_krita_restoration
    
    log_success "Krita post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Krita pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac