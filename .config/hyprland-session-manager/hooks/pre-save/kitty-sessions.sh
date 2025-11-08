#!/usr/bin/env zsh

# Kitty Terminal Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Kitty terminal session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[KITTY HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Kitty is running
is_kitty_running() {
    if pgrep -x "kitty" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Kitty window class
get_kitty_class() {
    # Kitty terminal window class
    echo "kitty"
}

# Save Kitty session data using kitty @ ls command
save_kitty_session() {
    local app_class="$(get_kitty_class)"
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    
    log_info "Saving Kitty terminal session data..."
    
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
    
    # Save Kitty session state using kitty @ ls command
    if command -v kitty > /dev/null; then
        log_info "Saving Kitty session state using kitty @ ls..."
        
        # Get current Kitty session state
        kitty @ ls > "${app_state_dir}/kitty_session_state.json" 2>/dev/null
        
        # Save individual window layouts
        kitty @ ls | jq -r '.[] | .tabs[] | .windows[] | "\(.id):\(.title):\(.cwd)"' > "${app_state_dir}/kitty_windows.txt" 2>/dev/null
        
        # Save tab information
        kitty @ ls | jq -r '.[] | .tabs[] | "\(.id):\(.title):\(.windows | length)"' > "${app_state_dir}/kitty_tabs.txt" 2>/dev/null
        
        # Save OS window information
        kitty @ ls | jq -r '.[] | "\(.id):\(.platform_window_id):\(.is_focused)"' > "${app_state_dir}/kitty_os_windows.txt" 2>/dev/null
    else
        log_warning "Kitty command not found - cannot save session state"
    fi
    
    # Save Kitty configuration
    local kitty_config="${HOME}/.config/kitty"
    if [[ -d "$kitty_config" ]]; then
        log_info "Found Kitty configuration directory"
        
        # Save kitty.conf if it exists
        if [[ -f "${kitty_config}/kitty.conf" ]]; then
            cp "${kitty_config}/kitty.conf" "${app_state_dir}/kitty.conf.backup" 2>/dev/null || true
        fi
        
        # Save session files if they exist
        find "$kitty_config" -name "*.session" -o -name "*.conf" > "${app_state_dir}/kitty_config_files.txt" 2>/dev/null
    fi
    
    # Save process information
    pgrep -f "kitty" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Kitty terminal session data saved"
}

# Create Kitty session summary
create_kitty_summary() {
    local app_class="$(get_kitty_class)"
    local app_state_dir="${SESSION_STATE_DIR}/kitty"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Kitty terminal session summary..."
    
    echo "Kitty Terminal Session Summary - $(date)" > "$summary_file"
    echo "==========================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Kitty windows: $window_count" >> "$summary_file"
    
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
    
    # Kitty session state information
    if [[ -f "${app_state_dir}/kitty_session_state.json" ]]; then
        echo "" >> "$summary_file"
        echo "Kitty session state:" >> "$summary_file"
        
        # Count OS windows
        local os_windows=$(jq -r 'length' "${app_state_dir}/kitty_session_state.json" 2>/dev/null || echo "0")
        echo "  OS Windows: $os_windows" >> "$summary_file"
        
        # Count tabs
        local total_tabs=0
        if command -v jq > /dev/null; then
            total_tabs=$(jq -r '[.[] | .tabs | length] | add' "${app_state_dir}/kitty_session_state.json" 2>/dev/null || echo "0")
        fi
        echo "  Total tabs: $total_tabs" >> "$summary_file"
        
        # Count windows
        local total_windows=0
        if command -v jq > /dev/null; then
            total_windows=$(jq -r '[.[] | .tabs[] | .windows | length] | add' "${app_state_dir}/kitty_session_state.json" 2>/dev/null || echo "0")
        fi
        echo "  Total windows: $total_windows" >> "$summary_file"
    fi
    
    log_success "Kitty terminal session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Kitty terminal pre-save hook..."
    
    if is_kitty_running; then
        save_kitty_session
        create_kitty_summary
        log_success "Kitty terminal pre-save hook completed"
    else
        log_info "Kitty terminal not running - nothing to save"
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
        log_info "Kitty post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac