# Workspace Restoration Hooks Integration Guide

## Overview

The enhanced workspace-based save and restore functionality integrates seamlessly with the existing Hyprland Session Manager hook system. This guide explains how application-specific hooks can leverage the new workspace restoration capabilities.

## Enhanced Data Structures

### Workspace Layout Data
The session manager now captures comprehensive workspace information:

```json
{
  "workspaces": [
    {
      "id": 1,
      "name": "main",
      "monitor": "DP-1",
      "windows": 3,
      "hasfullscreen": false
    }
  ]
}
```

### Window State Data
Detailed window information including positions and states:

```json
[
  {
    "address": "0x12345678",
    "class": "firefox",
    "title": "Mozilla Firefox",
    "workspace": {
      "id": 1,
      "name": "main"
    },
    "at": [100, 50],
    "size": [1200, 800],
    "floating": false,
    "fullscreen": false,
    "pinned": false
  }
]
```

### Application-Workspace Mapping
Links applications to their target workspaces:

```json
[
  {
    "class": "firefox",
    "workspace": 1,
    "title": "Mozilla Firefox",
    "command": "firefox"
  }
]
```

## Integration with Existing Hooks

### Pre-Save Hooks
Application-specific pre-save hooks continue to work as before. The enhanced workspace data is captured automatically alongside existing hook data.

**Example: VSCode Pre-Save Hook**
```bash
# Pre-save hook continues to save application-specific data
save_vscode_session() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    mkdir -p "$app_state_dir"
    
    # Save window information (now enhanced with workspace data)
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Window positions now include workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt"
        
        # Workspace assignments are automatically captured
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt"
    fi
    
    # Application-specific session data
    save_vscode_workspace_storage "$app_state_dir"
}
```

### Post-Restore Hooks
Post-restore hooks can now leverage the enhanced workspace data for better restoration.

**Example: Enhanced VSCode Post-Restore Hook**
```bash
restore_vscode_session() {
    local app_class="$(get_vscode_class)"
    local app_state_dir="${SESSION_STATE_DIR}/vscode"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No VSCode session data to restore"
        return
    fi
    
    log_info "Restoring VSCode session with workspace support..."
    
    # Check if workspace restoration data exists
    local workspace_layout="${SESSION_STATE_DIR}/workspace_layouts.json"
    if [[ -f "$workspace_layout" ]]; then
        log_info "Workspace layout data available - VSCode will be restored to correct workspace"
    fi
    
    # Launch VSCode (workspace assignment handled by main restoration)
    launch_vscode_with_session
    
    # Application-specific restoration continues
    restore_vscode_workspace_storage "$app_state_dir"
}
```

## New Hook Capabilities

### 1. Workspace-Aware Application Launching
Hooks can now check which workspace an application should be launched to:

```bash
# In post-restore hook
get_application_workspace() {
    local app_class="$1"
    local app_mapping="${SESSION_STATE_DIR}/application_workspace_mapping.json"
    
    if [[ -f "$app_mapping" ]]; then
        local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "$app_mapping" 2>/dev/null)
        echo "$workspace"
    else
        echo ""
    fi
}

# Usage in hook
target_workspace=$(get_application_workspace "firefox")
if [[ -n "$target_workspace" ]]; then
    log_info "Firefox should be launched to workspace $target_workspace"
fi
```

### 2. Window Position Validation
Hooks can verify window positioning after restoration:

```bash
validate_window_restoration() {
    local app_class="$1"
    local expected_positions="${SESSION_STATE_DIR}/vscode/positions.txt"
    
    if [[ -f "$expected_positions" ]]; then
        local current_windows=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length")
        local expected_windows=$(wc -l < "$expected_positions")
        
        if [[ $current_windows -eq $expected_windows ]]; then
            log_success "Window restoration validated: $current_windows windows"
        else
            log_warning "Partial window restoration: $current_windows/$expected_windows windows"
        fi
    fi
}
```

## Backward Compatibility

### Existing Hooks Continue Working
- All existing pre-save and post-restore hooks continue to function
- No changes required to current hook implementations
- Enhanced workspace data is captured automatically

### Fallback Behavior
If enhanced workspace data is not available, the system falls back to:
1. Basic application restoration (original behavior)
2. Individual hook execution for window positioning
3. No workspace assignment - applications launch to current workspace

## Best Practices for Hook Development

### 1. Leverage Workspace Data
When creating new hooks, use the enhanced workspace information:

```bash
# Good: Check workspace assignments
if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
    local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json")
    log_info "Application $app_class assigned to workspace $workspace"
fi
```

### 2. Maintain Backward Compatibility
Ensure hooks work with both old and new session data:

```bash
# Check for both old and new data formats
if [[ -f "${SESSION_STATE_DIR}/applications.txt" ]]; then
    # Old format available
    process_old_format
fi

if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
    # New format available
    process_new_format
fi
```

### 3. Coordinate with Main Restoration
Hooks should focus on application-specific data while letting the main system handle workspace management:

```bash
# Focus on application data
restore_application_data() {
    # Application-specific restoration logic
    # ...
    
    # Let main system handle workspace assignment
    log_info "Workspace assignment handled by main restoration system"
}
```

## Testing Hook Integration

### Test Script for Hook Developers
```bash
#!/usr/bin/env zsh
# test-hook-integration.sh

test_hook_workspace_integration() {
    local app_class="$1"
    
    echo "Testing workspace integration for $app_class..."
    
    # Check if workspace data exists
    if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
        local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
        
        if [[ -n "$workspace" && "$workspace" != "null" ]]; then
            echo "✓ $app_class mapped to workspace $workspace"
            return 0
        else
            echo "✗ No workspace mapping found for $app_class"
            return 1
        fi
    else
        echo "✗ No application workspace mapping file found"
        return 1
    fi
}

# Test specific applications
test_hook_workspace_integration "firefox"
test_hook_workspace_integration "code"
test_hook_workspace_integration "kitty"
```

## Migration Guide

### For Existing Hook Maintainers
1. **No immediate changes required** - existing hooks continue working
2. **Optional enhancements** - can leverage new workspace data for better restoration
3. **Testing recommended** - verify hooks work with enhanced session data

### For New Hook Development
1. **Use workspace-aware patterns** - check for workspace assignments
2. **Maintain compatibility** - support both old and new data formats
3. **Focus on application data** - let main system handle workspace management

## Performance Considerations

### Hook Execution Order
- Pre-save hooks run before workspace data capture
- Post-restore hooks run after workspace restoration
- This ensures hooks have access to complete session state

### Data Access Patterns
```bash
# Efficient: Check for enhanced data
if [[ -f "${SESSION_STATE_DIR}/workspace_layouts.json" ]]; then
    # Use enhanced data
    process_enhanced_restoration
else
    # Fallback to basic restoration
    process_basic_restoration
fi
```

## Conclusion

The enhanced workspace restoration functionality provides significant improvements while maintaining full backward compatibility with existing hooks. Hook developers can gradually adopt the new capabilities while ensuring their hooks continue to work with both old and new session data formats.

For questions or issues with hook integration, refer to the main session manager documentation or create an issue in the project repository.