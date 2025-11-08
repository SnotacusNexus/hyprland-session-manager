#!/usr/bin/env bash

# 🧪 Environment Validation System Test Script
# Comprehensive testing for the Hyprland Session Manager environment validation system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Source the environment validation system
source_environment_validation() {
    local env_validation_script="${SCRIPT_DIR}/environment-validation.sh"
    if [[ -f "$env_validation_script" ]]; then
        source "$env_validation_script"
        log_info "Environment validation system loaded"
        return 0
    else
        log_error "Environment validation script not found: $env_validation_script"
        return 1
    fi
}

# Test environment detection functions
test_environment_detection() {
    log_info "Testing environment detection functions..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test conda environment detection
    log_info "Testing conda environment detection..."
    if detect_conda_environments; then
        log_success "Conda environment detection passed"
        ((tests_passed++))
    else
        log_warning "Conda environment detection failed or no conda environments found"
        ((tests_failed++))
    fi
    
    # Test mamba environment detection
    log_info "Testing mamba environment detection..."
    if detect_mamba_environments; then
        log_success "Mamba environment detection passed"
        ((tests_passed++))
    else
        log_warning "Mamba environment detection failed or no mamba environments found"
        ((tests_failed++))
    fi
    
    # Test venv environment detection
    log_info "Testing venv environment detection..."
    if detect_venv_environments; then
        log_success "Venv environment detection passed"
        ((tests_passed++))
    else
        log_warning "Venv environment detection failed or no venv environments found"
        ((tests_failed++))
    fi
    
    # Test pyenv environment detection
    log_info "Testing pyenv environment detection..."
    if detect_pyenv_environments; then
        log_success "Pyenv environment detection passed"
        ((tests_passed++))
    else
        log_warning "Pyenv environment detection failed or no pyenv environments found"
        ((tests_failed++))
    fi
    
    # Test active environment detection
    log_info "Testing active environment detection..."
    local active_env=$(detect_active_environment)
    if [[ -n "$active_env" ]]; then
        log_success "Active environment detection passed: $active_env"
        ((tests_passed++))
    else
        log_warning "Active environment detection failed or no active environment found"
        ((tests_failed++))
    fi
    
    log_info "Environment detection tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test environment validation functions
test_environment_validation() {
    log_info "Testing environment validation functions..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test environment existence validation
    log_info "Testing environment existence validation..."
    if validate_environment_exists "system" "base" ""; then
        log_success "System environment existence validation passed"
        ((tests_passed++))
    else
        log_warning "System environment existence validation failed"
        ((tests_failed++))
    fi
    
    # Test environment health validation
    log_info "Testing environment health validation..."
    if validate_environment_health "system" "base" ""; then
        log_success "System environment health validation passed"
        ((tests_passed++))
    else
        log_warning "System environment health validation failed"
        ((tests_failed++))
    fi
    
    # Test environment metadata extraction
    log_info "Testing environment metadata extraction..."
    local metadata=$(get_environment_metadata "system" "base" "")
    if [[ -n "$metadata" ]]; then
        log_success "Environment metadata extraction passed"
        echo "Metadata: $metadata"
        ((tests_passed++))
    else
        log_warning "Environment metadata extraction failed"
        ((tests_failed++))
    fi
    
    log_info "Environment validation tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test enhanced terminal environment capture
test_terminal_environment_capture() {
    log_info "Testing enhanced terminal environment capture..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Create test session state directory
    mkdir -p "$SESSION_STATE_DIR"
    
    # Test terminal environment capture
    log_info "Testing terminal environment capture..."
    if capture_terminal_environment; then
        log_success "Terminal environment capture passed"
        ((tests_passed++))
    else
        log_warning "Terminal environment capture failed"
        ((tests_failed++))
    fi
    
    # Test environment metadata capture
    log_info "Testing environment metadata capture..."
    if capture_environment_metadata; then
        log_success "Environment metadata capture passed"
        ((tests_passed++))
    else
        log_warning "Environment metadata capture failed"
        ((tests_failed++))
    fi
    
    # Check if environment files were created
    local env_file="${SESSION_STATE_DIR}/environment_metadata.json"
    local terminal_file="${SESSION_STATE_DIR}/terminal_environment.json"
    
    if [[ -f "$env_file" ]]; then
        log_success "Environment metadata file created: $env_file"
        ((tests_passed++))
        echo "Environment metadata content:"
        cat "$env_file" | head -20
    else
        log_warning "Environment metadata file not created"
        ((tests_failed++))
    fi
    
    if [[ -f "$terminal_file" ]]; then
        log_success "Terminal environment file created: $terminal_file"
        ((tests_passed++))
        echo "Terminal environment content:"
        cat "$terminal_file" | head -20
    else
        log_warning "Terminal environment file not created"
        ((tests_failed++))
    fi
    
    log_info "Terminal environment capture tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test environment validation integration
test_validation_integration() {
    log_info "Testing environment validation integration..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test environment validation
    log_info "Testing environment validation..."
    if validate_environments; then
        log_success "Environment validation passed"
        ((tests_passed++))
    else
        log_warning "Environment validation failed"
        ((tests_failed++))
    fi
    
    # Test restoration environment validation
    log_info "Testing restoration environment validation..."
    if validate_restoration_environments; then
        log_success "Restoration environment validation passed"
        ((tests_passed++))
    else
        log_warning "Restoration environment validation failed"
        ((tests_failed++))
    fi
    
    log_info "Validation integration tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test error handling and edge cases
test_error_handling() {
    log_info "Testing error handling and edge cases..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test with invalid environment type
    log_info "Testing invalid environment type handling..."
    if ! validate_environment_exists "invalid_type" "invalid_name" ""; then
        log_success "Invalid environment type handling passed"
        ((tests_passed++))
    else
        log_warning "Invalid environment type handling failed"
        ((tests_failed++))
    fi
    
    # Test with invalid environment name
    log_info "Testing invalid environment name handling..."
    if ! validate_environment_exists "conda" "invalid_environment_name_12345" ""; then
        log_success "Invalid environment name handling passed"
        ((tests_passed++))
    else
        log_warning "Invalid environment name handling failed"
        ((tests_failed++))
    fi
    
    # Test with empty parameters
    log_info "Testing empty parameter handling..."
    if ! validate_environment_exists "" "" ""; then
        log_success "Empty parameter handling passed"
        ((tests_passed++))
    else
        log_warning "Empty parameter handling failed"
        ((tests_failed++))
    fi
    
    log_info "Error handling tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Test performance and caching
test_performance() {
    log_info "Testing performance and caching..."
    
    local tests_passed=0
    local tests_failed=0
    
    # Test detection performance
    log_info "Testing environment detection performance..."
    local start_time=$(date +%s.%N)
    detect_conda_environments > /dev/null 2>&1
    local end_time=$(date +%s.%N)
    local detection_time=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$detection_time < 5.0" | bc -l) )); then
        log_success "Environment detection performance passed: ${detection_time}s"
        ((tests_passed++))
    else
        log_warning "Environment detection performance slow: ${detection_time}s"
        ((tests_failed++))
    fi
    
    # Test validation performance
    log_info "Testing environment validation performance..."
    start_time=$(date +%s.%N)
    validate_environment_exists "system" "base" "" > /dev/null 2>&1
    end_time=$(date +%s.%N)
    local validation_time=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$validation_time < 2.0" | bc -l) )); then
        log_success "Environment validation performance passed: ${validation_time}s"
        ((tests_passed++))
    else
        log_warning "Environment validation performance slow: ${validation_time}s"
        ((tests_failed++))
    fi
    
    log_info "Performance tests: $tests_passed passed, $tests_failed failed"
    return $tests_failed
}

# Main test execution
run_all_tests() {
    log_info "Starting comprehensive environment validation system tests..."
    
    local total_passed=0
    local total_failed=0
    
    # Source environment validation system
    if ! source_environment_validation; then
        log_error "Failed to load environment validation system - aborting tests"
        return 1
    fi
    
    # Run test suites
    log_info "=== Test Suite 1: Environment Detection ==="
    if test_environment_detection; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    log_info "=== Test Suite 2: Environment Validation ==="
    if test_environment_validation; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    log_info "=== Test Suite 3: Terminal Environment Capture ==="
    if test_terminal_environment_capture; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    log_info "=== Test Suite 4: Validation Integration ==="
    if test_validation_integration; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    log_info "=== Test Suite 5: Error Handling ==="
    if test_error_handling; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    log_info "=== Test Suite 6: Performance ==="
    if test_performance; then
        ((total_passed++))
    else
        ((total_failed++))
    fi
    
    # Summary
    log_info "=== TEST SUMMARY ==="
    log_info "Total test suites: $((total_passed + total_failed))"
    log_info "Suites passed: $total_passed"
    log_info "Suites failed: $total_failed"
    
    if [[ $total_failed -eq 0 ]]; then
        log_success "All test suites passed! Environment validation system is working correctly."
        return 0
    else
        log_warning "Some test suites failed. Check the logs above for details."
        return 1
    fi
}

# Quick test function for basic validation
quick_test() {
    log_info "Running quick environment validation test..."
    
    if source_environment_validation; then
        log_success "Environment validation system loaded successfully"
        
        # Test basic detection
        local active_env=$(detect_active_environment)
        log_info "Active environment: $active_env"
        
        # Test basic validation
        if validate_environment_exists "system" "base" ""; then
            log_success "System environment validation passed"
        else
            log_warning "System environment validation failed"
        fi
        
        return 0
    else
        log_error "Failed to load environment validation system"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 {all|quick|help}"
    echo ""
    echo "Commands:"
    echo "  all   - Run comprehensive test suite"
    echo "  quick - Run quick validation test"
    echo "  help  - Show this help message"
    echo ""
    echo "Test Coverage:"
    echo "  • Environment detection (conda, mamba, venv, pyenv)"
    echo "  • Environment validation (existence, health)"
    echo "  • Terminal environment capture"
    echo "  • Integration with session manager"
    echo "  • Error handling and edge cases"
    echo "  • Performance and caching"
}

# Main execution
main() {
    local command="${1:-all}"
    
    case "$command" in
        "all")
            run_all_tests
            ;;
        "quick")
            quick_test
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

# Execute main function with all arguments
main "$@"