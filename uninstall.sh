#!/bin/bash

# HakPak Uninstaller
# Clean removal of HakPak installation
# Author: Teyvone Wells @ PhanesGuild Software LLC

set -euo pipefail

# Colors
declare -r GREEN='\033[0;32m'
declare -r RED='\033[0;31m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

show_header() {
    echo -e "${BOLD}${BLUE}"
    echo "██   ██  █████  ██   ██ ██████   █████  ██   ██"
    echo "██   ██ ██   ██ ██  ██  ██   ██ ██   ██ ██  ██ "
    echo "███████ ███████ █████   ██████  ███████ █████  "
    echo "██   ██ ██   ██ ██  ██  ██      ██   ██ ██  ██ "
    echo "██   ██ ██   ██ ██   ██ ██      ██   ██ ██   ██"
    echo -e "${NC}"
    echo -e "${BOLD}${RED}HakPak Uninstaller${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo
}

# Check if running as root
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root directly"
        print_info "It will use sudo when needed"
        exit 1
    fi
    
    # Test sudo access
    if ! sudo -n true 2>/dev/null; then
        if ! sudo true; then
            print_error "This script requires sudo privileges"
            exit 1
        fi
    fi
}

# Remove all HakPak files
uninstall_hakpak() {
    print_info "Removing HakPak installation..."
    
    local removed_count=0
    
    # Remove system files
    if [[ -d "/opt/hakpak" ]]; then
        sudo rm -rf "/opt/hakpak"
        print_success "Removed installation directory"
        ((removed_count++))
    fi
    
    if [[ -f "/usr/local/bin/hakpak" ]]; then
        sudo rm -f "/usr/local/bin/hakpak"
        print_success "Removed system executable"
        ((removed_count++))
    fi
    
    # Remove desktop integration
    if [[ -f "/usr/share/applications/hakpak.desktop" ]]; then
        sudo rm -f "/usr/share/applications/hakpak.desktop"
        print_success "Removed desktop entry"
        ((removed_count++))
    fi
    
    if [[ $removed_count -eq 0 ]]; then
        print_warning "No HakPak files found to remove"
    fi
    
    # Update system caches
    print_info "Updating system caches..."
    if command -v update-desktop-database &> /dev/null; then
        sudo update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
    
    print_success "System caches updated"
}

# Check what's installed
check_installation() {
    print_info "Checking for HakPak installation..."
    
    local found_items=0
    
    [[ -d "/opt/hakpak" ]] && { echo "  • Installation directory: /opt/hakpak"; ((found_items++)); }
    [[ -f "/usr/local/bin/hakpak" ]] && { echo "  • System executable: /usr/local/bin/hakpak"; ((found_items++)); }
    [[ -f "/usr/share/applications/hakpak.desktop" ]] && { echo "  • Desktop entry"; ((found_items++)); }
    
    if [[ $found_items -eq 0 ]]; then
        print_warning "No HakPak installation found"
        return 1
    else
        print_info "Found $found_items HakPak components"
        return 0
    fi
}

# Main uninstall process
main() {
    show_header
    
    case "${1:-}" in
        --check)
            check_installation
            exit $?
            ;;
        --force)
            print_warning "Force removal mode"
            ;;
        --help)
            echo "HakPak Uninstaller"
            echo ""
            echo "Usage: $0 [OPTION]"
            echo ""
            echo "Options:"
            echo "  --check   Check what's installed"
            echo "  --force   Force removal without confirmation"
            echo "  --help    Show this help"
            echo ""
            echo "Default: Interactive uninstall with confirmation"
            exit 0
            ;;
    esac
    
    check_privileges
    
    if ! check_installation; then
        exit 0
    fi
    
    echo
    if [[ "${1:-}" != "--force" ]]; then
        print_warning "This will completely remove HakPak from your system"
        read -rp "Continue with uninstallation? [y/N]: " confirm
        [[ $confirm =~ ^[Yy]$ ]] || { print_info "Uninstall cancelled"; exit 0; }
        echo
    fi
    
    uninstall_hakpak
    
    echo
    print_success "🗑️  HakPak has been completely uninstalled!"
    print_info "Thank you for using HakPak"
    echo
}

main "$@"
