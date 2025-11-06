#!/usr/bin/env zsh

# IDE Session Restoration Hook
# Post-restore hook for VSCode and Void IDE session recovery

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[IDE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[IDE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[IDE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Restore VSCode workspace and session information
restore_vscode_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/vscode" ]]; then
        log_warning "No saved VSCode session data found"
        return 1
    fi
    
    log_info "Attempting VSCode session restoration..."
    
    # Wait for VSCode to be ready
    sleep 3
    
    # Focus VSCode windows to trigger workspace loading
    if [[ -f "${SESSION_STATE_DIR}/vscode/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing VSCode window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/vscode/positions.txt"
    fi
    
    # VSCode should auto-restore workspaces and files
    # We can enhance this by opening specific projects if we have the paths
    
    log_success "VSCode session restoration attempted"
}

# Restore Void IDE session information
restore_void_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/void" ]]; then
        log_warning "No saved Void IDE session data found"
        return 1
    fi
    
    log_info "Attempting Void IDE session restoration..."
    
    # Wait for Void IDE to be ready
    sleep 3
    
    # Focus Void IDE windows
    if [[ -f "${SESSION_STATE_DIR}/void/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Void IDE window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/void/positions.txt"
    fi
    
    log_success "Void IDE session restoration attempted"
}

# Restore development environment
restore_dev_environment() {
    log_info "Restoring development environment context..."
    
    # This is informational - actual restoration happens through IDE sessions
    if [[ -f "${SESSION_STATE_DIR}/development/git_repos.txt" ]]; then
        log_info "Previously active git repositories:"
        cat "${SESSION_STATE_DIR}/development/git_repos.txt" | head -3 | while read repo; do
            log_info "  - $(basename "$(dirname "$repo")")"
        done
    fi
    
    log_success "Development environment context restored"
}

# Open specific projects based on saved information
open_saved_projects() {
    log_info "Opening saved projects..."
    
    local opened_count=0
    
    # Open VSCode projects from saved titles
    if [[ -f "${SESSION_STATE_DIR}/vscode/window_titles.txt" ]]; then
        while read -r title; do
            # Extract project paths from VSCode window titles
            # VSCode titles often contain file paths
            if [[ "$title" =~ "/" ]]; then
                local project_dir=$(echo "$title" | grep -o '/[^ ]*' | head -1)
                if [[ -n "$project_dir" && -d "$project_dir" ]]; then
                    log_info "Opening VSCode project: $project_dir"
                    nohup code "$project_dir" > /dev/null 2>&1 &
                    ((opened_count++))
                    sleep 2
                fi
            fi
        done < "${SESSION_STATE_DIR}/vscode/window_titles.txt"
    fi
    
    # Similar approach for Void IDE
    if [[ -f "${SESSION_STATE_DIR}/void/window_titles.txt" ]]; then
        while read -r title; do
            if [[ "$title" =~ "/" ]]; then
                local project_dir=$(echo "$title" | grep -o '/[^ ]*' | head -1)
                if [[ -n "$project_dir" && -d "$project_dir" ]]; then
                    log_info "Opening Void IDE project: $project_dir"
                    nohup void "$project_dir" > /dev/null 2>&1 &
                    ((opened_count++))
                    sleep 2
                fi
            fi
        done < "${SESSION_STATE_DIR}/void/window_titles.txt"
    fi
    
    if [[ $opened_count -gt 0 ]]; then
        log_success "Opened $opened_count projects"
    else
        log_info "No specific projects to open"
    fi
}

# Validate IDE restoration
validate_ide_restoration() {
    log_info "Validating IDE restoration..."
    
    local vscode_count=$(hyprctl clients -j | jq '[.[] | select(.class == "code")] | length' 2>/dev/null)
    local void_count=$(hyprctl clients -j | jq '[.[] | select(.class == "void")] | length' 2>/dev/null)
    
    local total_ides=$((vscode_count + void_count))
    
    if [[ -n "$total_ides" && "$total_ides" -gt 0 ]]; then
        log_success "IDE restoration successful - $total_ides IDE windows open"
        if [[ -n "$vscode_count" && "$vscode_count" -gt 0 ]]; then
            log_info "  VSCode: $vscode_count windows"
        fi
        if [[ -n "$void_count" && "$void_count" -gt 0 ]]; then
            log_info "  Void IDE: $void_count windows"
        fi
        return 0
    else
        log_warning "No IDE windows detected after restoration"
        return 1
    fi
}

# Send IDE restoration notification
send_ide_notification() {
    log_info "Sending IDE restoration notification..."
    
    if command -v notify-send > /dev/null; then
        local vscode_count=$(hyprctl clients -j | jq '[.[] | select(.class == "code")] | length' 2>/dev/null)
        local void_count=$(hyprctl clients -j | jq '[.[] | select(.class == "void")] | length' 2>/dev/null)
        
        local message="Development environments restored"
        if [[ -n "$vscode_count" && "$vscode_count" -gt 0 ]]; then
            message="$message\nVSCode: $vscode_count windows"
        fi
        if [[ -n "$void_count" && "$void_count" -gt 0 ]]; then
            message="$message\nVoid IDE: $void_count windows"
        fi
        
        notify-send "IDE Session Restored" "$message" -t 5000
    fi
}

# Main function
main() {
    log_info "Starting IDE session restoration..."
    
    # Wait for applications to stabilize
    sleep 3
    
    # Restore VSCode sessions
    restore_vscode_session
    
    # Restore Void IDE sessions
    restore_void_session
    
    # Additional wait for IDE loading
    sleep 2
    
    # Open specific projects
    open_saved_projects
    
    # Restore development environment context
    restore_dev_environment
    
    # Validate restoration
    validate_ide_restoration
    
    # Send notification
    send_ide_notification
    
    log_success "IDE session restoration completed"
}

# Execute main function
main "$@"