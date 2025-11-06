#!/usr/bin/env zsh

# Creative & Office Applications Session Management Hook
# Pre-save hook for Krita, GIMP, LibreOffice, Okular session preservation

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CREATIVE/OFFICE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CREATIVE/OFFICE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CREATIVE/OFFICE HOOK]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Save Krita session information
save_krita_session() {
    if pgrep -x "krita" > /dev/null; then
        log_info "Krita detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/krita"
        
        # Extract open documents from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "krita") | .title' > "${SESSION_STATE_DIR}/krita/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "krita") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/krita/positions.txt" 2>/dev/null
        
        # Krita auto-saves recovery files - we can note their locations
        local krita_recovery="${HOME}/.local/share/krita/recovery"
        if [[ -d "$krita_recovery" ]]; then
            find "$krita_recovery" -name "*.kra" -o -name "*.png" -o -name "*.jpg" > "${SESSION_STATE_DIR}/krita/recovery_files.txt" 2>/dev/null
        fi
        
        # Save recent documents list from Krita config
        local krita_config="${HOME}/.config/kritarc"
        if [[ -f "$krita_config" ]]; then
            grep -i "recent" "$krita_config" > "${SESSION_STATE_DIR}/krita/recent_documents.txt" 2>/dev/null
        fi
        
        log_success "Krita session information saved"
    else
        log_info "Krita not running"
    fi
}

# Save GIMP session information
save_gimp_session() {
    if pgrep -x "gimp" > /dev/null; then
        log_info "GIMP detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/gimp"
        
        # Extract open documents from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "gimp") | .title' > "${SESSION_STATE_DIR}/gimp/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "gimp") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/gimp/positions.txt" 2>/dev/null
        
        # GIMP session files location
        local gimp_session="${HOME}/.config/GIMP/2.10/sessionrc"
        if [[ -f "$gimp_session" ]]; then
            cp "$gimp_session" "${SESSION_STATE_DIR}/gimp/sessionrc.backup" 2>/dev/null
        fi
        
        # Save recent documents
        local gimp_recent="${HOME}/.config/GIMP/2.10/gimprc"
        if [[ -f "$gimp_recent" ]]; then
            grep -i "recent" "$gimp_recent" > "${SESSION_STATE_DIR}/gimp/recent_documents.txt" 2>/dev/null
        fi
        
        log_success "GIMP session information saved"
    else
        log_info "GIMP not running"
    fi
}

# Save LibreOffice session information
save_libreoffice_session() {
    if pgrep -f "libreoffice" > /dev/null; then
        log_info "LibreOffice detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/libreoffice"
        
        # Extract open documents from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "libreoffice") | .title' > "${SESSION_STATE_DIR}/libreoffice/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "libreoffice") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/libreoffice/positions.txt" 2>/dev/null
        
        # LibreOffice recovery files location
        local lo_recovery="${HOME}/.config/libreoffice/4/user/backup"
        if [[ -d "$lo_recovery" ]]; then
            find "$lo_recovery" -type f > "${SESSION_STATE_DIR}/libreoffice/recovery_files.txt" 2>/dev/null
        fi
        
        # Save recent documents from LibreOffice config
        local lo_config="${HOME}/.config/libreoffice/4/user/registrymodifications.xcu"
        if [[ -f "$lo_config" ]]; then
            grep -i "recent" "$lo_config" > "${SESSION_STATE_DIR}/libreoffice/recent_documents.txt" 2>/dev/null
        fi
        
        log_success "LibreOffice session information saved"
    else
        log_info "LibreOffice not running"
    fi
}

# Save Okular session information
save_okular_session() {
    if pgrep -x "okular" > /dev/null; then
        log_info "Okular detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/okular"
        
        # Extract open documents from window titles
        hyprctl clients -j | jq -r '.[] | select(.class == "okular") | .title' > "${SESSION_STATE_DIR}/okular/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "okular") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/okular/positions.txt" 2>/dev/null
        
        # Okular session files
        local okular_config="${HOME}/.config/okularpartrc"
        if [[ -f "$okular_config" ]]; then
            cp "$okular_config" "${SESSION_STATE_DIR}/okular/okularpartrc.backup" 2>/dev/null
        fi
        
        # Save recent documents
        local okular_recent="${HOME}/.config/okularrc"
        if [[ -f "$okular_recent" ]]; then
            grep -i "recent" "$okular_recent" > "${SESSION_STATE_DIR}/okular/recent_documents.txt" 2>/dev/null
        fi
        
        log_success "Okular session information saved"
    else
        log_info "Okular not running"
    fi
}

# Save Dolphin file manager session
save_dolphin_session() {
    if pgrep -x "dolphin" > /dev/null; then
        log_info "Dolphin detected - saving session information"
        
        mkdir -p "${SESSION_STATE_DIR}/dolphin"
        
        # Extract open windows and locations
        hyprctl clients -j | jq -r '.[] | select(.class == "dolphin") | .title' > "${SESSION_STATE_DIR}/dolphin/window_titles.txt" 2>/dev/null
        
        # Save window positions and layouts
        hyprctl clients -j | jq -r '.[] | select(.class == "dolphin") | "\(.address):\(.at[0]):\(.at[1]):\(.size[0]):\(.size[1]):\(.workspace.id):\(.title)"' > "${SESSION_STATE_DIR}/dolphin/positions.txt" 2>/dev/null
        
        # Dolphin session files
        local dolphin_session="${HOME}/.local/share/dolphin/sessions"
        if [[ -d "$dolphin_session" ]]; then
            find "$dolphin_session" -name "*.dolphinsession" > "${SESSION_STATE_DIR}/dolphin/session_files.txt" 2>/dev/null
        fi
        
        log_success "Dolphin session information saved"
    else
        log_info "Dolphin not running"
    fi
}

# Create creative/office applications summary
create_creative_office_summary() {
    log_info "Creating creative/office applications summary..."
    
    local summary_file="${SESSION_STATE_DIR}/creative_office_summary.txt"
    
    echo "Creative & Office Applications Summary - $(date)" > "$summary_file"
    echo "================================================" >> "$summary_file"
    
    # Krita info
    local krita_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "krita")] | length' 2>/dev/null)
    echo "Krita: $krita_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/krita/window_titles.txt" ]]; then
        echo "Open documents:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/krita/window_titles.txt" | head -3 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # GIMP info
    local gimp_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "gimp")] | length' 2>/dev/null)
    echo "GIMP: $gimp_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/gimp/window_titles.txt" ]]; then
        echo "Open documents:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/gimp/window_titles.txt" | head -3 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # LibreOffice info
    local libreoffice_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "libreoffice")] | length' 2>/dev/null)
    echo "LibreOffice: $libreoffice_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/libreoffice/window_titles.txt" ]]; then
        echo "Open documents:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/libreoffice/window_titles.txt" | head -3 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # Okular info
    local okular_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "okular")] | length' 2>/dev/null)
    echo "Okular: $okular_windows windows" >> "$summary_file"
    if [[ -f "${SESSION_STATE_DIR}/okular/window_titles.txt" ]]; then
        echo "Open documents:" >> "$summary_file"
        cat "${SESSION_STATE_DIR}/okular/window_titles.txt" | head -3 | sed 's/^/  - /' >> "$summary_file" 2>/dev/null
    fi
    
    echo "" >> "$summary_file"
    
    # Dolphin info
    local dolphin_windows=$(hyprctl clients -j | jq '[.[] | select(.class == "dolphin")] | length' 2>/dev/null)
    echo "Dolphin: $dolphin_windows windows" >> "$summary_file"
    
    log_success "Creative/office applications summary created"
}

# Main function
main() {
    log_info "Starting creative/office applications session preservation..."
    
    # Save Krita sessions
    save_krita_session
    
    # Save GIMP sessions
    save_gimp_session
    
    # Save LibreOffice sessions
    save_libreoffice_session
    
    # Save Okular sessions
    save_okular_session
    
    # Save Dolphin sessions
    save_dolphin_session
    
    # Create summary
    create_creative_office_summary
    
    log_success "Creative/office applications session preservation completed"
}

# Execute main function
main "$@"