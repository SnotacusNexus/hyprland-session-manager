#!/usr/bin/env zsh

# Discord Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Discord chat session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[DISCORD HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Discord is running
is_discord_running() {
    if pgrep -x "discord" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Discord window class
get_discord_class() {
    # Discord can have different window classes depending on the distribution
    local discord_classes=("discord" "Discord" "discord-ptb" "discord-canary")
    
    for class in "${discord_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "discord"
}

# Save Discord session data
save_discord_session() {
    local app_class="$(get_discord_class)"
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    
    log_info "Saving Discord session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain server/channel information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Discord configuration and session data
    local discord_config="${HOME}/.config/discord"
    local discord_data="${HOME}/.config/discord/settings.json"
    
    if [[ -d "$discord_config" ]]; then
        log_info "Found Discord configuration directory"
        
        # Save settings file (contains recent servers, themes, etc.)
        if [[ -f "$discord_data" ]]; then
            cp "$discord_data" "${app_state_dir}/settings.json" 2>/dev/null || log_warning "Could not copy Discord settings"
        fi
        
        # Save session storage directories
        find "$discord_config" -name "Session Storage" -type d > "${app_state_dir}/session_storage_dirs.txt" 2>/dev/null
        find "$discord_config" -name "Local Storage" -type d > "${app_state_dir}/local_storage_dirs.txt" 2>/dev/null
        
        # Save cache information
        local discord_cache="${HOME}/.cache/discord"
        if [[ -d "$discord_cache" ]]; then
            find "$discord_cache" -name "*.log" -o -name "*.json" > "${app_state_dir}/cache_files.txt" 2>/dev/null
        fi
    else
        log_warning "No Discord configuration directory found"
    fi
    
    # Save process information
    pgrep -f "discord" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save Discord version information if available
    if command -v discord > /dev/null; then
        discord --version > "${app_state_dir}/version.txt" 2>/dev/null || true
    fi
    
    log_success "Discord session data saved"
}

# Extract server and channel information from window titles
extract_discord_channels() {
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        log_info "Extracting Discord server and channel information..."
        
        # Discord window titles typically contain server and channel names
        # Format: "Channel Name - Server Name - Discord" or similar
        cat "${app_state_dir}/window_titles.txt" | \
        grep -E ".*-.*-.*Discord|.*Discord.*" | \
        sed 's/ - Discord//g' | \
        sed 's/Discord//g' | \
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//' > "${app_state_dir}/channels.txt" 2>/dev/null
        
        # Count unique servers/channels
        local channel_count=$(wc -l < "${app_state_dir}/channels.txt" 2>/dev/null || echo "0")
        log_info "Found $channel_count Discord channels/servers"
    fi
}

# Create Discord session summary
create_discord_summary() {
    local app_class="$(get_discord_class)"
    local app_state_dir="${SESSION_STATE_DIR}/discord"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Discord session summary..."
    
    echo "Discord Session Summary - $(date)" > "$summary_file"
    echo "==================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Discord windows: $window_count" >> "$summary_file"
    
    # Window titles (server/channel information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles:" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -5 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Extracted channels
    if [[ -f "${app_state_dir}/channels.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Detected channels/servers:" >> "$summary_file"
        cat "${app_state_dir}/channels.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Configuration status
    if [[ -f "${app_state_dir}/settings.json" ]]; then
        echo "" >> "$summary_file"
        echo "Configuration: Settings file saved" >> "$summary_file"
    fi
    
    log_success "Discord session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Discord pre-save hook..."
    
    if is_discord_running; then
        save_discord_session
        extract_discord_channels
        create_discord_summary
        log_success "Discord pre-save hook completed"
    else
        log_info "Discord not running - nothing to save"
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
        log_info "Discord post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac