#!/bin/bash

# Hakpak Manual Uninstaller
# Use this if the automatic uninstaller is missing

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

print_info "Manually uninstalling Hakpak..."

# Remove main executable
if [[ -f /usr/local/bin/hakpak ]]; then
    rm -f /usr/local/bin/hakpak
    print_success "Removed main executable"
else
    print_warning "Main executable not found"
fi

# Remove desktop entry
if [[ -f /usr/share/applications/hakpak.desktop ]]; then
    rm -f /usr/share/applications/hakpak.desktop
    print_success "Removed desktop entry"
else
    print_warning "Desktop entry not found"
fi

# Remove icons
removed_icons=0
for size in 16 32 48 64 128; do
    if [[ -f /usr/share/icons/hicolor/${size}x${size}/apps/hakpak.png ]]; then
        rm -f /usr/share/icons/hicolor/${size}x${size}/apps/hakpak.png
        ((removed_icons++))
    fi
done

if [[ -f /usr/share/pixmaps/hakpak.png ]]; then
    rm -f /usr/share/pixmaps/hakpak.png
    ((removed_icons++))
fi

if [[ $removed_icons -gt 0 ]]; then
    print_success "Removed $removed_icons icon files"
else
    print_warning "No icon files found"
fi

# Remove uninstaller
if [[ -f /usr/local/bin/hakpak-uninstall ]]; then
    rm -f /usr/local/bin/hakpak-uninstall
    print_success "Removed uninstaller"
fi

# Update databases
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
    print_success "Updated desktop database"
fi

if command -v gtk-update-icon-cache &> /dev/null; then
    gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
    print_success "Updated icon cache"
fi

print_success "Hakpak has been uninstalled!"
print_warning "Note: Kali repository and installed packages remain intact"
print_info "To remove Kali repository, run: sudo hakpak --remove-repo (if still available)"
