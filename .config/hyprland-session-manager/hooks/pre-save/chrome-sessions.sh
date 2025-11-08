#!/usr/bin/env zsh

# Chrome/Chromium Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Chrome/Chromium browser session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[CHROME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Chrome/Chromium is running
is_chrome_running() {
    if pgrep -x "chrome" > /dev/null || pgrep -x "chromium" > /dev/null || pgrep -x "google-chrome" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Chrome/Chromium window class
get_chrome_class() {
    # Chrome/Chromium can have different window classes depending on the distribution
    local chrome_classes=("google-chrome" "chromium" "chrome" "Chromium" "Google-chrome")
    
    for class in "${chrome_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "google-chrome"
}

# Save Chrome session data
save_chrome_session() {
    local app_class="$(get_chrome_class)"
    local app_state_dir="${SESSION_STATE_DIR}/chrome"
    
    log_info "Saving Chrome/Chromium session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain tab information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Chrome profile information
    local chrome_config="${HOME}/.config/google-chrome"
    local chromium_config="${HOME}/.config/chromium"
    
    # Check which browser is installed and save session data
    if [[ -d "$chrome_config" ]]; then
        log_info "Found Google Chrome configuration"
        # List available profiles
        find "$chrome_config" -name "Local State" -path "*/Default/*" -o -path "*/Profile */Local State" > "${app_state_dir}/chrome_profiles.txt" 2>/dev/null
        
        # Save session files if they exist
        find "$chrome_config" -name "Session Storage" -type d > "${app_state_dir}/session_storage_dirs.txt" 2>/dev/null
        find "$chrome_config" -name "Last Session" -o -name "Current Session" > "${app_state_dir}/session_files.txt" 2>/dev/null
        
    elif [[ -d "$chromium_config" ]]; then
        log_info "Found Chromium configuration"
        # List available profiles
        find "$chromium_config" -name "Local State" -path "*/Default/*" -o -path "*/Profile */Local State" > "${app_state_dir}/chromium_profiles.txt" 2>/dev/null
        
        # Save session files if they exist
        find "$chromium_config" -name "Session Storage" -type d > "${app_state_dir}/session_storage_dirs.txt" 2>/dev/null
        find "$chromium_config" -name "Last Session" -o -name "Current Session" > "${app_state_dir}/session_files.txt" 2>/dev/null
    else
        log_warning "No Chrome/Chromium configuration directory found"
    fi
    
    # Save process information
    pgrep -f "chrome\|chromium" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Chrome/Chromium session data saved"
}

# Create Chrome session summary
create_chrome_summary() {
    local app_class="$(get_chrome_class)"
    local app_state_dir="${SESSION_STATE_DIR}/chrome"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Chrome/Chromium session summary..."
    
    echo "Chrome/Chromium Session Summary - $(date)" > "$summary_file"
    echo "==========================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Chrome windows: $window_count" >> "$summary_file"
    
    # Window titles (tab information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (tabs):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Profile information
    if [[ -f "${app_state_dir}/chrome_profiles.txt" ]] || [[ -f "${app_state_dir}/chromium_profiles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Available profiles:" >> "$summary_file"
        if [[ -f "${app_state_dir}/chrome_profiles.txt" ]]; then
            echo "  Google Chrome profiles found" >> "$summary_file"
        fi
        if [[ -f "${app_state_dir}/chromium_profiles.txt" ]]; then
            echo "  Chromium profiles found" >> "$summary_file"
        fi
    fi
    
    log_success "Chrome/Chromium session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Chrome/Chromium pre-save hook..."
    
    if is_chrome_running; then
        save_chrome_session
        create_chrome_summary
        log_success "Chrome/Chromium pre-save hook completed"
    else
        log_info "Chrome/Chromium not running - nothing to save"
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
        log_info "Chrome post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac