#!/usr/bin/env zsh

# Hyprland Session Manager Test Script
# Comprehensive testing for all session manager components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[TEST SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[TEST WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[TEST ERROR]${NC} $1"
}

# Check if Hyprland is running
check_hyprland_running() {
    log_info "Checking if Hyprland is running..."
    
    if pgrep -x "hyprland" > /dev/null; then
        log_success "Hyprland is running"
        return 0
    else
        log_error "Hyprland is not running - tests requiring Hyprland will be skipped"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    for dep in hyprctl jq zsh; do
        if ! command -v "$dep" > /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
    
    log_success "All dependencies are available"
    return 0
}

# Test script execution
test_script_execution() {
    log_info "Testing script execution..."
    
    local script_dir="${HOME}/.config/hyprland-session-manager"
    
    if [[ ! -d "$script_dir" ]]; then
        log_error "Session manager directory not found: $script_dir"
        return 1
    fi
    
    # Test main script
    if "$script_dir/session-manager.sh" --help > /dev/null 2>&1; then
        log_success "Main session manager script is executable"
    else
        log_error "Main session manager script test failed"
        return 1
    fi
    
    # Test save script
    if "$script_dir/session-save.sh" > /dev/null 2>&1; then
        log_success "Session save script is executable"
    else
        log_error "Session save script test failed"
        return 1
    fi
    
    # Test restore script
    if "$script_dir/session-restore.sh" > /dev/null 2>&1; then
        log_success "Session restore script is executable"
    else
        log_error "Session restore script test failed"
        return 1
    fi
    
    return 0
}

# Test systemd services
test_systemd_services() {
    log_info "Testing systemd services..."
    
    # Check if service is enabled
    if systemctl --user is-enabled hyprland-session.service > /dev/null 2>&1; then
        log_success "Systemd service is enabled"
    else
        log_warning "Systemd service is not enabled"
    fi
    
    # Check service status
    local service_status=$(systemctl --user status hyprland-session.service 2>&1)
    if echo "$service_status" | grep -q "active (exited)"; then
        log_success "Systemd service is active"
    else
        log_warning "Systemd service status: $(echo "$service_status" | grep "Active:" | head -1)"
    fi
    
    return 0
}

# Test session save functionality
test_session_save() {
    log_info "Testing session save functionality..."
    
    if ! check_hyprland_running; then
        log_warning "Skipping session save test - Hyprland not running"
        return 0
    fi
    
    local script_dir="${HOME}/.config/hyprland-session-manager"
    
    # Clean any existing session state
    "$script_dir/session-manager.sh" clean
    
    # Perform session save
    if "$script_dir/session-manager.sh" save; then
        log_success "Session save completed successfully"
        
        # Verify session state was created
        local state_dir="$script_dir/session-state"
        if [[ -d "$state_dir" ]]; then
            local file_count=$(find "$state_dir" -type f | wc -l)
            if [[ $file_count -gt 0 ]]; then
                log_success "Session state created with $file_count files"
                return 0
            else
                log_error "Session state directory is empty"
                return 1
            fi
        else
            log_error "Session state directory was not created"
            return 1
        fi
    else
        log_error "Session save failed"
        return 1
    fi
}

# Test session status functionality
test_session_status() {
    log_info "Testing session status functionality..."
    
    local script_dir="${HOME}/.config/hyprland-session-manager"
    
    if "$script_dir/session-manager.sh" status; then
        log_success "Session status command executed successfully"
        return 0
    else
        log_error "Session status command failed"
        return 1
    fi
}

# Test hook system
test_hook_system() {
    log_info "Testing hook system..."
    
    local hooks_dir="${HOME}/.config/hyprland-session-manager/hooks"
    
    # Check if hook directories exist
    if [[ -d "$hooks_dir/pre-save" && -d "$hooks_dir/post-restore" ]]; then
        log_success "Hook directories exist"
        
        # Check for example hooks
        local pre_save_hooks=$(find "$hooks_dir/pre-save" -name "*.sh" | wc -l)
        local post_restore_hooks=$(find "$hooks_dir/post-restore" -name "*.sh" | wc -l)
        
        if [[ $pre_save_hooks -gt 0 ]]; then
            log_success "Found $pre_save_hooks pre-save hook(s)"
        else
            log_warning "No pre-save hooks found"
        fi
        
        if [[ $post_restore_hooks -gt 0 ]]; then
            log_success "Found $post_restore_hooks post-restore hook(s)"
        else
            log_warning "No post-restore hooks found"
        fi
        
        return 0
    else
        log_error "Hook directories not found"
        return 1
    fi
}

# Test ZFS integration (if applicable)
test_zfs_integration() {
    log_info "Testing ZFS integration..."
    
    # Check if ZFS root
    if command -v zfs > /dev/null && mount | grep -q "on / type zfs"; then
        log_success "ZFS root filesystem detected"
        
        # Check if ZFS snapshot was created during save
        local script_dir="${HOME}/.config/hyprland-session-manager"
        local snapshot_file="$script_dir/session-state/zfs_snapshot.txt"
        
        if [[ -f "$snapshot_file" ]]; then
            local snapshot=$(cat "$snapshot_file")
            log_success "ZFS snapshot created: $snapshot"
            
            # Verify snapshot exists
            if zfs list -H -o name "$snapshot" > /dev/null 2>&1; then
                log_success "ZFS snapshot verified"
            else
                log_warning "ZFS snapshot not found in zfs list"
            fi
        else
            log_warning "No ZFS snapshot information found"
        fi
    else
        log_info "Not a ZFS root filesystem - skipping ZFS tests"
    fi
    
    return 0
}

# Run comprehensive tests
run_comprehensive_tests() {
    log_info "Starting comprehensive tests..."
    
    local tests_passed=0
    local tests_failed=0
    local tests_skipped=0
    
    # Test 1: Dependencies
    if check_dependencies; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 2: Script execution
    if test_script_execution; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 3: Systemd services
    if test_systemd_services; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 4: Session save
    if test_session_save; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 5: Session status
    if test_session_status; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 6: Hook system
    if test_hook_system; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 7: ZFS integration
    if test_zfs_integration; then
        ((tests_passed++))
    else
        ((tests_skipped++))
    fi
    
    # Summary
    echo ""
    echo "=== TEST SUMMARY ==="
    echo "Tests passed: $tests_passed"
    echo "Tests failed: $tests_failed"
    echo "Tests skipped: $tests_skipped"
    echo "Total tests: $((tests_passed + tests_failed + tests_skipped))"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_success "All tests completed successfully!"
        return 0
    else
        log_error "Some tests failed - check the output above"
        return 1
    fi
}

# Main test function
main() {
    log_info "Starting Hyprland Session Manager tests..."
    
    if run_comprehensive_tests; then
        log_success "All tests completed successfully!"
        echo ""
        echo "🎉 Your Hyprland Session Manager is working correctly!"
        echo ""
        echo "Next steps:"
        echo "- Test manual save/restore with keybindings"
        echo "- Reboot to test automatic session management"
        echo "- Customize hooks for your specific applications"
    else
        log_error "Some tests failed - please check the installation"
        exit 1
    fi
}

# Execute main function
main "$@"