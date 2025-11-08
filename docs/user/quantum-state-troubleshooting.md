# Quantum State Manager - Troubleshooting Guide

## Overview

This comprehensive troubleshooting guide provides detailed solutions for issues specific to the Quantum State Manager system. The Quantum State Manager provides comprehensive desktop state persistence with enhanced capabilities for Hyprland session management.

---

## 1. Quick Diagnostic Procedures

### 1.1 System Health Check

```bash
# Check Quantum State Manager status
python quantum-state-manager.py --status

# Validate configuration
python quantum-state-config.py --validate

# Test Hyprland integration
hyprctl monitors
python -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('/tmp/hypr/.socket.sock'); print('Hyprland socket accessible')"

# Check system dependencies
python -c "import json, subprocess, threading, time, hashlib, os, sys, signal, logging, dataclasses, typing, pathlib, shutil, tempfile, uuid, datetime, re, collections, functools, itertools, contextlib, asyncio"
```

### 1.2 Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Enable quantum state debugging
export QUANTUM_STATE_DEBUG=1

# Run with debug output
python quantum-state-manager.py --status --debug
python quantum-state-manager.py --capture-state --debug

# Monitor debug logs
tail -f ~/.config/hyprland-session-manager/quantum-state/*.log
```

---

## 2. Common Issues and Solutions

### 2.1 Initialization and Startup Issues

#### Issue: Quantum State Manager Not Starting
**Symptoms**: Python import errors, missing dependencies, initialization failures

**Diagnostic Steps**:
```bash
# Check Python dependencies
python -c "import dataclasses_json, typing_extensions"

# Test basic functionality
python quantum-state-manager.py --version

# Check configuration file
ls -la ~/.config/hyprland-session-manager/quantum-state-config.json

# Verify directory structure
ls -la ~/.config/hyprland-session-manager/quantum-state/
```

**Solutions**:
1. **Install Missing Dependencies**:
   ```bash
   pip install dataclasses-json typing-extensions
   ```

2. **Reset Configuration**:
   ```bash
   python quantum-state-config.py --reset-defaults
   ```

3. **Check Hyprland Integration**:
   ```bash
   # Verify Hyprland is running
   hyprctl monitors
   
   # Test Hyprland socket connection
   python -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('/tmp/hypr/.socket.sock'); print('Hyprland socket accessible')"
   ```

#### Issue: Configuration Validation Fails
**Symptoms**: Configuration errors, invalid settings, missing required parameters

**Diagnostic Steps**:
```bash
# Validate configuration
python quantum-state-config.py --validate

# Check configuration file
cat ~/.config/hyprland-session-manager/quantum-state-config.json

# Test configuration loading
python quantum-state-config.py --test-load
```

**Solutions**:
1. **Reset Configuration**:
   ```bash
   # Reset to defaults
   python quantum-state-config.py --reset-defaults
   ```

2. **Manual Configuration**:
   ```bash
   # Edit configuration manually
   nano ~/.config/hyprland-session-manager/quantum-state-config.json
   ```

3. **Configuration Migration**:
   ```bash
   # Migrate from legacy configuration
   python quantum-state-config.py --migrate-legacy-config
   ```

### 2.2 State Capture Issues

#### Issue: State Capture Fails
**Symptoms**: Incomplete state capture, missing windows or applications

**Diagnostic Steps**:
```bash
# Test state capture manually
python quantum-state-manager.py --capture-state --debug

# Check application detection
python quantum-state-manager.py --list-applications

# Verify workspace capture
python quantum-state-manager.py --capture-workspaces

# Test individual components
python quantum-state-manager.py --capture-monitors
python quantum-state-manager.py --capture-windows
```

**Solutions**:
1. **Enable Debug Mode**:
   ```bash
   export QUANTUM_STATE_DEBUG=1
   python quantum-state-manager.py --capture-state
   ```

2. **Manual State Capture**:
   ```bash
   # Capture specific components
   python quantum-state-manager.py --capture-monitors
   python quantum-state-manager.py --capture-workspaces
   python quantum-state-manager.py --capture-windows
   ```

3. **Application-Specific Capture**:
   ```bash
   # Focus on specific applications
   python quantum-state-manager.py --capture-applications --app-filter="firefox,code,kitty"
   ```

#### Issue: Application Context Not Captured
**Symptoms**: Browser sessions, terminal sessions, or IDE workspaces not saved

**Diagnostic Steps**:
```bash
# Check application detection
python quantum-state-manager.py --list-applications

# Test application context capture
python quantum-state-manager.py --capture-applications --debug

# Verify application processes
ps aux | grep -E "(firefox|code|kitty)"
```

**Solutions**:
1. **Enable Application Context**:
   ```bash
   python quantum-state-config.py --set enable_application_context=true
   ```

2. **Application-Specific Configuration**:
   ```bash
   # Configure specific applications
   python quantum-state-config.py --set application_whitelist="firefox,code,kitty,obsidian"
   ```

3. **Manual Application Capture**:
   ```bash
   # Capture specific applications
   python quantum-state-manager.py --capture-application firefox
   python quantum-state-manager.py --capture-application code
   ```

### 2.3 State Restoration Issues

#### Issue: State Restoration Fails
**Symptoms**: Applications not restored, incorrect window placement, missing workspaces

**Diagnostic Steps**:
```bash
# Test state restoration
python quantum-state-manager.py --restore-state --dry-run

# Validate state file
python quantum-state-manager.py --validate-state

# Check application availability
python quantum-state-manager.py --check-applications

# Test individual restoration
python quantum-state-manager.py --restore-monitors --dry-run
python quantum-state-manager.py --restore-workspaces --dry-run
```

**Solutions**:
1. **Use Dry Run First**:
   ```bash
   python quantum-state-manager.py --restore-state --dry-run
   ```

2. **Partial Restoration**:
   ```bash
   # Restore specific components
   python quantum-state-manager.py --restore-monitors
   python quantum-state-manager.py --restore-workspaces
   python quantum-state-manager.py --restore-applications
   ```

3. **Application Recovery**:
   ```bash
   # Recover specific applications
   python quantum-state-manager.py --recover-application firefox
   python quantum-state-manager.py --recover-application code
   ```

#### Issue: Monitor Configuration Problems
**Symptoms**: Incorrect monitor arrangement, missing displays, resolution issues

**Diagnostic Steps**:
```bash
# Check current monitor configuration
hyprctl monitors

# Test monitor capture
python quantum-state-manager.py --capture-monitors --debug

# Validate monitor state
python quantum-state-manager.py --validate-state | grep -i monitor
```

**Solutions**:
1. **Manual Monitor Configuration**:
   ```bash
   # Capture current monitor state
   python quantum-state-manager.py --capture-monitors
   
   # Restore monitor configuration
   python quantum-state-manager.py --restore-monitors
   ```

2. **Monitor State Reset**:
   ```bash
   # Reset monitor configuration
   python quantum-state-manager.py --reset-monitors
   ```

### 2.4 Performance Issues

#### Issue: Performance Problems
**Symptoms**: Slow state capture/restoration, high CPU/memory usage

**Diagnostic Steps**:
```bash
# Check performance metrics
python quantum-state-manager.py --performance-stats

# Monitor resource usage
top -p $(pgrep -f quantum-state-manager)

# Test with reduced features
python quantum-state-manager.py --capture-state --minimal
```

**Solutions**:
1. **Optimize Configuration**:
   ```bash
   # Reduce capture frequency
   python quantum-state-config.py --set auto_save_interval=300
   
   # Disable intensive features
   python quantum-state-config.py --set enable_application_context=false
   ```

2. **Use Minimal Mode**:
   ```bash
   # Use minimal state capture
   python quantum-state-manager.py --capture-state --minimal
   ```

3. **Schedule Off-Peak Operations**:
   ```bash
   # Schedule state operations during low usage
   python quantum-state-manager.py --schedule-backup --time="02:00"
   ```

#### Issue: Memory Usage High
**Symptoms**: High memory consumption, system slowdown during state operations

**Diagnostic Steps**:
```bash
# Monitor memory usage
ps aux --sort=-%mem | grep quantum-state

# Check state file sizes
ls -lh ~/.config/hyprland-session-manager/quantum-state/*.json

# Test with memory limits
python quantum-state-manager.py --capture-state --memory-limit=512
```

**Solutions**:
1. **Enable State Compression**:
   ```bash
   python quantum-state-config.py --set enable_state_compression=true
   ```

2. **Reduce State Retention**:
   ```bash
   # Keep fewer state backups
   python quantum-state-config.py --set backup_retention_days=3
   ```

3. **Manual Memory Management**:
   ```bash
   # Clear state cache
   python quantum-state-manager.py --clear-cache
   ```

### 2.5 State Validation Issues

#### Issue: State Validation Failures
**Symptoms**: State validation errors, checksum mismatches, corrupted state files

**Diagnostic Steps**:
```bash
# Validate state integrity
python quantum-state-manager.py --validate-state

# Check state file integrity
python quantum-state-manager.py --check-state-integrity

# Verify backup availability
python quantum-state-manager.py --list-backups

# Test state file readability
python -m json.tool ~/.config/hyprland-session-manager/quantum-state/current_state.json
```

**Solutions**:
1. **Restore from Backup**:
   ```bash
   # List available backups
   python quantum-state-manager.py --list-backups
   
   # Restore from specific backup
   python quantum-state-manager.py --restore-backup backup_name
   ```

2. **Force State Rebuild**:
   ```bash
   # Force rebuild of state files
   python quantum-state-manager.py --rebuild-state
   ```

3. **Manual State Repair**:
   ```bash
   # Manual state file repair
   python quantum-state-manager.py --repair-state
   ```

#### Issue: Checksum Mismatches
**Symptoms**: State validation fails due to checksum errors

**Diagnostic Steps**:
```bash
# Check state file checksums
python quantum-state-manager.py --verify-checksums

# Compare state files
python quantum-state-manager.py --compare-states

# Validate individual components
python quantum-state-manager.py --validate-monitors
python quantum-state-manager.py --validate-workspaces
```

**Solutions**:
1. **Recalculate Checksums**:
   ```bash
   python quantum-state-manager.py --recalculate-checksums
   ```

2. **Force State Update**:
   ```bash
   python quantum-state-manager.py --force-state-update
   ```

3. **Manual Checksum Repair**:
   ```bash
   python quantum-state-manager.py --repair-checksums
   ```

### 2.6 Migration Issues

#### Issue: Legacy State Migration Fails
**Symptoms**: Migration errors, incomplete state transfer, compatibility issues

**Diagnostic Steps**:
```bash
# Test migration compatibility
python quantum-state-manager.py --test-migration

# Check legacy state files
ls -la ~/.config/hyprland-session-manager/session-state/

# Validate migration readiness
python quantum-state-migration-guide.md --check-readiness

# Compare legacy vs quantum state
python quantum-state-manager.py --compare-legacy-state
```

**Solutions**:
1. **Manual Migration**:
   ```bash
   # Manual state transfer
   python quantum-state-manager.py --migrate-legacy --manual
   ```

2. **Hybrid Operation**:
   ```bash
   # Run both systems temporarily
   ./session-manager.sh save
   python quantum-state-manager.py --save-state
   ```

3. **Migration Rollback**:
   ```bash
   # Rollback migration if needed
   python quantum-state-manager.py --rollback-migration
   ```

#### Issue: Configuration Migration Problems
**Symptoms**: Configuration conflicts, missing settings, migration failures

**Diagnostic Steps**:
```bash
# Check legacy configuration
cat ~/.config/hyprland-session-manager/environment-monitor.conf

# Test configuration migration
python quantum-state-config.py --migrate-legacy-config --dry-run

# Validate migrated configuration
python quantum-state-config.py --validate
```

**Solutions**:
1. **Manual Configuration Transfer**:
   ```bash
   # Manual configuration migration
   python quantum-state-config.py --migrate-legacy-config --manual
   ```

2. **Configuration Merge**:
   ```bash
   # Merge configurations
   python quantum-state-config.py --merge-configs
   ```

3. **Configuration Reset**:
   ```bash
   # Reset to defaults and reconfigure
   python quantum-state-config.py --reset-defaults
   ```

### 2.7 Integration Issues

#### Issue: Session Manager Integration Problems
**Symptoms**: Conflicts with legacy session manager, duplicate state saves, integration failures

**Diagnostic Steps**:
```bash
# Check integration status
python quantum-state-manager.py --integration-status

# Test session manager compatibility
./session-manager.sh save
python quantum-state-manager.py --save-state

# Verify no conflicts
ps aux | grep -E "(session-manager|quantum-state)"
```

**Solutions**:
1. **Disable Legacy Auto-Save**:
   ```bash
   # Disable legacy auto-save
   echo "AUTO_SAVE_ENABLED=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

2. **Use Quantum State Exclusively**:
   ```bash
   # Use quantum state manager exclusively
   python quantum-state-manager.py --enable-exclusive-mode
   ```

3. **Hybrid Operation**:
   ```bash
   # Configure hybrid operation
   python quantum-state-config.py --set hybrid_mode=true
   ```

#### Issue: Auto-Save Integration Problems
**Symptoms**: Auto-save not triggering, missed state saves, timing issues

**Diagnostic Steps**:
```bash
# Check auto-save configuration
python quantum-state-config.py --get auto_save_enabled
python quantum-state-config.py --get auto_save_interval

# Test auto-save functionality
python quantum-state-manager.py --test-auto-save

# Monitor auto-save events
tail -f ~/.config/hyprland-session-manager/quantum-state/auto-save.log
```

**Solutions**:
1. **Enable Auto-Save**:
   ```bash
   python quantum-state-config.py --set auto_save_enabled=true
   python quantum-state-manager.py --enable-auto-save
   ```

2. **Adjust Auto-Save Interval**:
   ```bash
   # Set appropriate interval (seconds)
   python quantum-state-config.py --set auto_save_interval=300
   ```

3. **Manual Save Trigger**:
   ```bash
   # Manual save as backup
   python quantum-state-manager.py --save-state
   ```

---

## 3. Emergency Procedures

### 3.1 Complete System Reset

If the Quantum State Manager becomes unresponsive or corrupted:

```bash
# Stop all quantum state processes
python quantum-state-manager.py --stop-monitoring
pkill -f quantum-state-manager

# Backup current state
cp -r ~/.config/hyprland-session-manager/quantum-state/ ~/backup/quantum-state-backup-$(date +%Y%m%d)

# Reset configuration
python quantum-state-config.py --reset-defaults

# Clear state cache
python quantum-state-manager.py --clear-cache

# Restart monitoring
python quantum-state-manager.py --start-monitoring
```

### 3.2 Recovery from Corrupted State

If state files become corrupted:

```bash
# List available backups
python quantum-state-manager.py --list-backups

# Restore from latest backup
python quantum-state-manager.py --restore-latest-backup

# Or restore specific backup
python quantum-state-manager.py --restore-backup backup_name

# Validate restored state
python quantum-state-manager.py --validate-state
```

### 3.3 Performance Emergency

If system performance is severely impacted:

```bash
# Stop monitoring immediately
python quantum-state-manager.py --stop-monitoring

# Clear all caches
python quantum-state-manager.py --clear-all-caches

# Disable intensive features
python quantum-state-config.py --set enable_application_context=false
python quantum-state-config.py --set auto_save_enabled=false

# Restart with minimal configuration
python quantum-state-manager.py --start-monitoring --minimal
```

---

## 4. Advanced Troubleshooting

### 4.1 Network and Remote Issues

If using Quantum State Manager in remote or networked environments:

```bash
# Check network dependencies
python -c "import requests, urllib3"

# Test remote state operations
python quantum-state-manager.py --test-remote

# Verify network connectivity
ping -c 3 8.8.8.8
```

### 4.2 File System Issues

If experiencing file system problems:

```bash
# Check file system health
df -h
lsblk

# Verify state directory permissions
ls -la ~/.config/hyprland-session-manager/quantum-state/

# Test file operations
python quantum-state-manager.py --test-file-ops
```

### 4.3 Security and Permission Issues

If encountering permission problems:

```bash
# Check file permissions
ls -la ~/.config/hyprland-session-manager/
ls -la ~/.config/hyprland-session-manager/quantum-state/

# Fix permissions if