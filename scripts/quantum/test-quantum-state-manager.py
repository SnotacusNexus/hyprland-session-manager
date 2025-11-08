#!/usr/bin/env python3
"""
🚀 Comprehensive Test Suite for Quantum State Manager

This test suite provides comprehensive testing for all aspects of the
Quantum State Manager, including unit tests, integration tests, performance
tests, validation tests, and compatibility tests.

Test Categories:
1. Core Quantum State Tests
2. Application Context Tests  
3. Monitor & Workspace Tests
4. Integration Tests
5. Performance Tests
6. Compatibility Tests

Key Features:
- Mock Hyprland environment for testing without real Hyprland
- Test data generation for realistic desktop state scenarios
- Performance benchmarking for optimization validation
- Error injection testing for robustness validation
- Integration testing with session manager commands
"""

import os
import sys
import json
import time
import unittest
import tempfile
import shutil
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock
from typing import Dict, List, Any, Optional
import hashlib
from datetime import datetime

# Add the current directory to Python path to import local modules
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the quantum state manager using importlib to handle hyphenated filename
import sys
import os
import importlib.util

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Load the quantum state manager module
spec = importlib.util.spec_from_file_location("quantum_state_manager", "quantum-state-manager.py")
quantum_state_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(quantum_state_module)

# Import the classes
QuantumStateManager = quantum_state_module.QuantumStateManager
QuantumState = quantum_state_module.QuantumState
# Import quantum state config using importlib
spec_config = importlib.util.spec_from_file_location("quantum_state_config", "quantum-state-config.py")
quantum_config_module = importlib.util.module_from_spec(spec_config)
spec_config.loader.exec_module(quantum_config_module)

# Import the classes
QuantumConfiguration = quantum_config_module.QuantumConfiguration
load_quantum_config = quantum_config_module.load_quantum_config
QuantumConfigManager = quantum_config_module.QuantumConfigManager

# Configure test logging
import logging
logging.basicConfig(level=logging.WARNING)  # Reduce noise during tests


class MockHyprlandEnvironment:
    """
    Mock Hyprland environment for testing without requiring real Hyprland
    
    Provides realistic mock data for all Hyprland commands and states
    that the Quantum State Manager interacts with.
    """
    
    def __init__(self):
        self.monitors = self._create_mock_monitors()
        self.workspaces = self._create_mock_workspaces()
        self.clients = self._create_mock_clients()
        self.active_window = self._create_mock_active_window()
        
    def _create_mock_monitors(self) -> List[Dict[str, Any]]:
        """Create realistic mock monitor data"""
        return [
            {
                "id": 1,
                "name": "eDP-1",
                "description": "Built-in Display",
                "width": 1920,
                "height": 1080,
                "refreshRate": 60.0,
                "x": 0,
                "y": 0,
                "activeWorkspace": {"id": 1, "name": "1"},
                "reserved": [0, 0, 0, 0],
                "scale": 1.0,
                "transform": 0,
                "focused": True,
                "dpmsStatus": True
            },
            {
                "id": 2,
                "name": "HDMI-A-1",
                "description": "External Display",
                "width": 2560,
                "height": 1440,
                "refreshRate": 144.0,
                "x": 1920,
                "y": 0,
                "activeWorkspace": {"id": 2, "name": "2"},
                "reserved": [0, 0, 0, 0],
                "scale": 1.0,
                "transform": 0,
                "focused": False,
                "dpmsStatus": True
            }
        ]
    
    def _create_mock_workspaces(self) -> List[Dict[str, Any]]:
        """Create realistic mock workspace data"""
        return [
            {
                "id": 1,
                "name": "1",
                "monitor": "eDP-1",
                "monitorID": 1,
                "windows": 3,
                "hasfullscreen": False,
                "lastwindow": "0x12345678",
                "lastwindowtitle": "Terminal",
                "persistent": False
            },
            {
                "id": 2,
                "name": "2",
                "monitor": "HDMI-A-1",
                "monitorID": 2,
                "windows": 2,
                "hasfullscreen": True,
                "lastwindow": "0x87654321",
                "lastwindowtitle": "Firefox",
                "persistent": False
            },
            {
                "id": 3,
                "name": "3",
                "monitor": "eDP-1",
                "monitorID": 1,
                "windows": 1,
                "hasfullscreen": False,
                "lastwindow": "0xabcdef12",
                "lastwindowtitle": "VSCode",
                "persistent": True
            }
        ]
    
    def _create_mock_clients(self) -> List[Dict[str, Any]]:
        """Create realistic mock client (window) data"""
        return [
            {
                "address": "0x12345678",
                "class": "kitty",
                "title": "Terminal - /home/user",
                "initialClass": "kitty",
                "initialTitle": "kitty",
                "pid": 1234,
                "xwayland": False,
                "pinned": False,
                "fullscreen": False,
                "fullscreenMode": 0,
                "fakeFullscreen": False,
                "floating": False,
                "monitor": 1,
                "workspace": {"id": 1, "name": "1"},
                "at": [100, 100],
                "size": [800, 600],
                "focusHistoryID": 1
            },
            {
                "address": "0x87654321",
                "class": "firefox",
                "title": "Mozilla Firefox",
                "initialClass": "firefox",
                "initialTitle": "firefox",
                "pid": 2345,
                "xwayland": False,
                "pinned": False,
                "fullscreen": True,
                "fullscreenMode": 1,
                "fakeFullscreen": False,
                "floating": False,
                "monitor": 2,
                "workspace": {"id": 2, "name": "2"},
                "at": [0, 0],
                "size": [2560, 1440],
                "focusHistoryID": 2
            },
            {
                "address": "0xabcdef12",
                "class": "code",
                "title": "VSCode - test-quantum-state-manager.py",
                "initialClass": "code",
                "initialTitle": "code",
                "pid": 3456,
                "xwayland": False,
                "pinned": False,
                "fullscreen": False,
                "fullscreenMode": 0,
                "fakeFullscreen": False,
                "floating": False,
                "monitor": 1,
                "workspace": {"id": 3, "name": "3"},
                "at": [200, 200],
                "size": [1200, 800],
                "focusHistoryID": 3
            },
            {
                "address": "0xfedcba98",
                "class": "krita",
                "title": "Krita - Untitled",
                "initialClass": "krita",
                "initialTitle": "krita",
                "pid": 4567,
                "xwayland": False,
                "pinned": False,
                "fullscreen": False,
                "fullscreenMode": 0,
                "fakeFullscreen": False,
                "floating": True,
                "monitor": 1,
                "workspace": {"id": 1, "name": "1"},
                "at": [50, 50],
                "size": [1000, 700],
                "focusHistoryID": 4
            }
        ]
    
    def _create_mock_active_window(self) -> Dict[str, Any]:
        """Create mock active window data"""
        return {
            "address": "0x12345678",
            "class": "kitty",
            "title": "Terminal - /home/user",
            "workspace": {"id": 1, "name": "1"},
            "at": [100, 100],
            "size": [800, 600]
        }
    
    def run_hyprctl_command(self, command: str) -> Optional[Dict[str, Any]]:
        """Mock hyprctl command execution"""
        if command == "monitors":
            return self.monitors
        elif command == "workspaces":
            return self.workspaces
        elif command == "clients":
            return self.clients
        elif command == "activewindow":
            return self.active_window
        else:
            return None


class TestDataGenerator:
    """
    Test data generator for creating realistic desktop state scenarios
    
    Generates comprehensive test data for all quantum state components
    including complex multi-monitor setups, application sessions, and
    development environments.
    """
    
    @staticmethod
    def generate_complex_monitor_layouts() -> List[Dict[str, Any]]:
        """Generate complex multi-monitor layout data"""
        return [
            {
                "id": 1,
                "name": "eDP-1",
                "description": "Built-in Display",
                "width": 3840,
                "height": 2160,
                "refreshRate": 120.0,
                "x": 0,
                "y": 0,
                "activeWorkspace": {"id": 1, "name": "1"},
                "reserved": [0, 0, 0, 0],
                "scale": 2.0,
                "transform": 0,
                "focused": True,
                "dpmsStatus": True
            },
            {
                "id": 2,
                "name": "DP-1",
                "description": "External Display 1",
                "width": 5120,
                "height": 2880,
                "refreshRate": 60.0,
                "x": 3840,
                "y": 0,
                "activeWorkspace": {"id": 2, "name": "2"},
                "reserved": [0, 0, 0, 0],
                "scale": 1.5,
                "transform": 0,
                "focused": False,
                "dpmsStatus": True
            },
            {
                "id": 3,
                "name": "HDMI-1",
                "description": "External Display 2",
                "width": 2560,
                "height": 1440,
                "refreshRate": 144.0,
                "x": 8960,
                "y": 0,
                "activeWorkspace": {"id": 3, "name": "3"},
                "reserved": [0, 0, 0, 0],
                "scale": 1.0,
                "transform": 0,
                "focused": False,
                "dpmsStatus": True
            }
        ]
    
    @staticmethod
    def generate_large_workspace_states() -> List[Dict[str, Any]]:
        """Generate large workspace state data for performance testing"""
        workspaces = []
        for i in range(1, 21):  # 20 workspaces
            workspace = {
                "id": i,
                "name": str(i),
                "monitor": f"Monitor-{(i % 3) + 1}",
                "monitorID": (i % 3) + 1,
                "windows": (i % 5) + 1,
                "hasfullscreen": i % 7 == 0,
                "lastwindow": f"0x{i:08x}",
                "lastwindowtitle": f"Window {i}",
                "persistent": i % 3 == 0
            }
            workspaces.append(workspace)
        return workspaces
    
    @staticmethod
    def generate_complex_application_contexts() -> List[Dict[str, Any]]:
        """Generate complex application context data"""
        return [
            {
                "class": "firefox",
                "pid": 1001,
                "title": "Mozilla Firefox - Multiple Tabs",
                "workspace": 1,
                "window_address": "0x12345678",
                "session_data": {
                    "type": "browser",
                    "browser": "firefox",
                    "tabs": ["GitHub", "Documentation", "Stack Overflow"],
                    "windows": ["Main Window"],
                    "session_file": "/home/user/.mozilla/firefox/profile/sessionstore.jsonlz4"
                },
                "environment": {
                    "development_environments": [{"type": "node", "environment": "development"}],
                    "current_directory": "/home/user/projects",
                    "environment_variables": {"NODE_ENV": "development"}
                },
                "state_checksum": "abc123def456"
            },
            {
                "class": "kitty",
                "pid": 1002,
                "title": "Terminal - Development",
                "workspace": 1,
                "window_address": "0x23456789",
                "session_data": {
                    "type": "terminal",
                    "terminal": "kitty",
                    "current_directory": "/home/user/projects/quantum-state-manager",
                    "environment": {"TERM": "xterm-256color", "SHELL": "/bin/bash"},
                    "shell_session": "bash"
                },
                "environment": {
                    "development_environments": [
                        {"type": "conda", "name": "base", "active": True},
                        {"type": "venv", "name": "quantum-env", "path": "/home/user/venvs/quantum", "active": True}
                    ],
                    "current_directory": "/home/user/projects/quantum-state-manager",
                    "environment_variables": {
                        "VIRTUAL_ENV": "/home/user/venvs/quantum",
                        "PYTHONPATH": "/home/user/projects/quantum-state-manager"
                    }
                },
                "state_checksum": "def456abc123"
            },
            {
                "class": "code",
                "pid": 1003,
                "title": "VSCode - Quantum State Manager Project",
                "workspace": 2,
                "window_address": "0x3456789a",
                "session_data": {
                    "type": "ide",
                    "ide": "code",
                    "workspace": "/home/user/projects/quantum-state-manager.code-workspace",
                    "open_files": ["quantum-state-manager.py", "test-quantum-state-manager.py"],
                    "projects": ["quantum-state-manager"]
                },
                "environment": {
                    "development_environments": [{"type": "node", "environment": "development"}],
                    "current_directory": "/home/user/projects/quantum-state-manager",
                    "environment_variables": {"NODE_ENV": "development"}
                },
                "state_checksum": "ghi789jkl012"
            }
        ]
    
    @staticmethod
    def generate_corrupted_state_data() -> Dict[str, Any]:
        """Generate corrupted state data for error recovery testing"""
        return {
            "timestamp": "invalid-timestamp",
            "session_id": "corrupted_session",
            "monitor_layouts": [{"invalid": "data"}],
            "workspace_states": "not_a_list",
            "window_states": None,
            "application_contexts": [],
            "terminal_sessions": [],
            "browser_sessions": [],
            "development_environments": [],
            "system_state": {},
            "validation_checksums": {"overall": "invalid_checksum"}
        }


class TestQuantumStateManager(unittest.TestCase):
    """
    Main test suite for Quantum State Manager
    
    Comprehensive testing covering all aspects of quantum state management
    including core functionality, application contexts, performance, and
    compatibility.
    """
    
    def setUp(self):
        """Set up test environment before each test"""
        # Create temporary directory for test data
        self.test_dir = tempfile.mkdtemp(prefix="quantum_test_")
        self.session_dir = os.path.join(self.test_dir, "session-manager")
        
        # Initialize mock Hyprland environment
        self.mock_hyprland = MockHyprlandEnvironment()
        
        # Patch hyprctl command to use mock environment
        self.hyprctl_patcher = patch.object(
            QuantumStateManager, 
            '_run_hyprctl_command',
            side_effect=self.mock_hyprland.run_hyprctl_command
        )
        self.mock_hyprctl = self.hyprctl_patcher.start()
        
        # Initialize quantum state manager
        self.manager = QuantumStateManager(session_dir=self.session_dir)
        
        # Test data generator
        self.data_gen = TestDataGenerator()
    
    def tearDown(self):
        """Clean up test environment after each test"""
        self.hyprctl_patcher.stop()
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)
    
    # =========================================================================
    # Core Quantum State Tests
    # =========================================================================
    
    def test_quantum_state_initialization(self):
        """Test quantum state manager initialization"""
        self.assertIsNotNone(self.manager)
        self.assertEqual(self.manager.session_dir, self.session_dir)
        self.assertTrue(os.path.exists(self.manager.state_dir))
        self.assertTrue(os.path.exists(self.manager.backup_dir))
    
    def test_quantum_state_dataclass(self):
        """Test QuantumState dataclass creation and serialization"""
        state = QuantumState(
            timestamp="2024-01-01T00:00:00",
            session_id="test_session",
            monitor_layouts=[{"id": 1, "name": "Test Monitor"}],
            workspace_states=[{"id": 1, "name": "Test Workspace"}],
            window_states=[{"address": "0x123", "class": "test"}],
            application_contexts=[{"class": "test", "pid": 123}],
            terminal_sessions=[{"class": "kitty", "pid": 123}],
            browser_sessions=[{"class": "firefox", "pid": 123}],
            development_environments=[{"type": "conda", "name": "test"}],
            system_state={"timestamp": "2024-01-01T00:00:00"},
            validation_checksums={"overall": "test_checksum"}
        )
        
        # Test dataclass attributes
        self.assertEqual(state.session_id, "test_session")
        self.assertEqual(len(state.monitor_layouts), 1)
        self.assertEqual(len(state.workspace_states), 1)
        self.assertEqual(len(state.window_states), 1)
        self.assertEqual(len(state.application_contexts), 1)
        
        # Test serialization to dict
        state_dict = state.__dict__
        self.assertIn("session_id", state_dict)
        self.assertIn("monitor_layouts", state_dict)
        self.assertIn("validation_checksums", state_dict)
    
    def test_monitor_layout_capture(self):
        """Test monitor layout capture functionality"""
        layouts = self.manager.capture_monitor_layouts()
        
        self.assertIsInstance(layouts, list)
        self.assertEqual(len(layouts), 2)  # From mock data
        
        # Verify monitor data structure
        monitor = layouts[0]
        self.assertIn("id", monitor)
        self.assertIn("name", monitor)
        self.assertIn("width", monitor)
        self.assertIn("height", monitor)
        self.assertIn("refreshRate", monitor)
    
    def test_workspace_state_capture(self):
        """Test workspace state capture functionality"""
        workspaces = self.manager.capture_workspace_states()
        
        self.assertIsInstance(workspaces, list)
        self.assertEqual(len(workspaces), 3)  # From mock data
        
        # Verify workspace data structure
        workspace = workspaces[0]
        self.assertIn("id", workspace)
        self.assertIn("name", workspace)
        self.assertIn("monitor", workspace)
        self.assertIn("windows", workspace)
        self.assertIn("clients", workspace)
    
    def test_window_state_capture(self):
        """Test window state capture functionality"""
        windows = self.manager.capture_window_states()
        
        self.assertIsInstance(windows, list)
        self.assertEqual(len(windows), 4)  # From mock data
        
        # Verify window data structure
        window = windows[0]
        self.assertIn("address", window)
        self.assertIn("class", window)
        self.assertIn("title", window)
        self.assertIn("workspace", window)
        self.assertIn("active", window)
    
    def test_application_context_capture(self):
        """Test application context capture functionality"""
        contexts = self.manager.capture_application_contexts()
        
        self.assertIsInstance(contexts, list)
        self.assertEqual(len(contexts), 4)  # From mock data
        
        # Verify context data structure
        context = contexts[0]
        self.assertIn("class", context)
        self.assertIn("pid", context)
        self.assertIn("session_data", context)
        self.assertIn("environment", context)
        self.assertIn("state_checksum", context)
    
    def test_terminal_session_capture(self):
        """Test terminal session capture functionality"""
        sessions = self.manager.capture_terminal_sessions()
        
        self.assertIsInstance(sessions, list)
        # Should capture kitty terminal from mock data
        terminal_classes = [s["class"] for s in sessions]
        self.assertIn("kitty", terminal_classes)
        
        # Verify session data structure
        if sessions:
            session = sessions[0]
            self.assertIn("class", session)
            self.assertIn("environment", session)
            self.assertIn("session_data", session)
    
    def test_browser_session_capture(self):
        """Test browser session capture functionality"""
        sessions = self.manager.capture_browser_sessions()
        
        self.assertIsInstance(sessions, list)
        # Should capture firefox browser from mock data
        browser_classes = [s["class"] for s in sessions]
        self.assertIn("firefox", browser_classes)
        
        # Verify session data structure
        if sessions:
            session = sessions[0]
            self.assertIn("class", session)
            self.assertIn("session_data", session)
    
    def test_development_environment_capture(self):
        """Test development environment capture functionality"""
        environments = self.manager.capture_development_environments()
        
        self.assertIsInstance(environments, list)
        # Should capture development environments from processes
        
        # Verify environment data structure
        if environments:
            env = environments[0]
            self.assertIn("pid", env)
            self.assertIn("environments", env)
    
    def test_system_state_capture(self):
        """Test system state capture functionality"""
        system_state = self.manager.capture_system_state()
        
        self.assertIsInstance(system_state, dict)
        self.assertIn("timestamp", system_state)
        self.assertIn("cpu_usage", system_state)
        self.assertIn("memory_usage", system_state)
        self.assertIn("disk_usage", system_state)
        self.assertIn("running_processes", system_state)
    
    def test_complete_quantum_state_capture(self):
        """Test complete quantum state capture"""
        quantum_state = self.manager.capture_quantum_state()
        
        self.assertIsInstance(quantum_state, QuantumState)
        self.assertIsNotNone(quantum_state.session_id)
        self.assertIsNotNone(quantum_state.timestamp)
        
        # Verify all components are captured
        self.assertGreater(len(quantum_state.monitor_layouts), 0)
        self.assertGreater(len(quantum_state.workspace_states), 0)
        self.assertGreater(len(quantum_state.window_states), 0)
        self.assertGreater(len(quantum_state.application_contexts), 0)
        self.assertGreater(len(quantum_state.terminal_sessions), 0)
        self.assertGreater(len(quantum_state.browser_sessions), 0)
        self.assertIsInstance(quantum_state.system_state, dict)
        self.assertIsInstance(quantum_state.validation_checksums, dict)
    
    # =========================================================================
    # State Save/Load Tests
    # =========================================================================
    
    def test_state_save_and_load(self):
        """Test quantum state save and load operations"""
        # Capture state
        original_state = self.manager.capture_quantum_state()
        
        # Save state
        saved_path = self.manager.save_quantum_state(original_state)
        self.assertTrue(os.path.exists(saved_path))
        
        # Load state
        loaded_state = self.manager.load_quantum_state(os.path.basename(saved_path))
        
        # Verify loaded state matches original
        self.assertEqual(original_state.session_id, loaded_state.session_id)
        self.assertEqual(len(original_state.monitor_layouts), len(loaded_state.monitor_layouts))
        self.assertEqual(len(original_state.workspace_states), len(loaded_state.workspace_states))
        self.assertEqual(len(original_state.window_states), len(loaded_state.window_states))
    
    def test_state_save_with_custom_filename(self):
        """Test state save with custom filename"""
        state = self.manager.capture_quantum_state()
        custom_filename = "custom_test_state.json"
        
        saved_path = self.manager.save_quantum_state(state, custom_filename)
        expected_path = os.path.join(self.manager.state_dir, custom_filename)
        
        self.assertEqual(saved_path, expected_path)
        self.assertTrue(os.path.exists(expected_path))
    
    def test_state_load_nonexistent_file(self):
        """Test loading non-existent state file"""
        with self.assertRaises(Exception):
            self.manager.load_quantum_state("nonexistent_state.json")
    
    def test_state_load_corrupted_file(self):
        """Test loading corrupted state file"""
        # Create corrupted state file
        corrupted_path = os.path.join(self.manager.state_dir, "corrupted_state.json")
        with open(corrupted_path, 'w') as f:
            f.write("invalid json content")
        
        with self.assertRaises(Exception):
            self.manager.load_quantum_state("corrupted_state.json")
    
    # =========================================================================
    # Validation and Checksum Tests
    # =========================================================================
    
    def test_checksum_generation(self):
        """Test checksum generation for state validation"""
        state = self.manager.capture_quantum_state()
        checksums = self.manager.generate_validation_checksums(state)
        
        self.assertIsInstance(checksums, dict)
        self.assertIn("overall", checksums)
        self.assertIn("monitor_layouts", checksums)
        self.assertIn("workspace_states", checksums)
        self.assertIn("window_states", checksums)
        self.assertIn("application_contexts", checksums)
        self.assertIn("terminal_sessions", checksums)
        self.assertIn("browser_sessions", checksums)
        self.assertIn("development_environments", checksums)
        self.assertIn("system_state", checksums)
        
        # Verify checksums are valid MD5 hashes
        for component, checksum in checksums.items():
            self.assertEqual(len(checksum), 32)  # MD5 hash length
            self.assertTrue(all(c in '0123456789abcdef' for c in checksum))
    
    def test_state_validation_success(self):
        """Test successful state validation"""
        state = self.manager.capture_quantum_state()
        
        # Save and load to ensure checksums are set
        saved_path = self.manager.save_quantum_state(state)
        loaded_state = self.manager.load_quantum_state(os.path.basename(saved_path))
        
        # Validate checksums
        is_valid = self.manager._validate_state_checksums(loaded_state)
        self.assertTrue(is_valid)
    
    def test_state_validation_failure(self):
        """Test state validation failure with tampered data"""
        state = self.manager.capture_quantum_state()
        
        # Tamper with the state data
        state.monitor_layouts[0]["name"] = "Tampered Monitor"
        
        # Validation should fail
        is_valid = self.manager._validate_state_checksums(state)
        self.assertFalse(is_valid)
    
    # =========================================================================
    # Application Context Tests
    # =========================================================================
    
    def test_browser_session_capture_methods(self):
        """Test browser-specific session capture methods"""
        # Test Firefox session capture
        firefox_data = self.manager._capture_browser_session("firefox", 1234)
        self.assertIsInstance(firefox_data, dict)
        self.assertEqual(firefox_data["type"], "browser")
        self.assertEqual(firefox_data["browser"], "firefox")
        
        # Test Chrome session capture
        chrome_data = self.manager._capture_browser_session("chrome", 1235)
        self.assertIsInstance(chrome_data, dict)
        self.assertEqual(chrome_data["type"], "browser")
        self.assertEqual(chrome_data["browser"], "chrome")
    
    def test_terminal_session_capture_methods(self):
        """Test terminal-specific session capture methods"""
        # Test Kitty session capture
        kitty_data = self.manager._capture_terminal_session("kitty", 1234)
        self.assertIsInstance(kitty_data, dict)
        self.assertEqual(kitty_data["type"], "terminal")
        self.assertEqual(kitty_data["terminal"], "kitty")
        
        # Test Alacritty session capture
        alacritty_data = self.manager._capture_terminal_session("alacritty", 1235)
        self.assertIsInstance(alacritty_data, dict)
        self.assertEqual(alacritty_data["type"], "terminal")
        self.assertEqual(alacritty_data["terminal"], "alacritty")
    
    def test_ide_session_capture_methods(self):
        """Test IDE-specific session capture methods"""
        # Test VSCode session capture
        vscode_data = self.manager._capture_ide_session("code", 1234)
        self.assertIsInstance(vscode_data, dict)
        self.assertEqual(vscode_data["type"], "ide")
        self.assertEqual(vscode_data["ide"], "code")
        
        # Test Void session capture
        void_data = self.manager._capture_ide_session("void", 1235)
        self.assertIsInstance(void_data, dict)
        self.assertEqual(void_data["type"], "ide")
        self.assertEqual(void_data["ide"], "void")
    
    def test_creative_session_capture_methods(self):
        """Test creative application session capture methods"""
        # Test Krita session capture
        krita_data = self.manager._capture_creative_session("krita", 1234)
        self.assertIsInstance(krita_data, dict)
        self.assertEqual(krita_data["type"], "creative")
        self.assertEqual(krita_data["application"], "krita")
        
        # Test GIMP session capture
        gimp_data = self.manager._capture_creative_session("gimp", 1235)
        self.assertIsInstance(gimp_data, dict)
        self.assertEqual(gimp_data["type"], "creative")
        self.assertEqual(gimp_data["application"], "gimp")
    
    def test_development_environment_detection(self):
        """Test development environment detection"""
        # Test with conda environment
        conda_env_vars = {"CONDA_DEFAULT_ENV": "base"}
        conda_envs = self.manager._detect_development_environments(conda_env_vars)
        self.assertEqual(len(conda_envs), 1)
        self.assertEqual(conda_envs[0]["type"], "conda")
        self.assertEqual(conda_envs[0]["name"], "base")
        
        # Test with virtual environment
        venv_env_vars = {"VIRTUAL_ENV": "/home/user/venvs/test"}
        venv_envs = self.manager._detect_development_environments(venv_env_vars)
        self.assertEqual(len(venv_envs), 1)
        self.assertEqual(venv_envs[0]["type"], "venv")
        self.assertEqual(venv_envs[0]["name"], "test")
        
        # Test with multiple environments
        multi_env_vars = {
            "CONDA_DEFAULT_ENV": "base",
            "VIRTUAL_ENV": "/home/user/venvs/test",
            "NODE_ENV": "development"
        }
        multi_envs = self.manager._detect_development_environments(multi_env_vars)
        self.assertEqual(len(multi_envs), 3)
    
    # =========================================================================
    # Performance Tests
    # =========================================================================
    
    def test_large_state_capture_performance(self):
        """Test performance of large state capture"""
        # Generate large workspace data
        large_workspaces = self.data_gen.generate_large_workspace_states()
        
        # Patch workspace capture to return large data
        with patch.object(self.manager, 'capture_workspace_states', return_value=large_workspaces):
            start_time = time.time()
            state = self.manager.capture_quantum_state()
            end_time = time.time()
            
            capture_time = end_time - start_time
            
            # Verify state was captured successfully
            self.assertIsInstance(state, QuantumState)
            self.assertEqual(len(state.workspace_states), 20)
            
            # Performance assertion (adjust threshold as needed)
            self.assertLess(capture_time, 5.0, "Large state capture took too long")
    
    def test_state_optimization_performance(self):
        """Test performance impact of state optimization"""
        state = self.manager.capture_quantum_state()
        
        # Test optimization with performance measurement
        start_time = time.time()
        optimized_state = self.manager.optimize_state_capture(state)
        optimization_time = time.time() - start_time
        
        self.assertIsInstance(optimized_state, QuantumState)
        self.assertLess(optimization_time, 1.0, "State optimization took too long")
    
    def test_state_compression_efficiency(self):
        """Test state compression efficiency"""
        state = self.manager.capture_quantum_state()
        
        # Save uncompressed state
        uncompressed_path = self.manager.save_quantum_state(state, "uncompressed_test.json")
        uncompressed_size = os.path.getsize(uncompressed_path)
        
        # Test with optimization enabled
        with patch.dict(self.manager.config, {'performance_optimization': True}):
            optimized_state = self.manager.optimize_state_capture(state)
            optimized_path = self.manager.save_quantum_state(optimized_state, "optimized_test.json")
            optimized_size = os.path.getsize(optimized_path)
        
        # Optimized state should be smaller or equal in size
        self.assertLessEqual(optimized_size, uncompressed_size)
    
    # =========================================================================
    # Integration Tests
    # =========================================================================
    
    def test_event_monitoring_integration(self):
        """Test event monitoring integration"""
        # Mock event callback
        mock_callback = Mock()
        mock_callback.on_workspace_focus = Mock()
        mock_callback.on_active_window_change = Mock()
        mock_callback.on_client_changes = Mock()
        
        # Add callback
        self.manager.add_event_callback(mock_callback)
        self.assertIn(mock_callback, self.manager.event_callbacks)
        
        # Remove callback
        self.manager.remove_event_callback(mock_callback)
        self.assertNotIn(mock_callback, self.manager.event_callbacks)
    
    def test_auto_save_integration(self):
        """Test auto-save functionality integration"""
        # Mock the capture and save methods
        with patch.object(self.manager, 'capture_quantum_state') as mock_capture, \
             patch.object(self.manager, 'save_quantum_state') as mock_save:
            
            mock_capture.return_value = self.manager.capture_quantum_state()
            mock_save.return_value = "/test/path/auto_save.json"
            
            # Start auto-save with short interval for testing
            self.manager.start_auto_save(interval=1)
            
            # Wait briefly for auto-save to trigger
            time.sleep(1.5)
            
            # Stop auto-save
            self.manager.stop_event_monitoring()
            
            # Verify auto-save was called
            mock_capture.assert_called()
            mock_save.assert_called()
    
    def test_configuration_integration(self):
        """Test configuration system integration"""
        # Test configuration loading
        config = self.manager._load_config()
        self.assertIsInstance(config, dict)
        self.assertIn("auto_save_interval", config)
        self.assertIn("application_contexts", config)
        self.assertIn("performance_optimization", config)
    
    # =========================================================================
    #
    # =========================================================================
    # Compatibility Tests
    # =========================================================================
    
    def test_backward_compatibility(self):
        """Test backward compatibility with legacy session formats"""
        # Create mock legacy session data
        legacy_data = {
            "monitors": [{"id": 1, "name": "Legacy Monitor"}],
            "workspaces": [{"id": 1, "name": "Legacy Workspace"}],
            "windows": [{"address": "0x123", "class": "legacy"}],
            "applications": [{"class": "legacy", "pid": 123}],
            "terminals": [{"class": "legacy-terminal", "pid": 123}],
            "browsers": [{"class": "legacy-browser", "pid": 123}],
            "environments": [{"type": "legacy", "name": "legacy-env"}],
            "system": {"timestamp": "2024-01-01T00:00:00"}
        }
        
        # Save legacy data to file
        legacy_file = os.path.join(self.test_dir, "legacy_session.json")
        with open(legacy_file, 'w') as f:
            json.dump(legacy_data, f)
        
        # Test migration
        quantum_state = self.manager.migrate_legacy_state(legacy_file)
        
        # Verify migration
        self.assertIsInstance(quantum_state, QuantumState)
        self.assertEqual(len(quantum_state.monitor_layouts), 1)
        self.assertEqual(len(quantum_state.workspace_states), 1)
        self.assertEqual(len(quantum_state.window_states), 1)
        self.assertEqual(len(quantum_state.application_contexts), 1)
        self.assertEqual(len(quantum_state.terminal_sessions), 1)
        self.assertEqual(len(quantum_state.browser_sessions), 1)
        self.assertEqual(len(quantum_state.development_environments), 1)
    
    def test_state_compatibility_validation(self):
        """Test state compatibility validation"""
        state = self.manager.capture_quantum_state()
        
        # Test compatibility validation
        is_compatible = self.manager.validate_state_compatibility(state)
        
        # Should be compatible with current system
        self.assertTrue(is_compatible)
    
    def test_compatible_states_listing(self):
        """Test listing of compatible quantum states"""
        # Create multiple state files
        for i in range(3):
            state = self.manager.capture_quantum_state()
            self.manager.save_quantum_state(state, f"test_state_{i}.json")
        
        # Get compatible states
        compatible_states = self.manager.get_compatible_states()
        
        self.assertIsInstance(compatible_states, list)
        self.assertGreaterEqual(len(compatible_states), 3)
        
        # Verify all listed states are compatible
        for state_file in compatible_states:
            self.assertTrue(state_file.startswith("quantum_state_") or state_file.startswith("test_state_"))
            self.assertTrue(state_file.endswith(".json"))
    
    # =========================================================================
    # Error Handling and Recovery Tests
    # =========================================================================
    
    def test_error_handling_corrupted_state(self):
        """Test error handling with corrupted state data"""
        # Create corrupted state file
        corrupted_path = os.path.join(self.manager.state_dir, "corrupted_state.json")
        with open(corrupted_path, 'w') as f:
            f.write("{invalid json")
        
        # Should raise exception when loading corrupted state
        with self.assertRaises(Exception):
            self.manager.load_quantum_state("corrupted_state.json")
    
    def test_error_handling_missing_directories(self):
        """Test error handling with missing directories"""
        # Remove state directory
        shutil.rmtree(self.manager.state_dir)
        
        # Should recreate directories when needed
        state = self.manager.capture_quantum_state()
        saved_path = self.manager.save_quantum_state(state)
        
        self.assertTrue(os.path.exists(saved_path))
        self.assertTrue(os.path.exists(self.manager.state_dir))
        self.assertTrue(os.path.exists(self.manager.backup_dir))
    
    def test_error_handling_hyprctl_failure(self):
        """Test error handling when hyprctl commands fail"""
        # Patch hyprctl to return None (simulating failure)
        with patch.object(self.manager, '_run_hyprctl_command', return_value=None):
            # Should handle hyprctl failures gracefully
            monitors = self.manager.capture_monitor_layouts()
            workspaces = self.manager.capture_workspace_states()
            windows = self.manager.capture_window_states()
            
            # Should return empty lists on failure
            self.assertEqual(monitors, [])
            self.assertEqual(workspaces, [])
            self.assertEqual(windows, [])
    
    # =========================================================================
    # Backup and Recovery Tests
    # =========================================================================
    
    def test_backup_creation(self):
        """Test backup creation functionality"""
        state = self.manager.capture_quantum_state()
        saved_path = self.manager.save_quantum_state(state)
        
        # Check if backup was created
        backup_files = [f for f in os.listdir(self.manager.backup_dir) 
                       if f.startswith("backup_")]
        
        self.assertGreater(len(backup_files), 0)
    
    def test_backup_cleanup(self):
        """Test backup cleanup functionality"""
        # Create multiple backup files
        for i in range(15):  # More than max_backups (default 10)
            backup_file = os.path.join(self.manager.backup_dir, f"backup_test_{i}.json")
            with open(backup_file, 'w') as f:
                f.write("test backup content")
        
        # Trigger backup cleanup
        state = self.manager.capture_quantum_state()
        self.manager.save_quantum_state(state)
        
        # Check if old backups were cleaned up
        backup_files = [f for f in os.listdir(self.manager.backup_dir) 
                       if f.startswith("backup_")]
        
        # Should have max_backups or fewer files
        self.assertLessEqual(len(backup_files), self.manager.config.get("max_backups", 10))
    
    # =========================================================================
    # Performance Benchmarking Tests
    # =========================================================================
    
    def test_performance_benchmarking(self):
        """Test performance benchmarking for state operations"""
        # Benchmark state capture
        capture_times = []
        for _ in range(5):
            start_time = time.time()
            state = self.manager.capture_quantum_state()
            end_time = time.time()
            capture_times.append(end_time - start_time)
        
        # Calculate average capture time
        avg_capture_time = sum(capture_times) / len(capture_times)
        
        # Benchmark state save
        save_times = []
        for _ in range(5):
            state = self.manager.capture_quantum_state()
            start_time = time.time()
            self.manager.save_quantum_state(state, f"benchmark_{int(time.time())}.json")
            end_time = time.time()
            save_times.append(end_time - start_time)
        
        # Calculate average save time
        avg_save_time = sum(save_times) / len(save_times)
        
        # Performance assertions
        self.assertLess(avg_capture_time, 2.0, "State capture too slow")
        self.assertLess(avg_save_time, 1.0, "State save too slow")
    
    def test_memory_usage_optimization(self):
        """Test memory usage optimization"""
        import psutil
        import os
        
        # Get initial memory usage
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        # Perform multiple state operations
        for i in range(10):
            state = self.manager.capture_quantum_state()
            optimized_state = self.manager.optimize_state_capture(state)
            self.manager.save_quantum_state(optimized_state, f"memory_test_{i}.json")
        
        # Get final memory usage
        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory
        
        # Memory usage should be reasonable
        self.assertLess(memory_increase, 100, "Memory usage too high")


class TestQuantumConfiguration(unittest.TestCase):
    """
    Test suite for Quantum Configuration System
    
    Tests configuration loading, validation, and management
    """
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp(prefix="quantum_config_test_")
        self.config_manager = QuantumConfigManager(config_dir=self.test_dir)
    
    def tearDown(self):
        """Clean up test environment"""
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)
    
    def test_configuration_loading(self):
        """Test configuration loading from multiple sources"""
        config = self.config_manager.load_configuration()
        
        self.assertIsInstance(config, QuantumConfiguration)
        self.assertEqual(config.config_version, "1.0.0")
        self.assertEqual(config.config_schema, "quantum-state-v1")
    
    def test_configuration_validation(self):
        """Test configuration validation"""
        config = QuantumConfiguration()
        
        # Valid configuration should pass validation
        self.assertTrue(config.validate())
    
    def test_configuration_saving(self):
        """Test configuration saving"""
        config = QuantumConfiguration()
        
        # Save configuration
        success = self.config_manager.save_configuration(config)
        self.assertTrue(success)
        
        # Verify file was created
        config_file = os.path.join(self.test_dir, "quantum-state-config.json")
        self.assertTrue(os.path.exists(config_file))
    
    def test_configuration_merging(self):
        """Test configuration merging"""
        base_config = QuantumConfiguration()
        update_config = {"core": {"auto_save_interval": 600}}
        
        # Merge configurations
        merged_config = base_config.merge_with(update_config)
        
        self.assertEqual(merged_config.core.auto_save_interval, 600)
        # Other settings should remain unchanged
        self.assertEqual(merged_config.core.state_validation_enabled, True)


def run_comprehensive_test_suite():
    """
    Run comprehensive test suite and generate test report
    
    Returns:
        bool: True if all tests passed, False otherwise
    """
    print("🚀 Running Comprehensive Quantum State Manager Test Suite...")
    print("=" * 60)
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test classes
    suite.addTests(loader.loadTestsFromTestCase(TestQuantumStateManager))
    suite.addTests(loader.loadTestsFromTestCase(TestQuantumConfiguration))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Generate test report
    print("\n" + "=" * 60)
    print("📊 TEST SUITE SUMMARY")
    print("=" * 60)
    print(f"Tests Run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Success Rate: {(result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100:.1f}%")
    
    if result.wasSuccessful():
        print("✅ All tests passed! Quantum State Manager is ready for production.")
        return True
    else:
        print("❌ Some tests failed. Please review the test results.")
        return False


def main():
    """Main function to run the test suite"""
    # Parse command line arguments
    import argparse
    parser = argparse.ArgumentParser(description="Quantum State Manager Test Suite")
    parser.add_argument("--quick", action="store_true", help="Run quick test subset")
    parser.add_argument("--performance", action="store_true", help="Run performance tests only")
    parser.add_argument("--compatibility", action="store_true", help="Run compatibility tests only")
    
    args = parser.parse_args()
    
    if args.quick:
        print("🧪 Running Quick Test Subset...")
        # Run only core tests using the test class directly
        loader = unittest.TestLoader()
        suite = loader.loadTestsFromTestCase(TestQuantumStateManager)
        
        # Filter to only run specific test methods
        filtered_suite = unittest.TestSuite()
        for test in suite:
            test_name = test._testMethodName
            if test_name in ['test_quantum_state_initialization', 'test_complete_quantum_state_capture', 'test_state_save_and_load']:
                filtered_suite.addTest(test)
        
        runner = unittest.TextTestRunner(verbosity=1)
        result = runner.run(filtered_suite)
        return result.wasSuccessful()
    
    elif args.performance:
        print("⚡ Running Performance Tests...")
        # Run only performance tests
        loader = unittest.TestLoader()
        suite = loader.loadTestsFromName('TestQuantumStateManager.test_large_state_capture_performance')
        suite.addTests(loader.loadTestsFromName('TestQuantumStateManager.test_state_optimization_performance'))
        suite.addTests(loader.loadTestsFromName('TestQuantumStateManager.test_performance_benchmarking'))
        runner = unittest.TextTestRunner(verbosity=1)
        result = runner.run(suite)
        return result.wasSuccessful()
    
    elif args.compatibility:
        print("🔄 Running Compatibility Tests...")
        # Run only compatibility tests
        loader = unittest.TestLoader()
        suite = loader.loadTestsFromName('TestQuantumStateManager.test_backward_compatibility')
        suite.addTests(loader.loadTestsFromName('TestQuantumStateManager.test_state_compatibility_validation'))
        suite.addTests(loader.loadTestsFromName('TestQuantumStateManager.test_compatible_states_listing'))
        runner = unittest.TextTestRunner(verbosity=1)
        result = runner.run(suite)
        return result.wasSuccessful()
    
    else:
        # Run comprehensive test suite
        return run_comprehensive_test_suite()


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)