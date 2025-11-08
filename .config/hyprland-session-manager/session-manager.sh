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
    if pgrep -x "Hyprland" > /dev/null; then
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

# Source environment validation system
source_environment_validation() {
    local env_validation_script="$(dirname "$0")/../environment-validation.sh"
    if [[ -f "$env_validation_script" ]]; then
        source "$env_validation_script"
        log_info "Environment validation system loaded"
        return 0
    else
        log_warning "Environment validation script not found: $env_validation_script"
        return 1
    fi
}

# Source environment change detection system
source_environment_change_detection() {
    local change_detector_script="$(dirname "$0")/../environment-change-detector.sh"
    if [[ -f "$change_detector_script" ]]; then
        source "$change_detector_script"
        log_info "Environment change detection system loaded"
        return 0
    else
        log_warning "Environment change detection script not found: $change_detector_script"
        return 1
    fi
}

# Quantum State Manager Integration Functions
initialize_quantum_state_manager() {
    log_info "Initializing Quantum State Manager..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    local quantum_config_script="$(dirname "$0")/../../quantum-state-config.py"
    
    if [[ -f "$quantum_manager_script" && -f "$quantum_config_script" ]]; then
        log_success "Quantum State Manager scripts found"
        return 0
    else
        log_warning "Quantum State Manager scripts not found: $quantum_manager_script"
        return 1
    fi
}

# Capture quantum state (replaces broken environment metadata capture)
capture_quantum_state() {
    log_info "Capturing quantum state..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    
    if [[ -f "$quantum_manager_script" ]]; then
        python3 "$quantum_manager_script" --capture --save
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Quantum state captured successfully"
            return 0
        else
            log_warning "Quantum state capture failed, falling back to legacy system"
            capture_environment_metadata
            return 1
        fi
    else
        log_warning "Quantum State Manager not available, using legacy system"
        capture_environment_metadata
        return 1
    fi
}

# Load quantum state for restoration
load_quantum_state() {
    log_info "Loading quantum state..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    
    if [[ -f "$quantum_manager_script" ]]; then
        python3 "$quantum_manager_script" --load --restore
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Quantum state loaded successfully"
            return 0
        else
            log_warning "Quantum state load failed, falling back to legacy system"
            return 1
        fi
    else
        log_warning "Quantum State Manager not available, using legacy system"
        return 1
    fi
}

# Start quantum state auto-save
start_quantum_auto_save() {
    log_info "Starting quantum state auto-save..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    
    if [[ -f "$quantum_manager_script" ]]; then
        python3 "$quantum_manager_script" --auto-save &
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Quantum state auto-save started"
            return 0
        else
            log_warning "Quantum state auto-save failed to start"
            return 1
        fi
    else
        log_warning "Quantum State Manager not available for auto-save"
        return 1
    fi
}

# Stop quantum state auto-save
stop_quantum_auto_save() {
    log_info "Stopping quantum state auto-save..."
    
    pkill -f "quantum-state-manager.py --auto-save"
    
    if [[ $? -eq 0 ]]; then
        log_success "Quantum state auto-save stopped"
        return 0
    else
        log_warning "No quantum state auto-save process found"
        return 1
    fi
}

# Validate quantum state compatibility
validate_quantum_state() {
    log_info "Validating quantum state compatibility..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    
    if [[ -f "$quantum_manager_script" ]]; then
        python3 "$quantum_manager_script" --validate
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Quantum state validation successful"
            return 0
        else
            log_warning "Quantum state validation failed"
            return 1
        fi
    else
        log_warning "Quantum State Manager not available for validation"
        return 1
    fi
}

# Migrate legacy session data to quantum state
migrate_legacy_to_quantum() {
    log_info "Migrating legacy session data to quantum state..."
    
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    
    if [[ -f "$quantum_manager_script" && -d "$SESSION_STATE_DIR" ]]; then
        python3 "$quantum_manager_script" --migrate-legacy "$SESSION_STATE_DIR"
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Legacy session data migrated to quantum state"
            return 0
        else
            log_warning "Legacy migration failed"
            return 1
        fi
    else
        log_warning "Migration not possible - missing components"
        return 1
    fi
}

# Start environment monitoring daemon
start_environment_monitoring() {
    log_info "Starting environment monitoring daemon..."
    
    local change_detector_script="$(dirname "$0")/../environment-change-detector.sh"
    if [[ -f "$change_detector_script" ]]; then
        "$change_detector_script" start
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Environment monitoring daemon started"
        else
            log_warning "Environment monitoring daemon startup failed"
        fi
        
        return $result
    else
        log_warning "Environment change detection script not found"
        return 1
    fi
}

# Stop environment monitoring daemon
stop_environment_monitoring() {
    log_info "Stopping environment monitoring daemon..."
    
    local change_detector_script="$(dirname "$0")/../environment-change-detector.sh"
    if [[ -f "$change_detector_script" ]]; then
        "$change_detector_script" stop
        local result=$?
        
        if [[ $result -eq 0 ]]; then
            log_success "Environment monitoring daemon stopped"
        else
            log_warning "Environment monitoring daemon stop failed"
        fi
        
        return $result
    else
        log_warning "Environment change detection script not found"
        return 1
    fi
}

# Show environment monitoring status
show_environment_monitoring_status() {
    local change_detector_script="$(dirname "$0")/../environment-change-detector.sh"
    if [[ -f "$change_detector_script" ]]; then
        "$change_detector_script" status
    else
        log_warning "Environment change detection script not found"
    fi
}

# Enhanced session save with quantum state management
enhanced_save_session() {
    log_info "Starting enhanced session save with quantum state management..."
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Run pre-save hooks
    run_pre_save_hooks
    
    # Save timestamp
    date '+%Y-%m-%d %H:%M:%S' > "${SESSION_STATE_DIR}/save_timestamp.txt"
    
    # Save window states
    save_window_states
    
    # Save applications
    save_applications
    
    # Capture quantum state (replaces broken environment metadata capture)
    if ! capture_quantum_state; then
        log_warning "Quantum state capture failed - using legacy environment validation"
        capture_environment_metadata
        validate_environments
    fi
    
    # Create ZFS snapshot
    create_zfs_snapshot
    
    log_success "Enhanced session saved with quantum state management"
}

# Enhanced session restore with quantum state management
enhanced_restore_session() {
    log_info "Starting enhanced session restore with quantum state management..."
    
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_error "No saved session found"
        return 1
    fi
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Wait for Hyprland initialization
    log_info "Waiting for Hyprland to be ready..."
    sleep 3
    
    # Try quantum state restoration first
    if load_quantum_state; then
        log_success "Quantum state restoration completed successfully"
        # Run post-restore hooks for quantum state
        run_post_restore_hooks
        return 0
    else
        log_warning "Quantum state restoration failed - falling back to legacy system"
        
        # Validate environments before restoration
        if ! validate_restoration_environments; then
            log_warning "Environment validation failed - proceeding with fallback restoration"
            fallback_restore_session
            return $?
        fi
        
        # Enhanced restoration workflow (legacy)
        create_workspaces_from_layout
        restore_applications_with_workspaces
        sleep 5
        restore_window_positions
        restore_workspace_focus
        run_post_restore_hooks
        validate_workspace_restoration
        
        log_success "Enhanced session restored with legacy environment validation"
        return 0
    fi
}

# Fallback restoration when environments are missing
fallback_restore_session() {
    log_info "Starting fallback session restoration..."
    
    # Create basic workspaces
    create_workspaces_from_layout
    
    # Launch applications without environment validation
    restore_applications_with_workspaces
    
    # Provide user feedback about missing environments
    report_missing_environments
    
    # Continue with basic restoration
    sleep 5
    restore_window_positions
    restore_workspace_focus
    run_post_restore_hooks
    
    log_success "Fallback session restoration completed"
}

# Report missing environments to user
report_missing_environments() {
    local env_file="${SESSION_STATE_DIR}/environment_metadata.json"
    
    if [[ ! -f "$env_file" ]]; then
        return 0
    fi
    
    log_warning "Some development environments are missing or unavailable:"
    
    if command -v jq > /dev/null; then
        jq -c '.environments[]' "$env_file" 2>/dev/null | while read -r env; do
            local env_type=$(echo "$env" | jq -r '.type')
            local env_name=$(echo "$env" | jq -r '.name')
            local env_status=$(echo "$env" | jq -r '.status')
            
            if ! validate_environment_exists "$env_type" "$env_name" ""; then
                log_warning "  - $env_type environment '$env_name' is missing"
            elif [[ "$env_status" == "active" ]] && ! validate_environment_health "$env_type" "$env_name" ""; then
                log_warning "  - $env_type environment '$env_name' is unhealthy"
            fi
        done
    fi
    
    log_info "Applications will launch with system Python environment"
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

# Enhanced workspace layout extraction
extract_workspace_layouts() {
    local workspace_file="${SESSION_STATE_DIR}/workspace_layouts.json"
    
    log_info "Extracting workspace layouts..."
    
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Create comprehensive workspace layout with window assignments
        hyprctl workspaces -j | jq '
        map({
            id: .id,
            name: .name,
            monitor: .monitor,
            monitorID: .monitorID,
            windows: .windows,
            hasfullscreen: .hasfullscreen
        })' > "$workspace_file" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            log_success "Workspace layouts extracted successfully"
            return 0
        else
            log_error "Failed to extract workspace layouts"
            return 1
        fi
    else
        log_error "Missing dependencies for workspace layout extraction"
        return 1
    fi
}

# Enhanced window state capture
capture_window_states() {
    local window_file="${SESSION_STATE_DIR}/window_states.json"
    
    log_info "Capturing window states..."
    
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Capture detailed window information including positions and states
        hyprctl clients -j | jq '
        map({
            address: .address,
            class: .class,
            title: .title,
            workspace: {
                id: .workspace.id,
                name: .workspace.name
            },
            at: .at,
            size: .size,
            floating: .floating,
            fullscreen: .fullscreen,
            pinned: .pinned,
            monitor: .monitor,
            monitorID: .monitorID,
            focused: .focused
        })' > "$window_file" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            log_success "Window states captured successfully"
            return 0
        else
            log_error "Failed to capture window states"
            return 1
        fi
    else
        log_error "Missing dependencies for window state capture"
        return 1
    fi
}

# Create application workspace mapping
create_application_mapping() {
    local mapping_file="${SESSION_STATE_DIR}/application_workspace_mapping.json"
    
    log_info "Creating application workspace mapping..."
    
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Extract application to workspace assignments
        hyprctl clients -j | jq '
        [.[] | {
            class: .class,
            workspace: .workspace.id,
            title: .title,
            command: .class  # Default command is the class name
        }] | unique_by(.class + "|" + (.workspace|tostring))' > "$mapping_file" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            local app_count=$(jq 'length' "$mapping_file" 2>/dev/null || echo "0")
            log_success "Application workspace mapping created for $app_count applications"
            return 0
        else
            log_error "Failed to create application workspace mapping"
            return 1
        fi
    else
        log_error "Missing dependencies for application mapping"
        return 1
    fi
}

# Save window states
save_window_states() {
    log_info "Saving enhanced window states..."
    
    # Save basic workspace information (backward compatibility)
    if command -v hyprctl > /dev/null; then
        hyprctl workspaces -j > "${SESSION_STATE_DIR}/workspaces.json" 2>/dev/null
        hyprctl clients -j > "${SESSION_STATE_DIR}/clients.json" 2>/dev/null
        hyprctl monitors -j > "${SESSION_STATE_DIR}/monitors.json" 2>/dev/null
        hyprctl activeworkspace -j > "${SESSION_STATE_DIR}/active_workspace.json" 2>/dev/null
    fi
    
    # Enhanced workspace layout extraction
    extract_workspace_layouts
    
    # Enhanced window state capture
    capture_window_states
    
    # Application workspace mapping
    create_application_mapping
    
    log_success "Enhanced window states saved successfully"
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

# Main session save function with quantum state integration
save_session() {
    log_info "Starting session save with quantum state integration..."
    
    # Create session state directory if it doesn't exist
    mkdir -p "$SESSION_STATE_DIR"
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Source environment validation system (for fallback)
    source_environment_validation
    
    # Use enhanced save with quantum state management
    enhanced_save_session
    
    # Start quantum auto-save after successful save
    start_quantum_auto_save
    
    log_success "Session saved successfully with quantum state integration"
}

# Workspace creation and management
create_workspaces_from_layout() {
    local layout_file="${SESSION_STATE_DIR}/workspace_layouts.json"
    
    if [[ ! -f "$layout_file" ]]; then
        log_warning "No workspace layout file found for restoration"
        return 1
    fi
    
    log_info "Creating workspaces from saved layout..."
    
    local workspace_count=0
    local created_count=0
    
    # Create workspaces based on saved layout
    jq -r '.[] | "\(.id):\(.name)"' "$layout_file" 2>/dev/null | while IFS=: read -r id name; do
        if [[ -n "$id" && "$id" != "null" ]]; then
            ((workspace_count++))
            
            # Switch to workspace (this creates it if it doesn't exist)
            hyprctl dispatch workspace "$id" > /dev/null 2>&1
            
            # Rename workspace if name is provided
            if [[ "$name" != "null" && "$name" != "" && "$name" != "null" ]]; then
                hyprctl dispatch renameworkspace "$id $name" > /dev/null 2>&1
                log_info "Created workspace $id: $name"
            else
                log_info "Created workspace $id"
            fi
            
            ((created_count++))
        fi
    done
    
    if [[ $created_count -gt 0 ]]; then
        log_success "Created $created_count/$workspace_count workspaces from layout"
        return 0
    else
        log_warning "No workspaces created from layout"
        return 1
    fi
}

# Enhanced workspace-aware application launching with direct workspace targeting
launch_application_to_workspace() {
    local class="$1"
    local workspace="$2"
    local command="$3"
    
    log_info "Launching $class to workspace $workspace"
    
    # Validate workspace exists
    if ! hyprctl workspaces -j | jq -e ".[] | select(.id == $workspace)" > /dev/null 2>&1; then
        log_warning "Target workspace $workspace does not exist - creating it"
        hyprctl dispatch workspace "$workspace" > /dev/null 2>&1
        sleep 1
    fi
    
    # Try direct workspace launching first (more efficient)
    local direct_launch_success=false
    if hyprctl dispatch exec "[workspace:$workspace] $command" > /dev/null 2>&1; then
        log_info "Using direct workspace launching for $class"
        direct_launch_success=true
    else
        log_info "Direct workspace launching failed for $class - using workspace switching"
        # Fallback: switch to workspace and launch
        hyprctl dispatch workspace "$workspace" > /dev/null 2>&1
        nohup $command > /dev/null 2>&1 &
    fi
    
    # Wait for window creation with timeout
    local max_attempts=30
    local attempt=0
    local window_found=false
    
    while [[ $attempt -lt $max_attempts ]]; do
        if hyprctl clients -j | jq -r ".[] | select(.class == \"$class\") | .address" 2>/dev/null | grep -q .; then
            window_found=true
            break
        fi
        sleep 1
        ((attempt++))
    done
    
    if [[ "$window_found" == "true" ]]; then
        log_success "$class launched successfully to workspace $workspace"
        return 0
    else
        log_warning "Timeout waiting for $class window creation in workspace $workspace"
        return 1
    fi
}

# Enhanced application restoration with workspace mapping and intelligent fallbacks
restore_applications_with_workspaces() {
    local app_mapping_file="${SESSION_STATE_DIR}/application_workspace_mapping.json"
    
    if [[ ! -f "$app_mapping_file" ]]; then
        log_warning "No application workspace mapping found - falling back to basic restoration"
        restore_applications
        return $?
    fi
    
    log_info "Restoring applications with workspace assignments..."
    
    local app_count=0
    local success_count=0
    local fallback_count=0
    
    # Process applications with workspace assignments
    jq -c '.[]' "$app_mapping_file" 2>/dev/null | while read -r app; do
        local class=$(echo "$app" | jq -r '.class')
        local workspace=$(echo "$app" | jq -r '.workspace')
        local command=$(echo "$app" | jq -r '.command')
        
        if [[ -n "$class" && "$class" != "null" && -n "$workspace" && "$workspace" != "null" ]]; then
            ((app_count++))
            
            # Use class as command if no specific command provided
            if [[ -z "$command" || "$command" == "null" ]]; then
                command="$class"
            fi
            
            # Check if this application supports workspace launching
            local supports_workspace_launch=true
            case "$class" in
                "kitty"|"Alacritty"|"wezterm"|"firefox"|"chromium"|"google-chrome"|"code"|"vscodium"|"void")
                    # These applications typically support workspace launching
                    supports_workspace_launch=true
                    ;;
                *)
                    # For other applications, use workspace switching fallback
                    supports_workspace_launch=false
                    ((fallback_count++))
                    ;;
            esac
            
            if launch_application_to_workspace "$class" "$workspace" "$command"; then
                ((success_count++))
            fi
            
            # Stagger launches to prevent system overload
            sleep 2
        fi
    done
    
    if [[ $success_count -gt 0 ]]; then
        if [[ $fallback_count -gt 0 ]]; then
            log_success "Successfully launched $success_count/$app_count applications to target workspaces ($fallback_count using fallback method)"
        else
            log_success "Successfully launched $success_count/$app_count applications to target workspaces"
        fi
        return 0
    else
        log_warning "No applications successfully launched to target workspaces"
        return 1
    fi
}

# Window positioning and state restoration
restore_window_positions() {
    local window_file="${SESSION_STATE_DIR}/window_states.json"
    
    if [[ ! -f "$window_file" ]]; then
        log_warning "No window state file found for restoration"
        return 1
    fi
    
    log_info "Restoring window positions and states..."
    
    local window_count=0
    local restored_count=0
    
    # Process window positioning
    jq -c '.[]' "$window_file" 2>/dev/null | while read -r window; do
        local address=$(echo "$window" | jq -r '.address')
        local class=$(echo "$window" | jq -r '.class')
        local workspace=$(echo "$window" | jq -r '.workspace.id')
        local floating=$(echo "$window" | jq -r '.floating')
        local fullscreen=$(echo "$window" | jq -r '.fullscreen')
        local pinned=$(echo "$window" | jq -r '.pinned')
        
        if [[ -n "$address" && "$address" != "null" && -n "$workspace" && "$workspace" != "null" ]]; then
            ((window_count++))
            
            # Move window to correct workspace
            if hyprctl dispatch movetoworkspacesilent "$workspace,address:$address" > /dev/null 2>&1; then
                ((restored_count++))
                
                # Restore window state
                if [[ "$floating" == "true" ]]; then
                    hyprctl dispatch togglefloating "address:$address" > /dev/null 2>&1 || true
                fi
                
                if [[ "$fullscreen" == "true" ]]; then
                    hyprctl dispatch fullscreen "1,address:$address" > /dev/null 2>&1 || true
                fi
                
                if [[ "$pinned" == "true" ]]; then
                    hyprctl dispatch pin "address:$address" > /dev/null 2>&1 || true
                fi
            fi
        fi
    done
    
    if [[ $restored_count -gt 0 ]]; then
        log_success "Restored positions for $restored_count/$window_count windows"
        return 0
    else
        log_warning "No window positions restored"
        return 1
    fi
}

# Workspace focus restoration
restore_workspace_focus() {
    local active_workspace_file="${SESSION_STATE_DIR}/active_workspace.json"
    
    if [[ ! -f "$active_workspace_file" ]]; then
        log_info "No active workspace information found"
        return 0
    fi
    
    log_info "Restoring workspace focus..."
    
    local active_workspace=$(jq -r '.id' "$active_workspace_file" 2>/dev/null)
    
    if [[ -n "$active_workspace" && "$active_workspace" != "null" ]]; then
        if hyprctl dispatch workspace "$active_workspace" > /dev/null 2>&1; then
            log_success "Restored focus to workspace $active_workspace"
            return 0
        else
            log_warning "Failed to restore focus to workspace $active_workspace"
            return 1
        fi
    else
        log_info "No valid active workspace ID found"
        return 0
    fi
}

# Workspace restoration validation
validate_workspace_restoration() {
    local expected_layout="${SESSION_STATE_DIR}/workspace_layouts.json"
    local actual_layout="${SESSION_STATE_DIR}/current_workspaces.json"
    
    # Capture current state
    hyprctl workspaces -j > "$actual_layout" 2>/dev/null
    
    # Compare expected vs actual
    local expected_count=$(jq 'length' "$expected_layout" 2>/dev/null || echo "0")
    local actual_count=$(jq 'length' "$actual_layout" 2>/dev/null || echo "0")
    
    if [[ $actual_count -ge $expected_count ]]; then
        log_success "Workspace restoration validated: $actual_count/$expected_count workspaces created"
        return 0
    else
        log_warning "Partial workspace restoration: $actual_count/$expected_count workspaces created"
        return 1
    fi
}

# Enhanced window state restoration
restore_window_states() {
    log_info "Starting enhanced window state restoration..."
    
    # Phase 1: Create workspaces from layout
    create_workspaces_from_layout
    
    # Phase 2: Wait a moment for workspace creation to complete
    sleep 2
    
    # Phase 3: Restore window positions and states
    restore_window_positions
    
    # Phase 4: Restore workspace focus
    restore_workspace_focus
    
    # Phase 5: Validate restoration
    validate_workspace_restoration
    
    log_success "Enhanced window state restoration completed"
}

# Enhanced application restoration with workspace awareness
restore_applications() {
    log_info "Starting enhanced application restoration..."
    
    # Check for enhanced session data first
    local app_mapping_file="${SESSION_STATE_DIR}/application_workspace_mapping.json"
    local workspace_layout="${SESSION_STATE_DIR}/workspace_layouts.json"
    
    if [[ -f "$app_mapping_file" && -f "$workspace_layout" ]]; then
        log_info "Enhanced session data found - using workspace-aware restoration"
        restore_applications_with_workspaces
        return $?
    fi
    
    # Fallback to traditional restoration
    log_info "Enhanced session data not found - using traditional restoration"
    
    if [[ ! -f "${SESSION_STATE_DIR}/applications.txt" ]]; then
        log_warning "No saved application information found"
        return 1
    fi
    
    local count=0
    local success_count=0
    
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
            ((success_count++))
            
            # Small delay between application launches
            sleep 1
        fi
    done < "${SESSION_STATE_DIR}/applications.txt"
    
    if [[ $success_count -gt 0 ]]; then
        log_success "Successfully launched $success_count/$count applications"
        return 0
    else
        log_warning "No applications successfully launched"
        return 1
    fi
}

# Enhanced session restoration with quantum state support
restore_session() {
    log_info "Starting enhanced session restore with quantum state support..."
    
    if [[ ! -d "$SESSION_STATE_DIR" ]]; then
        log_error "No saved session found"
        return 1
    fi
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Source environment validation system (for fallback)
    source_environment_validation
    
    # Use enhanced restore with quantum state management
    enhanced_restore_session
    
    # Start quantum auto-save after successful restore
    start_quantum_auto_save
    
    log_success "Session restored successfully with quantum state support"
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

# Quantum state save command
quantum_save() {
    log_info "Starting quantum state save..."
    
    if ! is_hyprland_running; then
        log_error "Hyprland is not running - cannot save quantum state"
        return 1
    fi
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Capture and save quantum state
    if capture_quantum_state; then
        log_success "Quantum state saved successfully"
        return 0
    else
        log_error "Quantum state save failed"
        return 1
    fi
}

# Quantum state restore command
quantum_restore() {
    log_info "Starting quantum state restore..."
    
    if ! is_hyprland_running; then
        log_error "Hyprland is not running - cannot restore quantum state"
        return 1
    fi
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Load and restore quantum state
    if load_quantum_state; then
        log_success "Quantum state restored successfully"
        return 0
    else
        log_error "Quantum state restore failed"
        return 1
    fi
}

# Quantum state status command
quantum_status() {
    log_info "Quantum state status:"
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Get compatible states
    local quantum_manager_script="$(dirname "$0")/../../quantum-state-manager.py"
    if [[ -f "$quantum_manager_script" ]]; then
        local compatible_states=$(python3 "$quantum_manager_script" --validate 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "  Quantum state: Available and compatible"
        else
            echo "  Quantum state: Incompatible or unavailable"
        fi
        
        # Show quantum state files
        local quantum_state_dir="${SESSION_STATE_DIR}/quantum-state"
        if [[ -d "$quantum_state_dir" ]]; then
            local quantum_files=$(find "$quantum_state_dir" -name "quantum_state_*.json" | wc -l)
            echo "  Quantum state files: $quantum_files"
            
            # Show latest state
            local latest_state=$(find "$quantum_state_dir" -name "quantum_state_*.json" -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)
            if [[ -n "$latest_state" ]]; then
                local timestamp=$(stat -c %y "$latest_state" 2>/dev/null | cut -d'.' -f1)
                echo "  Latest state: $(basename "$latest_state") ($timestamp)"
            fi
        fi
    else
        echo "  Quantum State Manager: Not available"
    fi
}

# Quantum state migration command
quantum_migrate() {
    log_info "Starting quantum state migration..."
    
    # Initialize quantum state manager
    initialize_quantum_state_manager
    
    # Migrate legacy session data
    if migrate_legacy_to_quantum; then
        log_success "Legacy session data migrated to quantum state"
        return 0
    else
        log_error "Quantum state migration failed"
        return 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 {save|restore|clean|status|monitor-start|monitor-stop|monitor-status|quantum-save|quantum-restore|quantum-status|quantum-migrate|help}"
    echo ""
    echo "Commands:"
    echo "  save           - Save current Hyprland session with comprehensive application state"
    echo "  restore        - Restore saved Hyprland session with application state recovery"
    echo "  clean          - Clean saved session state"
    echo "  status         - Show session status"
    echo "  monitor-start  - Start environment monitoring daemon"
    echo "  monitor-stop   - Stop environment monitoring daemon"
    echo "  monitor-status - Show environment monitoring status"
    echo "  quantum-save   - Save quantum state (replaces broken environment metadata)"
    echo "  quantum-restore - Restore quantum state with advanced recovery"
    echo "  quantum-status - Show quantum state status and compatibility"
    echo "  quantum-migrate - Migrate legacy session data to quantum state"
    echo "  help           - Show this help message"
    echo ""
    echo "Quantum State Features:"
    echo "  • Advanced monitor layout persistence"
    echo "  • Comprehensive workspace state capture"
    echo "  • Application context recovery"
    echo "  • Terminal session restoration"
    echo "  • Browser session recovery"
    echo "  • Development environment tracking"
    echo "  • Real-time auto-save capabilities"
    echo ""
    echo "Application Support:"
    echo "  • Browsers: Firefox (session state)"
    echo "  • IDEs: VSCode, Void IDE (workspace state)"
    echo "  • Creative: Krita, GIMP (document state)"
    echo "  • Office: LibreOffice, Okular (document state)"
    echo "  • Terminals: Kitty, Terminator, Tmux (session state)"
    echo "  • File Managers: Dolphin (session state)"
    echo ""
    echo "Environment Features:"
    echo "  • Environment validation and monitoring"
    echo "  • Automatic session saving on environment changes"
    echo "  • Real-time directory monitoring"
    echo "  • Desktop notifications for detected changes"
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
        "monitor-start")
            start_environment_monitoring
            ;;
        "monitor-stop")
            stop_environment_monitoring
            ;;
        "monitor-status")
            show_environment_monitoring_status
            ;;
        "quantum-save")
            if is_hyprland_running; then
                quantum_save
            else
                log_error "Hyprland is not running - cannot save quantum state"
                exit 1
            fi
            ;;
        "quantum-restore")
            if is_hyprland_running; then
                quantum_restore
            else
                log_error "Hyprland is not running - cannot restore quantum state"
                exit 1
            fi
            ;;
        "quantum-status")
            quantum_status
            ;;
        "quantum-migrate")
            quantum_migrate
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