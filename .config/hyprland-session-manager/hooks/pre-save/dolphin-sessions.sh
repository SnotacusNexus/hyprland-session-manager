#!/usr/bin/env zsh

# 🐬 Dolphin File Manager Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Dolphin file manager session preservation

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
# PRE-SAVE HOOK FUNCTIONS
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

# Save Dolphin session data
save_dolphin_session() {
    local app_class="$(get_dolphin_class)"
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    
    log_info "Saving Dolphin session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain directory paths)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Dolphin configuration and session files
    local dolphin_config="${HOME}/.config/dolphinrc"
    local dolphin_session_dir="${HOME}/.local/share/dolphin/sessions"
    local dolphin_view_props="${HOME}/.local/share/dolphin/view_properties"
    
    # Save main configuration file
    if [[ -f "$dolphin_config" ]]; then
        log_info "Saving Dolphin configuration..."
        cp "$dolphin_config" "${app_state_dir}/dolphinrc" 2>/dev/null || log_warning "Failed to copy dolphinrc"
    fi
    
    # Save session files if they exist
    if [[ -d "$dolphin_session_dir" ]]; then
        log_info "Saving Dolphin session files..."
        find "$dolphin_session_dir" -name "*.desktop" -o -name "*.session" > "${app_state_dir}/session_files.txt" 2>/dev/null
        # Copy recent session files
        find "$dolphin_session_dir" -name "*.desktop" -exec cp {} "${app_state_dir}/" \; 2>/dev/null || true
    fi
    
    # Save view properties
    if [[ -d "$dolphin_view_props" ]]; then
        log_info "Saving Dolphin view properties..."
        find "$dolphin_view_props" -name "*.ini" > "${app_state_dir}/view_properties.txt" 2>/dev/null
    fi
    
    # Save recent directories and files
    local dolphin_recent="${HOME}/.local/share/recently-used.xbel"
    if [[ -f "$dolphin_recent" ]]; then
        log_info "Saving recent files list..."
        cp "$dolphin_recent" "${app_state_dir}/recently-used.xbel" 2>/dev/null || log_warning "Failed to copy recently-used.xbel"
    fi
    
    # Save split view state from dolphinrc
    if [[ -f "$dolphin_config" ]]; then
        grep -E "(SplitView|SplitterSizes|LastUrl)" "$dolphin_config" > "${app_state_dir}/split_view_state.txt" 2>/dev/null || true
    fi
    
    # Save process information
    pgrep -f "dolphin" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save environment information
    printenv | grep -i "dolphin" > "${app_state_dir}/environment.txt" 2>/dev/null
    
    # Save Flatpak Dolphin data if available
    local flatpak_dolphin="${HOME}/.var/app/org.kde.dolphin"
    if [[ -d "$flatpak_dolphin" ]]; then
        log_info "Found Flatpak Dolphin installation, saving configuration..."
        find "$flatpak_dolphin" -name "dolphinrc" -o -name "sessions" > "${app_state_dir}/flatpak_config_locations.txt" 2>/dev/null
        # Copy Flatpak dolphinrc
        find "$flatpak_dolphin" -name "dolphinrc" -exec cp {} "${app_state_dir}/flatpak_dolphinrc" \; 2>/dev/null || true
    fi
    
    log_success "Dolphin session data saved"
}

# Create Dolphin session summary
create_dolphin_summary() {
    local app_class="$(get_dolphin_class)"
    local app_state_dir="${SESSION_STATE_DIR}/dolphin"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Dolphin session summary..."
    
    echo "Dolphin File Manager Session Summary - $(date)" > "$summary_file"
    echo "==============================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Dolphin windows: $window_count" >> "$summary_file"
    
    # Window titles (directory paths)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Open directories:" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Session files found
    if [[ -f "${app_state_dir}/session_files.txt" ]]; then
        local session_count=$(wc -l < "${app_state_dir}/session_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Session files: $session_count" >> "$summary_file"
    fi
    
    # Split view state
    if [[ -f "${app_state_dir}/split_view_state.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Split view configuration:" >> "$summary_file"
        grep "SplitView" "${app_state_dir}/split_view_state.txt" | head -2 >> "$summary_file" 2>/dev/null
    fi
    
    # Installation type
    if [[ -f "${app_state_dir}/flatpak_config_locations.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Installation: Flatpak" >> "$summary_file"
    else
        echo "" >> "$summary_file"
        echo "Installation: System package" >> "$summary_file"
    fi
    
    log_success "Dolphin session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Dolphin pre-save hook..."
    
    if is_dolphin_running; then
        save_dolphin_session
        create_dolphin_summary
        log_success "Dolphin pre-save hook completed"
    else
        log_info "Dolphin not running - nothing to save"
    fi
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        pre_save_main
        ;;
    "post-restore")
        log_info "Dolphin post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac