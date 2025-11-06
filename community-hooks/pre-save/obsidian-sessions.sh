#!/usr/bin/env zsh

# Obsidian Session Management Hook
# Community contributed by: [Your GitHub Username]
# Pre-save hook for Obsidian vault session preservation

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

# Save Obsidian session data
save_obsidian_session() {
    local app_class="$(get_obsidian_class)"
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    
    log_info "Saving Obsidian session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which often contain vault names)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Obsidian workspace information
    local obsidian_config="${HOME}/.config/obsidian"
    if [[ -d "$obsidian_config" ]]; then
        # List available vaults and workspaces
        find "$obsidian_config" -name "*.json" -path "*/workspace.json" > "${app_state_dir}/vault_workspaces.txt" 2>/dev/null
        
        # Save recent vaults information
        if [[ -f "${obsidian_config}/obsidian.json" ]]; then
            grep -i "vault\|workspace\|recent" "${obsidian_config}/obsidian.json" > "${app_state_dir}/recent_vaults.txt" 2>/dev/null
        fi
    fi
    
    # Save open note information from window titles
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        # Extract note names from window titles
        cat "${app_state_dir}/window_titles.txt" | grep -o "\[.*\]" > "${app_state_dir}/open_notes.txt" 2>/dev/null
    fi
    
    log_success "Obsidian session data saved"
}

# Create Obsidian session summary
create_obsidian_summary() {
    local app_class="$(get_obsidian_class)"
    local app_state_dir="${SESSION_STATE_DIR}/obsidian"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Obsidian session summary..."
    
    echo "Obsidian Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Obsidian windows: $window_count" >> "$summary_file"
    
    # Window titles
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles:" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -5 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Open notes
    if [[ -f "${app_state_dir}/open_notes.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Detected open notes:" >> "$summary_file"
        cat "${app_state_dir}/open_notes.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    log_success "Obsidian session summary created"
}

# Main function
main() {
    log_info "Starting Obsidian pre-save hook..."
    
    if is_obsidian_running; then
        save_obsidian_session
        create_obsidian_summary
        log_success "Obsidian pre-save hook completed"
    else
        log_info "Obsidian not running - nothing to save"
    fi
}

# Execute main function
main "$@"