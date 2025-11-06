#!/usr/bin/env zsh

# Comprehensive Session Management Hook
# Master pre-save hook that orchestrates all application-specific hooks

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[COMPREHENSIVE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[COMPREHENSIVE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[COMPREHENSIVE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[COMPREHENSIVE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Run application-specific hooks in sequence
run_application_hooks() {
    log_info "Running application-specific session hooks..."
    
    local hooks=(
        "browser-sessions.sh"
        "ide-sessions.sh"
        "creative-office-sessions.sh"
        "terminal-sessions.sh"
    )
    
    local successful_hooks=0
    local total_hooks=${#hooks[@]}
    
    for hook in "${hooks[@]}"; do
        local hook_path="${SESSION_DIR}/hooks/pre-save/${hook}"
        
        if [[ -x "$hook_path" ]]; then
            log_info "Executing hook: $hook"
            
            if "$hook_path"; then
                log_success "Hook completed successfully: $hook"
                ((successful_hooks++))
            else
                log_warning "Hook returned non-zero exit code: $hook"
            fi
        else
            log_warning "Hook not executable or not found: $hook"
        fi
    done
    
    log_success "Application hooks completed: $successful_hooks/$total_hooks successful"
}

# Save comprehensive system state
save_system_state() {
    log_info "Saving comprehensive system state..."
    
    # Save current time and session information
    date '+%Y-%m-%d %H:%M:%S' > "${SESSION_STATE_DIR}/comprehensive_save_timestamp.txt"
    
    # Save all running applications
    hyprctl clients -j > "${SESSION_STATE_DIR}/all_clients.json" 2>/dev/null
    
    # Save workspace information
    hyprctl workspaces -j > "${SESSION_STATE_DIR}/all_workspaces.json" 2>/dev/null
    
    # Save monitor configuration
    hyprctl monitors -j > "${SESSION_STATE_DIR}/all_monitors.json" 2>/dev/null
    
    # Save active workspace
    hyprctl activeworkspace -j > "${SESSION_STATE_DIR}/active_workspace.json" 2>/dev/null
    
    # Save system information
    uname -a > "${SESSION_STATE_DIR}/system_info.txt"
    whoami > "${SESSION_STATE_DIR}/current_user.txt"
    
    log_success "Comprehensive system state saved"
}

# Create session summary report
create_comprehensive_summary() {
    log_info "Creating comprehensive session summary..."
    
    local summary_file="${SESSION_STATE_DIR}/comprehensive_summary.txt"
    
    echo "=== HYPRLAND SESSION MANAGER - COMPREHENSIVE SESSION SUMMARY ===" > "$summary_file"
    echo "Save Time: $(date)" >> "$summary_file"
    echo "User: $(whoami)" >> "$summary_file"
    echo "System: $(uname -a)" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Application counts
    echo "APPLICATION SUMMARY:" >> "$summary_file"
    echo "====================" >> "$summary_file"
    
    # Count applications by class
    local app_classes=$(hyprctl clients -j 2>/dev/null | jq -r '.[].class' | sort | uniq -c | sort -nr)
    if [[ -n "$app_classes" ]]; then
        echo "$app_classes" >> "$summary_file"
    else
        echo "No applications detected" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    
    # Workspace information
    echo "WORKSPACE SUMMARY:" >> "$summary_file"
    echo "==================" >> "$summary_file"
    
    local workspace_count=$(hyprctl workspaces -j 2>/dev/null | jq 'length')
    local active_workspace=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name')
    
    echo "Total workspaces: $workspace_count" >> "$summary_file"
    echo "Active workspace: $active_workspace" >> "$summary_file"
    
    echo "" >> "$summary_file"
    
    # Hook execution summary
    echo "HOOK EXECUTION SUMMARY:" >> "$summary_file"
    echo "=======================" >> "$summary_file"
    
    local hooks=(
        "browser-sessions.sh"
        "ide-sessions.sh"
        "creative-office-sessions.sh"
        "terminal-sessions.sh"
    )
    
    for hook in "${hooks[@]}"; do
        local hook_path="${SESSION_DIR}/hooks/pre-save/${hook}"
        if [[ -x "$hook_path" ]]; then
            echo "✓ $hook - Available" >> "$summary_file"
        else
            echo "✗ $hook - Not available" >> "$summary_file"
        fi
    done
    
    echo "" >> "$summary_file"
    
    # Session state files
    echo "SESSION STATE FILES:" >> "$summary_file"
    echo "====================" >> "$summary_file"
    
    local file_count=$(find "$SESSION_STATE_DIR" -type f | wc -l)
    local dir_count=$(find "$SESSION_STATE_DIR" -type d | wc -l)
    
    echo "Files: $file_count" >> "$summary_file"
    echo "Directories: $dir_count" >> "$summary_file"
    
    echo "" >> "$summary_file"
    
    # Application-specific highlights
    echo "APPLICATION-SPECIFIC HIGHLIGHTS:" >> "$summary_file"
    echo "=================================" >> "$summary_file"
    
    # Browser highlights
    if [[ -f "${SESSION_STATE_DIR}/browser_summary.txt" ]]; then
        cat "${SESSION_STATE_DIR}/browser_summary.txt" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    # IDE highlights
    if [[ -f "${SESSION_STATE_DIR}/ide_summary.txt" ]]; then
        cat "${SESSION_STATE_DIR}/ide_summary.txt" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    # Creative/Office highlights
    if [[ -f "${SESSION_STATE_DIR}/creative_office_summary.txt" ]]; then
        cat "${SESSION_STATE_DIR}/creative_office_summary.txt" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    # Terminal highlights
    if [[ -f "${SESSION_STATE_DIR}/terminal_summary.txt" ]]; then
        cat "${SESSION_STATE_DIR}/terminal_summary.txt" >> "$summary_file"
        echo "" >> "$summary_file"
    fi
    
    echo "=== END OF SESSION SUMMARY ===" >> "$summary_file"
    
    log_success "Comprehensive session summary created"
}

# Validate session state
validate_session_state() {
    log_info "Validating session state..."
    
    local validation_passed=true
    
    # Check if session state directory exists
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_error "Session state directory does not exist"
        validation_passed=false
    fi
    
    # Check if we have basic session files
    local required_files=(
        "comprehensive_save_timestamp.txt"
        "all_clients.json"
        "comprehensive_summary.txt"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${SESSION_STATE_DIR}/$file" ]]; then
            log_warning "Required file missing: $file"
            validation_passed=false
        fi
    done
    
    # Check application-specific directories
    local app_dirs=("firefox" "vscode" "void" "krita" "gimp" "libreoffice" "okular" "dolphin" "kitty" "terminator" "tmux")
    
    for dir in "${app_dirs[@]}"; do
        if [[ -d "${SESSION_STATE_DIR}/$dir" ]]; then
            local file_count=$(find "${SESSION_STATE_DIR}/$dir" -type f | wc -l)
            if [[ $file_count -eq 0 ]]; then
                log_warning "Application directory empty: $dir"
            fi
        fi
    done
    
    if [[ "$validation_passed" == "true" ]]; then
        log_success "Session state validation passed"
        return 0
    else
        log_warning "Session state validation completed with warnings"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting comprehensive session preservation..."
    
    # Create session state directory
    mkdir -p "$SESSION_STATE_DIR"
    
    # Run application-specific hooks
    run_application_hooks
    
    # Save comprehensive system state
    save_system_state
    
    # Create comprehensive summary
    create_comprehensive_summary
    
    # Validate session state
    validate_session_state
    
    log_success "Comprehensive session preservation completed"
    
    # Show quick summary
    local total_files=$(find "$SESSION_STATE_DIR" -type f | wc -l)
    local total_dirs=$(find "$SESSION_STATE_DIR" -type d | wc -l)
    
    echo ""
    echo "=== SESSION SAVE COMPLETE ==="
    echo "Total files saved: $total_files"
    echo "Total directories: $total_dirs"
    echo "Session summary: ${SESSION_STATE_DIR}/comprehensive_summary.txt"
    echo "============================="
}

# Execute main function
main "$@"