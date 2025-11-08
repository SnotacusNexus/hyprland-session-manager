#!/usr/bin/env zsh

# 🗑️ Hyprland Session Manager Uninstallation Script
# Clean removal of all session manager files and configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
HYPRLAND_CONFIG_DIR="${HOME}/.config/hypr"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as correct user
check_user() {
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Do not run this script as root! Run as your regular user."
        exit 1
    fi
}

# Stop and disable systemd service
stop_systemd_service() {
    log_info "Stopping systemd service..."
    
    if systemctl --user is-active hyprland-session.service > /dev/null 2>&1; then
        systemctl --user stop hyprland-session.service
        log_success "Systemd service stopped"
    fi
    
    if systemctl --user is-enabled hyprland-session.service > /dev/null 2>&1; then
        systemctl --user disable hyprland-session.service
        log_success "Systemd service disabled"
    fi
    
    # Remove service files
    if [[ -f "$SYSTEMD_USER_DIR/hyprland-session.service" ]]; then
        rm -f "$SYSTEMD_USER_DIR/hyprland-session.service"
        log_success "Systemd service file removed"
    fi
    
    if [[ -f "$SYSTEMD_USER_DIR/hyprland-session.target" ]]; then
        rm -f "$SYSTEMD_USER_DIR/hyprland-session.target"
        log_success "Systemd target file removed"
    fi
    
    # Reload systemd
    systemctl --user daemon-reload
    log_success "Systemd daemon reloaded"
}

# Remove keybindings from Hyprland config
remove_keybindings() {
    log_info "Removing keybindings from Hyprland config..."
    
    local hyprland_config="$HYPRLAND_CONFIG_DIR/hyprland.conf"
    local temp_config="${hyprland_config}.tmp"
    
    if [[ ! -f "$hyprland_config" ]]; then
        log_warning "Hyprland config not found at $hyprland_config"
        return
    fi
    
    # Create backup
    cp "$hyprland_config" "${hyprland_config}.backup.$(date +%s)"
    
    # Remove session manager keybindings
    if grep -q "session-manager.sh" "$hyprland_config"; then
        # Remove lines containing session-manager.sh and the section header
        grep -v "session-manager.sh" "$hyprland_config" | \
        grep -v "^# Session Manager Keybindings$" > "$temp_config"
        
        mv "$temp_config" "$hyprland_config"
        log_success "Keybindings removed from Hyprland config"
    else
        log_info "No session manager keybindings found in config"
    fi
}

# Remove session manager directory
remove_session_directory() {
    log_info "Removing session manager directory..."
    
    if [[ -d "$SESSION_DIR" ]]; then
        # Ask for confirmation before removing session state
        echo ""
        echo -e "${YELLOW}WARNING: This will remove all saved session data.${NC}"
        read -q "?Are you sure you want to continue? [y/N] "
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$SESSION_DIR"
            log_success "Session manager directory removed"
        else
            log_info "Session manager directory removal cancelled"
        fi
    else
        log_info "Session manager directory not found"
    fi
}

# Clean up any remaining files
cleanup_remaining() {
    log_info "Cleaning up remaining files..."
    
    # Remove any backup files created during installation
    local backup_files=(
        "$HYPRLAND_CONFIG_DIR/hyprland.conf.backup.*"
    )
    
    for pattern in "${backup_files[@]}"; do
        if ls $pattern > /dev/null 2>&1; then
            rm -f $pattern
            log_success "Backup files cleaned up"
        fi
    done
}

# Display completion message
show_completion() {
    echo ""
    echo "=========================================="
    echo "🗑️  Hyprland Session Manager Uninstalled!"
    echo "=========================================="
    echo ""
    echo "✅ Removed:"
    echo "  - Session manager scripts and hooks"
    echo "  - Systemd service files"
    echo "  - Hyprland keybindings"
    echo "  - Session state data"
    echo ""
    echo "📝 Note:"
    echo "  - A backup of your Hyprland config was created"
    echo "  - You may need to restart Hyprland for changes to take effect"
    echo ""
}

# Main uninstallation function
main() {
    echo "🗑️  Hyprland Session Manager Uninstallation"
    echo "=========================================="
    echo ""
    
    check_user
    stop_systemd_service
    remove_keybindings
    remove_session_directory
    cleanup_remaining
    show_completion
}

# Execute main function
main "$@"