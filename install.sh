#!/usr/bin/env zsh

# 🚀 Hyprland Session Manager Installation Script
# Complete installation with dependency checking and configuration

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
SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"

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

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for Hyprland
    if ! command -v hyprctl > /dev/null; then
        log_error "Hyprland not found! Please install Hyprland first."
        exit 1
    fi
    
    # Check for Zsh
    if ! command -v zsh > /dev/null; then
        log_warning "Zsh not found. Installing..."
        if command -v pacman > /dev/null; then
            sudo pacman -S --noconfirm zsh
        elif command -v apt > /dev/null; then
            sudo apt update && sudo apt install -y zsh
        else
            log_error "Cannot install zsh automatically. Please install zsh manually."
            exit 1
        fi
    fi
    
    # Check for jq
    if ! command -v jq > /dev/null; then
        log_warning "jq not found. Installing..."
        if command -v pacman > /dev/null; then
            sudo pacman -S --noconfirm jq
        elif command -v apt > /dev/null; then
            sudo apt update && sudo apt install -y jq
        else
            log_error "Cannot install jq automatically. Please install jq manually."
            exit 1
        fi
    fi
    
    log_success "All dependencies satisfied"
}

# Check if Hyprland is running
check_hyprland_running() {
    if ! pgrep -x "Hyprland" > /dev/null; then
        log_warning "Hyprland is not currently running. Some features may not work until Hyprland is started."
    else
        log_success "Hyprland is running"
    fi
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    
    mkdir -p "$SESSION_DIR"
    mkdir -p "$SESSION_DIR/hooks/pre-save"
    mkdir -p "$SESSION_DIR/hooks/post-restore"
    mkdir -p "$SESSION_DIR/session-state"
    
    log_success "Directory structure created"
}

# Copy files to installation directory
copy_files() {
    log_info "Copying files..."
    
    # Copy main scripts
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/session-manager.sh" "$SESSION_DIR/"
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/session-save.sh" "$SESSION_DIR/"
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/session-restore.sh" "$SESSION_DIR/"
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/detect-hyprland.sh" "$SESSION_DIR/"
    
    # Copy hooks
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/hooks/pre-save/"*.sh "$SESSION_DIR/hooks/pre-save/"
    cp "$SCRIPT_DIR/.config/hyprland-session-manager/hooks/post-restore/"*.sh "$SESSION_DIR/hooks/post-restore/"
    
    # Copy systemd service files
    if [[ -f "$SCRIPT_DIR/.config/hyprland-session-manager/hyprland-session.service" ]]; then
        cp "$SCRIPT_DIR/.config/hyprland-session-manager/hyprland-session.service" "$SESSION_DIR/"
    fi
    
    if [[ -f "$SCRIPT_DIR/.config/hyprland-session-manager/hyprland-session.target" ]]; then
        cp "$SCRIPT_DIR/.config/hyprland-session-manager/hyprland-session.target" "$SESSION_DIR/"
    fi
    
    log_success "Files copied successfully"
}

# Set executable permissions
set_permissions() {
    log_info "Setting executable permissions..."
    
    # Main scripts
    chmod +x "$SESSION_DIR/session-manager.sh"
    chmod +x "$SESSION_DIR/session-save.sh"
    chmod +x "$SESSION_DIR/session-restore.sh"
    chmod +x "$SESSION_DIR/detect-hyprland.sh"
    
    # Hooks
    chmod +x "$SESSION_DIR/hooks/pre-save/"*.sh
    chmod +x "$SESSION_DIR/hooks/post-restore/"*.sh
    
    log_success "Permissions set"
}

# Add keybindings to Hyprland config
add_keybindings() {
    log_info "Adding keybindings to Hyprland config..."
    
    local hyprland_config="$HYPRLAND_CONFIG_DIR/hyprland.conf"
    
    # Check if config file exists
    if [[ ! -f "$hyprland_config" ]]; then
        log_warning "Hyprland config not found at $hyprland_config"
        log_info "Please add the following keybindings manually to your Hyprland config:"
        echo ""
        echo "# Session Manager Keybindings"
        echo "bind = SUPER SHIFT, S, exec, $SESSION_DIR/session-manager.sh save"
        echo "bind = SUPER SHIFT, R, exec, $SESSION_DIR/session-manager.sh restore"
        echo "bind = SUPER SHIFT, C, exec, $SESSION_DIR/session-manager.sh clean"
        echo ""
        return
    fi
    
    # Check if keybindings already exist
    if grep -q "session-manager.sh" "$hyprland_config"; then
        log_info "Session manager keybindings already exist in config"
        return
    fi
    
    # Add keybindings
    echo "" >> "$hyprland_config"
    echo "# Session Manager Keybindings" >> "$hyprland_config"
    echo "bind = SUPER SHIFT, S, exec, $SESSION_DIR/session-manager.sh save" >> "$hyprland_config"
    echo "bind = SUPER SHIFT, R, exec, $SESSION_DIR/session-manager.sh restore" >> "$hyprland_config"
    echo "bind = SUPER SHIFT, C, exec, $SESSION_DIR/session-manager.sh clean" >> "$hyprland_config"
    
    log_success "Keybindings added to Hyprland config"
}

# Setup systemd service (optional)
setup_systemd_service() {
    log_info "Setting up systemd service..."
    
    local systemd_user_dir="${HOME}/.config/systemd/user"
    
    # Create systemd user directory if it doesn't exist
    mkdir -p "$systemd_user_dir"
    
    # Copy service file if it exists
    if [[ -f "$SESSION_DIR/hyprland-session.service" ]]; then
        cp "$SESSION_DIR/hyprland-session.service" "$systemd_user_dir/"
        
        # Reload systemd and enable service
        systemctl --user daemon-reload
        
        log_info "Systemd service installed. To enable automatic session management:"
        echo "  systemctl --user enable hyprland-session.service"
        echo "  systemctl --user start hyprland-session.service"
    else
        log_warning "Systemd service file not found. Manual session management only."
    fi
}

# Test installation
test_installation() {
    log_info "Testing installation..."
    
    # Test if main script runs
    if "$SESSION_DIR/session-manager.sh" status > /dev/null 2>&1; then
        log_success "Installation test passed"
    else
        log_warning "Installation test had issues - please check manually"
    fi
}

# Display completion message
show_completion() {
    echo ""
    echo "=========================================="
    echo "🎉 Hyprland Session Manager Installed!"
    echo "=========================================="
    echo ""
    echo "📁 Installation Directory: $SESSION_DIR"
    echo ""
    echo "🎮 Usage:"
    echo "  Save session:    $SESSION_DIR/session-manager.sh save"
    echo "  Restore session: $SESSION_DIR/session-manager.sh restore"
    echo "  Clean session:   $SESSION_DIR/session-manager.sh clean"
    echo ""
    echo "⌨️  Keybindings (added to Hyprland config):"
    echo "  SUPER SHIFT + S - Save session"
    echo "  SUPER SHIFT + R - Restore session"
    echo "  SUPER SHIFT + C - Clean session state"
    echo ""
    echo "🔧 Optional Systemd Service:"
    echo "  systemctl --user enable hyprland-session.service"
    echo "  systemctl --user start hyprland-session.service"
    echo ""
    echo "📚 Documentation: See README.md for detailed usage"
    echo ""
}

# Main installation function
main() {
    echo "🚀 Hyprland Session Manager Installation"
    echo "========================================"
    echo ""
    
    check_user
    check_dependencies
    check_hyprland_running
    create_directories
    copy_files
    set_permissions
    add_keybindings
    setup_systemd_service
    test_installation
    show_completion
}

# Execute main function
main "$@"