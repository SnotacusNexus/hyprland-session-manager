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
