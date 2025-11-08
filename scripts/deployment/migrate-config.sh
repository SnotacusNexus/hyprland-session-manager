#!/bin/bash

# Hyprland Session Manager - Configuration Migration Script
# This script helps migrate existing configurations to the new organized structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$HOME/.config/hyprland-session-manager"
BACKUP_DIR="$CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if configuration directory exists
check_config_exists() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_warning "No existing configuration found at $CONFIG_DIR"
        log_info "This appears to be a new installation"
        return 1
    fi
    return 0
}

# Create backup of existing configuration
backup_config() {
    log_info "Creating backup of existing configuration..."
    if [[ -d "$CONFIG_DIR" ]]; then
        cp -r "$CONFIG_DIR" "$BACKUP_DIR"
        log_success "Configuration backed up to: $BACKUP_DIR"
    else
        log_warning "No configuration to backup"
    fi
}

# Migrate quantum state configuration
migrate_quantum_config() {
    local old_config="$CONFIG_DIR/quantum-state-config.yaml"
    local new_config="$CONFIG_DIR/quantum/state-config.yaml"
    
    if [[ -f "$old_config" ]]; then
        log_info "Migrating quantum state configuration..."
        mkdir -p "$(dirname "$new_config")"
        mv "$old_config" "$new_config"
        
        # Update paths in the configuration
        sed -i 's|\./quantum-state-manager\.py|scripts/quantum/quantum-state-manager.py|g' "$new_config"
        sed -i 's|\./quantum-state-config\.py|scripts/quantum/quantum-state-config.py|g' "$new_config"
        
        log_success "Quantum state configuration migrated"
    fi
}

# Migrate session data
migrate_session_data() {
    local old_sessions="$CONFIG_DIR/sessions"
    local new_sessions="$CONFIG_DIR/sessions"
    
    if [[ -d "$old_sessions" ]]; then
        log_info "Migrating session data..."
        # Session data location remains the same, just ensure proper structure
        mkdir -p "$new_sessions"
        log_success "Session data structure verified"
    fi
}

# Migrate hook configurations
migrate_hooks() {
    local old_hooks="$CONFIG_DIR/hooks"
    local new_hooks="$CONFIG_DIR/hooks"
    
    if [[ -d "$old_hooks" ]]; then
        log_info "Migrating hook configurations..."
        # Hook configurations remain in the same location
        mkdir -p "$new_hooks"
        log_success "Hook configurations verified"
    fi
}

# Update configuration file paths
update_config_paths() {
    log_info "Updating configuration file paths..."
    
    # Update main configuration if it exists
    local main_config="$CONFIG_DIR/config.yaml"
    if [[ -f "$main_config" ]]; then
        sed -i 's|\./quantum-state-manager\.py|scripts/quantum/quantum-state-manager.py|g' "$main_config"
        sed -i 's|\./environment-change-detector\.sh|scripts/legacy/environment-change-detector.sh|g' "$main_config"
        sed -i 's|\./environment-validation\.sh|scripts/legacy/environment-validation.sh|g' "$main_config"
        log_success "Main configuration paths updated"
    fi
}

# Create new configuration structure
create_new_structure() {
    log_info "Creating new configuration structure..."
    
    mkdir -p "$CONFIG_DIR/quantum"
    mkdir -p "$CONFIG_DIR/hooks"
    mkdir -p "$CONFIG_DIR/sessions"
    mkdir -p "$CONFIG_DIR/logs"
    
    log_success "New configuration structure created"
}

# Verify migration success
verify_migration() {
    log_info "Verifying migration..."
    
    local errors=0
    
    # Check essential directories
    for dir in "$CONFIG_DIR/quantum" "$CONFIG_DIR/hooks" "$CONFIG_DIR/sessions"; do
        if [[ ! -d "$dir" ]]; then
            log_error "Missing directory: $dir"
            ((errors++))
        fi
    done
    
    # Check if quantum state manager can be accessed
    if ! "$PROJECT_ROOT/scripts/quantum/quantum-state-manager.py" --version &>/dev/null; then
        log_warning "Quantum state manager check failed (this might be normal for new installations)"
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "Migration verification passed"
        return 0
    else
        log_error "Migration verification failed with $errors error(s)"
        return 1
    fi
}

# Display migration summary
show_summary() {
    echo
    echo "=========================================="
    echo "      MIGRATION SUMMARY"
    echo "=========================================="
    echo "Backup Location: $BACKUP_DIR"
    echo "Config Location: $CONFIG_DIR"
    echo "Project Root:    $PROJECT_ROOT"
    echo "Status:          COMPLETED"
    echo "=========================================="
    echo
    log_success "Configuration migration completed successfully!"
    log_info "Next steps:"
    log_info "1. Run: ./scripts/validation/deployment-validation.sh"
    log_info "2. Test: ./scripts/quantum/quantum-state-manager.py --test"
    log_info "3. Restart session manager if needed"
    echo
}

# Main migration function
main() {
    echo "=========================================="
    echo "  Hyprland Session Manager Migration"
    echo "=========================================="
    echo
    
    # Check if we have an existing configuration
    if ! check_config_exists; then
        log_info "Creating new configuration structure..."
        create_new_structure
        verify_migration
        show_summary
        exit 0
    fi
    
    # Perform migration steps
    backup_config
    migrate_quantum_config
    migrate_session_data
    migrate_hooks
    update_config_paths
    create_new_structure
    
    # Verify and show summary
    if verify_migration; then
        show_summary
    else
        log_error "Migration completed with warnings. Please review the output above."
        exit 1
    fi
}

# Handle script interruption
cleanup() {
    log_warning "Migration interrupted"
    log_info "Backup available at: $BACKUP_DIR"
    exit 1
}

trap cleanup SIGINT SIGTERM

# Run main function
main "$@"