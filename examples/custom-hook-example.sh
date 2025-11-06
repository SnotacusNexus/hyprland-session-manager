#!/usr/bin/env zsh

# 🎯 Custom Application Hook Example
# Template for adding support for new applications

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CUSTOM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CUSTOM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CUSTOM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[CUSTOM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if your application is running
is_app_running() {
    # Replace 'yourapp' with your application's process name
    if pgrep -x "yourapp" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get application window class (for Hyprland)
get_app_class() {
    # Replace 'yourapp' with your application's window class
    # Find this using: hyprctl clients | grep "class:"
    echo "yourapp"
}

# Save application session data
save_app_session() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/yourapp"
    
    log_info "Saving YourApp session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save application-specific session files
    # Example: Copy configuration or session files
    local app_config="${HOME}/.config/yourapp"
    if [[ -d "$app_config" ]]; then
        # Copy important session files
        find "$app_config" -name "*session*" -o -name "*state*" -o -name "*recent*" > "${app_state_dir}/config_files.txt" 2>/dev/null
        
        # Example: Backup specific files
        # cp "${app_config}/session.json" "${app_state_dir}/" 2>/dev/null || true
    fi
    
    # Save running processes related to your app
    pgrep -f "yourapp" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save environment information
    printenv | grep -i "yourapp" > "${app_state_dir}/environment.txt" 2>/dev/null
    
    log_success "YourApp session data saved"
}

# Create session summary
create_app_summary() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/yourapp"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating YourApp session summary..."
    
    echo "YourApp Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open windows: $window_count" >> "$summary_file"
    
    # Window titles
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles:" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    log_success "YourApp session summary created"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS  
# ============================================================================

# Restore application session data
restore_app_session() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/yourapp"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No YourApp session data to restore"
        return
    fi
    
    log_info "Restoring YourApp session..."
    
    # Restore application-specific session files
    # Example: Restore configuration or session files
    local app_config="${HOME}/.config/yourapp"
    if [[ -d "$app_config" ]]; then
        # Restore specific files if they exist
        # if [[ -f "${app_state_dir}/session.json" ]]; then
        #     cp "${app_state_dir}/session.json" "${app_config}/" 2>/dev/null || true
        # fi
        log_info "YourApp configuration directory found"
    fi
    
    # Launch application if not running
    if ! is_app_running; then
        log_info "YourApp not running - launching..."
        # Replace with your application's launch command
        # yourapp &
        log_success "YourApp launched"
    else
        log_info "YourApp already running"
    fi
    
    # Apply window layouts (this happens automatically via Hyprland)
    log_info "Window layouts will be restored by Hyprland"
    
    log_success "YourApp session restoration completed"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting YourApp pre-save hook..."
    
    if is_app_running; then
        save_app_session
        create_app_summary
        log_success "YourApp pre-save hook completed"
    else
        log_info "YourApp not running - nothing to save"
    fi
}

# Post-restore hook main function
post_restore_main() {
    log_info "Starting YourApp post-restore hook..."
    
    restore_app_session
    
    log_success "YourApp post-restore hook completed"
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
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac