#!/usr/bin/env zsh

# Example Post-Restore Hook
# This script runs after session restore operations
# Add your custom post-restore logic here

SESSION_DIR="${HOME}/.config/hyprland-session-manager"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[POST-RESTORE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[POST-RESTORE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[POST-RESTORE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Example: Restore browser sessions
restore_browser_sessions() {
    log_info "Restoring browser sessions..."
    
    # Wait for browsers to be ready
    sleep 3
    
    # Example: Focus Firefox windows
    if pgrep -x "firefox" > /dev/null; then
        log_info "Firefox detected - focusing windows"
        # You could add window management logic here
    fi
    
    # Example: Focus Chromium-based browsers
    if pgrep -x "chromium" > /dev/null || pgrep -x "google-chrome" > /dev/null; then
        log_info "Chromium-based browser detected - focusing windows"
    fi
}

# Example: Restore terminal sessions
restore_terminal_sessions() {
    log_info "Restoring terminal sessions..."
    
    # Example: Restore tmux sessions
    if command -v tmux > /dev/null; then
        log_info "Tmux available - sessions should auto-restore"
        # Additional tmux session management could go here
    fi
    
    # Example: Set terminal focus
    if pgrep -x "kitty" > /dev/null || pgrep -x "alacritty" > /dev/null; then
        log_info "Terminal emulator detected - consider window focus"
    fi
}

# Example: Restore development environments
restore_development_env() {
    log_info "Restoring development environments..."
    
    # Example: Check for code editors
    if pgrep -x "code" > /dev/null || pgrep -x "vscodium" > /dev/null; then
        log_info "VS Code detected - projects should auto-restore"
    fi
    
    # Example: Check for Neovim
    if pgrep -x "nvim" > /dev/null; then
        log_info "Neovim detected - session files should be loaded"
    fi
}

# Example: Perform post-restore cleanup
perform_cleanup() {
    log_info "Performing post-restore cleanup..."
    
    # Example: Remove temporary files
    local temp_dir="${SESSION_DIR}/session-state/temp"
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
        log_info "Temporary files cleaned up"
    fi
    
    # Example: Update session statistics
    local stats_file="${SESSION_DIR}/session-state/restore_stats.txt"
    echo "Last restore: $(date '+%Y-%m-%d %H:%M:%S')" > "$stats_file"
    echo "User: $(whoami)" >> "$stats_file"
    
    log_success "Cleanup completed"
}

# Example: Send notification
send_notification() {
    log_info "Sending restoration notification..."
    
    # Example: Use notify-send if available
    if command -v notify-send > /dev/null; then
        notify-send "Hyprland Session Manager" "Session restoration completed successfully" -t 3000
    fi
    
    # Alternative: Log message
    log_success "Session restoration completed - all applications launched"
}

# Example: Validate restoration
validate_restoration() {
    log_info "Validating restoration..."
    
    local success_count=0
    local total_expected=0
    
    # Count running applications that were supposed to be restored
    if [[ -f "${SESSION_DIR}/session-state/applications_enhanced.txt" ]]; then
        while IFS=: read -r class pid title; do
            if [[ -n "$class" && "$class" != "null" ]]; then
                ((total_expected++))
                if pgrep -x "$class" > /dev/null; then
                    ((success_count++))
                fi
            fi
        done < "${SESSION_DIR}/session-state/applications_enhanced.txt"
    fi
    
    if [[ $total_expected -gt 0 ]]; then
        local success_rate=$((success_count * 100 / total_expected))
        log_info "Restoration success rate: ${success_rate}% ($success_count/$total_expected)"
        
        if [[ $success_rate -lt 50 ]]; then
            log_warning "Low restoration success rate - some applications may not have launched"
        fi
    else
        log_warning "No application restoration data found"
    fi
}

# Main hook function
main() {
    log_info "Starting post-restore hook execution..."
    
    # Wait a moment for applications to stabilize
    sleep 2
    
    # Execute hook functions
    restore_browser_sessions
    restore_terminal_sessions
    restore_development_env
    validate_restoration
    perform_cleanup
    send_notification
    
    log_success "Post-restore hook execution completed"
}

# Execute main function
main "$@"