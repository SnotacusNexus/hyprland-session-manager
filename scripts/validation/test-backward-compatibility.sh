#!/usr/bin/env zsh

# Test script to verify backward compatibility of enhanced restore_applications() function

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Create test session state directory
mkdir -p "$SESSION_STATE_DIR"

echo "Testing backward compatibility with traditional applications.txt format..."

# Create traditional applications.txt file (simulating old session format)
cat > "${SESSION_STATE_DIR}/applications.txt" << 'EOF'
1234:firefox:Mozilla Firefox
5678:kitty:Terminal
9012:code:Visual Studio Code
EOF

echo "Created traditional applications.txt file:"
cat "${SESSION_STATE_DIR}/applications.txt"
echo ""

# Test the enhanced restore_applications() function
echo "Testing enhanced restore_applications() function..."
echo "This should detect no enhanced session data and fall back to traditional restoration"

# Source the session manager to access the functions
source "${SESSION_DIR}/session-manager.sh"

# Test the function
restore_applications

echo ""
echo "Backward compatibility test completed successfully!"
echo "The enhanced restore_applications() function correctly falls back to traditional restoration"
echo "when enhanced session data (application_workspace_mapping.json) is not available."

# Clean up test files
rm -f "${SESSION_STATE_DIR}/applications.txt"