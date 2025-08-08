#!/bin/bash

# HakPak Desktop Integration Installer
# Installs HakPak as a proper desktop application with desktop launcher

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should NOT be run as root"
    print_info "It will use sudo for operations that require privileges"
    exit 1
fi

# Detect user's desktop environment
detect_desktop_environment() {
    if [[ "$XDG_CURRENT_DESKTOP" =~ GNOME ]]; then
        echo "gnome"
    elif [[ "$XDG_CURRENT_DESKTOP" =~ KDE ]]; then
        echo "kde"
    elif [[ "$XDG_CURRENT_DESKTOP" =~ XFCE ]]; then
        echo "xfce"
    elif [[ "$XDG_CURRENT_DESKTOP" =~ MATE ]]; then
        echo "mate"
    elif [[ "$XDG_CURRENT_DESKTOP" =~ Cinnamon ]]; then
        echo "cinnamon"
    else
        echo "unknown"
    fi
}

echo -e "${BOLD}${BLUE}HakPak Universal Installer${NC}"
echo "════════════════════════════════════════"
echo -e "${BOLD}Universal Kali Tools Installer for Debian-Based Systems${NC}"
echo -e "${BLUE}Author:${NC} Teyvone Wells @ PhanesGuild Software LLC"
echo -e "${BLUE}Version:${NC} 2.0"
echo
print_info "Detected Desktop Environment: $(detect_desktop_environment | tr '[:lower:]' '[:upper:]')"
echo

# Verify required files exist
print_info "Verifying installation files..."
required_files=(
    "hakpak.sh"
    "hakpak-launcher.sh" 
    "hakpak.svg"
    "com.phanesguild.hakpak.policy"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        print_error "Required file missing: $file"
        print_info "Please ensure you have the complete HakPak package"
        exit 1
    fi
done
print_success "All required files found"

# Install main script
print_info "Installing HakPak executable..."
if sudo cp hakpak.sh /usr/local/bin/hakpak; then
    sudo chmod +x /usr/local/bin/hakpak
    print_success "HakPak executable installed to /usr/local/bin/hakpak"
else
    print_error "Failed to install HakPak executable"
    exit 1
fi

# Install launcher script
print_info "Installing HakPak launcher..."
if sudo cp hakpak-launcher.sh /usr/local/bin/hakpak-launcher; then
    sudo chmod +x /usr/local/bin/hakpak-launcher
    print_success "HakPak launcher installed to /usr/local/bin/hakpak-launcher"
else
    print_error "Failed to install HakPak launcher"
    exit 1
fi

# Install icons
print_info "Installing HakPak icons..."
sudo mkdir -p /usr/share/icons/hicolor/{16x16,32x32,48x48,64x64,128x128,scalable}/apps

# Install PNG icons if they exist
for size in 16 32 48 64 128; do
    if [[ -f "hakpak-${size}.png" ]]; then
        sudo cp "hakpak-${size}.png" "/usr/share/icons/hicolor/${size}x${size}/apps/hakpak.png"
        print_success "Installed ${size}x${size} icon"
    fi
done

# Install SVG icon
if [[ -f "hakpak.svg" ]]; then
    sudo cp "hakpak.svg" "/usr/share/icons/hicolor/scalable/apps/hakpak.svg"
    print_success "Installed scalable SVG icon"
fi

# Update icon cache
if command -v gtk-update-icon-cache &> /dev/null; then
    sudo gtk-update-icon-cache -t /usr/share/icons/hicolor/ 2>/dev/null || true
    print_success "Updated icon cache"
fi

# Install PolicyKit policy
print_info "Installing PolicyKit policy..."
if sudo cp com.phanesguild.hakpak.policy /usr/share/polkit-1/actions/; then
    print_success "PolicyKit policy installed"
else
    print_warning "Failed to install PolicyKit policy (authentication may not work properly)"
fi

# Create system desktop entry
print_info "Creating system desktop entry..."
cat > hakpak-system.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=HakPak
Comment=Universal Kali Tools Installer for Debian-Based Systems
Exec=/usr/local/bin/hakpak-launcher
Icon=hakpak
Terminal=false
Categories=System;Security;Administration;
Keywords=kali;security;tools;installer;penetration;testing;
StartupNotify=true
StartupWMClass=hakpak
Actions=Top10;WebTools;Individual;Status;

[Desktop Action Top10]
Name=Install Kali Top 10
Exec=/usr/local/bin/hakpak-launcher --install kali-linux-top10
Icon=hakpak

[Desktop Action WebTools]
Name=Install Web Security Tools
Exec=/usr/local/bin/hakpak-launcher --install kali-tools-web-application
Icon=hakpak

[Desktop Action Individual]
Name=Interactive Menu
Exec=/usr/local/bin/hakpak-launcher --interactive
Icon=hakpak

[Desktop Action Status]
Name=System Status
Exec=/usr/local/bin/hakpak-launcher --status
Icon=hakpak
EOF

# Install system desktop entry
if sudo cp hakpak-system.desktop /usr/share/applications/hakpak.desktop; then
    print_success "System desktop entry installed"
else
    print_error "Failed to install system desktop entry"
    exit 1
fi

# Create user desktop shortcut
print_info "Creating desktop shortcut..."
desktop_dir="$HOME/Desktop"

# Create Desktop directory if it doesn't exist
mkdir -p "$desktop_dir"

# Create user desktop entry
cat > "$desktop_dir/HakPak.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=HakPak
Comment=Universal Kali Tools Installer for Debian-Based Systems
Exec=/usr/local/bin/hakpak-launcher
Icon=hakpak
Terminal=false
Categories=System;Security;Administration;
Keywords=kali;security;tools;installer;penetration;testing;
StartupNotify=true
StartupWMClass=hakpak
EOF

# Make desktop shortcut executable
chmod +x "$desktop_dir/HakPak.desktop"

# For GNOME-based desktops, trust the desktop file
if command -v gio &> /dev/null; then
    gio set "$desktop_dir/HakPak.desktop" metadata::trusted true 2>/dev/null || true
fi

print_success "Desktop shortcut created: $desktop_dir/HakPak.desktop"

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true
    print_success "Desktop database updated"
fi

# Desktop environment specific setup
desktop_env=$(detect_desktop_environment)
case "$desktop_env" in
    "gnome")
        print_info "Configuring for GNOME desktop..."
        # Allow launching of desktop files
        gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask' 2>/dev/null || true
        ;;
    "kde")
        print_info "Configuring for KDE desktop..."
        # KDE should handle desktop files automatically
        ;;
    "xfce")
        print_info "Configuring for XFCE desktop..."
        # XFCE typically handles desktop files well
        ;;
esac

# Clean up temporary files
rm -f hakpak-system.desktop

echo
print_success "HakPak installation completed successfully!"
echo
echo -e "${BOLD}${GREEN}HakPak is now installed and ready to use:${NC}"
echo
echo -e "${BLUE}📱 Desktop Shortcut:${NC} HakPak icon on your desktop"
echo -e "${BLUE}🔍 Application Menu:${NC} Search for 'HakPak' in your app launcher"
echo -e "${BLUE}⚡ Terminal Access:${NC} Run 'hakpak' from any terminal"
echo
echo -e "${BOLD}${YELLOW}Usage Examples:${NC}"
echo -e "${BLUE}•${NC} Double-click the desktop icon to open HakPak"
echo -e "${BLUE}•${NC} Right-click the desktop icon for quick actions"
echo -e "${BLUE}•${NC} Search for 'HakPak' in Activities/Start Menu"
echo -e "${BLUE}•${NC} Terminal: hakpak --help for command options"
echo
echo -e "${BOLD}${RED}⚠️  Important Notes:${NC}"
echo -e "${BLUE}•${NC} HakPak requires administrator privileges"
echo -e "${BLUE}•${NC} You will be prompted for your password when launching"
echo -e "${BLUE}•${NC} Ensure your user account has sudo privileges"
echo
echo -e "${BOLD}${GREEN}Installation Log:${NC} /var/log/hakpak.log"
echo -e "${BOLD}${GREEN}Support:${NC} PhanesGuild Software LLC"
echo
print_success "Ready to forge your security toolkit! 🛡️"
