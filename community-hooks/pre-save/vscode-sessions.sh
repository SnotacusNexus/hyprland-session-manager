#!/usr/bin/env zsh

# VSCode Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for VSCode workspace and session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[VSCode HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if VSCode is running
is_vscode_running() {
    # Support multiple VSCode variants
    if pgrep -x "code" > /dev/null || \
       pgrep -x "vscode" > /dev/null || \
       pgrep -x "codium" > /dev/null || \
       pgrep -f "code.*--type=renderer" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get VSCode window class
get_vscode_class() {
    # VSCode can have different window classes depending on the distribution and variant
    local vscode_classes=("code" "Code" "vscode" "VSCode" "codium" "VSCodium")
    
    for class in "${vscode_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "code"
}

# Find VSCode configuration directories
find_vscode_configs() {
    local config_dirs=()
    
    # Official VSCode
    if [[ -d "${HOME}/.config/Code" ]]; then
        config_dirs+=("${HOME}/.config/Code")
    fi
    
    # VSCodium
    if [[ -d "${HOME}/.config/VSCodium" ]]; then
        config_dirs+=("${HOME}/.config/VSCodium")
    fi
    
    # Alternative locations
    if [[ -d "${HOME}/.vscode" ]]; then
        config_dirs+=("${HOME}/.vscode")
    fi
    
    echo "${config_dirs[@]}"
}

# Save VSCode workspace storage data
save_vscode_workspace_storage() {
    local app_state_dir="$1"
    local config_dirs=($(find_vscode_configs))
    
    log_info "Saving VSCode workspace storage data..."
    
    for config_dir in "${config_dirs[@]}"; do
        local workspace_storage="${config_dir}/User/workspaceStorage"
        
        if [[ -d "$workspace_storage" ]]; then
            log_info "Found workspace storage: $workspace_storage"
            
            # Save workspace storage directory structure
            find "$workspace_storage" -maxdepth 2 -type d -name "*.json" -o -name "state.vscdb" > "${app_state_dir}/workspace_storage_dirs.txt" 2>/dev/null
            
            # Save workspace state files
            find "$workspace_storage" -name "workspace.json" -o -name "state.vscdb" > "${app_state_dir}/workspace_state_files.txt" 2>/dev/null
            
            # Save recent workspace information
            if [[ -f "${config_dir}/User/state.vscdb" ]]; then
                cp "${config_dir}/User/state.vscdb" "${app_state_dir}/global_state.vscdb" 2>/dev/null || true
            fi
        else
            log_warning "No workspace storage found in $config_dir"
        fi
    done
}

# Save VSCode session data
save_vscode_session() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    log_info "Saving VSCode session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain project/folder names)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save VSCode configuration and session data
    save_vscode_workspace_storage "$app_state_dir"
    
    # Save global VSCode state
    local config_dirs=($(find_vscode_configs))
    for config_dir in "${config_dirs[@]}"; do
        local user_config="${config_dir}/User"
        
        if [[ -d "$user_config" ]]; then
            log_info "Processing VSCode config: $user_config"
            
            # Save global state
            if [[ -f "${user_config}/state.vscdb" ]]; then
                cp "${user_config}/state.vscdb" "${app_state_dir}/$(basename "$config_dir")_state.vscdb" 2>/dev/null || true
            fi
            
            # Save workspace trust settings
            if [[ -f "${user_config}/workspaceStorage/trust.json" ]]; then
                cp "${user_config}/workspaceStorage/trust.json" "${app_state_dir}/$(basename "$config_dir")_trust.json" 2>/dev/null || true
            fi
            
            # Save recent files and workspaces
            if [[ -f "${user_config}/globalStorage/storage.json" ]]; then
                cp "${user_config}/globalStorage/storage.json" "${app_state_dir}/$(basename "$config_dir")_storage.json" 2>/dev/null || true
            fi
        fi
    done
    
    # Save process information
    pgrep -f "code\|vscode\|codium" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save VSCode variant information
    local vscode_variant="unknown"
    if command -v code > /dev/null; then
        vscode_variant="code"
    elif command -v codium > /dev/null; then
        vscode_variant="codium"
    elif command -v vscode > /dev/null; then
        vscode_variant="vscode"
    fi
    echo "$vscode_variant" > "${app_state_dir}/vscode_variant.txt"
    
    log_success "VSCode session data saved"
}

# Create VSCode session summary
create_vscode_summary() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating VSCode session summary..."
    
    echo "VSCode Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open VSCode windows: $window_count" >> "$summary_file"
    
    # Window titles (project/folder information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (projects):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # VSCode variant
    if [[ -f "${app_state_dir}/vscode_variant.txt" ]]; then
        echo "" >> "$summary_file"
        echo "VSCode variant: $(cat "${app_state_dir}/vscode_variant.txt")" >> "$summary_file"
    fi
    
    # Workspace storage information
    if [[ -f "${app_state_dir}/workspace_state_files.txt" ]]; then
        local workspace_count=$(wc -l < "${app_state_dir}/workspace_state_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Workspace state files: $workspace_count" >> "$summary_file"
    fi
    
    # Configuration directories found
    local config_dirs=($(find_vscode_configs))
    if [[ ${#config_dirs[@]} -gt 0 ]]; then
        echo "" >> "$summary_file"
        echo "Configuration directories:" >> "$summary_file"
        for dir in "${config_dirs[@]}"; do
            echo "  - $(basename "$dir")" >> "$summary_file"
        done
    fi
    
    log_success "VSCode session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting VSCode pre-save hook..."
    
    if is_vscode_running; then
        save_vscode_session
        create_vscode_summary
        log_success "VSCode pre-save hook completed"
    else
        log_info "VSCode not running - nothing to save"
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
        log_info "VSCode post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac