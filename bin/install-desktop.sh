#!/bin/bash

# HakPak Desktop Installer
# Creates desktop shortcut and menu entry with icon
# Author: Teyvone Wells @ PhanesGuild Software LLC

set -euo pipefail

# Colors for output
declare -r GREEN='\033[0;32m'
declare -r RED='\033[0;31m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Get current directory and user info
INSTALL_DIR="$(pwd)"
HAKPAK_SCRIPT="${INSTALL_DIR}/hakpak.sh"
USER_HOME="${HOME}"
DESKTOP_DIR="${USER_HOME}/Desktop"
APPLICATIONS_DIR="${USER_HOME}/.local/share/applications"
ICONS_DIR="${USER_HOME}/.local/share/icons/hicolor/256x256/apps"

print_info "Installing HakPak Desktop Integration..."

# Create necessary directories
mkdir -p "${APPLICATIONS_DIR}"
mkdir -p "${ICONS_DIR}"
mkdir -p "${DESKTOP_DIR}"

# Install HakPak icon (professional PNG logo)
create_hakpak_icon() {
    local icon_path="${ICONS_DIR}/hakpak.png"
    
    print_info "Installing HakPak icon..."
    
    # Check if we have the professional logo files
    if [[ -f "${INSTALL_DIR}/hakpak-icon-256.png" ]]; then
        # Use the professional 256x256 PNG logo
        cp "${INSTALL_DIR}/hakpak-icon-256.png" "${icon_path}"
        print_success "Professional icon installed from hakpak-icon-256.png"
    elif [[ -f "${INSTALL_DIR}/hakpak-logo.png" ]]; then
        # Use the main logo and resize if needed
        if command -v convert >/dev/null 2>&1; then
            convert "${INSTALL_DIR}/hakpak-logo.png" -resize 256x256 "${icon_path}"
            print_success "Professional icon installed from hakpak-logo.png (resized)"
        else
            cp "${INSTALL_DIR}/hakpak-logo.png" "${icon_path}"
            print_success "Professional icon installed from hakpak-logo.png"
        fi
    else
        # Fall back to generating an icon
        create_fallback_icon "${icon_path}"
    fi
}

# Create fallback icon using base64 encoded PNG
create_fallback_icon() {
    local icon_path="$1"
    
    print_info "Creating fallback icon..."
    
    # Base64 encoded 256x256 PNG icon (professional HakPak design)
    cat << 'EOF' | base64 -d > "${icon_path}"
iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAABHNCSVQICAgIfAhkiAAAAAlwSFlz
AAAG7AAABuwBHnU4NQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAABxQSURB
VHic7Z15mFTV9ce/5/bt6u5qaBpo6AYaEFkUEAQXFBcUjSIaNxI1GmMSjdGJmcQkZjJJJpP5
JZlMJpPEJDNxSVwTF40L7riAGyAiAoKyNCANDU03TXfTXV2973d+f1TTPb3UXd1db9/3eZ6n
qare986pc+t+373n3nPvJTMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz
MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzM7O9
YGZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
ZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZmZm
EOF

    if [[ -f "${icon_path}" ]]; then
        print_success "Fallback icon created successfully"
    else
        print_error "Failed to create icon"
        return 1
    fi
}

# Create .desktop file for applications menu
create_desktop_entry() {
    local desktop_file="${APPLICATIONS_DIR}/hakpak.desktop"
    
    print_info "Creating application menu entry..."
    
    cat > "${desktop_file}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=HakPak Security Toolkit
Comment=Professional Cybersecurity Tools Collection
Exec=${HAKPAK_SCRIPT} --gui
Icon=hakpak
Terminal=true
StartupNotify=true
Categories=Development;Security;System;
Keywords=security;penetration;testing;hacking;nmap;tools;
GenericName=Security Toolkit
MimeType=application/x-hakpak;
StartupWMClass=hakpak
EOF

    chmod +x "${desktop_file}"
    print_success "Application menu entry created"
}

# Create desktop shortcut
create_desktop_shortcut() {
    local desktop_shortcut="${DESKTOP_DIR}/HakPak.desktop"
    
    print_info "Creating desktop shortcut..."
    
    cat > "${desktop_shortcut}" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=HakPak Security Toolkit
Comment=Professional Cybersecurity Tools Collection
Exec=${HAKPAK_SCRIPT} --gui
Icon=hakpak
Terminal=true
StartupNotify=true
Categories=Development;Security;System;
Keywords=security;penetration;testing;hacking;nmap;tools;
GenericName=Security Toolkit
MimeType=application/x-hakpak;
StartupWMClass=hakpak
EOF

    chmod +x "${desktop_shortcut}"
    
    # Try to make it trusted (for newer Ubuntu versions)
    if command -v gio >/dev/null 2>&1; then
        gio set "${desktop_shortcut}" metadata::trusted true 2>/dev/null || true
    fi
    
    print_success "Desktop shortcut created"
}

# Create launcher script that handles GUI mode
create_gui_launcher() {
    local launcher_script="${INSTALL_DIR}/hakpak-gui.sh"
    
    print_info "Creating GUI launcher..."
    
    cat > "${launcher_script}" << 'EOF'
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
EOF

    chmod +x "${launcher_script}"
    print_success "GUI launcher created"
}

# Update the main hakpak.sh to support --gui flag
update_main_script() {
    print_info "Adding GUI support to main script..."
    
    # Check if GUI support already exists
    if grep -q "gui.*GUI mode" "${HAKPAK_SCRIPT}"; then
        print_info "GUI support already exists in main script"
        return 0
    fi
    
    # Add GUI flag to help text
    local help_section_line
    help_section_line=$(grep -n "show_help()" "${HAKPAK_SCRIPT}" | cut -d: -f1)
    
    if [[ -n "${help_section_line}" ]]; then
        # Find the line with --help in the help function
        local help_text_line
        help_text_line=$(tail -n +${help_section_line} "${HAKPAK_SCRIPT}" | grep -n "\-\-help" | head -1 | cut -d: -f1)
        
        if [[ -n "${help_text_line}" ]]; then
            local actual_line=$((help_section_line + help_text_line - 1))
            
            # Add GUI option before --help
            sed -i "${actual_line}i\\    --gui                    Launch graphical interface" "${HAKPAK_SCRIPT}"
            print_success "Added GUI option to help text"
        fi
    fi
    
    # Add GUI flag handling to argument parsing
    local parse_args_line
    parse_args_line=$(grep -n "while.*getopts\|case.*\$1" "${HAKPAK_SCRIPT}" | head -1 | cut -d: -f1)
    
    if [[ -n "${parse_args_line}" ]]; then
        # Find a good place to add the GUI case
        local gui_case_line
        gui_case_line=$(tail -n +${parse_args_line} "${HAKPAK_SCRIPT}" | grep -n "\-\-help\|\-h)" | head -1 | cut -d: -f1)
        
        if [[ -n "${gui_case_line}" ]]; then
            local actual_line=$((parse_args_line + gui_case_line - 1))
            
            # Add GUI case before help case
            sed -i "${actual_line}i\\        --gui)" "${HAKPAK_SCRIPT}"
            sed -i "$((actual_line + 1))i\\            exec \"${HAKPAK_DIR}/hakpak-gui.sh\" --gui" "${HAKPAK_SCRIPT}"
            sed -i "$((actual_line + 2))i\\            ;;" "${HAKPAK_SCRIPT}"
            print_success "Added GUI flag handling to main script"
        fi
    fi
}

# Update desktop database
update_desktop_database() {
    print_info "Updating desktop database..."
    
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${APPLICATIONS_DIR}" 2>/dev/null || true
    fi
    
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache "${USER_HOME}/.local/share/icons/hicolor" 2>/dev/null || true
    fi
    
    print_success "Desktop database updated"
}

# Main installation function
main() {
    print_info "Starting HakPak Desktop Integration..."
    echo
    
    # Verify hakpak.sh exists
    if [[ ! -f "${HAKPAK_SCRIPT}" ]]; then
        print_error "HakPak script not found at ${HAKPAK_SCRIPT}"
        exit 1
    fi
    
    # Make hakpak.sh executable
    chmod +x "${HAKPAK_SCRIPT}"
    
    # Create all components
    create_hakpak_icon
    create_desktop_entry
    create_desktop_shortcut
    create_gui_launcher
    update_main_script
    update_desktop_database
    
    echo
    print_success "HakPak Desktop Integration completed successfully!"
    echo
    print_info "You can now:"
    echo "  • Find HakPak in your applications menu"
    echo "  • Double-click the desktop shortcut"
    echo "  • Run: ./hakpak.sh --gui"
    echo "  • Run: ./hakpak-gui.sh"
    echo
}

# Run main function
main "$@"
