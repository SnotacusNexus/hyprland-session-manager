#!/usr/bin/env zsh

# Telegram Desktop Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Telegram Desktop session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TELEGRAM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TELEGRAM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TELEGRAM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[TELEGRAM HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Telegram is running
is_telegram_running() {
    if pgrep -x "telegram-desktop" > /dev/null || pgrep -f "Telegram" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Telegram window class
get_telegram_class() {
    # Telegram Desktop window classes
    local telegram_classes=("telegram-desktop" "Telegram" "telegram")
    
    for class in "${telegram_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "telegram-desktop"
}

# Save Telegram session data
save_telegram_session() {
    local app_class="$(get_telegram_class)"
    local app_state_dir="${SESSION_STATE_DIR}/telegram"
    
    log_info "Saving Telegram Desktop session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain chat information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Telegram data directory information
    local telegram_data="${HOME}/.local/share/TelegramDesktop"
    
    if [[ -d "$telegram_data" ]]; then
        log_info "Found Telegram data directory"
        
        # Save tdata directory structure
        local tdata_dir="${telegram_data}/tdata"
        if [[ -d "$tdata_dir" ]]; then
            log_info "Found Telegram tdata directory - saving session information"
            
            # List important files in tdata
            find "$tdata_dir" -type f -name "*.key" -o -name "map*" -o -name "dbs*" -o -name "settings*" > "${app_state_dir}/telegram_files.txt" 2>/dev/null
            
            # Save directory structure
            find "$tdata_dir" -type d > "${app_state_dir}/telegram_dirs.txt" 2>/dev/null
            
            # Create backup of critical session files
            mkdir -p "${app_state_dir}/backup"
            
            # Backup key session files (avoid copying large files)
            local important_files=(
                "map0"
                "map1"
                "dbs"
                "settings"
                "usertags"
            )
            
            for file in "${important_files[@]}"; do
                if [[ -f "${tdata_dir}/${file}" ]]; then
                    echo "${tdata_dir}/${file}" >> "${app_state_dir}/config_files.txt" 2>/dev/null
                fi
            done
            
            # Create a checksum of key files to detect changes
            if command -v md5sum > /dev/null; then
                find "$tdata_dir" -name "map*" -o -name "dbs" -o -name "settings" | head -10 | xargs md5sum 2>/dev/null > "${app_state_dir}/file_checksums.txt" || true
            fi
        else
            log_warning "Telegram tdata directory not found at ${tdata_dir}"
        fi
    else
        log_warning "No Telegram data directory found at ~/.local/share/TelegramDesktop"
    fi
    
    # Save Telegram configuration
    local telegram_config="${HOME}/.config/TelegramDesktop"
    if [[ -d "$telegram_config" ]]; then
        log_info "Found Telegram configuration directory"
        
        # Save configuration files
        find "$telegram_config" -name "*.json" -o -name "*.ini" > "${app_state_dir}/config_files.txt" 2>/dev/null
    fi
    
    # Save process information
    pgrep -f "telegram" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Telegram Desktop session data saved"
}

# Create Telegram session summary
create_telegram_summary() {
    local app_class="$(get_telegram_class)"
    local app_state_dir="${SESSION_STATE_DIR}/telegram"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Telegram Desktop session summary..."
    
    echo "Telegram Desktop Session Summary - $(date)" > "$summary_file"
    echo "===========================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Telegram windows: $window_count" >> "$summary_file"
    
    # Window titles (chat information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (chats):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Telegram data information
    if [[ -f "${app_state_dir}/telegram_files.txt" ]]; then
        local file_count=$(wc -l < "${app_state_dir}/telegram_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Telegram session files: $file_count" >> "$summary_file"
    fi
    
    if [[ -f "${app_state_dir}/telegram_dirs.txt" ]]; then
        local dir_count=$(wc -l < "${app_state_dir}/telegram_dirs.txt" 2>/dev/null || echo "0")
        echo "Telegram data directories: $dir_count" >> "$summary_file"
    fi
    
    log_success "Telegram Desktop session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Telegram Desktop pre-save hook..."
    
    if is_telegram_running; then
        save_telegram_session
        create_telegram_summary
        log_success "Telegram Desktop pre-save hook completed"
    else
        log_info "Telegram Desktop not running - nothing to save"
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
        log_info "Telegram post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac