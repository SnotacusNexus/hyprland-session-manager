#!/usr/bin/env zsh

# 🔍 Enhanced Hook Validation Script
# Comprehensive validation for community hooks with performance and security checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
HOOKS_DIR="community-hooks"
SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
VALIDATION_REPORT="validation-report.md"

# Performance thresholds (seconds)
PERF_PRE_SAVE_MAX=2
PERF_POST_RESTORE_MAX=3

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

log_perf() {
    echo -e "${PURPLE}[PERF]${NC} $1"
}

log_security() {
    echo -e "${CYAN}[SECURITY]${NC} $1"
}

# Initialize validation report
init_validation_report() {
    cat > "$VALIDATION_REPORT" << EOF
# 🔍 Hook Validation Report

Generated: $(date)

## 📊 Summary

| Hook Type | Total | ✅ Passed | ❌ Failed | ⚠️ Warnings |
|-----------|-------|-----------|-----------|-------------|
| Pre-Save | 0 | 0 | 0 | 0 |
| Post-Restore | 0 | 0 | 0 | 0 |

## 📋 Detailed Results

EOF
}

# Update validation report
update_validation_report() {
    local hook_file="$1"
    local hook_type="$2"
    local status="$3"
    local details="$4"
    
    cat >> "$VALIDATION_REPORT" << EOF
### $(basename "$hook_file") ($hook_type)

**Status:** $status

**Details:**
$details

---

EOF
}

# Check hook file basics
check_hook_basics() {
    local hook_file="$1"
    local results=()
    
    # Check file exists
    if [[ ! -f "$hook_file" ]]; then
        results+=("❌ File not found")
        return 1
    fi
    
    # Check executable permission
    if [[ ! -x "$hook_file" ]]; then
        results+=("❌ Not executable")
    else
        results+=("✅ Executable")
    fi
    
    # Check shebang
    if ! head -1 "$hook_file" | grep -q "^#!/usr/bin/env zsh"; then
        results+=("❌ Invalid shebang")
    else
        results+=("✅ Correct shebang")
    fi
    
    # Check file size (not too large)
    local file_size=$(wc -c < "$hook_file")
    if [[ $file_size -gt 100000 ]]; then
        results+=("⚠️  File too large (${file_size} bytes)")
    else
        results+=("✅ Reasonable file size")
    fi
    
    echo "${results[*]}"
    return 0
}

# Check hook syntax and structure
check_hook_syntax() {
    local hook_file="$1"
    local results=()
    
    # Syntax check
    if zsh -n "$hook_file" 2>/dev/null; then
        results+=("✅ Syntax valid")
    else
        results+=("❌ Syntax errors")
        zsh -n "$hook_file" 2>&1 | head -5
        return 1
    fi
    
    # Check for required functions
    local required_funcs=(
        "log_info" "log_success" "log_warning" "log_error"
        "SESSION_DIR" "SESSION_STATE_DIR"
    )
    
    for func in "${required_funcs[@]}"; do
        if grep -q "$func" "$hook_file"; then
            results+=("✅ $func present")
        else
            results+=("❌ $func missing")
        fi
    done
    
    # Check for proper error handling
    if grep -q "set -e\|trap\|exit" "$hook_file"; then
        results+=("✅ Error handling present")
    else
        results+=("⚠️  Limited error handling")
    fi
    
    echo "${results[*]}"
    return 0
}

# Security checks
check_security() {
    local hook_file="$1"
    local results=()
    
    # Dangerous patterns
    local dangerous_patterns=(
        "rm -rf" "rm -fr" "rm -r" "rm -f /"
        "dd " "mkfs" "format" "shutdown" "reboot" "poweroff"
        "chmod 777" "chown root" "sudo "
        "curl.*\|\| wget.*\|" "wget.*\|\| curl.*\|"
        ":(){ :|:& };:"  # Fork bomb
    )
    
    local found_dangerous=()
    for pattern in "${dangerous_patterns[@]}"; do
        if grep -q "$pattern" "$hook_file"; then
            found_dangerous+=("$pattern")
        fi
    done
    
    if [[ ${#found_dangerous[@]} -gt 0 ]]; then
        results+=("❌ Dangerous patterns: ${found_dangerous[*]}")
    else
        results+=("✅ No dangerous patterns")
    fi
    
    # Check for external command execution
    local external_cmds=$(grep -E "\$\\(|`|" "$hook_file" | grep -v "\$SESSION" | head -5)
    if [[ -n "$external_cmds" ]]; then
        results+=("⚠️  External command execution detected")
    fi
    
    # Check for file path validation
    if grep -q "\[\[.*=~.*\]\]" "$hook_file"; then
        results+=("✅ Path validation present")
    else
        results+=("⚠️  No path validation")
    fi
    
    echo "${results[*]}"
    return 0
}

# Performance testing
check_performance() {
    local hook_file="$1"
    local hook_type="$2"
    local results=()
    
    # Create test environment
    mkdir -p "$SESSION_STATE_DIR"
    
    # Measure execution time
    local start_time=$(date +%s.%N)
    
    if timeout 30s "$hook_file" "$hook_type" > /dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local execution_time=$(echo "$end_time - $start_time" | bc)
        
        results+=("✅ Execution successful")
        
        # Check performance against threshold
        local max_time="$PERF_PRE_SAVE_MAX"
        if [[ "$hook_type" == "post-restore" ]]; then
            max_time="$PERF_POST_RESTORE_MAX"
        fi
        
        if (( $(echo "$execution_time > $max_time" | bc -l) )); then
            results+=("⚠️  Slow execution: ${execution_time}s (max: ${max_time}s)")
        else
            results+=("✅ Good performance: ${execution_time}s")
        fi
    else
        results+=("❌ Execution failed")
    fi
    
    echo "${results[*]}"
    return 0
}

# Compatibility checks
check_compatibility() {
    local hook_file="$1"
    local results=()
    
    # Check for distribution-specific commands
    local distro_specific=(
        "pacman" "apt" "dnf" "yum" "zypper" "emerge"
        "flatpak" "snap" "nix"
    )
    
    local found_specific=()
    for cmd in "${distro_specific[@]}"; do
        if grep -q "$cmd" "$hook_file"; then
            found_specific+=("$cmd")
        fi
    done
    
    if [[ ${#found_specific[@]} -gt 0 ]]; then
        results+=("⚠️  Distribution-specific: ${found_specific[*]}")
    else
        results+=("✅ Cross-distribution compatible")
    fi
    
    # Check for hard-coded paths
    local hardcoded_paths=$(grep -E "/usr/|/etc/|/var/" "$hook_file" | grep -v "SESSION" | head -3)
    if [[ -n "$hardcoded_paths" ]]; then
        results+=("⚠️  Hard-coded paths detected")
    fi
    
    echo "${results[*]}"
    return 0
}

# Validate a single hook
validate_hook() {
    local hook_file="$1"
    local hook_type="$2"
    
    echo ""
    echo "🔍 Validating: $(basename "$hook_file") ($hook_type)"
    echo "========================================"
    
    local all_results=()
    local has_errors=false
    local has_warnings=false
    
    # Run all validation checks
    log_info "Basic checks..."
    local basics=$(check_hook_basics "$hook_file")
    all_results+=("$basics")
    
    log_info "Syntax and structure..."
    local syntax=$(check_hook_syntax "$hook_file")
    all_results+=("$syntax")
    
    log_security "Security checks..."
    local security=$(check_security "$hook_file")
    all_results+=("$security")
    
    log_perf "Performance testing..."
    local performance=$(check_performance "$hook_file" "$hook_type")
    all_results+=("$performance")
    
    log_info "Compatibility checks..."
    local compatibility=$(check_compatibility "$hook_file")
    all_results+=("$compatibility")
    
    # Compile results
    local details=""
    for result in "${all_results[@]}"; do
        details+="$result\n"
        if [[ "$result" == *"❌"* ]]; then
            has_errors=true
        fi
        if [[ "$result" == *"⚠️"* ]]; then
            has_warnings=true
        fi
    done
    
    # Determine status
    local status
    if [[ "$has_errors" == true ]]; then
        status="❌ FAILED"
    elif [[ "$has_warnings" == true ]]; then
        status="⚠️  PASSED WITH WARNINGS"
    else
        status="✅ PASSED"
    fi
    
    echo ""
    echo "📊 Result: $status"
    echo "$details"
    
    # Update report
    update_validation_report "$hook_file" "$hook_type" "$status" "$details"
    
    if [[ "$has_errors" == true ]]; then
        return 1
    else
        return 0
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
    local warning_hooks=0
    
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
    echo "📊 $hook_type Hooks Summary:"
    echo "========================================"
    echo "Total hooks: $total_hooks"
    echo "✅ Passed: $passed_hooks"
    echo "❌ Failed: $failed_hooks"
    echo "⚠️  Warnings: $warning_hooks"
    
    if [[ $failed_hooks -eq 0 ]]; then
        log_success "🎉 All $hook_type hooks validation passed!"
        return 0
    else
        log_error "💥 $failed_hooks $hook_type hooks failed validation"
        return 1
    fi
}

# Generate final report
generate_final_report() {
    echo ""
    echo "📄 Validation report saved to: $VALIDATION_REPORT"
    echo ""
    
    # Show summary from report
    if [[ -f "$VALIDATION_REPORT" ]]; then
        echo "## 📊 Final Summary"
        grep -A10 "## 📊 Summary" "$VALIDATION_REPORT" | head -12
    fi
}

# Main validation function
main() {
    echo "🔍 Enhanced Hyprland Session Manager Hook Validation"
    echo "=================================================="
    echo ""
    
    # Initialize validation report
    init_validation_report
    
    local overall_result=0
    
    # Validate pre-save hooks
    if ! validate_hooks_directory "$HOOKS_DIR/pre-save" "pre-save"; then
        overall_result=1
    fi
    
    # Validate post-restore hooks
    if ! validate_hooks_directory "$HOOKS_DIR/post-restore" "post-restore"; then
        overall_result=1
    fi
    
    # Generate final report
    generate_final_report
    
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