#!/usr/bin/env zsh

# Workspace Restoration Test Script
# Validates the enhanced workspace save and restore functionality

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TEST]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[TEST SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[TEST WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[TEST ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if Hyprland is running
check_hyprland_running() {
    if pgrep -x "Hyprland" > /dev/null; then
        log_success "Hyprland is running"
        return 0
    else
        log_error "Hyprland is not running - cannot test workspace restoration"
        return 1
    fi
}

# Check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v hyprctl > /dev/null; then
        missing_deps+=("hyprctl")
    fi
    
    if ! command -v jq > /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    else
        log_success "All dependencies available"
        return 0
    fi
}

# Test workspace layout extraction
test_workspace_layout_extraction() {
    log_info "Testing workspace layout extraction..."
    
    if [[ ! -f "${SESSION_STATE_DIR}/workspace_layouts.json" ]]; then
        log_warning "No workspace layout file found - run session save first"
        return 1
    fi
    
    local layout_count=$(jq 'length' "${SESSION_STATE_DIR}/workspace_layouts.json" 2>/dev/null || echo "0")
    
    if [[ $layout_count -gt 0 ]]; then
        log_success "Workspace layout extraction: $layout_count workspaces captured"
        return 0
    else
        log_error "No workspace layouts found in file"
        return 1
    fi
}

# Test window state capture
test_window_state_capture() {
    log_info "Testing window state capture..."
    
    if [[ ! -f "${SESSION_STATE_DIR}/window_states.json" ]]; then
        log_warning "No window state file found - run session save first"
        return 1
    fi
    
    local window_count=$(jq 'length' "${SESSION_STATE_DIR}/window_states.json" 2>/dev/null || echo "0")
    
    if [[ $window_count -gt 0 ]]; then
        log_success "Window state capture: $window_count windows captured"
        return 0
    else
        log_error "No window states found in file"
        return 1
    fi
}

# Test application workspace mapping
test_application_mapping() {
    log_info "Testing application workspace mapping..."
    
    if [[ ! -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
        log_warning "No application mapping file found - run session save first"
        return 1
    fi
    
    local app_count=$(jq 'length' "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null || echo "0")
    
    if [[ $app_count -gt 0 ]]; then
        log_success "Application workspace mapping: $app_count applications mapped"
        return 0
    else
        log_error "No application mappings found in file"
        return 1
    fi
}

# Test workspace creation
test_workspace_creation() {
    log_info "Testing workspace creation from layout..."
    
    # Create a test workspace layout
    local test_layout="${SESSION_STATE_DIR}/test_workspace_layouts.json"
    cat > "$test_layout" << 'EOF'
[
  {
    "id": 99,
    "name": "test-workspace",
    "monitor": "",
    "monitorID": 0,
    "windows": 0,
    "hasfullscreen": false
  }
]
EOF
    
    # Test workspace creation function
    if hyprctl dispatch workspace 99 > /dev/null 2>&1; then
        log_success "Test workspace creation: Workspace 99 created successfully"
        # Clean up test workspace
        hyprctl dispatch workspace 1 > /dev/null 2>&1
        rm -f "$test_layout"
        return 0
    else
        log_error "Test workspace creation: Failed to create workspace"
        rm -f "$test_layout"
        return 1
    fi
}

# Test data structure validation
test_data_structure_validation() {
    log_info "Testing data structure validation..."
    
    local validation_passed=true
    
    # Check workspace layout structure
    if [[ -f "${SESSION_STATE_DIR}/workspace_layouts.json" ]]; then
        if ! jq -e '.[] | has("id") and has("name")' "${SESSION_STATE_DIR}/workspace_layouts.json" > /dev/null 2>&1; then
            log_error "Workspace layout structure validation failed"
            validation_passed=false
        fi
    fi
    
    # Check window state structure
    if [[ -f "${SESSION_STATE_DIR}/window_states.json" ]]; then
        if ! jq -e '.[] | has("address") and has("class") and has("workspace")' "${SESSION_STATE_DIR}/window_states.json" > /dev/null 2>&1; then
            log_error "Window state structure validation failed"
            validation_passed=false
        fi
    fi
    
    # Check application mapping structure
    if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
        if ! jq -e '.[] | has("class") and has("workspace")' "${SESSION_STATE_DIR}/application_workspace_mapping.json" > /dev/null 2>&1; then
            log_error "Application mapping structure validation failed"
            validation_passed=false
        fi
    fi
    
    if [[ "$validation_passed" == "true" ]]; then
        log_success "Data structure validation passed"
        return 0
    else
        log_error "Data structure validation failed"
        return 1
    fi
}

# Test backward compatibility
test_backward_compatibility() {
    log_info "Testing backward compatibility..."
    
    local compatibility_passed=true
    
    # Check if original session files still exist
    local original_files=("workspaces.json" "clients.json" "monitors.json" "active_workspace.json" "applications.txt")
    
    for file in "${original_files[@]}"; do
        if [[ ! -f "${SESSION_STATE_DIR}/$file" ]]; then
            log_warning "Original session file missing: $file"
            compatibility_passed=false
        fi
    done
    
    if [[ "$compatibility_passed" == "true" ]]; then
        log_success "Backward compatibility: Original session files preserved"
        return 0
    else
        log_warning "Backward compatibility: Some original files missing"
        return 1
    fi
}

# Run comprehensive test suite
run_test_suite() {
    log_info "Starting workspace restoration test suite..."
    
    local tests_passed=0
    local tests_failed=0
    local tests_total=0
    
    # Test 1: Check dependencies
    ((tests_total++))
    if check_dependencies; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 2: Check Hyprland running
    ((tests_total++))
    if check_hyprland_running; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 3: Test workspace layout extraction
    ((tests_total++))
    if test_workspace_layout_extraction; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 4: Test window state capture
    ((tests_total++))
    if test_window_state_capture; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 5: Test application mapping
    ((tests_total++))
    if test_application_mapping; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 6: Test workspace creation
    ((tests_total++))
    if test_workspace_creation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 7: Test data structure validation
    ((tests_total++))
    if test_data_structure_validation; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 8: Test backward compatibility
    ((tests_total++))
    if test_backward_compatibility; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Summary
    echo ""
    echo "=== TEST SUITE SUMMARY ==="
    echo "Total tests: $tests_total"
    echo "Passed: $tests_passed"
    echo "Failed: $tests_failed"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_success "All tests passed! Workspace restoration functionality is ready."
        return 0
    else
        log_warning "Some tests failed. Please check the implementation."
        return 1
    fi
}

# Main execution
main() {
    echo "Workspace Restoration Test Suite"
    echo "================================"
    echo ""
    
    run_test_suite
}

# Execute main function
main "$@"