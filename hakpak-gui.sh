#!/bin/bash

# HakPak GUI Launcher
# Provides a simple graphical interface for HakPak

HAKPAK_DIR="$(dirname "$(readlink -f "$0")")"
HAKPAK_SCRIPT="${HAKPAK_DIR}/hakpak.sh"

# Check if zenity is available for GUI dialogs
if ! command -v zenity >/dev/null 2>&1; then
    echo "Installing zenity for GUI support..."
    sudo apt-get update && sudo apt-get install -y zenity
fi

# Show main menu
show_main_menu() {
    local choice
    choice=$(zenity --list \
        --title="HakPak Security Toolkit v1.0.0" \
        --text="Select an action:" \
        --column="Action" \
        "List Available Tools" \
        "Install All Tools" \
        "Install Specific Tool" \
        "Run Security Scan" \
        "Update HakPak" \
        "Show System Info" \
        "Open Terminal" \
        --width=400 --height=300)
    
    case "${choice}" in
        "List Available Tools")
            "${HAKPAK_SCRIPT}" --list-tools | zenity --text-info \
                --title="Available Security Tools" \
                --width=600 --height=400
            ;;
        "Install All Tools")
            if zenity --question --text="Install all security tools?\n\nThis may take 10-20 minutes."; then
                "${HAKPAK_SCRIPT}" --install-all 2>&1 | zenity --progress \
                    --title="Installing Security Tools" \
                    --pulsate --auto-close
            fi
            ;;
        "Install Specific Tool")
            install_specific_tool
            ;;
        "Run Security Scan")
            run_security_scan
            ;;
        "Update HakPak")
            "${HAKPAK_SCRIPT}" --update 2>&1 | zenity --progress \
                --title="Updating HakPak" \
                --pulsate --auto-close
            ;;
        "Show System Info")
            "${HAKPAK_SCRIPT}" --system-info | zenity --text-info \
                --title="System Information" \
                --width=600 --height=400
            ;;
        "Open Terminal")
            gnome-terminal -- bash -c "cd '${HAKPAK_DIR}' && bash"
            ;;
    esac
}

# Install specific tool submenu
install_specific_tool() {
    local tools=("nmap" "dirb" "nikto" "masscan" "gobuster" "hydra" "john" "hashcat" "sqlmap" "metasploit")
    local tool_list=""
    
    for tool in "${tools[@]}"; do
        tool_list="${tool_list}${tool}\n"
    done
    
    local selected_tool
    selected_tool=$(echo -e "${tool_list}" | zenity --list \
        --title="Select Tool to Install" \
        --column="Tool" \
        --width=300 --height=400)
    
    if [[ -n "${selected_tool}" ]]; then
        "${HAKPAK_SCRIPT}" --install "${selected_tool}" 2>&1 | zenity --progress \
            --title="Installing ${selected_tool}" \
            --pulsate --auto-close
    fi
}

# Run security scan submenu
run_security_scan() {
    local target
    target=$(zenity --entry \
        --title="Security Scan Target" \
        --text="Enter target IP or domain:" \
        --entry-text="127.0.0.1")
    
    if [[ -n "${target}" ]]; then
        "${HAKPAK_SCRIPT}" --scan "${target}" 2>&1 | zenity --text-info \
            --title="Security Scan Results - ${target}" \
            --width=800 --height=600
    fi
}

# Main execution
if [[ "${1:-}" == "--gui" ]] || [[ -z "${1:-}" ]]; then
    show_main_menu
else
    # Pass through to main script
    "${HAKPAK_SCRIPT}" "$@"
fi
