#!/bin/bash

# Hakpak Reinstaller Script
# Safely uninstalls and reinstalls HakPak

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "HakPak Reinstaller"
echo "=================="
echo ""

# Step 1: Uninstall existing installation
print_info "Step 1: Uninstalling existing HakPak installation..."

if [[ -f /usr/local/bin/hakpak-uninstall ]]; then
    print_info "Using built-in uninstaller..."
    /usr/local/bin/hakpak-uninstall
else
    print_warning "Built-in uninstaller not found, using manual removal..."
    
    # Manual cleanup
    rm -f /usr/local/bin/hakpak
    rm -f /usr/share/applications/hakpak.desktop
    rm -f /usr/share/icons/hicolor/*/apps/hakpak.png
    rm -f /usr/share/pixmaps/hakpak.png
    rm -f /usr/local/bin/hakpak-uninstall
    
    # Update databases
    update-desktop-database /usr/share/applications 2>/dev/null || true
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
    
    print_success "Manual cleanup completed"
fi

print_success "Uninstallation completed"
echo ""

# Step 2: Reinstall
print_info "Step 2: Reinstalling HakPak..."

if [[ -f "./commercial-install.sh" ]]; then
    print_info "Running commercial installer..."
    ./commercial-install.sh
    print_success "Reinstallation completed!"
else
    print_error "commercial-install.sh not found in current directory"
    print_info "Please run this script from the HakPak directory"
    exit 1
fi

echo ""
print_success "HakPak has been successfully reinstalled!"
print_info "You can now run 'hakpak' or find it in your applications menu"
