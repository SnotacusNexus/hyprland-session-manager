#!/usr/bin/env zsh

# Obsidian Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Obsidian vault session restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[OBSIDIAN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[OBSIDIAN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[OBSIDIAN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[OBSIDIAN HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS
# ============================================================================

# Detect if Obsidian is running
is_obsidian_running() {
    if pgrep -x "obsidian" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Obsidian window class
get_obsidian_class() {
    echo "obsidian"
}

# Find Obsidian installation methods
find_obsidian_installations() {
    local installations=()
    
    # System installation
    if command -v obsidian > /dev/null; then
        installations+=("system:obsidian")
    fi
    
    # Flatpak installation
    if command -v flatpak > /dev/null && flatpak list --app | grep -q "md.obsidian.Obsidian"; then
        installations+=("flatpak:md.obsidian.Obsidian")
    fi
    
    # AppImage (common locations)
    local appimage_locations=(
        "${HOME}/Applications/obsidian.AppImage"
        "${HOME}/.local/bin/obsidian"
        "${HOME}/Downloads/obsidian*.AppImage"
        "/opt/obsidian/obsidian.AppImage"
    )
    
    for location in "${appimage_locations[@]}"; do
        if ls $location > /dev/null 2>&1; then
            installations+=("appimage:$(ls $location | head -1)")
        fi
    done
    
    echo "${installations[@]}"
}

# Get Obsidian executable command
get_obsidian_command() {
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    
    # Check saved installation method first
    if [[ -f "${app_state_dir}/installation_method.txt" ]]; then
        local saved_method=$(cat "${app_state_dir}/installation_method.txt")
        case "$saved_method" in
            "system:obsidian")
                if command -v obsidian > /dev/null; then
                    echo "obsidian"
                    return 0
                fi
                ;;
            "flatpak:md.obsidian.Obsidian")
                if command -v flatpak > /dev/null; then
                    echo "flatpak run md.obsidian.Obsidian"
                    return 0
                fi
                ;;
            appimage:*)
                local appimage_path="${saved_method#appimage:}"
                if [[ -f "$appimage_path" && -x "$appimage_path" ]]; then
                    echo "$appimage_path"
                    return 0
                fi
                ;;
        esac
    fi
    
    # Fallback to available installations
    local installations=($(find_obsidian_installations))
    for installation in "${installations[@]}"; do
        case "$installation" in
            "system:obsidian")
                echo "obsidian"
                return 0
                ;;
            "flatpak:md.obsidian.Obsidian")
                echo "flatpak run md.obsidian.Obsidian"
                return 0
                ;;
            appimage:*)
                local appimage_path="${installation#appimage:}"
                echo "$appimage_path"
                return 0
                ;;
        esac
    done
    
    log_error "No Obsidian installation found"
    return 1
}

# Find Obsidian vaults from saved session data
find_saved_vaults() {
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    local vaults=()
    
    if [[ ! -d "$app_state_dir" ]]; then
        return 1
    fi
    
    # Extract vault paths from window titles
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        # Obsidian window titles often contain vault names in brackets
        local vault_names=$(grep -o "\[.*\]" "${app_state_dir}/window_titles.txt" | sed 's/\[\(.*\)\]/\1/' | sort -u)
        for vault_name in $vault_names; do
            # Try to find vault by name in common locations
            local possible_locations=(
                "${HOME}/Documents/Obsidian/${vault_name}"
                "${HOME}/Obsidian/${vault_name}"
                "${HOME}/.local/share/obsidian/${vault_name}"
                "${HOME}/${vault_name}"
            )
            
            for location in "${possible_locations[@]}"; do
                if [[ -d "$location" && -f "${location}/.obsidian" ]]; then
                    vaults+=("$location")
                    break
                fi
            done
        done
    fi
    
    # Also check for vaults from Obsidian configuration
    local obsidian_config="${HOME}/.config/obsidian"
    if [[ -d "$obsidian_config" ]]; then
        # Look for vault configuration files
        local config_vaults=$(find "$obsidian_config" -name "app.json" -exec grep -l "vaults" {} \; 2>/dev/null)
        if [[ -n "$config_vaults" ]]; then
            log_info "Found Obsidian vault configuration"
        fi
    fi
    
    echo "${vaults[@]}"
}

# Launch Obsidian with vault restoration
launch_obsidian_with_vaults() {
    local obsidian_cmd=$(get_obsidian_command)
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local vaults=($(find_saved_vaults))
    
    log_info "Launching Obsidian ($obsidian_cmd) for session restoration..."
    
    if [[ ${#vaults[@]} -eq 0 ]]; then
        # Launch Obsidian without specific vaults - it will restore last session
        log_info "No specific vaults found - launching Obsidian for auto-restore"
        $obsidian_cmd &
    else
        # Launch Obsidian with each vault
        log_info "Found ${#vaults[@]} vaults to restore"
        for vault in "${vaults[@]}"; do
            if [[ -d "$vault" && -f "${vault}/.obsidian" ]]; then
                log_info "Opening vault: $(basename "$vault")"
                $obsidian_cmd "$vault" &
                # Small delay between launches to avoid overwhelming the system
                sleep 1
            else
                log_warning "Invalid vault path: $vault"
            fi
        done
    fi
    
    local obsidian_pid=$!
    log_info "Obsidian launched with PID: $obsidian_pid"
    
    # Wait a moment for Obsidian to start
    sleep 2
    
    # Verify Obsidian started successfully
    if is_obsidian_running; then
        log_success "Obsidian launched successfully"
        return 0
    else
        log_error "Obsidian failed to start"
        return 1
    fi
}

# Restore Obsidian session data
restore_obsidian_session() {
    local app_class="$(get_obsidian_class)"
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Obsidian session data to restore"
        return
    fi
    
    log_info "Restoring Obsidian session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -8
    fi
    
    # Launch Obsidian if not running
    if ! is_obsidian_running; then
        launch_obsidian_with_vaults
    else
        log_info "Obsidian already running - session should auto-restore"
        
        # If Obsidian is already running, we can try to focus the windows
        # to ensure they're properly positioned by Hyprland
        local obsidian_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null)
        for window in $obsidian_windows; do
            hyprctl dispatch focuswindow "address:$window" > /dev/null 2>&1
            sleep 0.3
        done
    fi
    
    log_success "Obsidian session restoration initiated"
}

# Verify Obsidian session restoration
verify_obsidian_restoration() {
    local app_class="$(get_obsidian_class)"
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    
    log_info "Verifying Obsidian session restoration..."
    
    # Wait for Obsidian to fully load and restore session
    sleep 4
    
    # Check if Obsidian windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Obsidian windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Obsidian restoration verified - $current_windows windows detected"
            
            # Additional verification: check if windows have meaningful titles
            local window_titles=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" 2>/dev/null)
            if [[ -n "$window_titles" ]]; then
                log_info "Obsidian window titles:"
                echo "$window_titles" | head -5 | sed 's/^/  - /'
            fi
            
            return 0
        else
            log_warning "No Obsidian windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        if [[ $current_windows -gt 0 ]]; then
            log_success "Obsidian windows detected - restoration likely successful"
            return 0
        else
            log_warning "No Obsidian windows detected"
            return 1
        fi
    fi
}

# Handle Obsidian installation compatibility
ensure_obsidian_compatibility() {
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    
    log_info "Ensuring Obsidian installation compatibility..."
    
    # Check if saved installation method matches available installation
    if [[ -f "${app_state_dir}/installation_method.txt" ]]; then
        local saved_method=$(cat "${app_state_dir}/installation_method.txt")
        local current_method=""
        
        case "$saved_method" in
            "system:obsidian")
                if command -v obsidian > /dev/null; then
                    current_method="system:obsidian"
                fi
                ;;
            "flatpak:md.obsidian.Obsidian")
                if command -v flatpak > /dev/null && flatpak list --app | grep -q "md.obsidian.Obsidian"; then
                    current_method="flatpak:md.obsidian.Obsidian"
                fi
                ;;
            appimage:*)
                local appimage_path="${saved_method#appimage:}"
                if [[ -f "$appimage_path" && -x "$appimage_path" ]]; then
                    current_method="$saved_method"
                fi
                ;;
        esac
        
        if [[ -n "$current_method" && "$saved_method" != "$current_method" ]]; then
            log_warning "Obsidian installation method mismatch: saved=$saved_method, current=$current_method"
            log_info "Session restoration might work differently between installation methods"
        elif [[ -n "$current_method" ]]; then
            log_success "Obsidian installation method matches: $current_method"
        else
            log_warning "Saved Obsidian installation method not available: $saved_method"
        fi
    else
        log_info "No saved Obsidian installation method information"
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Obsidian post-restore hook..."
    
    # Ensure compatibility between Obsidian installations
    ensure_obsidian_compatibility
    
    # Restore Obsidian session
    restore_obsidian_session
    
    # Give Obsidian time to restore, then verify
    sleep 6
    verify_obsidian_restoration
    
    log_success "Obsidian post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Obsidian pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac