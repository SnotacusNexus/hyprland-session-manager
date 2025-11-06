#!/usr/bin/env zsh

# Krita Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for Krita document and session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[Krita HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if Krita is running
is_krita_running() {
    # Support multiple Krita variants and installation methods
    if pgrep -x "krita" > /dev/null || \
       pgrep -f "krita-bin" > /dev/null || \
       pgrep -f "org.kde.krita" > /dev/null || \
       pgrep -f "flatpak.*krita" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get Krita window class
get_krita_class() {
    # Krita can have different window classes depending on the distribution and installation method
    local krita_classes=("krita" "Krita" "org.kde.krita")
    
    for class in "${krita_classes[@]}"; do
        if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
            if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
                echo "$class"
                return 0
            fi
        fi
    done
    
    # Default fallback
    echo "krita"
}

# Find Krita configuration and data directories
find_krita_dirs() {
    local krita_dirs=()
    
    # Standard XDG locations
    if [[ -d "${HOME}/.config/krita" ]]; then
        krita_dirs+=("${HOME}/.config/krita")
    fi
    
    if [[ -d "${HOME}/.local/share/krita" ]]; then
        krita_dirs+=("${HOME}/.local/share/krita")
    fi
    
    # Flatpak installation
    if [[ -d "${HOME}/.var/app/org.kde.krita" ]]; then
        krita_dirs+=("${HOME}/.var/app/org.kde.krita")
    fi
    
    # Snap installation
    if [[ -d "${HOME}/snap/krita" ]]; then
        krita_dirs+=("${HOME}/snap/krita")
    fi
    
    echo "${krita_dirs[@]}"
}

# Save Krita session configuration
save_krita_config() {
    local app_state_dir="$1"
    
    log_info "Saving Krita configuration data..."
    
    # Save main configuration file
    local kritarc="${HOME}/.config/kritarc"
    if [[ -f "$kritarc" ]]; then
        cp "$kritarc" "${app_state_dir}/kritarc" 2>/dev/null || true
        log_info "Saved kritarc configuration"
    else
        log_warning "kritarc configuration file not found"
    fi
    
    # Save session-specific configuration
    local krita_config="${HOME}/.config/krita"
    if [[ -d "$krita_config" ]]; then
        # Save recent documents list
        if [[ -f "${krita_config}/recentdocuments" ]]; then
            cp "${krita_config}/recentdocuments" "${app_state_dir}/recentdocuments" 2>/dev/null || true
        fi
        
        # Save session files
        find "$krita_config" -name "*session*" -o -name "*recent*" > "${app_state_dir}/config_files.txt" 2>/dev/null
    fi
}

# Save Krita document and autosave data
save_krita_documents() {
    local app_state_dir="$1"
    
    log_info "Saving Krita document and autosave data..."
    
    local krita_data="${HOME}/.local/share/krita"
    if [[ -d "$krita_data" ]]; then
        # Save autosave directory structure
        local autosave_dir="${krita_data}/autosave"
        if [[ -d "$autosave_dir" ]]; then
            log_info "Found autosave directory: $autosave_dir"
            
            # List autosave files
            find "$autosave_dir" -name "*.kra" -o -name "*.ora" -o -name "*.png" > "${app_state_dir}/autosave_files.txt" 2>/dev/null
            
            # Save autosave file metadata
            if [[ -f "${app_state_dir}/autosave_files.txt" ]]; then
                local autosave_count=$(wc -l < "${app_state_dir}/autosave_files.txt" 2>/dev/null || echo "0")
                log_info "Found $autosave_count autosave files"
            fi
        else
            log_warning "No autosave directory found"
        fi
        
        # Save recent documents information
        local recent_docs="${krita_data}/recentdocuments"
        if [[ -d "$recent_docs" ]]; then
            find "$recent_docs" -type f > "${app_state_dir}/recent_documents.txt" 2>/dev/null
        fi
        
        # Save brush presets and resources
        local resources_dir="${krita_data}/resources"
        if [[ -d "$resources_dir" ]]; then
            find "$resources_dir" -name "*.kpp" -o -name "*.bundle" > "${app_state_dir}/resource_files.txt" 2>/dev/null
        fi
    else
        log_warning "Krita data directory not found: $krita_data"
    fi
}

# Save Krita session data
save_krita_session() {
    local app_class="$(get_krita_class)"
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    
    log_info "Saving Krita session data..."
    
    # Create application state directory
    mkdir -p "$app_state_dir"
    
    # Save window information
    if command -v hyprctl > /dev/null && command -v jq > /dev/null; then
        # Save window titles (which contain document names)
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | .title" > "${app_state_dir}/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)\"" > "${app_state_dir}/positions.txt" 2>/dev/null
        
        # Save workspace assignments
        hyprctl clients -j | jq -r ".[] | select(.class == \"$app_class\") | \"\(.workspace.id):\(.address)\"" > "${app_state_dir}/workspaces.txt" 2>/dev/null
    fi
    
    # Save Krita configuration and document data
    save_krita_config "$app_state_dir"
    save_krita_documents "$app_state_dir"
    
    # Save process information
    pgrep -f "krita" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save Krita installation information
    local krita_variant="unknown"
    if command -v krita > /dev/null; then
        krita_variant="system"
    elif command -v flatpak > /dev/null && flatpak list --app | grep -q "org.kde.krita"; then
        krita_variant="flatpak"
    elif [[ -d "/snap/krita" ]] || command -v snap > /dev/null && snap list | grep -q "krita"; then
        krita_variant="snap"
    fi
    echo "$krita_variant" > "${app_state_dir}/krita_variant.txt"
    
    log_success "Krita session data saved"
}

# Create Krita session summary
create_krita_summary() {
    local app_class="$(get_krita_class)"
    local app_state_dir="${SESSION_STATE_DIR}/krita"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating Krita session summary..."
    
    echo "Krita Session Summary - $(date)" > "$summary_file"
    echo "================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open Krita windows: $window_count" >> "$summary_file"
    
    # Window titles (document names)
    if [[ -f "${app_state_dir}/window_titles.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Window titles (documents):" >> "$summary_file"
        cat "${app_state_dir}/window_titles.txt" | head -10 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Workspace distribution
    if [[ -f "${app_state_dir}/workspaces.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Workspace distribution:" >> "$summary_file"
        cat "${app_state_dir}/workspaces.txt" | sort | uniq -c | sed 's/^/  /' >> "$summary_file" 2>/dev/null
    fi
    
    # Krita variant
    if [[ -f "${app_state_dir}/krita_variant.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Krita variant: $(cat "${app_state_dir}/krita_variant.txt")" >> "$summary_file"
    fi
    
    # Autosave file count
    if [[ -f "${app_state_dir}/autosave_files.txt" ]]; then
        local autosave_count=$(wc -l < "${app_state_dir}/autosave_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Autosave files: $autosave_count" >> "$summary_file"
    fi
    
    # Configuration directories found
    local krita_dirs=($(find_krita_dirs))
    if [[ ${#krita_dirs[@]} -gt 0 ]]; then
        echo "" >> "$summary_file"
        echo "Configuration directories:" >> "$summary_file"
        for dir in "${krita_dirs[@]}"; do
            echo "  - $(basename "$dir")" >> "$summary_file"
        done
    fi
    
    log_success "Krita session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting Krita pre-save hook..."
    
    if is_krita_running; then
        save_krita_session
        create_krita_summary
        log_success "Krita pre-save hook completed"
    else
        log_info "Krita not running - nothing to save"
    fi
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

# Determine if this is pre-save or post-restore hook
case "${1}" in
    "pre-save")
        pre_save_main
        ;;
    "post-restore")
        log_info "Krita post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac