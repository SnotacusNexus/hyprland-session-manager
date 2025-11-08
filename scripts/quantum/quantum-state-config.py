#!/usr/bin/env python3
"""
🚀 Quantum State Configuration Management System
Comprehensive configuration management for Hyprland Session Manager's Quantum State Manager

This module provides a flexible, user-configurable system for managing all aspects
of quantum state persistence, including auto-save intervals, application context
tracking, performance optimization, and backward compatibility settings.

Key Features:
- Comprehensive configuration schema with sensible defaults
- Multi-source configuration loading (file, environment, defaults)
- Configuration validation with type checking
- Legacy system migration capabilities
- Performance tuning parameters
- User customization for all quantum state parameters

Configuration Categories:
1. Core Quantum State Settings
2. Application Context Configuration  
3. Monitor & Workspace Settings
4. Performance & Optimization
5. Integration & Compatibility
6. Backup & Validation Settings
"""

import os
import json
import yaml
import configparser
from pathlib import Path
from typing import Dict, List, Any, Optional, Union
from dataclasses import dataclass, field, asdict
from enum import Enum
import logging

# Configure logging
logger = logging.getLogger(__name__)

class CompressionMethod(Enum):
    """Supported compression methods for state optimization"""
    NONE = "none"
    GZIP = "gzip"
    LZ4 = "lz4"
    ZSTD = "zstd"

class ValidationLevel(Enum):
    """State validation levels"""
    NONE = "none"
    BASIC = "basic"
    STRICT = "strict"
    PARANOID = "paranoid"

@dataclass
class CoreQuantumSettings:
    """
    Core quantum state management settings
    
    Controls the fundamental behavior of the quantum state manager including
    auto-save intervals, state validation, and basic operational parameters.
    """
    
    # Auto-save configuration
    auto_save_enabled: bool = True
    auto_save_interval: int = 300  # seconds
    auto_save_on_workspace_change: bool = True
    auto_save_on_window_focus: bool = False
    auto_save_on_application_launch: bool = False
    auto_save_on_application_exit: bool = False
    
    # State validation settings
    state_validation_enabled: bool = True
    validation_level: ValidationLevel = ValidationLevel.BASIC
    checksum_verification: bool = True
    integrity_check_on_load: bool = True
    integrity_check_on_save: bool = True
    
    # Session management
    session_persistence: bool = True
    session_timeout: int = 3600  # 1 hour
    max_concurrent_sessions: int = 5
    
    # Basic operational settings
    enable_logging: bool = True
    log_level: str = "INFO"
    log_file: str = "/tmp/quantum-state-manager.log"

@dataclass
class ApplicationContextSettings:
    """
    Application-specific context tracking configuration
    
    Controls which applications are monitored and how their session data
    is captured and restored.
    """
    
    # Browser session tracking
    browsers_enabled: bool = True
    browser_applications: List[str] = field(default_factory=lambda: [
        "firefox", "chrome", "chromium", "brave", "vivaldi", "opera", "edge"
    ])
    browser_session_capture: bool = True
    browser_tab_restoration: bool = True
    browser_window_restoration: bool = True
    browser_profile_detection: bool = True
    
    # Terminal session tracking
    terminals_enabled: bool = True
    terminal_applications: List[str] = field(default_factory=lambda: [
        "kitty", "alacritty", "wezterm", "gnome-terminal", "terminator", 
        "xfce4-terminal", "konsole", "tilix", "urxvt", "xterm"
    ])
    terminal_session_capture: bool = True
    terminal_environment_tracking: bool = True
    terminal_current_directory: bool = True
    terminal_command_history: bool = False
    
    # IDE session tracking
    ides_enabled: bool = True
    ide_applications: List[str] = field(default_factory=lambda: [
        "code", "vscodium", "void", "pycharm", "intellij", "webstorm",
        "clion", "rider", "phpstorm", "rubymine", "android-studio"
    ])
    ide_workspace_capture: bool = True
    ide_open_files_capture: bool = True
    ide_project_structure: bool = False
    
    # Creative application tracking
    creative_enabled: bool = True
    creative_applications: List[str] = field(default_factory=lambda: [
        "krita", "gimp", "blender", "inkscape", "darktable", "rawtherapee",
        "shotcut", "kdenlive", "audacity", "ardour", "musescore"
    ])
    creative_document_capture: bool = True
    creative_workspace_layout: bool = True
    creative_tool_settings: bool = False
    
    # Development environment tracking
    development_environments_enabled: bool = True
    track_conda_environments: bool = True
    track_virtual_environments: bool = True
    track_pyenv_environments: bool = True
    track_node_environments: bool = True
    track_rust_environments: bool = True
    track_go_environments: bool = True

@dataclass
class MonitorWorkspaceSettings:
    """
    Monitor and workspace configuration settings
    
    Controls how monitor layouts, workspace states, and window arrangements
    are captured and restored.
    """
    
    # Monitor layout persistence
    monitor_detection_enabled: bool = True
    monitor_layout_capture: bool = True
    monitor_resolution_tracking: bool = True
    monitor_scale_tracking: bool = True
    monitor_position_tracking: bool = True
    monitor_refresh_rate_tracking: bool = True
    
    # Workspace state management
    workspace_persistence_enabled: bool = True
    workspace_layout_capture: bool = True
    workspace_window_arrangement: bool = True
    workspace_focus_history: bool = True
    workspace_special_workspaces: bool = True
    
    # Window state tracking
    window_state_capture: bool = True
    window_position_tracking: bool = True
    window_size_tracking: bool = True
    window_focus_state: bool = True
    window_fullscreen_state: bool = True
    window_floating_state: bool = True
    window_pinned_state: bool = True
    
    # Hyprland-specific settings
    hyprland_integration: bool = True
    hyprland_event_monitoring: bool = True
    hyprland_workspace_rules: bool = True
    hyprland_window_rules: bool = True

@dataclass
class PerformanceOptimizationSettings:
    """
    Performance and optimization configuration
    
    Controls performance tuning, state compression, memory usage limits,
    and processing timeouts for large state captures.
    """
    
    # Performance optimization
    performance_optimization_enabled: bool = True
    state_compression_enabled: bool = True
    compression_method: CompressionMethod = CompressionMethod.GZIP
    compression_level: int = 6
    
    # Memory management
    max_memory_usage_mb: int = 512
    memory_cleanup_interval: int = 60  # seconds
    cache_enabled: bool = True
    cache_size_mb: int = 100
    
    # Processing limits
    max_processing_time_seconds: int = 30
    large_state_threshold_mb: int = 50
    parallel_processing_enabled: bool = True
    max_parallel_processes: int = 4
    
    # State optimization
    remove_redundant_data: bool = True
    optimize_application_contexts: bool = True
    optimize_terminal_sessions: bool = True
    optimize_browser_sessions: bool = True
    compress_system_state: bool = True
    
    # Resource usage
    cpu_usage_limit_percent: int = 80
    disk_io_limit_mbps: int = 100
    network_bandwidth_limit_mbps: int = 10

@dataclass
class BackupValidationSettings:
    """
    Backup management and validation configuration
    
    Controls backup creation, retention policies, and state validation
    procedures.
    """
    
    # Backup management
    backup_enabled: bool = True
    max_backups: int = 10
    backup_retention_days: int = 30
    backup_compression: bool = True
    incremental_backups: bool = True
    
    # Backup triggers
    backup_on_state_save: bool = True
    backup_on_config_change: bool = True
    backup_on_system_startup: bool = False
    backup_on_system_shutdown: bool = False
    
    # Validation settings
    validate_on_save: bool = True
    validate_on_load: bool = True
    validate_checksums: bool = True
    validate_integrity: bool = True
    validate_compatibility: bool = True
    
    # Recovery options
    auto_recovery_enabled: bool = True
    recovery_attempts: int = 3
    fallback_to_last_good_state: bool = True

@dataclass
class IntegrationCompatibilitySettings:
    """
    Integration and compatibility configuration
    
    Controls integration with other systems, backward compatibility,
    and migration from legacy session manager settings.
    """
    
    # Hyprland integration
    hyprland_integration_enabled: bool = True
    hyprland_socket_monitoring: bool = True
    hyprland_event_handling: bool = True
    hyprland_config_sync: bool = True
    
    # Backward compatibility
    backward_compatibility_enabled: bool = True
    legacy_session_migration: bool = True
    legacy_format_support: bool = True
    migration_auto_detect: bool = True
    
    # System integration
    systemd_integration: bool = True
    dbus_integration: bool = False
    x11_integration: bool = True
    wayland_integration: bool = True
    
    # External tool integration
    external_tools_enabled: bool = True
    wmctrl_support: bool = True
    xdotool_support: bool = True
    wlr_randr_support: bool = True
    
    # File format compatibility
    json_format_enabled: bool = True
    yaml_format_enabled: bool = True
    binary_format_enabled: bool = False

@dataclass
class QuantumConfiguration:
    """
    Complete quantum state configuration
    
    Aggregates all configuration categories into a single comprehensive
    configuration object with validation and loading capabilities.
    """
    
    # Configuration metadata
    config_version: str = "1.0.0"
    config_schema: str = "quantum-state-v1"
    
    # Configuration categories
    core: CoreQuantumSettings = field(default_factory=CoreQuantumSettings)
    applications: ApplicationContextSettings = field(default_factory=ApplicationContextSettings)
    monitor_workspace: MonitorWorkspaceSettings = field(default_factory=MonitorWorkspaceSettings)
    performance: PerformanceOptimizationSettings = field(default_factory=PerformanceOptimizationSettings)
    backup: BackupValidationSettings = field(default_factory=BackupValidationSettings)
    integration: IntegrationCompatibilitySettings = field(default_factory=IntegrationCompatibilitySettings)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary with Enum serialization"""
        def serialize_enums(obj):
            if isinstance(obj, Enum):
                return obj.value
            elif isinstance(obj, dict):
                return {k: serialize_enums(v) for k, v in obj.items()}
            elif isinstance(obj, list):
                return [serialize_enums(item) for item in obj]
            else:
                return obj
        
        config_dict = asdict(self)
        return serialize_enums(config_dict)
    
    def to_json(self) -> str:
        """Convert configuration to JSON string"""
        return json.dumps(self.to_dict(), indent=2, ensure_ascii=False)
    
    def validate(self) -> bool:
        """Validate configuration integrity"""
        try:
            # Core settings validation
            if self.core.auto_save_interval < 10:
                logger.warning("Auto-save interval too short, minimum is 10 seconds")
                return False
            
            if self.core.max_concurrent_sessions < 1:
                logger.warning("Max concurrent sessions must be at least 1")
                return False
            
            # Performance settings validation
            if self.performance.max_memory_usage_mb < 64:
                logger.warning("Max memory usage too low, minimum is 64MB")
                return False
            
            if self.performance.max_processing_time_seconds < 5:
                logger.warning("Max processing time too short, minimum is 5 seconds")
                return False
            
            # Backup settings validation
            if self.backup.max_backups < 1:
                logger.warning("Max backups must be at least 1")
                return False
            
            # All validations passed
            return True
            
        except Exception as e:
            logger.error(f"Configuration validation failed: {e}")
            return False
    
    def merge_with(self, other_config: Dict[str, Any]) -> 'QuantumConfiguration':
        """Merge with another configuration dictionary"""
        try:
            # Create a copy of current configuration as dict
            current_dict = self.to_dict()
            
            # Deep merge the configurations
            merged_dict = self._deep_merge(current_dict, other_config)
            
            # Create new configuration from merged dict
            return QuantumConfiguration.from_dict(merged_dict)
            
        except Exception as e:
            logger.error(f"Configuration merge failed: {e}")
            return self
    
    @staticmethod
    def _deep_merge(base: Dict[str, Any], update: Dict[str, Any]) -> Dict[str, Any]:
        """Deep merge two dictionaries"""
        result = base.copy()
        
        for key, value in update.items():
            if (key in result and isinstance(result[key], dict) and 
                isinstance(value, dict)):
                result[key] = QuantumConfiguration._deep_merge(result[key], value)
            else:
                result[key] = value
        
        return result
    
    @classmethod
    def from_dict(cls, config_dict: Dict[str, Any]) -> 'QuantumConfiguration':
        """Create configuration from dictionary"""
        try:
            # Convert nested dictionaries to appropriate dataclasses
            core_dict = config_dict.get('core', {})
            applications_dict = config_dict.get('applications', {})
            monitor_workspace_dict = config_dict.get('monitor_workspace', {})
            performance_dict = config_dict.get('performance', {})
            backup_dict = config_dict.get('backup', {})
            integration_dict = config_dict.get('integration', {})
            
            # Create configuration object
            config = cls(
                config_version=config_dict.get('config_version', '1.0.0'),
                config_schema=config_dict.get('config_schema', 'quantum-state-v1'),
                core=CoreQuantumSettings(**core_dict),
                applications=ApplicationContextSettings(**applications_dict),
                monitor_workspace=MonitorWorkspaceSettings(**monitor_workspace_dict),
                performance=PerformanceOptimizationSettings(**performance_dict),
                backup=BackupValidationSettings(**backup_dict),
                integration=IntegrationCompatibilitySettings(**integration_dict)
            )
            
            return config
            
        except Exception as e:
            logger.error(f"Failed to create configuration from dict: {e}")
            # Return default configuration on failure
            return cls()
    
    @classmethod
    def from_json(cls, json_str: str) -> 'QuantumConfiguration':
        """Create configuration from JSON string"""
        try:
            config_dict = json.loads(json_str)
            return cls.from_dict(config_dict)
        except Exception as e:
            logger.error(f"Failed to parse configuration JSON: {e}")
            return cls()
    
    @classmethod
    def from_yaml(cls, yaml_str: str) -> 'QuantumConfiguration':
        """Create configuration from YAML string"""
        try:
            config_dict = yaml.safe_load(yaml_str)
            return cls.from_dict(config_dict)
        except Exception as e:
            logger.error(f"Failed to parse configuration YAML: {e}")
            return cls()

class QuantumConfigManager:
    """
    Quantum Configuration Manager
    
    Handles loading, saving, and managing quantum state configurations
    from multiple sources including files, environment variables, and defaults.
    """
    
    def __init__(self, config_dir: str = None):
        self.config_dir = config_dir or os.path.expanduser("~/.config/hyprland-session-manager")
        self.config_file = os.path.join(self.config_dir, "quantum-state-config.json")
        self.legacy_config_file = os.path.join(self.config_dir, "session-manager-config.json")
        
        # Create config directory if it doesn't exist
        Path(self.config_dir).mkdir(parents=True, exist_ok=True)
        
        logger.info(f"Quantum Config Manager initialized: {self.config_dir}")
    
    def load_configuration(self) -> QuantumConfiguration:
        """
        Load configuration from multiple sources with fallback
        
        Loading order:
        1. User configuration file
        2. Environment variables
        3. Legacy configuration migration
        4. Default configuration
        """
        config = QuantumConfiguration()
        
        # 1. Load from user configuration file
        file_config = self._load_from_file()
        if file_config:
            config = config.merge_with(file_config)
            logger.info("Loaded configuration from file")
        
        # 2. Load from environment variables
        env_config = self._load_from_environment()
        if env_config:
            config = config.merge_with(env_config)
            logger.info("Loaded configuration from environment")
        
        # 3. Migrate from legacy configuration
        legacy_config = self._migrate_legacy_config()
        if legacy_config:
            config = config.merge_with(legacy_config)
            logger.info("Migrated configuration from legacy system")
        
        # 4. Validate final configuration
        if not config.validate():
            logger.warning("Configuration validation failed, using defaults")
            return QuantumConfiguration()
        
        logger.info("Configuration loaded successfully")
        return config
    
    def save_configuration(self, config: QuantumConfiguration) -> bool:
        """Save configuration to file"""
        try:
            # Validate before saving
            if not config.validate():
                logger.error("Cannot save invalid configuration")
                return False
            
            # Convert to JSON and save
            config_json = config.to_json()
            with open(self.config_file, 'w') as f:
                f.write(config_json)
            
            logger.info(f"Configuration saved: {self.config_file}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to save configuration: {e}")
            return False
    
    def _load_from_file(self) -> Optional[Dict[str, Any]]:
        """Load configuration from file"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r') as f:
                    config_data = json.load(f)
                return config_data
            
            # Also check for YAML configuration
            yaml_config_file = self.config_file.replace('.json', '.yaml')
            if os.path.exists(yaml_config_file):
                with open(yaml_config_file, 'r') as f:
                    config_data = yaml.safe_load(f)
                return config_data
            
        except Exception as e:
            logger.warning(f"Failed to load configuration from file: {e}")
        
        return None
    
    def _load_from_environment(self) -> Dict[str, Any]:
        """Load configuration from environment variables"""
        env_config = {}
        
        try:
            # Core settings from environment
            if os.getenv('QUANTUM_AUTO_SAVE_INTERVAL'):
                env_config.setdefault('core', {})['auto_save_interval'] = int(os.getenv('QUANTUM_AUTO_SAVE_INTERVAL'))
            
            if os.getenv('QUANTUM_STATE_VALIDATION'):
                env_config.setdefault('core', {})['state_validation_enabled'] = os.getenv('QUANTUM_STATE_VALIDATION').lower() == 'true'
            
            if os.getenv('QUANTUM_LOG_LEVEL'):
                env_config.setdefault('core', {})['log_level'] = os.getenv('QUANTUM_LOG_LEVEL')
            
            # Performance settings from environment
            if os.getenv('QUANTUM_MAX_MEMORY_MB'):
                env_config.setdefault('performance', {})['max_memory_usage_mb'] = int(os.getenv('QUANTUM_MAX_MEMORY_MB'))
            
            if os.getenv('QUANTUM_COMPRESSION_METHOD'):
                env_config.setdefault('performance', {})['compression_method'] = os.getenv('QUANTUM_COMPRESSION_METHOD')
            
            # Application settings from environment
            if os.getenv('QUANTUM_BROWSERS_ENABLED'):
                env_config.setdefault('applications', {})['browsers_enabled'] = os.getenv('QUANTUM_BROWSERS_ENABLED').lower() == 'true'
            
            if os.getenv('QUANTUM_TERMINALS_ENABLED'):
                env_config.setdefault('applications', {})['terminals_enabled'] = os.getenv('QUANTUM_TERMINALS_ENABLED').lower() == 'true'
            
            # Parse browser applications from environment
            if os.getenv('QUANTUM_BROWSER_APPLICATIONS'):
                browsers = os.getenv('QUANTUM_BROWSER_APPLICATIONS').split(',')
                env_config.setdefault('applications', {})['browser_applications'] = [b.strip() for b in browsers]
            
            # Parse terminal applications from environment
            if os.getenv('QUANTUM_TERMINAL_APPLICATIONS'):
                terminals = os.getenv('QUANTUM_TERMINAL_APPLICATIONS').split(',')
                env_config.setdefault('applications', {})['terminal_applications'] = [t.strip() for t in terminals]
            
        except Exception as e:
            logger.warning(f"Failed to parse environment configuration: {e}")
        
        return env_config
    
    def _migrate_legacy_config(self) -> Optional[Dict[str, Any]]:
        """Migrate configuration from legacy session manager"""
        try:
            if not os.path.exists(self.legacy_config_file):
                return None
            
            with open(self.legacy_config_file, 'r') as f:
                legacy_config = json.load(f)
            
            # Convert legacy format to quantum format
            quantum_config = {}
            
            # Migrate core settings
            if 'auto_save_interval' in legacy_config:
                quantum_config.setdefault('core', {})['auto_save_interval'] = legacy_config['auto_save_interval']
            
            if 'max_backups' in legacy_config:
                quantum_config.setdefault('backup', {})['max_backups'] = legacy_config['max_backups']
            
            if 'state_validation' in legacy_config:
                quantum_config.setdefault('core', {})['state_validation_enabled'] = legacy_config['state_validation']
            
            # Migrate application contexts
            if 'application_contexts' in legacy_config:
                legacy_apps = legacy_config['application_contexts']
                
                # Migrate browsers
                if 'browsers' in legacy_apps:
                    quantum_config.setdefault('applications', {})['browser_applications'] = legacy_apps['browsers']
                
                # Migrate terminals
                if 'terminals' in legacy_apps:
                    quantum_config.setdefault('applications', {})['terminal_applications'] = legacy_apps['terminals']
                
                # Migrate IDEs
                if 'ides' in legacy_apps:
                    quantum_config.setdefault('applications', {})['ide_applications'] = legacy_apps['ides']
            
            # Migrate performance settings
            if 'performance_optimization' in legacy_config:
                quantum_config.setdefault('performance', {})['performance_optimization_enabled'] = legacy_config['performance_optimization']
            
            logger.info("Successfully migrated legacy configuration")
            return quantum_config
            
        except Exception as e:
            logger.warning(f"Legacy configuration migration failed: {e}")
            return None
    
    def create_default_config(self) -> QuantumConfiguration:
        """Create and save default configuration"""
        default_config = QuantumConfiguration()
        
        if self.save_configuration(default_config):
            logger.info(f"Default configuration created: {self.config_file}")
        else:
            logger.error("Failed to create default configuration")
        
        return default_config
    
    def get_config_info(self) -> Dict[str, Any]:
        """Get configuration information and status"""
        info = {
            'config_file': self.config_file,
            'config_dir': self.config_dir,
            'file_exists': os.path.exists(self.config_file),
            'legacy_config_exists': os.path.exists(self.legacy_config_file),
            'file_size': 0,
            'last_modified': None
        }
        
        if info['file_exists']:
            try:
                stat = os.stat(self.config_file)
                info['file_size'] = stat.st_size
                info['last_modified'] = stat.st_mtime
            except Exception as e:
                logger.warning(f"Failed to get file stats: {e}")
        
        return info

# Global configuration instance
QUANTUM_CONFIG: QuantumConfiguration = None

def load_quantum_config(config_dir: str = None) -> QuantumConfiguration:
    """Load quantum configuration (global function for compatibility)"""
    global QUANTUM_CONFIG
    
    if QUANTUM_CONFIG is None:
        config_manager = QuantumConfigManager(config_dir)
        QUANTUM_CONFIG = config_manager.load_configuration()
    
    return QUANTUM_CONFIG

def save_quantum_config(config: QuantumConfiguration, config_dir: str = None) -> bool:
    """Save quantum configuration (global function for compatibility)"""
    global QUANTUM_CONFIG
    
    config_manager = QuantumConfigManager(config_dir)
    success = config_manager.save_configuration(config)
    
    if success:
        QUANTUM_CONFIG = config
    
    return success

def get_quantum_config() -> QuantumConfiguration:
    """Get current quantum configuration"""
    global QUANTUM_CONFIG
    
    if QUANTUM_CONFIG is None:
        return load_quantum_config()
    
    return QUANTUM_CONFIG

def main():
    """Main function for testing the configuration system"""
    print("🚀 Testing Quantum State Configuration System...")
    
    # Test configuration loading
    config_manager = QuantumConfigManager()
    config = config_manager.load_configuration()
    
    print("✅ Configuration loaded successfully")
    print(f"Config version: {config.config_version}")
    print(f"Auto-save interval: {config.core.auto_save_interval}s")
    print(f"Browsers enabled: {config.applications.browsers_enabled}")
    print(f"Terminals enabled: {config.applications.terminals_enabled}")
    print(f"Performance optimization: {config.performance.performance_optimization_enabled}")
    
    # Test configuration validation
    if config.validate():
        print("✅ Configuration validation passed")
    else:
        print("❌ Configuration validation failed")
    
    # Test configuration saving
    if config_manager.save_configuration(config):
        print("✅ Configuration saved successfully")
    else:
        print("❌ Configuration save failed")
    
    # Test configuration info
    info = config_manager.get_config_info()
    print(f"Config file: {info['config_file']}")
    print(f"File exists: {info['file_exists']}")
    print(f"Legacy config exists: {info['legacy_config_exists']}")
    
    print("🎉 Configuration system test completed!")

if __name__ == "__main__":
    main()