#!/usr/bin/env zsh

# Telegram Desktop Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Post-restore hook for Telegram Desktop session restoration

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
# POST-RESTORE HOOK FUNCTIONS
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

# Launch Telegram Desktop
launch_telegram() {
    log_info "Launching Telegram Desktop..."
    
    # Check if Telegram is available
    local telegram_cmd=""
    if command -v telegram-desktop > /dev/null; then
        telegram_cmd="telegram-desktop"
    elif command -v telegram > /dev/null; then
        telegram_cmd="telegram"
    else
        log_error "No Telegram Desktop executable found in PATH"
        return 1
    fi
    
    # Launch Telegram (it auto-restores sessions from its data directory)
    $telegram_cmd &
    
    local telegram_pid=$!
    log_info "Telegram Desktop launched with PID: $telegram_pid"
    
    # Wait a moment for Telegram to start
    sleep 3
    
    # Verify Telegram started successfully
    if kill -0 $telegram_pid 2>/dev/null; then
        log_success "Telegram Desktop launched successfully"
        return 0
    else
        log_error "Telegram Desktop failed to start"
        return 1
    fi
}

# Verify Telegram data directory
verify_telegram_data() {
    local telegram_data="${HOME}/.local/share/TelegramDesktop"
    local app_state_dir="${SESSION_STATE_DIR}/telegram"
    
    log_info "Verifying Telegram data directory..."
    
    if [[ -d "$telegram_data" ]]; then
        local tdata_dir="${telegram_data}/tdata"
        if [[ -d "$tdata_dir" ]]; then
            log_success "Telegram data directory exists and contains tdata"
            
            # Check if key session files exist
            local key_files_exist=0
            local important_files=("map0" "map1" "dbs" "settings")
            
            for file in "${important_files[@]}"; do
                if [[ -f "${tdata_dir}/${file}" ]]; then
                    key_files_exist=$((key_files_exist + 1))
                fi
            done
            
            if [[ $key_files_exist -gt 0 ]]; then
                log_success "Found $key_files_exist key session files - Telegram should restore sessions"
                return 0
            else
                log_warning "No key session files found - Telegram may start fresh"
                return 1
            fi
        else
            log_warning "Telegram tdata directory not found - Telegram will start fresh"
            return 1
        fi
    else
        log_warning "Telegram data directory not found - Telegram will start fresh"
        return 1
    fi
}

# Restore Telegram session data
restore_telegram_session() {
    local app_class="$(get_telegram_class)"
    local app_state_dir="${SESSION_STATE_DIR}/telegram"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No Telegram Desktop session data to restore"
        return
    fi
    
    log_info "Restoring Telegram Desktop session..."
    
    # Check if session summary exists
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        log_info "Session summary found:"
        cat "${app_state_dir}/session_summary.txt" | head -10
    fi
    
    # Verify Telegram data directory first
    verify_telegram_data
    
    # Launch Telegram if not running
    if ! is_telegram_running; then
        launch_telegram
    else
        log_info "Telegram Desktop already running - sessions should be preserved"
    fi
    
    # Note: Telegram automatically handles session restoration from its tdata directory
    # The window positions and layouts are handled by Hyprland
    
    log_success "Telegram Desktop session restoration initiated"
}

# Verify Telegram session restoration
verify_telegram_restoration() {
    local app_class="$(get_telegram_class)"
    local app_state_dir="${SESSION_STATE_DIR}/telegram"
    
    log_info "Verifying Telegram Desktop session restoration..."
    
    # Wait a bit for Telegram to fully load
    sleep 5
    
    # Check if Telegram windows are present
    local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    
    if [[ -f "${app_state_dir}/session_summary.txt" ]]; then
        local saved_windows=$(grep "Open Telegram windows:" "${app_state_dir}/session_summary.txt" | grep -o '[0-9]*' || echo "0")
        
        if [[ $current_windows -gt 0 ]]; then
            log_success "Telegram Desktop restoration verified - $current_windows windows detected"
            return 0
        else
            log_warning "No Telegram windows detected after restoration attempt"
            return 1
        fi
    else
        log_info "No saved session summary for comparison"
        return 0
    fi
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Post-restore hook main function
post_restore_main() {
    log_info "Starting Telegram Desktop post-restore hook..."
    
    restore_telegram_session
    
    # Give Telegram time to restore, then verify
    sleep 8
    verify_telegram_restoration
    
    log_success "Telegram Desktop post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        log_info "Telegram pre-save hook would be handled by separate script"
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac