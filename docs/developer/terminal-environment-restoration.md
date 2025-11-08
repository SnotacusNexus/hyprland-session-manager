# Terminal Environment and Path Restoration

## Overview

The enhanced workspace-based session management system now includes comprehensive terminal environment and path restoration capabilities with integrated environment validation. This feature allows terminal applications to save their current working directory, environment variables, shell state, and development environment context, enabling complete restoration of terminal sessions across system restarts with validation of required environments.

## Key Features

- **Current Working Directory Preservation**: Saves and restores the current path for each terminal window
- **Environment Variable Capture**: Preserves shell environment state
- **Development Environment Validation**: Validates conda, mamba, venv, and pyenv environments
- **Environment Health Checking**: Tests environment functionality before restoration
- **Application-Specific Integration**: Works with popular terminal emulators
- **Workspace-Aware Positioning**: Terminal windows restore to their original workspaces
- **Graceful Degradation**: Falls back gracefully when full restoration isn't possible
- **Environment Metadata Capture**: Stores comprehensive environment information for validation

## Supported Terminal Applications

| Application | Class Name | Environment Support | Path Restoration |
|-------------|------------|---------------------|------------------|
| Kitty | `kitty` | ✅ Full | ✅ Full |
| Alacritty | `Alacritty` | ✅ Full | ✅ Full |
| GNOME Terminal | `gnome-terminal` | ✅ Full | ✅ Full |
| Konsole | `konsole` | ✅ Full | ✅ Full |
| Terminator | `terminator` | ✅ Full | ✅ Full |
| XTerm | `xterm` | ⚠️ Limited | ⚠️ Limited |
| Generic Terminals | `*terminal*` | ⚠️ Basic | ⚠️ Basic |

## Implementation Details

### Data Capture

Terminal environment data is captured during the session save process, including development environment validation:

```json
{
  "terminal_states": {
    "kitty": [
      {
        "window_address": "0x12345678",
        "workspace": 1,
        "current_directory": "/home/user/projects/my-project",
        "environment": {
          "PWD": "/home/user/projects/my-project",
          "TERM": "xterm-kitty",
          "SHELL": "/bin/zsh",
          "PATH": "/usr/local/bin:/usr/bin:/bin",
          "custom_vars": {
            "MY_PROJECT_ENV": "development"
          }
        },
        "shell_pid": 12345,
        "timestamp": "2024-01-15T10:30:00Z",
        "development_environment": {
          "type": "conda",
          "name": "my-project-env",
          "path": "/home/user/miniconda3/envs/my-project-env",
          "status": "active",
          "python_version": "3.11.5",
          "packages": ["numpy", "pandas", "matplotlib"]
        }
      }
    ]
  },
  "environment_metadata": {
    "environments": [
      {
        "type": "conda",
        "name": "my-project-env",
        "path": "/home/user/miniconda3/envs/my-project-env",
        "status": "active",
        "validation": {
          "exists": true,
          "healthy": true,
          "python_available": true,
          "packages_available": true
        }
      },
      {
        "type": "venv",
        "name": "test-env",
        "path": "/home/user/projects/test-env",
        "status": "inactive",
        "validation": {
          "exists": true,
          "healthy": true,
          "python_available": true
        }
      }
    ]
  }
}
```

### Enhanced Hook Functions with Environment Validation

#### Pre-Save Hook Example with Environment Validation

```bash
#!/usr/bin/env zsh
# hooks/pre-save/terminal-environment.sh

save_terminal_environment() {
    local app_class="$1"
    local app_state_dir="${SESSION_STATE_DIR}/terminal-environments"
    
    mkdir -p "$app_state_dir"
    
    # Get terminal windows
    local terminal_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address")
    
    for window in $terminal_windows; do
        local window_data=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$window\")")
        local workspace=$(echo "$window_data" | jq -r '.workspace.id')
        local pid=$(echo "$window_data" | jq -r '.pid')
        
        # Save terminal environment data with development environment context
        save_terminal_state "$app_class" "$window" "$workspace" "$pid"
    done
}

save_terminal_state() {
    local app_class="$1"
    local window="$2"
    local workspace="$3"
    local pid="$4"
    
    local state_file="${SESSION_STATE_DIR}/terminal-environments/${app_class}_${window}.json"
    
    # Get current directory from process
    local current_dir=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "")
    
    # Get environment variables
    local env_vars=""
    if [[ -f "/proc/$pid/environ" ]]; then
        env_vars=$(cat "/proc/$pid/environ" | tr '\0' '\n' | grep -E "^(PWD|TERM|SHELL|PATH|HOME|CONDA_DEFAULT_ENV|VIRTUAL_ENV|PYENV_VERSION)=")
    fi
    
    # Detect development environment
    local dev_env_data=$(detect_active_environment)
    
    cat > "$state_file" << EOF
{
  "window_address": "$window",
  "workspace": $workspace,
  "current_directory": "$current_dir",
  "environment": $(echo "$env_vars" | jq -R -s 'split("\n") | map(select(. != "")) | map(split("=")) | map({(.[0]): .[1]}) | add'),
  "shell_pid": $pid,
  "timestamp": "$(date -Iseconds)",
  "development_environment": $dev_env_data
}
EOF
}
```

#### Post-Restore Hook Example

```bash
#!/usr/bin/env zsh
# hooks/post-restore/terminal-environment.sh

restore_terminal_environment() {
    local app_class="$1"
    local app_state_dir="${SESSION_STATE_DIR}/terminal-environments"
    
    if [[ ! -d "$app_state_dir" ]]; then
        return 0
    fi
    
    # Find terminal state files for this application
    local state_files=("${app_state_dir}/${app_class}_"*.json)
    
    for state_file in $state_files; do
        if [[ -f "$state_file" ]]; then
            restore_terminal_state "$app_class" "$state_file"
        fi
    done
}

restore_terminal_state() {
    local app_class="$1"
    local state_file="$2"
    
    local window=$(jq -r '.window_address' "$state_file")
    local workspace=$(jq -r '.workspace' "$state_file")
    local current_dir=$(jq -r '.current_directory' "$state_file")
    local env_vars=$(jq -r '.environment' "$state_file")
    
    # Find the restored terminal window
    local new_window=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\" and .workspace.id == $workspace) | .address" | head -1)
    
    if [[ -n "$new_window" && -n "$current_dir" && "$current_dir" != "null" ]]; then
        # Change to the saved directory
        hyprctl dispatch focuswindow "address:$new_window"
        # Send change directory command (application-specific)
        send_terminal_command "$app_class" "$new_window" "cd \"$current_dir\""
    fi
}

send_terminal_command() {
    local app_class="$1"
    local window="$2"
    local command="$3"
    
    case "$app_class" in
        "kitty")
            # Kitty remote control
            kitty @ --to "unix:/tmp/kitty_$window" send-text "$command\n" 2>/dev/null || true
            ;;
        "Alacritty")
            # Alacritty IPC (if available)
            echo "$command" | socat - UNIX-CONNECT:"/tmp/alacritty_$window" 2>/dev/null || true
            ;;
        *)
            # Generic fallback - focus and simulate typing
            hyprctl dispatch focuswindow "address:$window"
            sleep 0.1
            # Use xdotool or similar for generic terminals
            xdotool type --window "$window" "$command"
            xdotool key --window "$window" Return
            ;;
    esac
}
```

## Configuration

### Session Manager Integration

The terminal environment restoration is integrated into the main session manager:

```bash
# Enhanced session data capture includes terminal environments
capture_enhanced_session_data() {
    extract_workspace_layouts
    capture_window_states
    create_application_mapping
    capture_terminal_environments  # New function
}

capture_terminal_environments() {
    log_info "Capturing terminal environment data..."
    
    # Supported terminal applications
    local terminal_apps=("kitty" "Alacritty" "gnome-terminal" "konsole" "terminator")
    
    for app in $terminal_apps; do
        if pgrep -x "$app" > /dev/null; then
            save_terminal_environment "$app"
        fi
    done
}
```

### User Configuration

Users can customize terminal restoration behavior:

```bash
# In session manager configuration
TERMINAL_RESTORATION_ENABLED=true
TERMINAL_PATH_RESTORATION=true
TERMINAL_ENVIRONMENT_RESTORATION=true
TERMINAL_COMMAND_HISTORY=false  # Optional: restore command history
```

## Usage Examples

### Basic Usage

1. **Save Session**: Terminal windows automatically capture environment data
2. **Restore Session**: Terminal windows restore with correct paths and environments
3. **Workspace Integration**: Terminals return to their original workspaces

### Advanced Configuration

```bash
# Custom terminal applications
CUSTOM_TERMINAL_APPS=("my-terminal" "custom-term")

# Environment variables to preserve
PRESERVE_ENV_VARS=("PWD" "TERM" "SHELL" "PATH" "HOME" "EDITOR" "LANG")

# Exclude specific directories
EXCLUDE_PATHS=("/tmp" "/dev" "/proc")
```

## Troubleshooting

### Common Issues

1. **Path Restoration Fails**
   - Check if terminal supports IPC
   - Verify process permissions
   - Ensure terminal is fully initialized before restoration

2. **Environment Variables Not Preserved**
   - Some terminals don't expose environment via /proc
   - Use terminal-specific IPC methods when available

3. **Workspace Positioning Issues**
   - Verify workspace data is captured correctly
   - Check for workspace conflicts

### Debug Mode

Enable debug logging for terminal restoration:

```bash
export TERMINAL_RESTORATION_DEBUG=1
./session-manager.sh save
```

## Best Practices

1. **Application Support**: Prioritize terminals with good IPC support
2. **Fallback Strategies**: Implement graceful degradation for unsupported features
3. **User Experience**: Provide clear feedback during restoration
4. **Performance**: Cache environment data to avoid excessive process inspection
5. **Security**: Sanitize environment data and avoid sensitive information

## Integration with Workspace System

The terminal environment restoration integrates seamlessly with the workspace-based session management:

- **Workspace Context**: Terminal paths are workspace-specific
- **Application Mapping**: Terminal windows map to their original workspaces
- **Layout Preservation**: Terminal positions and sizes are preserved
- **State Coordination**: Environment restoration occurs after window positioning

## Future Enhancements

- [ ] Shell history restoration
- [ ] Terminal theme and appearance preservation
- [ ] Tab and split-pane restoration for terminal multiplexers
- [ ] SSH session reconnection
- [ ] Docker container session preservation