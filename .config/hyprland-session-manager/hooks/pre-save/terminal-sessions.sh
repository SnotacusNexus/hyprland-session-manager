#!/usr/bin/env zsh

# Terminal Session Management Hook
# Pre-save hook for Kitty, Terminator, Tmux session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TERMINAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TERMINAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TERMINAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Save Kitty terminal session information
save_kitty_session() {
    if pgrep -x "kitty" > /dev/null; then
        log_info "Kitty detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/kitty"
        
        # Extract terminal information from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "kitty") | .title' > "${SESSION_STATE_DIR}/kitty/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "kitty") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/kitty/positions.txt" 2>/dev/null
        
        # Kitty session management
        if command -v kitty > /dev/null; then
            # Save current kitty session
            kitty @ ls > "${SESSION_STATE_DIR}/kitty/current_sessions.json" 2>/dev/null
            
            # Save kitty layout
            kitty @ get-layout > "${SESSION_STATE_DIR}/kitty/layout.txt" 2>/dev/null
            
            # Save kitty window information
            kitty @ ls | jq '.[].tabs[].windows[] | {title, cwd, pid, command_line}' > "${SESSION_STATE_DIR}/kitty/window_details.json" 2>/dev/null
        fi
        
        log_success "Kitty session information saved"
    else
        log_info "Kitty not running"
    fi
}

# Save Terminator terminal session information
save_terminator_session() {
    if pgrep -x "terminator" > /dev/null; then
        log_info "Terminator detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/terminator"
        
        # Extract terminal information from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "terminator") | .title' > "${SESSION_STATE_DIR}/terminator/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "terminator") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/terminator/positions.txt" 2>/dev/null
        
        # Terminator configuration and layout
        local terminator_config="${HOME}/.config/terminator/config"
        if [[ -f "$terminator_config" ]]; then
            cp "$terminator_config" "${SESSION_STATE_DIR}/terminator/config.backup" 2>/dev/null
        fi
        
        # Terminator layouts directory
        local terminator_layouts="${HOME}/.config/terminator/layouts"
        if [[ -d "$terminator_layouts" ]]; then
            ls "$terminator_layouts" > "${SESSION_STATE_DIR}/terminator/available_layouts.txt" 2>/dev/null
        fi
        
        log_success "Terminator session information saved"
    else
        log_info "Terminator not running"
    fi
}

# Save Tmux session information
save_tmux_session() {
    if pgrep -x "tmux" > /dev/null; then
        log_info "Tmux detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/tmux"
        
        # Save current tmux sessions
        if command -v tmux > /dev/null; then
            tmux list-sessions > "${SESSION_STATE_DIR}/tmux/sessions.txt" 2>/dev/null
            
            # Save detailed session information
            tmux list-sessions -F '#{session_name}:#{session_attached}:#{session_windows}:#{session_created}' > "${SESSION_STATE_DIR}/tmux/session_details.txt" 2>/dev/null
            
            # Save window information for each session
            tmux list-sessions -F '#{session_name}' | while read session; do
                tmux list-windows -t "$session" -F "$session:#{window_index}:#{window_name}:#{window_active}:#{pane_current_command}" >> "${SESSION_STATE_DIR}/tmux/window_details.txt" 2>/dev/null
            done
            
            # Save tmux server information
            tmux info > "${SESSION_STATE_DIR}/tmux/server_info.txt" 2>/dev/null
        fi
        
        log_success "Tmux session information saved"
    else
        log_info "Tmux not running"
    fi
}

# Save shell history and environment
save_shell_environment() {
    log_info "Saving shell environment information..."
    
    mkdir -p "${SESSION_STATE_DIR}/shell"
    
    # Save current directory of terminal windows
    # This is challenging without direct process access
    # We'll save what we can from window titles
    
    # Save shell history timestamps (if available)
    if [[ -f "${HOME}/.zsh_history" ]]; then
        # Get last few history entries with timestamps
        tail -20 "${HOME}/.zsh_history" > "${SESSION_STATE_DIR}/shell/recent_history.txt" 2>/dev/null
    fi
    
    # Save environment variables that might be relevant
    printenv | grep -E "(PWD|OLDPWD|HOME|USER|SHELL|TERM|TMUX)" > "${SESSION_STATE_DIR}/shell/environment.txt" 2>/dev/null
    
    # Save current working directory
    pwd > "${SESSION_STATE_DIR}/shell/current_directory.txt" 2>/dev/null
    
    log_success "Shell environment information saved"
}

# Save running processes in terminals
save_terminal_processes() {
    log_info "Saving terminal process information..."
    
    # This is a best-effort approach to capture what's running in terminals
    
    # Save process tree for terminal applications
    pgrep -x "kitty" | while read pid; do
        pstree -p "$pid" > "${SESSION_STATE_DIR}/kitty/process_tree_${pid}.txt" 2>/dev/null
    done
    
    pgrep -x "terminator" | while read pid; do
        pstree -p "$pid" > "${SESSION_STATE_DIR}/terminator/process_tree_${pid}.txt" 2>/dev/null
    done
    
    # Save tmux processes
    pgrep -x "tmux" | while read pid; do
        pstree -p "$pid" > "${SESSION_STATE_DIR}/tmux/process_tree_${pid}.txt" 2>/dev/null
    done
    
    log_success "Terminal process information saved"
}

# Create terminal session summary
create_terminal_summary() {
    log_info "Creating terminal session summary..."
    
    local summary_file="${SESSION_STATE_DIR}/terminal_summary.txt"
    
    echo "Terminal Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Kitty info
    local kitty_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "kitty")] | length' 2>/dev/null)
    echo "Kitty: $kitty_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/kitty/current_sessions.json" ]]; then
        local kitty_tabs=$(jq '.[].tabs | length' "${SESSION_STATE_DIR}/kitty/current_sessions.json" 2>/dev/null | awk '{sum+=$1} END {print sum}')
        echo "  Tabs: $kitty_tabs" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    
    # Terminator info
    local terminator_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "terminator")] | length' 2>/dev/null)
    echo "Terminator: $terminator_windows windows" >> "$summary_file"
    
    echo "" >> "$summary_file"
    
    # Tmux info
    if [[ -f "${SESSION_STATE_DIR}/tmux/sessions.txt" ]]; then
        local tmux_sessions=$(wc -l < "${SESSION_STATE_DIR}/tmux/sessions.txt")
        echo "Tmux: $tmux_sessions sessions" >> "$summary_file"
        
        # List active sessions
        echo "Active sessions:" >> "$summary_file"
        grep "(attached)" "${SESSION_STATE_DIR}/tmux/sessions.txt" | head -3 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    else
        echo "Tmux: No active sessions" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    
    # Shell environment
    echo "Shell Environment:" >> "$summary_file"
    echo "  Current directory: $(cat "${SESSION_STATE_DIR}/shell/current_directory.txt" 2>/dev/null)" >> "$summary_file"
    
    log_success "Terminal session summary created"
}

# Main function
main() {
    log_info "Starting terminal session preservation..."
    
    # Save Kitty sessions
    save_kitty_session
    
    # Save Terminator sessions
    save_terminator_session
    
    # Save Tmux sessions
    save_tmux_session
    
    # Save shell environment
    save_shell_environment
    
    # Save terminal processes
    save_terminal_processes
    
    # Create summary
    create_terminal_summary
    
    log_success "Terminal session preservation completed"
}

# Execute main function
main "$@"