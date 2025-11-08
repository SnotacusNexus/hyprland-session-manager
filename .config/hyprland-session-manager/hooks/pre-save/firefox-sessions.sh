#!/usr/bin/env zsh

# Firefox Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Firefox browser session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[FIREFOX HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Firefox is running
is_firefox_running() {
    if pgrep -x "firefox" > /dev/null || pgrep -f "firefox-bin" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Firefox window class
get_firefox_class() {
    # Firefox can have different window classes depending on the distribution
    local firefox_classes=("firefox" "Firefox" "firefox-esr" "Firefox-esr")
    
    for class in "${firefox_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "firefox"
}

# Find Firefox profiles
find_firefox_profiles() {
    local firefox_dir="${HOME}/.mozilla/firefox"
    local profiles=()
    
    if [[ ! -d "$firefox_dir" ]]; then
        log_warning "Firefox directory not found: $firefox_dir"
        return 1
    fi
    
    # Find profile directories (they contain profiles.ini or are named *.default*)
    while IFS= read -r profile; do
        if [[ -d "$profile" ]] && [[ "$profile" != *"Crash Reports"* ]] && [[ "$profile" != *"Pending Pings"* ]]; then
            profiles+=("$profile")
        fi
    done < <(find "$firefox_dir" -maxdepth 1 -type d -name "*.*" 2>/dev/null)
    
    if [[ ${#profiles[@]} -eq 0 ]]; then
        log_warning "No Firefox profiles found"
        return 1
    fi
    
    printf '%s\n' "${profiles[@]}"
    return 0
}

# Save Firefox session data
save_firefox_session() {
    local app_class="$(get_firefox_class)"
    local app_state_dir="${SESSION_STATE_DIR}/firefox"
    
    log_info "Saving Firefox session data..."
    
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
    else
        log_warning "hyprctl or jq not available - skipping window state capture"
    fi
    
    # Save Firefox profile and session information
    local firefox_config="${HOME}/.mozilla/firefox"
    
    if [[ -d "$firefox_config" ]]; then
        log_info "Found Firefox configuration directory"
        
        # Save profile list
        find_firefox_profiles > "${app_state_dir}/profiles.txt" 2>/dev/null
        
        # Save sessionstore files from each profile
        local profiles=$(find_firefox_profiles)
        if [[ -n "$profiles" ]]; then
            local profile_count=0
            while IFS= read -r profile; do
                if [[ -n "$profile" ]] && [[ -d "$profile" ]]; then
                    ((profile_count++))
                    local profile_name=$(basename "$profile")
                    local profile_state_dir="${app_state_dir}/profiles/${profile_name}"
                    mkdir -p "$profile_state_dir"
                    
                    # Save sessionstore files
                    local session_files=("recovery.jsonlz4" "previous.jsonlz4" "upgrade.jsonlz4.backup" "sessionstore.jsonlz4")
                    
                    for session_file in "${session_files[@]}"; do
                        local session_path="${profile}/sessionstore-backups/${session_file}"
                        if [[ -f "$session_path" ]]; then
                            log_info "Found session file: $session_file in profile $profile_name"
                            echo "$session_path" >> "${app_state_dir}/session_files.txt"
                            # Note: We don't copy the actual session files as Firefox manages them internally
                        fi
                    done
                    
                    # Save profile information
                    echo "Profile: $profile_name" >> "${profile_state_dir}/profile_info.txt"
                    echo "Path: $profile" >> "${profile_state_dir}/profile_info.txt"
                    
                    # Check for important profile files
                    local profile_files=("prefs.js" "places.sqlite" "cookies.sqlite")
                    for pfile in "${profile_files[@]}"; do
                        if [[ -f "${profile}/${pfile}" ]]; then
                            echo "${profile}/${pfile}" >> "${profile_state_dir}/profile_files.txt"
                        fi
                    done
                fi
            done <<< "$profiles"
            
            log_info "Processed $profile_count Firefox profiles"
        fi
        
        # Save profiles.ini
        if [[ -f "${firefox_config}/profiles.ini" ]]; then
            cp "${firefox_config}/profiles.ini" "${app_state_dir}/profiles.ini" 2>/dev/null || true
            log_info "Saved profiles.ini"
        fi
    else
        log_warning "Firefox configuration directory not found: $firefox_config"
    fi
    
    # Save process information
    pgrep -f "firefox" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save Firefox version information
    if command -v firefox > /dev/null; then
        firefox --version 2>/dev/null > "${app_state_dir}/version.txt" || true
    fi
    
    log_success "Firefox session data saved"
}

# Create Firefox session summary
create_firefox_summary() {
    local app_class="$(get_firefox_class)"
    local app_state_dir="${SESSION_STATE_DIR}/firefox"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Firefox session summary..."
    
    echo "Firefox Session Summary - $(date)" > "$summary_file"
    echo "=================================" >> "$summary_file"
    
    # Window count
    local window_count=0
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    fi
    echo "Open Firefox windows: $window_count" >> "$summary_file"
    
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
    if [[ -f "${app_state_dir}/profiles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Firefox profiles:" >> "$summary_file"
        cat "${app_state_dir}/profiles.txt" | while IFS= read -r profile; do
            if [[ -n "$profile" ]]; then
                echo "  - $(basename "$profile")" >> "$summary_file"
            fi
        done
    fi
    
    # Session files
    if [[ -f "${app_state_dir}/session_files.txt" ]]; then
        local session_count=$(wc -l < "${app_state_dir}/session_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Session files found: $session_count" >> "$summary_file"
    fi
    
    log_success "Firefox session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Firefox pre-save hook..."
    
    if is_firefox_running; then
        save_firefox_session
        create_firefox_summary
        log_success "Firefox pre-save hook completed"
    else
        log_info "Firefox not running - nothing to save"
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
        log_info "Firefox post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac