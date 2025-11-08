
# 🚀 Quantum State Manager - Comprehensive User Guide

## Overview

The **Quantum State Manager** is a revolutionary desktop state persistence system for Hyprland that replaces the legacy environment management system with superior quantum persistence technology. This comprehensive guide covers everything you need to know about installing, configuring, and using the Quantum State Manager.

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage Guide](#usage-guide)
6. [Application Contexts](#application-contexts)
7. [Performance Optimization](#performance-optimization)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Features](#advanced-features)
10. [Migration Guide](#migration-guide)

## Introduction

### What is Quantum State Manager?

The Quantum State Manager is a comprehensive desktop state persistence system that:

- **Captures complete desktop state** including monitors, workspaces, windows, and application contexts
- **Provides real-time monitoring** of Hyprland events and state changes
- **Offers automatic state saving** with configurable intervals
- **Supports application session recovery** for browsers, terminals, IDEs, and creative applications
- **Includes performance optimization** for large state captures
- **Ensures state integrity** with validation checksums and backup systems

### Key Benefits

- **🔄 Complete State Persistence**: Restore your entire desktop exactly as you left it
- **⚡ Real-time Monitoring**: Automatic state capture on workspace and window changes
- **🔧 Application Context Recovery**: Restore browser tabs, terminal sessions, and IDE workspaces
- **📊 Performance Optimized**: Efficient state capture and compression
- **🛡️ State Validation**: Checksum-based integrity verification
- **📦 Backup System**: Automatic backup creation and cleanup

## Quick Start

### Basic Usage

```bash
# Capture and save quantum state
python quantum-state-manager.py --capture --save

# Load and restore quantum state
python quantum-state-manager.py --load --restore

# Start auto-save daemon
python quantum-state-manager.py --auto-save

# Validate state compatibility
python quantum-state-manager.py --validate
```

### Session Manager Integration

```bash
# Save current session
./session-manager.sh save

# Restore saved session
./session-manager.sh restore

# List available sessions
./session-manager.sh list
```

## Installation

### Prerequisites

- **Hyprland** compositor
- **Python 3.8+** with required packages:
  - `psutil` for system monitoring
  - `PyYAML` for configuration files
  - `dataclasses` for state management

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/hyprland-session-manager
   cd hyprland-session-manager
   ```

2. **Install dependencies**:
   ```bash
   pip install psutil PyYAML
   ```

3. **Run installation script**:
   ```bash
   ./install.sh
   ```

4. **Verify installation**:
   ```bash
   python quantum-state-manager.py --help
   ```

### Configuration Directory

The Quantum State Manager creates its configuration directory at:
```
~/.config/hyprland-session-manager/
```

This directory contains:
- `quantum-state-config.json` - Main configuration file
- `quantum-state/` - State files directory
- `quantum-state/backups/` - Backup files directory

## Configuration

### Configuration Files

The Quantum State Manager uses a comprehensive configuration system with the following structure:

#### Main Configuration File
```json
{
  "config_version": "1.0.0",
  "config_schema": "quantum-state-v1",
  "core": {
    "auto_save_enabled": true,
    "auto_save_interval": 300,
    "state_validation_enabled": true,
    "validation_level": "basic"
  },
  "applications": {
    "browsers_enabled": true,
    "browser_applications": ["firefox", "chrome", "chromium"],
    "terminals_enabled": true,
    "terminal_applications": ["kitty", "alacritty", "wezterm"]
  },
  "performance": {
    "performance_optimization_enabled": true,
    "max_memory_usage_mb": 512,
    "state_compression_enabled": true
  },
  "backup": {
    "backup_enabled": true,
    "max_backups": 10,
    "backup_retention_days": 30
  }
}
```

### Environment Variables

You can also configure the Quantum State Manager using environment variables:

```bash
# Core settings
export QUANTUM_AUTO_SAVE_INTERVAL=300
export QUANTUM_STATE_VALIDATION=true
export QUANTUM_LOG_LEVEL=INFO

# Application settings
export QUANTUM_BROWSERS_ENABLED=true
export QUANTUM_TERMINALS_ENABLED=true
export QUANTUM_BROWSER_APPLICATIONS="firefox,chrome,chromium"
export QUANTUM_TERMINAL_APPLICATIONS="kitty,alacritty,wezterm"

# Performance settings
export QUANTUM_MAX_MEMORY_MB=512
export QUANTUM_COMPRESSION_METHOD=gzip
```

### Configuration Categories

#### Core Settings
- **Auto-save**: Enable/disable automatic state saving
- **Validation**: State integrity verification
- **Session Management**: Session persistence and timeout settings
- **Logging**: Log level and file configuration

#### Application Contexts
- **Browsers**: Browser session tracking and restoration
- **Terminals**: Terminal session and environment tracking
- **IDEs**: IDE workspace and file tracking
- **Creative Apps**: Creative application document tracking

#### Performance Optimization
- **Compression**: State compression methods and levels
- **Memory Management**: Memory usage limits and cleanup
- **Processing Limits**: Timeouts and parallel processing

#### Backup & Validation
- **Backup Management**: Backup creation and retention policies
- **Validation**: State validation on save/load operations
- **Recovery**: Automatic recovery from corrupted states

## Usage Guide

### Basic Commands

#### Capture Quantum State
```bash
# Capture and save state
python quantum-state-manager.py --capture --save

# Capture state with custom filename
python quantum-state-manager.py --capture --save --session-dir /custom/path
```

#### Load Quantum State
```bash
# Load and restore state
python quantum-state-manager.py --load --restore

# Load specific state file
python quantum-state-manager.py --load quantum_state_1234567890.json --restore
```

#### Auto-save Daemon
```bash
# Start auto-save with default interval (5 minutes)
python quantum-state-manager.py --auto-save

# Start auto-save with custom interval
python quantum-state-manager.py --auto-save --session-dir /custom/path
```

### Session Manager Integration

The Quantum State Manager integrates seamlessly with the Hyprland Session Manager:

```bash
# Save current session (uses quantum state manager)
./session-manager.sh save

# Restore saved session
./session-manager.sh restore

# List available quantum states
./session-manager.sh list

# Migrate from legacy session format
./session-manager.sh migrate-legacy /path/to/legacy/sessions
```

### State Management

#### View Available States
```bash
python quantum-state-manager.py --validate
```

This command lists all compatible quantum state files and validates their integrity.

#### State Validation
```bash
# Validate state compatibility with current system
python quantum-state-manager.py --validate
```

#### Backup Management
Backups are automatically created when states are saved. You can manage them through the configuration:

```json
{
  "backup": {
    "backup_enabled": true,
    "max_backups": 10,
    "backup_retention_days": 30,
    "backup_compression": true
  }
}
```

## Application Contexts

### Browser Session Recovery

The Quantum State Manager supports comprehensive browser session recovery:

#### Supported Browsers
- **Firefox**: Session store recovery with profile detection
- **Chrome/Chromium**: Session storage tracking
- **Brave**: Session data capture
- **Vivaldi**: Browser state tracking
- **Opera**: Session restoration
- **Edge**: Microsoft Edge support

#### Configuration
```json
{
  "applications": {
    "browsers_enabled": true,
    "browser_applications": ["firefox", "chrome", "chromium", "brave"],
    "browser_session_capture": true,
    "browser_tab_restoration": true,
    "browser_window_restoration": true
  }
}
```

### Terminal Session Recovery

Terminal sessions are captured with environment context:

#### Supported Terminals
- **Kitty**: Remote control session capture
- **Alacritty**: Session state tracking
- **WezTerm**: Terminal state capture
- **GNOME Terminal**: Session recovery
- **Terminator**: Multi-pane session restoration
- **Tmux**: Tmux session integration

#### Features
- Current working directory restoration
- Environment variable tracking
- Shell session context
- Development environment detection

#### Configuration
```json
{
  "applications": {
    "terminals_enabled": true,
    "terminal_applications": ["kitty", "alacritty", "wezterm", "gnome-terminal"],
    "terminal_session_capture": true,
    "terminal_environment_tracking": true,
    "terminal_current_directory": true
  }
}
```

### IDE Session Recovery

IDE workspace and file context recovery:

#### Supported IDEs
- **VSCode/VSCodium**: Workspace and open file restoration
- **Void Editor**: Session file tracking
- **PyCharm**: Project context
- **IntelliJ IDEA**: Development environment
- **WebStorm**: Web development context

#### Features
- Workspace file tracking
- Open file restoration
- Project structure context
- Development environment integration

### Creative Application Recovery

Creative application document and workspace recovery:

#### Supported Applications
- **Krita**: Document and workspace layout
- **GIMP**: Session and tool settings
- **Blender**: Project and workspace
- **Inkscape**: Document context
- **Darktable**: Photo editing sessions

## Performance Optimization

### State Compression

The Quantum State Manager includes multiple compression methods:

```json
{
  "performance": {
    "state_compression_enabled": true,
    "compression_method": "gzip",
    "compression_level": 6,
    "remove_redundant_data": true
  }
}
```

#### Compression Methods
- **GZIP**: Standard compression (default)
- **LZ4**: Fast compression with good ratio
- **ZSTD**: High compression ratio
- **NONE**: No compression (for debugging)

### Memory Management

```json
{
  "performance": {
    "max_memory_usage_mb": 512,
    "memory_cleanup_interval": 60,
    "cache_enabled": true,
    "cache_size_mb": 100
  }
}
```

### Processing Optimization

```json
{
  "performance": {
    "max_processing_time_seconds": 30,
    "large_state_threshold_mb": 50,
    "parallel_processing_enabled": true,
    "max_parallel_processes": 4
  }
}
```

### Optimization Techniques

1. **Redundant Data Removal**: Remove duplicate and unnecessary data
2. **Application Context Optimization**: Compress large session files
3. **Terminal Session Optimization**: Filter environment variables
4. **Browser Session Optimization**: Store only session file paths
5. **System State Compression**: Optimize system monitoring data

## Troubleshooting

### Common Issues

#### State Capture Fails
**Symptoms**: State capture returns empty data or fails
**Solutions**:
1. Check Hyprland is running: `hyprctl monitors`
2. Verify Python dependencies: `pip list | grep psutil`
3. Check permissions for `/proc` directory access
4. Review logs: `/tmp/quantum-state-manager.log`

#### State Validation Fails
**Symptoms**: State validation returns checksum errors
**Solutions**:
1. Check for system changes between capture and restore
2. Verify monitor configuration hasn't changed
3. Check for corrupted state files
4. Use backup restoration: Enable `auto_recovery_enabled`

#### Auto-save Not Working
**Symptoms**: Auto-save daemon doesn't create state files
**Solutions**:
1. Check auto-save configuration: `auto_save_enabled` and `auto_save_interval`
2. Verify daemon is running: Check process list
3. Review log files for errors
4. Check disk space in state directory

#### Application Context Not Captured
**Symptoms**: Specific application sessions not restored
**Solutions**:
1. Verify application is in configured list
2. Check application-specific configuration
3. Verify application is running during capture
4. Check application session file permissions

### Logging and Debugging

#### Enable Debug Logging
```json
{
  "core": {
    "enable_logging": true,
    "log_level": "DEBUG",
    "log_file": "/tmp/quantum-state-manager.log"
  }
}
```

#### Common Log Messages
- `✅ Quantum state captured successfully` - Successful state capture
- `❌ Failed to capture quantum state` - State capture failure
- `✅ State validation successful` - Validation passed
- `❌ State validation failed` - Validation failed
- `✅ Auto-saved quantum state` - Auto-save completed
- `⚠️ Checksum mismatch` - Integrity verification failure

### Recovery Procedures

#### From Corrupted State
1. Enable automatic recovery in configuration
2. Use backup restoration
3. Manual state file repair
4. Fallback to last known good state

#### From System Changes
1. Validate state compatibility before restoration
2. Use partial restoration for compatible components
3. Manual adjustment of incompatible settings
4. Create new baseline state after system changes

## Advanced Features

### Event Monitoring

The Quantum State Manager includes real-time Hyprland event monitoring:

```python
# Add custom event callbacks
def on_workspace_focus(workspace):
    print(f"Workspace focused: {workspace['name']}")

def on_active_window_change(window):
    print(f"Active window changed: {window['title']}")

manager.add_event_callback(on_workspace_focus)
manager.add_event_callback(on_active_window_change)
manager.start_event_monitoring()
```

#### Event Types
- **Workspace Focus**: When workspace focus changes
- **Active Window**: When active window changes
- **Client Changes**: When windows are created/destroyed

### Custom Application Hooks

Extend application context capture with custom hooks:

```python
def custom_application_capture(app_class, pid):
    # Custom application session capture logic
    return {
        "custom_data": "application_specific_data",
        "session_files": ["/path/to/session/file"]
    }

# Register custom capture method
manager._capture_application_session_data = custom_application_capture
```

### Development Environment Integration

The Quantum State Manager detects and tracks development environments:

#### Supported Environments
- **Conda**: Active conda environments
- **Virtual Environments**: Python virtual environments
- **Pyenv**: Python version management
- **Node.js**: Node.js development environments
- **Rust**: Rust development toolchains
- **Go**: Go development environments

#### Configuration
```json
{
  "applications": {
    "development_environments_enabled": true,
    "track_conda_environments": true,
    "track_virtual_environments": true,
    "track_pyenv_environments": true,
    "track_node_environments": true
  }
}
```

### State Compatibility Validation

Advanced state compatibility checking:

```python
# Check if state is compatible with current system
is_compatible = manager.validate_state_compatibility(quantum_state)

if is_compatible:
    print("State is compatible with current system")
else:
    print("State may not restore correctly due to system changes")
```

#### Compatibility Checks
- Monitor count and configuration
- Workspace availability
- System resource compatibility
- Application availability

## Migration Guide

### From Legacy Session Manager

#### Automatic Migration
```bash
# Migrate all legacy session files
python quantum-state-manager.py --migrate-legacy ~/.config/hyprland-session-manager

# Migrate specific legacy directory
python quantum-state-manager.py --migrate-legacy /path/to/legacy/sessions
```

#### Manual Migration Steps

1. **Backup Legacy Data**:
   ```bash
   cp -r ~/.config/hyprland-session-manager ~/.config/hyprland-session-manager-backup
   ```

2. **Run Migration**:
   ```bash
   python quantum-state-manager.py --migrate-legacy ~/.config/hyprland-session-manager-backup
   ```

3. **Verify Migration**:
   ```bash
   python quantum-state-manager.py --validate
   ```

4. **Test Restoration**:
   ```bash
   python quantum-state-manager.py --load --restore
   ```

#### Migration Features
- **Legacy Format Support**: Compatible with old session formats
- **Configuration Migration**: Migrates legacy configuration settings
- **State Conversion**: Converts legacy state to quantum state format
- **Validation**: Validates migrated state integrity

### Configuration Migration

Legacy configuration settings are automatically migrated to the new quantum configuration format:

#### Migrated Settings
- Auto-save intervals
- Backup limits
- State validation settings
- Application context configurations
- Performance optimization settings

## Best Practices

### State Management
1. **Regular Backups**: Keep multiple state backups for recovery
2. **Validation**: Always validate states before critical operations
3. **Compatibility**: Check state compatibility after system changes
4. **Cleanup**: Regularly clean up old state files

### Performance
1. **Optimization**: Enable performance optimization for large states
2. **Compression**: Use appropriate compression for your needs
3. **Memory Limits**: Set reasonable memory usage limits
4. **Processing Timeouts**: Configure appropriate timeouts

### Application Contexts
1. **Configuration**: Configure application lists for your workflow
2. **Testing**: Test application context restoration
3. **Customization**: Extend with custom application hooks
4. **Monitoring**: Monitor application context capture success

### Troubleshooting
1. **Logging**: Enable debug