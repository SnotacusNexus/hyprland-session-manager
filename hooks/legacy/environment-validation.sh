#!/usr/bin/env zsh

# 🐍 Environment Validation System for Hyprland Session Manager
# Comprehensive detection and validation of development environments
# Supports: conda, mamba, venv, pyenv environments

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[ENV-INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[ENV-SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[ENV-WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ENV-ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# =============================================================================
# 1. ENVIRONMENT DETECTION FUNCTIONS
# =============================================================================

# Detect conda environments and active environments
detect_conda_environments() {
    local env_data=()
    
    # Check if conda is available
    if command -v conda > /dev/null; then
        log_info "Detecting conda environments..."
        
        # Get active conda environment
        local active_env=$(conda info --base 2>/dev/null | xargs basename 2>/dev/null || echo "")
        if [[ -n "$active_env" ]]; then
            env_data+=("conda:$active_env:active")
            log_info "Found active conda environment: $active_env"
        fi
        
        # Get all conda environments
        if command -v jq > /dev/null; then
            local env_list=$(conda env list --json 2>/dev/null | jq -r '.envs[]' 2>/dev/null || echo "")
            for env_path in $env_list; do
                local env_name=$(basename "$env_path")
                if [[ "$env_name" != "$active_env" ]]; then
                    env_data+=("conda:$env_name:available")
                    log_info "Found conda environment: $env_name"
                fi
            done
        else
            # Fallback without jq
            local env_list=$(conda env list 2>/dev/null | grep -v "^#" | grep -v "^base" | awk '{print $1}' | grep -v "^$" || echo "")
            for env_name in $env_list; do
                if [[ "$env_name" != "$active_env" ]]; then
                    env_data+=("conda:$env_name:available")
                    log_info "Found conda environment: $env_name"
                fi
            done
        fi
    else
        log_info "Conda not available"
    fi
    
    echo "${env_data[@]}"
}

# Detect mamba environments (conda-compatible)
detect_mamba_environments() {
    local env_data=()
    
    # Check if mamba is available
    if command -v mamba > /dev/null; then
        log_info "Detecting mamba environments..."
        
        # Get active mamba environment
        local active_env=$(mamba info --base 2>/dev/null | xargs basename 2>/dev/null || echo "")
        if [[ -n "$active_env" ]]; then
            env_data+=("mamba:$active_env:active")
            log_info "Found active mamba environment: $active_env"
        fi
        
        # Get all mamba environments
        if command -v jq > /dev/null; then
            local env_list=$(mamba env list --json 2>/dev/null | jq -r '.envs[]' 2>/dev/null || echo "")
            for env_path in $env_list; do
                local env_name=$(basename "$env_path")
                if [[ "$env_name" != "$active_env" ]]; then
                    env_data+=("mamba:$env_name:available")
                    log_info "Found mamba environment: $env_name"
                fi
            done
        else
            # Fallback without jq
            local env_list=$(mamba env list 2>/dev/null | grep -v "^#" | grep -v "^base" | awk '{print $1}' | grep -v "^$" || echo "")
            for env_name in $env_list; do
                if [[ "$env_name" != "$active_env" ]]; then
                    env_data+=("mamba:$env_name:available")
                    log_info "Found mamba environment: $env_name"
                fi
            done
        fi
    else
        log_info "Mamba not available"
    fi
    
    echo "${env_data[@]}"
}

# Detect Python virtual environments
detect_venv_environments() {
    local env_data=()
    
    log_info "Detecting virtual environments..."
    
    # Check for virtual environments in common locations
    local venv_locations=(
        "$HOME/.virtualenvs"
        "$HOME/venvs"
        "$HOME/.venvs"
        "./.venv"
        "./venv"
        "../.venv"
        "../venv"
    )
    
    for location in "${venv_locations[@]}"; do
        if [[ -d "$location" ]]; then
            # Find all virtual environments in this location
            local envs=$(find "$location" -maxdepth 1 -type d -name "*" 2>/dev/null)
            for env_path in $envs; do
                if [[ -f "$env_path/bin/activate" || -f "$env_path/Scripts/activate" ]]; then
                    local env_name=$(basename "$env_path")
                    env_data+=("venv:$env_name:$env_path")
                    log_info "Found virtual environment: $env_name at $env_path"
                fi
            done
        fi
    done
    
    # Check for .venv in current and parent directories
    local current_dir=$(pwd)
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.venv" && (-f "$current_dir/.venv/bin/activate" || -f "$current_dir/.venv/Scripts/activate") ]]; then
            local env_name=$(basename "$current_dir")
            env_data+=("venv:$env_name:$current_dir/.venv")
            log_info "Found project virtual environment: $env_name at $current_dir/.venv"
            break
        fi
        current_dir=$(dirname "$current_dir")
    done
    
    echo "${env_data[@]}"
}

# Detect pyenv environments and virtual environments
detect_pyenv_environments() {
    local env_data=()
    
    # Check if pyenv is available
    if command -v pyenv > /dev/null; then
        log_info "Detecting pyenv environments..."
        
        # Get active pyenv version
        local active_version=$(pyenv version-name 2>/dev/null || echo "")
        if [[ -n "$active_version" && "$active_version" != "system" ]]; then
            env_data+=("pyenv:$active_version:active")
            log_info "Found active pyenv version: $active_version"
        fi
        
        # Get all installed pyenv versions
        local versions=$(pyenv versions --bare 2>/dev/null || echo "")
        for version in $versions; do
            if [[ "$version" != "$active_version" && "$version" != "system" ]]; then
                env_data+=("pyenv:$version:available")
                log_info "Found pyenv version: $version"
            fi
        done
        
        # Get pyenv virtual environments
        if command -v pyenv-virtualenv > /dev/null; then
            local virtualenvs=$(pyenv virtualenvs --bare 2>/dev/null || echo "")
            for virtualenv in $virtualenvs; do
                env_data+=("pyenv-virtualenv:$virtualenv:available")
                log_info "Found pyenv virtual environment: $virtualenv"
            done
        fi
    else
        log_info "Pyenv not available"
    fi
    
    echo "${env_data[@]}"
}

# Identify currently active environment
detect_active_environment() {
    local active_env=""
    
    # Check for conda environment
    if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
        active_env="conda:$CONDA_DEFAULT_ENV"
        log_info "Active conda environment detected: $CONDA_DEFAULT_ENV"
    
    # Check for virtual environment
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        local env_name=$(basename "$VIRTUAL_ENV")
        active_env="venv:$env_name"
        log_info "Active virtual environment detected: $env_name"
    
    # Check for pyenv environment
    elif [[ -n "$PYENV_VERSION" ]]; then
        active_env="pyenv:$PYENV_VERSION"
        log_info "Active pyenv version detected: $PYENV_VERSION"
    
    else
        log_info "No active development environment detected"
    fi
    
    echo "$active_env"
}

# =============================================================================
# 2. ENVIRONMENT VALIDATION FUNCTIONS
# =============================================================================

# Validate environment existence and accessibility
validate_environment_exists() {
    local env_type="$1"
    local env_name="$2"
    local env_path="$3"
    
    log_info "Validating existence of $env_type environment: $env_name"
    
    case "$env_type" in
        "conda")
            if command -v conda > /dev/null; then
                if command -v jq > /dev/null; then
                    conda env list --json | jq -e ".envs[] | select(endswith(\"$env_name\"))" > /dev/null 2>&1
                    local result=$?
                else
                    conda env list | grep -q "^$env_name\s" > /dev/null 2>&1
                    local result=$?
                fi
                if [[ $result -eq 0 ]]; then
                    log_success "Conda environment '$env_name' exists"
                    return 0
                else
                    log_error "Conda environment '$env_name' does not exist"
                    return 1
                fi
            else
                log_error "Conda not available for validation"
                return 1
            fi
            ;;
        "mamba")
            if command -v mamba > /dev/null; then
                if command -v jq > /dev/null; then
                    mamba env list --json | jq -e ".envs[] | select(endswith(\"$env_name\"))" > /dev/null 2>&1
                    local result=$?
                else
                    mamba env list | grep -q "^$env_name\s" > /dev/null 2>&1
                    local result=$?
                fi
                if [[ $result -eq 0 ]]; then
                    log_success "Mamba environment '$env_name' exists"
                    return 0
                else
                    log_error "Mamba environment '$env_name' does not exist"
                    return 1
                fi
            else
                log_error "Mamba not available for validation"
                return 1
            fi
            ;;
        "venv")
            if [[ -d "$env_path" && (-f "$env_path/bin/activate" || -f "$env_path/Scripts/activate") ]]; then
                log_success "Virtual environment '$env_name' exists at $env_path"
                return 0
            else
                log_error "Virtual environment '$env_name' does not exist at $env_path"
                return 1
            fi
            ;;
        "pyenv")
            if command -v pyenv > /dev/null; then
                pyenv versions --bare | grep -q "^$env_name$" > /dev/null 2>&1
                local result=$?
                if [[ $result -eq 0 ]]; then
                    log_success "Pyenv version '$env_name' exists"
                    return 0
                else
                    log_error "Pyenv version '$env_name' does not exist"
                    return 1
                fi
            else
                log_error "Pyenv not available for validation"
                return 1
            fi
            ;;
        "pyenv-virtualenv")
            if command -v pyenv > /dev/null && command -v pyenv-virtualenv > /dev/null; then
                pyenv virtualenvs --bare | grep -q "^$env_name$" > /dev/null 2>&1
                local result=$?
                if [[ $result -eq 0 ]]; then
                    log_success "Pyenv virtual environment '$env_name' exists"
                    return 0
                else
                    log_error "Pyenv virtual environment '$env_name' does not exist"
                    return 1
                fi
            else
                log_error "Pyenv-virtualenv not available for validation"
                return 1
            fi
            ;;
        *)
            log_error "Unknown environment type: $env_type"
            return 1
            ;;
    esac
}

# Validate environment health and functionality
validate_environment_health() {
    local env_type="$1"
    local env_name="$2"
    local env_path="$3"
    
    log_info "Validating health of $env_type environment: $env_name"
    
    case "$env_type" in
        "conda"|"mamba")
            # Test conda/mamba environment activation and basic commands
            local temp_script=$(mktemp)
            cat > "$temp_script" << 'EOF'
#!/bin/bash
source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$1"
python -c "import sys; print(f'Python {sys.version}')" > /dev/null 2>&1
exit $?
EOF
            chmod +x "$temp_script"
            "$temp_script" "$env_name"
            local result=$?
            rm -f "$temp_script"
            
            if [[ $result -eq 0 ]]; then
                log_success "$env_type environment '$env_name' is healthy"
                return 0
            else
                log_error "$env_type environment '$env_name' is unhealthy"
                return 1
            fi
            ;;
        "venv")
            # Test virtual environment activation
            local temp_script=$(mktemp)
            cat > "$temp_script" << 'EOF'
#!/bin/bash
source "$1/bin/activate"
python -c "import sys; print(f'Python {sys.version}')" > /dev/null 2>&1
exit $?
EOF
            chmod +x "$temp_script"
            "$temp_script" "$env_path"
            local result=$?
            rm -f "$temp_script"
            
            if [[ $result -eq 0 ]]; then
                log_success "Virtual environment '$env_name' is healthy"
                return 0
            else
                log_error "Virtual environment '$env_name' is unhealthy"
                return 1
            fi
            ;;
        "pyenv")
            # Test pyenv environment
            pyenv shell "$env_name" && python -c "import sys; print(f'Python {sys.version}')" > /dev/null 2>&1
            local result=$?
            
            if [[ $result -eq 0 ]]; then
                log_success "Pyenv version '$env_name' is healthy"
                return 0
            else
                log_error "Pyenv version '$env_name' is unhealthy"
                return 1
            fi
            ;;
        *)
            log_error "Health validation not supported for environment type: $env_type"
            return 1
            ;;
    esac
}

# Extract environment metadata
get_environment_metadata() {
    local env_type="$1"
    local env_name="$2"
    local env_path="$3"
    
    log_info "Extracting metadata for $env_type environment: $env_name"
    
    local metadata='{}'
    
    case "$env_type" in
        "conda"|"mamba")
            # Get conda/mamba environment metadata
            local env_info=$(conda info --envs 2>/dev/null | grep "^$env_name\s" || echo "")
            local python_version=$(conda run -n "$env_name" python --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
            
            metadata=$(jq -n \
                --arg type "$env_type" \
                --arg name "$env_name" \
                --arg path "$env_path" \
                --arg python_version "$python_version" \
                --arg status "available" \
                '{
                    type: $type,
                    name: $name,
                    path: $path,
                    python_version: $python_version,
                    status: $status,
                    validation: {
                        exists: true,
                        healthy: null,
                        last_validated: null
                    }
                }')
            ;;
        "venv")
            # Get virtual environment metadata
            local python_version=$("$env_path/bin/python" --version 2>/dev/null | cut -d' ' -f2 || echo "unknown")
            
            metadata=$(jq -n \
                --arg type "$env_type" \
                --arg name "$env_name" \
                --arg path "$env_path" \
                --arg python_version "$python_version" \
                --arg status "available" \
                '{
                    type: $type,
                    name: $name,
                    path: $path,
                    python_version: $python_version,
                    status: $status,
                    validation: {
                        exists: true,
                        healthy: null,
                        last_validated: null
                    }
                }')
            ;;
        "pyenv")
            # Get pyenv metadata
            metadata=$(jq -n \
                --arg type "$env_type" \
                --arg name "$env_name" \
                --arg path "" \
                --arg status "available" \
                '{
                    type: $type,
                    name: $name,
                    path: $path,
                    python_version: $name,
                    status: $status,
                    validation: {
                        exists: true,
                        healthy: null,
                        last_validated: null
                    }
                }')
            ;;
    esac
    
    echo "$metadata"
}

# =============================================================================

# =============================================================================
# 3. INTEGRATION AND UTILITY FUNCTIONS
# =============================================================================

# Capture all environment metadata for session save
capture_environment_metadata() {
    local env_file="${SESSION_STATE_DIR}/environment_metadata.json"
    
    log_info "Capturing environment metadata..."
    
    local env_data=()
    
    # Detect all environment types
    env_data+=($(detect_conda_environments))
    env_data+=($(detect_mamba_environments))
    env_data+=($(detect_venv_environments))
    env_data+=($(detect_pyenv_environments))
    
    # Process and save environment data
    local json_data='{"timestamp": "'$(date -Iseconds)'", "environments": ['
    local first=true
    
    for env_entry in "${env_data[@]}"; do
        IFS=':' read -r env_type env_name env_status <<< "$env_entry"
        
        if [[ "$first" == "true" ]]; then
            first=false
        else
            json_data+=','
        fi
        
        json_data+='{"type": "'$env_type'", "name": "'$env_name'", "status": "'$env_status'"}'
    done
    
    json_data+=']}'
    
    if command -v jq > /dev/null; then
        echo "$json_data" | jq '.' > "$env_file" 2>/dev/null
    else
        echo "$json_data" > "$env_file"
    fi
    
    log_success "Environment metadata captured to $env_file"
}

# Validate all environments for restoration
validate_restoration_environments() {
    local env_file="${SESSION_STATE_DIR}/environment_metadata.json"
    
    if [[ ! -f "$env_file" ]]; then
        log_info "No environment metadata found - skipping validation"
        return 0
    fi
    
    log_info "Validating environments for restoration..."
    
    local missing_envs=()
    local unhealthy_envs=()
    
    # Process each environment from saved metadata
    if command -v jq > /dev/null; then
        jq -c '.environments[]' "$env_file" 2>/dev/null | while read -r env; do
            local env_type=$(echo "$env" | jq -r '.type')
            local env_name=$(echo "$env" | jq -r '.name')
            local env_status=$(echo "$env" | jq -r '.status')
            
            # Validate environment existence
            if ! validate_environment_exists "$env_type" "$env_name" ""; then
                missing_envs+=("$env_type:$env_name")
                log_warning "Environment missing: $env_type:$env_name"
                continue
            fi
            
            # Validate environment health for active environments
            if [[ "$env_status" == "active" ]]; then
                if ! validate_environment_health "$env_type" "$env_name" ""; then
                    unhealthy_envs+=("$env_type:$env_name")
                    log_warning "Environment unhealthy: $env_type:$env_name"
                fi
            fi
        done
    fi
    
    # Report validation results
    if [[ ${#missing_envs[@]} -eq 0 && ${#unhealthy_envs[@]} -eq 0 ]]; then
        log_success "All environments validated successfully"
        return 0
    else
        log_warning "Environment validation completed with issues"
        log_info "Missing environments: ${missing_envs[*]}"
        log_info "Unhealthy environments: ${unhealthy_envs[*]}"
        return 1
    fi
}

# Enhanced terminal environment capture with development environment context
save_terminal_environment_enhanced() {
    local app_class="$1"
    local app_state_dir="${SESSION_STATE_DIR}/terminal-environments"
    
    mkdir -p "$app_state_dir"
    
    # Get terminal windows
    local terminal_windows=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .address" 2>/dev/null || echo "")
    
    for window in $terminal_windows; do
        local window_data=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$window\")" 2>/dev/null || echo "{}")
        local workspace=$(echo "$window_data" | jq -r '.workspace.id' 2>/dev/null || echo "0")
        local pid=$(echo "$window_data" | jq -r '.pid' 2>/dev/null || echo "0")
        
        # Save terminal environment data with validation
        save_terminal_state_enhanced "$app_class" "$window" "$workspace" "$pid"
    done
}

# Enhanced terminal state saving with environment validation
save_terminal_state_enhanced() {
    local app_class="$1"
    local window="$2"
    local workspace="$3"
    local pid="$4"
    
    local state_file="${SESSION_STATE_DIR}/terminal-environments/${app_class}_${window}.json"
    
    # Get current directory from process
    local current_dir=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo "")
    
    # Get environment variables
    local env_vars=""
    if [[ -f "/proc/$pid/environ" ]]; then
        env_vars=$(cat "/proc/$pid/environ" | tr '\0' '\n')
    fi
    
    # Extract development environment information
    local dev_environments="[]"
    local conda_env=$(echo "$env_vars" | grep "^CONDA_DEFAULT_ENV=" | cut -d= -f2)
    local venv_path=$(echo "$env_vars" | grep "^VIRTUAL_ENV=" | cut -d= -f2)
    local pyenv_version=$(echo "$env_vars" | grep "^PYENV_VERSION=" | cut -d= -f2)
    
    if [[ -n "$conda_env" ]]; then
        dev_environments=$(echo "$dev_environments" | jq ". += [{\"type\": \"conda\", \"name\": \"$conda_env\", \"active\": true}]" 2>/dev/null || echo "$dev_environments")
    fi
    
    if [[ -n "$venv_path" ]]; then
        local venv_name=$(basename "$venv_path")
        dev_environments=$(echo "$dev_environments" | jq ". += [{\"type\": \"venv\", \"name\": \"$venv_name\", \"path\": \"$venv_path\", \"active\": true}]" 2>/dev/null || echo "$dev_environments")
    fi
    
    if [[ -n "$pyenv_version" ]]; then
        dev_environments=$(echo "$dev_environments" | jq ". += [{\"type\": \"pyenv\", \"name\": \"$pyenv_version\", \"active\": true}]" 2>/dev/null || echo "$dev_environments")
    fi
    
    # Create enhanced terminal state file
    cat > "$state_file" << EOF
{
  "window_address": "$window",
  "workspace": $workspace,
  "current_directory": "$current_dir",
  "environment": $(echo "$env_vars" | jq -R -s 'split("\n") | map(select(. != "")) | map(split("=")) | map({(.[0]): .[1]}) | add' 2>/dev/null || echo "{}"),
  "development_environments": $dev_environments,
  "shell_pid": $pid,
  "timestamp": "$(date -Iseconds)"
}
EOF
    
    log_info "Enhanced terminal state saved for $app_class window $window"
}

# =============================================================================
# 4. MAIN FUNCTIONS FOR SESSION MANAGER INTEGRATION
# =============================================================================

# Main function to run environment validation during session save
validate_environments() {
    log_info "Starting environment validation..."
    
    # Capture environment metadata
    capture_environment_metadata
    
    # Validate all detected environments
    local env_file="${SESSION_STATE_DIR}/environment_metadata.json"
    if [[ -f "$env_file" ]]; then
        local env_count=$(jq '.environments | length' "$env_file" 2>/dev/null || echo "0")
        log_success "Environment validation completed for $env_count environments"
    else
        log_warning "No environment metadata captured"
    fi
}

# Test function to demonstrate environment detection
test_environment_detection() {
    log_info "Testing environment detection system..."
    
    echo "=== Conda Environments ==="
    detect_conda_environments
    
    echo "=== Mamba Environments ==="
    detect_mamba_environments
    
    echo "=== Virtual Environments ==="
    detect_venv_environments
    
    echo "=== Pyenv Environments ==="
    detect_pyenv_environments
    
    echo "=== Active Environment ==="
    detect_active_environment
    
    log_success "Environment detection test completed"
}

# =============================================================================
# 5. SCRIPT EXECUTION AND USAGE
# =============================================================================

# Show usage information
show_usage() {
    echo "Usage: $0 {detect|validate|test|help}"
    echo ""
    echo "Environment Validation System Commands:"
    echo "  detect    - Detect all available development environments"
    echo "  validate  - Validate environment existence and health"
    echo "  test      - Run comprehensive environment detection test"
    echo "  help      - Show this help message"
    echo ""
    echo "Integration:"
    echo "  This script is designed to be sourced by the Hyprland Session Manager"
    echo "  for automatic environment validation during session save/restore."
}

# Main execution
main() {
    local command="${1:-help}"
    
    case "$command" in
        "detect")
            test_environment_detection
            ;;
        "validate")
            validate_environments
            ;;
        "test")
            test_environment_detection
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
