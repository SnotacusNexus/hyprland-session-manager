#!/usr/bin/env zsh

# LibreOffice Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for LibreOffice document and session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if LibreOffice is running
is_libreoffice_running() {
    # Support multiple LibreOffice variants and components
    if pgrep -x "soffice" > /dev/null || \
       pgrep -x "libreoffice" > /dev/null || \
       pgrep -f "soffice.bin" > /dev/null || \
       pgrep -f "libreoffice.*writer" > /dev/null || \
       pgrep -f "libreoffice.*calc" > /dev/null || \
       pgrep -f "libreoffice.*impress" > /dev/null || \
       pgrep -f "libreoffice.*draw" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get LibreOffice window class
get_libreoffice_class() {
    # LibreOffice can have different window classes depending on the component
    local libreoffice_classes=("libreoffice" "LibreOffice" "soffice" "libreoffice-writer" "libreoffice-calc" "libreoffice-impress" "libreoffice-draw")
    
    for class in "${libreoffice_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "libreoffice"
}

# Find LibreOffice configuration directories
find_libreoffice_configs() {
    local config_dirs=()
    
    # Standard LibreOffice configuration
    if [[ -d "${HOME}/.config/libreoffice" ]]; then
        config_dirs+=("${HOME}/.config/libreoffice")
    fi
    
    # Alternative locations (older versions)
    if [[ -d "${HOME}/.libreoffice" ]]; then
        config_dirs+=("${HOME}/.libreoffice")
    fi
    
    # Flatpak location
    if [[ -d "${HOME}/.var/app/org.libreoffice.LibreOffice/config/libreoffice" ]]; then
        config_dirs+=("${HOME}/.var/app/org.libreoffice.LibreOffice/config/libreoffice")
    fi
    
    # Snap location
    if [[ -d "${HOME}/snap/libreoffice/current/.config/libreoffice" ]]; then
        config_dirs+=("${HOME}/snap/libreoffice/current/.config/libreoffice")
    fi
    
    echo "${config_dirs[@]}"
}

# Get LibreOffice executable command
get_libreoffice_command() {
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    
    # Check saved variant first
    if [[ -f "${app_state_dir}/libreoffice_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/libreoffice_variant.txt")
        case "$saved_variant" in
            "soffice")
                if command -v soffice > /dev/null; then
                    echo "soffice"
                    return 0
                fi
                ;;
            "libreoffice")
                if command -v libreoffice > /dev/null; then
                    echo "libreoffice"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback to available variants
    if command -v soffice > /dev/null; then
        echo "soffice"
    elif command -v libreoffice > /dev/null; then
        echo "libreoffice"
    else
        log_error "No LibreOffice variant found in PATH"
        return 1
    fi
}

# Launch LibreOffice with session restoration
launch_libreoffice_with_session() {
    local libreoffice_cmd=$(get_libreoffice_command)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    log_info "Launching LibreOffice ($libreoffice_cmd) for session restoration..."
    
    # LibreOffice automatically restores documents from recovery files
    # We launch it without specific files to let it restore automatically
    $libreoffice_cmd &
    
    local libreoffice_pid=$!
    log_info "LibreOffice launched with PID: $libreoffice_pid"
    
    # Wait a moment for LibreOffice to start
    sleep 3
    
    # Verify LibreOffice started successfully
    if kill -0 $libreoffice_pid 2>/dev/null; then
        log_success "LibreOffice launched successfully"
        return 0
    else
        log_error "LibreOffice failed to start"
        return 1
    fi
}

# Restore LibreOffice registry modifications
restore_libreoffice_registry() {
    local app_state_dir="$1"
    local config_dirs=($(find_libreoffice_configs))
    
    log_info "Restoring LibreOffice registry modifications..."
    
    # Note: We need to be careful with registry files as they might be in use
    # We'll restore them only if LibreOffice is not running
    
    if ! is_libreoffice_running; then
        for config_dir in "${config_dirs[@]}"; do
            if [[ -d "$config_dir" ]]; then
                log_info "Found LibreOffice config directory: $config_dir"
                
                # Look for backed up registry files
                for registry_backup in "${app_state_dir}"/registry_*.xcu; do
                    if [[ -f "$registry_backup" ]]; then
                        # Extract original path from backup filename
                        local original_path=$(echo "$registry_backup" | sed 's|.*registry_||' | sed 's|_|/|g' | sed 's|_config/|.config/|' | sed 's|_home_|/home/|')
                        local full_path="${HOME}/${original_path}"
                        
                        # Create directory if needed
                        local dir_path=$(dirname "$full_path")
                        mkdir -p "$dir_path"
                        
                        # Restore the registry file
                        cp "$registry_backup" "$full_path" 2>/dev/null && \
                            log_info "Restored registry file: $full_path" || \
                            log_warning "Failed to restore registry file: $full_path"
                    fi
                done
            fi
        done
    else
        log_warning "LibreOffice is running - skipping registry restoration to avoid conflicts"
    fi
}

# Verify LibreOffice recovery files
verify_libreoffice_recovery_files() {
    local app_state_dir="$1"
    
    log_info "Verifying LibreOffice recovery files..."
    
    # Check if recovery files exist in standard locations
    local recovery_locations=(
        "${HOME}/.local/share/libreoffice"
        "${HOME}/.cache/libreoffice"
        "${HOME}/.var/app/org.libreoffice.LibreOffice/cache/libreoffice"
        "${HOME}/snap/libreoffice/current/.cache/libreoffice"
    )
    
    local recovery_found=false
    
    for location in "${recovery_locations[@]}"; do
        if [[ -d "$location" ]]; then
            local recovery_count=$(find "$location" \( -name "*recovery*" -o -name "*autosave*" \) -type f 2>/dev/null | wc -l)
            if [[ $recovery_count -gt 0 ]]; then
                log_info "Found $recovery_count recovery files in $location"
                recovery_found=true
            fi
        fi
    done
    
    if [[ "$recovery_found" == true ]]; then
        log_success "LibreOffice recovery files verified"
        return 0
    else
        log_warning "No LibreOffice recovery files found"
        return 1
    fi
}

# Restore LibreOffice session data
restore_libreoffice_session() {
    local app_class="$(get_libreoffice_class)"
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No LibreOffice session data to restore"
        return
    fi
    
    log_info "Restoring LibreOffice session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Restore registry modifications (if safe)
    restore_libreoffice_registry "$app_state_dir"
    
    # Verify recovery files exist
    verify_libreoffice_recovery_files "$app_state_dir"
    
    # Launch LibreOffice if not running
    if ! is_libreoffice_running; then
        launch_libreoffice_with_session
    else
        log_info "LibreOffice already running - recovery should auto-restore"
        
        # If LibreOffice is already running, we can try to trigger document restoration
        # by focusing the windows (Hyprland will handle window positioning)
        local libreoffice_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null)
        for window in $libreoffice_windows; do
            hyprctl dispatch focuswindow "address:$window" > /dev/null 2>&1
            sleep 0.5
        done
    fi
    
    log_success "LibreOffice session restoration initiated"
}

# Verify LibreOffice session restoration
verify_libreoffice_restoration() {
    local app_class="$(get_libreoffice_class)"
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    
    log_info "Verifying LibreOffice session restoration..."
    
    # Wait for LibreOffice to fully load and restore documents
    sleep 5
    
    # Check if LibreOffice windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open LibreOffice windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "LibreOffice restoration verified - $current_windows windows detected"
            
            # Additional verification: check if windows have meaningful titles (document names)
            local window_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null)
            if [[ -n "$window_titles" ]]; then
                log_info "LibreOffice window titles:"
                echo "$window_titles" | head -5 | sed 's/^/  - /'
            fi
            
            # Check if documents were restored (window titles should contain document names)
            local document_windows=$(echo "$window_titles" | grep -E "\.od[tspg]|\.docx?|\.xlsx?|\.pptx?" | wc -l)
            if [[ $document_windows -gt 0 ]]; then
                log_success "Document restoration verified - $document_windows documents detected"
            else
                log_warning "No document windows detected - session may be empty"
            fi
            
            return 0
        else
            log_warning "No LibreOffice windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "LibreOffice windows detected - restoration likely successful"
            return 0
        else
            log_warning "No LibreOffice windows detected"
            return 1
        fi
    fi
}

# Handle LibreOffice variant compatibility
ensure_libreoffice_compatibility() {
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    
    log_info "Ensuring LibreOffice variant compatibility..."
    
    # Check if saved variant matches available variant
    if [[ -f "${app_state_dir}/libreoffice_variant.txt" ]]; then
        local saved_variant=$(cat "${app_state_dir}/libreoffice_variant.txt")
        local current_variant=$(get_libreoffice_command 2>/dev/null || echo "unknown")
        
        if [[ "$saved_variant" != "$current_variant" ]]; then
            log_warning "LibreOffice variant mismatch: saved=$saved_variant, current=$current_variant"
            log_info "Session restoration might work differently between variants"
        else
            log_success "LibreOffice variant matches: $current_variant"
        fi
    else
        log_info "No saved LibreOffice variant information"
    fi
}

# Check for recovery file conflicts
check_recovery_conflicts() {
    log_info "Checking for recovery file conflicts..."
    
    local recovery_locations=(
        "${HOME}/.local/share/libreoffice"
        "${HOME}/.cache/libreoffice"
    )
    
    local conflicts_found=false
    
    for location in "${recovery_locations[@]}"; do
        if [[ -d "$location" ]]; then
            # Check for multiple recovery files for the same document
            local duplicate_recoveries=$(find "$location" -name "*recovery*" -type f 2>/dev/null | \
                sed 's/.*recovery-//' | sort | uniq -d)
            
            if [[ -n "$duplicate_recoveries" ]]; then
                log_warning "Found potential recovery file conflicts in $location"
                conflicts_found=true
            fi
        fi
    done
    
    if [[ "$conflicts_found" == false ]]; then
        log_success "No recovery file conflicts detected"
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting LibreOffice post-restore hook..."
    
    # Ensure compatibility between LibreOffice variants
    ensure_libreoffice_compatibility
    
    # Check for potential recovery file conflicts
    check_recovery_conflicts
    
    # Restore LibreOffice session
    restore_libreoffice_session
    
    # Give LibreOffice time to restore, then verify
    sleep 8
    verify_libreoffice_restoration
    
    log_success "LibreOffice post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "LibreOffice pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac