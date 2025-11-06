# 🚀 Hyprland Session Manager with Systemd Integration - Complete Implementation Guide

## 🎯 Project Overview
Create a robust session manager for Hyprland that enables session resume functionality with systemd integration. Target environment: Arch Linux with ZFS root filesystem and Zsh shell.

## 📋 Core Requirements
- **Session Persistence**: Save and restore Hyprland sessions across reboots
- **Systemd Integration**: Automatic save on shutdown, restore on startup
- **ZFS Integration**: Leverage ZFS snapshots for system-level recovery
- **Comprehensive State Capture**: Window positions, workspaces, applications
- **Modular Architecture**: Extensible with pre/post hooks
- **Performance**: Reasonable save/restore times

## 📁 Project Structure
```
~/.config/hyprland-session-manager/
├── session-manager.sh          # Main session management script
├── session-save.sh            # Session saving logic
├── session-restore.sh         # Session restoration logic  
├── hyprland-session.service   # Systemd user service
├── hyprland-session.target    # Systemd target
├── hooks/
│   ├── pre-save/              # Custom pre-save hooks
│   └── post-restore/          # Custom post-restore hooks
└── session-state/             # Session state storage
```

## 🔧 Core Implementation Components

### 1. Main Session Manager Script (`session-manager.sh`)

**Key Features:**
- Zsh-compatible implementation
- Window state capture using `hyprctl`
- Application tracking by PID and class
- Workspace and monitor configuration saving
- ZFS snapshot integration
- Hook system for extensibility

**Critical Functions:**
- `save_session()` - Comprehensive state capture
- `restore_session()` - State restoration with timing delays
- `save_window_states()` - Window positions and layouts
- `save_applications()` - Running application tracking
- `run_pre_save_hooks()`, `run_post_restore_hooks()` - Modular extensions

### 2. Systemd Service Integration

**Service File (`hyprland-session.service`):**
- User service (runs under user context)
- `ExecStart` for session restoration on login
- `ExecStop` for session saving on logout/shutdown
- Proper dependency management with graphical session
- Zsh environment configuration

**Target File (`hyprland-session.target`):**
- Service grouping and dependency management

### 3. Hyprland Configuration Integration

**Keybindings:**
- `$mainMod + SHIFT + S` - Manual session save
- `$mainMod + SHIFT + R` - Manual session restore  
- `$mainMod + SHIFT + C` - Clean session state
- Auto-restore on Hyprland startup

### 4. ZFS Integration Features

**Automatic Snapshots:**
- Root filesystem detection
- Recursive snapshot creation
- Timestamp-based naming
- Optional pre-save hook for advanced ZFS operations

### 5. Hook System Architecture

**Pre-Save Hooks:**
- Execute before session save
- Use cases: Application-specific quiescing, custom backups

**Post-Restore Hooks:**
- Execute after session restore  
- Use cases: Application session restoration, post-startup configuration

## 🛠️ Technical Implementation Details

### Session State Capture
```bash
# Window and workspace state
hyprctl workspaces -j > workspaces.json
hyprctl clients -j > clients.json  
hyprctl monitors -j > monitors.json
hyprctl activeworkspace -j > active_workspace.json

# Application tracking
hyprctl clients -j | jq -r '.[] | "\(.pid):\(.class):\(.title)"' > applications.txt
```

### Application Restoration Logic
- PID-based application tracking
- Class-based application launching
- Timing delays for application readiness
- Failure handling and reporting

### Systemd Integration Points
- Proper service type (`oneshot` with `RemainAfterExit`)
- User service context
- Graphical session dependencies
- Timeout configurations for graceful shutdown

## 📊 Performance Considerations

**Save Operations:**
- Parallel state capture where possible
- Minimal blocking operations
- Incremental state updates (future enhancement)

**Restore Operations:**  
- Staggered application launching
- Workspace activation delays
- Application readiness detection

## 🔍 Error Handling & Recovery

**Robust Error Handling:**
- Service existence checks
- File permission validation
- Command availability verification
- Graceful degradation when components missing

**Recovery Mechanisms:**
- Partial session restoration
- State validation before restoration
- Fallback behaviors for missing components

## 🚀 Deployment Instructions

### 1. File Placement
```bash
# Create directory structure
mkdir -p ~/.config/hyprland-session-manager/{hooks/pre-save,hooks/post-restore,session-state}

# Place all script files in appropriate locations
```

### 2. Permission Configuration
```bash
# Make scripts executable
chmod +x ~/.config/hyprland-session-manager/*.sh
chmod +x ~/.config/hyprland-session-manager/hooks/*/*.sh

# Ensure proper ownership
chown -R $USER:$USER ~/.config/hyprland-session-manager
```

### 3. Systemd Service Setup
```bash
# Enable user services
systemctl --user enable hyprland-session.service
systemctl --user start hyprland-session.service

# Verify service status
systemctl --user status hyprland-session.service
```

### 4. Hyprland Configuration
Add keybindings and auto-start configuration to `~/.config/hypr/hyprland.conf`

## 🧪 Testing & Validation

**Manual Testing Commands:**
```bash
# Test session save
~/.config/hyprland-session-manager/session-manager.sh save

# Test session restore
~/.config/hyprland-session-manager/session-manager.sh restore

# Check session status
~/.config/hyprland-session-manager/session-manager.sh status

# Clean session state
~/.config/hyprland-session-manager/session-manager.sh clean
```

**Service Validation:**
```bash
# Check service logs
journalctl --user-unit hyprland-session.service -f

# Test systemd integration
systemctl --user restart hyprland-session.service
```

## 📈 Enhancement Opportunities

**Future Improvements:**
- Incremental session saving
- Application-specific restoration scripts
- Session versioning and rollback
- Remote session backup/restore
- Performance metrics and optimization

## 🎯 Success Criteria

**Functional Requirements:**
- [ ] Session saves successfully on shutdown
- [ ] Session restores successfully on startup  
- [ ] Window positions and workspaces preserved
- [ ] Applications relaunch appropriately
- [ ] ZFS snapshots created (if ZFS root)
- [ ] Systemd service starts/stops correctly
- [ ] Manual save/restore operations work
- [ ] Error conditions handled gracefully

**Performance Requirements:**
- [ ] Save operation completes within 10 seconds
- [ ] Restore operation completes within 30 seconds
- [ ] System boot not significantly impacted
- [ ] Memory usage minimal when idle

## 💡 Implementation Notes

**Arch Linux Specific:**
- Zsh shell compatibility required
- ZFS utilities assumed available if ZFS root
- Systemd user session management
- Hyprland window manager environment

**Dependencies:**
- `hyprctl` (from Hyprland)
- `jq` for JSON processing
- `zfs` utilities (if ZFS root)
- `xdotool` for advanced application control (optional)

This implementation provides a complete, production-ready session management solution for Hyprland with proper systemd integration and ZFS support. The modular design allows for easy extension and customization while maintaining robust error handling and performance characteristics suitable for daily use.
