# 🛠️ Hook Development Guide

Welcome to the comprehensive guide for developing application session hooks for Hyprland Session Manager! This guide will help you create high-quality, reliable hooks that preserve application states effectively.

## 🎯 Understanding Session Management

### What Makes a Good Hook?

A good session hook should:
- **Preserve user workflow** - Save exactly what the user was doing
- **Be reliable** - Work consistently across different scenarios
- **Handle errors gracefully** - Don't crash if something goes wrong
- **Be efficient** - Minimal impact on session save/restore times
- **Be safe** - No destructive operations without confirmation

### Session Data Categories

1. **Window State** (Essential)
   - Window positions and sizes
   - Workspace assignments
   - Monitor placements

2. **Application State** (Important)
   - Open documents/files
   - Current project/workspace
   - Application settings

3. **Session State** (Advanced)
   - Undo history
   - Cursor positions
   - Temporary files

## 🔍 Application Research Methodology

### Step 1: Identify Application Details

```bash
# Find process name
ps aux | grep -i "appname"

# Find window class
hyprctl clients | grep -A5 -B5 "appname"

# Locate configuration files
find ~/.config -name "*appname*" -type f 2>/dev/null
find ~/.local/share -name "*appname*" -type f 2>/dev/null
```

### Step 2: Analyze Session Storage

**Common Session Storage Locations:**
- `~/.config/appname/` - Configuration files
- `~/.local/share/appname/` - Application data
- `~/.cache/appname/` - Temporary/cache files
- Application-specific directories

**Look for:**
- Files containing "session", "state", "recent", "backup"
- JSON/XML configuration files
- SQLite databases
- Recovery/autosave files

### Step 3: Test Session Features

1. **Does the app have built-in session management?**
2. **What happens when you close and reopen?**
3. **Are there command-line options for session restoration?**
4. **Does it auto-save state?**

## 🏗️ Hook Development Process

### Phase 1: Basic Hook Structure

Start with the template and implement:

1. **Application detection** (`is_app_running`)
2. **Window class identification** (`get_app_class`)
3. **Basic window state saving**
4. **Safe directory creation**

### Phase 2: Application-Specific Logic

Add application-specific session preservation:

1. **Configuration file backup**
2. **Session state extraction**
3. **Recovery file handling**
4. **Launch command customization**

### Phase 3: Advanced Features

Implement advanced session management:

1. **Error recovery**
2. **Performance optimization**
3. **Cross-platform compatibility**
4. **User configuration options**

## 💻 Hook Implementation Patterns

### Pattern 1: Configuration File Backup

```bash
save_config_files() {
    local config_dir="${HOME}/.config/myapp"
    local state_dir="${SESSION_STATE_DIR}/myapp"
    
    if [[ -d "$config_dir" ]]; then
        # Backup specific configuration files
        find "$config_dir" -name "*.conf" -o -name "*.json" -o -name "*.xml" | \
        while read -r config_file; do
            cp "$config_file" "$state_dir/" 2>/dev/null || true
        done
    fi
}
```

### Pattern 2: SQLite Database Extraction

```bash
save_sqlite_data() {
    local db_file="${HOME}/.local/share/myapp/data.db"
    local state_dir="${SESSION_STATE_DIR}/myapp"
    
    if [[ -f "$db_file" ]] && command -v sqlite3 > /dev/null; then
        # Extract recent documents
        sqlite3 "$db_file" "SELECT path FROM recent_files;" > "${state_dir}/recent_files.txt" 2>/dev/null
        
        # Extract session state
        sqlite3 "$db_file" "SELECT key, value FROM session_state;" > "${state_dir}/session_state.txt" 2>/dev/null
    fi
}
```

### Pattern 3: Process State Capture

```bash
save_process_state() {
    local app_pid=$(pgrep -x "myapp")
    local state_dir="${SESSION_STATE_DIR}/myapp"
    
    if [[ -n "$app_pid" ]]; then
        # Save process information
        ps -p "$app_pid" -o pid,ppid,cmd > "${state_dir}/process_info.txt" 2>/dev/null
        
        # Save open files
        lsof -p "$app_pid" 2>/dev/null | grep -v "mem\|cwd" > "${state_dir}/open_files.txt" 2>/dev/null
    fi
}
```

## 🧪 Testing Strategies

### Unit Testing

Test individual hook functions:

```bash
# Test application detection
./my-hook.sh pre-save

# Test with debug mode
HYPRLAND_SESSION_DEBUG=1 ./my-hook.sh pre-save

# Test error conditions
rm -rf ~/.config/hyprland-session-manager/session-state/myapp
./my-hook.sh post-restore
```

### Integration Testing

Test complete session workflow:

1. **Start application** and configure state
2. **Save session** and verify data is captured
3. **Close application**
4. **Restore session** and verify state is recovered
5. **Compare** before/after states

### Edge Case Testing

- Application not running
- No session data to restore
- Corrupted session files
- Missing dependencies
- Permission issues

## 🔧 Debugging Techniques

### Enable Debug Logging

```bash
# Set debug environment variable
export HYPRLAND_SESSION_DEBUG=1

# Run hook with detailed output
./my-hook.sh pre-save
```

### Log Analysis

Check these locations for debugging information:

- `~/.config/hyprland-session-manager/session-state/[appname]/`
- System logs: `journalctl --user-unit=hyprland-session`
- Hook-specific log files

### Common Issues and Solutions

**Issue: Hook not executing**
- Check file permissions: `chmod +x hook-file.sh`
- Verify shebang line: `#!/usr/bin/env zsh`
- Check for syntax errors: `zsh -n hook-file.sh`

**Issue: Session data not saving**
- Verify application detection logic
- Check file paths and permissions
- Test individual save functions

**Issue: Session restoration failing**
- Verify session data exists
- Check application launch commands
- Test restoration step by step

## 🚀 Performance Optimization

### Efficient File Operations

```bash
# Use efficient file copying
cp file1 file2 destination/  # Multiple files at once

# Avoid unnecessary operations
if [[ -f "$file" ]]; then
    cp "$file" "$destination/"
fi

# Use streaming for large files
cat large_file | head -1000 > sampled_data.txt
```

### Memory Management

```bash
# Process large files in chunks
while IFS= read -r line; do
    # Process line
    echo "$line" >> output.txt
done < large_file.txt

# Use temporary files for large operations
local temp_file=$(mktemp)
# ... operations on temp_file
mv "$temp_file" "$final_location"
```

## 🔒 Security Best Practices

### Safe File Operations

```bash
# Never use eval with user input
# BAD: eval "$user_input"
# GOOD: Use specific, validated commands

# Validate file paths
if [[ "$file_path" =~ ^[a-zA-Z0-9_./-]+$ ]]; then
    # Safe to use
else
    log_error "Invalid file path: $file_path"
    return 1
fi
```

### Permission Handling

```bash
# Don't require root privileges
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run hooks as root"
    exit 1
fi

# Handle permission errors gracefully
cp "$source" "$dest" 2>/dev/null || {
    log_warning "Could not copy $source - permission denied"
    return 0  # Continue with other operations
}
```

## 📊 Quality Metrics

### Hook Quality Checklist

- [ ] **Reliability**: Works consistently across different scenarios
- [ ] **Safety**: No destructive operations without confirmation
- [ ] **Performance**: Minimal impact on session operations
- [ ] **Error Handling**: Graceful degradation when things go wrong
- [ ] **Documentation**: Clear comments and logging
- [ ] **Compatibility**: Works across different distributions
- [ ] **Maintainability**: Clean, readable code

### Performance Benchmarks

Aim for these performance targets:
- **Pre-save hook**: < 2 seconds
- **Post-restore hook**: < 3 seconds
- **Memory usage**: < 50MB
- **Disk usage**: < 100MB per application

## 🎯 Advanced Techniques

### Cross-Distribution Compatibility

```bash
# Detect distribution
detect_distro() {
    if [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

# Handle different installation paths
case $(detect_distro) in
    "arch")
        APP_PATH="/usr/bin/myapp"
        ;;
    "debian")
        APP_PATH="/usr/bin/myapp"
        ;;
    "fedora")
        APP_PATH="/usr/bin/myapp"
        ;;
    *)
        APP_PATH="myapp"  # Rely on PATH
        ;;
esac
```

### User Configuration Integration

```bash
# Check for user overrides
local user_config="${SESSION_DIR}/config/myapp.conf"
if [[ -f "$user_config" ]]; then
    source "$user_config"
fi

# Allow user customization
: ${MYAPP_SAVE_HISTORY:=true}
: ${MYAPP_MAX_FILES:=100}
```

---

**Remember:** The goal is to create hooks that "just work" for users while being robust and maintainable for the community. Happy hook development! 🚀