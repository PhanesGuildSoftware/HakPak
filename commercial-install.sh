#!/bin/bash

# Hakpak Commercial Installation Script
# PhanesGuild Software LLC

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     HAKPAK INSTALLER                        ║"
    echo "║           Universal Kali Tools for Debian Systems          ║"
    echo "║                    PhanesGuild Software LLC                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This installer must be run as root (use sudo)"
        exit 1
    fi
}

check_system() {
    print_info "Checking system compatibility..."
    
    # Check for supported distributions
    if [[ -f /etc/os-release ]]; then
        # Use grep to extract values without sourcing to avoid readonly conflicts
        local distro_id
        distro_id=$(grep '^ID=' /etc/os-release | cut -d'=' -f2- | tr -d '"')
        local distro_name
        distro_name=$(grep '^NAME=' /etc/os-release | cut -d'=' -f2- | tr -d '"')
        
        case "$distro_id" in
            ubuntu|debian|pop|linuxmint|parrot)
                print_success "Detected supported distribution: $distro_name"
                ;;
            *)
                print_warning "Distribution '$distro_name' may not be fully supported"
                print_info "Hakpak officially supports: Ubuntu, Debian, Pop!_OS, Linux Mint, Parrot OS"
                read -rp "Continue anyway? [y/N]: " confirm
                [[ $confirm =~ ^[Yy]$ ]] || exit 1
                ;;
        esac
    else
        print_warning "Cannot detect distribution"
    fi
    
    print_success "System compatibility check passed"
}

install_files() {
    print_info "Installing Hakpak files..."
    
    # Create directories
    mkdir -p /usr/local/bin
    mkdir -p /usr/share/applications
    mkdir -p /usr/share/icons/hicolor/{16x16,32x32,48x48,64x64,128x128}/apps
    mkdir -p /usr/share/pixmaps
    
    # Install main script
    cp hakpak.sh /usr/local/bin/hakpak
    chmod +x /usr/local/bin/hakpak
    print_success "Installed main executable to /usr/local/bin/hakpak"
    
    # Install desktop entry
    cp hakpak.desktop /usr/share/applications/
    print_success "Installed desktop entry"
    
    # Install icons
    cp hakpak-16.png /usr/share/icons/hicolor/16x16/apps/hakpak.png
    cp hakpak-32.png /usr/share/icons/hicolor/32x32/apps/hakpak.png
    cp hakpak-48.png /usr/share/icons/hicolor/48x48/apps/hakpak.png
    cp hakpak-64.png /usr/share/icons/hicolor/64x64/apps/hakpak.png
    cp hakpak-128.png /usr/share/icons/hicolor/128x128/apps/hakpak.png
    cp hakpak-64.png /usr/share/pixmaps/hakpak.png
    print_success "Installed application icons"
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database /usr/share/applications
        print_success "Updated desktop database"
    fi
    
    # Update icon cache
    if command -v gtk-update-icon-cache &> /dev/null; then
        gtk-update-icon-cache /usr/share/icons/hicolor &> /dev/null || true
        print_success "Updated icon cache"
    fi
}

create_uninstaller() {
    cat > /usr/local/bin/hakpak-uninstall << 'EOF'
#!/bin/bash
# Hakpak Uninstaller

echo "Removing Hakpak..."

# Remove files
rm -f /usr/local/bin/hakpak
rm -f /usr/share/applications/hakpak.desktop
rm -f /usr/share/icons/hicolor/*/apps/hakpak.png
rm -f /usr/share/pixmaps/hakpak.png

# Update databases
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo "Hakpak has been uninstalled."
echo "Note: Installed Kali packages and repository configuration remain."
EOF

    chmod +x /usr/local/bin/hakpak-uninstall
    print_success "Created uninstaller at /usr/local/bin/hakpak-uninstall"
}

main() {
    print_header
    
    check_root
    check_system
    
    print_info "Installing Hakpak..."
    install_files
    create_uninstaller
    
    echo ""
    print_success "Hakpak installation completed!"
    echo ""
    print_info "You can now:"
    echo "  • Run 'hakpak' from terminal"
    echo "  • Find 'Hakpak' in your applications menu"
    echo "  • Uninstall with 'sudo hakpak-uninstall'"
    echo ""
    print_warning "Note: Hakpak requires sudo privileges to install packages"
    echo ""
    print_info "Forge wisely. Strike precisely."
    echo ""
}

main "$@"
