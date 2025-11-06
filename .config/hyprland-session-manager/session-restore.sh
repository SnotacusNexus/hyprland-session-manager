#!/usr/bin/env zsh

# Session Restore Script
# Called by session-manager.sh for restore operations

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Wait for Hyprland to be ready
wait_for_hyprland() {
    log_info "Waiting for Hyprland to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if pgrep -x "Hyprland" > /dev/null && command -v hyprctl > /dev/null; then
            # Test if hyprctl is responding
            if hyprctl version > /dev/null 2>&1; then
                log_success "Hyprland is ready (attempt $attempt/$max_attempts)"
                return 0
            fi
        fi
        
        sleep 1
        ((attempt++))
    done
    
    log_warning "Hyprland not ready after $max_attempts attempts - proceeding anyway"
    return 1
}

# Enhanced application restoration
restore_enhanced_applications() {
    log_info "Restoring enhanced applications..."
    
    if [[ ! -f "${SESSION_STATE_DIR}/applications_enhanced.txt" ]]; then
        log_warning "No enhanced application information found"
        return 1
    fi
    
    local count=0
    local failed=0
    
    while IFS=: read -r class pid title; do
        if [[ -n "$class" && "$class" != "null" ]]; then
            log_info "Launching: $class"
            
            # Enhanced application launching with better detection
            case "$class" in
                "kitty"|"alacritty"|"wezterm")
                    # Terminal emulators
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "Command not found: $class"
                        ((failed++))
                    fi
                    ;;
                "firefox"|"chromium"|"google-chrome"|"brave-browser")
                    # Web browsers
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "Browser not found: $class"
                        ((failed++))
                    fi
                    ;;
                "code"|"vscodium"|"codium")
                    # Code editors
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "Code editor not found: $class"
                        ((failed++))
                    fi
                    ;;
                "thunar"|"nautilus"|"dolphin"|"pcmanfm")
                    # File managers
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "File manager not found: $class"
                        ((failed++))
                    fi
                    ;;
                "obs"|"obs-studio")
                    # OBS Studio
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "OBS Studio not found: $class"
                        ((failed++))
                    fi
                    ;;
                "discord"|"telegram-desktop"|"signal-desktop")
                    # Messaging apps
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "Messaging app not found: $class"
                        ((failed++))
                    fi
                    ;;
                *)
                    # Generic application launch
                    if command -v "$class" > /dev/null; then
                        nohup "$class" > /dev/null 2>&1 &
                        ((count++))
                    else
                        log_warning "Application not found: $class"
                        ((failed++))
                    fi
                    ;;
            esac
            
            # Staggered delay between launches
            sleep 2
        fi
    done < "${SESSION_STATE_DIR}/applications_enhanced.txt"
    
    if [[ $failed -gt 0 ]]; then
        log_warning "Failed to launch $failed applications"
    fi
    
    log_success "Successfully launched $count applications"
}

# Restore workspace focus (basic implementation)
restore_workspace_focus() {
    log_info "Attempting workspace focus restoration..."
    
    if [[ -f "${SESSION_STATE_DIR}/active_workspace.json" ]] && command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        local workspace_id=$(jq -r '.id' "${SESSION_STATE_DIR}/active_workspace.json" 2>/dev/null)
        if [[ -n "$workspace_id" && "$workspace_id" != "null" ]]; then
            log_info "Focusing workspace: $workspace_id"
            hyprctl dispatch workspace "$workspace_id"
        fi
    else
        log_info "Workspace focus information not available"
    fi
}

# Validate session state
validate_session_state() {
    log_info "Validating session state..."
    
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_warning "No session state directory found"
        return 1
    fi
    
    local required_files=("save_timestamp.txt" "applications_enhanced.txt")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${SESSION_STATE_DIR}/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_warning "Missing session files: ${missing_files[*]}"
        return 1
    fi
    
    log_success "Session state validation passed"
    return 0
}

# Main restore function
main() {
    log_info "Starting enhanced session restore..."
    
    # Validate session state
    if ! validate_session_state; then
        log_warning "Session state validation failed - attempting partial restore"
    fi
    
    # Wait for Hyprland
    wait_for_hyprland
    
    # Additional delay for stability
    sleep 2
    
    # Restore applications
    restore_enhanced_applications
    
    # Restore workspace focus
    restore_workspace_focus
    
    log_success "Enhanced session restore completed"
}

# Execute main function
main "$@"