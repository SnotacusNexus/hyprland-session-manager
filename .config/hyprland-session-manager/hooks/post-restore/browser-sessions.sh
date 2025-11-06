#!/usr/bin/env zsh

# Browser Session Restoration Hook
# Post-restore hook for Firefox session recovery

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[BROWSER RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[BROWSER RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[BROWSER RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Wait for Firefox to be ready
wait_for_firefox() {
    log_info "Waiting for Firefox to initialize..."
    
    local max_wait=30
    local waited=0
    
    while [[ $waited -lt $max_wait ]]; do
        if pgrep -x "firefox" > /dev/null; then
            # Check if Firefox profile is accessible
            local firefox_profile=$(find "${HOME}/.mozilla/firefox" -name "*.default*" -type d 2>/dev/null | head -1)
            if [[ -n "$firefox_profile" && -f "${firefox_profile}/sessionstore.json" ]]; then
                log_success "Firefox is ready (waited ${waited}s)"
                return 0
            fi
        fi
        sleep 1
        ((waited++))
    done
    
    log_warning "Firefox not ready after $max_wait seconds"
    return 1
}

# Restore Firefox session using saved session files
restore_firefox_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/firefox" ]]; then
        log_warning "No saved Firefox session data found"
        return 1
    fi
    
    log_info "Attempting Firefox session restoration..."
    
    local firefox_profile=$(find "${HOME}/.mozilla/firefox" -name "*.default*" -type d 2>/dev/null | head -1)
    
    if [[ -n "$firefox_profile" ]]; then
        # Wait for Firefox to be ready
        wait_for_firefox
        
        # Small delay to ensure Firefox is fully loaded
        sleep 3
        
        # Restore session files if they exist
        if [[ -f "${SESSION_STATE_DIR}/firefox/sessionstore.json" ]]; then
            log_info "Restoring Firefox session from backup..."
            
            # Backup current session first
            cp "${firefox_profile}/sessionstore.json" "${firefox_profile}/sessionstore.json.backup.$(date +%s)" 2>/dev/null
            
            # Restore saved session
            cp "${SESSION_STATE_DIR}/firefox/sessionstore.json" "${firefox_profile}/" 2>/dev/null
            
            log_success "Firefox session files restored"
        else
            log_warning "No Firefox session backup found"
        fi
        
        # Firefox should auto-restore sessions on next launch
        # We'll trigger a reload by focusing windows
        restore_firefox_window_focus
    else
        log_warning "Firefox profile not found"
    fi
}

# Restore Firefox window focus and positions
restore_firefox_window_focus() {
    log_info "Restoring Firefox window focus..."
    
    if [[ -f "${SESSION_STATE_DIR}/firefox/positions.txt" ]]; then
        # Read saved window positions
        while IFS=: read -r address pos_x pos_y size_x size_y workspace; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Firefox window: $address"
                
                # Focus the window (this might trigger session restoration)
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 0.5
            fi
        done < "${SESSION_STATE_DIR}/firefox/positions.txt"
    fi
    
    # Focus any Firefox window to trigger session load
    local firefox_windows=$(hyprctl clients -j | jq -r '.[] | select(.class == "firefox") | .address' 2>/dev/null | head -1)
    if [[ -n "$firefox_windows" ]]; then
        hyprctl dispatch focuswindow "address:$firefox_windows" 2>/dev/null
        log_success "Focused Firefox window: $firefox_windows"
    fi
}

# Send browser restoration notification
send_browser_notification() {
    log_info "Sending browser restoration notification..."
    
    if command -v notify-send > /dev/null; then
        notify-send "Browser Session Restored" "Firefox sessions have been restored\nCheck your tabs and windows" -t 5000
    fi
}

# Validate browser restoration
validate_browser_restoration() {
    log_info "Validating browser restoration..."
    
    local firefox_count=$(hyprctl clients -j | jq '[.[] | select(.class == "firefox")] | length' 2>/dev/null)
    
    if [[ -n "$firefox_count" && "$firefox_count" -gt 0 ]]; then
        log_success "Firefox restoration successful - $firefox_count windows open"
        return 0
    else
        log_warning "No Firefox windows detected after restoration"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting browser session restoration..."
    
    # Wait a moment for applications to stabilize
    sleep 2
    
    # Restore Firefox session
    restore_firefox_session
    
    # Additional wait for session loading
    sleep 3
    
    # Validate restoration
    validate_browser_restoration
    
    # Send notification
    send_browser_notification
    
    log_success "Browser session restoration completed"
}

# Execute main function
main "$@"