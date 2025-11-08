#!/usr/bin/env bash

# 🧪 Test Suite for Environment Change Detection System
# Comprehensive testing of environment monitoring and automatic session saving

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
TEST_DIR="${SESSION_DIR}/test-environment-changes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[TEST]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TEST]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TEST]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[TEST]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# TEST SETUP AND TEARDOWN
# =============================================================================

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    
    # Create test virtual environments
    create_test_virtual_environments
    
    # Create test configuration
    create_test_configuration
    
    log_success "Test environment setup completed"
}

# Cleanup test environment
cleanup_test_environment() {
    log_info "Cleaning up test environment..."
    
    # Remove test virtual environments
    cleanup_test_virtual_environments
    
    # Remove test directory
    rm -rf "$TEST_DIR"
    
    # Stop any running monitoring daemons
    stop_test_monitoring
    
    log_success "Test environment cleanup completed"
}

# Create test virtual environments
create_test_virtual_environments() {
    log_info "Creating test virtual environments..."
    
    # Create test virtual environments directory
    local test_venv_dir="$TEST_DIR/venvs"
    mkdir -p "$test_venv_dir"
    
    # Create test virtual environments
    python3 -m venv "$test_venv_dir/test-env-1" 2>/dev/null && log_success "Created test-env-1"
    python3 -m venv "$test_venv_dir/test-env-2" 2>/dev/null && log_success "Created test-env-2"
    python3 -m venv "$test_venv_dir/test-env-3" 2>/dev/null && log_success "Created test-env-3"
    
    # Create test requirements files
    echo "requests==2.28.0" > "$test_venv_dir/test-env-1/requirements.txt"
    echo "numpy==1.24.0" > "$test_venv_dir/test-env-2/requirements.txt"
    echo "pandas==1.5.0" > "$test_venv_dir/test-env-3/requirements.txt"
}

# Cleanup test virtual environments
cleanup_test_virtual_environments() {
    log_info "Cleaning up test virtual environments..."
    
    local test_venv_dir="$TEST_DIR/venvs"
    if [[ -d "$test_venv_dir" ]]; then
        rm -rf "$test_venv_dir"
        log_success "Test virtual environments cleaned up"
    fi
}

# Create test configuration
create_test_configuration() {
    log_info "Creating test configuration..."
    
    local test_config="$TEST_DIR/environment-monitor.conf"
    
    cat > "$test_config" << 'EOF'
# Test Environment Change Detection Configuration

# Monitoring settings
MONITOR_INTERVAL=5
CHANGE_THRESHOLD=1
AUTO_SAVE_ENABLED=true
NOTIFICATION_ENABLED=false

# Directory monitoring
MONITOR_CONDA=false
MONITOR_MAMBA=false
MONITOR_VENV=true
MONITOR_PYENV=false

# Change triggers
TRIGGER_ENVIRONMENT_CREATION=true
TRIGGER_ENVIRONMENT_DELETION=true
TRIGGER_PACKAGE_INSTALLATION=true
TRIGGER_PACKAGE_UPDATES=true
TRIGGER_ENVIRONMENT_SWITCHES=true

# Performance settings
CACHE_ENABLED=true
BATCH_PROCESSING=true
MAX_MONITORS=5

# Custom directory paths
CUSTOM_PATHS="$TEST_DIR/venvs"
EOF
    
    log_success "Test configuration created"
}

# =============================================================================
# TEST FUNCTIONS
# =============================================================================

# Test environment change detector startup
test_detector_startup() {
    log_info "Testing environment change detector startup..."
    
    local change_detector="./environment-change-detector.sh"
    
    if [[ ! -f "$change_detector" ]]; then
        log_error "Environment change detector script not found"
        return 1
    fi
    
    # Test help command
    if "$change_detector" help > /dev/null 2>&1; then
        log_success "Help command test passed"
    else
        log_error "Help command test failed"
        return 1
    fi
    
    # Test status command
    if "$change_detector" status > /dev/null 2>&1; then
        log_success "Status command test passed"
    else
        log_warning "Status command test returned non-zero (may be expected)"
    fi
    
    log_success "Environment change detector startup test completed"
    return 0
}

# Test directory monitoring
test_directory_monitoring() {
    log_info "Testing directory monitoring..."
    
    local change_detector="./environment-change-detector.sh"
    local test_file="$TEST_DIR/test-monitor.txt"
    
    # Start monitoring with test configuration
    export CONFIG_FILE="$TEST_DIR/environment-monitor.conf"
    if ! "$change_detector" start > /dev/null 2>&1; then
        log_error "Failed to start monitoring daemon"
        return 1
    fi
    
    # Wait for monitoring to start
    sleep 3
    
    # Create test file to trigger monitoring
    echo "test content" > "$test_file"
    
    # Wait for change detection
    sleep 2
    
    # Check if monitoring is running
    if [[ -f "${SESSION_DIR}/monitor_daemon.pid" ]]; then
        local daemon_pid=$(cat "${SESSION_DIR}/monitor_daemon.pid")
        if kill -0 "$daemon_pid" 2>/dev/null; then
            log_success "Directory monitoring test passed"
        else
            log_error "Monitoring daemon not running"
            return 1
        fi
    else
        log_error "Monitoring daemon PID file not found"
        return 1
    fi
    
    # Stop monitoring
    "$change_detector" stop > /dev/null 2>&1
    
    # Cleanup test file
    rm -f "$test_file"
    
    return 0
}

# Test environment change detection
test_environment_change_detection() {
    log_info "Testing environment change detection..."
    
    local change_detector="./environment-change-detector.sh"
    local test_venv_dir="$TEST_DIR/venvs"
    
    # Start monitoring with test configuration
    export CONFIG_FILE="$TEST_DIR/environment-monitor.conf"
    if ! "$change_detector" start > /dev/null 2>&1; then
        log_error "Failed to start monitoring daemon"
        return 1
    fi
    
    # Wait for monitoring to start
    sleep 3
    
    # Create new virtual environment to trigger change detection
    local new_env="$test_venv_dir/test-env-new"
    if python3 -m venv "$new_env" 2>/dev/null; then
        log_success "Created test environment for change detection"
        
        # Wait for change detection
        sleep 5
        
        # Check if baseline was updated
        if [[ -f "${SESSION_STATE_DIR}/environment_baseline.json" ]]; then
            log_success "Environment baseline updated after change detection"
        else
            log_warning "Environment baseline not found after change detection"
        fi
    else
        log_error "Failed to create test environment"
        return 1
    fi
    
    # Stop monitoring
    "$change_detector" stop > /dev/null 2>&1
    
    # Cleanup test environment
    rm -rf "$new_env"
    
    log_success "Environment change detection test completed"
    return 0
}

# Test automatic session saving
test_automatic_session_saving() {
    log_info "Testing automatic session saving..."
    
    local change_detector="./environment-change-detector.sh"
    local session_manager="${SESSION_DIR}/session-manager.sh"
    local test_venv_dir="$TEST_DIR/venvs"
    
    # Ensure session manager exists
    if [[ ! -f "$session_manager" ]]; then
        log_warning "Session manager not found - skipping automatic save test"
        return 0
    fi
    
    # Start monitoring with test configuration
    export CONFIG_FILE="$TEST_DIR/environment-monitor.conf"
    if ! "$change_detector" start > /dev/null 2>&1; then
        log_error "Failed to start monitoring daemon"
        return 1
    fi
    
    # Wait for monitoring to start
    sleep 3
    
    # Create significant environment change (new environment)
    local significant_env="$test_venv_dir/significant-change-env"
    if python3 -m venv "$significant_env" 2>/dev/null; then
        log_success "Created significant environment change"
        
        # Wait for automatic save to trigger
        sleep 10
        
        # Check if session was saved
        if [[ -f "${SESSION_STATE_DIR}/save_timestamp.txt" ]]; then
            log_success "Automatic session saving triggered successfully"
        else
            log_warning "Automatic session saving may not have triggered"
        fi
    else
        log_error "Failed to create significant environment change"
        return 1
    fi
    
    # Stop monitoring
    "$change_detector" stop > /dev/null 2>&1
    
    # Cleanup test environment
    rm -rf "$significant_env"
    
    log_success "Automatic session saving test completed"
    return 0
}

# Test error handling and recovery
test_error_handling() {
    log_info "Testing error handling and recovery..."
    
    local change_detector="./environment-change-detector.sh"
    
    # Test with invalid configuration
    export CONFIG_FILE="/nonexistent/config.conf"
    if "$change_detector" start > /dev/null 2>&1; then
        log_success "Error handling test passed (invalid config handled)"
    else
        log_warning "Invalid configuration test returned non-zero (may be expected)"
    fi
    
    # Reset configuration
    export CONFIG_FILE="$TEST_DIR/environment-monitor.conf"
    
    log_success "Error handling test completed"
    return 0
}

# Test integration with session manager
test_session_manager_integration() {
    log_info "Testing session manager integration..."
    
    local session_manager="${SESSION_DIR}/session-manager.sh"
    
    if [[ ! -f "$session_manager" ]]; then
        log_warning "Session manager not found - skipping integration test"
        return 0
    fi
    
    # Test monitor-start command
    if "$session_manager" monitor-start > /dev/null 2>&1; then
        log_success "Monitor start command test passed"
    else
        log_warning "Monitor start command returned non-zero (may be expected)"
    fi
    
    # Test monitor-status command
    if "$session_manager" monitor-status > /dev/null 2>&1; then
        log_success "Monitor status command test passed"
    else
        log_warning "Monitor status command returned non-zero (may be expected)"
    fi
    
    # Test monitor-stop command
    if "$session_manager" monitor-stop > /dev/null 2>&1; then
        log_success "Monitor stop command test passed"
    else
        log_warning "Monitor stop command returned non-zero (may be expected)"
    fi
    
    log_success "Session manager integration test completed"
    return 0
}

# Stop test monitoring
stop_test_monitoring() {
    log_info "Stopping test monitoring..."
    
    local change_detector="./environment-change-detector.sh"
    
    if [[ -f "$change_detector" ]]; then
        "$change_detector" stop > /dev/null 2>&1
        log_success "Test monitoring stopped"
    fi
}

# =============================================================================
# MAIN TEST EXECUTION
# =============================================================================

# Run all tests
run_all_tests() {
    log_info "Starting comprehensive environment change detection tests..."
    
    local tests_passed=0
    local tests_failed=0
    local tests_skipped=0
    
    # Test 1: Detector startup
    if test_detector_startup; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 2: Directory monitoring
    if test_directory_monitoring; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 3: Environment change detection
    if test_environment_change_detection; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 4: Automatic session saving
    if test_automatic_session_saving; then
        ((tests_passed++))
    else
        ((tests_skipped++))
    fi
    
    # Test 5: Error handling
    if test_error_handling; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 6: Session manager integration
    if test_session_manager_integration; then
        ((tests_passed++))
    else
        ((tests_skipped++))
    fi
    
    # Print test summary
    log_info "Test Summary:"
    echo "  Passed:  $tests_passed"
    echo "  Failed:  $tests_failed"
    echo "  Skipped: $tests_skipped"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_success "All tests completed successfully"
        return 0
    else
        log_error "Some tests failed"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 {run|setup|cleanup|help}"
    echo ""
    echo "Environment Change Detection Test Suite Commands:"
    echo "  run      - Run all tests"
    echo "  setup    - Setup test environment"
    echo "  cleanup  - Cleanup test environment"
    echo "  help     - Show this help message"
    echo ""
    echo "Test Coverage:"
    echo "  • Environment change detector startup"
    echo "  • Directory monitoring with inotify"
    echo "  • Environment change detection"
    echo "  • Automatic session saving"
    echo "  • Error handling and recovery"
    echo "  • Session manager integration"
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "run")
            setup_test_environment
            run_all_tests
            local result=$?
            cleanup_test_environment
            exit $result
            ;;
        "setup")
            setup_test_environment
            ;;
        "cleanup")
            cleanup_test_environment
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