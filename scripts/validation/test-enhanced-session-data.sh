#!/usr/bin/env zsh

# Test script to create enhanced session data and test restoration

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Create session state directory
mkdir -p "$SESSION_STATE_DIR"

echo "Creating enhanced session test data..."

# Create enhanced workspace layouts
cat > "${SESSION_STATE_DIR}/workspace_layouts.json" << 'EOF'
[
  {
    "id": 10,
    "name": "test-workspace-10",
    "monitor": "HDMI-A-1",
    "monitorID": 0,
    "windows": 0,
    "hasfullscreen": false
  },
  {
    "id": 20,
    "name": "test-workspace-20",
    "monitor": "HDMI-A-1",
    "monitorID": 0,
    "windows": 0,
    "hasfullscreen": false
  }
]
EOF

# Create enhanced application workspace mapping
cat > "${SESSION_STATE_DIR}/application_workspace_mapping.json" << 'EOF'
[
  {
    "class": "kitty",
    "workspace": 10,
    "title": "Test Terminal",
    "command": "kitty"
  },
  {
    "class": "firefox",
    "workspace": 20,
    "title": "Test Browser",
    "command": "firefox"
  }
]
EOF

# Create enhanced window states
cat > "${SESSION_STATE_DIR}/window_states.json" << 'EOF'
[
  {
    "address": "0x123456789abc",
    "class": "kitty",
    "title": "Test Terminal",
    "workspace": {
      "id": 10,
      "name": "test-workspace-10"
    },
    "at": [100, 100],
    "size": [800, 600],
    "floating": false,
    "fullscreen": 0,
    "pinned": false
  },
  {
    "address": "0xabcdef123456",
    "class": "firefox",
    "title": "Test Browser",
    "workspace": {
      "id": 20,
      "name": "test-workspace-20"
    },
    "at": [200, 200],
    "size": [1024, 768],
    "floating": false,
    "fullscreen": 0,
    "pinned": false
  }
]
EOF

# Create active workspace file
cat > "${SESSION_STATE_DIR}/active_workspace.json" << 'EOF'
{
  "id": 10,
  "name": "test-workspace-10"
}
EOF

echo "Enhanced session test data created successfully!"
echo "Files created:"
echo "- workspace_layouts.json"
echo "- application_workspace_mapping.json" 
echo "- window_states.json"
echo "- active_workspace.json"

echo ""
echo "Testing enhanced restore functionality..."
echo "This should use the enhanced workspace-aware restoration"

# Source the session manager
source "${SESSION_DIR}/session-manager.sh"

# Test enhanced restore
restore_session

echo ""
echo "Enhanced session restoration test completed!"