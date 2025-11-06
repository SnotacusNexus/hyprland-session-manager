#!/usr/bin/env zsh

# 🚀 Hyprland Session Manager
# Complete session management with systemd integration
# Target: Arch Linux with ZFS root and Zsh shell

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"
HOOKS_PRE_SAVE_DIR="${SESSION_DIR}/hooks/pre-save"
HOOKS_POST_RESTORE_DIR="${SESSION_DIR}/hooks/post-restore"

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

# Check if Hyprland is running
is_hyprland_running() {
    if pgrep -x "hyprland" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Check if ZFS root filesystem
is_zfs_root() {
    if command -v zfs > /dev/null && mount | grep -q "on / type zfs"; then
        return 0
    else
        return 1
    fi
}

# Run pre-save hooks
run_pre_save_hooks() {
    if [[ -d "$HOOKS_PRE_SAVE_DIR" ]]; then
        log_info "Running pre-save hooks..."
        
        # Run comprehensive session hook first
        local comprehensive_hook="${HOOKS_PRE_SAVE_DIR}/comprehensive-session.sh"
        if [[ -x "$comprehensive_hook" ]]; then
            log_info "Executing comprehensive session hook"
            "$comprehensive_hook"
            if [[ $? -ne 0 ]]; then
                log_warning "Comprehensive hook returned non-zero exit code"
            fi
        else
            # Fallback to individual hooks
            for hook in "$HOOKS_PRE_SAVE_DIR"/*.sh; do
                if [[ -x "$hook" && "$(basename "$hook")" != "comprehensive-session.sh" ]]; then
                    log_info "Executing hook: $(basename "$hook")"
                    "$hook"
                    if [[ $? -ne 0 ]]; then
                        log_warning "Hook $(basename "$hook") returned non-zero exit code"
                    fi
                fi
            done
        fi
    fi
}

# Run post-restore hooks
run_post_restore_hooks() {
    if [[ -d "$HOOKS_POST_RESTORE_DIR" ]]; then
        log_info "Running post-restore hooks..."
        
        # Run comprehensive restoration hook first
        local comprehensive_hook="${HOOKS_POST_RESTORE_DIR}/comprehensive-session.sh"
        if [[ -x "$comprehensive_hook" ]]; then
            log_info "Executing comprehensive restoration hook"
            "$comprehensive_hook"
            if [[ $? -ne 0 ]]; then
                log_warning "Comprehensive restoration hook returned non-zero exit code"
            fi
        else
            # Fallback to individual hooks
            for hook in "$HOOKS_POST_RESTORE_DIR"/*.sh; do
                if [[ -x "$hook" && "$(basename "$hook")" != "comprehensive-session.sh" ]]; then
                    log_info "Executing hook: $(basename "$hook")"
                    "$hook"
                    if [[ $? -ne 0 ]]; then
                        log_warning "Hook $(basename "$hook") returned non-zero exit code"
                    fi
                fi
            done
        fi
    fi
}

# Save window states
save_window_states() {
    log_info "Saving window states..."
    
    # Save workspace information
    if command -v hyprctl > /dev/null; then
        hyprctl workspaces -j > "${SESSION_STATE_DIR}/workspaces.json" 2>/dev/null
        hyprctl clients -j > "${SESSION_STATE_DIR}/clients.json" 2>/dev/null
        hyprctl monitors -j > "${SESSION_STATE_DIR}/monitors.json" 2>/dev/null
        hyprctl activeworkspace -j > "${SESSION_STATE_DIR}/active_workspace.json" 2>/dev/null
        
        log_success "Window states saved successfully"
    else
        log_error "hyprctl not found - cannot save window states"
        return 1
    fi
}

# Save applications
save_applications() {
    log_info "Saving application information..."
    
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Extract application information
        hyprctl clients -j | jq -r '.[] | "\(.pid):\(.class):\(.title)"' > "${SESSION_STATE_DIR}/applications.txt" 2>/dev/null
        
        # Save active window information
        hyprctl activewindow -j > "${SESSION_STATE_DIR}/active_window.json" 2>/dev/null
        
        log_success "Application information saved successfully"
    else
        log_warning "Missing dependencies - cannot save application information"
    fi
}

# Create ZFS snapshot
create_zfs_snapshot() {
    if is_zfs_root; then
        log_info "Creating ZFS snapshot..."
        
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        local root_dataset=$(mount | grep "on / type zfs" | awk '{print $1}')
        
        if [[ -n "$root_dataset" ]]; then
            zfs snapshot "${root_dataset}@session_${timestamp}"
            if [[ $? -eq 0 ]]; then
                log_success "ZFS snapshot created: ${root_dataset}@session_${timestamp}"
                echo "${root_dataset}@session_${timestamp}" > "${SESSION_STATE_DIR}/zfs_snapshot.txt"
            else
                log_error "Failed to create ZFS snapshot"
            fi
        else
            log_warning "Could not determine ZFS root dataset"
        fi
    else
        log_info "Not a ZFS root filesystem - skipping ZFS snapshot"
    fi
}

# Main session save function
save_session() {
    log_info "Starting session save..."
    
    # Create session state directory if it doesn't exist
    mkdir -p "$SESSION_STATE_DIR"
    
    # Run pre-save hooks (includes comprehensive application state saving)
    run_pre_save_hooks
    
    # Save timestamp
    date '+%Y-%m-%d %H:%M:%S' > "${SESSION_STATE_DIR}/save_timestamp.txt"
    
    # Save window states
    save_window_states
    
    # Save applications
    save_applications
    
    # Create ZFS snapshot
    create_zfs_snapshot
    
    log_success "Session saved successfully"
}

# Restore window states
restore_window_states() {
    log_info "Restoring window states..."
    
    # Note: Hyprland doesn't have direct window state restoration
    # This function would need to be enhanced with specific application restoration
    # For now, we'll focus on application restoration via hooks
    
    log_info "Window state restoration handled by application-specific hooks"
}

# Restore applications
restore_applications() {
    log_info "Restoring applications..."
    
    if [[ ! -f "${SESSION_STATE_DIR}/applications.txt" ]]; then
        log_warning "No saved application information found"
        return 1
    fi
    
    local count=0
    while IFS=: read -r pid class title; do
        if [[ -n "$class" && "$class" != "null" ]]; then
            log_info "Launching application: $class"
            
            # Launch application based on class
            case "$class" in
                "kitty"|"Alacritty"|"wezterm")
                    # Terminal emulators
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                "firefox"|"chromium"|"google-chrome")
                    # Web browsers
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                "code"|"vscodium"|"void")
                    # Code editors
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                "thunar"|"nautilus"|"dolphin")
                    # File managers
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                "krita"|"gimp")
                    # Creative applications
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                "libreoffice"|"okular")
                    # Office applications
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
                *)
                    # Generic application launch
                    nohup "$class" > /dev/null 2>&1 &
                    ;;
            esac
            
            ((count++))
            # Small delay between application launches
            sleep 1
        fi
    done < "${SESSION_STATE_DIR}/applications.txt"
    
    log_success "Restored $count applications"
}

# Main session restore function
restore_session() {
    log_info "Starting session restore..."
    
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_error "No saved session found"
        return 1
    fi
    
    # Wait for Hyprland to be fully initialized
    log_info "Waiting for Hyprland to be ready..."
    sleep 3
    
    # Restore applications (basic fallback)
    restore_applications
    
    # Run post-restore hooks (includes comprehensive application state restoration)
    run_post_restore_hooks
    
    log_success "Session restored successfully"
}

# Clean session state
clean_session() {
    log_info "Cleaning session state..."
    
    if [[ -d "$SESSION_STATE_DIR" ]]; then
        rm -rf "${SESSION_STATE_DIR}"/*
        log_success "Session state cleaned"
    else
        log_warning "No session state directory found"
    fi
}

# Show session status
show_status() {
    log_info "Session status:"
    
    if [[ -d "$SESSION_STATE_DIR" ]]; then
        if [[ -f "${SESSION_STATE_DIR}/save_timestamp.txt" ]]; then
            local timestamp=$(cat "${SESSION_STATE_DIR}/save_timestamp.txt")
            echo "  Last saved: $timestamp"
        else
            echo "  No saved session found"
        fi
        
        # Count saved files
        local file_count=$(find "$SESSION_STATE_DIR" -type f | wc -l)
        echo "  Saved files: $file_count"
        
        # Check ZFS snapshot
        if [[ -f "${SESSION_STATE_DIR}/zfs_snapshot.txt" ]]; then
            local snapshot=$(cat "${SESSION_STATE_DIR}/zfs_snapshot.txt")
            echo "  ZFS snapshot: $snapshot"
        fi
        
        # Show available hooks
        echo "  Available hooks:"
        if [[ -d "$HOOKS_PRE_SAVE_DIR" ]]; then
            local pre_hooks=$(find "$HOOKS_PRE_SAVE_DIR" -name "*.sh" -executable | wc -l)
            echo "    Pre-save: $pre_hooks"
        fi
        if [[ -d "$HOOKS_POST_RESTORE_DIR" ]]; then
            local post_hooks=$(find "$HOOKS_POST_RESTORE_DIR" -name "*.sh" -executable | wc -l)
            echo "    Post-restore: $post_hooks"
        fi
    else
        echo "  No session state directory"
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 {save|restore|clean|status|help}"
    echo ""
    echo "Commands:"
    echo "  save     - Save current Hyprland session with comprehensive application state"
    echo "  restore  - Restore saved Hyprland session with application state recovery"
    echo "  clean    - Clean saved session state"
    echo "  status   - Show session status"
    echo "  help     - Show this help message"
    echo ""
    echo "Application Support:"
    echo "  • Browsers: Firefox (session state)"
    echo "  • IDEs: VSCode, Void IDE (workspace state)"
    echo "  • Creative: Krita, GIMP (document state)"
    echo "  • Office: LibreOffice, Okular (document state)"
    echo "  • Terminals: Kitty, Terminator, Tmux (session state)"
    echo "  • File Managers: Dolphin (session state)"
    echo ""
    echo "Environment:"
    echo "  SESSION_DIR: $SESSION_DIR"
    echo "  SESSION_STATE_DIR: $SESSION_STATE_DIR"
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "save")
            if is_hyprland_running; then
                save_session
            else
                log_error "Hyprland is not running - cannot save session"
                exit 1
            fi
            ;;
        "restore")
            if is_hyprland_running; then
                restore_session
            else
                log_error "Hyprland is not running - cannot restore session"
                exit 1
            fi
            ;;
        "clean")
            clean_session
            ;;
        "status")
            show_status
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