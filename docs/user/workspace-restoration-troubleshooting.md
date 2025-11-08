# Workspace Restoration Troubleshooting Guide

## Overview

This guide helps diagnose and resolve common issues with workspace-based session management in the Hyprland session manager.

## Common Issues and Solutions

### 1. Workspace Layouts Not Restoring

**Symptoms:**
- Applications restore but workspace layouts are incorrect
- Windows appear in wrong workspaces
- Workspace order is scrambled

**Solutions:**

1. **Check Enhanced Data Files:**
   ```bash
   ls -la ~/.config/hyprland-session-manager/session-state/
   ```
   Verify these files exist:
   - `workspace_layouts.json`
   - `application_workspace_mapping.json`
   - `window_states.json`

2. **Verify Hyprland Version:**
   ```bash
   hyprctl version
   ```
   Ensure you're running Hyprland v0.40.0 or later for full workspace support.

3. **Check Session Data Integrity:**
   ```bash
   # Validate workspace layouts
   jq . ~/.config/hyprland-session-manager/session-state/workspace_layouts.json
   
   # Validate application mapping
   jq . ~/.config/hyprland-session-manager/session-state/application_workspace_mapping.json
   ```

4. **Enable Debug Mode:**
   ```bash
   export HYPRLAND_SESSION_DEBUG=1
   ./session-manager.sh restore
   ```

### 2. Terminal Environment Not Restoring

**Symptoms:**
- Terminal windows open but don't restore to correct directories
- Environment variables not preserved
- Terminal sessions incomplete

**Solutions:**

1. **Check Terminal Support:**
   - Verify your terminal supports IPC (Kitty, Alacritty work best)
   - Check if terminal is running with proper permissions

2. **Enable Terminal Debug:**
   ```bash
   export TERMINAL_RESTORATION_DEBUG=1
   ./session-manager.sh save
   ```

3. **Verify Process Access:**
   ```bash
   # Check if session manager can access terminal processes
   ls -la /proc/$(pgrep kitty)/cwd
   ```

4. **Manual Terminal Testing:**
   ```bash
   # Test Kitty remote control
   kitty @ ls
   
   # Test environment capture
   readlink /proc/$(pgrep kitty)/cwd
   ```

### 3. Application Workspace Mapping Issues

**Symptoms:**
- Applications launch in wrong workspaces
- Multiple instances of same app in different workspaces
- Workspace assignments inconsistent

**Solutions:**

1. **Check Application Mapping:**
   ```bash
   jq . ~/.config/hyprland-session-manager/session-state/application_workspace_mapping.json
   ```

2. **Verify Window Classes:**
   ```bash
   hyprctl clients -j | jq -r '.[] | "\(.class): \(.workspace.id)"'
   ```

3. **Reset Application Mapping:**
   ```bash
   rm ~/.config/hyprland-session-manager/session-state/application_workspace_mapping.json
   ./session-manager.sh save
   ```

### 4. Performance Issues During Restoration

**Symptoms:**
- Session restoration takes too long
- System becomes unresponsive
- Applications launch slowly

**Solutions:**

1. **Check System Resources:**
   ```bash
   # Monitor during restoration
   htop
   ```

2. **Optimize Hook Performance:**
   - Review slow-running hooks
   - Add delays between application launches
   - Use parallel execution where safe

3. **Enable Performance Logging:**
   ```bash
   export SESSION_PERFORMANCE_LOG=1
   ./session-manager.sh restore
   ```

### 5. Backward Compatibility Issues

**Symptoms:**
- Traditional sessions not working after upgrade
- Missing application data
- Session files not recognized

**Solutions:**

1. **Check Session Data Format:**
   ```bash
   # Check if enhanced data exists
   ls -la ~/.config/hyprland-session-manager/session-state/*.json
   
   # Check traditional session data
   ls -la ~/.config/hyprland-session-manager/session-state/applications/
   ```

2. **Force Traditional Mode:**
   ```bash
   export SESSION_MODE=traditional
   ./session-manager.sh restore
   ```

3. **Migration Testing:**
   ```bash
   # Test migration from traditional to enhanced
   ./test-backward-compatibility.sh
   ```

## Debug Mode

Enable comprehensive debugging to diagnose issues:

```bash
# Enable all debug modes
export HYPRLAND_SESSION_DEBUG=1
export TERMINAL_RESTORATION_DEBUG=1
export SESSION_PERFORMANCE_LOG=1
export WORKSPACE_RESTORATION_DEBUG=1

# Run with debug output
./session-manager.sh save 2>&1 | tee /tmp/session-debug.log
./session-manager.sh restore 2>&1 | tee /tmp/restore-debug.log
```

## Log Analysis

### Key Log Patterns to Monitor

1. **Workspace Restoration:**
   ```
   [INFO] Restoring workspace layouts...
   [SUCCESS] Workspace 1 layout restored
   [ERROR] Failed to restore workspace 2 layout
   ```

2. **Application Launching:**
   ```
   [INFO] Launching application: kitty on workspace 1
   [SUCCESS] Application launched successfully
   [WARNING] Application already running, focusing instead
   ```

3. **Terminal Environment:**
   ```
   [INFO] Restoring terminal environment for kitty
   [SUCCESS] Terminal directory restored: /home/user/projects
   [ERROR] Failed to restore terminal environment
   ```

### Common Error Messages

```
# Workspace errors
"Failed to create workspace"
"Workspace layout file missing"
"Invalid workspace ID"

# Application errors  
"Application not found"
"Failed to launch application"
"Window class mismatch"

# Terminal errors
"Terminal IPC not available"
"Process directory inaccessible"
"Environment restoration failed"
```

## System Requirements Verification

### Required Tools
```bash
# Check if required tools are installed
command -v hyprctl && echo "✓ Hyprland control available" || echo "✗ Hyprland control missing"
command -v jq && echo "✓ JSON processor available" || echo "✗ JSON processor missing"
command -v kitty && echo "✓ Kitty available" || echo "✗ Kitty missing (optional)"
```

### File Permissions
```bash
# Check session directory permissions
ls -la ~/.config/hyprland-session-manager/
ls -la ~/.config/hyprland-session-manager/session-state/
```

### Hyprland Configuration
```bash
# Check Hyprland config for workspace settings
grep -E "(workspace|monitor)" ~/.config/hypr/hyprland.conf
```

## Performance Optimization

### Session Save Optimization

1. **Reduce Data Collection:**
   ```bash
   # Limit workspace data collection
   export WORKSPACE_DATA_LIMIT=10
   ```

2. **Optimize Hook Execution:**
   - Run hooks in parallel where possible
   - Add timeouts for slow hooks
   - Cache expensive operations

### Session Restore Optimization

1. **Stagger Application Launch:**
   ```bash
   # Add delays between application launches
   export APPLICATION_LAUNCH_DELAY=1
   ```

2. **Prioritize Critical Applications:**
   - Launch terminal and browser first
   - Delay non-critical applications
   - Use workspace-based prioritization

## Testing and Validation

### Quick Health Check
```bash
# Run comprehensive health check
./test-workspace-restoration.sh
./test-enhanced-session-data.sh
./test-backward-compatibility.sh
```

### Manual Testing Steps

1. **Save Session:**
   ```bash
   ./session-manager.sh save
   ```

2. **Verify Data:**
   ```bash
   # Check enhanced data
   jq . ~/.config/hyprland-session-manager/session-state/workspace_layouts.json
   jq . ~/.config/hyprland-session-manager/session-state/application_workspace_mapping.json
   ```

3. **Restore Session:**
   ```bash
   ./session-manager.sh restore
   ```

4. **Verify Restoration:**
   - Check workspace layouts
   - Verify application positions
   - Confirm terminal environments

## Recovery Procedures

### Reset Session Data
```bash
# Complete reset
rm -rf ~/.config/hyprland-session-manager/session-state/
mkdir -p ~/.config/hyprland-session-manager/session-state/
```

### Fallback to Traditional Mode
```bash
# Force traditional session mode
export SESSION_MODE=traditional
./session-manager.sh restore
```

### Manual Workspace Restoration
```bash
# Manual workspace creation if automatic fails
hyprctl dispatch workspace 1
hyprctl dispatch workspace 2
# etc.
```

## Getting Help

If issues persist:

1. **Check Documentation:**
   - [Workspace Restoration User Guide](workspace-restoration-user-guide.md)
   - [Terminal Environment Restoration](terminal-environment-restoration.md)
   - [Migration Guide](workspace-restoration-migration-guide.md)

2. **Community Support:**
   - Check GitHub issues
   - Join Hyprland community channels
   - Review community hooks for examples

3. **Debug Information:**
   Collect and share:
   - Debug logs
   - System information
   - Session data samples
   - Error messages