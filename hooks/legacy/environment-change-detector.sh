#!/usr/bin/env bash

# 🚀 Environment Change Detection Daemon for Hyprland Session Manager
# Real-time monitoring of development environment changes with automatic session saving
# Supports: conda, mamba, venv, pyenv environments

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
MONITOR_PIDS_FILE="${SESSION_DIR}/monitor_pids.txt"
CONFIG_FILE="${SESSION_DIR}/environment-monitor.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
MONITOR_INTERVAL=60
CHANGE_THRESHOLD=2
AUTO_SAVE_ENABLED=true
NOTIFICATION_ENABLED=true
CACHE_ENABLED=true
BATCH_PROCESSING=true
MAX_MONITORS=10

# Logging functions
log_info() {
    echo -e "${BLUE}[ENV-MONITOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[ENV-MONITOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[ENV-MONITOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ENV-MONITOR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# 1. CONFIGURATION MANAGEMENT
# =============================================================================

# Load configuration from file
load_configuration() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        
        # Source the configuration file
        source "$CONFIG_FILE"
        
        # Validate configuration values
        validate_configuration
    else
        log_info "Using default configuration"
        create_default_configuration
    fi
}

# Create default configuration file
create_default_configuration() {
    cat > "$CONFIG_FILE" << 'EOF'
# Environment Change Detection Configuration
# Hyprland Session Manager - Environment Monitor

# Monitoring settings
MONITOR_INTERVAL=60
CHANGE_THRESHOLD=2
AUTO_SAVE_ENABLED=true
NOTIFICATION_ENABLED=true

# Directory monitoring
MONITOR_CONDA=true
MONITOR_MAMBA=true
MONITOR_VENV=true
MONITOR_PYENV=true

# Change triggers
TRIGGER_ENVIRONMENT_CREATION=true
TRIGGER_ENVIRONMENT_DELETION=true
TRIGGER_PACKAGE_INSTALLATION=true
TRIGGER_PACKAGE_UPDATES=false
TRIGGER_ENVIRONMENT_SWITCHES=false

# Performance settings
CACHE_ENABLED=true
BATCH_PROCESSING=true
MAX_MONITORS=10

# Custom directory paths (space-separated)
CUSTOM_PATHS=""
EOF
    log_success "Default configuration created at $CONFIG_FILE"
}

# Validate configuration values
validate_configuration() {
    [[ "$MONITOR_INTERVAL" =~ ^[0-9]+$ ]] || MONITOR_INTERVAL=60
    [[ "$CHANGE_THRESHOLD" =~ ^[0-9]+$ ]] || CHANGE_THRESHOLD=2
    [[ "$AUTO_SAVE_ENABLED" =~ ^(true|false)$ ]] || AUTO_SAVE_ENABLED=true
    [[ "$NOTIFICATION_ENABLED" =~ ^(true|false)$ ]] || NOTIFICATION_ENABLED=true
    [[ "$MAX_MONITORS" =~ ^[0-9]+$ ]] || MAX_MONITORS=10
}

# =============================================================================
# 2. DIRECTORY MONITORING SYSTEM
# =============================================================================

# Get directories to monitor
get_monitor_directories() {
    local watch_dirs=()
    
    # Conda environments
    if [[ "$MONITOR_CONDA" == "true" ]] && command -v conda > /dev/null; then
        local conda_base=$(conda info --base 2>/dev/null)
        if [[ -n "$conda_base" ]]; then
            watch_dirs+=("$conda_base/envs")
            log_info "Monitoring conda environments at: $conda_base/envs"
        fi
    fi
    
    # Mamba environments
    if [[ "$MONITOR_MAMBA" == "true" ]] && command -v mamba > /dev/null; then
        local mamba_base=$(mamba info --base 2>/dev/null)
        if [[ -n "$mamba_base" ]]; then
            watch_dirs+=("$mamba_base/envs")
            log_info "Monitoring mamba environments at: $mamba_base/envs"
        fi
    fi
    
    # Virtual environment locations
    if [[ "$MONITOR_VENV" == "true" ]]; then
        watch_dirs+=(
            "$HOME/.virtualenvs"
            "$HOME/venvs"
            "$HOME/.venvs"
        )
        log_info "Monitoring virtual environments in standard locations"
    fi
    
    # Pyenv versions
    if [[ "$MONITOR_PYENV" == "true" ]] && command -v pyenv > /dev/null; then
        local pyenv_root=$(pyenv root 2>/dev/null)
        if [[ -n "$pyenv_root" ]]; then
            watch_dirs+=("$pyenv_root/versions")
            log_info "Monitoring pyenv versions at: $pyenv_root/versions"
        fi
    fi
    
    # Custom paths
    if [[ -n "$CUSTOM_PATHS" ]]; then
        for custom_path in $CUSTOM_PATHS; do
            if [[ -d "$custom_path" ]]; then
                watch_dirs+=("$custom_path")
                log_info "Monitoring custom path: $custom_path"
            fi
        done
    fi
    
    echo "${watch_dirs[@]}"
}

# Monitor directory using inotify
monitor_directory() {
    local directory="$1"
    
    if [[ ! -d "$directory" ]]; then
        log_warning "Directory does not exist: $directory"
        return 1
    fi
    
    log_info "Starting monitoring for directory: $directory"
    
    # Use inotifywait for real-time monitoring
    inotifywait -m -r -e create,delete,modify,move \
        --format "%w%f %e %T" --timefmt "%Y-%m-%dT%H:%M:%S" \
        "$directory" 2>/dev/null | while read path event time; do
        
        log_info "Directory change detected: $path - $event at $time"
        handle_directory_change "$path" "$event" "$time"
    done &
    
    local monitor_pid=$!
    echo "$monitor_pid" >> "$MONITOR_PIDS_FILE"
    log_success "Started monitoring for $directory (PID: $monitor_pid)"
}

# Handle directory change events
handle_directory_change() {
    local path="$1"
    local event="$2"
    local time="$3"
    
    # Classify the change type
    local change_type=$(classify_directory_change "$path" "$event")
    local impact_score=$(assess_change_impact "$change_type" "$path")
    
    log_info "Change classified as: $change_type (impact: $impact_score)"
    
    # Trigger automatic save if impact is above threshold
    if [[ "$impact_score" -ge "$CHANGE_THRESHOLD" ]]; then
        trigger_automatic_save "$change_type" "$path" "$impact_score"
    fi
    
    # Send notification
    if [[ "$NOTIFICATION_ENABLED" == "true" ]]; then
        send_desktop_notification "Environment Change Detected" \
            "$change_type: $path" "normal"
    fi
}

# Classify directory change events
classify_directory_change() {
    local path="$1"
    local event="$2"
    
    case "$event" in
        "CREATE")
            if [[ "$path" =~ /envs/ ]]; then
                echo "environment_created"
            else
                echo "file_created"
            fi
            ;;
        "DELETE")
            if [[ "$path" =~ /envs/ ]]; then
                echo "environment_deleted"
            else
                echo "file_deleted"
            fi
            ;;
        "MODIFY")
            if [[ "$path" =~ requirements\.txt$ ]] || [[ "$path" =~ environment\.yml$ ]]; then
                echo "dependency_file_modified"
            elif [[ "$path" =~ /bin/ ]] || [[ "$path" =~ /Scripts/ ]]; then
                echo "environment_binary_modified"
            else
                echo "file_modified"
            fi
            ;;
        "MOVED_TO")
            echo "file_moved_in"
            ;;
        "MOVED_FROM")
            echo "file_moved_out"
            ;;
        *)
            echo "unknown_change"
            ;;
    esac
}

# =============================================================================
# 3. CHANGE DETECTION ENGINE
# =============================================================================

# Establish environment baseline
establish_baseline() {
    local baseline_file="${SESSION_STATE_DIR}/environment_baseline.json"
    
    log_info "Establishing environment baseline..."
    
    # Capture current environment state
    capture_environment_snapshot "$baseline_file"
    
    if [[ -f "$baseline_file" ]]; then
        log_success "Environment baseline established at $baseline_file"
        return 0
    else
        log_error "Failed to establish environment baseline"
        return 1
    fi
}

# Capture environment snapshot
capture_environment_snapshot() {
    local snapshot_file="$1"
    
    # Source environment validation functions
    local env_validation_script="$(dirname "$0")/environment-validation.sh"
    if [[ -f "$env_validation_script" ]]; then
        source "$env_validation_script"
        
        # Use environment validation system to capture metadata
        capture_environment_metadata
        
        # Copy the environment metadata to our snapshot file
        if [[ -f "${SESSION_STATE_DIR}/environment_metadata.json" ]]; then
            cp "${SESSION_STATE_DIR}/environment_metadata.json" "$snapshot_file"
        fi
    else
        log_error "Environment validation script not found: $env_validation_script"
        return 1
    fi
}

# Compare environment states
compare_environment_states() {
    local baseline_file="$1"
    local current_file="$2"
    
    if [[ ! -f "$baseline_file" ]] || [[ ! -f "$current_file" ]]; then
        log_error "Missing baseline or current state file"
        return 1
    fi
    
    local changes=()
    
    if command -v jq > /dev/null; then
        # Compare environment lists
        local baseline_envs=$(jq -r '.environments[] | "\(.type):\(.name)"' "$baseline_file" 2>/dev/null | sort)
        local current_envs=$(jq -r '.environments[] | "\(.type):\(.name)"' "$current_file" 2>/dev/null | sort)
        
        # Detect new environments
        local new_envs=$(comm -13 <(echo "$baseline_envs") <(echo "$current_envs"))
        if [[ -n "$new_envs" ]]; then
            while IFS= read -r env; do
                changes+=("environment_created:$env")
            done <<< "$new_envs"
        fi
        
        # Detect removed environments
        local removed_envs=$(comm -23 <(echo "$baseline_envs") <(echo "$current_envs"))
        if [[ -n "$removed_envs" ]]; then
            while IFS= read -r env; do
                changes+=("environment_deleted:$env")
            done <<< "$removed_envs"
        fi
    fi
    
    echo "${changes[@]}"
}

# Perform periodic environment scan
perform_periodic_scan() {
    local baseline_file="${SESSION_STATE_DIR}/environment_baseline.json"
    local current_file="${SESSION_STATE_DIR}/environment_current.json"
    
    log_info "Performing periodic environment scan..."
    
    # Capture current environment state
    capture_environment_snapshot "$current_file"
    
    if [[ ! -f "$baseline_file" ]]; then
        # First run - set baseline
        cp "$current_file" "$baseline_file"
        log_info "Initial environment baseline established"
        return 0
    fi
    
    # Compare baseline with current state
    local changes=$(compare_environment_states "$baseline_file" "$current_file")
    
    if [[ -n "$changes" ]]; then
        log_info "Environment changes detected: $changes"
        
        for change in $changes; do
            IFS=':' read -r change_type change_details <<< "$change"
            local impact_score=$(assess_change_impact "$change_type" "$change_details")
            
            log_info "Processing change: $change_type - $change_details (impact: $impact_score)"
            
            if [[ "$impact_score" -ge "$CHANGE_THRESHOLD" ]]; then
                trigger_automatic_save "$change_type" "$change_details" "$impact_score"
            fi
        done
        
        # Update baseline
        cp "$current_file" "$baseline_file"
        log_success "Environment baseline updated"
    else
        log_info "No environment changes detected in periodic scan"
    fi
}

# =============================================================================
# 4. CHANGE CLASSIFICATION AND IMPACT ASSESSMENT
# =============================================================================

# Assess change impact
assess_change_impact() {
    local change_type="$1"
    local change_details="$2"
    
    local impact_score=0
    
    # High impact changes
    case "$change_type" in
        "environment_created"|"environment_deleted")
            impact_score=3
            ;;
        "core_package_change")
            impact_score=2
            ;;
        "dependency_file_modified")
            impact_score=2
            ;;
        "environment_binary_modified")
            impact_score=1
            ;;
        "file_created"|"file_deleted")
            impact_score=0  # Low impact for regular files
            ;;
        *)
            impact_score=0
            ;;
    esac
    
    # Environment type modifiers
    if [[ "$change_details" =~ conda ]]; then
        impact_score=$((impact_score + 1))
    elif [[ "$change_details" =~ mamba ]]; then
        impact_score=$((impact_score + 1))
    elif [[ "$change_details" =~ pyenv ]]; then
        impact_score=$((impact_score + 1))
    fi
    
    echo "$impact_score"
}

# =============================================================================
# 5. AUTOMATIC SESSION SAVING
# =============================================================================

# Trigger automatic session save
trigger_automatic_save() {
    local change_type="$1"
    local change_details="$2"
    local impact_score="$3"
    
    if [[ "$AUTO_SAVE_ENABLED" != "true" ]]; then
        log_info "Automatic saving disabled - change detected but not saving"
        return 0
    fi
    
    log_info "Triggering automatic session save due to: $change_type"
    
    # Send desktop notification
    if [[ "$NOTIFICATION_ENABLED" == "true" ]]; then
        send_desktop_notification "Environment Change Detected" \
            "Saving session due to: $change_details" \
            "normal"
    fi
    
    # Trigger session save
    local session_manager="${SESSION_DIR}/session-manager.sh"
    if [[ -f "$session_manager" ]]; then
        log_info "Executing session save: $session_manager save"
        "$session_manager" save
        local save_result=$?
        
        if [[ $save_result -eq 0 ]]; then
            log_success "Automatic session save completed successfully"
            send_desktop_notification "Session Saved" \
                "Session automatically saved due to environment changes" \
                "success"
        else
            log_error "Automatic session save failed with exit code: $save_result"
            send_desktop_notification "Session Save Failed" \
                "Failed to automatically save session" \
                "error"
        fi
        
        return $save_result
    else
        log_error "Session manager not found at $session_manager"
        return 1
    fi
}

# =============================================================================
# 6. DESKTOP NOTIFICATION SYSTEM
# =============================================================================

# Send desktop notifications
send_desktop_notification() {
    local title="$1"
    local message="$2"
    local urgency="$3"  # low, normal, critical
    
    if command -v notify-send > /dev/null; then
        notify-send -u "$urgency" -t 5000 \
            "Hyprland Environment Monitor" \
            "$title: $message"
        log_info "Desktop notification sent: $title - $message"
    elif command -v kdialog > /dev/null; then
        kdialog --title "Hyprland Environment Monitor" \
            --msgbox "$title: $message"
        log_info "KDE notification sent: $title - $message"
    else
        log_info "NOTIFICATION: $title - $message"
    fi
}

# =============================================================================
# 7. ERROR HANDLING AND RECOVERY
# =============================================================================

# Cleanup monitoring processes
cleanup_monitoring() {
    log_info "Cleaning up monitoring processes..."
    
    if [[ -f "$MONITOR_PIDS_FILE" ]]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                log_info "Terminated monitoring process: $pid"
            fi
        done < "$MONITOR_PIDS_FILE"
        rm -f "$MONITOR_PIDS_FILE"
    fi
    
    # Remove stop signal file if it exists
    rm -f "${SESSION_DIR}/stop_monitoring"
    
    log_success "Monitoring cleanup completed"
}

# Handle monitoring errors
handle_monitoring_error() {
    local function="$1"
    local error_code="$2"
    
    log_error "Monitoring error in $function (code: $error_code)"
    
    case "$error_code" in
        1)
            log_error "Configuration error in $function"
            send_desktop_notification "Configuration Error" \
                "Monitor configuration issue detected in $function" \
                "critical"
            ;;
        2)
            log_error "Permission error in $function"
            send_desktop_notification "Permission Error" \
                "Insufficient permissions for $function" \
                "critical"
            ;;
        3)
            log_error "Resource error in $function"
            send_desktop_notification "Resource Error" \
                "Resource limit reached in $function" \
                "critical"
            ;;
        *)
            log_error "Unknown error in $function (code: $error_code)"
            send_desktop_notification "Unknown Error" \
                "Unexpected error in $function" \
                "critical"
            ;;
    esac
    
    # Attempt recovery
    attempt_error_recovery "$function" "$error_code"
}

# Error recovery mechanisms
attempt_error_recovery() {
    local function="$1"
    local error_code="$2"
    
    log_info "Attempting recovery for $function (error: $error_code)"
    
    case "$function" in
        "monitor_directory")
            # Restart directory monitoring
            restart_directory_monitoring
            ;;
        "detect_environment_changes")
            # Re-establish baseline
            establish_baseline
            ;;
        "trigger_automatic_save")
            # Retry with backup method
            backup_session_save
            ;;
        *)
            # Generic recovery - restart monitoring
            restart_monitoring_daemon
            ;;
    esac
}

# Restart directory monitoring
restart_directory_monitoring() {
    log_info "Restarting directory monitoring"
    cleanup_monitoring
    sleep 2
    initialize_monitoring
}

# Backup session save method
backup_session_save() {
    log_info "Attempting backup session save method"
    
    # Simple session save without environment validation
    local session_manager="${SESSION_DIR}/session-manager.sh"
    if [[ -f "$session_manager" ]]; then
        # Use basic save functionality
        "$session_manager" save > /dev/null 2>&1
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Backup session save completed"
        else
            log_error "Backup session save failed"
        fi
        
        return $result
    fi
    
    return 1
}

# Health check and self-repair
perform_health_check() {
    local health_issues=()
    
    # Check directory monitors
    if [[ ! -f "$MONITOR_PIDS_FILE" ]]; then
        health_issues+=("monitor_pids_file_missing")
    fi
    
    # Check active processes
    if [[ -f "$MONITOR_PIDS_FILE" ]]; then
        while read -r pid; do
            if ! kill -0 "$pid" 2>/dev/null; then
                health_issues+=("monitor_process_dead:$pid")
            fi
        done < "$MONITOR_PIDS_FILE"
    fi
    
    # Check baseline file
    if [[ ! -f "${SESSION_STATE_DIR}/environment_baseline.json" ]]; then
        health_issues+=("baseline_file_missing")
    fi
    
    # Take recovery action if issues found
    if [[ ${#health_issues[@]} -gt 0 ]]; then
        log_warning "Health check issues detected: ${health_issues[*]}"
        perform_self_repair "${health_issues[@]}"
        return 1
    fi
    
    log_success "Health check passed"
    return 0
}

# Self-repair function
perform_self_repair() {
    local issues=("$@")
    
    log_info "Performing self-repair for issues: ${issues[*]}"
    
    for issue in "${issues[@]}"; do
        case "$issue" in
            "monitor_pids_file_missing"|"monitor_process_dead"*)
                restart_directory_monitoring
                ;;
            "baseline_file_missing")
                establish_baseline
                ;;
        esac
    done
}

# =============================================================================
# 8. MAIN MONITORING LOOP AND INITIALIZATION
# =============================================================================

# Initialize monitoring system
initialize_monitoring() {
    log_info "Initializing environment monitoring system..."
    
    # Create necessary directories
    mkdir -p "$SESSION_DIR" "$SESSION_STATE_DIR"
    
    # Load configuration
    load_configuration
    
    # Establish baseline
    establish_baseline
    
    # Start directory monitoring
    start_directory_monitoring
    
    log_success "Environment monitoring system initialized"
}

# Start directory monitoring
start_directory_monitoring() {
    local watch_dirs=($(get_monitor_directories))
    local monitor_count=0
    
    log_info "Starting directory monitoring for ${#watch_dirs[@]} directories"
    
    for dir in "${watch_dirs[@]}"; do
        if [[ $monitor_count -lt $MAX_MONITORS ]]; then
            if monitor_directory "$dir"; then
                ((monitor_count++))
            fi
        else
            log_warning "Maximum monitor limit reached ($MAX_MONITORS) - skipping $dir"
        fi
    done
    
    log_success "Started monitoring for $monitor_count directories"
}

# Main monitoring loop
main_monitoring_loop() {
    log_info "Starting environment monitoring daemon"
    
    # Initialize monitoring
    initialize_monitoring
    
    # Main monitoring loop
    while true; do
        # Perform periodic health check
        perform_health_check
        
        # Perform periodic environment scan
        perform_periodic_scan
        
        # Wait for next cycle
        sleep "$MONITOR_INTERVAL"
        
        # Check for termination signal
        if [[ -f "${SESSION_DIR}/stop_monitoring" ]]; then
            log_info "Stop signal detected - stopping environment monitoring"
            cleanup_monitoring
            exit 0
        fi
    done
}

# Start monitoring daemon
start_monitoring() {
    log_info "Starting environment change detection daemon"
    
    # Check if already running
    if [[ -f "$MONITOR_PIDS_FILE" ]]; then
        log_warning "Monitoring appears to be already running"
        if [[ "$1" != "--force" ]]; then
            log_info "Use --force to restart monitoring"
            return 1
        fi
        cleanup_monitoring
    fi
    
    # Remove stop signal file if it exists
    rm -f "${SESSION_DIR}/stop_monitoring"
    
    # Start main monitoring loop in background
    main_monitoring_loop &
    local daemon_pid=$!
    
    echo "$daemon_pid" > "${SESSION_DIR}/monitor_daemon.pid"
    log_success "Environment monitoring daemon started (PID: $daemon_pid)"
}

# Stop monitoring daemon
stop_monitoring() {
    log_info "Stopping environment monitoring daemon"
    
    # Create stop signal file
    touch "${SESSION_DIR}/stop_monitoring"
    
    # Wait for graceful shutdown
    sleep 2
    
    # Force cleanup if still running
    cleanup_monitoring
    
    # Remove daemon PID file
    rm -f "${SESSION_DIR}/monitor_daemon.pid"
    
    log_success "Environment monitoring daemon stopped"
}

# Show monitoring status
show_status() {
    log_info "Environment monitoring status:"
    
    if [[ -f "${SESSION_DIR}/monitor_daemon.pid" ]]; then
        local daemon_pid=$(cat "${SESSION_DIR}/monitor_daemon.pid")
        if kill -0 "$daemon_pid" 2>/dev/null; then
            echo "  Monitoring daemon: RUNNING (PID: $daemon_pid)"
        else
            echo "  Monitoring daemon: STOPPED"
        fi
    else
        echo "  Monitoring daemon: STOPPED"
    fi
    
    if [[ -f "$MONITOR_PIDS_FILE" ]]; then
        local monitor_count=$(wc -l < "$MONITOR_PIDS_FILE")
        echo "  Active monitors: $monitor_count"
    else
        echo "  Active monitors: 0"
    fi
    
    if [[ -f "${SESSION_STATE_DIR}/environment_baseline.json" ]]; then
        echo "  Baseline: ESTABLISHED"
        if command -v jq > /dev/null; then
            local env_count=$(jq '.environments | length' "${SESSION_STATE_DIR}/environment_baseline.json" 2>/dev/null || echo "0")
            echo "  Tracked environments: $env_count"
        fi
    else
        echo "  Baseline: NOT ESTABLISHED"
    fi
    
    echo "  Configuration: $CONFIG_FILE"
    echo "  Auto-save: $AUTO_SAVE_ENABLED"
    echo "  Notifications: $NOTIFICATION_ENABLED"
}

# =============================================================================
# 9. COMMAND LINE INTERFACE
# =============================================================================

# Show usage information
show_usage() {
    echo "Usage: $0 {start|stop|status|restart|help} [--force]"
    echo ""
    echo "Environment Change Detection Daemon Commands:"
    echo "  start     - Start environment monitoring daemon"
    echo "  stop      - Stop environment monitoring daemon"
    echo "  status    - Show monitoring status"
    echo "  restart   - Restart monitoring daemon"
    echo "  help      - Show this help message"
    echo ""
    echo "Options:"
    echo "  --force   - Force restart even if already running"
    echo ""
    echo "Features:"
    echo "  • Real-time directory monitoring with inotify"
    echo "  • Automatic session saving on environment changes"
    echo "  • Desktop notifications for detected changes"
    echo "  • Health monitoring and self-recovery"
    echo "  • Configurable change impact thresholds"
    echo ""
    echo "Configuration: $CONFIG_FILE"
}

# Main execution
main() {
    local command="${1:-help}"
    local option="${2:-}"
    
    case "$command" in
        "start")
            start_monitoring "$option"
            ;;
        "stop")
            stop_monitoring
            ;;
        "status")
            show_status
            ;;
        "restart")
            stop_monitoring
            sleep 1
            start_monitoring "$option"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi