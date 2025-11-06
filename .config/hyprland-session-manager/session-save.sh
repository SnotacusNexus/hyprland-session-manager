#!/usr/bin/env zsh

# Session Save Script
# Called by session-manager.sh for save operations

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Enhanced application tracking
save_enhanced_applications() {
    log_info "Saving enhanced application information..."
    
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save detailed client information
        hyprctl clients -j > "${SESSION_STATE_DIR}/clients_detailed.json" 2>/dev/null
        
        # Extract application launch commands
        hyprctl clients -j | jq -r '.[] | select(.class != null) | "\(.class):\(.pid):\(.title)"' > "${SESSION_STATE_DIR}/applications_enhanced.txt" 2>/dev/null
        
        # Save workspace to application mapping
        hyprctl clients -j | jq -r '.[] | select(.workspace.id != null) | "\(.workspace.id):\(.class):\(.title)"' > "${SESSION_STATE_DIR}/workspace_apps.txt" 2>/dev/null
        
        log_success "Enhanced application information saved"
    else
        log_info "Missing dependencies - using basic application tracking"
    fi
}

# Save Hyprland configuration state
save_hyprland_config() {
    log_info "Saving Hyprland configuration state..."
    
    if command -v hyprctl > /dev/null; then
        # Save current keybinds
        hyprctl binds > "${SESSION_STATE_DIR}/keybinds.txt" 2>/dev/null
        
        # Save dispatcher rules
        hyprctl dispatchers > "${SESSION_STATE_DIR}/dispatchers.txt" 2>/dev/null
        
        # Save animation settings
        hyprctl animations > "${SESSION_STATE_DIR}/animations.txt" 2>/dev/null
        
        log_success "Hyprland configuration state saved"
    else
        log_info "hyprctl not available - skipping configuration state"
    fi
}

# Save system information
save_system_info() {
    log_info "Saving system information..."
    
    # Save current user
    whoami > "${SESSION_STATE_DIR}/user.txt"
    
    # Save display information
    echo "$DISPLAY" > "${SESSION_STATE_DIR}/display.txt"
    echo "$WAYLAND_DISPLAY" > "${SESSION_STATE_DIR}/wayland_display.txt"
    
    # Save environment variables
    printenv | grep -E "(XDG|WAYLAND|HYPR)" > "${SESSION_STATE_DIR}/environment.txt"
    
    log_success "System information saved"
}

# Main save function
main() {
    log_info "Starting enhanced session save..."
    
    # Create session state directory
    mkdir -p "$SESSION_STATE_DIR"
    
    # Save timestamp
    date '+%Y-%m-%d %H:%M:%S' > "${SESSION_STATE_DIR}/save_timestamp.txt"
    
    # Save enhanced application information
    save_enhanced_applications
    
    # Save Hyprland configuration
    save_hyprland_config
    
    # Save system information
    save_system_info
    
    log_success "Enhanced session save completed"
}

# Execute main function
main "$@"