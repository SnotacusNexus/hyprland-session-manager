#!/usr/bin/env zsh

# Signal Desktop Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Signal Desktop session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[SIGNAL HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Signal is running
is_signal_running() {
    if pgrep -x "signal-desktop" > /dev/null || pgrep -f "Signal" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Signal window class
get_signal_class() {
    # Signal Desktop window classes
    local signal_classes=("signal-desktop" "Signal" "signal")
    
    for class in "${signal_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "signal-desktop"
}

# Save Signal session data
save_signal_session() {
    local app_class="$(get_signal_class)"
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    
    log_info "Saving Signal Desktop session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain conversation information)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Signal configuration and data
    local signal_config="${HOME}/.config/Signal"
    
    if [[ -d "$signal_config" ]]; then
        log_info "Found Signal configuration directory"
        
        # Save configuration files
        find "$signal_config" -name "*.json" -o -name "config.json" -o -name "settings.json" > "${app_state_dir}/config_files.txt" 2>/dev/null
        
        # Save important configuration files
        local important_files=(
            "config.json"
            "settings.json"
            "window-state.json"
        )
        
        for file in "${important_files[@]}"; do
            if [[ -f "${signal_config}/${file}" ]]; then
                cp "${signal_config}/${file}" "${app_state_dir}/" 2>/dev/null || true
                log_info "Saved Signal configuration file: $file"
            fi
        done
        
        # Save logs directory information (for debugging)
        local logs_dir="${signal_config}/logs"
        if [[ -d "$logs_dir" ]]; then
            find "$logs_dir" -name "*.log" | head -5 > "${app_state_dir}/log_files.txt" 2>/dev/null
        fi
    else
        log_warning "No Signal configuration directory found at ~/.config/Signal"
    fi
    
    # Save Signal data from various locations
    local signal_data_locations=(
        "${HOME}/.config/Signal"
        "${HOME}/.var/app/org.signal.Signal/config/Signal"  # Flatpak location
        "${HOME}/snap/signal-desktop/current/.config/Signal"  # Snap location
    )
    
    for location in "${signal_data_locations[@]}"; do
        if [[ -d "$location" ]]; then
            log_info "Found Signal data at: $location"
            echo "$location" >> "${app_state_dir}/data_locations.txt" 2>/dev/null
        fi
    done
    
    # Save process information
    pgrep -f "signal" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    log_success "Signal Desktop session data saved"
}

# Create Signal session summary
create_signal_summary() {
    local app_class="$(get_signal_class)"
    local app_state_dir="${SESSION_STATE_DIR}/signal"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Signal Desktop session summary..."
    
    echo "Signal Desktop Session Summary - $(date)" > "$summary_file"
    echo "=========================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Signal windows: $window_count" >> "$summary_file"
    
    # Window titles (conversation information)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (conversations):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Configuration information
    if [[ -f "${app_state_dir}/config_files.txt" ]]; then
        local config_count=$(wc -l < "${app_state_dir}/config_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Configuration files: $config_count" >> "$summary_file"
    fi
    
    # Data locations
    if [[ -f "${app_state_dir}/data_locations.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Signal data locations:" >> "$summary_file"
        cat "${app_state_dir}/data_locations.txt" | head -5 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    log_success "Signal Desktop session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Signal Desktop pre-save hook..."
    
    if is_signal_running; then
        save_signal_session
        create_signal_summary
        log_success "Signal Desktop pre-save hook completed"
    else
        log_info "Signal Desktop not running - nothing to save"
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
        log_info "Signal post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac