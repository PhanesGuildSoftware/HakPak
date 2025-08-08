#!/bin/bash

#!/bin/bash

# HakPak Universal Installer
# Main installer script for HakPak after download and unzip
# Author: Teyvone Wells @ PhanesGuild Software LLC

# Exit on any error
set -euo pipefail

# Colors for output
declare -r GREEN='\033[0;32m'
declare -r RED='\033[0;31m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m' # No Color

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

print_header() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "██   ██  █████  ██   ██ ██████   █████  ██   ██"
    echo "██   ██ ██   ██ ██  ██  ██   ██ ██   ██ ██  ██ "
    echo "███████ ███████ █████   ██████  ███████ █████  "
    echo "██   ██ ██   ██ ██  ██  ██      ██   ██ ██  ██ "
    echo "██   ██ ██   ██ ██   ██ ██      ██   ██ ██   ██"
    echo -e "${NC}"
    echo -e "${BOLD}${GREEN}Universal Kali Tools Installer for Debian-Based Systems${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Author:${NC} Teyvone Wells @ PhanesGuild Software LLC"
    echo -e "${BLUE}Version:${NC} 2.0"
    echo -e "${BLUE}Support:${NC} https://phanesguild.com"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo
}

# Detect distribution
detect_distribution() {
    print_info "Detecting system compatibility..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect distribution - /etc/os-release not found"
        exit 1
    fi
    
    # Extract distribution info
    local os_info
    os_info=$(cat /etc/os-release)
    local distro_id=$(echo "$os_info" | grep '^ID=' | cut -d'=' -f2- | tr -d '"')
    local distro_name=$(echo "$os_info" | grep '^NAME=' | cut -d'=' -f2- | tr -d '"')
    local distro_version=$(echo "$os_info" | grep '^VERSION_ID=' | cut -d'=' -f2- | tr -d '"')
    
    # Check if distribution is supported
    case "$distro_id" in
        ubuntu|debian|pop|linuxmint|parrot)
            print_success "Supported distribution detected: $distro_name $distro_version"
            ;;
        *)
            print_warning "Distribution '$distro_name' may not be fully supported"
            print_info "HakPak officially supports: Ubuntu, Debian, Pop!_OS, Linux Mint, Parrot OS"
            read -rp "Continue anyway? [y/N]: " continue_unsupported
            [[ $continue_unsupported =~ ^[Yy]$ ]] || exit 1
            ;;
    esac
}

# Check system requirements
check_requirements() {
    print_info "Checking system requirements..."
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        print_info "Testing sudo access..."
        if ! sudo true; then
            print_error "This installation requires sudo privileges"
            print_info "Please ensure your user account can use sudo"
            exit 1
        fi
    fi
    print_success "Sudo access confirmed"
    
    # Check available disk space (minimum 2GB)
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
        print_warning "Low disk space detected: $(( available_space / 1024 / 1024 ))GB available"
        print_info "Minimum recommended: 2GB free space"
        print_info "For full toolset installation: 8GB+ recommended"
        read -rp "Continue with installation? [y/N]: " continue_low_space
        [[ $continue_low_space =~ ^[Nn]$ ]] && exit 1
    else
        print_success "Sufficient disk space available: $(( available_space / 1024 / 1024 ))GB"
    fi
    
    # Check internet connectivity
    print_info "Testing internet connectivity..."
    if ! timeout 10 ping -c 1 8.8.8.8 &> /dev/null; then
        print_warning "Internet connectivity test failed"
        print_info "Internet access is required for package installation"
        read -rp "Continue anyway? [y/N]: " continue_offline
        [[ $continue_offline =~ ^[Nn]$ ]] && exit 1
    else
        print_success "Internet connectivity verified"
    fi
    
    # Check for required commands
    local required_commands=("apt" "dpkg" "curl" "wget")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command not found: $cmd"
            exit 1
        fi
    done
    print_success "Required system commands available"
}

# Verify installation files
verify_files() {
    print_info "Verifying installation package..."
    
    local required_files=(
        "hakpak.sh"
        "hakpak-launcher.sh"
        "install-desktop.sh"
        "com.phanesguild.hakpak.policy"
        "hakpak.svg"
    )
    
    local missing_files=()
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Installation package is incomplete. Missing files:"
        for file in "${missing_files[@]}"; do
            echo "  • $file"
        done
        print_info "Please re-download the complete HakPak package"
        exit 1
    fi
    
    print_success "All required files present"
}

# Generate missing PNG icons from SVG
generate_icons() {
    print_info "Preparing application icons..."
    
    # Check if ImageMagick is available
    if ! command -v convert &> /dev/null; then
        print_info "Installing ImageMagick for icon generation..."
        sudo apt update -qq
        sudo apt install -y imagemagick
    fi
    
    # Generate PNG icons from SVG if they don't exist
    local sizes=(16 32 48 64 128)
    for size in "${sizes[@]}"; do
        if [[ ! -f "hakpak-${size}.png" ]] && [[ -f "hakpak.svg" ]]; then
            print_info "Generating ${size}x${size} icon..."
            convert "hakpak.svg" -resize "${size}x${size}" "hakpak-${size}.png" 2>/dev/null || {
                print_warning "Failed to generate ${size}x${size} icon"
            }
        fi
    done
    
    print_success "Application icons prepared"
}

# Show installation options
show_options() {
    echo
    echo -e "${BOLD}${YELLOW}INSTALLATION OPTIONS${NC}"
    echo "════════════════════════════════════════"
    echo "1) 🖥️  Desktop Application (Recommended)"
    echo "   • Installs HakPak as a desktop application"
    echo "   • Creates desktop shortcut and menu entry"
    echo "   • Includes GUI launcher with authentication"
    echo "   • Best for desktop users"
    echo
    echo "2) 💻 Command Line Only"
    echo "   • Installs HakPak for terminal use only"
    echo "   • No desktop integration"
    echo "   • Minimal installation"
    echo "   • Best for servers or minimal systems"
    echo
    echo "3) 📦 Portable Mode"
    echo "   • Runs HakPak from current directory"
    echo "   • No system installation required"
    echo "   • Temporary usage"
    echo "   • Best for testing or single use"
    echo
    echo "4) ❌ Cancel Installation"
    echo
}

# Install desktop application mode
install_desktop_mode() {
    print_info "Starting desktop application installation..."
    
    # Generate icons if needed
    generate_icons
    
    # Run desktop installer
    if [[ -f "install-desktop.sh" ]]; then
        chmod +x install-desktop.sh
        if ./install-desktop.sh; then
            print_success "Desktop application installation completed!"
            return 0
        else
            print_error "Desktop installation failed"
            return 1
        fi
    else
        print_error "Desktop installer script not found"
        return 1
    fi
}

# Install command line only mode
install_cli_mode() {
    print_info "Starting command line installation..."
    
    # Install main script only
    if sudo cp hakpak.sh /usr/local/bin/hakpak; then
        sudo chmod +x /usr/local/bin/hakpak
        print_success "HakPak CLI installed to /usr/local/bin/hakpak"
        
        echo
        print_success "Command line installation completed!"
        echo
        print_info "Usage: hakpak --help"
        print_info "Example: sudo hakpak --install kali-linux-top10"
        return 0
    else
        print_error "Failed to install HakPak CLI"
        return 1
    fi
}

# Run portable mode
run_portable_mode() {
    print_info "Starting HakPak in portable mode..."
    
    # Make hakpak.sh executable
    chmod +x hakpak.sh
    
    print_success "HakPak ready to run in portable mode"
    echo
    print_info "Usage: sudo ./hakpak.sh"
    print_warning "Note: Running in portable mode - no system installation performed"
    
    # Ask if user wants to run now
    read -rp "Run HakPak now? [Y/n]: " run_now
    if [[ $run_now =~ ^[Nn]$ ]]; then
        return 0
    fi
    
    # Run HakPak
    sudo ./hakpak.sh
}

# Post-installation information
show_post_install_info() {
    local install_mode="$1"
    
    echo
    echo -e "${BOLD}${GREEN}🎉 HakPak Installation Successful! 🎉${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    case "$install_mode" in
        "desktop")
            echo -e "${BOLD}Desktop Application Mode Installed${NC}"
            echo
            echo -e "${GREEN}🖥️  Desktop Access:${NC}"
            echo -e "   ${BLUE}•${NC} Look for 'HakPak' icon on your desktop"
            echo -e "   ${BLUE}•${NC} Search 'HakPak' in your application menu"
            echo -e "   ${BLUE}•${NC} Find it under System Tools/Administration"
            echo
            echo -e "${GREEN}⚡ Quick Actions:${NC}"
            echo -e "   ${BLUE}•${NC} Right-click desktop icon for quick installs"
            echo -e "   ${BLUE}•${NC} Double-click to open interactive menu"
            echo
            echo -e "${GREEN}💻 Terminal Access:${NC}"
            echo -e "   ${BLUE}•${NC} Run: hakpak"
            echo -e "   ${BLUE}•${NC} Help: hakpak --help"
            ;;
        "cli")
            echo -e "${BOLD}Command Line Mode Installed${NC}"
            echo
            echo -e "${GREEN}💻 Terminal Usage:${NC}"
            echo -e "   ${BLUE}•${NC} Interactive menu: sudo hakpak"
            echo -e "   ${BLUE}•${NC} Install Top 10: sudo hakpak --install kali-linux-top10"
            echo -e "   ${BLUE}•${NC} Help & options: hakpak --help"
            ;;
        "portable")
            return 0  # Already shown in run_portable_mode
            ;;
    esac
    
    echo
    echo -e "${YELLOW}⚠️  Important Notes:${NC}"
    echo -e "   ${BLUE}•${NC} HakPak requires sudo/administrator privileges"
    echo -e "   ${BLUE}•${NC} You'll be prompted for your password when launching"
    echo -e "   ${BLUE}•${NC} Ensure stable internet connection for installations"
    echo -e "   ${BLUE}•${NC} Check /var/log/hakpak.log for detailed logs"
    echo
    echo -e "${BOLD}${BLUE}Ready to forge your security toolkit! 🛡️⚒️${NC}"
    echo
}

# Main installation function
main() {
    # Show header
    print_header
    
    # Pre-installation checks
    detect_distribution
    check_requirements
    verify_files
    
    # Show installation options
    show_options
    
    # Get user choice
    while true; do
        read -rp "Select installation option [1-4]: " choice
        
        case "$choice" in
            1)
                if install_desktop_mode; then
                    show_post_install_info "desktop"
                    break
                else
                    print_error "Desktop installation failed"
                    exit 1
                fi
                ;;
            2)
                if install_cli_mode; then
                    show_post_install_info "cli"
                    break
                else
                    print_error "CLI installation failed"
                    exit 1
                fi
                ;;
            3)
                run_portable_mode
                show_post_install_info "portable"
                break
                ;;
            4)
                print_info "Installation cancelled by user"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-4."
                ;;
        esac
    done
    
    # Clean up
    print_info "Cleaning up temporary files..."
    # Remove generated icons if they were created by this script
    # (Keep them if user wants to reinstall later)
    
    print_success "Installation completed successfully!"
}

# Check if running as root (should not be)
if [[ $EUID -eq 0 ]]; then
    print_error "Please do not run this installer as root"
    print_info "The installer will use sudo when needed"
    print_info "Run as: ./install.sh"
    exit 1
fi

# Make sure we're in the right directory
if [[ ! -f "hakpak.sh" ]]; then
    print_error "Please run this installer from the HakPak directory"
    print_info "Ensure you've extracted the HakPak package and are in the correct folder"
    exit 1
fi

# Run main installation
main "$@"

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      HAKPAK INSTALLER                       ║"
    echo "║            Quick Setup for Debian-Based Systems             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_requirements() {
    print_info "Checking system requirements..."
    
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
                read -p "Continue anyway? [y/N]: " -n 1 -r
                echo
                [[ $REPLY =~ ^[Yy]$ ]] || exit 1
                ;;
        esac
    else
        print_warning "Cannot detect distribution"
    fi
    
    # Check if sudo available
    if ! command -v sudo &> /dev/null; then
        print_warning "sudo is required for installation"
        exit 1
    fi
    
    print_success "System requirements met"
}

install_hakpak() {
    local install_dir="$1"
    
    print_info "Installing Hakpak to $install_dir..."
    
    # Create directory if it doesn't exist
    sudo mkdir -p "$install_dir"
    
    # Copy script
    sudo cp "$(dirname "$0")/hakpak.sh" "$install_dir/"
    sudo chmod +x "$install_dir/hakpak.sh"
    
    # Create symlink for global access
    sudo ln -sf "$install_dir/hakpak.sh" /usr/local/bin/hakpak 2>/dev/null || true
    
    print_success "Hakpak installed successfully"
}

show_usage() {
    echo
    print_info "Usage options:"
    echo "  1. Run directly: sudo $PWD/hakpak.sh"
    echo "  2. Run globally: sudo hakpak (if symlink created)"
    echo "  3. Run from install directory: sudo $1/hakpak.sh"
    echo
    print_info "For help and documentation, see: README.md"
}

main() {
    print_header
    
    check_requirements
    
    # Default installation directory
    local default_dir="/opt/hakpak"
    
    print_info "Choose installation option:"
    echo "1) Install to $default_dir (recommended)"
    echo "2) Specify custom directory"
    echo "3) Run from current directory"
    echo "4) Exit"
    
    read -p "Select option [1-4]: " -n 1 -r choice
    echo
    
    case $choice in
        1)
            install_hakpak "$default_dir"
            show_usage "$default_dir"
            ;;
        2)
            read -p "Enter installation directory: " custom_dir
            install_hakpak "$custom_dir"
            show_usage "$custom_dir"
            ;;
        3)
            print_info "Making script executable in current directory..."
            chmod +x "$(dirname "$0")/hakpak.sh"
            print_success "Ready to run: sudo ./hakpak.sh"
            ;;
        4)
            print_info "Installation cancelled"
            exit 0
            ;;
        *)
            print_warning "Invalid option"
            exit 1
            ;;
    esac
    
    echo
    read -p "Run Hakpak now? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        case $choice in
            1|2)
                if [[ $choice -eq 1 ]]; then
                    sudo "$default_dir/hakpak.sh"
                else
                    sudo "$custom_dir/hakpak.sh"
                fi
                ;;
            3)
                sudo "$(dirname "$0")/hakpak.sh"
                ;;
        esac
    else
        print_success "Installation complete! Run when ready."
    fi
}

main "$@"
