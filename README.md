# 🚀 Hyprland Session Manager

![GitHub](https://img.shields.io/github/license/SnotacusNexus/hyprland-session-manager)

![GitHub release](https://img.shields.io/github/v/release/SnotacusNexus/hyprland-session-manager)

![GitHub issues](https://img.shields.io/github/issues/SnotacusNexus/hyprland-session-manager)

![GitHub pull requests](https://img.shields.io/github/issues-pr/SnotacusNexus/hyprland-session-manager)


# 🚀 Hyprland Session Manager

A comprehensive session management system for Hyprland that preserves your entire desktop state across reboots. Save and restore window layouts, application sessions, and workspace configurations with intelligent application-specific hooks.

![Hyprland Session Manager](https://img.shields.io/badge/Hyprland-Compatible-blue)
![Shell Script](https://img.shields.io/badge/Shell-Zsh-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

### 🎯 Comprehensive Application Support (15 Applications)
- **🌐 Cross-Browser Support**: Firefox, Chrome/Chromium, and Thorium session restoration with tabs, profiles, and window positions
- **💬 Messaging Integration**: Discord, Slack, Telegram, and Signal chat state preservation
- ** IDEs**: VSCode and Void IDE workspace and project state preservation
- **🖥️ Terminals**: Kitty and Terminator session and layout restoration
- **📝 Note Taking**: Obsidian vault and session management
- **🎨 Creative Apps**: Krita document recovery and window layouts
- **📄 Office Tools**: LibreOffice document session management
- **📁 File Managers**: Dolphin directory state preservation

### 🔧 Advanced Session Management
- **Window State Capture**: Complete workspace layouts and window positions
- **Application-Specific Hooks**: Intelligent state preservation for each app type
- **Hyprland Integration**: Native `hyprctl` commands for accurate state management
- **Systemd Service**: Automatic session save/restore on system events
- **ZFS Snapshots**: Filesystem-level session backups (optional)

### 🛡️ Robust Architecture
- **Error Handling**: Graceful degradation when hooks fail
- **Comprehensive Logging**: Detailed logs for debugging
- **State Validation**: Verification of saved session integrity
- **Modular Design**: Easy to extend with custom hooks

## 📦 Installation

### Prerequisites
- **Hyprland** (with `hyprctl` available)
- **Zsh** shell
- **jq** for JSON processing
- **Optional**: ZFS filesystem for snapshots

### Quick Install
```bash
# Clone the repository
git clone https://github.com/SnotacusNexus/hyprland-session-manager.git
cd hyprland-session-manager

# Run installation script
./install.sh
```

### For Contributors
Want to add hooks for your favorite applications?
```bash
# Validate your hooks before submitting
./validate-hook.sh

# Test your hooks
./community-hooks/pre-save/your-app.sh pre-save
./community-hooks/post-restore/your-app.sh post-restore
```

### Manual Installation
```bash
# Copy files to config directory
cp -r .config/hyprland-session-manager ~/.config/

# Make scripts executable
chmod +x ~/.config/hyprland-session-manager/*.sh
chmod +x ~/.config/hyprland-session-manager/hooks/pre-save/*.sh
chmod +x ~/.config/hyprland-session-manager/hooks/post-restore/*.sh

# Add keybindings to your Hyprland config
echo "# Session Manager Keybindings" >> ~/.config/hypr/hyprland.conf
echo "bind = SUPER SHIFT, S, exec, ~/.config/hyprland-session-manager/session-manager.sh save" >> ~/.config/hypr/hyprland.conf
echo "bind = SUPER SHIFT, R, exec, ~/.config/hyprland-session-manager/session-manager.sh restore" >> ~/.config/hypr/hyprland.conf
echo "bind = SUPER SHIFT, C, exec, ~/.config/hyprland-session-manager/session-manager.sh clean" >> ~/.config/hypr/hyprland.conf
```

## 🎮 Usage

### Basic Commands
```bash
# Save current session
~/.config/hyprland-session-manager/session-manager.sh save

# Restore saved session
~/.config/hyprland-session-manager/session-manager.sh restore

# Clean session state
~/.config/hyprland-session-manager/session-manager.sh clean

# Check session status
~/.config/hyprland-session-manager/session-manager.sh status
```

### Keybindings (Recommended)
- **`SUPER SHIFT + S`**: Save session
- **`SUPER SHIFT + R`**: Restore session  
- **`SUPER SHIFT + C`**: Clean session state

### Systemd Integration
Enable automatic session management:
```bash
# Enable systemd service
systemctl --user enable hyprland-session.service
systemctl --user start hyprland-session.service
```

## 🔧 Configuration

### Application Hooks
Session manager includes pre-configured hooks for:

| Application | Pre-Save Hook | Post-Restore Hook | Data Preserved | Notes |
|-------------|---------------|-------------------|----------------|--------|
| Firefox | ✅ | ✅ | Tabs, session, window positions | Full session restoration |
| Chrome/Chromium | ✅ | ✅ | Tabs, profiles, window positions | Complete session support |
| Thorium Browser | ✅ | ✅ | Tabs, profiles, window positions | Full session restoration |
| VSCode | ✅ | ✅ | Workspace, projects, layouts | Workspace state recovery |
| Void IDE | ✅ | ✅ | Workspace, projects, layouts | Project state preservation |
| Kitty | ✅ | ✅ | Terminal sessions, layouts | Basic session support with limitations* |
| Terminator | ✅ | ✅ | Window layouts, sessions | Layout restoration |
| Discord | ✅ | ✅ | Server/channel state, window positions | Chat state preservation |
| Slack | ✅ | ✅ | Workspace/channel state, window positions | Workspace state management |
| Telegram | ✅ | ✅ | Chat sessions, window positions | Conversation state preservation |
| Signal | ✅ | ✅ | Conversation state, window positions | Chat session management |
| Obsidian | ✅ | ✅ | Vault sessions, note state | Note state preservation |
| Krita | ✅ | ✅ | Documents, recovery files | Document recovery |
| LibreOffice | ✅ | ✅ | Open documents, window state | Document session management |
| Dolphin | ✅ | ✅ | Directory state, window layout | Directory navigation |

*Kitty terminal session restoration has limitations with complex terminal sessions

### Custom Hooks
Add your own application hooks:

1. **Create pre-save hook**:
```bash
# ~/.config/hyprland-session-manager/hooks/pre-save/my-app.sh
#!/usr/bin/env zsh
# Your pre-save logic here
```

2. **Create post-restore hook**:
```bash
# ~/.config/hyprland-session-manager/hooks/post-restore/my-app.sh  
#!/usr/bin/env zsh
# Your post-restore logic here
```

3. **Make executable**:
```bash
chmod +x ~/.config/hyprland-session-manager/hooks/*/my-app.sh
```

## 📊 Application Support Matrix

### Fully Supported Applications (15 Total)
- **Firefox**: Complete session restoration with tabs and positions
- **Chrome/Chromium**: Tab sessions, profiles, and window positions
- **Thorium Browser**: Full session restoration with tabs and profiles
- **VSCode**: Workspace state and project recovery
- **Void IDE**: Window layouts and project state
- **Kitty**: Terminal sessions and layouts (basic support with limitations)
- **Terminator**: Window layouts and session management
- **Discord**: Server/channel state and window positions
- **Slack**: Workspace/channel state and window positions
- **Telegram**: Chat session preservation and window positions
- **Signal**: Conversation state management and window positions
- **Obsidian**: Vault sessions and note state preservation
- **Krita**: Document recovery and window positions
- **LibreOffice**: Open documents and window state
- **Dolphin**: Directory state and window positions

### Known Limitations
- **Kitty Terminal**: Complex terminal sessions may not restore completely
- **Application-specific data**: Some applications may require manual configuration restoration

### Basic Support (Window State Only)
- Any application with proper window class detection
- Generic window position and workspace restoration

## 🐛 Troubleshooting

### Common Issues

**Session not saving properly:**
- Check if `hyprctl` is available and working
- Verify all scripts have executable permissions
- Check logs in `~/.config/hyprland-session-manager/session-state/`

**Applications not restoring:**
- Ensure application-specific hooks are executable
- Check if applications are installed in PATH
- Verify window class names match (use `hyprctl clients`)

**Systemd service not starting:**
- Check user systemd service status: `systemctl --user status hyprland-session`
- Verify environment variables are set correctly
- Check journal logs: `journalctl --user-unit=hyprland-session`

### Debug Mode
Enable detailed logging:
```bash
export HYPRLAND_SESSION_DEBUG=1
~/.config/hyprland-session-manager/session-manager.sh save
```

## 🔄 How It Works

### Session Save Process
1. **Window State Capture**: Uses `hyprctl` to save workspace layouts and window positions
2. **Application Hooks**: Runs pre-save hooks for each detected application type
3. **State Serialization**: Saves application-specific data to session state directory
4. **Metadata Creation**: Generates comprehensive session summaries and logs

### Session Restore Process  
1. **Window Layout Restoration**: Recreates workspaces and window placements
2. **Application Launch**: Uses saved commands to relaunch applications
3. **State Recovery**: Runs post-restore hooks to restore application sessions
4. **Validation**: Verifies restoration success and logs results

## 🤝 Community Contributions

**We actively welcome community hooks!** 🎉

### 🚀 Submit Your Application Hooks
Got a custom session save/restore script for your favorite app? **We want it!**

1. **Create hooks** using our [hook template](examples/custom-hook-example.sh)
2. **Place them** in the [community-hooks](community-hooks/) directory
3. **Validate** with `./validate-hook.sh`
4. **Submit PR** - we'll merge quality hooks into the main project!

### 🏆 Featured Community Hooks
*Your hooks could be featured here!* Submit your PR and help others.

### 🤝 Contributing Guidelines
See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

#### Adding New Application Support
1. Create pre-save and post-restore hooks
2. Test with the actual application
3. Update documentation
4. Submit pull request

#### Reporting Issues
Please include:
- Hyprland version
- Application details
- Session manager logs
- Steps to reproduce

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### 🏆 Core Contributors
- **[Your Name]** - Project creator and maintainer

### 🤝 Community Hook Contributors
*This space reserved for your name! Submit your first hook PR to be featured here.*

### 💖 Special Thanks
- **Hyprland Team** for the amazing compositor
- **Hyprland Community** for plugin examples and inspiration
- **All Contributors** who help improve this project

---

**Made with ❤️ for the Hyprland community**

*If this project helps you, please consider giving it a ⭐ on GitHub and submitting your application hooks!*