# 🤝 Community Hooks Directory

Welcome to the community hooks directory! This is where community members can contribute their custom application session save and restore scripts.

## 🎯 How to Contribute Your Hooks

### Quick Start
1. **Fork the repository**
2. **Create your hooks** in this directory
3. **Test thoroughly** with your application
4. **Submit a pull request**
5. **Get your hooks merged** into the main project!

### Hook Structure
```
community-hooks/
├── pre-save/
│   ├── your-app.sh          # Your pre-save hook
│   └── another-app.sh       # Another pre-save hook
└── post-restore/
    ├── your-app.sh          # Your post-restore hook
    └── another-app.sh       # Another post-restore hook
```

## 📋 Contribution Guidelines

### Required for All Hooks
- ✅ **Follow the template** structure
- ✅ **Test thoroughly** with the actual application
- ✅ **Handle errors gracefully**
- ✅ **Include proper logging**
- ✅ **Document any requirements**
- ✅ **Use Zsh syntax** consistently

### Quality Standards
- **Reliability**: Hooks should work consistently
- **Safety**: No destructive operations without confirmation
- **Performance**: Minimal impact on session save/restore times
- **Compatibility**: Works across different Hyprland setups

### Naming Convention
- Use **lowercase** with hyphens: `my-app.sh`
- Be **descriptive**: `obsidian-sessions.sh` not `obsidian.sh`
- Include **application name**: `firefox-tabs.sh`

## 🚀 Hook Template

Use this template for all new hooks. For workspace-aware hooks, see the enhanced template below.

```bash
#!/usr/bin/env zsh

# [APP NAME] Session Management Hook
# Community contributed by: [Your GitHub Username]
# Pre-save/Post-restore hook for [App Name] session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[APP-NAME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[APP-NAME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[APP-NAME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[APP-NAME HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS (for pre-save hooks)
# ============================================================================

# Detect if application is running
is_app_running() {
    if pgrep -x "appname" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get application window class
get_app_class() {
    echo "appname"  # Replace with actual window class
}

# Save application session data
save_app_session() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/appname"
    
    log_info "Saving [App Name] session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions (workspace data automatically captured by enhanced system)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Optional: Leverage enhanced workspace data when available
        if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
            local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
            if [[ -n "$workspace" && "$workspace" != "null" ]]; then
                log_info "Application workspace assignment detected: $workspace"
            fi
        fi
    fi
    
    # Add your application-specific session saving logic here
    # Example: Save configuration files, session data, etc.
    
    log_success "[App Name] session data saved"
}

# ============================================================================
# POST-RESTORE HOOK FUNCTIONS (for post-restore hooks)
# ============================================================================

# Restore application session data
restore_app_session() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/appname"
    
    if [[ ! -d "$app_state_dir" ]]; then
        log_info "No [App Name] session data to restore"
        return
    fi
    
    log_info "Restoring [App Name] session..."
    
    # Add your application-specific session restoration logic here
    # Example: Restore configuration files, session data, etc.
    
    # Optional: Check workspace assignment (workspace positioning handled by main system)
    if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
        local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
        if [[ -n "$workspace" && "$workspace" != "null" ]]; then
            log_info "Application will be restored to workspace $workspace"
        fi
    fi
    
    log_success "[App Name] session restoration completed"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting [App Name] pre-save hook..."
    
    if is_app_running; then
        save_app_session
        log_success "[App Name] pre-save hook completed"
    else
        log_info "[App Name] not running - nothing to save"
    fi
}

# Post-restore hook main function
post_restore_main() {
    log_info "Starting [App Name] post-restore hook..."
    
    restore_app_session
    
    log_success "[App Name] post-restore hook completed"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        pre_save_main
        ;;
    "post-restore")
        post_restore_main
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac
```

## 🧪 Testing Your Hooks

Before submitting, test thoroughly:

```bash
# Test pre-save hook
./community-hooks/pre-save/your-app.sh pre-save

# Test post-restore hook  
./community-hooks/post-restore/your-app.sh post-restore

# Test with debug mode
HYPRLAND_SESSION_DEBUG=1 ./community-hooks/pre-save/your-app.sh pre-save
```

## 📝 Pull Request Checklist

- [ ] Hook follows the template structure
- [ ] Both pre-save and post-restore hooks included
- [ ] Tested with the actual application
- [ ] Error handling implemented
- [ ] Logging included
- [ ] No destructive operations
- [ ] Documentation updated (if needed)
- [ ] Works across different setups

## 🏆 Recognition

All accepted hooks will:
- Be **merged into the main project**
- Have **contributor credit** in the README
- Be **automatically included** in future releases
- Help **thousands of Hyprland users**

## 🎯 Available Community Hooks (30 Total Hooks - 15 Applications)

### Complete Application Coverage (All 15 Applications ✅)
- **🌐 Firefox**: Complete session restoration with tabs, profiles, and window positions
- **🌐 Chrome/Chromium**: Complete session restoration with tabs, profiles, and window positions
- **🌐 Thorium Browser**: Full session restoration with tabs and profiles
- **💻 VSCode**: Workspace state and project recovery with layout preservation
- **💻 Void IDE**: Workspace and project state preservation with configuration backup
- **🖥️ Kitty**: Terminal session and layout restoration with workspace integration
- **🖥️ Terminator**: Window layouts and session management with layout file backup and workspace integration
- **💬 Discord**: Server/channel state preservation and window positioning
- **💬 Slack**: Workspace/channel state management and session recovery
- **💬 Telegram**: Chat session preservation and conversation state
- **💬 Signal**: Conversation state management and chat sessions
- **📝 Obsidian**: Vault sessions and note state preservation
- **🎨 Krita**: Document recovery and window positions with recovery file management
- **📄 LibreOffice**: Open documents and window state with document session management
- **📁 Dolphin**: Directory state and window layout with navigation preservation

### Featured High-Quality Implementations
- **🌐 Firefox**: Comprehensive session restoration with tab recovery and profile support
- **🌐 Thorium Browser**: Complete session restoration with profile support and tab recovery
- **💻 VSCode**: Advanced workspace state recovery with project configuration backup
- **💬 Telegram Desktop**: Complete chat session preservation with conversation state
- **🖥️ Kitty Terminal**: Advanced terminal session management with layout restoration and workspace integration
- **💻 Void IDE**: Full workspace and project state recovery with configuration backup
- **💬 Signal Desktop**: Complete conversation state management and chat session preservation
- **🖥️ Terminator Terminal**: Window layouts and session management with layout file backup and workspace integration
- **🎨 Krita**: Document recovery system with automatic recovery file management
- **📄 LibreOffice**: Document session management with open document state preservation

### Popular Applications We'd Love Hooks For
- **Browsers**: Brave, Safari, Edge
- **IDEs**: IntelliJ, PyCharm, WebStorm, Neovim, Emacs
- **Creative**: Blender, Inkscape, DaVinci Resolve, GIMP
- **Office**: OnlyOffice, Microsoft Office (via Wine), Okular
- **Media**: VLC, MPV, Spotify, Audacity, OBS Studio
- **Development**: Docker, Postman, DBeaver, GitKraken
- **Utilities**: Teams, Zoom, Element, Thunderbird

## 📋 Current Hook Status & Limitations

### Fully Functional Hooks (All 15 Applications)
- **🌐 Firefox**: Complete session restoration with tabs, profiles, and window positions
- **🌐 Chrome/Chromium**: Complete session restoration with tabs, profiles, and window positions
- **🌐 Thorium Browser**: Full session restoration with tabs and profiles
- **💻 VSCode**: Workspace state and project recovery with layout preservation
- **💻 Void IDE**: Workspace and project state preservation with configuration backup
- **🖥️ Kitty**: Terminal session and layout restoration (basic support with limitations)
- **🖥️ Terminator**: Window layouts and session management with layout file backup
- **💬 Discord**: Server/channel state preservation and window positioning
- **💬 Slack**: Workspace/channel state management and session recovery
- **💬 Telegram**: Chat session preservation and conversation state
- **💬 Signal**: Conversation state management and chat sessions
- **📝 Obsidian**: Vault sessions and note state preservation
- **🎨 Krita**: Document recovery and window positions with recovery file management
- **📄 LibreOffice**: Open documents and window state with document session management
- **📁 Dolphin**: Directory state and window layout with navigation preservation

### Hooks with Known Limitations
- **🖥️ Kitty Terminal**: Enhanced session support with workspace integration:
  - Complex terminal sessions may not restore completely
  - Running processes in terminals are not preserved
  - Session restoration works best with simple shell sessions
  - Now includes workspace positioning and environment restoration
- **🖥️ Terminator Terminal**: Layout restoration with workspace integration:
  - Running processes are not preserved
  - Complex terminal layouts may have partial restoration
  - Enhanced with workspace positioning support

### Performance & Compatibility Notes
- All 30 hooks (15 pre-save + 15 post-restore) have been tested for performance and show acceptable execution times
- Hooks follow established patterns and are ready for community use
- Some applications may require specific installation paths or configurations
- Terminal applications have inherent limitations in preserving running processes
- All hooks have been validated and pass comprehensive testing

## 🚀 Get Started!

1. **Pick an application** you use regularly
2. **Study its session management** (config files, session storage)
3. **Create hooks** using the template
4. **Test thoroughly** with different scenarios
5. **Submit your PR** and join the community!

## 🏗️ Workspace-Aware Hook Development

### Enhanced Hook Template

For applications that benefit from workspace integration, use this enhanced template:

```bash
# Enhanced save function with workspace awareness
save_app_session_enhanced() {
    local app_class="$(get_app_class)"
    local app_state_dir="${SESSION_STATE_DIR}/appname"
    
    log_info "Saving [App Name] session data with workspace integration..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions (workspace data automatically captured by enhanced system)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Leverage enhanced workspace data when available
        if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
            local workspace=$(jq -r ".[] | select(.class == \"$app_class\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
            if [[ -n "$workspace" && "$workspace" != "null" ]]; then
                log_info "Application workspace assignment detected: $workspace"
                # Save workspace-specific application data
                save_workspace_specific_data "$app_class" "$workspace" "$app_state_dir"
            fi
        fi
    fi
    
    log_success "[App Name] session data saved with workspace integration"
}
```

### Terminal Environment Restoration

For terminal applications, consider implementing environment and path restoration:

```bash
# Terminal-specific environment saving
save_terminal_environment() {
    local app_class="$1"
    local window="$2"
    local workspace="$3"
    local pid="$4"
    
    local state_file="${SESSION_STATE_DIR}/terminal-environments/${app_class}_${window}.json"
    
    # Get current directory from process
    local current_dir=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "")
    
    # Save terminal state
    cat > "$state_file" << EOF
{
  "window_address": "$window",
  "workspace": $workspace,
  "current_directory": "$current_dir",
  "shell_pid": $pid,
  "timestamp": "$(date -Iseconds)"
}
EOF
}
```

See [terminal-environment-restoration.md](../terminal-environment-restoration.md) for complete implementation details.

### Workspace Integration Benefits

- **Automatic Positioning**: Applications restore to their original workspaces
- **Layout Coordination**: Works with main system's workspace layout restoration
- **Enhanced Data**: Access to workspace-specific application data
- **Backward Compatibility**: Maintains functionality with traditional session data

---

**Your hooks help make Hyprland session management better for everyone!** 🎉