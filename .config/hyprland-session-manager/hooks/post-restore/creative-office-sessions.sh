#!/usr/bin/env zsh

# Creative & Office Applications Session Restoration Hook
# Post-restore hook for Krita, GIMP, LibreOffice, Okular session recovery

SESSION_DIR="${HOME}/.config/hyprland-session-manager"
SESSION_STATE_DIR="${SESSION_DIR}/session-state"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[CREATIVE/OFFICE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[CREATIVE/OFFICE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[CREATIVE/OFFICE RESTORE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Restore Krita session information
restore_krita_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/krita" ]]; then
        log_warning "No saved Krita session data found"
        return 1
    fi
    
    log_info "Attempting Krita session restoration..."
    
    # Wait for Krita to be ready
    sleep 3
    
    # Focus Krita windows
    if [[ -f "${SESSION_STATE_DIR}/krita/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Krita window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/krita/positions.txt"
    fi
    
    # Krita should auto-recover files from its recovery directory
    # We can check if recovery files exist and notify user
    if [[ -f "${SESSION_STATE_DIR}/krita/recovery_files.txt" ]]; then
        local recovery_count=$(wc -l < "${SESSION_STATE_DIR}/krita/recovery_files.txt")
        log_info "Krita has $recovery_count recovery files available"
    fi
    
    log_success "Krita session restoration attempted"
}

# Restore GIMP session information
restore_gimp_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/gimp" ]]; then
        log_warning "No saved GIMP session data found"
        return 1
    fi
    
    log_info "Attempting GIMP session restoration..."
    
    # Wait for GIMP to be ready
    sleep 3
    
    # Focus GIMP windows
    if [[ -f "${SESSION_STATE_DIR}/gimp/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing GIMP window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/gimp/positions.txt"
    fi
    
    # GIMP should restore its session automatically if sessionrc exists
    log_success "GIMP session restoration attempted"
}

# Restore LibreOffice session information
restore_libreoffice_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/libreoffice" ]]; then
        log_warning "No saved LibreOffice session data found"
        return 1
    fi
    
    log_info "Attempting LibreOffice session restoration..."
    
    # Wait for LibreOffice to be ready
    sleep 3
    
    # Focus LibreOffice windows
    if [[ -f "${SESSION_STATE_DIR}/libreoffice/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing LibreOffice window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/libreoffice/positions.txt"
    fi
    
    # LibreOffice has auto-recovery features
    if [[ -f "${SESSION_STATE_DIR}/libreoffice/recovery_files.txt" ]]; then
        local recovery_count=$(wc -l < "${SESSION_STATE_DIR}/libreoffice/recovery_files.txt")
        log_info "LibreOffice has $recovery_count recovery files available"
    fi
    
    log_success "LibreOffice session restoration attempted"
}

# Restore Okular session information
restore_okular_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/okular" ]]; then
        log_warning "No saved Okular session data found"
        return 1
    fi
    
    log_info "Attempting Okular session restoration..."
    
    # Wait for Okular to be ready
    sleep 3
    
    # Focus Okular windows
    if [[ -f "${SESSION_STATE_DIR}/okular/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Okular window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/okular/positions.txt"
    fi
    
    # Okular should restore recent documents automatically
    log_success "Okular session restoration attempted"
}

# Restore Dolphin file manager session
restore_dolphin_session() {
    if [[ ! -d "${SESSION_STATE_DIR}/dolphin" ]]; then
        log_warning "No saved Dolphin session data found"
        return 1
    fi
    
    log_info "Attempting Dolphin session restoration..."
    
    # Wait for Dolphin to be ready
    sleep 3
    
    # Focus Dolphin windows
    if [[ -f "${SESSION_STATE_DIR}/dolphin/positions.txt" ]]; then
        while IFS=: read -r address pos_x pos_y size_x size_y workspace title; do
            if [[ -n "$address" && "$address" != "null" ]]; then
                log_info "Focusing Dolphin window: $title"
                
                # Focus the window
                hyprctl dispatch focuswindow "address:$address" 2>/dev/null
                
                # Small delay between window operations
                sleep 1
            fi
        done < "${SESSION_STATE_DIR}/dolphin/positions.txt"
    fi
    
    # Dolphin has session management - it should restore automatically
    log_success "Dolphin session restoration attempted"
}

# Open recent documents based on saved information
open_recent_documents() {
    log_info "Attempting to open recent documents..."
    
    local opened_count=0
    
    # Open documents from saved window titles
    for app_dir in "krita" "gimp" "libreoffice" "okular"; do
        if [[ -f "${SESSION_STATE_DIR}/${app_dir}/window_titles.txt" ]]; then
            while read -r title; do
                # Extract file paths from window titles
                if [[ "$title" =~ "/" && "$title" =~ "\.[a-zA-Z0-9]+" ]]; then
                    local file_path=$(echo "$title" | grep -o '/[^ ]*\.[a-zA-Z0-9]+' | head -1)
                    if [[ -n "$file_path" && -f "$file_path" ]]; then
                        log_info "Opening $app_dir document: $(basename "$file_path")"
                        
                        case "$app_dir" in
                            "krita")
                                nohup krita "$file_path" > /dev/null 2>&1 &
                                ;;
                            "gimp")
                                nohup gimp "$file_path" > /dev/null 2>&1 &
                                ;;
                            "libreoffice")
                                nohup libreoffice "$file_path" > /dev/null 2>&1 &
                                ;;
                            "okular")
                                nohup okular "$file_path" > /dev/null 2>&1 &
                                ;;
                        esac
                        
                        ((opened_count++))
                        sleep 2
                    fi
                fi
            done < "${SESSION_STATE_DIR}/${app_dir}/window_titles.txt"
        fi
    done
    
    if [[ $opened_count -gt 0 ]]; then
        log_success "Opened $opened_count documents"
    else
        log_info "No specific documents to open"
    fi
}

# Validate creative/office applications restoration
validate_creative_office_restoration() {
    log_info "Validating creative/office applications restoration..."
    
    local krita_count=$(hyprctl clients -j | jq '[.[] | select(.class == "krita")] | length' 2>/dev/null)
    local gimp_count=$(hyprctl clients -j | jq '[.[] | select(.class == "gimp")] | length' 2>/dev/null)
    local libreoffice_count=$(hyprctl clients -j | jq '[.[] | select(.class == "libreoffice")] | length' 2>/dev/null)
    local okular_count=$(hyprctl clients -j | jq '[.[] | select(.class == "okular")] | length' 2>/dev/null)
    local dolphin_count=$(hyprctl clients -j | jq '[.[] | select(.class == "dolphin")] | length' 2>/dev/null)
    
    local total_apps=$((krita_count + gimp_count + libreoffice_count + okular_count + dolphin_count))
    
    if [[ -n "$total_apps" && "$total_apps" -gt 0 ]]; then
        log_success "Creative/office applications restoration successful - $total_apps windows open"
        
        [[ -n "$krita_count" && "$krita_count" -gt 0 ]] && log_info "  Krita: $krita_count windows"
        [[ -n "$gimp_count" && "$gimp_count" -gt 0 ]] && log_info "  GIMP: $gimp_count windows"
        [[ -n "$libreoffice_count" && "$libreoffice_count" -gt 0 ]] && log_info "  LibreOffice: $libreoffice_count windows"
        [[ -n "$okular_count" && "$okular_count" -gt 0 ]] && log_info "  Okular: $okular_count windows"
        [[ -n "$dolphin_count" && "$dolphin_count" -gt 0 ]] && log_info "  Dolphin: $dolphin_count windows"
        
        return 0
    else
        log_warning "No creative/office application windows detected after restoration"
        return 1
    fi
}

# Send creative/office applications restoration notification
send_creative_office_notification() {
    log_info "Sending creative/office applications restoration notification..."
    
    if command -v notify-send > /dev/null; then
        local krita_count=$(hyprctl clients -j | jq '[.[] | select(.class == "krita")] | length' 2>/dev/null)
        local gimp_count=$(hyprctl clients -j | jq '[.[] | select(.class == "gimp")] | length' 2>/dev/null)
        local libreoffice_count=$(hyprctl clients -j | jq '[.[] | select(.class == "libreoffice")] | length' 2>/dev/null)
        local okular_count=$(hyprctl clients -j | jq '[.[] | select(.class == "okular")] | length' 2>/dev/null)
        
        local message="Creative & Office applications restored"
        [[ -n "$krita_count" && "$krita_count" -gt 0 ]] && message="$message\nKrita: $krita_count windows"
        [[ -n "$gimp_count" && "$gimp_count" -gt 0 ]] && message="$message\nGIMP: $gimp_count windows"
        [[ -n "$libreoffice_count" && "$libreoffice_count" -gt 0 ]] && message="$message\nLibreOffice: $libreoffice_count windows"
        [[ -n "$okular_count" && "$okular_count" -gt 0 ]] && message="$message\nOkular: $okular_count windows"
        
        notify-send "Creative/Office Session Restored" "$message" -t 5000
    fi
}

# Main function
main() {
    log_info "Starting creative/office applications session restoration..."
    
    # Wait for applications to stabilize
    sleep 3
    
    # Restore Krita sessions
    restore_krita_session
    
    # Restore GIMP sessions
    restore_gimp_session
    
    # Restore LibreOffice sessions
    restore_libreoffice_session
    
    # Restore Okular sessions
    restore_okular_session
    
    # Restore Dolphin sessions
    restore_dolphin_session
    
    # Additional wait for application loading
    sleep 2
    
    # Open recent documents
    open_recent_documents
    
    # Validate restoration
    validate_creative_office_restoration
    
    # Send notification
    send_creative_office_notification
    
    log_success "Creative/office applications session restoration completed"
}

# Execute main function
main "$@"