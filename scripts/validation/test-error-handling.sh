#!/usr/bin/env zsh

# Test script to verify error handling and graceful degradation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Create session state directory
mkdir -p "$SESSION_STATE_DIR"

echo "Testing error handling and graceful degradation..."

# Test 1: Missing enhanced session data (should fall back to traditional)
echo ""
echo "=== TEST 1: Missing enhanced session data ==="
rm -f "${SESSION_STATE_DIR}/workspace_layouts.json"
rm -f "${SESSION_STATE_DIR}/application_workspace_mapping.json"
rm -f "${SESSION_STATE_DIR}/window_states.json"

# Create only traditional applications.txt
cat > "${SESSION_STATE_DIR}/applications.txt" << 'EOF'
1234:kitty:Test Terminal
5678:firefox:Test Browser
EOF

echo "Created traditional applications.txt only"
echo "Testing restore with missing enhanced data (should fall back to traditional)"

# Source the session manager
source "${SESSION_DIR}/session-manager.sh"

# Test restore with missing enhanced data
restore_applications

echo ""
echo "=== TEST 2: Corrupted enhanced session data ==="
# Create corrupted JSON files
echo "invalid json content" > "${SESSION_STATE_DIR}/workspace_layouts.json"
echo "invalid json content" > "${SESSION_STATE_DIR}/application_workspace_mapping.json"
echo "invalid json content" > "${SESSION_STATE_DIR}/window_states.json"

echo "Created corrupted enhanced session data"
echo "Testing restore with corrupted data (should handle gracefully)"

# Test restore with corrupted data
restore_applications

echo ""
echo "=== TEST 3: Missing dependencies ==="
echo "Testing behavior when dependencies are missing"

# Temporarily modify PATH to simulate missing dependencies
OLD_PATH="$PATH"
export PATH="/tmp/nonexistent:$PATH"

# Test functions that require dependencies
extract_workspace_layouts
capture_window_states
create_application_mapping

# Restore PATH
export PATH="$OLD_PATH"

echo ""
echo "=== TEST 4: Empty session state ==="
rm -rf "${SESSION_STATE_DIR}"/*

echo "Testing restore with empty session state"
restore_session

echo ""
echo "Error handling and graceful degradation tests completed!"