# 🤝 Contributing to Hyprland Session Manager

Thank you for your interest in contributing to the Hyprland Session Manager! We welcome contributions from the community and are excited to work together to make session management better for everyone.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Adding New Application Support](#adding-new-application-support)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)
- [Style Guide](#style-guguide)

## 📜 Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- Be respectful and inclusive
- Exercise consideration and respect in your speech and actions
- Attempt collaboration before conflict
- Refrain from demeaning, discriminatory, or harassing behavior
- Be mindful of your surroundings and fellow participants

## 🚀 Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/hyprland-session-manager.git
   cd hyprland-session-manager
   ```

3. **Set up the development environment** (see [Development Setup](#development-setup))
4. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 💡 How to Contribute

### Types of Contributions We're Looking For

- **Bug Fixes**: Identify and fix issues in the code
- **New Application Support**: Add hooks for additional applications
- **Documentation**: Improve README, add examples, fix typos
- **Performance Improvements**: Optimize existing code
- **New Features**: Suggest and implement new functionality
- **Testing**: Add tests or improve test coverage

### Development Setup

1. **Prerequisites**:
   - Hyprland with `hyprctl`
   - Zsh shell
   - jq for JSON processing

2. **Install development version**:
   ```bash
   ./install.sh
   ```

3. **Test your changes**:
   ```bash
   # Test save functionality
   ~/.config/hyprland-session-manager/session-manager.sh save
   
   # Test restore functionality  
   ~/.config/hyprland-session-manager/session-manager.sh restore
   
   # Test with debug mode
   HYPRLAND_SESSION_DEBUG=1 ~/.config/hyprland-session-manager/session-manager.sh save
   ```

## 🎯 Adding New Application Support

### Step 1: Create Pre-Save Hook

Create a new file in `hooks/pre-save/`:

```bash
# hooks/pre-save/your-app.sh
#!/usr/bin/env zsh

# Your App Session Management Hook
# Pre-save hook for Your App session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Save Your App session information
save_your_app_session() {
    if pgrep -x "yourapp" > /dev/null; then
        log_info "Your App detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/yourapp"
        
        # Extract open documents from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "yourapp") | .title' > "${SESSION_STATE_DIR}/yourapp/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts (workspace data automatically captured)
        hyprctl clients -j | jq -r '.[] | select(.class == "yourapp") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/yourapp/positions.txt" 2>/dev/null
        
        # Save application-specific session files
        # Example: cp "${HOME}/.config/yourapp/session.json" "${SESSION_STATE_DIR}/yourapp/" 2>/dev/null
        
        # Optional: Leverage enhanced workspace data
        if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
            local workspace=$(jq -r ".[] | select(.class == \"yourapp\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
            if [[ -n "$workspace" && "$workspace" != "null" ]]; then
                log_info "Your App workspace assignment detected: $workspace"
            fi
        fi
        
        log_success "Your App session information saved"
    else
        log_info "Your App not running"
    fi
}

# Main function
main() {
    log_info "Starting Your App session preservation..."
    
    save_your_app_session
    
    log_success "Your App session preservation completed"
}

# Execute main function
main "$@"
```

### Step 2: Create Post-Restore Hook

Create a new file in `hooks/post-restore/`:

```bash
# hooks/post-restore/your-app.sh
#!/usr/bin/env zsh

# Your App Session Restoration Hook
# Post-restore hook for Your App session recovery

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[YOUR-APP HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Restore Your App session information
restore_your_app_session() {
    if [[ -d "${SESSION_STATE_DIR}/yourapp" ]]; then
        log_info "Restoring Your App session..."
        
        # Check if session files exist
        if [[ -f "${SESSION_STATE_DIR}/yourapp/window_titles.txt" ]]; then
            # Restore application session
            # Example: cp "${SESSION_STATE_DIR}/yourapp/session.json" "${HOME}/.config/yourapp/" 2>/dev/null
            
            # Optional: Check workspace assignment (workspace positioning handled by main system)
            if [[ -f "${SESSION_STATE_DIR}/application_workspace_mapping.json" ]]; then
                local workspace=$(jq -r ".[] | select(.class == \"yourapp\") | .workspace" "${SESSION_STATE_DIR}/application_workspace_mapping.json" 2>/dev/null)
                if [[ -n "$workspace" && "$workspace" != "null" ]]; then
                    log_info "Your App will be restored to workspace $workspace"
                fi
            fi
            
            log_success "Your App session restored"
        else
            log_warning "No Your App session data found to restore"
        fi
    else
        log_info "No Your App session data to restore"
    fi
}

# Main function
main() {
    log_info "Starting Your App session restoration..."
    
    restore_your_app_session
    
    log_success "Your App session restoration completed"
}

# Execute main function
main "$@"
```

### Step 3: Test Thoroughly

- Test with the application running
- Test with the application not running
- Verify session data is saved correctly
- Verify session data is restored correctly
- Test edge cases and error conditions
- Test with enhanced workspace data available
- Verify hooks work with both traditional and enhanced session data

### Step 4: Update Documentation

- Add your application to the README.md support matrix
- Document any special requirements or limitations
- Add examples if applicable
- Note workspace integration capabilities

### Workspace-Aware Hook Development

When creating hooks for the enhanced workspace system:

1. **Focus on Application Data**: Let the main system handle workspace management
2. **Check for Enhanced Data**: Use workspace mapping when available
3. **Maintain Compatibility**: Ensure hooks work with both data formats
4. **Coordinate with Main System**: Avoid duplicating workspace positioning logic

See [workspace-restoration-hooks-guide.md](workspace-restoration-hooks-guide.md) for detailed workspace integration guidance.

### Terminal Application Enhancement

For terminal applications, consider saving environment and path information:

```bash
# Example: Enhanced terminal session saving
save_terminal_session() {
    local app_class="$1"
    local app_state_dir="${SESSION_STATE_DIR}/$app_class"
    
    mkdir -p "$app_state_dir"
    
    # Save window information
    hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt"
    
    # Save terminal-specific data (environment, current path)
    # This requires application-specific implementation
    save_terminal_environment_data "$app_class" "$app_state_dir"
}
```

See the terminal-specific documentation for detailed implementation examples.

## 🔄 Pull Request Process

1. **Ensure your code follows the style guide**
2. **Add or update tests** as needed
3. **Update documentation** to reflect your changes
4. **Test your changes** thoroughly
5. **Submit your pull request** with a clear description

### Pull Request Checklist

- [ ] Code follows the style guide
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Changes tested on actual Hyprland setup
- [ ] No breaking changes introduced
- [ ] Commit messages are clear and descriptive

## 🐛 Reporting Bugs

When reporting bugs, please include:

1. **Hyprland version**: `hyprctl version`
2. **Session manager version**: Git commit hash
3. **Application details**: What applications were running
4. **Steps to reproduce**: Clear, step-by-step instructions
5. **Expected behavior**: What you expected to happen
6. **Actual behavior**: What actually happened
7. **Logs**: Session manager logs from `~/.config/hyprland-session-manager/session-state/`
8. **Screenshots**: If applicable

## 💡 Feature Requests

We welcome feature requests! Please:

1. **Check if the feature already exists**
2. **Explain the problem** you're trying to solve
3. **Describe your proposed solution**
4. **Provide use cases** and examples
5. **Consider if it fits the project scope**

## 📝 Style Guide

### Shell Script Style

- Use **Zsh** for all scripts
- Follow **Google Shell Style Guide**
- Use **4-space indentation**
- **Quote all variables**
- Use **[[ ]]** for conditionals
- Include **proper error handling**
- Add **comments** for complex logic

### Documentation Style

- Use **Markdown** for documentation
- Follow **GitHub Flavored Markdown**
- Include **code examples** where helpful
- Use **tables** for comparison and matrices
- Add **emoji** for visual clarity (sparingly)

### Commit Message Style

- Use **conventional commits** format
- Start with **type**: feat, fix, docs, style, refactor, test, chore
- Use **imperative mood**: "Add feature" not "Added feature"
- Keep first line under **50 characters**
- Include **detailed description** if needed

Example commit messages:
```
feat: add Firefox session restoration
fix: handle missing hyprctl gracefully
docs: update installation instructions
```

## 🙏 Thank You!

Thank you for contributing to the Hyprland Session Manager! Your efforts help make session management better for the entire Hyprland community.

---

*Happy coding! 🚀*