#!/usr/bin/env zsh

# Comprehensive Session Restoration Hook
# Master post-restore hook that orchestrates all application-specific restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[COMPREHENSIVE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[COMPREHENSIVE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[COMPREHENSIVE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[COMPREHENSIVE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Validate session state before restoration
validate_restoration_state() {
    log_info "Validating session state for restoration..."
    
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_error "No session state directory found - cannot restore"
        return 1
    fi
    
    # Check for comprehensive save timestamp
    if [[ ! -f "${SESSION_STATE_DIR}/comprehensive_save_timestamp.txt" ]]; then
        log_warning "No comprehensive save timestamp found - may be incomplete session"
    fi
    
    # Check for basic session files
    if [[ ! -f "${SESSION_STATE_DIR}/all_clients.json" ]]; then
        log_warning "No client information found - limited restoration possible"
    fi
    
    log_success "Session state validation completed"
    return 0
}

# Run application-specific restoration hooks in sequence
run_application_restoration_hooks() {
    log_info "Running application-specific restoration hooks..."
    
    local hooks=(
        "browser-sessions.sh"
        "ide-sessions.sh"
        "creative-office-sessions.sh"
        "terminal-sessions.sh"
    )
    
    local successful_hooks=0
    local total_hooks=${#hooks[@]}
    
    for hook in "${hooks[@]}"; do
        local hook_path="${SESSION_DIR}/hooks/post-restore/${hook}"
        
        if [[ -x "$hook_path" ]]; then
            log_info "Executing restoration hook: $hook"
            
            if "$hook_path"; then
                log_success "Restoration hook completed successfully: $hook"
                ((successful_hooks++))
            else
                log_warning "Restoration hook returned non-zero exit code: $hook"
            fi
            
            # Small delay between hooks to allow applications to stabilize
            sleep 2
        else
            log_warning "Restoration hook not executable or not found: $hook"
        fi
    done
    
    log_success "Application restoration hooks completed: $successful_hooks/$total_hooks successful"
}

# Restore basic window and workspace state
restore_basic_state() {
    log_info "Restoring basic window and workspace state..."
    
    # Wait for Hyprland to be fully ready
    sleep 3
    
    # Restore workspace focus if available
    if [[ -f "${SESSION_STATE_DIR}/active_workspace.json" ]] && command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        local workspace_id=$(jq -r '.id' "${SESSION_STATE_DIR}/active_workspace.json" 2>/dev/null)
        if [[ -n "$workspace_id" && "$workspace_id" != "null" ]]; then
            log_info "Focusing workspace: $workspace_id"
            hyprctl dispatch workspace "$workspace_id"
        fi
    fi
    
    log_success "Basic state restoration completed"
}

# Create restoration summary report
create_restoration_summary() {
    log_info "Creating restoration summary..."
    
    local summary_file="${SESSION_STATE_DIR}/restoration_summary.txt"
    
    echo "=== HYPRLAND SESSION MANAGER - RESTORATION SUMMARY ===" > "$summary_file"n    echo "Restoration Time: $(date)" >> "$summary_file"
    echo "User: $(whoami)" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Current application state
    echo "CURRENT APPLICATION STATE:" >> "$summary_file"
    echo "==========================" >> "$summary_file"
    
    local current_apps=$(hyprctl clients -j 2>/dev/null | jq -r '.[].class' | sort | uniq -c | sort -nr)
    if [[ -n "$current_apps" ]]; then
        echo "$current_apps" >> "$summary_file"
    else
        echo "No applications detected" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    
    # Compare with saved state
    echo "COMPARISON WITH SAVED STATE:" >> "$summary_file"
    echo "============================" >> "$summary_file"
    
    if [[ -f "${SESSION_STATE_DIR}/comprehensive_summary.txt" ]]; then
        # Extract application counts from saved state
        local saved_apps_section=$(grep -A 20 "APPLICATION SUMMARY:" "${SESSION_STATE_DIR}/comprehensive_summary.txt" | tail -n +3 | grep -v "^===" | head -10)
        
        if [[ -n "$saved_apps_section" ]]; then
            echo "Saved state applications:" >> "$summary_file"
            echo "$saved_apps_section" >> "$summary_file"
        fi
    else
        echo "No saved state summary available for comparison" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    
    # Restoration status by application category
    echo "RESTORATION STATUS BY CATEGORY:" >> "$summary_file"
    echo "===============================" >> "$summary_file"
    
    # Browser restoration
    local browser_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("firefox|chromium|chrome|brave"))] | length' 2>/dev/null)
    echo "Browsers: $browser_count windows restored" >> "$summary_file"
    
    # IDE restoration
    local ide_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("code|void"))] | length' 2>/dev/null)
    echo "IDEs: $ide_count windows restored" >> "$summary_file"
    
    # Creative/Office restoration
    local creative_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("krita|gimp|libreoffice|okular"))] | length' 2>/dev/null)
    echo "Creative/Office: $creative_count windows restored" >> "$summary_file"
    
    # Terminal restoration
    local terminal_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("kitty|terminator|alacritty"))] | length' 2>/dev/null)
    echo "Terminals: $terminal_count windows restored" >> "$summary_file"
    
    # File manager
    local fileman_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("dolphin|nautilus|thunar"))] | length' 2>/dev/null)
    echo "File Managers: $fileman_count windows restored" >> "$summary_file"
    
    echo "" >> "$summary_file"
    
    # Restoration instructions
    echo "ADDITIONAL RESTORATION STEPS:" >> "$summary_file"
    echo "=============================" >> "$summary_file"
    
    # Check for application-specific restoration instructions
    local instruction_files=$(find "$SESSION_STATE_DIR" -name "*instructions.txt" -o -name "*restore_instructions.txt")
    
    if [[ -n "$instruction_files" ]]; then
        echo "Additional restoration steps may be required:" >> "$summary_file"
        for instruction_file in $instruction_files; do
            local app_name=$(basename "$(dirname "$instruction_file")")
            echo "- Check ${app_name}/$(basename "$instruction_file")" >> "$summary_file"
        done
    else
        echo "No additional restoration steps required" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    echo "=== END OF RESTORATION SUMMARY ===" >> "$summary_file"
    
    log_success "Restoration summary created"
}

# Send comprehensive restoration notification
send_comprehensive_notification() {
    log_info "Sending comprehensive restoration notification..."
    
    if command -v notify-send > /dev/null; then
        # Count restored applications by category
        local browser_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("firefox|chromium|chrome|brave"))] | length' 2>/dev/null)
        local ide_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("code|void"))] | length' 2>/dev/null)
        local creative_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("krita|gimp|libreoffice|okular"))] | length' 2>/dev/null)
        local terminal_count=$(hyprctl clients -j | jq '[.[] | select(.class | test("kitty|terminator|alacritty"))] | length' 2>/dev/null)
        
        local total_apps=$((browser_count + ide_count + creative_count + terminal_count))
        
        local message="Session restoration completed\nTotal applications: $total_apps"
        
        [[ $browser_count -gt 0 ]] && message="$message\nBrowsers: $browser_count"
        [[ $ide_count -gt 0 ]] && message="$message\nIDEs: $ide_count"
        [[ $creative_count -gt 0 ]] && message="$message\nCreative/Office: $creative_count"
        [[ $terminal_count -gt 0 ]] && message="$message\nTerminals: $terminal_count"
        
        notify-send "Session Restoration Complete" "$message" -t 7000
    fi
}

# Validate restoration success
validate_restoration_success() {
    log_info "Validating restoration success..."
    
    local total_restored=$(hyprctl clients -j | jq 'length' 2>/dev/null)
    
    if [[ -n "$total_restored" && "$total_restored" -gt 0 ]]; then
        log_success "Restoration successful - $total_restored windows restored"
        return 0
    else
        log_warning "No windows detected after restoration"
        return 1
    fi
}

# Clean up temporary restoration files
cleanup_restoration() {
    log_info "Cleaning up restoration files..."
    
    # Remove temporary files created during restoration
    local temp_files=(
        "${SESSION_STATE_DIR}/restoration_summary.txt"
        "${SESSION_STATE_DIR}/terminal_restore_instructions.txt"
        "${SESSION_STATE_DIR}/tmux/restore_instructions.txt"
    )
    
    for temp_file in "${temp_files[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file"
        fi
    done
    
    log_success "Restoration cleanup completed"
}

# Main function
main() {
    log_info "Starting comprehensive session restoration..."
    
    # Validate session state
    if ! validate_restoration_state; then
        log_error "Cannot proceed with restoration - invalid session state"
        return 1
    fi
    
    # Initial wait for system stability
    sleep 2
    
    # Run application-specific restoration hooks
    run_application_restoration_hooks
    
    # Restore basic window and workspace state
    restore_basic_state
    
    # Additional wait for applications to fully load
    sleep 3
    
    # Create restoration summary
    create_restoration_summary
    
    # Validate restoration success
    validate_restoration_success
    
    # Send notification
    send_comprehensive_notification
    
    # Clean up
    cleanup_restoration
    
    log_success "Comprehensive session restoration completed"
    
    # Show quick summary
    local total_windows=$(hyprctl clients -j | jq 'length' 2>/dev/null)
    
    echo ""
    echo "=== SESSION RESTORATION COMPLETE ==="
    echo "Total windows restored: $total_windows"
    echo "Restoration summary: ${SESSION_STATE_DIR}/restoration_summary.txt"
    echo "===================================="
}

# Execute main function
main "$@"