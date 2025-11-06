#!/usr/bin/env zsh

# Browser Session Management Hook
# Pre-save hook for Firefox session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[BROWSER HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[BROWSER HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[BROWSER HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Save Firefox session using sessionstore.json
save_firefox_session() {
    if pgrep -x "firefox" > /dev/null; then
        log_info "Firefox detected - attempting session save"
        
        # Find Firefox profile directory
        local firefox_profile=$(find "${HOME}/.mozilla/firefox" -name "*.default*" -type d 2>/dev/null | head -1)
        
        if [[ -n "$firefox_profile" && -f "${firefox_profile}/sessionstore.json" ]]; then
            # Backup sessionstore files
            mkdir -p "${SESSION_STATE_DIR}/firefox"
            
            # Copy session files
            cp "${firefox_profile}/sessionstore.json" "${SESSION_STATE_DIR}/firefox/" 2>/dev/null
            cp "${firefox_profile}/sessionstore-backups/recovery.jsonlz4" "${SESSION_STATE_DIR}/firefox/" 2>/dev/null 2>&1
            
            # Save open window information
            hyprctl clients -j | jq -r '.[] | select(.class == "firefox") | "\(.address):\(.title)"' > "${SESSION_STATE_DIR}/firefox/windows.txt" 2>/dev/null
            
            log_success "Firefox session saved from profile: $(basename "$firefox_profile")"
        else
            log_warning "Firefox profile or session files not found"
        fi
        
        # Save Firefox window positions
        hyprctl clients -j | jq -r '.[] | select(.class == "firefox") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id)"' > "${SESSION_STATE_DIR}/firefox/positions.txt" 2>/dev/null
    else
        log_info "Firefox not running - no session to save"
    fi
}

# Save browser tabs using command line (alternative method)
save_browser_tabs_cli() {
    log_info "Saving browser tab information..."
    
    # Extract URLs from Firefox using various methods
    if command -v sqlite3 > /dev/null; then
        local firefox_profile=$(find "${HOME}/.mozilla/firefox" -name "*.default*" -type d 2>/dev/null | head -1)
        
        if [[ -n "$firefox_profile" && -f "${firefox_profile}/places.sqlite" ]]; then
            # Extract recently visited URLs (this is a fallback, not current tabs)
            sqlite3 "${firefox_profile}/places.sqlite" "SELECT url FROM moz_places ORDER BY last_visit_date DESC LIMIT 20;" > "${SESSION_STATE_DIR}/firefox/recent_urls.txt" 2>/dev/null
        fi
    fi
    
    # Save window titles which often contain page titles
    hyprctl clients -j | jq -r '.[] | select(.class == "firefox") | .title' > "${SESSION_STATE_DIR}/firefox/window_titles.txt" 2>/dev/null
}

# Create browser session summary
create_browser_summary() {
    log_info "Creating browser session summary..."
    
    local summary_file="${SESSION_STATE_DIR}/browser_summary.txt"
    
    echo "Browser Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Firefox info
    if pgrep -x "firefox" > /dev/null; then
        local firefox_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "firefox")] | length' 2>/dev/null)
        echo "Firefox: $firefox_windows windows open" >> "$summary_file"
        
        # List window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "firefox") | "  - " + .title' >> "$summary_file" 2>/dev/null
    else
        echo "Firefox: Not running" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    log_success "Browser session summary created"
}

# Main function
main() {
    log_info "Starting browser session preservation..."
    
    # Create browser state directory
    mkdir -p "${SESSION_STATE_DIR}/firefox"
    
    # Save Firefox session
    save_firefox_session
    
    # Save browser tabs using CLI methods
    save_browser_tabs_cli
    
    # Create summary
    create_browser_summary
    
    log_success "Browser session preservation completed"
}

# Execute main function
main "$@"