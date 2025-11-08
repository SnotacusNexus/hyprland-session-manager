#!/usr/bin/env zsh

# 🔍 Hook Validation Script
# Validates community hooks before merging into main project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOOKS_DIR="community-hooks"
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Logging functions
log_info() {
    echo -e "${BLUE}[VALIDATE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[VALIDATE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[VALIDATE]${NC} $1"
}

log_error() {
    echo -e "${RED}[VALIDATE]${NC} $1"
}

# Check if hook file exists
check_hook_exists() {
    local hook_file="$1"
    
    if [[ ! -f "$hook_file" ]]; then
        log_error "Hook file not found: $hook_file"
        return 1
    fi
    
    log_success "Hook file exists: $(basename "$hook_file")"
    return 0
}

# Check if hook is executable
check_hook_executable() {
    local hook_file="$1"
    
    if [[ ! -x "$hook_file" ]]; then
        log_error "Hook is not executable: $hook_file"
        return 1
    fi
    
    log_success "Hook is executable: $(basename "$hook_file")"
    return 0
}

# Check hook syntax
check_hook_syntax() {
    local hook_file="$1"
    
    if ! zsh -n "$hook_file" 2>/dev/null; then
        log_error "Syntax error in hook: $hook_file"
        zsh -n "$hook_file"
        return 1
    fi
    
    log_success "Syntax check passed: $(basename "$hook_file")"
    return 0
}

# Check hook follows template structure
check_hook_structure() {
    local hook_file="$1"
    local required_sections=(
        "SESSION_DIR"
        "SESSION_STATE_DIR"
        "log_info"
        "log_success"
        "log_warning"
        "log_error"
    )
    
    local missing_sections=()
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$hook_file"; then
            missing_sections+=("$section")
        fi
    done
    
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        log_warning "Missing template sections: ${missing_sections[*]}"
        return 1
    fi
    
    log_success "Template structure check passed: $(basename "$hook_file")"
    return 0
}

# Check for dangerous operations
check_dangerous_operations() {
    local hook_file="$1"
    local dangerous_patterns=(
        "rm -rf"
        "rm -fr"
        "rm -r"
        "rm -f"
        "dd "
        ":(){ :|:& };:"
        "mkfs"
        "format"
        "shutdown"
        "reboot"
        "poweroff"
    )
    
    local found_dangerous=()
    
    for pattern in "${dangerous_patterns[@]}"; do
        if grep -q "$pattern" "$hook_file"; then
            found_dangerous+=("$pattern")
        fi
    done
    
    if [[ ${#found_dangerous[@]} -gt 0 ]]; then
        log_error "Dangerous operations found: ${found_dangerous[*]}"
        return 1
    fi
    
    log_success "Safety check passed: $(basename "$hook_file")"
    return 0
}

# Test hook execution
test_hook_execution() {
    local hook_file="$1"
    local hook_type="$2"
    
    # Create test session state directory
    mkdir -p "$SESSION_STATE_DIR"
    
    log_info "Testing hook execution: $(basename "$hook_file") $hook_type"
    
    # Run hook with timeout
    if timeout 30s "$hook_file" "$hook_type" > /dev/null 2>&1; then
        log_success "Hook execution test passed: $(basename "$hook_file")"
        return 0
    else
        log_error "Hook execution test failed: $(basename "$hook_file")"
        return 1
    fi
}

# Validate a single hook
validate_hook() {
    local hook_file="$1"
    local hook_type="$2"
    
    echo ""
    echo "🔍 Validating hook: $(basename "$hook_file")"
    echo "========================================"
    
    local tests_passed=0
    local tests_failed=0
    
    # Run all validation checks
    if check_hook_exists "$hook_file"; then ((tests_passed++)); else ((tests_failed++)); fi
    if check_hook_executable "$hook_file"; then ((tests_passed++)); else ((tests_failed++)); fi
    if check_hook_syntax "$hook_file"; then ((tests_passed++)); else ((tests_failed++)); fi
    if check_hook_structure "$hook_file"; then ((tests_passed++)); else ((tests_failed++)); fi
    if check_dangerous_operations "$hook_file"; then ((tests_passed++)); else ((tests_failed++)); fi
    if test_hook_execution "$hook_file" "$hook_type"; then ((tests_passed++)); else ((tests_failed++)); fi
    
    echo ""
    if [[ $tests_failed -eq 0 ]]; then
        log_success "✅ All tests passed for $(basename "$hook_file")"
        return 0
    else
        log_error "❌ $tests_failed tests failed for $(basename "$hook_file")"
        return 1
    fi
}

# Validate all hooks in a directory
validate_hooks_directory() {
    local hooks_dir="$1"
    local hook_type="$2"
    
    if [[ ! -d "$hooks_dir" ]]; then
        log_warning "Hooks directory not found: $hooks_dir"
        return 0
    fi
    
    local hook_files=("$hooks_dir"/*.sh)
    
    if [[ ${#hook_files[@]} -eq 0 ]]; then
        log_info "No hooks found in $hooks_dir"
        return 0
    fi
    
    local total_hooks=0
    local passed_hooks=0
    local failed_hooks=0
    
    for hook_file in "${hook_files[@]}"; do
        if [[ -f "$hook_file" ]]; then
            ((total_hooks++))
            if validate_hook "$hook_file" "$hook_type"; then
                ((passed_hooks++))
            else
                ((failed_hooks++))
            fi
        fi
    done
    
    echo ""
    echo "📊 Validation Summary for $hook_type hooks:"
    echo "========================================"
    echo "Total hooks: $total_hooks"
    echo "✅ Passed: $passed_hooks"
    echo "❌ Failed: $failed_hooks"
    
    if [[ $failed_hooks -eq 0 ]]; then
        log_success "🎉 All $hook_type hooks validation passed!"
        return 0
    else
        log_error "💥 $failed_hooks $hook_type hooks failed validation"
        return 1
    fi
}

# Main validation function
main() {
    echo "🔍 Hyprland Session Manager Hook Validation"
    echo "=========================================="
    echo ""
    
    local overall_result=0
    
    # Validate pre-save hooks
    if ! validate_hooks_directory "$HOOKS_DIR/pre-save" "pre-save"; then
        overall_result=1
    fi
    
    # Validate post-restore hooks
    if ! validate_hooks_directory "$HOOKS_DIR/post-restore" "post-restore"; then
        overall_result=1
    fi
    
    echo ""
    echo "🏁 Validation Complete"
    echo "====================="
    
    if [[ $overall_result -eq 0 ]]; then
        log_success "🎉 All hooks validation passed! Ready for merge."
    else
        log_error "💥 Some hooks failed validation. Please fix before merging."
    fi
    
    return $overall_result
}

# Execute main function
main "$@"