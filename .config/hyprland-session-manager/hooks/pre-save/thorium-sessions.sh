#!/usr/bin/env zsh

# Thorium Browser Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Thorium browser session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[THORIUM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Thorium is running
is_thorium_running() {
    if pgrep -x "thorium" > /dev/null || pgrep -f "thorium-browser" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Thorium window class
get_thorium_class() {
    # Thorium can have different window classes
    local thorium_classes=("thorium-browser" "Thorium" "thorium")
    
    for class in "${thorium_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "thorium-browser"
}

# Save Thorium session data
save_thorium_session() {
    local app_class="$(get_thorium_class)"
    local app_state_dir="${SESSION_STATE_DIR}/thorium"
    
    log_info "Saving Thorium browser session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain tab information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Thorium profile information
    local thorium_config="${HOME}/.config/thorium"
    
    if [[ -d "$thorium_config" ]]; then
        log_info "Found Thorium configuration directory"
        
        # Save session files from Default profile
        local default_profile="${thorium_config}/Default"
        if [[ -d "$default_profile" ]]; then
            # Save session files
            find "$default_profile" -name "Session Storage" -type d > "${app_state_dir}/session_storage_dirs.txt" 2>/dev/null
            find "$default_profile" -name "Last Session" -o -name "Current Session" -o -name "Last Tabs" > "${app_state_dir}/session_files.txt" 2>/dev/null
            
            # Save important session-related files
            local session_files=(
                "Session Storage"
                "Local Storage"
                "Preferences"
                "History"
                "Bookmarks"
                "Cookies"
            )
            
            for file in "${session_files[@]}"; do
                if [[ -e "${default_profile}/${file}" ]]; then
                    echo "${default_profile}/${file}" >> "${app_state_dir}/config_files.txt" 2>/dev/null
                fi
            done
            
            # Create a backup of critical session files
            mkdir -p "${app_state_dir}/backup"
            if [[ -f "${default_profile}/Preferences" ]]; then
                cp "${default_profile}/Preferences" "${app_state_dir}/backup/" 2>/dev/null || true
            fi
        fi
        
        # List all profiles
        find "$thorium_config" -name "Local State" -path "*/Default/*" -o -path "*/Profile */Local State" > "${app_state_dir}/thorium_profiles.txt" 2>/dev/null
    else
        log_warning "No Thorium configuration directory found at ~/.config/thorium"
    fi
    
    # Save process information
    pgrep -f "thorium" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Thorium browser session data saved"
}

# Create Thorium session summary
create_thorium_summary() {
    local app_class="$(get_thorium_class)"
    local app_state_dir="${SESSION_STATE_DIR}/thorium"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Thorium browser session summary..."
    
    echo "Thorium Browser Session Summary - $(date)" > "$summary_file"
    echo "==========================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Thorium windows: $window_count" >> "$summary_file"
    
    # Window titles (tab information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (tabs):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Profile information
    if [[ -f "${app_state_dir}/thorium_profiles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Available profiles:" >> "$summary_file"
        local profile_count=$(wc -l < "${app_state_dir}/thorium_profiles.txt" 2>/dev/null || echo "0")
        echo "  $profile_count profiles found" >> "$summary_file"
    fi
    
    log_success "Thorium browser session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Thorium browser pre-save hook..."
    
    if is_thorium_running; then
        save_thorium_session
        create_thorium_summary
        log_success "Thorium browser pre-save hook completed"
    else
        log_info "Thorium browser not running - nothing to save"
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
        log_info "Thorium post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac