#!/usr/bin/env zsh

# Void IDE Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Void IDE workspace preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[VOID IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Void IDE is running
is_void_running() {
    if pgrep -x "void" > /dev/null || pgrep -f "Void" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Void IDE window class
get_void_class() {
    # Void IDE window classes
    local void_classes=("void" "Void" "void-ide")
    
    for class in "${void_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "void"
}

# Save Void IDE session data
save_void_session() {
    local app_class="$(get_void_class)"
    local app_state_dir="${SESSION_STATE_DIR}/void"
    
    log_info "Saving Void IDE session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain project/workspace information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Void IDE configuration and workspace data
    local void_config="${HOME}/.config/Void"
    
    if [[ -d "$void_config" ]]; then
        log_info "Found Void IDE configuration directory"
        
        # Save workspace storage information
        local workspace_storage="${void_config}/User/workspaceStorage"
        if [[ -d "$workspace_storage" ]]; then
            log_info "Found Void IDE workspace storage"
            
            # List workspace directories
            find "$workspace_storage" -maxdepth 1 -type d -name "*" > "${app_state_dir}/workspace_dirs.txt" 2>/dev/null
            
            # Save workspace metadata
            find "$workspace_storage" -name "workspace.json" -o -name "state.vscdb" > "${app_state_dir}/workspace_files.txt" 2>/dev/null
            
            # Create backup of workspace state files
            mkdir -p "${app_state_dir}/workspace_backup"
            find "$workspace_storage" -name "workspace.json" -o -name "state.vscdb" | head -10 | while read -r file; do
                local dir_name=$(basename "$(dirname "$file")")
                mkdir -p "${app_state_dir}/workspace_backup/${dir_name}"
                cp "$file" "${app_state_dir}/workspace_backup/${dir_name}/" 2>/dev/null || true
            done
        fi
        
        # Save global storage
        local global_storage="${void_config}/User/globalStorage"
        if [[ -d "$global_storage" ]]; then
            log_info "Found Void IDE global storage"
            find "$global_storage" -name "storage.json" -o -name "state.vscdb" > "${app_state_dir}/global_storage_files.txt" 2>/dev/null
        fi
        
        # Save user settings
        local user_settings="${void_config}/User/settings.json"
        if [[ -f "$user_settings" ]]; then
            cp "$user_settings" "${app_state_dir}/user_settings.json.backup" 2>/dev/null || true
            log_info "Saved Void IDE user settings"
        fi
        
        # Save keybindings
        local keybindings="${void_config}/User/keybindings.json"
        if [[ -f "$keybindings" ]]; then
            cp "$keybindings" "${app_state_dir}/keybindings.json.backup" 2>/dev/null || true
            log_info "Saved Void IDE keybindings"
        fi
        
        # Save snippets if they exist
        local snippets_dir="${void_config}/User/snippets"
        if [[ -d "$snippets_dir" ]]; then
            find "$snippets_dir" -name "*.json" > "${app_state_dir}/snippet_files.txt" 2>/dev/null
        fi
    else
        log_warning "No Void IDE configuration directory found at ~/.config/Void"
    fi
    
    # Save process information
    pgrep -f "void" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Void IDE session data saved"
}

# Create Void IDE session summary
create_void_summary() {
    local app_class="$(get_void_class)"
    local app_state_dir="${SESSION_STATE_DIR}/void"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Void IDE session summary..."
    
    echo "Void IDE Session Summary - $(date)" > "$summary_file"
    echo "==================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Void IDE windows: $window_count" >> "$summary_file"
    
    # Window titles (project/workspace information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (projects/workspaces):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace information
    if [[ -f "${app_state_dir}/workspace_dirs.txt" ]]; then
        local workspace_count=$(wc -l < "${app_state_dir}/workspace_dirs.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Workspace directories: $workspace_count" >> "$summary_file"
    fi
    
    if [[ -f "${app_state_dir}/workspace_files.txt" ]]; then
        local workspace_files=$(wc -l < "${app_state_dir}/workspace_files.txt" 2>/dev/null || echo "0")
        echo "Workspace state files: $workspace_files" >> "$summary_file"
    fi
    
    # Configuration information
    if [[ -f "${app_state_dir}/user_settings.json.backup" ]]; then
        echo "" >> "$summary_file"
        echo "User settings: backed up" >> "$summary_file"
    fi
    
    if [[ -f "${app_state_dir}/keybindings.json.backup" ]]; then
        echo "Keybindings: backed up" >> "$summary_file"
    fi
    
    log_success "Void IDE session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Void IDE pre-save hook..."
    
    if is_void_running; then
        save_void_session
        create_void_summary
        log_success "Void IDE pre-save hook completed"
    else
        log_info "Void IDE not running - nothing to save"
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
        log_info "Void IDE post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac