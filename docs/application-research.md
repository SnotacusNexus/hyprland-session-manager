# 🔍 Application Research Guide

This guide helps you research applications to understand how they manage sessions and what data can be preserved.

## 🎯 Research Methodology

### Step 1: Basic Application Information

#### Identify Application Details

```bash
# Find the application process
ps aux | grep -i "application-name"

# Get detailed process information
pgrep -x "application-name" | xargs ps -o pid,ppid,cmd -p

# Check if it's running as a service
systemctl --user status "*application*" 2>/dev/null
```

#### Window Information

```bash
# Get window class and title
hyprctl clients | grep -A10 -B10 "application"

# Detailed window information
hyprctl clients -j | jq '.[] | select(.class | test("application", "i"))'

# Monitor window changes in real-time
watch -n 1 'hyprctl clients | grep -A5 "application"'
```

### Step 2: File System Analysis

#### Configuration Files

```bash
# Search for configuration directories
find ~/.config -name "*application*" -type d 2>/dev/null
find ~/.local/share -name "*application*" -type d 2>/dev/null
find /usr/share -name "*application*" -type d 2>/dev/null

# Look for configuration files
find ~/.config -name "*application*" -type f 2>/dev/null | head -20
find ~/.local/share -name "*application*" -type f 2>/dev/null | head -20
```

#### Session-Related Files

```bash
# Search for session, state, or recent files
find ~/.config -name "*session*" -o -name "*state*" -o -name "*recent*" -o -name "*backup*" 2>/dev/null
find ~/.local/share -name "*session*" -o -name "*state*" -o -name "*recent*" -o -name "*backup*" 2>/dev/null

# Look for auto-save or recovery files
find ~/.local/share -name "*autosave*" -o -name "*recovery*" -o -name "*temp*" 2>/dev/null
```

### Step 3: Database Analysis

#### SQLite Databases

```bash
# Find SQLite databases
find ~/.config ~/.local/share -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" 2>/dev/null

# Examine database structure (if sqlite3 is available)
for db in $(find ~/.config ~/.local/share -name "*.db" -o -name "*.sqlite*" 2>/dev/null); do
    echo "=== Database: $db ==="
    sqlite3 "$db" ".tables" 2>/dev/null
    echo
done
```

#### Common Database Tables to Look For

- `recent_files`, `recent_documents`
- `session_state`, `app_state`
- `open_files`, `current_files`
- `workspaces`, `projects`
- `history`, `undo_stack`

### Step 4: Process Analysis

#### Open Files and Resources

```bash
# See what files the application has open
pgrep -x "application-name" | xargs lsof -p

# Monitor file access in real-time
sudo strace -f -e trace=file -p $(pgrep -x "application-name") 2>&1 | grep -v ENOENT
```

#### Network and IPC

```bash
# Check for network connections
pgrep -x "application-name" | xargs lsof -p | grep -E "(TCP|UDP|IPv)"

# Look for IPC mechanisms
find /tmp -name "*application*" -type f 2>/dev/null
ls -la /run/user/$(id -u)/ | grep -i application
```

## 📊 Application Categories

### Category 1: Document-Based Applications

**Examples:** LibreOffice, GIMP, Krita, Inkscape

**What to look for:**
- Open document paths
- Recent files lists
- Auto-save/recovery files
- Undo history
- Application preferences

**Research commands:**
```bash
# Document applications often store recent files
find ~/.config -name "*recent*" -o -name "*history*" 2>/dev/null

# Look for document recovery
find ~/.local/share -name "*recovery*" -o -name "*autosave*" 2>/dev/null
```

### Category 2: Project-Based Applications

**Examples:** VSCode, IntelliJ, Blender, Godot

**What to look for:**
- Workspace/project files
- Open file lists
- Session state
- Debugger state
- Terminal sessions

**Research commands:**
```bash
# Project files and workspaces
find ~/.config -name "*workspace*" -o -name "*project*" 2>/dev/null

# Session and state files
find ~/.config -name "*session*" -o -name "*state*" 2>/dev/null
```

### Category 3: Browser-Based Applications

**Examples:** Firefox, Chrome, Chromium, Brave

**What to look for:**
- Session files (sessionstore.json)
- Profile directories
- Tab/window state
- Browsing history
- Cookies and cache

**Research commands:**
```bash
# Browser profiles and sessions
find ~/.mozilla ~/.config -name "sessionstore*" -o -name "*recovery*" 2>/dev/null

# Profile directories
ls -la ~/.mozilla/firefox/ 2>/dev/null
ls -la ~/.config/chromium/ 2>/dev/null
```

### Category 4: Terminal Applications

**Examples:** Kitty, Terminator, Alacritty, Wezterm

**What to look for:**
- Session files
- Layout configurations
- Command history
- Working directories
- Process trees

**Research commands:**
```bash
# Terminal session files
find ~/.config -name "*session*" -o -name "*layout*" 2>/dev/null

# Shell history
ls -la ~/.zsh_history ~/.bash_history 2>/dev/null
```

## 🔧 Advanced Research Techniques

### File Monitoring

```bash
# Monitor file changes while using the application
inotifywait -m -r ~/.config/application-name/ ~/.local/share/application-name/ 2>/dev/null

# Monitor specific directories
watch -n 1 'ls -la ~/.config/application-name/ ~/.local/share/application-name/ 2>/dev/null'
```

### Process Tracing

```bash
# Trace file operations
strace -f -e trace=file -o application-trace.txt application-name

# Trace system calls
strace -f -o application-full-trace.txt application-name
```

### Memory Analysis

```bash
# Check memory maps
pgrep -x "application-name" | xargs pmap

# Look for shared memory
ipcs -m | grep $(whoami)
```

## 📝 Research Documentation Template

### Application: [Application Name]

#### Basic Information
- **Process Name:** 
- **Window Class:** 
- **Configuration Directory:** 
- **Data Directory:** 

#### Session Data Sources

**Configuration Files:**
- `~/.config/application/settings.json` - Application settings
- `~/.config/application/recent-files.txt` - Recent documents
- `~/.local/share/application/session.state` - Session state

**Database Files:**
- `~/.local/share/application/app.db` - SQLite database
  - `recent_files` table - Recent documents
  - `session_state` table - Current session

**Temporary Files:**
- `/tmp/application-autosave-*` - Auto-save files
- `~/.cache/application/recovery-*` - Recovery data

#### Session Restoration Method

**Launch Command:**
```bash
application-name --restore-session /path/to/session/file
```

**Manual Restoration:**
1. Copy session files to appropriate locations
2. Launch application
3. Application auto-detects restored session

#### Special Considerations
- Requires specific command-line flags for session restoration
- Session files are in binary format
- Cross-platform compatibility issues

## 🎯 Quick Research Checklist

### Basic Information
- [ ] Process name identified
- [ ] Window class identified
- [ ] Configuration directory found
- [ ] Data directory found

### Session Data
- [ ] Session files located
- [ ] Recent files list found
- [ ] Auto-save/recovery files identified
- [ ] Database files examined

### Restoration Method
- [ ] Command-line options researched
- [ ] Session file format understood
- [ ] Restoration process tested
- [ ] Error conditions handled

### Testing
- [ ] Basic session save tested
- [ ] Session restoration verified
- [ ] Edge cases considered
- [ ] Performance impact assessed

## 🔍 Common Research Tools

### Essential Tools
- `find` - File system search
- `grep` - Pattern matching
- `lsof` - Open file inspection
- `strace` - System call tracing
- `sqlite3` - Database inspection
- `inotifywait` - File change monitoring

### Advanced Tools
- `ltrace` - Library call tracing
- `gdb` - Debugger for complex applications
- `strings` - Extract text from binary files
- `file` - Identify file types
- `hexdump` - Binary file analysis

---

**Remember:** Thorough research is the foundation of a reliable hook. The more you understand about how an application manages its state, the better your hook will be! 🔍