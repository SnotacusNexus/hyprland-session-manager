
# 🔄 Quantum State Migration Guide

## Overview

This guide provides comprehensive instructions for migrating from the legacy environment management system to the new **Quantum State Manager**. The migration process is designed to be smooth and preserve all your existing session data while providing access to the enhanced features of the quantum state system.

## Table of Contents

1. [Migration Benefits](#migration-benefits)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Migration Methods](#migration-methods)
4. [Configuration Migration](#configuration-migration)
5. [State File Migration](#state-file-migration)
6. [Post-Migration Verification](#post-migration-verification)
7. [Troubleshooting Migration](#troubleshooting-migration)
8. [Rollback Procedures](#rollback-procedures)

## Migration Benefits

### Why Migrate to Quantum State Manager?

| Feature | Legacy System | Quantum State Manager |
|---------|---------------|----------------------|
| **State Persistence** | Basic workspace/window tracking | Complete desktop state with application contexts |
| **Application Recovery** | Limited application support | Comprehensive browser, terminal, IDE, and creative app recovery |
| **Performance** | Basic optimization | Advanced compression and memory management |
| **Validation** | No integrity checks | Checksum-based state validation |
| **Backup System** | Manual backups | Automatic backup creation and cleanup |
| **Real-time Monitoring** | No event monitoring | Real-time Hyprland event tracking |
| **Configuration** | Simple settings | Comprehensive multi-source configuration |

### Key Improvements

1. **🔄 Complete State Capture**: Monitor layouts, workspace states, window arrangements, and application contexts
2. **⚡ Real-time Auto-save**: Automatic state saving with configurable intervals
3. **🔧 Application Session Recovery**: Restore browser tabs, terminal sessions, IDE workspaces
4. **📊 Performance Optimization**: Efficient state compression and memory management
5. **🛡️ State Integrity**: Validation checksums and backup systems
6. **🎯 Configuration Flexibility**: Multi-source configuration with environment variables

## Pre-Migration Checklist

### System Requirements

- [ ] **Hyprland** compositor installed and running
- [ ] **Python 3.8+** with required dependencies
- [ ] **Legacy session data** backed up
- [ ] **Current session** saved using legacy system
- [ ] **Disk space** available for new state files

### Dependency Verification

```bash
# Check Python version
python3 --version

# Verify required packages
pip list | grep -E "(psutil|PyYAML)"

# Check Hyprland availability
hyprctl monitors
```

### Backup Current System

```bash
# Backup legacy session data
cp -r ~/.config/hyprland-session-manager ~/.config/hyprland-session-manager-backup

# Backup current session
./session-manager.sh save

# Verify backup
ls -la ~/.config/hyprland-session-manager-backup/
```

## Migration Methods

### Method 1: Automatic Migration (Recommended)

The Quantum State Manager includes built-in migration tools for automatic conversion of legacy session data.

#### Step-by-Step Automatic Migration

1. **Install Quantum State Manager**:
   ```bash
   # Clone and install the new system
   git clone https://github.com/your-username/hyprland-session-manager
   cd hyprland-session-manager
   ./install.sh
   ```

2. **Run Automatic Migration**:
   ```bash
   # Migrate all legacy session data
   python quantum-state-manager.py --migrate-legacy ~/.config/hyprland-session-manager-backup
   ```

3. **Verify Migration**:
   ```bash
   # List migrated quantum states
   python quantum-state-manager.py --validate
   
   # Test restoration of migrated state
   python quantum-state-manager.py --load --restore
   ```

#### Migration Output Example

```
🔄 Migrating legacy session data from: /home/user/.config/hyprland-session-manager-backup
✅ Migrated: session_20240101_120000.json
✅ Migrated: session_20240101_130000.json
✅ Migrated: session_20240101_140000.json
✅ Migration completed: 3 files migrated
```

### Method 2: Manual Migration

For users who prefer manual control or have custom session formats.

#### Manual Migration Steps

1. **Create Quantum State Directory**:
   ```bash
   mkdir -p ~/.config/hyprland-session-manager/quantum-state
   mkdir -p ~/.config/hyprland-session-manager/quantum-state/backups
   ```

2. **Convert Legacy State Files**:
   ```python
   import json
   from datetime import datetime
   
   def convert_legacy_to_quantum(legacy_file, quantum_file):
       with open(legacy_file, 'r') as f:
           legacy_data = json.load(f)
       
       # Convert to quantum state format
       quantum_state = {
           "timestamp": datetime.now().isoformat(),
           "session_id": f"migrated_{int(datetime.now().timestamp())}",
           "monitor_layouts": legacy_data.get("monitors", []),
           "workspace_states": legacy_data.get("workspaces", []),
           "window_states": legacy_data.get("windows", []),
           "application_contexts": legacy_data.get("applications", []),
           "terminal_sessions": legacy_data.get("terminals", []),
           "browser_sessions": legacy_data.get("browsers", []),
           "development_environments": legacy_data.get("environments", []),
           "system_state": legacy_data.get("system", {}),
           "validation_checksums": {}
       }
       
       with open(quantum_file, 'w') as f:
           json.dump(quantum_state, f, indent=2)
   
   # Convert all legacy files
   import glob
   legacy_files = glob.glob("~/.config/hyprland-session-manager-backup/*.json")
   for legacy_file in legacy_files:
       quantum_file = legacy_file.replace(".json", "_quantum.json")
       convert_legacy_to_quantum(legacy_file, quantum_file)
   ```

3. **Move Converted Files**:
   ```bash
   mv ~/.config/hyprland-session-manager-backup/*_quantum.json ~/.config/hyprland-session-manager/quantum-state/
   ```

### Method 3: Hybrid Migration

Run both systems temporarily during transition period.

#### Hybrid Setup

1. **Keep Legacy System**:
   ```bash
   # Don't remove legacy system immediately
   # Keep both systems running
   ```

2. **Configure Quantum System**:
   ```bash
   # Use different session directory for quantum system
   python quantum-state-manager.py --session-dir ~/.config/hyprland-quantum-manager
   ```

3. **Parallel Operation**:
   - Use legacy system for daily operations
   - Test quantum system with migrated data
   - Gradually transition to quantum system

## Configuration Migration

### Automatic Configuration Migration

The Quantum State Manager automatically migrates legacy configuration settings:

#### Migrated Configuration Settings

| Legacy Setting | Quantum Equivalent | Migration Notes |
|----------------|-------------------|-----------------|
| `auto_save_interval` | `core.auto_save_interval` | Same functionality, enhanced options |
| `max_backups` | `backup.max_backups` | Enhanced backup management |
| `state_validation` | `core.state_validation_enabled` | Advanced validation system |
| `performance_optimization` | `performance.performance_optimization_enabled` | Comprehensive optimization |
| `application_contexts.browsers` | `applications.browser_applications` | Extended browser support |
| `application_contexts.terminals` | `applications.terminal_applications` | Enhanced terminal tracking |
| `application_contexts.ides` | `applications.ide_applications` | IDE workspace recovery |

### Manual Configuration Review

After automatic migration, review and customize your configuration:

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
    "terminal_applications": ["kitty", "alacritty", "wezterm"],
    "development_environments_enabled": true
  },
  "performance": {
    "performance_optimization_enabled": true,
    "state_compression_enabled": true
  }
}
```

### New Configuration Features

Take advantage of new configuration options:

#### Enhanced Auto-save Triggers
```json
{
  "core": {
    "auto_save_on_workspace_change": true,
    "auto_save_on_window_focus": false,
    "auto_save_on_application_launch": false,
    "auto_save_on_application_exit": false
  }
}
```

#### Advanced Performance Settings
```json
{
  "performance": {
    "compression_method": "gzip",
    "compression_level": 6,
    "max_memory_usage_mb": 512,
    "parallel_processing_enabled": true
  }
}
```

#### Comprehensive Backup Management
```json
{
  "backup": {
    "backup_retention_days": 30,
    "backup_compression": true,
    "incremental_backups": true,
    "auto_recovery_enabled": true
  }
}
```

## State File Migration

### Legacy vs Quantum State Format

#### Legacy State Format
```json
{
  "timestamp": "2024-01-01T12:00:00",
  "monitors": [...],
  "workspaces": [...],
  "windows": [...],
  "applications": [...]
}
```

#### Quantum State Format
```json
{
  "timestamp": "2024-01-01T12:00:00",
  "session_id": "quantum_1704115200",
  "monitor_layouts": [...],
  "workspace_states": [...],
  "window_states": [...],
  "application_contexts": [...],
  "terminal_sessions": [...],
  "browser_sessions": [...],
  "development_environments": [...],
  "system_state": {...},
  "validation_checksums": {...}
}
```

### Migration Validation

Verify that all legacy data is properly migrated:

```bash
# Check migrated state files
python quantum-state-manager.py --validate

# Test state loading
python quantum-state-manager.py --load quantum_state_migrated_1704115200.json

# Verify application contexts
python quantum-state-manager.py --load --restore
```

### Data Preservation

The migration process preserves:

- ✅ **Monitor layouts** and configurations
- ✅ **Workspace states** and arrangements
- ✅ **Window positions** and sizes
- ✅ **Application contexts** and sessions
- ✅ **Terminal sessions** and environments
- ✅ **Browser sessions** and tabs
- ✅ **Development environments** and contexts

## Post-Migration Verification

### Functional Testing

#### Basic Operations Test
```bash
# Test state capture
python quantum-state-manager.py --capture --save

# Test state restoration
python quantum-state-manager.py --load --restore

# Test auto-save functionality
python quantum-state-manager.py --auto-save &
```

#### Application Context Test
1. **Open applications** (browser, terminal, IDE)
2. **Capture state** with application contexts
3. **Close applications**
4. **Restore state** and verify application recovery

#### Performance Test
```bash
# Test state capture performance
time python quantum-state-manager.py --capture --save

# Test state file sizes
ls -lh ~/.config/hyprland-session-manager/quantum-state/
```

### Configuration Verification

#### Verify Migrated Settings
```bash
# Check configuration file
cat ~/.config/hyprland-session-manager/quantum-state-config.json

# Test configuration loading
python -c "
from quantum_state_config import load_quantum_config
config = load_quantum_config()
print('Auto-save interval:', config.core.auto_save_interval)
print('Browsers enabled:', config.applications.browsers_enabled)
"
```

#### Verify Environment Variables
```bash
# Set environment variables for testing
export QUANTUM_AUTO_SAVE_INTERVAL=600
export QUANTUM_BROWSERS_ENABLED=true

# Test environment configuration
python quantum-state-manager.py --capture --save
```

### Integration Testing

#### Session Manager Integration
```bash
# Test session manager commands
./session-manager.sh save
./session-manager.sh list
./session-manager.sh restore
```

#### Hyprland Integration
```bash
# Test Hyprland event monitoring
python quantum-state-manager.py --auto-save &

# Change workspaces and verify auto-save
hyprctl dispatch workspace 2
hyprctl dispatch workspace 1
```

## Troubleshooting Migration

### Common Migration Issues

#### Migration Fails with Permission Errors
**Problem**: Migration script cannot access legacy files
**Solution**:
```bash
# Check file permissions
ls -la ~/.config/hyprland-session-manager-backup/

# Fix permissions if needed
chmod 644 ~/.config/hyprland-session-manager-backup/*.json
```

#### Migrated States Fail Validation
**Problem**: Migrated state files fail checksum validation
**Solution**:
```bash
# Re-migrate with fresh data
python quantum-state-manager.py --migrate-legacy ~/.config/hyprland-session-manager-backup --force

# Or manually validate and fix
python -c "
import json
state_file = 'quantum_state_migrated_1234567890.json'
with open(state_file, 'r') as f:
    data = json.load(f)
print('State structure:', list(data.keys()))
"
```

#### Application Contexts Not Migrated
**Problem**: Migrated states don't include application sessions
**Solution**:
1. Check legacy state files contain application data
2. Verify migration script version
3. Manual conversion may be needed for custom formats

#### Performance Issues After Migration
**Problem**: Quantum state operations are slower than legacy system
**Solution**:
```json
{
  "performance": {
    "performance_optimization_enabled": true,
    "state_compression_enabled": true,
    "remove_redundant_data": true,
    "max_memory_usage_mb": 256
  }
}
```

### Debugging Migration Problems

#### Enable Debug Logging
```json
{
  "core": {
    "enable_logging": true,
    "log_level": "DEBUG",
    "log_file": "/tmp/quantum-migration.log"
  }
}
```

#### Check Migration Logs
```bash
# Monitor migration process
tail -f /tmp/quantum-migration.log

# Check for specific errors
grep -i "error\|failed\|exception" /tmp/quantum-migration.log
```

#### Validate Migration Steps
```bash
# Step-by-step validation
echo "1. Checking legacy data..."
ls -la ~/.config/hyprland-session-manager-backup/

echo "2. Checking quantum directory..."
ls -la ~/.config/hyprland-session-manager/quantum-state/

echo "3. Testing state loading..."
python quantum-state-manager.py --validate
```

## Rollback Procedures

### Complete Rollback

If migration causes issues, you can roll back to the legacy system:

#### Step 1: Stop Quantum System
```bash
# Stop any running quantum processes
pkill -f "quantum-state-manager.py"

# Remove quantum configuration
rm -rf ~/.config/hyprland-session-manager/quantum-state
rm -f ~/.config/hyprland-session-manager/quantum-state-config.json
```

#### Step 2: Restore Legacy System
```bash
# Restore from backup
cp -r ~/.config/hyprland-session-manager-backup/* ~/.config/hyprland-session-manager/

# Verify restoration
./session-manager.sh list
```

#### Step 3: Test Legacy System
```bash
# Test legacy functionality
./session-manager.sh save
./session-manager.sh restore
```

### Partial Rollback

If only specific features have issues:

#### Rollback Configuration Only
```bash
# Backup current quantum config
cp ~/.config/hyprland-session-manager/quantum-state-config.json ~/.config/hyprland-session-manager/quantum-state-config.json.backup

# Restore default configuration
python -c "
from quantum_state_config import QuantumConfiguration
config = QuantumConfiguration()
import json
with open('~/.config/hyprland-session-manager/quantum-state-config.json', 'w') as f:
    json.dump(config.to_dict(), f, indent=2)
"
```

#### Disable Problematic Features
```json
{
  "applications": {
    "browsers_enabled": false,
    "terminals_enabled": false,
    "development_environments_enabled": false
  },
  "performance": {
    "performance_optimization_enabled": false
  }
}
```

## Migration Success Checklist

- [ ] **Legacy data backed up** and verified
- [ ] **Automatic migration** completed successfully
- [ ] **Migrated states** pass validation checks
- [ ] **Configuration settings** properly migrated
- [ ] **Basic operations** (capture/save/restore) working
- [ ] **Application contexts** properly restored
- [ ] **Auto-save functionality** working correctly
- [ ] **Performance** meets expectations
- [ ] **Integration** with session manager working
- [ ] **Backup system** creating proper backups
- [ ] **Rollback procedure** tested and documented

## Next Steps After Migration

### Optimize Your Workflow

1. **Customize Auto-save Settings**:
   ```json
   {
     "core": {
       "auto_save_interval": 600,
       "auto_save_on_workspace_change": true
     }
   }
   ```

2. **Configure Application Tracking**:
   ```json
   {
     "applications": {
      