#!/usr/bin/env zsh

# LibreOffice Session Management Hook
# Community contributed by: Hyprland Session Manager Team
# Pre-save hook for LibreOffice document and session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[LibreOffice HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# ============================================================================
# PRE-SAVE HOOK FUNCTIONS
# ============================================================================

# Detect if LibreOffice is running
is_libreoffice_running() {
    # Support multiple LibreOffice variants and components
    if pgrep -x "soffice" > /dev/null || \
       pgrep -x "libreoffice" > /dev/null || \
       pgrep -f "soffice.bin" > /dev/null || \
       pgrep -f "libreoffice.*writer" > /dev/null || \
       pgrep -f "libreoffice.*calc" > /dev/null || \
       pgrep -f "libreoffice.*impress" > /dev/null || \
       pgrep -f "libreoffice.*draw" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get LibreOffice window class
get_libreoffice_class() {
    # LibreOffice can have different window classes depending on the component
    local libreoffice_classes=("libreoffice" "LibreOffice" "soffice" "libreoffice-writer" "libreoffice-calc" "libreoffice-impress" "libreoffice-draw")
    
    for class in "${libreoffice_classes[@]}"; do
        if hyprctl clients -j | jq -r ".[] | .class" 2>/dev/null | grep -q "$class"; then
            echo "$class"
            return 0
        fi
    done
    
    # Default fallback
    echo "libreoffice"
}

# Find LibreOffice configuration directories
find_libreoffice_configs() {
    local config_dirs=()
    
    # Standard LibreOffice configuration
    if [[ -d "${HOME}/.config/libreoffice" ]]; then
        config_dirs+=("${HOME}/.config/libreoffice")
    fi
    
    # Alternative locations (older versions)
    if [[ -d "${HOME}/.libreoffice" ]]; then
        config_dirs+=("${HOME}/.libreoffice")
    fi
    
    # Flatpak location
    if [[ -d "${HOME}/.var/app/org.libreoffice.LibreOffice/config/libreoffice" ]]; then
        config_dirs+=("${HOME}/.var/app/org.libreoffice.LibreOffice/config/libreoffice")
    fi
    
    # Snap location
    if [[ -d "${HOME}/snap/libreoffice/current/.config/libreoffice" ]]; then
        config_dirs+=("${HOME}/snap/libreoffice/current/.config/libreoffice")
    fi
    
    echo "${config_dirs[@]}"
}

# Save LibreOffice registry modifications
save_libreoffice_registry() {
    local app_state_dir="$1"
    local config_dirs=($(find_libreoffice_configs))
    
    log_info "Saving LibreOffice registry modifications..."
    
    for config_dir in "${config_dirs[@]}"; do
        # Look for registrymodifications.xcu in various locations
        local registry_files=()
        
        # Check for user registry modifications
        if [[ -d "$config_dir" ]]; then
            find "$config_dir" -name "registrymodifications.xcu" -type f > "${app_state_dir}/registry_files.txt" 2>/dev/null
            
            # Save the actual registry files
            while IFS= read -r registry_file; do
                if [[ -f "$registry_file" ]]; then
                    local relative_path=$(echo "$registry_file" | sed "s|${HOME}/||")
                    local safe_name=$(echo "$relative_path" | sed 's|/|_|g' | sed 's/\./_/g')
                    cp "$registry_file" "${app_state_dir}/registry_${safe_name}" 2>/dev/null || true
                    log_info "Saved registry file: $registry_file"
                fi
            done < "${app_state_dir}/registry_files.txt"
        fi
    done
}

# Save LibreOffice recovery and autosave files
save_libreoffice_recovery_files() {
    local app_state_dir="$1"
    
    log_info "Saving LibreOffice recovery and autosave files..."
    
    # Look for recovery files in standard locations
    local recovery_locations=(
        "${HOME}/.local/share/libreoffice"
        "${HOME}/.cache/libreoffice"
        "${HOME}/.var/app/org.libreoffice.LibreOffice/cache/libreoffice"
        "${HOME}/snap/libreoffice/current/.cache/libreoffice"
    )
    
    for location in "${recovery_locations[@]}"; do
        if [[ -d "$location" ]]; then
            # Find recovery and autosave files
            find "$location" \( -name "*recovery*" -o -name "*autosave*" -o -name "*backup*" \) -type f > "${app_state_dir}/recovery_files_$(basename "$location").txt" 2>/dev/null
            
            # Save file information (not the files themselves to avoid corruption)
            if [[ -f "${app_state_dir}/recovery_files_$(basename "$location").txt" ]]; then
                local file_count=$(wc -l < "${app_state_dir}/recovery_files_$(basename "$location").txt" 2>/dev/null || echo "0")
                log_info "Found $file_count recovery files in $location"
            fi
        fi
    done
}

# Save LibreOffice recent documents
save_libreoffice_recent_documents() {
    local app_state_dir="$1"
    local config_dirs=($(find_libreoffice_configs))
    
    log_info "Saving LibreOffice recent documents list..."
    
    for config_dir in "${config_dirs[@]}"; do
        # Look for recent documents in registry or configuration
        local recent_files=()
        
        # Check for registrymodifications.xcu which contains recent files
        local registry_file=$(find "$config_dir" -name "registrymodifications.xcu" -type f | head -1)
        if [[ -f "$registry_file" ]]; then
            # Extract recent documents from registry file
            if command -v xmllint > /dev/null; then
                xmllint --xpath "//item[@oor:path='/org.openoffice.Office.Common/History/Histories']/node/prop[@oor:name='PickList']/value/text()" "$registry_file" 2>/dev/null | \
                    sed 's/"/"/g' | grep -o '[^"]*\.od[tsgp]' > "${app_state_dir}/recent_documents.txt" 2>/dev/null || true
            fi
        fi
        
        # Also look for any session or history files
        find "$config_dir" -name "*history*" -o -name "*recent*" -o -name "*session*" > "${app_state_dir}/history_files.txt" 2>/dev/null
    done
}

# Save LibreOffice session data
save_libreoffice_session() {
    local app_class="$(get_libreoffice_class)"
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    
    log_info "Saving LibreOffice session data..."
    
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
    
    # Save LibreOffice configuration and session data
    save_libreoffice_registry "$app_state_dir"
    save_libreoffice_recovery_files "$app_state_dir"
    save_libreoffice_recent_documents "$app_state_dir"
    
    # Save process information
    pgrep -f "soffice\|libreoffice" > "${app_state_dir}/processes.txt" 2>/dev/null
    
    # Save LibreOffice variant information
    local libreoffice_variant="unknown"
    if command -v soffice > /dev/null; then
        libreoffice_variant="soffice"
    elif command -v libreoffice > /dev/null; then
        libreoffice_variant="libreoffice"
    fi
    echo "$libreoffice_variant" > "${app_state_dir}/libreoffice_variant.txt"
    
    # Save component information
    local components=()
    if pgrep -f "writer" > /dev/null; then components+=("writer"); fi
    if pgrep -f "calc" > /dev/null; then components+=("calc"); fi
    if pgrep -f "impress" > /dev/null; then components+=("impress"); fi
    if pgrep -f "draw" > /dev/null; then components+=("draw"); fi
    printf "%s\n" "${components[@]}" > "${app_state_dir}/components.txt" 2>/dev/null
    
    log_success "LibreOffice session data saved"
}

# Create LibreOffice session summary
create_libreoffice_summary() {
    local app_class="$(get_libreoffice_class)"
    local app_state_dir="${SESSION_STATE_DIR}/libreoffice"
    local summary_file="${app_state_dir}/session_summary.txt"
    
    log_info "Creating LibreOffice session summary..."
    
    echo "LibreOffice Session Summary - $(date)" > "$summary_file"
    echo "==================================" >> "$summary_file"
    
    # Window count
    local window_count=$(hyprctl clients -j | jq "[.[] | select(.class == \"$app_class\")] | length" 2>/dev/null || echo "0")
    echo "Open LibreOffice windows: $window_count" >> "$summary_file"
    
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
    
    # LibreOffice variant
    if [[ -f "${app_state_dir}/libreoffice_variant.txt" ]]; then
        echo "" >> "$summary_file"
        echo "LibreOffice variant: $(cat "${app_state_dir}/libreoffice_variant.txt")" >> "$summary_file"
    fi
    
    # Components in use
    if [[ -f "${app_state_dir}/components.txt" ]]; then
        echo "" >> "$summary_file"
        echo "Active components:" >> "$summary_file"
        cat "${app_state_dir}/components.txt" | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    # Registry files found
    if [[ -f "${app_state_dir}/registry_files.txt" ]]; then
        local registry_count=$(wc -l < "${app_state_dir}/registry_files.txt" 2>/dev/null || echo "0")
        echo "" >> "$summary_file"
        echo "Registry files: $registry_count" >> "$summary_file"
    fi
    
    # Recovery files found
    local total_recovery_files=0
    for recovery_file in "${app_state_dir}"/recovery_files_*.txt; do
        if [[ -f "$recovery_file" ]]; then
            local count=$(wc -l < "$recovery_file" 2>/dev/null || echo "0")
            total_recovery_files=$((total_recovery_files + count))
        fi
    done
    echo "" >> "$summary_file"
    echo "Recovery files: $total_recovery_files" >> "$summary_file"
    
    # Configuration directories found
    local config_dirs=($(find_libreoffice_configs))
    if [[ ${#config_dirs[@]} -gt 0 ]]; then
        echo "" >> "$summary_file"
        echo "Configuration directories:" >> "$summary_file"
        for dir in "${config_dirs[@]}"; do
            echo "  - $(basename "$dir")" >> "$summary_file"
        done
    fi
    
    log_success "LibreOffice session summary created"
}

# ============================================================================
# MAIN FUNCTIONS
# ============================================================================

# Pre-save hook main function
pre_save_main() {
    log_info "Starting LibreOffice pre-save hook..."
    
    if is_libreoffice_running; then
        save_libreoffice_session
        create_libreoffice_summary
        log_success "LibreOffice pre-save hook completed"
    else
        log_info "LibreOffice not running - nothing to save"
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
        log_info "LibreOffice post-restore hook would be handled by separate script"
        ;;
    *)
        log_error "Invalid argument. Use 'pre-save' or 'post-restore'"
        exit 1
        ;;
esac