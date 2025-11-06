#!/usr/bin/env zsh

# IDE Session Management Hook
# Pre-save hook for VSCode and Void IDE session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[IDE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Save VSCode workspace and session information
save_vscode_session() {
    if pgrep -x "code" > /dev/null; then
        log_info "VSCode detected - saving workspace information"
        
        mkdir -p "${SESSION_STATE_DIR}/vscode"
        
        # Extract open files and projects from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "code") | .title' > "${SESSION_STATE_DIR}/vscode/window_titles.txt" 2>/dev/null
        
        # Save VSCode workspace storage
        local vscode_storage="${HOME}/.config/Code/User/workspaceStorage"
        if [[ -d "$vscode_storage" ]]; then
            # List workspace folders
            find "$vscode_storage" -name "workspace.json" -exec dirname {} \; > "${SESSION_STATE_DIR}/vscode/workspace_folders.txt" 2>/dev/null
        fi
        
        # Save VSCode state (if accessible)
        local vscode_state="${HOME}/.config/Code/User/globalStorage/state.vscdb"
        if [[ -f "$vscode_state" ]]; then
            cp "$vscode_state" "${SESSION_STATE_DIR}/vscode/state.vscdb.backup" 2>/dev/null
        fi
        
        # Save recent projects
        local vscode_recent="${HOME}/.config/Code/User/globalStorage/storage.json"
        if [[ -f "$vscode_recent" ]]; then
            cp "$vscode_recent" "${SESSION_STATE_DIR}/vscode/storage.json.backup" 2>/dev/null
        fi
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "code") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/vscode/positions.txt" 2>/dev/null
        
        log_success "VSCode session information saved"
    else
        log_info "VSCode not running"
    fi
}

# Save Void IDE session information
save_void_session() {
    if pgrep -x "void" > /dev/null; then
        log_info "Void IDE detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/void"
        
        # Extract open files and projects from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "void") | .title' > "${SESSION_STATE_DIR}/void/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "void") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/void/positions.txt" 2>/dev/null
        
        # Void IDE might have its own session files
        local void_config="${HOME}/.config/void"
        if [[ -d "$void_config" ]]; then
            # Look for session or state files
            find "$void_config" -name "*session*" -o -name "*state*" -o -name "*workspace*" > "${SESSION_STATE_DIR}/void/config_files.txt" 2>/dev/null
        fi
        
        log_success "Void IDE session information saved"
    else
        log_info "Void IDE not running"
    fi
}

# Save general development environment state
save_dev_environment() {
    log_info "Saving development environment state..."
    
    mkdir -p "${SESSION_STATE_DIR}/development"
    
    # Save current git repositories (if any terminal has git repos open)
    if command -v git > /dev/null; then
        # This is a basic approach - could be enhanced
        find /home/SnotacusNexus/git -name ".git" -type d 2>/dev/null | head -10 > "${SESSION_STATE_DIR}/development/git_repos.txt"
    fi
    
    # Save terminal sessions that might be development-related
    hyprctl clients -j | jq -r '.[] | select(.class | test("(kitty|terminator|alacritty)")) | "\(.class):\(.title)"' > "${SESSION_STATE_DIR}/development/terminal_sessions.txt" 2>/dev/null
    
    # Save any running development servers
    pgrep -f "node\|python\|ruby\|java\|go" > "${SESSION_STATE_DIR}/development/running_servers.txt" 2>/dev/null
    
    log_success "Development environment state saved"
}

# Create IDE session summary
create_ide_summary() {
    log_info "Creating IDE session summary..."
    
    local summary_file="${SESSION_STATE_DIR}/ide_summary.txt"
    
    echo "IDE Session Summary - $(date)" > "$summary_file"
    echo "============================" >> "$summary_file"
    
    # VSCode info
    local vscode_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "code")] | length' 2>/dev/null)
    echo "VSCode: $vscode_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/vscode/window_titles.txt" ]]; then
        echo "Open projects:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/vscode/window_titles.txt" | head -5 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # Void IDE info
    local void_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "void")] | length' 2>/dev/null)
    echo "Void IDE: $void_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/void/window_titles.txt" ]]; then
        echo "Open projects:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/void/window_titles.txt" | head -5 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # Development environment
    echo "Development Environment:" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/development/git_repos.txt" ]]; then
        local repo_count=$(wc -l < "${SESSION_STATE_DIR}/development/git_repos.txt")
        echo "  Git repositories: $repo_count" >> "$summary_file"
    fi
    
    if [[ -f "${SESSION_STATE_DIR}/development/running_servers.txt" ]]; then
        local server_count=$(wc -l < "${SESSION_STATE_DIR}/development/running_servers.txt")
        echo "  Running servers: $server_count" >> "$summary_file"
    fi
    
    log_success "IDE session summary created"
}

# Main function
main() {
    log_info "Starting IDE session preservation..."
    
    # Save VSCode sessions
    save_vscode_session
    
    # Save Void IDE sessions
    save_void_session
    
    # Save development environment
    save_dev_environment
    
    # Create summary
    create_ide_summary
    
    log_success "IDE session preservation completed"
}

# Execute main function
main "$@"