#!/usr/bin/env zsh

# Terminator Terminal Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Terminator terminal session preservation

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
# PRE-SAVE HOOK FUNCTIONS
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

# Save Terminator session data
save_terminator_session() {
    local app_class="$(get_terminator_class)"
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    
    log_info "Saving Terminator terminal session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain terminal session info)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Terminator configuration and layouts
    local terminator_config="${HOME}/.config/terminator"
    
    if [[ -d "$terminator_config" ]]; then
        log_info "Found Terminator configuration directory"
        
        # Save main configuration file
        if [[ -f "${terminator_config}/config" ]]; then
            cp "${terminator_config}/config" "${app_state_dir}/terminator_config.backup" 2>/dev/null || true
            log_info "Saved Terminator configuration file"
        fi
        
        # Save layout files
        find "$terminator_config" -name "*.layout" > "${app_state_dir}/layout_files.txt" 2>/dev/null
        
        # Copy layout files to backup directory
        mkdir -p "${app_state_dir}/layouts"
        find "$terminator_config" -name "*.layout" -exec cp {} "${app_state_dir}/layouts/" \; 2>/dev/null || true
        
        # List available layouts from config
        if [[ -f "${terminator_config}/config" ]]; then
            grep -E "\[\[.*\]\]" "${terminator_config}/config" | sed 's/\[\[\(.*\)\]\]/\1/' > "${app_state_dir}/available_layouts.txt" 2>/dev/null
        fi
    else
        log_warning "No Terminator configuration directory found at ~/.config/terminator"
    fi
    
    # Try to get current layout information from running Terminator instances
    if is_terminator_running; then
        log_info "Attempting to capture current Terminator layout state..."
        
        # Use wmctrl to get window information (fallback if hyprctl not available)
        if command -v wmctrl > /dev/null; then
            wmctrl -l -x | grep -i terminator > "${app_state_dir}/wmctrl_windows.txt" 2>/dev/null
        fi
        
        # Try to get layout information from D-Bus (if available)
        if command -v dbus-send > /dev/null && command -v gdbus > /dev/null; then
            log_info "Checking for D-Bus methods to capture layout..."
            # Terminator doesn't have a standard D-Bus API for layout capture
        fi
    fi
    
    # Save process information
    pgrep -f "terminator" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Terminator terminal session data saved"
}

# Create Terminator session summary
create_terminator_summary() {
    local app_class="$(get_terminator_class)"
    local app_state_dir="${SESSION_STATE_DIR}/terminator"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Terminator terminal session summary..."
    
    echo "Terminator Terminal Session Summary - $(date)" > "$summary_file"
    echo "==============================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Terminator windows: $window_count" >> "$summary_file"
    
    # Window titles (terminal sessions)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (terminal sessions):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Layout information
    if [[ -f "${app_state_dir}/available_layouts.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Available layouts:" >> "$summary_file"
        cat "${app_state_dir}/available_layouts.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Layout files
    if [[ -f "${app_state_dir}/layout_files.txt" ]]; then
        local layout_count=$(wc -l < "${app_state_dir}/layout_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Layout files: $layout_count" >> "$summary_file"
    fi
    
    log_success "Terminator terminal session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Terminator terminal pre-save hook..."
    
    if is_terminator_running; then
        save_terminator_session
        create_terminator_summary
        log_success "Terminator terminal pre-save hook completed"
    else
        log_info "Terminator terminal not running - nothing to save"
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
        log_info "Terminator post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac