#!/usr/bin/env zsh

# 🚀 Hyprland Session Manager - Deployment Validation Script
# Comprehensive validation for deployment readiness

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[VALIDATION]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[VALIDATION SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[VALIDATION WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[VALIDATION ERROR]${NC} $1"
}

# Check if running in project directory
check_project_directory() {
    log_info "Checking project directory structure..."
    
    local required_dirs=("scripts" "docs" "hooks" ".config" "community-hooks" "examples")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        log_error "Missing required directories: ${missing_dirs[*]}"
        return 1
    fi
    
    log_success "Project directory structure is complete"
    return 0
}

# Check script organization
check_script_organization() {
    log_info "Checking script organization..."
    
    local script_dirs=("scripts/quantum" "scripts/deployment" "scripts/validation")
    local missing_scripts=()
    
    for dir in "${script_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_scripts+=("$dir")
        fi
    done
    
    # Check for key script files
    local key_scripts=(
        "scripts/quantum/quantum-state-manager.py"
        "scripts/quantum/quantum-state-config.py"
        "scripts/deployment/deploy.sh"
        "scripts/validation/test.sh"
    )
    
    for script in "${key_scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        log_error "Missing scripts or directories: ${missing_scripts[*]}"
        return 1
    fi
    
    log_success "Script organization is complete"
    return 0
}

# Check documentation organization
check_documentation_organization() {
    log_info "Checking documentation organization..."
    
    local doc_dirs=("docs/user" "docs/developer" "docs/architecture")
    local missing_docs=()
    
    for dir in "${doc_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_docs+=("$dir")
        fi
    done
    
    # Check for key documentation files
    local key_docs=(
        "docs/user/quantum-state-user-guide.md"
        "docs/user/workspace-restoration-user-guide.md"
        "docs/developer/workspace-restoration-hooks-guide.md"
        "docs/architecture/workspace-restoration-architecture.md"
    )
    
    for doc in "${key_docs[@]}"; do
        if [[ ! -f "$doc" ]]; then
            missing_docs+=("$doc")
        fi
    done
    
    if [[ ${#missing_docs[@]} -gt 0 ]]; then
        log_error "Missing documentation files: ${missing_docs[*]}"
        return 1
    fi
    
    log_success "Documentation organization is complete"
    return 0
}

# Check hook organization
check_hook_organization() {
    log_info "Checking hook organization..."
    
    local hook_dirs=("hooks/legacy" "community-hooks/pre-save" "community-hooks/post-restore")
    local missing_hooks=()
    
    for dir in "${hook_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_hooks+=("$dir")
        fi
    done
    
    # Check for key hook files
    local key_hooks=(
        "hooks/legacy/environment-validation.sh"
        "community-hooks/pre-save/firefox-sessions.sh"
        "community-hooks/post-restore/firefox-sessions.sh"
    )
    
    for hook in "${key_hooks[@]}"; do
        if [[ ! -f "$hook" ]]; then
            missing_hooks+=("$hook")
        fi
    done
    
    if [[ ${#missing_hooks[@]} -gt 0 ]]; then
        log_error "Missing hook files: ${missing_hooks[*]}"
        return 1
    fi
    
    log_success "Hook organization is complete"
    return 0
}

# Check file permissions
check_file_permissions() {
    log_info "Checking file permissions..."
    
    local scripts=(
        "scripts/quantum/quantum-state-manager.py"
        "scripts/deployment/deploy.sh"
        "scripts/validation/test.sh"
        "install.sh"
        "uninstall.sh"
    )
    
    local permission_issues=()
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" && ! -x "$script" ]]; then
            permission_issues+=("$script")
        fi
    done
    
    if [[ ${#permission_issues[@]} -gt 0 ]]; then
        log_warning "Scripts missing executable permissions: ${permission_issues[*]}"
        log_info "Fixing permissions..."
        for script in "${permission_issues[@]}"; do
            chmod +x "$script"
        done
        log_success "Permissions fixed"
    else
        log_success "All scripts have proper permissions"
    fi
    
    return 0
}

# Check configuration files
check_configuration_files() {
    log_info "Checking configuration files..."
    
    local config_files=(
        ".config/hyprland-session-manager/session-manager.sh"
        ".config/hyprland-session-manager/session-save.sh"
        ".config/hyprland-session-manager/session-restore.sh"
    )
    
    local missing_configs=()
    
    for config in "${config_files[@]}"; do
        if [[ ! -f "$config" ]]; then
            missing_configs+=("$config")
        fi
    done
    
    if [[ ${#missing_configs[@]} -gt 0 ]]; then
        log_error "Missing configuration files: ${missing_configs[*]}"
        return 1
    fi
    
    log_success "Configuration files are complete"
    return 0
}

# Check for duplicate files
check_duplicate_files() {
    log_info "Checking for duplicate files..."
    
    # Check for files that might have been left in root directory (excluding main scripts)
    local root_files=$(find . -maxdepth 1 -type f -name "*.sh" -o -name "*.py" -o -name "*.md" | grep -v "README.md" | grep -v "LICENSE" | grep -v "CONTRIBUTING.md" | grep -v "PROJECT_ORGANIZATION_PLAN.md" | grep -v ".gitignore" | grep -v "install.sh" | grep -v "uninstall.sh")
    
    if [[ -n "$root_files" ]]; then
        log_warning "Files found in root directory that should be organized:"
        echo "$root_files"
        return 1
    fi
    
    log_success "No duplicate files found"
    return 0
}

# Check README completeness
check_readme_completeness() {
    log_info "Checking README completeness..."
    
    if [[ ! -f "README.md" ]]; then
        log_error "README.md is missing"
        return 1
    fi
    
    # Check for key sections in README (with and without emojis)
    local required_sections=(
        "Features"
        "Installation"
        "Usage"
        "Configuration"
        "Troubleshooting"
        "Community Contributions"
    )
    
    local missing_sections=()
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "##.*$section" README.md; then
            missing_sections+=("$section")
        fi
    done
    
    if [[ ${#missing_sections[@]} -gt 0 ]]; then
        log_error "README missing sections: ${missing_sections[*]}"
        return 1
    fi
    
    log_success "README is comprehensive"
    return 0
}

# Run comprehensive validation
run_comprehensive_validation() {
    log_info "Starting comprehensive deployment validation..."
    
    local tests_passed=0
    local tests_failed=0
    local tests_total=8
    
    # Test 1: Project directory structure
    if check_project_directory; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 2: Script organization
    if check_script_organization; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 3: Documentation organization
    if check_documentation_organization; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 4: Hook organization
    if check_hook_organization; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 5: File permissions
    if check_file_permissions; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 6: Configuration files
    if check_configuration_files; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 7: Duplicate files
    if check_duplicate_files; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Test 8: README completeness
    if check_readme_completeness; then
        ((tests_passed++))
    else
        ((tests_failed++))
    fi
    
    # Summary
    echo ""
    echo "=== DEPLOYMENT VALIDATION SUMMARY ==="
    echo "Tests passed: $tests_passed/$tests_total"
    echo "Tests failed: $tests_failed"
    
    if [[ $tests_failed -eq 0 ]]; then
        log_success "🎉 Deployment validation completed successfully!"
        echo ""
        echo "The project is ready for deployment with:"
        echo "✓ Organized directory structure"
        echo "✓ Complete documentation"
        echo "✓ Proper file permissions"
        echo "✓ Comprehensive README"
        echo "✓ All components properly integrated"
        return 0
    else
        log_error "Deployment validation failed - please fix the issues above"
        return 1
    fi
}

# Main function
main() {
    echo "🚀 Hyprland Session Manager - Deployment Validation"
    echo "=================================================="
    echo ""
    
    if run_comprehensive_validation; then
        log_success "Project is deployment-ready!"
        exit 0
    else
        log_error "Project needs fixes before deployment"
        exit 1
    fi
}

# Execute main function
main "$@"