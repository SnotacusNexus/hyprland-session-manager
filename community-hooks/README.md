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

Use this template for all new hooks:

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
        
        # Save window positions
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
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

## 🎯 Popular Applications We'd Love Hooks For

- **Browsers**: Chrome, Chromium, Brave, Safari
- **IDEs**: IntelliJ, PyCharm, WebStorm, Neovim
- **Creative**: Blender, Inkscape, DaVinci Resolve
- **Office**: OnlyOffice, Microsoft Office (via Wine)
- **Media**: VLC, MPV, Spotify, Audacity
- **Development**: Docker, Postman, DBeaver
- **Utilities**: Discord, Slack, Telegram

## 🚀 Get Started!

1. **Pick an application** you use regularly
2. **Study its session management** (config files, session storage)
3. **Create hooks** using the template
4. **Test thoroughly** with different scenarios
5. **Submit your PR** and join the community!

---

**Your hooks help make Hyprland session management better for everyone!** 🎉