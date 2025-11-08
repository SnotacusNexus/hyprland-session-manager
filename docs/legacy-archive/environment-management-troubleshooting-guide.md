# Environment Management System - Troubleshooting Guide

## Overview

This troubleshooting guide provides step-by-step solutions for common issues with the environment-aware session management system and the new Quantum State Manager. The guide is organized by symptom and includes diagnostic procedures and workarounds.

**Note**: The Quantum State Manager supersedes many legacy environment management features with enhanced capabilities for comprehensive desktop state persistence.

---

## 1. Diagnostic Procedures

### 1.1 System Health Check

Run the comprehensive health check to identify system issues:

```bash
# Run basic system check (legacy system)
./environment-validation.sh detect
./environment-change-detector.sh status
./test-environment-validation.sh quick

# Quantum State Manager health check
python quantum-state-manager.py --status
python quantum-state-manager.py --validate-config

# Check for common configuration issues
grep -E "(MONITOR|TRIGGER|ENABLED)" ~/.config/hyprland-session-manager/environment-monitor.conf

# Verify file permissions
ls -la ~/.config/hyprland-session-manager/
ls -la ~/.config/hyprland-session-manager/quantum-state/
```

### 1.2 Debug Mode

Enable detailed logging for troubleshooting:

```bash
# Enable debug mode (legacy system)
export ENVIRONMENT_DEBUG=1
export SESSION_DEBUG=1

# Quantum State Manager debug mode
export QUANTUM_STATE_DEBUG=1
python quantum-state-manager.py --debug

# Run commands with debug output
./environment-validation.sh detect
./environment-change-detector.sh start
python quantum-state-manager.py --status

# Check debug logs
tail -f ~/.config/hyprland-session-manager/*.log
tail -f ~/.config/hyprland-session-manager/quantum-state/*.log
```

---

## 2. Common Issues and Solutions

### 2.1 Environment Detection Issues

#### Issue: No Environments Detected
**Symptoms**: Empty detection results, "No environments found" messages

**Diagnostic Steps**:
```bash
# Check environment manager availability
command -v conda
command -v mamba
command -v pyenv

# Verify common environment locations
ls -la ~/.virtualenvs/ 2>/dev/null || echo "No virtualenvs directory"
ls -la ~/miniconda3/envs/ 2>/dev/null || echo "No conda environments"
ls -la ~/anaconda3/envs/ 2>/dev/null || echo "No anaconda environments"

# Test individual detection functions
./environment-validation.sh detect --type conda
./environment-validation.sh detect --type venv
```

**Solutions**:
1. **Environment Manager Not Installed**:
   ```bash
   # Install missing environment manager
   # conda/miniconda, mamba, pyenv, or virtualenv
   ```

2. **Custom Environment Locations**:
   ```bash
   # Add custom paths to configuration
   echo 'CUSTOM_PATHS="/custom/venv/path /another/path"' >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

3. **Permission Issues**:
   ```bash
   # Fix directory permissions
   chmod 755 ~/.virtualenvs/
   chmod 755 ~/miniconda3/envs/
   ```

#### Issue: Partial Environment Detection
**Symptoms**: Some environments detected, others missing

**Diagnostic Steps**:
```bash
# Compare manual vs automated detection
conda env list
./environment-validation.sh detect --type conda

mamba env list  
./environment-validation.sh detect --type mamba

pyenv versions
./environment-validation.sh detect --type pyenv
```

**Solutions**:
1. **Environment Naming Issues**:
   - Some detection methods rely on specific naming patterns
   - Use standard environment naming conventions

2. **Path Resolution Problems**:
   ```bash
   # Check path resolution
   realpath ~/miniconda3/envs/
   # Ensure symbolic links are resolved correctly
   ```

### 2.2 Validation Issues

#### Issue: Health Validation Always Fails
**Symptoms**: All environments reported as unhealthy, activation tests fail

**Diagnostic Steps**:
```bash
# Test environment activation manually
conda activate test-env
python -c "import sys; print(sys.version)"

# Check activation script availability
ls -la ~/miniconda3/etc/profile.d/conda.sh

# Test virtual environment
source /path/to/venv/bin/activate
python --version
```

**Solutions**:
1. **Skip Health Validation** (Recommended Workaround):
   ```bash
   export SKIP_HEALTH_VALIDATION=true
   ./environment-validation.sh validate
   ```

2. **Fix Activation Issues**:
   ```bash
   # Ensure conda is properly initialized
   source ~/miniconda3/etc/profile.d/conda.sh
   conda init bash  # or zsh, depending on shell
   ```

3. **Use Existence Validation Only**:
   ```bash
   # Manual existence validation
   validate_environment_exists "conda" "my-env" ""
   ```

#### Issue: Metadata Capture Fails
**Symptoms**: Missing Python versions, incomplete environment information

**Diagnostic Steps**:
```bash
# Test metadata extraction for specific environment
get_environment_metadata "conda" "base" ""

# Check jq availability (required for JSON processing)
command -v jq

# Test Python version detection
conda run -n base python --version
```

**Solutions**:
1. **Install jq** (if missing):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # CentOS/RHEL
   sudo yum install jq
   
   # macOS
   brew install jq
   ```

2. **Use Basic Environment Listing**:
   ```bash
   # Use detection without detailed metadata
   ./environment-validation.sh detect
   capture_environment_metadata  # Basic listing works
   ```

### 2.3 Change Detection Issues

#### Issue: Change Detection Not Working
**Symptoms**: No change notifications, monitoring daemon not responding

**Diagnostic Steps**:
```bash
# Check monitoring status
./environment-change-detector.sh status

# Verify daemon is running
ps aux | grep environment-change-detector

# Check for PID files
ls -la ~/.config/hyprland-session-manager/monitor_*.txt

# Test directory monitoring
inotifywait -m -e create /tmp/test-dir &
# Create test file in another terminal
touch /tmp/test-dir/test-file.txt
```

**Solutions**:
1. **Restart Monitoring Daemon**:
   ```bash
   ./environment-change-detector.sh stop
   sleep 2
   ./environment-change-detector.sh start --force
   ```

2. **Check inotify Limits**:
   ```bash
   # Check current inotify limits
   cat /proc/sys/fs/inotify/max_user_watches
   cat /proc/sys/fs/inotify/max_user_instances
   
   # Increase limits if needed
   echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
   echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

3. **Permission Issues**:
   ```bash
   # Ensure user has access to monitor directories
   ls -la ~/miniconda3/envs/
   ls -la ~/.virtualenvs/
   ```

#### Issue: False Positive Change Detection
**Symptoms**: Too many change notifications, auto-save triggers too frequently

**Diagnostic Steps**:
```bash
# Check current configuration
grep -E "(CHANGE_THRESHOLD|MONITOR_INTERVAL)" ~/.config/hyprland-session-manager/environment-monitor.conf

# Monitor change events with debug
export ENVIRONMENT_DEBUG=1
./environment-change-detector.sh start
```

**Solutions**:
1. **Adjust Change Threshold**:
   ```bash
   # Increase threshold to reduce sensitivity
   echo "CHANGE_THRESHOLD=3" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

2. **Increase Monitoring Interval**:
   ```bash
   # Check less frequently
   echo "MONITOR_INTERVAL=300" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

3. **Disable Less Critical Triggers**:
   ```bash
   echo "TRIGGER_PACKAGE_UPDATES=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   echo "TRIGGER_ENVIRONMENT_SWITCHES=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

### 2.4 Auto-Save Integration Issues

#### Issue: Auto-Save Not Triggering
**Symptoms**: Changes detected but no session save occurs

**Diagnostic Steps**:
```bash
# Check auto-save configuration (legacy system)
grep AUTO_SAVE_ENABLED ~/.config/hyprland-session-manager/environment-monitor.conf

# Quantum State Manager auto-save status
python quantum-state-manager.py --status | grep -i auto

# Verify session manager availability
ls -la ~/.config/hyprland-session-manager/session-manager.sh

# Test manual session save
./session-manager.sh save

# Check for integration issues
./test-environment-change-detection.sh run
```

**Solutions**:
1. **Enable Auto-Save** (Legacy System):
   ```bash
   echo "AUTO_SAVE_ENABLED=true" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

2. **Use Quantum State Manager Auto-Save** (Recommended):
   ```bash
   # Enable quantum state auto-save
   python quantum-state-manager.py --enable-auto-save
   python quantum-state-manager.py --start-monitoring
   ```

3. **Manual Save Workflow**:
   ```bash
   # Use manual saves until integration is fixed
   ./environment-change-detector.sh start
   # When notified of changes, manually run:
   ./session-manager.sh save
   ```

4. **Verify Session Manager**:
   ```bash
   # Ensure session manager script exists and is executable
   chmod +x ~/.config/hyprland-session-manager/session-manager.sh
   ```

#### Issue: Auto-Save Fails
**Symptoms**: Auto-save triggered but session save fails

**Diagnostic Steps**:
```bash
# Check session manager logs
tail -f ~/.config/hyprland-session-manager/session-manager.log

# Check Quantum State Manager logs
tail -f ~/.config/hyprland-session-manager/quantum-state/*.log

# Test session save manually
./session-manager.sh save

# Test quantum state save
python quantum-state-manager.py --save-state

# Check for permission issues
ls -la ~/.config/hyprland-session-manager/session-state/
ls -la ~/.config/hyprland-session-manager/quantum-state/
```

**Solutions**:
1. **Fix Permission Issues**:
   ```bash
   chmod 755 ~/.config/hyprland-session-manager/
   chmod 755 ~/.config/hyprland-session-manager/session-state/
   chmod 755 ~/.config/hyprland-session-manager/quantum-state/
   ```

2. **Use Quantum State Manager** (Recommended):
   ```bash
   # Use quantum state manager instead of legacy auto-save
   python quantum-state-manager.py --save-state
   ```

3. **Use Manual Save**:
   ```bash
   # Disable auto-save and use manual workflow
   echo "AUTO_SAVE_ENABLED=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

### 2.5 Performance Issues

#### Issue: High Resource Usage
**Symptoms**: System slowdown, high CPU/memory usage by monitoring

**Diagnostic Steps**:
```bash
# Check resource usage
ps aux --sort=-%cpu | grep environment
top -p $(pgrep -f environment-change-detector)

# Monitor process activity
strace -p $(pgrep -f environment-change-detector) 2>&1 | head -20
```

**Solutions**:
1. **Reduce Monitoring Frequency**:
   ```bash
   echo "MONITOR_INTERVAL=300" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

2. **Limit Concurrent Monitors**:
   ```bash
   echo "MAX_MONITORS=5" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

3. **Disable Intensive Features**:
   ```bash
   echo "CACHE_ENABLED=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   echo "BATCH_PROCESSING=false" >> ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

#### Issue: Slow Environment Detection
**Symptoms**: Long delays when detecting environments

**Diagnostic Steps**:
```bash
# Time environment detection
time ./environment-validation.sh detect

# Check for network issues (conda may try to reach repositories)
ping repo.anaconda.com
```

**Solutions**:
1. **Use Offline Mode** (if applicable):
   ```bash
   conda config --set offline true
   ```

2. **Manual Detection with Caching**:
   ```bash
   # Run detection once and reuse results
   ./environment-validation.sh detect > /tmp/env-cache.json
   # Use cached results for subsequent operations
   ```

---

## 3. Emergency Procedures

### 3.1 Complete System Reset

If the system becomes unresponsive or corrupted:

```bash
# Stop all monitoring processes
./environment-change-detector.sh stop
pkill -f environment-change-detector
pkill -f inotifywait

# Clean up PID files
rm -f ~/.config/hyprland-session-manager/monitor_*.txt
rm -f ~/.config/hyprland-session-manager/stop_monitoring

# Reset configuration
mv ~/.config/hyprland-session-manager/environment-monitor.conf ~/.config/hyprland-session-manager/environment-monitor.conf.backup

# Restart with defaults
./environment-change-detector.sh start
```

### 3.2 Recovery from Failed Session Save

If auto-save fails during critical environment changes:

```bash
# Manual environment validation (legacy system)
./environment-validation.sh validate

# Quantum State Manager recovery
python quantum-state-manager.py --recover-state
python quantum-state-manager.py --validate-state

# Force session save without validation
./session-manager.sh save --force

# Or use basic save functionality
./session-manager.sh save-basic

# Use quantum state save as backup
python quantum-state-manager.py --save-state
```

### 3.3 Environment Corruption Recovery

If environments become corrupted during monitoring:

```bash
# Stop monitoring immediately
./environment-change-detector.sh stop

# Validate environment integrity
conda info
conda list -n base

# Repair conda environment if needed
conda clean --all
conda update --all

# Restart monitoring after repair
./environment-change-detector.sh start
```

---

## 4. Advanced Troubleshooting

### 4.1 Network Issues

If environment detection fails due to network problems:

```bash
# Check network connectivity for environment managers
ping repo.anaconda.com
ping pypi.org

# Use offline mode for conda
conda config --set offline true

# Configure proxies if needed
export http_proxy=http://proxy:port
export https_proxy=https://proxy:port
```

### 4.2 Shell Integration Issues

If environment detection fails due to shell configuration:

```bash
# Check shell initialization
cat ~/.bashrc | grep -i conda
cat ~/.zshrc | grep -i conda

# Reinitialize conda
source ~/miniconda3/etc/profile.d/conda.sh
conda init

# Test shell integration
conda activate base
python --version
```

### 4.3 File System Issues

If monitoring fails due to file system problems:

```bash
# Check file system health
df -h
lsblk

# Check for mount issues
mount | grep /home

# Verify inotify works
inotifywait -m -e create /tmp 2>&1 | head -5
```

---

## 5. Support Information

### 5.1 Log Files Location

- **Application Logs**: `~/.config/hyprland-session-manager/*.log`
- **Quantum State Logs**: `~/.config/hyprland-session-manager/quantum-state/*.log`
- **System Logs**: `journalctl -u hyprland-session-manager`
- **Debug Logs**: Enable with `export ENVIRONMENT_DEBUG=1`
- **Quantum State Debug**: Enable with `export QUANTUM_STATE_DEBUG=1`

### 5.2 Test Suite

Run comprehensive tests to identify issues:

```bash
# Basic functionality tests (legacy system)
./test-environment-validation.sh quick

# Quantum State Manager tests
python test-quantum-state-manager.py

# Comprehensive testing
./test-environment-validation.sh all
./test-environment-change-detection.sh run

# Integration tests
./test-enhanced-session-data.sh

# Quantum State integration tests
python quantum-state-manager.py --test-integration
```

### 5.3 Getting Help

When requesting support, provide:

1. **System Information**:
   ```bash
   uname -a
   lsb_release -a 2>/dev/null || cat /etc/os-release
   ```

2. **Environment Information**:
   ```bash
   conda --version
   mamba --version
   pyenv --version
   ```

3. **Configuration**:
   ```bash
   cat ~/.config/hyprland-session-manager/environment-monitor.conf
   ```

4. **Error Logs**:
   ```bash
   tail -50 ~/.config/hyprland-session-manager/*.log
   ```

---

## 6. Prevention and Best Practices

### 6.1 Regular Maintenance

```bash
# Weekly system check
./environment-validation.sh validate
./environment-change-detector.sh status

# Monthly comprehensive testing
./test-environment-validation.sh all
```

### 6.2 Backup Procedures

```bash
# Backup configuration
cp ~/.config/hyprland-session-manager/environment-monitor.conf ~/backup/

# Backup session state (legacy system)
tar -czf ~/backup/session-state-$(date +%Y%m%d).tar.gz ~/.config/hyprland-session-manager/session-state/

# Backup quantum state data
tar -czf ~/backup/quantum-state-$(date +%Y%m%d).tar.gz ~/.config/hyprland-session-manager/quantum-state/

# Create quantum state backup
python quantum-state-manager.py --create-backup
```

### 6.3 Update Procedures

When updating the system:

```bash
# Stop monitoring before updates
./environment-change-detector.sh stop
python quantum-state-manager.py --stop-monitoring

# Update environment managers
conda update --all
pip list --outdated

# Restart monitoring after updates
./environment-change-detector.sh start
python quantum-state-manager.py --start-monitoring

# Validate quantum state after updates
python quantum-state-manager.py --validate-state
```

This troubleshooting guide should help resolve most common issues with the environment management system and Quantum State Manager. For persistent problems, refer to the main documentation or seek support from the development team.

---

## 7. Quantum State Manager Troubleshooting

### 7.1 Quantum State Manager Issues

#### Issue: Quantum State Manager Not Starting
**Symptoms**: Python import errors, missing dependencies, initialization failures

**Diagnostic Steps**:
```bash
# Check Python dependencies
python -c "import json, subprocess, threading, time, hashlib, os, sys, signal, logging, dataclasses, typing, pathlib, shutil, tempfile, uuid, datetime, re, collections, functools, itertools, contextlib, asyncio"

# Test quantum state manager
python quantum-state-manager.py --status

# Check configuration
python quantum-state-config.py --validate
```

**Solutions**:
1. **Install Missing Dependencies**:
   ```bash
   pip install dataclasses-json typing-extensions
   ```

2. **Fix Configuration Issues**:
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

### 7.2 Migration Issues

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

### 7.3 Configuration Issues

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

### 7.4 Integration Issues

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

For comprehensive Quantum State Manager troubleshooting, refer to the `quantum-state-user-guide.md` and `quantum-state-migration-guide.md` documentation.