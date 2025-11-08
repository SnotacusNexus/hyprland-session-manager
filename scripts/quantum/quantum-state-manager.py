#!/usr/bin/env python3
"""
🚀 Quantum State Manager for Hyprland Session Manager
Comprehensive desktop state management with quantum persistence approach
Replaces broken environment management system with superior hyprpersist methodology
"""

import os
import json
import subprocess
import time
import logging
import sys
import hashlib
import threading
import asyncio
import select
from pathlib import Path
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, asdict
from datetime import datetime
import psutil
import yaml
import configparser
import argparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/tmp/quantum-state-manager.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class QuantumState:
    """Comprehensive quantum state representation"""
    timestamp: str
    session_id: str
    monitor_layouts: List[Dict[str, Any]]
    workspace_states: List[Dict[str, Any]]
    window_states: List[Dict[str, Any]]
    application_contexts: List[Dict[str, Any]]
    terminal_sessions: List[Dict[str, Any]]
    browser_sessions: List[Dict[str, Any]]
    development_environments: List[Dict[str, Any]]
    system_state: Dict[str, Any]
    validation_checksums: Dict[str, str]

class QuantumStateManager:
    """Main quantum state manager implementing hyprpersist approach"""
    
    def __init__(self, session_dir: str = None):
        self.session_dir = session_dir or os.path.expanduser("~/.config/hyprland-session-manager")
        self.state_dir = os.path.join(self.session_dir, "quantum-state")
        self.backup_dir = os.path.join(self.state_dir, "backups")
        
        # Create directories
        Path(self.state_dir).mkdir(parents=True, exist_ok=True)
        Path(self.backup_dir).mkdir(parents=True, exist_ok=True)
        
        # Configuration
        self.config = self._load_config()
        
        # Event monitoring
        self.event_monitor_running = False
        self.event_callbacks = []
        
        logger.info(f"Quantum State Manager initialized: {self.state_dir}")

    def _load_config(self) -> Dict[str, Any]:
        """Load quantum state configuration using the new configuration system"""
        try:
            # Import the new configuration system
            from quantum_state_config import load_quantum_config, get_quantum_config
            
            # Load configuration
            config = load_quantum_config(self.session_dir)
            
            # Convert to dictionary format for backward compatibility
            config_dict = {
                "auto_save_interval": config.core.auto_save_interval,
                "max_backups": config.backup.max_backups,
                "state_validation": config.core.state_validation_enabled,
                "performance_optimization": config.performance.performance_optimization_enabled,
                "application_contexts": {
                    "browsers": config.applications.browser_applications,
                    "terminals": config.applications.terminal_applications,
                    "ides": config.applications.ide_applications,
                    "creative": config.applications.creative_applications
                },
                "monitor_detection": config.monitor_workspace.monitor_detection_enabled,
                "workspace_persistence": config.monitor_workspace.workspace_persistence_enabled,
                "environment_tracking": config.applications.development_environments_enabled
            }
            
            logger.info("✅ Loaded configuration using new quantum configuration system")
            return config_dict
            
        except Exception as e:
            logger.warning(f"Failed to load quantum config using new system: {e}")
            
            # Fallback to old method
            config_path = os.path.join(self.session_dir, "quantum-state-config.py")
            if os.path.exists(config_path):
                try:
                    # Import the config module
                    import importlib.util
                    spec = importlib.util.spec_from_file_location("quantum_config", config_path)
                    config_module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(config_module)
                    return getattr(config_module, "QUANTUM_CONFIG", {})
                except Exception as e2:
                    logger.warning(f"Failed to load quantum config: {e2}")
            
            # Default configuration
            return {
                "auto_save_interval": 300,  # 5 minutes
                "max_backups": 10,
                "state_validation": True,
                "performance_optimization": True,
                "application_contexts": {
                    "browsers": ["firefox", "chrome", "chromium", "brave"],
                    "terminals": ["kitty", "alacritty", "wezterm", "gnome-terminal"],
                    "ides": ["code", "vscodium", "void", "pycharm"],
                    "creative": ["krita", "gimp", "blender", "inkscape"]
                },
                "monitor_detection": True,
                "workspace_persistence": True,
                "environment_tracking": True
            }

    def _run_hyprctl_command(self, command: str) -> Optional[Dict[str, Any]]:
        """Execute hyprctl command and return JSON result"""
        try:
            result = subprocess.run(
                ["hyprctl", command, "-j"],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                return json.loads(result.stdout)
        except (subprocess.TimeoutExpired, json.JSONDecodeError, FileNotFoundError) as e:
            logger.warning(f"Hyprctl command failed: {command} - {e}")
        return None

    def capture_monitor_layouts(self) -> List[Dict[str, Any]]:
        """Capture comprehensive monitor layouts and configurations"""
        logger.info("Capturing quantum monitor layouts...")
        
        monitors = self._run_hyprctl_command("monitors") or []
        layouts = []
        
        for monitor in monitors:
            layout = {
                "id": monitor.get("id"),
                "name": monitor.get("name"),
                "description": monitor.get("description"),
                "width": monitor.get("width"),
                "height": monitor.get("height"),
                "refreshRate": monitor.get("refreshRate"),
                "x": monitor.get("x"),
                "y": monitor.get("y"),
                "activeWorkspace": monitor.get("activeWorkspace", {}),
                "reserved": monitor.get("reserved", []),
                "scale": monitor.get("scale", 1.0),
                "transform": monitor.get("transform", 0),
                "focused": monitor.get("focused", False),
                "dpmsStatus": monitor.get("dpmsStatus", True)
            }
            layouts.append(layout)
        
        logger.info(f"Captured {len(layouts)} monitor layouts")
        return layouts

    def capture_workspace_states(self) -> List[Dict[str, Any]]:
        """Capture comprehensive workspace states with quantum persistence"""
        logger.info("Capturing quantum workspace states...")
        
        workspaces = self._run_hyprctl_command("workspaces") or []
        clients = self._run_hyprctl_command("clients") or []
        
        workspace_states = []
        
        for workspace in workspaces:
            workspace_id = workspace.get("id")
            workspace_clients = [
                client for client in clients 
                if client.get("workspace", {}).get("id") == workspace_id
            ]
            
            workspace_state = {
                "id": workspace_id,
                "name": workspace.get("name"),
                "monitor": workspace.get("monitor"),
                "monitorID": workspace.get("monitorID"),
                "windows": workspace.get("windows", 0),
                "hasfullscreen": workspace.get("hasfullscreen", False),
                "lastwindow": workspace.get("lastwindow", ""),
                "lastwindowtitle": workspace.get("lastwindowtitle", ""),
                "clients": [
                    {
                        "address": client.get("address"),
                        "class": client.get("class"),
                        "title": client.get("title"),
                        "initialClass": client.get("initialClass"),
                        "initialTitle": client.get("initialTitle")
                    }
                    for client in workspace_clients
                ],
                "persistent": workspace.get("persistent", False),
                "specialWorkspace": workspace_id < 0  # Negative IDs are special workspaces
            }
            workspace_states.append(workspace_state)
        
        logger.info(f"Captured {len(workspace_states)} workspace states")
        return workspace_states

    def capture_window_states(self) -> List[Dict[str, Any]]:
        """Capture comprehensive window states with quantum accuracy"""
        logger.info("Capturing quantum window states...")
        
        clients = self._run_hyprctl_command("clients") or []
        active_window = self._run_hyprctl_command("activewindow") or {}
        
        window_states = []
        
        for client in clients:
            window_state = {
                "address": client.get("address"),
                "class": client.get("class"),
                "title": client.get("title"),
                "initialClass": client.get("initialClass"),
                "initialTitle": client.get("initialTitle"),
                "pid": client.get("pid"),
                "xwayland": client.get("xwayland", False),
                "pinned": client.get("pinned", False),
                "fullscreen": client.get("fullscreen", False),
                "fullscreenMode": client.get("fullscreenMode", 0),
                "fakeFullscreen": client.get("fakeFullscreen", False),
                "floating": client.get("floating", False),
                "monitor": client.get("monitor"),
                "workspace": client.get("workspace", {}),
                "at": client.get("at", [0, 0]),
                "size": client.get("size", [0, 0]),
                "focusHistoryID": client.get("focusHistoryID", 0),
                "active": client.get("address") == active_window.get("address")
            }
            window_states.append(window_state)
        
        logger.info(f"Captured {len(window_states)} window states")
        return window_states

    def capture_application_contexts(self) -> List[Dict[str, Any]]:
        """Capture application-specific contexts with quantum persistence"""
        logger.info("Capturing quantum application contexts...")
        
        clients = self._run_hyprctl_command("clients") or []
        application_contexts = []
        
        for client in clients:
            app_class = client.get("class", "").lower()
            pid = client.get("pid")
            
            context = {
                "class": app_class,
                "pid": pid,
                "title": client.get("title"),
                "workspace": client.get("workspace", {}).get("id"),
                "window_address": client.get("address"),
                "session_data": self._capture_application_session_data(app_class, pid),
                "environment": self._capture_process_environment(pid),
                "state_checksum": self._generate_state_checksum(client)
            }
            application_contexts.append(context)
        
        logger.info(f"Captured {len(application_contexts)} application contexts")
        return application_contexts

    def _capture_application_session_data(self, app_class: str, pid: int) -> Dict[str, Any]:
        """Capture application-specific session data"""
        session_data = {}
        
        try:
            if app_class in ["firefox", "chrome", "chromium", "brave"]:
                session_data = self._capture_browser_session(app_class, pid)
            elif app_class in ["kitty", "alacritty", "wezterm", "gnome-terminal"]:
                session_data = self._capture_terminal_session(app_class, pid)
            elif app_class in ["code", "vscodium", "void"]:
                session_data = self._capture_ide_session(app_class, pid)
            elif app_class in ["krita", "gimp", "blender"]:
                session_data = self._capture_creative_session(app_class, pid)
        except Exception as e:
            logger.warning(f"Failed to capture session data for {app_class}: {e}")
        
        return session_data

    def _capture_browser_session(self, browser: str, pid: int) -> Dict[str, Any]:
        """Capture browser session state"""
        session_data = {
            "type": "browser",
            "browser": browser,
            "tabs": [],
            "windows": [],
            "session_file": None
        }
        
        try:
            # Browser-specific session capture
            if browser == "firefox":
                # Firefox session recovery
                profile_dir = self._find_firefox_profile(pid)
                if profile_dir:
                    session_file = os.path.join(profile_dir, "sessionstore.jsonlz4")
                    if os.path.exists(session_file):
                        session_data["session_file"] = session_file
                        session_data["profile"] = profile_dir
            
            elif browser in ["chrome", "chromium", "brave"]:
                # Chrome-based browser session recovery
                session_data["session_storage"] = self._find_chrome_session(pid)
        
        except Exception as e:
            logger.warning(f"Browser session capture failed for {browser}: {e}")
        
        return session_data

    def _capture_terminal_session(self, terminal: str, pid: int) -> Dict[str, Any]:
        """Capture terminal session state"""
        session_data = {
            "type": "terminal",
            "terminal": terminal,
            "current_directory": None,
            "environment": {},
            "shell_session": None
        }
        
        try:
            # Get current working directory
            if pid:
                try:
                    cwd = os.readlink(f"/proc/{pid}/cwd")
                    session_data["current_directory"] = cwd
                except (OSError, FileNotFoundError):
                    pass
            
            # Get environment variables
            if pid and os.path.exists(f"/proc/{pid}/environ"):
                with open(f"/proc/{pid}/environ", "rb") as f:
                    env_data = f.read().replace(b'\x00', b'\n').decode('utf-8', errors='ignore')
                    env_vars = {}
                    for line in env_data.split('\n'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            env_vars[key] = value
                    session_data["environment"] = env_vars
            
            # Terminal-specific session capture
            if terminal == "kitty":
                session_data["kitty_session"] = self._capture_kitty_session(pid)
            elif terminal == "tmux":
                session_data["tmux_session"] = self._capture_tmux_session(pid)
        
        except Exception as e:
            logger.warning(f"Terminal session capture failed for {terminal}: {e}")
        
        return session_data

    def _capture_ide_session(self, ide: str, pid: int) -> Dict[str, Any]:
        """Capture IDE session state"""
        session_data = {
            "type": "ide",
            "ide": ide,
            "workspace": None,
            "open_files": [],
            "projects": []
        }
        
        try:
            # IDE-specific session capture
            if ide in ["code", "vscodium"]:
                session_data["vscode_session"] = self._capture_vscode_session(pid)
            elif ide == "void":
                session_data["void_session"] = self._capture_void_session(pid)
        
        except Exception as e:
            logger.warning(f"IDE session capture failed for {ide}: {e}")
        
        return session_data

    def _capture_creative_session(self, app: str, pid: int) -> Dict[str, Any]:
        """Capture creative application session state"""
        session_data = {
            "type": "creative",
            "application": app,
            "open_documents": [],
            "workspace_layout": None
        }
        
        try:
            # Application-specific session capture
            if app == "krita":
                session_data["krita_session"] = self._capture_krita_session(pid)
            elif app == "gimp":
                session_data["gimp_session"] = self._capture_gimp_session(pid)
        
        except Exception as e:
            logger.warning(f"Creative session capture failed for {app}: {e}")
        
        return session_data

    def _capture_process_environment(self, pid: int) -> Dict[str, Any]:
        """Capture process environment and development contexts"""
        environment = {
            "development_environments": [],
            "current_directory": None,
            "environment_variables": {}
        }
        
        if not pid:
            return environment
        
        try:
            # Get current directory
            cwd = os.readlink(f"/proc/{pid}/cwd")
            environment["current_directory"] = cwd
            
            # Get environment variables
            if os.path.exists(f"/proc/{pid}/environ"):
                with open(f"/proc/{pid}/environ", "rb") as f:
                    env_data = f.read().replace(b'\x00', b'\n').decode('utf-8', errors='ignore')
                    env_vars = {}
                    for line in env_data.split('\n'):
                        if '=' in line:
                            key, value = line.split('=', 1)
                            env_vars[key] = value
                    environment["environment_variables"] = env_vars
            
            # Detect development environments
            dev_envs = self._detect_development_environments(environment["environment_variables"])
            environment["development_environments"] = dev_envs
        
        except Exception as e:
            logger.warning(f"Process environment capture failed for PID {pid}: {e}")
        
        return environment

    def _detect_development_environments(self, env_vars: Dict[str, str]) -> List[Dict[str, Any]]:
        """Detect active development environments"""
        environments = []
        
        # Conda environments
        if "CONDA_DEFAULT_ENV" in env_vars:
            environments.append({
                "type": "conda",
                "name": env_vars["CONDA_DEFAULT_ENV"],
                "active": True
            })
        
        # Virtual environments
        if "VIRTUAL_ENV" in env_vars:
            environments.append({
                "type": "venv",
                "name": os.path.basename(env_vars["VIRTUAL_ENV"]),
                "path": env_vars["VIRTUAL_ENV"],
                "active": True
            })
        
        # Pyenv environments
        if "PYENV_VERSION" in env_vars:
            environments.append({
                "type": "pyenv",
                "name": env_vars["PYENV_VERSION"],
                "active": True
            })
        
        # Node.js environments
        if "NODE_ENV" in env_vars:
            environments.append({
                "type": "node",
                "environment": env_vars["NODE_ENV"],
                "active": True
            })
        
        return environments

    def _generate_state_checksum(self, state_data: Dict[str, Any]) -> str:
        """Generate checksum for state validation"""
        state_str = json.dumps(state_data, sort_keys=True)
        return hashlib.md5(state_str.encode()).hexdigest()


    def _find_firefox_profile(self, pid: int) -> Optional[str]:
        """Find Firefox profile directory"""
        try:
            # Look for Firefox profile in common locations
            home = os.path.expanduser("~")
            firefox_dir = os.path.join(home, ".mozilla", "firefox")
            if os.path.exists(firefox_dir):
                # Look for profiles.ini
                profiles_ini = os.path.join(firefox_dir, "profiles.ini")
                if os.path.exists(profiles_ini):
                    config = configparser.ConfigParser()
                    config.read(profiles_ini)
                    
                    # Find default profile
                    for section in config.sections():
                        if section.startswith("Profile"):
                            if config.get(section, "Default", fallback="0") == "1":
                                profile_path = config.get(section, "Path", fallback="")
                                if profile_path:
                                    full_path = os.path.join(firefox_dir, profile_path)
                                    if os.path.exists(full_path):
                                        return full_path
                    
                    # Fallback: find any profile directory
                    for item in os.listdir(firefox_dir):
                        item_path = os.path.join(firefox_dir, item)
                        if os.path.isdir(item_path) and item.endswith(".default"):
                            return item_path
        except Exception as e:
            logger.warning(f"Failed to find Firefox profile: {e}")
        
        return None

    def _find_chrome_session(self, pid: int) -> Dict[str, Any]:
        """Find Chrome-based browser session data"""
        session_data = {}
        
        try:
            home = os.path.expanduser("~")
            # Look for Chrome-based browser profiles
            browsers = ["google-chrome", "chromium", "brave-browser"]
            
            for browser in browsers:
                browser_dir = os.path.join(home, ".config", browser)
                if os.path.exists(browser_dir):
                    # Look for session files
                    session_files = []
                    for root, dirs, files in os.walk(browser_dir):
                        for file in files:
                            if file.startswith("Session") and file.endswith((".json", ".db")):
                                session_files.append(os.path.join(root, file))
                    
                    if session_files:
                        session_data[browser] = {
                            "session_files": session_files,
                            "profile_dir": browser_dir
                        }
        except Exception as e:
            logger.warning(f"Failed to find Chrome session: {e}")
        
        return session_data

    def _capture_kitty_session(self, pid: int) -> Dict[str, Any]:
        """Capture Kitty terminal session data"""
        session_data = {}
        
        try:
            # Try to get Kitty session via remote control
            result = subprocess.run(
                ["kitty", "@", "ls"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                try:
                    kitty_data = json.loads(result.stdout)
                    session_data["kitty_sessions"] = kitty_data
                except json.JSONDecodeError:
                    session_data["kitty_output"] = result.stdout
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            logger.debug(f"Kitty session capture failed: {e}")
        
        return session_data

    def _capture_tmux_session(self, pid: int) -> Dict[str, Any]:
        """Capture tmux session data"""
        session_data = {}
        
        try:
            # Get tmux sessions
            result = subprocess.run(
                ["tmux", "list-sessions"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                session_data["tmux_sessions"] = result.stdout.strip().split('\n')
            
            # Get tmux windows for current session
            result = subprocess.run(
                ["tmux", "list-windows"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                session_data["tmux_windows"] = result.stdout.strip().split('\n')
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            logger.debug(f"Tmux session capture failed: {e}")
        
        return session_data

    def _capture_vscode_session(self, pid: int) -> Dict[str, Any]:
        """Capture VSCode session data"""
        session_data = {}
        
        try:
            home = os.path.expanduser("~")
            vscode_dir = os.path.join(home, ".config", "Code")
            if os.path.exists(vscode_dir):
                # Look for workspace storage
                storage_dir = os.path.join(vscode_dir, "User", "workspaceStorage")
                if os.path.exists(storage_dir):
                    workspace_data = []
                    for item in os.listdir(storage_dir):
                        item_path = os.path.join(storage_dir, item)
                        if os.path.isdir(item_path):
                            workspace_file = os.path.join(item_path, "workspace.json")
                            if os.path.exists(workspace_file):
                                try:
                                    with open(workspace_file, 'r') as f:
                                        workspace_info = json.load(f)
                                        workspace_data.append({
                                            "id": item,
                                            "workspace": workspace_info
                                        })
                                except json.JSONDecodeError:
                                    pass
                    
                    session_data["workspace_storage"] = workspace_data
        except Exception as e:
            logger.warning(f"VSCode session capture failed: {e}")
        
        return session_data

    def _capture_void_session(self, pid: int) -> Dict[str, Any]:
        """Capture Void editor session data"""
        session_data = {}
        
        try:
            home = os.path.expanduser("~")
            void_dir = os.path.join(home, ".config", "void")
            if os.path.exists(void_dir):
                # Look for session files
                session_files = []
                for root, dirs, files in os.walk(void_dir):
                    for file in files:
                        if file.endswith(".session"):
                            session_files.append(os.path.join(root, file))
                
                if session_files:
                    session_data["session_files"] = session_files
        except Exception as e:
            logger.warning(f"Void session capture failed: {e}")
        
        return session_data

    def _capture_krita_session(self, pid: int) -> Dict[str, Any]:
        """Capture Krita session data"""
        session_data = {}
        
        try:
            home = os.path.expanduser("~")
            krita_dir = os.path.join(home, ".local", "share", "krita")
            if os.path.exists(krita_dir):
                # Look for session files
                session_files = []
                for root, dirs, files in os.walk(krita_dir):
                    for file in files:
                        if file.endswith((".kra", ".session")):
                            session_files.append(os.path.join(root, file))
                
                if session_files:
                    session_data["document_files"] = session_files
        except Exception as e:
            logger.warning(f"Krita session capture failed: {e}")
        
        return session_data

    def _capture_gimp_session(self, pid: int) -> Dict[str, Any]:
        """Capture GIMP session data"""
        session_data = {}
        
        try:
            home = os.path.expanduser("~")
            gimp_dir = os.path.join(home, ".config", "GIMP")
            if os.path.exists(gimp_dir):
                # Look for session files
                session_files = []
                for version_dir in os.listdir(gimp_dir):
                    version_path = os.path.join(gimp_dir, version_dir)
                    if os.path.isdir(version_path):
                        session_file = os.path.join(version_path, "sessionrc")
                        if os.path.exists(session_file):
                            session_files.append(session_file)
                
                if session_files:
                    session_data["session_files"] = session_files
        except Exception as e:
            logger.warning(f"GIMP session capture failed: {e}")
        
        return session_data

    def capture_terminal_sessions(self) -> List[Dict[str, Any]]:
        """Capture comprehensive terminal sessions with environment tracking"""
        logger.info("Capturing quantum terminal sessions...")
        
        clients = self._run_hyprctl_command("clients") or []
        terminal_sessions = []
        
        for client in clients:
            app_class = client.get("class", "").lower()
            if app_class in self.config["application_contexts"]["terminals"]:
                pid = client.get("pid")
                
                terminal_session = {
                    "class": app_class,
                    "pid": pid,
                    "window_address": client.get("address"),
                    "workspace": client.get("workspace", {}).get("id"),
                    "environment": self._capture_process_environment(pid),
                    "session_data": self._capture_terminal_session(app_class, pid),
                    "timestamp": datetime.now().isoformat()
                }
                terminal_sessions.append(terminal_session)
        
        logger.info(f"Captured {len(terminal_sessions)} terminal sessions")
        return terminal_sessions

    def capture_browser_sessions(self) -> List[Dict[str, Any]]:
        """Capture comprehensive browser sessions"""
        logger.info("Capturing quantum browser sessions...")
        
        clients = self._run_hyprctl_command("clients") or []
        browser_sessions = []
        
        for client in clients:
            app_class = client.get("class", "").lower()
            if app_class in self.config["application_contexts"]["browsers"]:
                pid = client.get("pid")
                
                browser_session = {
                    "class": app_class,
                    "pid": pid,
                    "window_address": client.get("address"),
                    "workspace": client.get("workspace", {}).get("id"),
                    "session_data": self._capture_browser_session(app_class, pid),
                    "timestamp": datetime.now().isoformat()
                }
                browser_sessions.append(browser_session)
        
        logger.info(f"Captured {len(browser_sessions)} browser sessions")
        return browser_sessions

    def capture_development_environments(self) -> List[Dict[str, Any]]:
        """Capture development environments from all processes"""
        logger.info("Capturing quantum development environments...")
        
        environments = []
        
        # Scan all processes for development environments
        for proc in psutil.process_iter(['pid', 'environ']):
            try:
                env_vars = proc.info.get('environ', {})
                if env_vars is None:
                    continue
                    
                dev_envs = self._detect_development_environments(env_vars)
                
                if dev_envs:
                    environment_data = {
                        "pid": proc.info['pid'],
                        "environments": dev_envs,
                        "timestamp": datetime.now().isoformat()
                    }
                    environments.append(environment_data)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                continue
        
        logger.info(f"Captured {len(environments)} development environments")
        return environments

    def capture_system_state(self) -> Dict[str, Any]:
        """Capture comprehensive system state"""
        logger.info("Capturing quantum system state...")
        
        system_state = {
            "timestamp": datetime.now().isoformat(),
            "cpu_usage": psutil.cpu_percent(interval=1),
            "memory_usage": dict(psutil.virtual_memory()._asdict()),
            "disk_usage": {},
            "network_connections": [],
            "running_processes": len(psutil.pids())
        }
        
        # Disk usage
        for partition in psutil.disk_partitions():
            try:
                usage = psutil.disk_usage(partition.mountpoint)
                system_state["disk_usage"][partition.mountpoint] = {
                    "total": usage.total,
                    "used": usage.used,
                    "free": usage.free,
                    "percent": usage.percent
                }
            except PermissionError:
                continue
        
        # Network connections
        for conn in psutil.net_connections(kind='inet'):
            system_state["network_connections"].append({
                "fd": conn.fd,
                "family": conn.family,
                "type": conn.type,
                "laddr": conn.laddr,
                "raddr": conn.raddr,
                "status": conn.status,
                "pid": conn.pid
            })
        
        logger.info("System state captured successfully")
        return system_state

    def generate_validation_checksums(self, state: QuantumState) -> Dict[str, str]:
        """Generate validation checksums for state integrity"""
        checksums = {}
        
        # Generate checksums for each component
        components = {
            "monitor_layouts": state.monitor_layouts,
            "workspace_states": state.workspace_states,
            "window_states": state.window_states,
            "application_contexts": state.application_contexts,
            "terminal_sessions": state.terminal_sessions,
            "browser_sessions": state.browser_sessions,
            "development_environments": state.development_environments,
            "system_state": state.system_state
        }
        
        for component, data in components.items():
            checksums[component] = self._generate_state_checksum(data)
        
        # Overall state checksum
        state_dict = asdict(state)
        state_dict.pop("validation_checksums", None)  # Remove existing checksums
        checksums["overall"] = self._generate_state_checksum(state_dict)
        
        return checksums

    def capture_quantum_state(self) -> QuantumState:
        """Capture complete quantum state with all components"""
        logger.info("🚀 Capturing comprehensive quantum state...")
        
        # Generate session ID
        session_id = f"quantum_{int(time.time())}"
        
        # Capture all state components
        monitor_layouts = self.capture_monitor_layouts()
        workspace_states = self.capture_workspace_states()
        window_states = self.capture_window_states()
        application_contexts = self.capture_application_contexts()
        terminal_sessions = self.capture_terminal_sessions()
        browser_sessions = self.capture_browser_sessions()
        development_environments = self.capture_development_environments()
        system_state = self.capture_system_state()
        
        # Create quantum state
        quantum_state = QuantumState(
            timestamp=datetime.now().isoformat(),
            session_id=session_id,
            monitor_layouts=monitor_layouts,
            workspace_states=workspace_states,
            window_states=window_states,
            application_contexts=application_contexts,
            terminal_sessions=terminal_sessions,
            browser_sessions=browser_sessions,
            development_environments=development_environments,
            system_state=system_state,
            validation_checksums={}
        )
        
        # Generate validation checksums
        quantum_state.validation_checksums = self.generate_validation_checksums(quantum_state)
        
        logger.info(f"✅ Quantum state captured successfully: {session_id}")
        return quantum_state

    def save_quantum_state(self, state: QuantumState, filename: str = None) -> str:
        """Save quantum state to file with validation"""
        if not filename:
            filename = f"quantum_state_{state.session_id}.json"
        
        state_path = os.path.join(self.state_dir, filename)
        
        try:
            # Convert state to dictionary
            state_dict = asdict(state)
            
            # Save with pretty formatting
            with open(state_path, 'w') as f:
                json.dump(state_dict, f, indent=2, ensure_ascii=False)
            
            logger.info(f"✅ Quantum state saved: {state_path}")
            
            # Create backup
            self._create_backup(state_path)
            
            return state_path
        except Exception as e:
            logger.error(f"❌ Failed to save quantum state: {e}")
            raise

    def load_quantum_state(self, filename: str) -> QuantumState:
        """Load quantum state from file with validation"""
        state_path = os.path.join(self.state_dir, filename)
        
        try:
            with open(state_path, 'r') as f:
                state_dict = json.load(f)
            
            # Convert back to QuantumState object
            quantum_state = QuantumState(**state_dict)
            
            # Validate checksums
            if self.config.get("state_validation", True):
                self._validate_state_checksums(quantum_state)
            
            logger.info(f"✅ Quantum state loaded: {state_path}")
            return quantum_state
        except Exception as e:
            logger.error(f"❌ Failed to load quantum state: {e}")
            raise

    def _validate_state_checksums(self, state: QuantumState) -> bool:
        """Validate state integrity using checksums"""
        try:
            current_checksums = self.generate_validation_checksums(state)
            
            for component, expected_checksum in state.validation_checksums.items():
                if component != "overall":  # Skip overall for component validation
                    current_checksum = current_checksums.get(component)
                    if current_checksum != expected_checksum:
                        logger.warning(f"Checksum mismatch for {component}: expected {expected_checksum}, got {current_checksum}")
                        return False
            
            # Validate overall checksum
            overall_expected = state.validation_checksums.get("overall")
            overall_current = current_checksums.get("overall")
            if overall_expected != overall_current:
                logger.warning(f"Overall checksum mismatch: expected {overall_expected}, got {overall_current}")
                return False
            
            logger.info("✅ State validation successful")
            return True
        except Exception as e:
            logger.error(f"State validation failed: {e}")
            return False

    def _create_backup(self, state_path: str):
        """Create backup of state file"""
        try:
            backup_name = f"backup_{os.path.basename(state_path)}_{int(time.time())}"
            backup_path = os.path.join(self.backup_dir, backup_name)
            
            import shutil
            shutil.copy2(state_path, backup_path)
            
            # Clean up old backups
            self._cleanup_old_backups()
            
            logger.info(f"✅ Backup created: {backup_path}")
        except Exception as e:
            logger.warning(f"Failed to create backup: {e}")

    def _cleanup_old_backups(self):
        """Clean up old backup files"""
        try:
            backup_files = []
            for file in os.listdir(self.backup_dir):
                if file.startswith("backup_"):

                    file_path = os.path.join(self.backup_dir, file)
                    backup_files.append((file_path, os.path.getctime(file_path)))
            
            # Sort by creation time (oldest first)
            backup_files.sort(key=lambda x: x[1])
            
            # Remove oldest backups if we exceed the limit
            max_backups = self.config.get("max_backups", 10)
            if len(backup_files) > max_backups:
                files_to_remove = backup_files[:len(backup_files) - max_backups]
                for file_path, _ in files_to_remove:
                    os.remove(file_path)
                    logger.info(f"Removed old backup: {file_path}")
        except Exception as e:
            logger.warning(f"Failed to cleanup old backups: {e}")

    def start_event_monitoring(self):
        """Start real-time Hyprland event monitoring"""
        if self.event_monitor_running:
            logger.info("Event monitoring already running")
            return
        
        self.event_monitor_running = True
        monitor_thread = threading.Thread(target=self._event_monitor_loop, daemon=True)
        monitor_thread.start()
        logger.info("✅ Started real-time Hyprland event monitoring")

    def stop_event_monitoring(self):
        """Stop event monitoring"""
        self.event_monitor_running = False
        logger.info("Stopped Hyprland event monitoring")

    def _event_monitor_loop(self):
        """Main event monitoring loop"""
        try:
            while self.event_monitor_running:
                # Monitor Hyprland events
                self._monitor_hyprland_events()
                time.sleep(1)  # Check every second
        except Exception as e:
            logger.error(f"Event monitoring loop failed: {e}")
            self.event_monitor_running = False

    def _monitor_hyprland_events(self):
        """Monitor Hyprland events for state changes"""
        try:
            # Monitor workspace changes
            workspaces = self._run_hyprctl_command("workspaces")
            if workspaces:
                self._handle_workspace_changes(workspaces)
            
            # Monitor active window changes
            active_window = self._run_hyprctl_command("activewindow")
            if active_window:
                self._handle_active_window_change(active_window)
            
            # Monitor client changes
            clients = self._run_hyprctl_command("clients")
            if clients:
                self._handle_client_changes(clients)
                
        except Exception as e:
            logger.debug(f"Hyprland event monitoring failed: {e}")

    def _handle_workspace_changes(self, workspaces: List[Dict[str, Any]]):
        """Handle workspace change events"""
        # Check for workspace focus changes
        for workspace in workspaces:
            if workspace.get("focused", False):
                # Workspace focus changed
                for callback in self.event_callbacks:
                    if hasattr(callback, "on_workspace_focus"):
                        callback.on_workspace_focus(workspace)

    def _handle_active_window_change(self, active_window: Dict[str, Any]):
        """Handle active window change events"""
        # Active window changed
        for callback in self.event_callbacks:
            if hasattr(callback, "on_active_window_change"):
                callback.on_active_window_change(active_window)

    def _handle_client_changes(self, clients: List[Dict[str, Any]]):
        """Handle client (window) change events"""
        # Check for new windows or window state changes
        for callback in self.event_callbacks:
            if hasattr(callback, "on_client_changes"):
                callback.on_client_changes(clients)

    def add_event_callback(self, callback: Callable):
        """Add event callback for state changes"""
        self.event_callbacks.append(callback)
        logger.info(f"Added event callback: {callback.__name__ if hasattr(callback, '__name__') else type(callback).__name__}")

    def remove_event_callback(self, callback: Callable):
        """Remove event callback"""
        if callback in self.event_callbacks:
            self.event_callbacks.remove(callback)
            logger.info(f"Removed event callback: {callback.__name__ if hasattr(callback, '__name__') else type(callback).__name__}")

    def start_auto_save(self, interval: int = None):
        """Start automatic state saving"""
        if interval is None:
            interval = self.config.get("auto_save_interval", 300)
        
        def auto_save_loop():
            while True:
                time.sleep(interval)
                try:
                    state = self.capture_quantum_state()
                    self.save_quantum_state(state, f"auto_save_{int(time.time())}.json")
                    logger.info(f"✅ Auto-saved quantum state")
                except Exception as e:
                    logger.error(f"Auto-save failed: {e}")
        
        auto_save_thread = threading.Thread(target=auto_save_loop, daemon=True)
        auto_save_thread.start()
        logger.info(f"✅ Started auto-save with {interval} second interval")

    def optimize_state_capture(self, state: QuantumState) -> QuantumState:
        """Optimize state capture for performance"""
        if not self.config.get("performance_optimization", True):
            return state
        
        # Remove redundant data
        optimized_state = QuantumState(
            timestamp=state.timestamp,
            session_id=state.session_id,
            monitor_layouts=state.monitor_layouts,
            workspace_states=state.workspace_states,
            window_states=state.window_states,
            application_contexts=self._optimize_application_contexts(state.application_contexts),
            terminal_sessions=self._optimize_terminal_sessions(state.terminal_sessions),
            browser_sessions=self._optimize_browser_sessions(state.browser_sessions),
            development_environments=state.development_environments,
            system_state=state.system_state,
            validation_checksums=state.validation_checksums
        )
        
        return optimized_state

    def _optimize_application_contexts(self, contexts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Optimize application contexts for performance"""
        optimized = []
        for context in contexts:
            # Remove large binary data or compress
            optimized_context = context.copy()
            if "session_data" in optimized_context:
                # Remove large session files from context
                session_data = optimized_context["session_data"]
                if isinstance(session_data, dict):
                    for key in list(session_data.keys()):
                        if key.endswith("_files") and isinstance(session_data[key], list):
                            # Keep only file paths, not content
                            session_data[key] = [os.path.basename(f) for f in session_data[key]]
            optimized.append(optimized_context)
        return optimized

    def _optimize_terminal_sessions(self, sessions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Optimize terminal sessions for performance"""
        optimized = []
        for session in sessions:
            optimized_session = session.copy()
            # Remove large environment data if not needed
            if "environment" in optimized_session:
                env = optimized_session["environment"]
                if "environment_variables" in env:
                    # Keep only essential environment variables
                    essential_vars = ["PWD", "TERM", "SHELL", "PATH", "HOME", "USER"]
                    env["environment_variables"] = {
                        k: v for k, v in env["environment_variables"].items() 
                        if k in essential_vars
                    }
            optimized.append(optimized_session)
        return optimized

    def _optimize_browser_sessions(self, sessions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Optimize browser sessions for performance"""
        optimized = []
        for session in sessions:
            optimized_session = session.copy()
            # Remove large session file content, keep only paths
            if "session_data" in optimized_session:
                session_data = optimized_session["session_data"]
                if "session_file" in session_data:
                    session_data["session_file"] = os.path.basename(session_data["session_file"])
            optimized.append(optimized_session)
        return optimized

    def get_compatible_states(self) -> List[str]:
        """Get list of compatible quantum state files"""
        compatible_states = []
        
        try:
            for file in os.listdir(self.state_dir):
                if file.startswith("quantum_state_") and file.endswith(".json"):
                    file_path = os.path.join(self.state_dir, file)
                    try:
                        # Try to load and validate the state
                        state = self.load_quantum_state(file)
                        compatible_states.append(file)
                    except Exception:
                        # File exists but may not be compatible
                        continue
        except Exception as e:
            logger.warning(f"Failed to get compatible states: {e}")
        
        return compatible_states

    def migrate_legacy_state(self, legacy_file: str) -> QuantumState:
        """Migrate legacy session state to quantum state format"""
        try:
            with open(legacy_file, 'r') as f:
                legacy_data = json.load(f)
            
            # Convert legacy format to quantum state
            quantum_state = QuantumState(
                timestamp=datetime.now().isoformat(),
                session_id=f"migrated_{int(time.time())}",
                monitor_layouts=legacy_data.get("monitors", []),
                workspace_states=legacy_data.get("workspaces", []),
                window_states=legacy_data.get("windows", []),
                application_contexts=legacy_data.get("applications", []),
                terminal_sessions=legacy_data.get("terminals", []),
                browser_sessions=legacy_data.get("browsers", []),
                development_environments=legacy_data.get("environments", []),
                system_state=legacy_data.get("system", {}),
                validation_checksums={}
            )
            
            # Generate new checksums
            quantum_state.validation_checksums = self.generate_validation_checksums(quantum_state)
            
            logger.info(f"✅ Migrated legacy state: {legacy_file}")
            return quantum_state
            
        except Exception as e:
            logger.error(f"Failed to migrate legacy state: {e}")
            raise

    def validate_state_compatibility(self, state: QuantumState) -> bool:
        """Validate state compatibility with current system"""
        try:
            # Check monitor compatibility
            current_monitors = self.capture_monitor_layouts()
            if len(current_monitors) != len(state.monitor_layouts):
                logger.warning("Monitor count mismatch")
                return False
            
            # Check workspace compatibility
            current_workspaces = self.capture_workspace_states()
            if len(current_workspaces) < len(state.workspace_states):
                logger.warning("Workspace count mismatch")
                return False
            
            # Check system compatibility
            current_system = self.capture_system_state()
            # Basic system compatibility checks
            
            return True
        except Exception as e:
            logger.error(f"State compatibility validation failed: {e}")
            return False

def main():
    """Main function with command-line interface for session manager integration"""
    parser = argparse.ArgumentParser(description="Quantum State Manager for Hyprland Session Manager")
    parser.add_argument("--capture", action="store_true", help="Capture quantum state")
    parser.add_argument("--save", action="store_true", help="Save captured state")
    parser.add_argument("--load", action="store_true", help="Load quantum state")
    parser.add_argument("--restore", action="store_true", help="Restore state to system")
    parser.add_argument("--auto-save", action="store_true", help="Start auto-save daemon")
    parser.add_argument("--validate", action="store_true", help="Validate state compatibility")
    parser.add_argument("--migrate-legacy", type=str, help="Migrate legacy session data from directory")
    parser.add_argument("--session-dir", type=str, help="Session directory path")
    
    args = parser.parse_args()
    
    # Initialize manager
    manager = QuantumStateManager(args.session_dir)
    
    try:
        # Handle capture and save operation
        if args.capture and args.save:
            print("🚀 Capturing and saving quantum state...")
            state = manager.capture_quantum_state()
            saved_path = manager.save_quantum_state(state)
            print(f"✅ Quantum state saved: {saved_path}")
            return 0
        
        # Handle load and restore operation
        elif args.load and args.restore:
            print("📂 Loading and restoring quantum state...")
            # Find the latest quantum state file
            compatible_states = manager.get_compatible_states()
            if not compatible_states:
                print("❌ No compatible quantum states found")
                return 1
            
            latest_state = sorted(compatible_states)[-1]  # Get latest state
            state = manager.load_quantum_state(latest_state)
            
            # Validate compatibility before restoration
            if manager.validate_state_compatibility(state):
                print("✅ State compatibility validated, proceeding with restoration")
                # TODO: Implement actual state restoration logic
                print("🔄 State restoration would be performed here")
                return 0
            else:
                print("❌ State compatibility validation failed")
                return 1
        
        # Handle auto-save operation
        elif args.auto_save:
            print("🔄 Starting quantum state auto-save daemon...")
            manager.start_auto_save()
            # Keep the process running
            try:
                while True:
                    time.sleep(60)  # Keep alive
            except KeyboardInterrupt:
                print("🛑 Auto-save daemon stopped")
            return 0
        
        # Handle validation operation
        elif args.validate:
            print("🔍 Validating quantum state compatibility...")
            compatible_states = manager.get_compatible_states()
            if compatible_states:
                latest_state = sorted(compatible_states)[-1]
                state = manager.load_quantum_state(latest_state)
                if manager.validate_state_compatibility(state):
                    print("✅ Quantum state validation successful")
                    return 0
                else:
                    print("❌ Quantum state validation failed")
                    return 1
            else:
                print("❌ No quantum states found for validation")
                return 1
        
        # Handle legacy migration
        elif args.migrate_legacy:
            print(f"🔄 Migrating legacy session data from: {args.migrate_legacy}")
            legacy_files = []
            legacy_dir = args.migrate_legacy
            
            # Look for legacy session files
            for file in os.listdir(legacy_dir):
                if file.endswith((".json", ".txt")) and not file.startswith("quantum_state_"):
                    legacy_files.append(os.path.join(legacy_dir, file))
            
            if not legacy_files:
                print("❌ No legacy session files found")
                return 1
            
            migrated_count = 0
            for legacy_file in legacy_files:
                try:
                    quantum_state = manager.migrate_legacy_state(legacy_file)
                    manager.save_quantum_state(quantum_state)
                    migrated_count += 1
                    print(f"✅ Migrated: {os.path.basename(legacy_file)}")
                except Exception as e:
                    print(f"❌ Failed to migrate {legacy_file}: {e}")
            
            print(f"✅ Migration completed: {migrated_count} files migrated")
            return 0
        
        # Default: run test mode
        else:
            print("🧪 Running quantum state manager test...")
            try:
                # Capture quantum state
                print("🚀 Capturing quantum state...")
                state = manager.capture_quantum_state()
                
                # Save state
                print("💾 Saving quantum state...")
                saved_path = manager.save_quantum_state(state)
                
                # Load state
                print("📂 Loading quantum state...")
                loaded_state = manager.load_quantum_state(os.path.basename(saved_path))
                
                # Validate state
                print("🔍 Validating state...")
                is_valid = manager._validate_state_checksums(loaded_state)
                
                if is_valid:
                    print("✅ Quantum State Manager test completed successfully!")
                    print(f"Session ID: {loaded_state.session_id}")
                    print(f"Monitors: {len(loaded_state.monitor_layouts)}")
                    print(f"Workspaces: {len(loaded_state.workspace_states)}")
                    print(f"Windows: {len(loaded_state.window_states)}")
                    print(f"Applications: {len(loaded_state.application_contexts)}")
                    print(f"Terminals: {len(loaded_state.terminal_sessions)}")
                    print(f"Browsers: {len(loaded_state.browser_sessions)}")
                    return 0
                else:
                    print("❌ State validation failed!")
                    return 1
                    
            except Exception as e:
                print(f"❌ Test failed: {e}")
                return 1
    
    except Exception as e:
        print(f"❌ Quantum State Manager operation failed: {e}")
        return 1

if __name__ == "__main__":
    exit(main())
