#!/usr/bin/env zsh

# 🧹 Sanitize for GitHub Script
# Removes personal information and prepares for public GitHub repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(pwd)"
BACKUP_DIR="${PROJECT_DIR}/.backup-$(date +%s)"
SANITIZED_DIR="${PROJECT_DIR}/hyprland-session-manager-github"

# Logging functions
log_info() {
    echo -e "${BLUE}[SANITIZE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SANITIZE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SANITIZE]${NC} $1"
}

log_error() {
    echo -e "${RED}[SANITIZE]${NC} $1"
}

# Create backup
create_backup() {
    log_info "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    log_success "Backup created: $BACKUP_DIR"
}

# Create sanitized directory
create_sanitized_dir() {
    log_info "Creating sanitized directory..."
    rm -rf "$SANITIZED_DIR"
    mkdir -p "$SANITIZED_DIR"
    
    # Copy all files except session state and backups
    rsync -av --exclude='.backup-*' --exclude='session-state' --exclude='research_data' \
          --exclude='.git' --exclude='*.old' --exclude='*.backup' \
          "$PROJECT_DIR/" "$SANITIZED_DIR/" > /dev/null 2>&1
    
    log_success "Sanitized directory created: $SANITIZED_DIR"
}

# Sanitize file contents
sanitize_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    # Skip binary files
    if file "$file" | grep -q "binary"; then
        return
    fi
    
    # Create temporary file
    local temp_file="${file}.tmp"
    
    # Apply sanitization rules
    sed -E '
        # Replace specific username with generic
        s/SnotacusNexus/SnotacusNexus/g
        
        # Replace specific home directory
        s|/home/SnotacusNexus/|/home/SnotacusNexus/|g
        
        # Replace specific git directory
        s|/home/SnotacusNexus/git/hyprland-session-manager|/home/SnotacusNexus/.config/hyprland-session-manager|g
        
        # Replace GitHub URLs
        s|https://github.com/SnotacusNexus/hyprland-session-manager|https://github.com/SnotacusNexus/hyprland-session-manager|g
        
        # Remove any personal API keys or tokens (generic patterns)
        s/[a-zA-Z0-9]{32,}/[REDACTED_API_KEY]/g
        s/ghp_[a-zA-Z0-9]{36}/[REDACTED_GITHUB_TOKEN]/g
        
        # Remove any IP addresses
        s/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[REDACTED_IP]/g
        
        # Remove any email addresses
        s/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[REDACTED_EMAIL]/g
    ' "$file" > "$temp_file"
    
    # Replace original file if changes were made
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        log_info "Sanitized: $(basename "$file")"
    else
        rm "$temp_file"
    fi
}

# Sanitize all text files
sanitize_all_files() {
    log_info "Sanitizing file contents..."
    
    # Find all text files
    find "$SANITIZED_DIR" -type f \( -name "*.sh" -o -name "*.md" -o -name "*.txt" -o -name "*.conf" -o -name "*.yml" -o -name "*.yaml" \) | \
    while read -r file; do
        sanitize_file "$file"
    done
    
    log_success "File content sanitization complete"
}

# Update README for GitHub
update_readme_for_github() {
    local readme_file="$SANITIZED_DIR/README.md"
    
    log_info "Updating README for GitHub..."
    
    # Add GitHub badges
    sed -i '1i\
# 🚀 Hyprland Session Manager\n\
![GitHub](https://img.shields.io/github/license/SnotacusNexus/hyprland-session-manager)\n\
![GitHub release](https://img.shields.io/github/v/release/SnotacusNexus/hyprland-session-manager)\n\
![GitHub issues](https://img.shields.io/github/issues/SnotacusNexus/hyprland-session-manager)\n\
![GitHub pull requests](https://img.shields.io/github/issues-pr/SnotacusNexus/hyprland-session-manager)\n\
' "$readme_file"
    
    log_success "README updated for GitHub"
}

# Remove sensitive directories
remove_sensitive_dirs() {
    log_info "Removing sensitive directories..."
    
    # Remove session state directories
    find "$SANITIZED_DIR" -type d -name "session-state" -exec rm -rf {} + 2>/dev/null || true
    find "$SANITIZED_DIR" -type d -name "research_data" -exec rm -rf {} + 2>/dev/null || true
    
    # Remove any backup directories
    find "$SANITIZED_DIR" -type d -name ".backup-*" -exec rm -rf {} + 2>/dev/null || true
    
    log_success "Sensitive directories removed"
}

# Create .gitignore
create_gitignore() {
    log_info "Creating .gitignore..."
    
    cat > "$SANITIZED_DIR/.gitignore" << 'EOF'
# Session state data
session-state/
*.session
*.state

# Backup files
*.backup
*.old
.backup-*

# Personal configuration
personal-config/
secrets.conf
*.key
*.token

# Temporary files
*.tmp
*.temp

# Log files
*.log
logs/

# System files
.DS_Store
Thumbs.db

# Development
research_data/
test-data/

# Local overrides
local-overrides/
user-config/
EOF
    
    log_success ".gitignore created"
}

# Create GitHub deployment script
create_github_deploy_script() {
    log_info "Creating GitHub deployment script..."
    
    cat > "$SANITIZED_DIR/deploy-to-github.sh" << 'EOF'
#!/usr/bin/env zsh

# 🚀 GitHub Deployment Script
# Use this to deploy the sanitized version to GitHub

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GitHub Deployment${NC}"
echo "=================="
echo ""

# Check if we're in the sanitized directory
if [[ ! -f "README.md" ]] || [[ ! -d ".github" ]]; then
    echo "❌ Error: This doesn't look like the sanitized directory."
    echo "   Run ./sanitize-for-github.sh first, then run this script from the generated directory."
    exit 1
fi

# Initialize git if not already
echo "📦 Setting up Git repository..."
if [[ ! -d ".git" ]]; then
    git init
    git add .
    git commit -m "Initial commit: Hyprland Session Manager"
    echo "✅ Git repository initialized"
else
    echo "ℹ️  Git repository already exists"
fi

# Instructions for GitHub
echo ""
echo "🎯 Next Steps:"
echo "============="
echo ""
echo "1. Create a new repository on GitHub:"
echo "   - Go to https://github.com/new"
echo "   - Name it 'hyprland-session-manager'"
echo "   - Make it PUBLIC (for community contributions)"
echo "   - DO NOT initialize with README (we already have one)"
echo ""
echo "2. Connect your local repository:"
echo "   git remote add origin https://github.com/SnotacusNexus/hyprland-session-manager.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "3. Enable GitHub Actions:"
echo "   - Go to your repository Settings > Actions > General"
echo "   - Enable 'Allow all actions and reusable workflows'"
echo ""
echo "4. Update the README:"
echo "   - Replace 'SnotacusNexus' with your actual GitHub username"
echo "   - Update repository URLs in documentation"
echo ""
echo "5. Create first release:"
echo "   - Go to Releases > Create new release"
echo "   - Tag: v1.0.0"
echo "   - Title: Initial Release"
echo "   - Description: Comprehensive Hyprland session management with community hooks"
echo ""
echo "✅ Your Hyprland Session Manager is ready for the community! 🚀"
EOF
    
    chmod +x "$SANITIZED_DIR/deploy-to-github.sh"
    log_success "GitHub deployment script created"
}

# Create final instructions
create_final_instructions() {
    log_info "Creating final instructions..."
    
    cat > "$SANITIZED_DIR/GITHUB_SETUP.md" << 'EOF'
# 🚀 GitHub Setup Instructions

## What Just Happened

This directory (`hyprland-session-manager-github/`) contains a sanitized version of your Hyprland Session Manager, ready for public GitHub release.

## 🧹 What Was Sanitized

- ✅ Removed personal username references
- ✅ Replaced specific home directory paths
- ✅ Removed session state data
- ✅ Added proper .gitignore
- ✅ Updated documentation for public use

## 🎯 Next Steps

### 1. Review the Sanitized Code
```bash
cd hyprland-session-manager-github
# Review files to ensure no personal information remains
```

### 2. Deploy to GitHub
```bash
./deploy-to-github.sh
# Follow the instructions in the script
```

### 3. Configure GitHub Repository
- Enable GitHub Actions in repository settings
- Set up branch protection rules
- Configure issue templates
- Enable GitHub Discussions for community

### 4. Announce to Community
- Post in Hyprland Discord/Matrix channels
- Share on Reddit (r/hyprland)
- Add to Hyprland community lists

## 📋 Repository Checklist

- [ ] Repository created on GitHub
- [ ] Code pushed to main branch
- [ ] GitHub Actions enabled
- [ ] README URLs updated
- [ ] First release created
- [ ] Community announcement made

## 🔧 Repository Settings

**Recommended Settings:**
- Visibility: Public
- Issues: Enabled
- Pull Requests: Enabled
- Discussions: Enabled
- Wiki: Disabled (use docs/ instead)
- Projects: Enabled

**Branch Protection:**
- Require pull request reviews
- Require status checks to pass
- Include administrators
- Require linear history

## 🎉 Welcome to Open Source!

Your project is now ready to grow through community contributions. The infrastructure is in place for:

- Automated hook validation
- Community contribution workflow
- Quality assurance through CI/CD
- Sustainable community growth

**Thank you for sharing your work with the Hyprland community!** 🌟
EOF
    
    log_success "Final instructions created"
}

# Main sanitization function
main() {
    echo "🧹 Hyprland Session Manager - GitHub Sanitization"
    echo "================================================"
    echo ""
    
    # Check if we're in the right directory
    if [[ ! -f "README.md" ]] || [[ ! -d ".github" ]]; then
        log_error "This doesn't look like the Hyprland Session Manager directory"
        log_error "Please run this script from the project root"
        exit 1
    fi
    
    create_backup
    create_sanitized_dir
    sanitize_all_files
    update_readme_for_github
    remove_sensitive_dirs
    create_gitignore
    create_github_deploy_script
    create_final_instructions
    
    echo ""
    echo "🎉 Sanitization Complete!"
    echo "======================="
    echo ""
    echo "✅ Backup created: $BACKUP_DIR"
    echo "✅ Sanitized version: $SANITIZED_DIR"
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Review the sanitized code in: $SANITIZED_DIR"
    echo "2. Run: cd $SANITIZED_DIR && ./deploy-to-github.sh"
    echo "3. Follow the deployment instructions"
    echo ""
    echo "📚 See $SANITIZED_DIR/GITHUB_SETUP.md for detailed instructions"
    echo ""
}

# Execute main function
main "$@"