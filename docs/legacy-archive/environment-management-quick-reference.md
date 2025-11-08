# Environment Management System - Quick Reference Guide

## Quick Commands Reference

### Legacy Environment Validation
```bash
# Basic environment detection
./environment-validation.sh detect

# Validate all environments
./environment-validation.sh validate

# Test specific environment type
./environment-validation.sh detect --type conda

# Quick status check
./environment-validation.sh test
```

### Legacy Change Detection
```bash
# Start monitoring daemon
./environment-change-detector.sh start

# Check monitoring status
./environment-change-detector.sh status

# Stop monitoring
./environment-change-detector.sh stop

# Restart monitoring
./environment-change-detector.sh restart
```

### Quantum State Manager
```bash
# Comprehensive state management
python quantum-state-manager.py --status
python quantum-state-manager.py --capture-state
python quantum-state-manager.py --restore-state

# Real-time monitoring
python quantum-state-manager.py --start-monitoring
python quantum-state-manager.py --stop-monitoring

# State validation and backup
python quantum-state-manager.py --validate-state
python quantum-state-manager.py --create-backup
python quantum-state-manager.py --list-backups
```

### Manual Workflows (Recommended)
```bash
# Legacy manual workflow
./environment-validation.sh validate && ./session-manager.sh save

# Quantum State Manager workflow
python quantum-state-manager.py --save-state

# Hybrid operation during migration
./environment-validation.sh validate && ./session-manager.sh save && python quantum-state-manager.py --save-state
```

## Current Status Summary

### ✅ Working Features (Legacy System)
- **Environment Detection**: conda, mamba, venv, pyenv
- **Basic Validation**: Environment existence checking
- **Change Monitoring**: Directory watching with inotify
- **Notifications**: Desktop notifications for changes
- **Configuration**: Full configuration management

### ✅ Working Features (Quantum State Manager)
- **Comprehensive State Capture**: Monitors, workspaces, windows, applications
- **Real-time Monitoring**: Live Hyprland event monitoring
- **Application Context Recovery**: Browser, terminal, IDE, creative apps
- **State Validation**: Checksum-based integrity verification
- **Backup Management**: Automatic backup creation and cleanup
- **Performance Optimization**: State compression, memory management
- **Legacy Integration**: Seamless integration with existing system

### ⚠️ Limited Features (Legacy System)
- **Health Validation**: Basic checks work, activation tests unreliable
- **Metadata Capture**: Environment listing works, detailed metadata incomplete
- **Auto-Save**: Trigger system works, session save integration unreliable

### ❌ Broken Features (Legacy System)
- **Full Integration**: Environment validation not integrated with session workflows
- **Performance**: No caching implemented
- **Some Validation**: Missing function implementations

### ⚠️ Limited Features (Quantum State Manager)
- **Advanced Performance**: Some optimization features in development
- **Application Recovery**: Some application-specific recovery under development
- **Migration System**: Legacy state migration system being enhanced

## Configuration Quick Settings

### Legacy System - For Production Use
```bash
# In ~/.config/hyprland-session-manager/environment-monitor.conf
MONITOR_INTERVAL=300           # 5 minutes for performance
CHANGE_THRESHOLD=3             # Higher threshold to reduce false positives
AUTO_SAVE_ENABLED=false        # Manual saves recommended
NOTIFICATION_ENABLED=true      # Get notified of changes
```

### Legacy System - For Development
```bash
MONITOR_INTERVAL=60            # Frequent checks
CHANGE_THRESHOLD=1             # Sensitive to changes
AUTO_SAVE_ENABLED=false        # Manual control during development
NOTIFICATION_ENABLED=true      # Stay informed
```

### Quantum State Manager - Recommended Settings
```bash
# Use quantum-state-config.py for configuration
python quantum-state-config.py --set auto_save_interval=300
python quantum-state-config.py --set enable_application_context=true
python quantum-state-config.py --set backup_retention_days=7

# Enable auto-save and monitoring
python quantum-state-manager.py --enable-auto-save
python quantum-state-manager.py --start-monitoring
```

## Troubleshooting Quick Fixes

### Environment Not Detected
```bash
# Check if environment manager is available
command -v conda
command -v mamba

# Test detection manually
./environment-validation.sh detect
```

### Health Validation Fails
```bash
# Skip health validation
export SKIP_HEALTH_VALIDATION=true
./environment-validation.sh validate

# Or use existence validation only
validate_environment_exists "conda" "my-env" ""
```

### Change Detection Not Working
```bash
# Check status and restart
./environment-change-detector.sh status
./environment-change-detector.sh restart --force

# Verify configuration
cat ~/.config/hyprland-session-manager/environment-monitor.conf
```

### Auto-Save Not Triggering
```bash
# Manual save workflow (recommended)
./environment-validation.sh validate
./session-manager.sh save
```

## File Locations

### Legacy System Configuration Files
- `~/.config/hyprland-session-manager/environment-monitor.conf` - Main configuration
- `~/.config/hyprland-session-manager/session-state/` - Session data

### Quantum State Manager Files
- `~/.config/hyprland-session-manager/quantum-state/` - Quantum state data
- `~/.config/hyprland-session-manager/quantum-state-config.json` - Configuration
- `~/.config/hyprland-session-manager/quantum-state/backups/` - State backups

### Legacy Script Files
- `./environment-validation.sh` - Environment detection and validation
- `./environment-change-detector.sh` - Change monitoring daemon
- `./test-environment-validation.sh` - Validation tests
- `./test-environment-change-detection.sh` - Change detection tests

### Quantum State Manager Scripts
- `./quantum-state-manager.py` - Main quantum state manager
- `./quantum-state-config.py` - Configuration management
- `./test-quantum-state-manager.py` - Comprehensive test suite

### Log Files
- **Legacy**: Check `~/.config/hyprland-session-manager/` for log files
- **Quantum State**: Check `~/.config/hyprland-session-manager/quantum-state/` for logs
- **System logs**: `journalctl -u hyprland-session-manager`

## Performance Tips

### Reduce Resource Usage
```bash
# Increase monitoring interval
MONITOR_INTERVAL=300

# Limit concurrent monitors
MAX_MONITORS=5

# Disable less critical triggers
TRIGGER_PACKAGE_UPDATES=false
TRIGGER_ENVIRONMENT_SWITCHES=false
```

### Manual Optimization
```bash
# Use manual validation instead of continuous monitoring
./environment-validation.sh validate
# Only when needed: ./session-manager.sh save
```

## Common Workflows

### Legacy Daily Development Workflow
```bash
# Start work session
./environment-change-detector.sh start

# When making environment changes, manually save:
./session-manager.sh save

# End work session
./environment-change-detector.sh stop
```

### Quantum State Manager Daily Workflow
```bash
# Start quantum state monitoring
python quantum-state-manager.py --start-monitoring

# State automatically saved on changes
# Manual save if needed:
python quantum-state-manager.py --save-state

# End work session
python quantum-state-manager.py --stop-monitoring
```

### Project Environment Setup
```bash
# Legacy validation
./environment-validation.sh detect --type venv
./environment-validation.sh validate
./session-manager.sh save

# Quantum State Manager setup
python quantum-state-manager.py --capture-state
python quantum-state-manager.py --validate-state
```

### Environment Migration
```bash
# Legacy migration workflow
./environment-validation.sh detect > environments.txt
./environment-validation.sh validate
./session-manager.sh save

# Quantum State Manager migration
python quantum-state-manager.py --migrate-legacy
python quantum-state-manager.py --validate-state
```

## Emergency Procedures

### Monitoring Daemon Issues
```bash
# Force stop all monitoring
./environment-change-detector.sh stop
pkill -f environment-change-detector

# Clean up PID files
rm -f ~/.config/hyprland-session-manager/monitor_*.txt
```

### Session Save Issues
```bash
# Manual session save without validation
./session-manager.sh save --skip-validation

# Or use basic save
./session-manager.sh save-basic
```

### Configuration Reset
```bash
# Backup current configuration
cp ~/.config/hyprland-session-manager/environment-monitor.conf ~/backup/

# Reset to defaults
rm ~/.config/hyprland-session-manager/environment-monitor.conf
./environment-change-detector.sh start  # Creates new default config
```

## Support Information

### Legacy Debug Mode
```bash
# Enable detailed logging
export ENVIRONMENT_DEBUG=1
./environment-validation.sh detect
```

### Quantum State Manager Debug Mode
```bash
# Enable quantum state debugging
export QUANTUM_STATE_DEBUG=1
python quantum-state-manager.py --status
python quantum-state-manager.py --capture-state --debug
```

### Test Suite
```bash
# Legacy system tests
./test-environment-validation.sh quick
./test-environment-validation.sh all

# Quantum State Manager tests
python test-quantum-state-manager.py
python quantum-state-manager.py --test-integration
```

### Version Information
Check the main documentation for current version and known issues. Quantum State Manager supersedes many legacy features with enhanced capabilities.

---

**Note**: This quick reference complements the full documentation. Refer to `environment-management-system-documentation.md`, `quantum-state-user-guide.md`, and `quantum-state-migration-guide.md` for complete details, architecture diagrams, and in-depth troubleshooting.