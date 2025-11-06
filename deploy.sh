#!/usr/bin/env zsh

# Hyprland Session Manager Deployment Script
# Complete deployment to user's home directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DEPLOY SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DEPLOY WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[DEPLOY ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if running as correct user
check_user() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
    
    log_success "Running as user: $(whoami)"
}

# Backup existing configuration
backup_existing() {
    local target_dir="${HOME}/.config/hyprland-session-manager"
    
    if [[ -d "$target_dir" ]]; then
        local backup_dir="${target_dir}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing configuration to: $backup_dir"
        cp -r "$target_dir" "$backup_dir"
        log_success "Backup created: $backup_dir"
    fi
}

# Deploy configuration files
deploy_files() {
    log_info "Deploying configuration files..."
    
    local source_dir="$SCRIPT_DIR/.config/hyprland-session-manager"
    local target_dir="${HOME}/.config/hyprland-session-manager"
    
    # Create target directory structure
    mkdir -p "$target_dir/hooks/pre-save"
    mkdir -p "$target_dir/hooks/post-restore"
    mkdir -p "$target_dir/session-state"
    
    # Copy main scripts
    cp "$source_dir/session-manager.sh" "$target_dir/"
    cp "$source_dir/session-save.sh" "$target_dir/"
    cp "$source_dir/session-restore.sh" "$target_dir/"
    
    # Copy systemd files
    cp "$source_dir/hyprland-session.service" "$target_dir/"
    cp "$source_dir/hyprland-session.target" "$target_dir/"
    
    # Copy example hooks
    cp "$source_dir/hooks/pre-save/example-pre-save.sh" "$target_dir/hooks/pre-save/"
    cp "$source_dir/hooks/post-restore/example-post-restore.sh" "$target_dir/hooks/post-restore/"
    
    log_success "Configuration files deployed"
}

# Set file permissions
set_permissions() {
    log_info "Setting file permissions..."
    
    local target_dir="${HOME}/.config/hyprland-session-manager"
    
    # Make scripts executable
    chmod +x "$target_dir/session-manager.sh"
    chmod +x "$target_dir/session-save.sh"
    chmod +x "$target_dir/session-restore.sh"
    
    # Make example hooks executable
    chmod +x "$target_dir/hooks/pre-save/example-pre-save.sh"
    chmod +x "$target_dir/hooks/post-restore/example-post-restore.sh"
    
    # Ensure proper ownership
    chown -R "$(whoami):$(whoami)" "$target_dir"
    
    log_success "File permissions set"
}

# Setup systemd services
setup_systemd() {
    log_info "Setting up systemd services..."
    
    local systemd_user_dir="${HOME}/.config/systemd/user"
    local source_dir="${HOME}/.config/hyprland-session-manager"
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$systemd_user_dir"
    
    # Copy service files to systemd directory
    cp "$source_dir/hyprland-session.service" "$systemd_user_dir/"
    cp "$source_dir/hyprland-session.target" "$systemd_user_dir/"
    
    # Reload systemd and enable services
    systemctl --user daemon-reload
    systemctl --user enable hyprland-session.service
    systemctl --user enable hyprland-session.target
    
    log_success "Systemd services configured and enabled"
}

# Add Hyprland keybindings
add_hyprland_keybindings() {
    log_info "Adding Hyprland keybindings..."
    
    local hyprland_conf="${HOME}/.config/hypr/hyprland.conf"
    local keybindings="\n# Hyprland Session Manager Keybindings
bind = $mainMod SHIFT, S, exec, ~/.config/hyprland-session-manager/session-manager.sh save
bind = $mainMod SHIFT, R, exec, ~/.config/hyprland-session-manager/session-manager.sh restore
bind = $mainMod SHIFT, C, exec, ~/.config/hyprland-session-manager/session-manager.sh clean"
    
    # Check if Hyprland config exists
    if [[ ! -f "$hyprland_conf" ]]; then
        log_warning "Hyprland configuration not found at $hyprland_conf"
        log_info "Please add the keybindings manually to your Hyprland config:"
        echo "$keybindings"
        return
    fi
    
    # Check if keybindings already exist
    if grep -q "Hyprland Session Manager Keybindings" "$hyprland_conf"; then
        log_info "Session manager keybindings already exist in Hyprland config"
        return
    fi
    
    # Append keybindings to config
    echo "$keybindings" >> "$hyprland_conf"
    
    log_success "Hyprland keybindings added"
}

# Run post-deployment test
run_post_deploy_test() {
    log_info "Running post-deployment test..."
    
    local script_dir="${HOME}/.config/hyprland-session-manager"
    
    # Test script execution
    if "$script_dir/session-manager.sh" --help > /dev/null 2>&1; then
        log_success "Session manager script test passed"
    else
        log_error "Session manager script test failed"
        return 1
    fi
    
    # Test systemd service
    if systemctl --user is-enabled hyprland-session.service > /dev/null 2>&1; then
        log_success "Systemd service test passed"
    else
        log_error "Systemd service test failed"
        return 1
    fi
    
    log_success "Post-deployment test completed successfully"
    return 0
}

# Show deployment summary
show_summary() {
    echo ""
    echo -e "${GREEN}🎉 Hyprland Session Manager Deployment Complete!${NC}"
    echo ""
    echo "Deployment Summary:"
    echo "✓ Configuration files deployed to: ${HOME}/.config/hyprland-session-manager"
    echo "✓ Systemd services enabled and configured"
    echo "✓ Hyprland keybindings added"
    echo "✓ File permissions set"
    echo ""
    echo "Next Steps:"
    echo "1. Restart Hyprland to load the new keybindings"
    echo "2. Test manual session save: $mainMod + SHIFT + S"
    echo "3. Test manual session restore: $mainMod + SHIFT + R"
    echo "4. Reboot to test automatic session management"
    echo "5. Customize hooks for your specific applications"
    echo ""
    echo "Available Commands:"
    echo "  ~/.config/hyprland-session-manager/session-manager.sh save"
    echo "  ~/.config/hyprland-session-manager/session-manager.sh restore"
    echo "  ~/.config/hyprland-session-manager/session-manager.sh clean"
    echo "  ~/.config/hyprland-session-manager/session-manager.sh status"
    echo ""
    echo "Configuration Directory: ${HOME}/.config/hyprland-session-manager"
    echo "Session State Directory: ${HOME}/.config/hyprland-session-manager/session-state"
    echo "Hook Directories: ${HOME}/.config/hyprland-session-manager/hooks/{pre-save,post-restore}"
    echo ""
}

# Main deployment function
main() {
    log_info "Starting Hyprland Session Manager deployment..."
    
    check_user
    backup_existing
    deploy_files
    set_permissions
    setup_systemd
    add_hyprland_keybindings
    
    if run_post_deploy_test; then
        show_summary
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment completed with errors - please check the output above"
        exit 1
    fi
}

# Execute main function
main "$@"