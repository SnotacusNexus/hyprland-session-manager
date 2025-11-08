#!/usr/bin/env bash

# 🔧 Environment Change Detection Configuration Management
# Centralized configuration system for environment monitoring and automatic session saving

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
CONFIG_DIR="${SESSION_DIR}/config"
DEFAULT_CONFIG_FILE="${CONFIG_DIR}/environment-monitor.conf"
USER_CONFIG_FILE="${HOME}/.config/hyprland-session-manager/environment-monitor.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[CONFIG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CONFIG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CONFIG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[CONFIG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# CONFIGURATION MANAGEMENT FUNCTIONS
# =============================================================================

# Initialize configuration system
initialize_config_system() {
    log_info "Initializing configuration system..."
    
    # Create configuration directory
    mkdir -p "$CONFIG_DIR"
    
    # Create default configuration if it doesn't exist
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        create_default_configuration
    fi
    
    # Create user configuration if it doesn't exist
    if [[ ! -f "$USER_CONFIG_FILE" ]]; then
        create_user_configuration
    fi
    
    log_success "Configuration system initialized"
}

# Create default configuration
create_default_configuration() {
    log_info "Creating default configuration..."
    
    cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
# 🛡️ Environment Change Detection Configuration
# Default configuration for environment monitoring and automatic session saving

# =============================================================================
# MONITORING SETTINGS
# =============================================================================

# Monitoring interval in seconds
MONITOR_INTERVAL=30

# Change detection threshold (number of changes before triggering)
CHANGE_THRESHOLD=3

# Enable automatic session saving
AUTO_SAVE_ENABLED=true

# Enable desktop notifications
NOTIFICATION_ENABLED=true

# Notification urgency level (low, normal, critical)
NOTIFICATION_URGENCY=normal

# =============================================================================
# DIRECTORY MONITORING
# =============================================================================

# Monitor conda environments
MONITOR_CONDA=true

# Monitor mamba environments
MONITOR_MAMBA=true

# Monitor virtual environments (venv)
MONITOR_VENV=true

# Monitor pyenv environments
MONITOR_PYENV=true

# Monitor custom directory paths (space-separated)
CUSTOM_PATHS=""

# =============================================================================
# CHANGE TRIGGERS
# =============================================================================

# Trigger on environment creation
TRIGGER_ENVIRONMENT_CREATION=true

# Trigger on environment deletion
TRIGGER_ENVIRONMENT_DELETION=true

# Trigger on package installation
TRIGGER_PACKAGE_INSTALLATION=true

# Trigger on package updates
TRIGGER_PACKAGE_UPDATES=true

# Trigger on environment switches
TRIGGER_ENVIRONMENT_SWITCHES=true

# =============================================================================
# IMPACT CLASSIFICATION
# =============================================================================

# High impact threshold (triggers immediate save)
HIGH_IMPACT_THRESHOLD=10

# Medium impact threshold (triggers save after delay)
MEDIUM_IMPACT_THRESHOLD=5

# Low impact threshold (triggers save only if accumulation)
LOW_IMPACT_THRESHOLD=2

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

# Enable caching for performance
CACHE_ENABLED=true

# Enable batch processing of changes
BATCH_PROCESSING=true

# Maximum number of concurrent monitors
MAX_MONITORS=10

# Cache TTL in seconds
CACHE_TTL=300

# =============================================================================
# ERROR HANDLING
# =============================================================================

# Enable automatic error recovery
AUTO_RECOVERY_ENABLED=true

# Maximum retry attempts
MAX_RETRY_ATTEMPTS=3

# Retry delay in seconds
RETRY_DELAY=5

# Health check interval in seconds
HEALTH_CHECK_INTERVAL=60

# =============================================================================
# LOGGING SETTINGS
# =============================================================================

# Enable detailed logging
DETAILED_LOGGING=false

# Log file path
LOG_FILE="${SESSION_DIR}/logs/environment-monitor.log"

# Maximum log file size in MB
MAX_LOG_SIZE=10

# =============================================================================
# ADVANCED SETTINGS
# =============================================================================

# Enable experimental features
EXPERIMENTAL_FEATURES=false

# Debug mode (verbose output)
DEBUG_MODE=false

# Monitor system-wide changes
MONITOR_SYSTEM_WIDE=false

# Custom environment detection scripts
CUSTOM_DETECTION_SCRIPTS=""
EOF
    
    log_success "Default configuration created at: $DEFAULT_CONFIG_FILE"
}

# Create user configuration
create_user_configuration() {
    log_info "Creating user configuration..."
    
    # Copy default configuration to user location
    cp "$DEFAULT_CONFIG_FILE" "$USER_CONFIG_FILE"
    
    log_success "User configuration created at: $USER_CONFIG_FILE"
    log_info "Edit $USER_CONFIG_FILE to customize settings"
}

# Load configuration
load_configuration() {
    local config_file="${1:-$USER_CONFIG_FILE}"
    
    # Use default config if user config doesn't exist
    if [[ ! -f "$config_file" ]]; then
        config_file="$DEFAULT_CONFIG_FILE"
    fi
    
    # Source the configuration file
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        log_success "Configuration loaded from: $config_file"
        return 0
    else
        log_error "Configuration file not found: $config_file"
        return 1
    fi
}

# Validate configuration
validate_configuration() {
    log_info "Validating configuration..."
    
    local errors=0
    
    # Check required variables
    local required_vars=(
        "MONITOR_INTERVAL"
        "CHANGE_THRESHOLD"
        "AUTO_SAVE_ENABLED"
        "NOTIFICATION_ENABLED"
        "HIGH_IMPACT_THRESHOLD"
        "MEDIUM_IMPACT_THRESHOLD"
        "LOW_IMPACT_THRESHOLD"
        "MAX_MONITORS"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            log_error "Required configuration variable not set: $var"
            ((errors++))
        fi
    done
    
    # Validate numeric values
    if [[ ! "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] || [[ "$MONITOR_INTERVAL" -lt 1 ]]; then
        log_error "MONITOR_INTERVAL must be a positive integer"
        ((errors++))
    fi
    
    if [[ ! "$CHANGE_THRESHOLD" =~ ^[0-9]+$ ]] || [[ "$CHANGE_THRESHOLD" -lt 1 ]]; then
        log_error "CHANGE_THRESHOLD must be a positive integer"
        ((errors++))
    fi
    
    if [[ ! "$MAX_MONITORS" =~ ^[0-9]+$ ]] || [[ "$MAX_MONITORS" -lt 1 ]]; then
        log_error "MAX_MONITORS must be a positive integer"
        ((errors++))
    fi
    
    # Validate boolean values
    local boolean_vars=(
        "AUTO_SAVE_ENABLED"
        "NOTIFICATION_ENABLED"
        "MONITOR_CONDA"
        "MONITOR_MAMBA"
        "MONITOR_VENV"
        "MONITOR_PYENV"
        "TRIGGER_ENVIRONMENT_CREATION"
        "TRIGGER_ENVIRONMENT_DELETION"
        "TRIGGER_PACKAGE_INSTALLATION"
        "TRIGGER_PACKAGE_UPDATES"
        "TRIGGER_ENVIRONMENT_SWITCHES"
        "CACHE_ENABLED"
        "BATCH_PROCESSING"
        "AUTO_RECOVERY_ENABLED"
        "DETAILED_LOGGING"
        "EXPERIMENTAL_FEATURES"
        "DEBUG_MODE"
        "MONITOR_SYSTEM_WIDE"
    )
    
    for var in "${boolean_vars[@]}"; do
        if [[ -n "${!var}" ]] && [[ "${!var}" != "true" ]] && [[ "${!var}" != "false" ]]; then
            log_error "Boolean variable $var must be 'true' or 'false'"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "Configuration validation passed"
        return 0
    else
        log_error "Configuration validation failed with $errors error(s)"
        return 1
    fi
}

# Show current configuration
show_configuration() {
    log_info "Current Configuration:"
    
    echo ""
    echo "=== MONITORING SETTINGS ==="
    echo "MONITOR_INTERVAL: $MONITOR_INTERVAL"
    echo "CHANGE_THRESHOLD: $CHANGE_THRESHOLD"
    echo "AUTO_SAVE_ENABLED: $AUTO_SAVE_ENABLED"
    echo "NOTIFICATION_ENABLED: $NOTIFICATION_ENABLED"
    echo "NOTIFICATION_URGENCY: $NOTIFICATION_URGENCY"
    
    echo ""
    echo "=== DIRECTORY MONITORING ==="
    echo "MONITOR_CONDA: $MONITOR_CONDA"
    echo "MONITOR_MAMBA: $MONITOR_MAMBA"
    echo "MONITOR_VENV: $MONITOR_VENV"
    echo "MONITOR_PYENV: $MONITOR_PYENV"
    echo "CUSTOM_PATHS: $CUSTOM_PATHS"
    
    echo ""
    echo "=== CHANGE TRIGGERS ==="
    echo "TRIGGER_ENVIRONMENT_CREATION: $TRIGGER_ENVIRONMENT_CREATION"
    echo "TRIGGER_ENVIRONMENT_DELETION: $TRIGGER_ENVIRONMENT_DELETION"
    echo "TRIGGER_PACKAGE_INSTALLATION: $TRIGGER_PACKAGE_INSTALLATION"
    echo "TRIGGER_PACKAGE_UPDATES: $TRIGGER_PACKAGE_UPDATES"
    echo "TRIGGER_ENVIRONMENT_SWITCHES: $TRIGGER_ENVIRONMENT_SWITCHES"
    
    echo ""
    echo "=== IMPACT CLASSIFICATION ==="
    echo "HIGH_IMPACT_THRESHOLD: $HIGH_IMPACT_THRESHOLD"
    echo "MEDIUM_IMPACT_THRESHOLD: $MEDIUM_IMPACT_THRESHOLD"
    echo "LOW_IMPACT_THRESHOLD: $LOW_IMPACT_THRESHOLD"
    
    echo ""
    echo "=== PERFORMANCE SETTINGS ==="
    echo "CACHE_ENABLED: $CACHE_ENABLED"
    echo "BATCH_PROCESSING: $BATCH_PROCESSING"
    echo "MAX_MONITORS: $MAX_MONITORS"
    echo "CACHE_TTL: $CACHE_TTL"
    
    echo ""
    echo "=== ERROR HANDLING ==="
    echo "AUTO_RECOVERY_ENABLED: $AUTO_RECOVERY_ENABLED"
    echo "MAX_RETRY_ATTEMPTS: $MAX_RETRY_ATTEMPTS"
    echo "RETRY_DELAY: $RETRY_DELAY"
    echo "HEALTH_CHECK_INTERVAL: $HEALTH_CHECK_INTERVAL"
    
    echo ""
    echo "=== LOGGING SETTINGS ==="
    echo "DETAILED_LOGGING: $DETAILED_LOGGING"
    echo "LOG_FILE: $LOG_FILE"
    echo "MAX_LOG_SIZE: $MAX_LOG_SIZE"
    
    echo ""
    echo "=== ADVANCED SETTINGS ==="
    echo "EXPERIMENTAL_FEATURES: $EXPERIMENTAL_FEATURES"
    echo "DEBUG_MODE: $DEBUG_MODE"
    echo "MONITOR_SYSTEM_WIDE: $MONITOR_SYSTEM_WIDE"
    echo "CUSTOM_DETECTION_SCRIPTS: $CUSTOM_DETECTION_SCRIPTS"
}

# Update configuration value
update_config_value() {
    local key="$1"
    local value="$2"
    local config_file="${3:-$USER_CONFIG_FILE}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check if key exists in configuration
    if grep -q "^$key=" "$config_file"; then
        # Update existing key
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
        log_success "Updated configuration: $key=$value"
    else
        # Add new key
        echo "$key=$value" >> "$config_file"
        log_success "Added configuration: $key=$value"
    fi
    
    # Validate the updated configuration
    if load_configuration "$config_file" && validate_configuration; then
        log_success "Configuration update validated successfully"
        return 0
    else
        log_error "Configuration update validation failed"
        return 1
    fi
}

# Reset configuration to defaults
reset_configuration() {
    local config_file="${1:-$USER_CONFIG_FILE}"
    
    log_info "Resetting configuration to defaults..."
    
    # Remove existing user configuration
    rm -f "$config_file"
    
    # Create new user configuration from defaults
    create_user_configuration
    
    log_success "Configuration reset to defaults"
}

# Export configuration for other scripts
export_configuration() {
    local config_file="${1:-$USER_CONFIG_FILE}"
    
    if load_configuration "$config_file"; then
        # Export all configuration variables
        export MONITOR_INTERVAL CHANGE_THRESHOLD AUTO_SAVE_ENABLED NOTIFICATION_ENABLED
        export MONITOR_CONDA MONITOR_MAMBA MONITOR_VENV MONITOR_PYENV CUSTOM_PATHS
        export TRIGGER_ENVIRONMENT_CREATION TRIGGER_ENVIRONMENT_DELETION
        export TRIGGER_PACKAGE_INSTALLATION TRIGGER_PACKAGE_UPDATES TRIGGER_ENVIRONMENT_SWITCHES
        export HIGH_IMPACT_THRESHOLD MEDIUM_IMPACT_THRESHOLD LOW_IMPACT_THRESHOLD
        export CACHE_ENABLED BATCH_PROCESSING MAX_MONITORS CACHE_TTL
        export AUTO_RECOVERY_ENABLED MAX_RETRY_ATTEMPTS RETRY_DELAY HEALTH_CHECK_INTERVAL
        export DETAILED_LOGGING LOG_FILE MAX_LOG_SIZE
        export EXPERIMENTAL_FEATURES DEBUG_MODE MONITOR_SYSTEM_WIDE CUSTOM_DETECTION_SCRIPTS
        
        log_success "Configuration exported successfully"
        return 0
    else
        log_error "Failed to export configuration"
        return 1
    fi
}

# =============================================================================
# CONFIGURATION UTILITIES
# =============================================================================

# Get configuration value
get_config_value() {
    local key="$1"
    local config_file="${2:-$USER_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        # Source the file temporarily to get the value
        local value
        value=$(source "$config_file" && echo "${!key}")
        echo "$value"
        return 0
    else
        log_error "Configuration file not found: $config_file"
        return 1
    fi
}

# List all configuration keys
list_config_keys() {
    local config_file="${1:-$USER_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        # Extract all variable names (excluding comments and empty lines)
        grep -E '^[A-Z_]+=' "$config_file" | cut -d'=' -f1 | sort
    else
        log_error "Configuration file not found: $config_file"
        return 1
    fi
}

# Compare configurations
compare_configurations() {
    local config1="${1:-$DEFAULT_CONFIG_FILE}"
    local config2="${2:-$USER_CONFIG_FILE}"
    
    log_info "Comparing configurations:"
    echo "  Default: $config1"
    echo "  User:    $config2"
    
    if [[ ! -f "$config1" ]] || [[ ! -f "$config2" ]]; then
        log_error "One or both configuration files not found"
        return 1
    fi
    
    # Use diff to compare files
    diff -u "$config1" "$config2" || true
}

# =============================================================================
# MAIN COMMAND HANDLER
# =============================================================================

# Show usage information
show_usage() {
    echo "Usage: $0 {init|show|validate|update|reset|export|get|list|compare|help}"
    echo ""
    echo "Environment Change Detection Configuration Management Commands:"
    echo "  init     - Initialize configuration system"
    echo "  show     - Show current configuration"
    echo "  validate - Validate current configuration"
    echo "  update   - Update configuration value (key value [file])"
    echo "  reset    - Reset configuration to defaults"
    echo "  export   - Export configuration for other scripts"
    echo "  get      - Get specific configuration value (key [file])"
    echo "  list     - List all configuration keys"
    echo "  compare  - Compare default and user configurations"
    echo "  help     - Show this help message"
    echo ""
    echo "Configuration Files:"
    echo "  Default: $DEFAULT_CONFIG_FILE"
    echo "  User:    $USER_CONFIG_FILE"
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            initialize_config_system
            ;;
        "show")
            load_configuration && show_configuration
            ;;
        "validate")
            load_configuration && validate_configuration
            ;;
        "update")
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                log_error "Usage: $0 update <key> <value> [config_file]"
                return 1
            fi
            update_config_value "$2" "$3" "$4"
            ;;
        "reset")
            reset_configuration "$2"
            ;;
        "export")
            export_configuration "$2"
            ;;
        "get")
            if [[ -z "$2" ]]; then
                log_error "Usage: $0 get <key> [config_file]"
                return 1
            fi
            get_config_value "$2" "$3"
            ;;
        "list")
            list_config_keys "$2"
            ;;
        "compare")
            compare_configurations "$2" "$3"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi