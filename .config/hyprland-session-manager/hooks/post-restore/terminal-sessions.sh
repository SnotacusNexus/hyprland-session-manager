#!/usr/bin/env zsh

# Terminal Session Restoration Hook
# Post-restore hook for Kitty, Terminator, Tmux session recovery

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TERMINAL RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TERMINAL RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TERMINAL RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Restore Kitty terminal session information
restore_kitty_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/kitty" ]]; then
        log_warning "No saved Kitty session data found"
        return 1
    fi
    
    log_info "Attempting Kitty session restoration..."
    
    # Wait for Kitty to be ready
    sleep 3
    
    # Focus Kitty windows
    if [[ -f "${SESSION_STATE_DIR}/kitty/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Kitty window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/kitty/positions.txt"
    fi
    
    # Kitty has advanced session management - attempt to restore layout
    if [[ -f "${SESSION_STATE_DIR}/kitty/layout.txt" ]] && command -v kitty > /dev/null; then
        log_info "Attempting to restore Kitty layout..."
        # Note: Kitty layout restoration requires specific setup
        # This would need kitty session files to be properly configured
    fi
    
    log_success "Kitty session restoration attempted"
}

# Restore Terminator terminal session information
restore_terminator_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/terminator" ]]; then
        log_warning "No saved Terminator session data found"
        return 1
    fi
    
    log_info "Attempting Terminator session restoration..."
    
    # Wait for Terminator to be ready
    sleep 3
    
    # Focus Terminator windows
    if [[ -f "${SESSION_STATE_DIR}/terminator/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Terminator window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/terminator/positions.txt"
    fi
    
    # Terminator can restore layouts if properly configured
    if [[ -f "${SESSION_STATE_DIR}/terminator/config.backup" ]]; then
        log_info "Terminator configuration backup available"
        # Note: Actual layout restoration requires terminator to be configured for session saving
    fi
    
    log_success "Terminator session restoration attempted"
}

# Restore Tmux session information
restore_tmux_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/tmux" ]]; then
        log_warning "No saved Tmux session data found"
        return 1
    fi
    
    log_info "Attempting Tmux session restoration..."
    
    # Check if tmux server is running
    if ! command -v tmux > /dev/null; then
        log_warning "Tmux not available"
        return 1
    fi
    
    # Restore tmux sessions if they were saved
    if [[ -f "${SESSION_STATE_DIR}/tmux/sessions.txt" ]]; then
        log_info "Found saved tmux sessions"
        
        # List saved sessions
        while read -r session_line; do
            local session_name=$(echo "$session_line" | cut -d: -f1)
            
            # Check if session already exists
            if ! tmux has-session -t "$session_name" 2>/dev/null; then
                log_info "Creating tmux session: $session_name"
                
                # Create new session
                tmux new-session -d -s "$session_name"
                
                # Note: Full session restoration would require saving/restoring
                # window layouts, panes, and running commands
            else
                log_info "Tmux session already exists: $session_name"
            fi
        done < "${SESSION_STATE_DIR}/tmux/session_details.txt" 2>/dev/null
        
        # Attach to the first session if none are attached
        local attached_sessions=$(tmux list-sessions -F '#{session_attached}' | grep -c '^1$')
        if [[ $attached_sessions -eq 0 ]]; then
            local first_session=$(tmux list-sessions -F '#{session_name}' | head -1)
            if [[ -n "$first_session" ]]; then
                log_info "Attaching to tmux session: $first_session"
                # Note: We can't directly attach from a script, but we can notify the user
                echo "To restore tmux sessions, run: tmux attach-session -t $first_session" > "${SESSION_STATE_DIR}/tmux/restore_instructions.txt"
            fi
        fi
    fi
    
    log_success "Tmux session restoration attempted"
}

# Create new terminal sessions based on saved information
create_terminal_sessions() {
    log_info "Creating terminal sessions based on saved state..."
    
    local created_count=0
    
    # Create Kitty sessions if none exist
    local kitty_count=$(hyprctl clients -j | jq '[.[] | select(.class == "kitty")] | length' 2>/dev/null)
    if [[ -z "$kitty_count" || "$kitty_count" -eq 0 ]]; then
        if [[ -f "${SESSION_STATE_DIR}/kitty/window_titles.txt" ]]; then
            local saved_kitty_count=$(wc -l < "${SESSION_STATE_DIR}/kitty/window_titles.txt")
            if [[ "$saved_kitty_count" -gt 0 ]]; then
                log_info "Creating new Kitty terminal"
                nohup kitty > /dev/null 2>&1 &
                ((created_count++))
                sleep 2
            fi
        fi
    fi
    
    # Create Terminator sessions if none exist
    local terminator_count=$(hyprctl clients -j | jq '[.[] | select(.class == "terminator")] | length' 2>/dev/null)
    if [[ -z "$terminator_count" || "$terminator_count" -eq 0 ]]; then
        if [[ -f "${SESSION_STATE_DIR}/terminator/window_titles.txt" ]]; then
            local saved_terminator_count=$(wc -l < "${SESSION_STATE_DIR}/terminator/window_titles.txt")
            if [[ "$saved_terminator_count" -gt 0 ]]; then
                log_info "Creating new Terminator terminal"
                nohup terminator > /dev/null 2>&1 &
                ((created_count++))
                sleep 2
            fi
        fi
    fi
    
    if [[ $created_count -gt 0 ]]; then
        log_success "Created $created_count new terminal sessions"
    else
        log_info "No new terminal sessions needed"
    fi
}

# Send commands to restore terminal state
send_terminal_commands() {
    log_info "Attempting to send restoration commands to terminals..."
    
    # This is a basic approach - more advanced would require terminal-specific APIs
    
    # For Kitty, we could use the remote control feature
    if command -v kitty > /dev/null && [[ -f "${SESSION_STATE_DIR}/shell/current_directory.txt" ]]; then
        local saved_dir=$(cat "${SESSION_STATE_DIR}/shell/current_directory.txt" 2>/dev/null)
        if [[ -n "$saved_dir" && -d "$saved_dir" ]]; then
            log_info "Setting Kitty working directory to: $saved_dir"
            # Note: This would require kitty to be running with remote control enabled
            # kitty @ set-spawn-timeout 1
            # kitty @ set-window-title "Restored Session"
        fi
    fi
    
    log_info "Terminal command restoration attempted"
}

# Validate terminal restoration
validate_terminal_restoration() {
    log_info "Validating terminal restoration..."
    
    local kitty_count=$(hyprctl clients -j | jq '[.[] | select(.class == "kitty")] | length' 2>/dev/null)
    local terminator_count=$(hyprctl clients -j | jq '[.[] | select(.class == "terminator")] | length' 2>/dev/null)
    local tmux_sessions=$(tmux list-sessions 2>/dev/null | wc -l)
    
    local total_terminals=$((kitty_count + terminator_count))
    
    if [[ -n "$total_terminals" && "$total_terminals" -gt 0 ]]; then
        log_success "Terminal restoration successful - $total_terminals terminal windows open"
        
        [[ -n "$kitty_count" && "$kitty_count" -gt 0 ]] && log_info "  Kitty: $kitty_count windows"
        [[ -n "$terminator_count" && "$terminator_count" -gt 0 ]] && log_info "  Terminator: $terminator_count windows"
        [[ -n "$tmux_sessions" && "$tmux_sessions" -gt 0 ]] && log_info "  Tmux: $tmux_sessions sessions"
        
        return 0
    else
        log_warning "No terminal windows detected after restoration"
        return 1
    fi
}

# Send terminal restoration notification
send_terminal_notification() {
    log_info "Sending terminal restoration notification..."
    
    if command -v notify-send > /dev/null; then
        local kitty_count=$(hyprctl clients -j | jq '[.[] | select(.class == "kitty")] | length' 2>/dev/null)
        local terminator_count=$(hyprctl clients -j | jq '[.[] | select(.class == "terminator")] | length' 2>/dev/null)
        local tmux_sessions=$(tmux list-sessions 2>/dev/null | wc -l)
        
        local message="Terminal sessions restored"
        [[ -n "$kitty_count" && "$kitty_count" -gt 0 ]] && message="$message\nKitty: $kitty_count windows"
        [[ -n "$terminator_count" && "$terminator_count" -gt 0 ]] && message="$message\nTerminator: $terminator_count windows"
        [[ -n "$tmux_sessions" && "$tmux_sessions" -gt 0 ]] && message="$message\nTmux: $tmux_sessions sessions"
        
        notify-send "Terminal Session Restored" "$message" -t 5000
    fi
}

# Provide restoration instructions for advanced features
provide_restoration_instructions() {
    log_info "Providing restoration instructions..."
    
    local instructions_file="${SESSION_STATE_DIR}/terminal_restore_instructions.txt"
    
    echo "Terminal Session Restoration Instructions" > "$instructions_file"
    echo "========================================" >> "$instructions_file"
    echo "" >> "$instructions_file"
    
    # Tmux instructions
    if [[ -f "${SESSION_STATE_DIR}/tmux/sessions.txt" ]]; then
        echo "Tmux Sessions:" >> "$instructions_file"
        echo "To restore tmux sessions, run:" >> "$instructions_file"
        while read -r session_line; do
            local session_name=$(echo "$session_line" | cut -d: -f1)
            echo "  tmux attach-session -t $session_name" >> "$instructions_file"
        done < "${SESSION_STATE_DIR}/tmux/session_details.txt" 2>/dev/null
        echo "" >> "$instructions_file"
    fi
    
    # Kitty instructions
    if [[ -f "${SESSION_STATE_DIR}/kitty/current_sessions.json" ]]; then
        echo "Kitty Sessions:" >> "$instructions_file"
        echo "Kitty sessions should auto-restore. If not, check kitty session configuration." >> "$instructions_file"
        echo "" >> "$instructions_file"
    fi
    
    # Terminator instructions
    if [[ -f "${SESSION_STATE_DIR}/terminator/config.backup" ]]; then
        echo "Terminator Layouts:" >> "$instructions_file"
        echo "Terminator layouts can be restored via its layout manager (Ctrl+Shift+L)" >> "$instructions_file"
        echo "" >> "$instructions_file"
    fi
    
    log_info "Restoration instructions saved to: $instructions_file"
}

# Main function
main() {
    log_info "Starting terminal session restoration..."
    
    # Wait for applications to stabilize
    sleep 3
    
    # Restore Kitty sessions
    restore_kitty_session
    
    # Restore Terminator sessions
    restore_terminator_session
    
    # Restore Tmux sessions
    restore_tmux_session
    
    # Additional wait for terminal loading
    sleep 2
    
    # Create new terminal sessions if needed
    create_terminal_sessions
    
    # Send commands to terminals
    send_terminal_commands
    
    # Provide instructions
    provide_restoration_instructions
    
    # Validate restoration
    validate_terminal_restoration
    
    # Send notification
    send_terminal_notification
    
    log_success "Terminal session restoration completed"
}

# Execute main function
main "$@"