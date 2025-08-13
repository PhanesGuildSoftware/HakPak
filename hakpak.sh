#!/bin/bash

# HakPak v1.0 - Professional Security Toolkit for Ubuntu 24.04
# Author: Teyvone Wells @ PhanesGuild Software LLC

set -euo pipefail

# Version and branding
readonly HAKPAK_VERSION="1.0"
readonly SCRIPT_NAME="HakPak"

# Colors
declare -r GREEN='\033[0;32m'
declare -r RED='\033[0;31m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r PURPLE='\033[0;35m'
declare -r CYAN='\033[0;36m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

# Output functions
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

show_header() {
    clear
    echo -e "${BOLD}${CYAN}██╗  ██╗ █████╗ ██╗  ██╗██████╗  █████╗ ██╗  ██╗${NC}"
    echo -e "${BOLD}${CYAN}██║  ██║██╔══██╗██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝${NC}"
    echo -e "${BOLD}${CYAN}███████║███████║█████╔╝ ██████╔╝███████║█████╔╝${NC} "
    echo -e "${BOLD}${CYAN}██╔══██║██╔══██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗${NC} "
    echo -e "${BOLD}${CYAN}██║  ██║██║  ██║██║  ██╗██║     ██║  ██║██║  ██╗${NC}"
    echo -e "${BOLD}${BLUE}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝${NC}"
    echo
    echo -e "${BOLD}${GREEN}Professional Security Toolkit v${HAKPAK_VERSION}${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Author:${NC} Teyvone Wells @ PhanesGuild Software LLC"
    echo -e "${BLUE}Platform:${NC} Ubuntu 24.04 LTS (Tested & Verified)"
    echo -e "${BLUE}Tools:${NC} 15 Essential Security Tools"
    echo -e "${BLUE}Support:${NC} https://www.phanesguild.llc"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo
}
declare LOG_FILE="/var/log/hakpak.log"  # Not readonly to allow fallback
declare -r KALI_REPO_URL="http://http.kali.org/kali"
declare -r KALI_GPG_URL="https://archive.kali.org/archive-key.asc"

# Distribution variables (set by detect_distribution)
declare DISTRO_NAME=""
declare DISTRO_VERSION=""
declare DISTRO_CODENAME=""
declare DISTRO_ARCH=""
declare DISTRO_ID=""   # <-- make ID global so other funcs can use it

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Enhanced print functions
print_banner() {
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        HAKPAK v$HAKPAK_VERSION                          ║"
    echo "║            Universal Kali Tools Installer                   ║"
    echo "║              Forge Wisely. Strike Precisely.                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}[i]${NC} Detected: $DISTRO_NAME $DISTRO_VERSION ($DISTRO_ARCH)"
    echo ""
}

print_help() {
    echo -e "${BLUE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    HAKPAK v$HAKPAK_VERSION - HELP                        ║"
    echo "║         Professional Security Toolkit (License Required)    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}USAGE:${NC}"
    echo "  sudo hakpak [OPTION]"
    echo ""
    echo -e "${BOLD}LICENSING:${NC}"
    echo "  ⚠️  HakPak requires a valid license for all operations"
    echo "  🔑 Activate: sudo hakpak --activate YOUR_LICENSE_KEY"
    echo "  🛒 Purchase: https://phanesguild.llc/hakpak"
    echo ""
    echo -e "${BOLD}OPTIONS:${NC}"
    echo "  --gui                   Launch graphical interface"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  -s, --status            Show system status and installed packages"
    echo "  --setup-repo            Setup Kali repository only"
    echo "  --remove-repo           Remove Kali repository and preferences"
    echo "  --fix-deps              Fix dependency issues"
    echo "  --list-metapackages     List all available Kali metapackages"
    echo "  --install PACKAGE       Install specific metapackage or tool"
    echo "  --interactive           Launch interactive menu (default)"
    echo ""
    echo -e "${BOLD}LICENSE OPTIONS:${NC}"
    echo "  --license-status        Show HakPak license status and features"
    echo "  --validate-license      Validate license file"
    echo "  --activate LICENSE_KEY  Activate HakPak with license key"
    echo "  --dashboard             Show HakPak system overview (license required)"
    echo "  --install-comprehensive Install comprehensive toolset (license required)"
    echo ""
    echo -e "${BOLD}EXAMPLES:${NC}"
    echo "  sudo hakpak --activate LICENSE_KEY       # First step: activate license"
    echo "  sudo hakpak                              # Launch interactive menu"
    echo "  sudo hakpak --status                     # Show system status"
    echo "  sudo hakpak --install nmap               # Install specific tool"
    echo "  sudo hakpak --install sqlmap             # Install SQL injection tool"
    echo "  sudo hakpak --install hydra              # Install password cracker"
    echo "  sudo hakpak --list-metapackages          # Show available packages"
    echo "  sudo hakpak --setup-repo                 # Setup repository only"
    echo "  sudo hakpak --fix-deps                   # Fix broken packages"
    echo "  sudo hakpak --license-status             # Show license info"
    echo "  sudo hakpak --pro-dashboard              # Access Pro system overview"
    echo "  sudo hakpak --install-pro-suite          # Install Pro security tools"
    echo "  sudo hakpak --init                       # Initialize with mode detection"
    echo ""
    echo -e "${BOLD}SUPPORTED DISTRIBUTIONS:${NC}"
    echo "  • Ubuntu 24.04 LTS (Tested & Verified)"
    echo "  • Other Debian-based distributions (Untested - Use at own risk)"
    echo ""
    echo -e "${BOLD}AVAILABLE TOOLS (15 Essential Security Tools):${NC}"
    echo "  • Network: nmap, sqlmap, nikto"
    echo "  • Web Testing: dirb, gobuster, wfuzz, ffuf"
    echo "  • Password: hydra, john, hashcat"
    echo "  • Analysis: wireshark, tcpdump, netcat"
    echo "  • Exploitation: exploitdb, searchsploit"
    echo ""
    echo -e "${BOLD}SYSTEM REQUIREMENTS:${NC}"
    echo "  • Ubuntu 24.04 LTS (Primary support)"
    echo "  • Root/sudo privileges"
    echo "  • Internet connection"
    echo "  • 5GB+ available disk space"
    echo ""
    echo -e "${BOLD}SUPPORT:${NC}"
    echo "  • Log file: /var/log/hakpak.log"
    echo "  • Website: https://www.phanesguild.llc"
    echo "  • Email: owner@phanesguild.llc"
    echo "  • Discord: PhanesGuildSoftware"
    echo "  • GitHub: https://github.com/PhanesGuildSoftware"
    echo "  • PhanesGuild Software LLC"
    echo ""
}

print_version() {
    echo -e "${BOLD}Hakpak v$HAKPAK_VERSION${NC}"
    echo "Universal Kali Tools Installer for Debian-Based Systems"
    echo "Copyright © 2025 PhanesGuild Software LLC"
    echo ""
    echo "Supported distributions: Ubuntu, Debian, Pop!_OS, Linux Mint, Parrot OS"
    echo "This program installs Kali Linux security tools with proper repository management."
    echo ""
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    log_message "INFO" "$1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1" >&2
    log_message "ERROR" "$1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    log_message "WARN" "$1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
    log_message "INFO" "$1"
}

# Distribution detection layer
detect_distribution() {
    print_info "Detecting distribution..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot detect distribution - /etc/os-release not found"
        exit 1
    fi
    
    # Use a completely isolated approach to avoid any variable conflicts
    local os_info
    
    # Read file contents in a way that prevents any variable assignment attempts
    os_info=$(sed 's/^VERSION=/OS_VERSION=/' /etc/os-release)
    
    # Extract values directly without sourcing to avoid readonly conflicts
    DISTRO_NAME=$(echo "$os_info" | grep '^NAME=' | cut -d'=' -f2- | tr -d '"')
    DISTRO_VERSION=$(echo "$os_info" | grep '^VERSION_ID=' | cut -d'=' -f2- | tr -d '"')
    [[ -z "$DISTRO_VERSION" ]] && DISTRO_VERSION="unknown"
    
    # Try VERSION_CODENAME first, then UBUNTU_CODENAME as fallback
    DISTRO_CODENAME=$(echo "$os_info" | grep '^VERSION_CODENAME=' | cut -d'=' -f2- | tr -d '"')
    [[ -z "$DISTRO_CODENAME" ]] && DISTRO_CODENAME=$(echo "$os_info" | grep '^UBUNTU_CODENAME=' | cut -d'=' -f2- | tr -d '"')
    
    # Extract ID for distribution checking
    DISTRO_ID=$(echo "$os_info" | grep '^ID=' | cut -d'=' -f2- | tr -d '"')

    DISTRO_ARCH=$(dpkg --print-architecture)
    
    # Check if distribution is supported
    case "$DISTRO_ID" in
        ubuntu)
            if [[ $(echo "$DISTRO_VERSION 20.04" | awk '{print ($1 >= $2)}') -eq 0 ]]; then
                print_error "Ubuntu $DISTRO_VERSION not supported. Minimum required: 20.04"
                exit 1
            fi
            print_success "Ubuntu $DISTRO_VERSION detected and supported"
            ;;
        debian)
            if [[ $(echo "$DISTRO_VERSION 11" | awk '{print ($1 >= $2)}') -eq 0 ]]; then
                print_error "Debian $DISTRO_VERSION not supported. Minimum required: 11 (Bullseye)"
                exit 1
            fi
            print_success "Debian $DISTRO_VERSION detected and supported"
            ;;
        pop)
            print_success "Pop!_OS $DISTRO_VERSION detected and supported"
            ;;
        linuxmint)
            print_success "Linux Mint $DISTRO_VERSION detected and supported"
            ;;
        parrot)
            print_success "Parrot OS detected and supported"
            ;;
        *)
            print_error "Unsupported distribution: $DISTRO_NAME"
            print_info "Hakpak supports: Ubuntu, Debian, Pop!_OS, Linux Mint, Parrot OS"
            print_info "For support requests, contact PhanesGuild Software LLC"
            exit 1
            ;;
    esac
}

# Environment safety checks
perform_safety_checks() {
    print_info "Performing environment safety checks..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "Hakpak must be run as root (use sudo)"
        exit 1
    fi
    
    # Check network connectivity
    print_info "Testing network connectivity..."
    if ! timeout 10 ping -c 1 8.8.8.8 &> /dev/null; then
        if ! timeout 10 curl -s --head https://archive.kali.org &> /dev/null; then
            print_error "No internet connection detected"
            print_info "Hakpak requires internet access to download packages"
            exit 1
        fi
    fi
    print_success "Network connectivity verified"
    
    # Check available disk space (minimum 2GB)
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
        print_warning "Low disk space detected. At least 2GB recommended."
        print_info "Available: $(( available_space / 1024 / 1024 ))GB"
    else
        print_success "Sufficient disk space available"
    fi
    
    print_success "Environment safety checks completed"
}

# Check and install essential dependencies
check_dependencies() {
    print_info "Checking essential dependencies..."
    
    local dependencies=("curl" "wget" "apt-transport-https" "ca-certificates" "gnupg" "lsb-release")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if ! dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_info "Installing missing dependencies: ${missing_deps[*]}"
        if apt update && apt install -y "${missing_deps[@]}"; then
            print_success "Dependencies installed successfully"
        else
            print_error "Failed to install dependencies. Please install manually: ${missing_deps[*]}"
            exit 1
        fi
    else
        print_success "All dependencies satisfied"
    fi
}

# Enhanced dependency conflict resolution
resolve_version_conflicts() {
    print_info "Resolving package version conflicts for mixed repositories..."
    
    # Create apt preferences for stable Ubuntu packages
    cat <<EOF | tee /etc/apt/preferences.d/ubuntu-stability.pref > /dev/null
# Prefer Ubuntu packages for core system libraries
Package: ruby ruby-dev libruby*
Pin: release o=Ubuntu
Pin-Priority: 700

Package: python3* libpython3* python3-*
Pin: release o=Ubuntu  
Pin-Priority: 700

Package: libssl* libgcrypt* openssh-client* openssh-server*
Pin: release o=Ubuntu
Pin-Priority: 700

Package: samba-common-bin gss-ntlmssp
Pin: release o=Ubuntu
Pin-Priority: 700

# Block problematic Kali packages that conflict with Ubuntu base
Package: openssh-client-gssapi kali-system-core openssl-provider-legacy
Pin: release o=Kali
Pin-Priority: -1

# Block Kali versions of core system packages
Package: openssh-server openssh-client base-files systemd*
Pin: release o=Kali
Pin-Priority: -1
EOF

    # Handle specific problematic packages
    print_info "Managing problematic package versions..."
    
    # Remove conflicting Kali packages that have Ubuntu equivalents
    local conflicting_packages=(
        "python3-donut" "python3-pytz" "openssh-client-gssapi" 
        "beef-xss" "dradis" "fiked" "sslyze" "kali-system-core"
        "openssl-provider-legacy"
    )
    
    for pkg in "${conflicting_packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            print_info "Removing conflicting package: $pkg"
            apt remove -y "$pkg" || true
        fi
    done
    
    # Install Ubuntu-compatible alternatives
    print_info "Installing Ubuntu-compatible security tools..."
    apt install -y --no-install-recommends \
        python3-cryptography \
        python3-paramiko \
        python3-sqlalchemy \
        ruby \
        ruby-dev \
        openssh-client || true
    
    print_success "Version conflict resolution completed"
}

# Modular function: Setup Kali repository
setup_kali_repository() {
    print_info "Setting up Kali Linux repository..."
    
    # Check if already configured
    if [[ -f /etc/apt/sources.list.d/kali.list ]] && [[ -f /etc/apt/preferences.d/kali.pref ]]; then
        print_warning "Kali repository already configured"
        read -rp "Reconfigure? [y/N]: " reconfigure
        [[ $reconfigure =~ ^[Yy]$ ]] || return 0
    fi
    
    # Backup sources
    backup_sources_list
    
    # Add Kali repository
    echo "deb $KALI_REPO_URL kali-rolling main contrib non-free non-free-firmware" | tee /etc/apt/sources.list.d/kali.list > /dev/null
    
    # Set up pinning preferences with higher priorities for security tools
    cat <<EOF | tee /etc/apt/preferences.d/kali.pref > /dev/null
# Prevent automatic installation from Kali repository for system packages
Package: *
Pin: release o=Kali
Pin-Priority: 50

# Allow Kali metapackages and tools to be installed when explicitly requested
Package: kali-*
Pin: release o=Kali
Pin-Priority: 500

# Allow specific security tools from Kali with high priority
Package: nmap
Pin: release o=Kali
Pin-Priority: 500

Package: sqlmap
Pin: release o=Kali
Pin-Priority: 500

Package: nikto
Pin: release o=Kali
Pin-Priority: 500

Package: dirb
Pin: release o=Kali
Pin-Priority: 500

Package: gobuster
Pin: release o=Kali
Pin-Priority: 500

Package: hydra
Pin: release o=Kali
Pin-Priority: 500

Package: john
Pin: release o=Kali
Pin-Priority: 500

Package: hashcat
Pin: release o=Kali
Pin-Priority: 500

Package: wireshark*
Pin: release o=Kali
Pin-Priority: 500

Package: wfuzz
Pin: release o=Kali
Pin-Priority: 500

Package: ffuf
Pin: release o=Kali
Pin-Priority: 500

Package: exploitdb
Pin: release o=Kali
Pin-Priority: 500

Package: searchsploit
Pin: release o=Kali
Pin-Priority: 500

Package: aircrack-ng
Pin: release o=Kali
Pin-Priority: 500

Package: burpsuite
Pin: release o=Kali
Pin-Priority: 500

Package: metasploit-framework
Pin: release o=Kali
Pin-Priority: 500

Package: zaproxy
Pin: release o=Kali
Pin-Priority: 500

Package: recon-ng
Pin: release o=Kali
Pin-Priority: 500

Package: maltego
Pin: release o=Kali
Pin-Priority: 500

# Allow all security tools from Kali
Package: *cracker* *scan* *exploit* *sec* *hack* *pen* *vuln*
Pin: release o=Kali
Pin-Priority: 500
EOF

    # Add Kali GPG key with error handling
    if ! curl -fsSL "$KALI_GPG_URL" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/kali-archive.gpg > /dev/null; then
        print_error "Failed to add Kali GPG key"
        return 1
    fi
    
    # Resolve version conflicts before updating
    resolve_version_conflicts
    
    # Update package lists
    print_info "Updating package lists..."
    if ! apt update; then
        print_error "Failed to update package lists"
        return 1
    fi
    
    print_success "Kali repository configured successfully"
}

# Modular function: Install Kali Top 10 Tools
install_kali_top10() {
    print_info "Installing Essential Security Tools (Ubuntu 24.04 & Debian Compatible)..."
    setup_kali_repository || return 1

    # For Ubuntu 24.04 and Debian, install individual tools instead of metapackages
    if { [[ "$DISTRO_NAME" == *"Ubuntu"* ]] && [[ "$DISTRO_VERSION" == "24.04" ]]; } || [[ "$DISTRO_NAME" == *"Debian"* ]]; then
        print_info "Ubuntu 24.04 or Debian detected - installing compatible individual tools..."

        local essential_tools=(
            "nmap"              # Network scanner
            "sqlmap"            # SQL injection testing  
            "nikto"             # Web vulnerability scanner
            "dirb"              # Directory brute forcer
            "gobuster"          # Directory/file brute forcer
            "hydra"             # Password brute forcer
            "john"              # Password cracker
            "hashcat"           # Advanced password recovery
            "wireshark"         # Network protocol analyzer
            "tcpdump"           # Packet analyzer
            "netcat-traditional" # Network utility
            "wfuzz"             # Web application fuzzer
            "ffuf"              # Fast web fuzzer
            "exploitdb"         # Exploit database
            "searchsploit"      # Exploit search tool
        )

        local installed_count=0
        local total_tools=${#essential_tools[@]}

        print_info "Installing $total_tools essential security tools..."

        for tool in "${essential_tools[@]}"; do
            if install_package_safe "$tool" "$tool"; then
                ((installed_count++))
            else
                print_warning "Skipped: $tool (not available or conflicts)"
            fi
        done

        echo ""
        print_success "Essential Tools Installation Complete!"
        print_info "Successfully installed: $installed_count out of $total_tools tools"

        if [[ $installed_count -gt 10 ]]; then
            print_success "You now have a comprehensive security toolkit!"
        elif [[ $installed_count -gt 5 ]]; then
            print_success "You have a solid foundation of security tools!"
        else
            print_warning "Some tools had conflicts. Try installing them individually."
        fi

        return 0
    else
        # For other distributions, try the metapackage
        print_info "Installing kali-linux-default metapackage..."
        install_package_safe "kali-linux-default" "Kali Linux Essential Tools"
    fi
}

# Modular function: Install Full Kali Tools
install_kali_full() {
    if { [[ "$DISTRO_NAME" == *"Ubuntu"* ]] && [[ "$DISTRO_VERSION" == "24.04" ]]; } || [[ "$DISTRO_NAME" == *"Debian"* ]]; then
        print_warning "Ubuntu 24.04 or Debian Compatibility Notice"
        echo "Large Kali metapackages have dependency conflicts with Ubuntu 24.04 and Debian."
        echo "Instead, HakPak will install compatible tool collections."
        echo ""
        read -rp "Continue with compatible installation? [Y/n]: " confirm
        [[ $confirm =~ ^[Nn]$ ]] && return 0

        setup_kali_repository || return 1

        print_info "Installing comprehensive security tool collection for Ubuntu 24.04/Debian..."

        # Install working tool categories
        local tool_categories=(
            "Information Gathering Tools"
            "Web Application Security"
            "Network Analysis Tools" 
            "Password Security Tools"
            "Vulnerability Assessment"
        )

        local category_tools=(
            "nmap wireshark tcpdump netcat-traditional dnsutils whois"
            "sqlmap nikto dirb gobuster wfuzz ffuf zaproxy"
            "ettercap-text-only arp-scan netdiscover masscan"
            "hydra john hashcat wordlists"
            "exploitdb searchsploit lynis chkrootkit"
        )

        local total_installed=0

        for i in "${!tool_categories[@]}"; do
            echo ""
            print_info "Installing: ${tool_categories[$i]}"

            local tools_in_category=(${category_tools[$i]})
            local category_count=0

            for tool in "${tools_in_category[@]}"; do
                if install_package_safe "$tool" "$tool"; then
                    ((category_count++))
                    ((total_installed++))
                fi
            done

            print_info "Category complete: $category_count tools installed"
        done

        echo ""
        print_success "Ubuntu 24.04/Debian Compatible Installation Complete!"
        print_info "Total tools installed: $total_installed"
        print_info "This provides comprehensive security testing capabilities."

        return 0
    else
        # Original full installation for other distributions
        print_warning "Installing Full Kali Toolset - This will install ~8GB+ of tools"
        read -rp "Continue? [y/N]: " confirm
        [[ $confirm =~ ^[Yy]$ ]] || return 0

        setup_kali_repository || return 1

        # Pre-install dependency resolution
        print_info "Preparing system for large installation..."
        fix_dependencies
    fi
    
    # Try installing core packages first to avoid conflicts
    print_info "Installing core Kali components..."
    
    # Skip problematic metapackages on Ubuntu 24.04 and try individual tools instead
    if [[ "$DISTRO_NAME" == *"Ubuntu"* ]] && [[ "$DISTRO_VERSION" == "24.04" ]]; then
        print_info "Ubuntu 24.04 detected - using compatible installation approach..."
        
        # Install essential tools individually to avoid metapackage conflicts
        print_info "Installing essential tools individually..."
        local essential_tools=(
            "nmap" "wireshark" "burpsuite" "sqlmap" "john" 
            "hashcat" "hydra" "gobuster" "nikto" "dirb"
            "metasploit-framework" "aircrack-ng" "recon-ng"
            "exploitdb" "searchsploit" "wfuzz" "ffuf"
            "maltego" "zaproxy" "beef-xss" "armitage"
            "ettercap-text-only" "tcpdump" "netcat-traditional"
        )
        
        local installed_count=0
        for tool in "${essential_tools[@]}"; do
            if install_package_safe "$tool" "$tool"; then
                ((installed_count++))
            else
                print_warning "Skipped: $tool (not available or conflicts)"
            fi
        done
        
        print_info "Successfully installed $installed_count out of ${#essential_tools[@]} essential tools"
        
        # Try installing some working metapackages
        print_info "Installing compatible tool collections..."
        install_package_safe "kali-tools-information-gathering" "Information Gathering Tools" || true
        install_package_safe "kali-tools-vulnerability-assessment" "Vulnerability Assessment Tools" || true
        install_package_safe "kali-tools-web-application" "Web Application Tools" || true
        
        return 0
    else
        # Original approach for other distributions
        apt install -y --no-install-recommends kali-linux-core kali-system-core || {
            print_warning "Core installation failed, attempting alternative approach..."
            
            # Try installing without problematic packages
            print_info "Installing essential tools individually..."
            local essential_tools=(
                "nmap" "wireshark" "burpsuite" "sqlmap" "john" 
                "hashcat" "hydra" "gobuster" "nikto" "dirb"
                "metasploit-framework" "aircrack-ng" "recon-ng"
                "exploitdb" "searchsploit" "wfuzz" "ffuf"
            )
            
            local installed_count=0
            for tool in "${essential_tools[@]}"; do
                if apt install -y --no-install-recommends "$tool" 2>/dev/null; then
                    ((installed_count++))
                    print_success "Installed: $tool"
                else
                    print_warning "Skipped: $tool (dependency conflict)"
                fi
            done
            
            print_info "Successfully installed $installed_count out of ${#essential_tools[@]} essential tools"
            return 0
        }
        
        # If core installation succeeded, try the full package
        install_large_package "kali-linux-large" "Full Kali Toolset"
    fi
}

# Modular function: Install individual tool
install_individual_tool() {
    local tool_name="$1"
    print_info "Installing individual tool: $tool_name"
    setup_kali_repository || return 1
    install_package_safe "$tool_name" "$tool_name"
}

# Modular function: Remove Kali repository
remove_kali_repository() {
    print_warning "This will remove the Kali repository and all pinning preferences"
    read -rp "Are you sure? [y/N]: " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_info "Removing Kali repository..."
        
        # Remove files if they exist
        [[ -f /etc/apt/sources.list.d/kali.list ]] && rm -f /etc/apt/sources.list.d/kali.list
        [[ -f /etc/apt/preferences.d/kali.pref ]] && rm -f /etc/apt/preferences.d/kali.pref
        [[ -f /etc/apt/trusted.gpg.d/kali-archive.gpg ]] && rm -f /etc/apt/trusted.gpg.d/kali-archive.gpg
        
        # Update package lists
        if apt update; then
            print_success "Kali repository removed successfully"
        else
            print_error "Error updating package lists after removal"
        fi
    else
        print_info "Operation cancelled"
    fi
}

# Custom Toolkits Manager - Full Implementation
custom_toolkits_manager() {
    print_info "Custom Toolkits Manager"
    
    while true; do
        echo -e "\n${BOLD}${BLUE}CUSTOM TOOLKITS MANAGER${NC}"
        echo "═══════════════════════════════════════"
        echo "1) Create New Toolkit"
        echo "2) List Existing Toolkits"
        echo "3) Install Toolkit"
        echo "4) Delete Toolkit"
        echo "5) Export Toolkit"
        echo "6) Import Toolkit"
        echo "7) Back to Main Menu"
        echo "═══════════════════════════════════════"
        read -rp "Select an option [1-7]: " toolkit_choice

        case $toolkit_choice in
            1) create_custom_toolkit ;;
            2) list_custom_toolkits ;;
            3) install_custom_toolkit ;;
            4) delete_custom_toolkit ;;
            5) export_custom_toolkit ;;
            6) import_custom_toolkit ;;
            7) return 0 ;;
            *) print_error "Invalid option. Please select 1-7." ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

# Custom Toolkit Functions
create_custom_toolkit() {
    print_info "Creating new custom toolkit..."
    
    # Create toolkit directory if it doesn't exist
    local toolkit_dir="/var/lib/hakpak/toolkits"
    mkdir -p "$toolkit_dir"
    
    read -rp "Enter toolkit name: " toolkit_name
    [[ -z "$toolkit_name" ]] && { print_error "Toolkit name cannot be empty"; return 1; }
    
    # Sanitize toolkit name
    toolkit_name=$(echo "$toolkit_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    local toolkit_file="$toolkit_dir/${toolkit_name}.toolkit"
    
    if [[ -f "$toolkit_file" ]]; then
        print_warning "Toolkit '$toolkit_name' already exists"
        read -rp "Overwrite? [y/N]: " overwrite
        [[ $overwrite =~ ^[Yy]$ ]] || return 0
    fi
    
    read -rp "Enter toolkit description: " toolkit_desc
    [[ -z "$toolkit_desc" ]] && toolkit_desc="Custom toolkit: $toolkit_name"
    
    # Create toolkit file header
    cat > "$toolkit_file" << EOF
# Hakpak Custom Toolkit
# Name: $toolkit_name
# Description: $toolkit_desc
# Created: $(date)
# Format: package_name|description|category

EOF
    
    print_success "Toolkit '$toolkit_name' created"
    
    # Add packages to toolkit
    while true; do
        echo ""
        read -rp "Add package to toolkit (empty to finish): " package_name
        [[ -z "$package_name" ]] && break
        
        read -rp "Package description (optional): " package_desc
        [[ -z "$package_desc" ]] && package_desc="$package_name"
        
        read -rp "Package category (optional): " package_cat
        [[ -z "$package_cat" ]] && package_cat="custom"
        
        echo "$package_name|$package_desc|$package_cat" >> "$toolkit_file"
         print_success "Added '$package_name' to toolkit"
    done
    
    print_success "Custom toolkit '$toolkit_name' created successfully"
    log_message "INFO" "Created custom toolkit: $toolkit_name"
}

list_custom_toolkits() {
    print_info "Listing custom toolkits..."
    
    local toolkit_dir="/var/lib/hakpak/toolkits"
    
    if [[ ! -d "$toolkit_dir" ]] || [[ -z "$(ls -A "$toolkit_dir"/*.toolkit 2>/dev/null)" ]]; then
        print_warning "No custom toolkits found"
        return 0
    fi
    
    echo -e "\n${BOLD}Available Custom Toolkits:${NC}"
    echo "─────────────────────────────────────"
    
    for toolkit_file in "$toolkit_dir"/*.toolkit; do
        [[ ! -f "$toolkit_file" ]] && continue
        
        local toolkit_name=$(basename "$toolkit_file" .toolkit)
        local toolkit_desc=$(grep "^# Description:" "$toolkit_file" | cut -d' ' -f3-)
        local package_count=$(grep -c "^[^#]" "$toolkit_file" || echo "0")
        
        echo -e "${GREEN}• $toolkit_name${NC}"
        echo -e "  Description: $toolkit_desc"
        echo -e "  Packages: $package_count"
        echo ""
    done
}

install_custom_toolkit() {
    print_info "Installing custom toolkit..."
    
    local toolkit_dir="/var/lib/hakpak/toolkits"
    
    if [[ ! -d "$toolkit_dir" ]] || [[ -z "$(ls -A "$toolkit_dir"/*.toolkit 2>/dev/null)" ]]; then
        print_warning "No custom toolkits found. Create one first."
        return 0
    fi
    
    echo "Available toolkits:"
    local -a toolkits=()
    local i=1
    
    for toolkit_file in "$toolkit_dir"/*.toolkit; do
        [[ ! -f "$toolkit_file" ]] && continue
        local toolkit_name=$(basename "$toolkit_file" .toolkit)
        toolkits+=("$toolkit_name")
        echo "$i) $toolkit_name"
        ((i++))
    done
    
    read -rp "Select toolkit number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#toolkits[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_toolkit="${toolkits[$((selection-1))]}"
    local toolkit_file="$toolkit_dir/${selected_toolkit}.toolkit"
    
    print_info "Installing toolkit: $selected_toolkit"
    
    # Setup repository if needed
    setup_kali_repository || return 1
    
    # Install packages from toolkit
    local installed=0
    local failed=0
    
    while IFS='|' read -r package_name package_desc package_cat; do
        [[ "$package_name" =~ ^#.*$ ]] && continue  # Skip comments
        [[ -z "$package_name" ]] && continue        # Skip empty lines
        
        print_info "Installing: $package_name ($package_desc)"
        
        if install_package_safe "$package_name" "$package_desc"; then
            ((installed++))
        else
            ((failed++))
        fi
    done < "$toolkit_file"
    
    echo ""
    print_success "Toolkit installation completed"
    print_info "Packages installed: $installed"
    [[ $failed -gt 0 ]] && print_warning "Packages failed: $failed"
    
    log_message "INFO" "Installed custom toolkit: $selected_toolkit ($installed packages)"
}

delete_custom_toolkit() {
    print_info "Deleting custom toolkit..."
    
    local toolkit_dir="/var/lib/hakpak/toolkits"
    
    if [[ ! -d "$toolkit_dir" ]] || [[ -z "$(ls -A "$toolkit_dir"/*.toolkit 2>/dev/null)" ]]; then
        print_warning "No custom toolkits found"
        return 0
    fi
    
    echo "Available toolkits:"
    local -a toolkits=()
    local i=1
    
    for toolkit_file in "$toolkit_dir"/*.toolkit; do
        [[ ! -f "$toolkit_file" ]] && continue
        local toolkit_name=$(basename "$toolkit_file" .toolkit)
        toolkits+=("$toolkit_name")
        echo "$i) $toolkit_name"
        ((i++))
    done
    
    read -rp "Select toolkit number to delete: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#toolkits[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_toolkit="${toolkits[$((selection-1))]}"
    
    print_warning "This will permanently delete toolkit: $selected_toolkit"
    read -rp "Are you sure? [y/N]: " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -f "$toolkit_dir/${selected_toolkit}.toolkit"
        print_success "Toolkit '$selected_toolkit' deleted"
        log_message "INFO" "Deleted custom toolkit: $selected_toolkit"
    else
        print_info "Operation cancelled"
    fi
}

export_custom_toolkit() {
    print_info "Exporting custom toolkit..."
    
    local toolkit_dir="/var/lib/hakpak/toolkits"
    
    if [[ ! -d "$toolkit_dir" ]] || [[ -z "$(ls -A "$toolkit_dir"/*.toolkit 2>/dev/null)" ]]; then
        print_warning "No custom toolkits found"
        return 0
    fi
    
    echo "Available toolkits:"
    local -a toolkits=()
    local i=1
    
    for toolkit_file in "$toolkit_dir"/*.toolkit; do
        [[ ! -f "$toolkit_file" ]] && continue
        local toolkit_name=$(basename "$toolkit_file" .toolkit)
        toolkits+=("$toolkit_name")
        echo "$i) $toolkit_name"
        ((i++))
    done
    
    read -rp "Select toolkit number to export: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#toolkits[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_toolkit="${toolkits[$((selection-1))]}"
    local export_file="$PWD/${selected_toolkit}_$(date +%Y%m%d_%H%M%S).toolkit"
    
    cp "$toolkit_dir/${selected_toolkit}.toolkit" "$export_file"
    print_success "Toolkit exported to: $export_file"
    log_message "INFO" "Exported custom toolkit: $selected_toolkit to $export_file"
}

import_custom_toolkit() {
    print_info "Importing custom toolkit..."
    
    read -rp "Enter path to toolkit file: " import_file
    
    if [[ ! -f "$import_file" ]]; then
        print_error "File not found: $import_file"
        return 1
    fi
    
    # Validate toolkit file format
    if ! grep -q "^# Hakpak Custom Toolkit" "$import_file"; then
        print_error "Invalid toolkit file format"
        return 1
    fi
    
    local toolkit_name=$(basename "$import_file" .toolkit)
    local toolkit_dir="/var/lib/hakpak/toolkits"
    mkdir -p "$toolkit_dir"
    
    local dest_file="$toolkit_dir/${toolkit_name}.toolkit"
    
    if [[ -f "$dest_file" ]]; then
        print_warning "Toolkit '$toolkit_name' already exists"
        read -rp "Overwrite? [y/N]: " overwrite
        [[ $overwrite =~ ^[Yy]$ ]] || return 0
    fi
    
    cp "$import_file" "$dest_file"
    print_success "Toolkit imported: $toolkit_name"
    log_message "INFO" "Imported custom toolkit: $toolkit_name from $import_file"
}

offline_installer_mode() {
    print_info "Offline Installer Mode"
    
    while true; do
        echo -e "\n${BOLD}${BLUE}OFFLINE INSTALLER MODE${NC}"
        echo "═══════════════════════════════════════"
        echo "1) Download Packages for Offline Use"
        echo "2) Install from Downloaded Packages"
        echo "3) Create Offline Repository"
        echo "4) List Downloaded Packages"
        echo "5) Clean Downloaded Packages"
        echo "6) Back to Main Menu"
        echo "═══════════════════════════════════════"
        read -rp "Select an option [1-6]: " offline_choice

        case $offline_choice in
            1) download_packages_offline ;;
            2) install_offline_packages ;;
            3) create_offline_repository ;;
            4) list_offline_packages ;;
            5) clean_offline_packages ;;
            6) return 0 ;;
            *) print_error "Invalid option. Please select 1-6." ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

# Offline Installer Functions
download_packages_offline() {
    print_info "Downloading packages for offline installation..."
    
    local offline_dir="/var/lib/hakpak/offline"
    mkdir -p "$offline_dir"
    
    echo "Select package collection to download:"
    echo "1) Kali Essential Tools"
    echo "2) Kali Default Tools"
    echo "3) Individual Package"
    echo "4) Custom Toolkit"
    
    read -rp "Select option [1-4]: " download_choice
    
    local package_list=""
    
    case $download_choice in
        1) package_list="kali-linux-default" ;;
        2) package_list="kali-linux-default" ;;
        3) 
            read -rp "Enter package name: " package_list
            [[ -z "$package_list" ]] && { print_error "Package name required"; return 1; }
            ;;
        4)
            local toolkit_dir="/var/lib/hakpak/toolkits"
            if [[ ! -d "$toolkit_dir" ]] || [[ -z "$(ls -A "$toolkit_dir"/*.toolkit 2>/dev/null)" ]]; then
                print_warning "No custom toolkits found"
                return 0
            fi
            
            echo "Available toolkits:"
            local -a toolkits=()
            local i=1
            
            for toolkit_file in "$toolkit_dir"/*.toolkit; do
                [[ ! -f "$toolkit_file" ]] && continue
                local toolkit_name=$(basename "$toolkit_file" .toolkit)
                toolkits+=("$toolkit_name")
                echo "$i) $toolkit_name"
                ((i++))
            done
            
            read -rp "Select toolkit number: " selection
            
            if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#toolkits[@]}" ]]; then
                print_error "Invalid selection"
                return 1
            fi
            
            local selected_toolkit="${toolkits[$((selection-1))]}"
            local toolkit_file="$toolkit_dir/${selected_toolkit}.toolkit"
            
            # Extract package names from toolkit
            package_list=$(grep -v "^#" "$toolkit_file" | grep -v "^$" | cut -d'|' -f1 | tr '\n' ' ')
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
    
    # Setup repository if needed
    setup_kali_repository || return 1
    
    print_info "Downloading packages and dependencies..."
    
    # Update package lists
    apt update
    
    # Download packages with dependencies
    if apt download $package_list $(apt-cache depends $package_list | grep "Depends:" | cut -d':' -f2 | tr -d ' ') 2>/dev/null; then
        # Move downloaded packages to offline directory
        mv *.deb "$offline_dir/" 2>/dev/null || true
        print_success "Packages downloaded to $offline_dir"
    else
        print_error "Failed to download some packages"
        return 1
    fi
    
    # Create package list file
    ls "$offline_dir"/*.deb > "$offline_dir/package_list.txt" 2>/dev/null || true
    
    print_success "Offline package download completed"
    log_message "INFO" "Downloaded offline packages: $package_list"
}

install_offline_packages() {
    print_info "Installing from offline packages..."
    
    local offline_dir="/var/lib/hakpak/offline"
    
    if [[ ! -d "$offline_dir" ]] || [[ -z "$(ls -A "$offline_dir"/*.deb 2>/dev/null)" ]]; then
        print_warning "No offline packages found. Download packages first."
        return 0
    fi
    
    print_info "Found offline packages in $offline_dir"
    local package_count=$(ls "$offline_dir"/*.deb 2>/dev/null | wc -l)
    print_info "Package count: $package_count"
    
    read -rp "Install all offline packages? [y/N]: " confirm
    [[ $confirm =~ ^[Yy]$ ]] || return 0
    
    print_info "Installing offline packages..."
    
    # Install packages using dpkg
    local installed=0
    local failed=0
    
    for deb_file in "$offline_dir"/*.deb; do
        [[ ! -f "$deb_file" ]] && continue
        
        local package_name=$(basename "$deb_file" | cut -d'_' -f1)
        print_info "Installing: $package_name"
        
        if dpkg -i "$deb_file" 2>/dev/null; then
            ((installed++))
        else
            ((failed++))
            print_warning "Failed to install: $package_name"
        fi
    done
    
    # Fix any dependency issues
    if [[ $failed -gt 0 ]]; then
        print_info "Fixing dependency issues..."
        apt --fix-broken install -y
    fi
    
    echo ""
    print_success "Offline installation completed"
    print_info "Packages installed: $installed"
    [[ $failed -gt 0 ]] && print_warning "Packages failed: $failed"
    
    log_message "INFO" "Installed offline packages: $installed successful, $failed failed"
}

create_offline_repository() {
    print_info "Creating offline repository..."
    
    local offline_dir="/var/lib/hakpak/offline"
    local repo_dir="$offline_dir/repository"
    
    if [[ ! -d "$offline_dir" ]] || [[ -z "$(ls -A "$offline_dir"/*.deb 2>/dev/null)" ]]; then
        print_warning "No offline packages found. Download packages first."
        return 0
    fi
    
    # Check if dpkg-scanpackages is available
    if ! command -v dpkg-scanpackages &> /dev/null; then
        print_info "Installing dpkg-dev for repository creation..."
        apt install -y dpkg-dev
    fi
    
    mkdir -p "$repo_dir"
    
    # Copy packages to repository directory
    cp "$offline_dir"/*.deb "$repo_dir/"
    
    # Create Packages file
    cd "$offline_dir"
    dpkg-scanpackages repository /dev/null | gzip -9c > repository/Packages.gz
    
    # Create Release file
    cat > repository/Release << EOF
Archive: hakpak-offline
Component: main
Origin: Hakpak Offline Repository
Label: Hakpak Offline
Suite: offline
Date: $(date -Ru)
Description: Hakpak Offline Package Repository
EOF
    
    print_success "Offline repository created at $repo_dir"
    print_info "To use this repository, add to sources.list:"
    echo "deb [trusted=yes] file://$repo_dir ./"
    
    log_message "INFO" "Created offline repository at $repo_dir"
}

list_offline_packages() {
    print_info "Listing offline packages..."
    
    local offline_dir="/var/lib/hakpak/offline"
    
    if [[ ! -d "$offline_dir" ]] || [[ -z "$(ls -A "$offline_dir"/*.deb 2>/dev/null)" ]]; then
        print_warning "No offline packages found"
        return 0
    fi
    
    echo -e "\n${BOLD}Downloaded Offline Packages:${NC}"
    echo "─────────────────────────────────────"
    
    local total_size=0
    local count=0
    
    for deb_file in "$offline_dir"/*.deb; do
        [[ ! -f "$deb_file" ]] && continue
        
        local package_name=$(basename "$deb_file" | cut -d'_' -f1)
        local package_version=$(basename "$deb_file" | cut -d'_' -f2)
        local file_size=$(du -h "$deb_file" | cut -f1)
        local file_size_bytes=$(du -b "$deb_file" | cut -f1)
        
        echo -e "${GREEN}• $package_name${NC} ($package_version) - $file_size"
        total_size=$((total_size + file_size_bytes))
        ((count++))
    done
    
    echo "─────────────────────────────────────"
    echo "Total packages: $count"
    echo "Total size: $(( total_size / 1024 / 1024 ))MB"
}

clean_offline_packages() {
    print_info "Cleaning offline packages..."
    
    local offline_dir="/var/lib/hakpak/offline"
    
    if [[ ! -d "$offline_dir" ]]; then
        print_info "No offline directory found"
        return 0
    fi
    
    local package_count=$(ls "$offline_dir"/*.deb 2>/dev/null | wc -l)
    
    if [[ $package_count -eq 0 ]]; then
        print_info "No offline packages to clean"
        return 0
    fi
    
    print_warning "This will delete $package_count offline packages"
    read -rp "Are you sure? [y/N]: " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -rf "$offline_dir"
        print_success "Offline packages cleaned"
        log_message "INFO" "Cleaned offline packages directory"
    else
        print_info "Operation cancelled"
    fi
}

container_isolation_mode() {
    print_info "Container Isolation Mode"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Installing Docker..."
        install_docker || return 1
    fi
    
    while true; do
        echo -e "\n${BOLD}${BLUE}CONTAINER ISOLATION MODE${NC}"
        echo "═══════════════════════════════════════"
        echo "1) Create Isolated Kali Container"
        echo "2) List Kali Containers"
        echo "3) Start Container"
        echo "4) Stop Container"
        echo "5) Enter Container Shell"
        echo "6) Install Tools in Container"
        echo "7) Export Container"
        echo "8) Import Container"
        echo "9) Remove Container"
        echo "10) Back to Main Menu"
        echo "═══════════════════════════════════════"
        read -rp "Select an option [1-10]: " container_choice

        case $container_choice in
            1) create_kali_container ;;
            2) list_kali_containers ;;
            3) start_kali_container ;;
            4) stop_kali_container ;;
            5) enter_container_shell ;;
            6) install_tools_in_container ;;
            7) export_kali_container ;;
            8) import_kali_container ;;
            9) remove_kali_container ;;
            10) return 0 ;;
            *) print_error "Invalid option. Please select 1-10." ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

# Container Isolation Functions
install_docker() {
    print_info "Installing Docker..."
    
    # Update package lists
    apt update
    
    # Install prerequisites
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Detect Debian vs Ubuntu for Docker repo
    . /etc/os-release
    local docker_base="ubuntu"
    if [[ "$ID" == "debian" ]]; then docker_base="debian"; fi
    
    # Add Docker's official GPG key
    curl -fsSL "https://download.docker.com/linux/${docker_base}/gpg" | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${docker_base} $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    print_success "Docker installed successfully"
    log_message "INFO" "Docker installed for container isolation"
}

create_kali_container() {
    print_info "Creating isolated Kali container..."
    
    read -rp "Enter container name: " container_name
    [[ -z "$container_name" ]] && { print_error "Container name cannot be empty"; return 1; }
    
    # Sanitize container name
    container_name=$(echo "$container_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    # Check if container already exists
    if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        print_warning "Container '$container_name' already exists"
        return 1
    fi
    
    echo "Select Kali base image:"
    echo "1) kalilinux/kali-rolling (latest rolling)"
    echo "2) kalilinux/kali-linux-docker (stable)"
    echo "3) kalilinux/kali-last-release (latest release)"
    
    read -rp "Select option [1-3]: " image_choice
    
    local kali_image=""
    case $image_choice in
        1) kali_image="kalilinux/kali-rolling" ;;
        2) kali_image="kalilinux/kali-linux-docker" ;;
        3) kali_image="kalilinux/kali-last-release" ;;
        *) print_error "Invalid option"; return 1 ;;
    esac
    
    print_info "Pulling Kali image: $kali_image"
    docker pull "$kali_image"
    
    print_info "Creating container: $container_name"
    
    # Create container with security tools directory mounted
    docker run -d \
        --name "$container_name" \
        --hostname "hakpak-${container_name}" \
        -v "/var/lib/hakpak/containers/${container_name}:/hakpak" \
        --cap-add=NET_ADMIN \
        --cap-add=NET_RAW \
        --security-opt apparmor:unconfined \
        "$kali_image" \
        tail -f /dev/null
    
    # Create container directory
    mkdir -p "/var/lib/hakpak/containers/${container_name}"
    
    # Initialize container with updates
    print_info "Initializing container..."
    docker exec "$container_name" apt update
    docker exec "$container_name" apt install -y kali-linux-core
    
    print_success "Kali container '$container_name' created successfully"
    log_message "INFO" "Created Kali container: $container_name"
}

list_kali_containers() {
    print_info "Listing Kali containers..."
    
    local containers=$(docker ps -a --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" 2>/dev/null)
    
    if [[ -z "$containers" ]] || [[ "$containers" == "NAMES"* ]]; then
        print_warning "No Kali containers found"
        return 0
    fi
    
    echo -e "\n${BOLD}Kali Containers:${NC}"
    echo "─────────────────────────────────────"
    echo "$containers"
}

start_kali_container() {
    print_info "Starting Kali container..."
    
    local containers=$(docker ps -a --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$containers" ]]; then
        print_warning "No Kali containers found"
        return 0
    fi
    
    echo "Available containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        local status=$(docker ps -a --filter "name=${container}" --format "{{.Status}}")
        echo "$i) $container [$status]"
        ((i++))
    done <<< "$containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    
    print_info "Starting container: $selected_container"
    
    if docker start "$selected_container"; then
        print_success "Container '$selected_container' started"
    else
        print_error "Failed to start container"
    fi
}

stop_kali_container() {
    print_info "Stopping Kali container..."
    
    local running_containers=$(docker ps --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$running_containers" ]]; then
        print_warning "No running Kali containers found"
        return 0
    fi
    
    echo "Running containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        echo "$i) $container"
        ((i++))
    done <<< "$running_containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    
    print_info "Stopping container: $selected_container"
    
    if docker stop "$selected_container"; then
        print_success "Container '$selected_container' stopped"
    else
        print_error "Failed to stop container"
    fi
}

enter_container_shell() {
    print_info "Entering container shell..."
    
    local running_containers=$(docker ps --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$running_containers" ]]; then
        print_warning "No running Kali containers found. Start a container first."
        return 0
    fi
    
    echo "Running containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        echo "$i) $container"
        ((i++))
    done <<< "$running_containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    
    print_info "Entering shell for container: $selected_container"
    print_info "Type 'exit' to return to Hakpak"
    
    docker exec -it "$selected_container" /bin/bash
}

install_tools_in_container() {
    print_info "Installing tools in container..."
    
    local running_containers=$(docker ps --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$running_containers" ]]; then
        print_warning "No running Kali containers found. Start a container first."
        return 0
    fi
    
    echo "Running containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        echo "$i) $container"
        ((i++))
    done <<< "$running_containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    
    echo "Select tool collection to install:"
    echo "1) Kali Essential Tools"
    echo "2) Kali Default Tools"
    echo "3) Individual Package"
    
    read -rp "Select option [1-3]: " tool_choice
    
    local package_to_install=""
    
    case $tool_choice in
        1) package_to_install="kali-linux-default" ;;
        2) package_to_install="kali-linux-default" ;;
        3) 
            read -rp "Enter package name: " package_to_install
            [[ -z "$package_to_install" ]] && { print_error "Package name required"; return 1; }
            ;;
        *) print_error "Invalid option"; return 1 ;;
    esac
    
    print_info "Installing $package_to_install in container: $selected_container"
    
    # Update package lists in container
    docker exec "$selected_container" apt update
    
    # Install the package
    if docker exec "$selected_container" apt install -y "$package_to_install"; then
        print_success "Package '$package_to_install' installed in container"
        log_message "INFO" "Installed $package_to_install in container: $selected_container"
    else
        print_error "Failed to install package in container"
    fi
}

export_kali_container() {
    print_info "Exporting Kali container..."
    
    local containers=$(docker ps -a --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$containers" ]]; then
        print_warning "No Kali containers found"
        return 0
    fi
    
    echo "Available containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        echo "$i) $container"
        ((i++))
    done <<< "$containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    local export_file="$PWD/${selected_container}_$(date +%Y%m%d_%H%M%S).tar"
    
    print_info "Exporting container to: $export_file"
    
    if docker export "$selected_container" > "$export_file"; then
        print_success "Container exported successfully"
        print_info "Export file: $export_file"
        log_message "INFO" "Exported container: $selected_container to $export_file"
    else
        print_error "Failed to export container"
    fi
}

import_kali_container() {
    print_info "Importing Kali container..."
    
    read -rp "Enter path to container tar file: " import_file
    
    if [[ ! -f "$import_file" ]]; then
        print_error "File not found: $import_file"
        return 1
    fi
    
    read -rp "Enter name for imported container: " container_name
    [[ -z "$container_name" ]] && { print_error "Container name cannot be empty"; return 1; }
    
    # Sanitize container name
    container_name=$(echo "$container_name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    
    print_info "Importing container: $container_name"
    
    if docker import "$import_file" "hakpak/${container_name}:imported"; then
        # Create and start the container
        docker run -d \
            --name "$container_name" \
            --hostname "hakpak-${container_name}" \
            -v "/var/lib/hakpak/containers/${container_name}:/hakpak" \
            --cap-add=NET_ADMIN \
            --cap-add=NET_RAW \
            --security-opt apparmor:unconfined \
            "hakpak/${container_name}:imported" \
            tail -f /dev/null
        
        mkdir -p "/var/lib/hakpak/containers/${container_name}"
        
        print_success "Container imported and started: $container_name"
        log_message "INFO" "Imported container: $container_name from $import_file"
    else
        print_error "Failed to import container"
    fi
}

remove_kali_container() {
    print_info "Removing Kali container..."
    
    local containers=$(docker ps -a --filter "ancestor=kalilinux/kali-rolling" --filter "ancestor=kalilinux/kali-linux-docker" --filter "ancestor=kalilinux/kali-last-release" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$containers" ]]; then
        print_warning "No Kali containers found"
        return 0
    fi
    
    echo "Available containers:"
    local -a container_array=()
    local i=1
    
    while IFS= read -r container; do
        container_array+=("$container")
        local status=$(docker ps -a --filter "name=${container}" --format "{{.Status}}")
        echo "$i) $container [$status]"
        ((i++))
    done <<< "$containers"
    
    read -rp "Select container number: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#container_array[@]}" ]]; then
        print_error "Invalid selection"
        return 1
    fi
    
    local selected_container="${container_array[$((selection-1))]}"
    
    print_warning "This will permanently delete container: $selected_container"
    read -rp "Are you sure? [y/N]: " confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        # Stop container if running
        docker stop "$selected_container" 2>/dev/null || true
        
        # Remove container
        if docker rm "$selected_container"; then
            # Remove container directory
            rm -rf "/var/lib/hakpak/containers/${selected_container}"
            print_success "Container '$selected_container' removed"
            log_message "INFO" "Removed container: $selected_container"
        else
            print_error "Failed to remove container"
        fi
    else
        print_info "Operation cancelled"
    fi
}

# Helper functions (modularized from original)
backup_sources_list() {
    local backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ -f /etc/apt/sources.list ]]; then
        cp /etc/apt/sources.list "$backup_file"
        print_success "Sources.list backed up to $backup_file"
    fi
}

install_package_safe() {
    local package="$1"
    local description="${2:-$package}"
    
    print_info "Installing $description..."
    
    # Check if package exists in any repository
    if ! apt-cache show "$package" &> /dev/null; then
        print_error "Package '$package' not found in repositories"
        return 1
    fi
    
    # Check if already installed
    if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        print_success "$description is already installed"
        return 0
    fi
    
    print_info "Checking package availability..."
    apt-cache policy "$package"
    
    # First, try installing from Ubuntu repository (safer for dependencies)
    if apt-cache policy "$package" | grep -q "ubuntu"; then
        print_info "Installing Ubuntu version (safer for dependencies)..."
        local ubuntu_version=$(apt-cache policy "$package" | grep "ubuntu" | head -1 | awk '{print $1}')
        if [[ -n "$ubuntu_version" ]]; then
            if DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends "$package=$ubuntu_version"; then
                print_success "$description installed successfully from Ubuntu repository"
                log_message "INFO" "Successfully installed from Ubuntu: $package"
                return 0
            fi
        fi
    fi
    
    # If Ubuntu version failed or doesn't exist, try Kali with dependency resolution
    if apt-cache policy "$package" | grep -q "kali"; then
        print_info "Attempting Kali version with full dependency resolution..."
        
        # Try installing the entire dependency chain from Kali
        if DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends -t kali-rolling "$package"; then
            print_success "$description installed successfully from Kali repository"
            log_message "INFO" "Successfully installed from Kali: $package"
            return 0
        fi
        
        # If that fails, try allowing mixed versions
        print_info "Attempting mixed-repository installation with version flexibility..."
        if DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends --allow-downgrades --allow-change-held-packages "$package"; then
            print_success "$description installed successfully (mixed repositories)"
            log_message "INFO" "Successfully installed with mixed repos: $package"
            return 0
        fi
    fi
    
    # Last resort: try installing just from Ubuntu repos to avoid conflicts
    print_info "Falling back to Ubuntu repository version..."
    if DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends --no-install-suggests -o APT::Default-Release=noble "$package"; then
        print_success "$description installed successfully from Ubuntu (fallback)"
        log_message "INFO" "Successfully installed Ubuntu fallback: $package"
        return 0
    fi
    
    print_error "Failed to install $description"
    print_info "Checking package availability..."
    apt-cache policy "$package"
    log_message "ERROR" "Failed to install: $package"
    return 1
}

install_large_package() {
    local package="$1"
    local description="${2:-$package}"
    
    print_warning "Large package installation: $description"
    print_info "This may take significant time and disk space"
    
    # Check available space again
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 8388608 ]]; then  # 8GB in KB
        print_warning "Less than 8GB available. Large installations may fail."
        read -rp "Continue anyway? [y/N]: " space_confirm
        [[ $space_confirm =~ ^[Yy]$ ]] || return 1
    fi
    
    install_package_safe "$package" "$description"
}

show_system_status() {
    echo -e "\n${BOLD}HAKPAK SYSTEM STATUS${NC}"
    echo "────────────────────────────────────────"
    
    # Show distribution info
    echo -e "${BLUE}[i]${NC} Distribution: $DISTRO_NAME $DISTRO_VERSION"
    echo -e "${BLUE}[i]${NC} Architecture: $DISTRO_ARCH"
    
    # Check repository status
    if [[ -f /etc/apt/sources.list.d/kali.list ]]; then
        print_success "Kali repository: Configured"
    else
        print_warning "Kali repository: Not configured"
    fi
    
    # Show installed Kali packages
    local kali_packages
    kali_packages=$(dpkg -l | grep -c "^ii.*kali" || echo "0")
    echo -e "${BLUE}[i]${NC} Installed Kali packages: $kali_packages"
    
    # Show disk usage
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "${BLUE}[i]${NC} Disk usage: $disk_usage"
    
    # Show available space
    local available_space_gb
    available_space_gb=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${BLUE}[i]${NC} Available space: $available_space_gb"
    
    # Show last update
    local last_update
    last_update=$(stat -c %y /var/cache/apt/pkgcache.bin 2>/dev/null | cut -d' ' -f1 || echo "Unknown")
    echo -e "${BLUE}[i]${NC} Last apt update: $last_update"
}

list_metapackages() {
    print_info "Available Kali Metapackages"
    
    # Setup repository if needed
    setup_kali_repository || return 1
    
    echo -e "\n${BOLD}KALI LINUX METAPACKAGES${NC}"
    echo "═════════════════════════════════════════════════════════"
    
    # Core metapackages
    echo -e "${GREEN}${BOLD}Core Metapackages:${NC}"
    echo "  • kali-linux-core          - Essential Kali base system"
    echo "  • kali-linux-headless      - Headless/server installation"
    echo "  • kali-linux-default       - Standard desktop installation"
    echo "  • kali-linux-light         - Lightweight installation"
    echo "  • kali-linux-arm           - ARM-specific tools"
    echo ""
    
    # Size-based metapackages
    echo -e "${BLUE}${BOLD}Size-Based Collections:${NC}"
    echo "  • kali-linux-default       - Essential security tools (~2GB)"
    echo "  • kali-linux-large         - Large collection (~8GB)"
    echo "  • kali-linux-everything    - Complete collection (~15GB)"
    echo ""
    
    # Category-based metapackages
    echo -e "${YELLOW}${BOLD}Category-Based Tools:${NC}"
    echo "  • kali-tools-information-gathering   - OSINT and reconnaissance"
    echo "  • kali-tools-vulnerability-assessment - Security scanners"
    echo "  • kali-tools-web-application          - Web security tools"
    echo "  • kali-tools-database                 - Database assessment"
    echo "  • kali-tools-passwords                - Password attacks"
    echo "  • kali-tools-wireless                 - Wireless security"
    echo "  • kali-tools-reverse-engineering      - Binary analysis"
    echo "  • kali-tools-exploitation             - Penetration testing"
    echo "  • kali-tools-forensics                - Digital forensics"
    echo "  • kali-tools-hardware                 - Hardware hacking"
    echo "  • kali-tools-crypto-stego             - Cryptography tools"
    echo "  • kali-tools-fuzzing                  - Fuzzing tools"
    echo "  • kali-tools-gpu                      - GPU-accelerated tools"
    echo "  • kali-tools-social-engineering       - Social engineering"
    echo "  • kali-tools-sniffing-spoofing        - Network analysis"
    echo "  • kali-tools-post-exploitation        - Post-exploitation"
    echo "  • kali-tools-maintain-access          - Persistence tools"
    echo "  • kali-tools-reporting                - Reporting tools"
    echo ""
    
    # Desktop environments
    echo -e "${RED}${BOLD}Desktop Environments:${NC}"
    echo "  • kali-desktop-core        - Core desktop components"
    echo "  • kali-desktop-e17         - Enlightenment desktop"
    echo "  • kali-desktop-gnome       - GNOME desktop environment"
    echo "  • kali-desktop-i3          - i3 window manager"
    echo "  • kali-desktop-kde         - KDE desktop environment"
    echo "  • kali-desktop-lxde        - LXDE desktop environment"
    echo "  • kali-desktop-mate        - MATE desktop environment"
    echo "  • kali-desktop-xfce        - Xfce desktop environment"
    echo ""
    
    echo -e "${BOLD}Usage Examples:${NC}"
    echo "  sudo hakpak --install kali-linux-default"
    echo "  sudo hakpak --install kali-tools-web-application"
    echo "  sudo hakpak --install nmap"
    echo ""
    
    # Show available packages from repository if configured
    if [[ -f /etc/apt/sources.list.d/kali.list ]]; then
        print_info "Updating package information..."
        apt update &>/dev/null
        
        local available_kali_packages
        available_kali_packages=$(apt-cache search "kali-" | grep "^kali-" | wc -l)
        echo -e "${BLUE}[i]${NC} Total available Kali packages: $available_kali_packages"
    fi
    
    # Show enterprise license status
    echo
    echo -e "${BOLD}${PURPLE}Enterprise License Status:${NC}"
    echo "════════════════════════════════════════"
    if check_enterprise_license; then
        print_success "Valid enterprise license found"
        get_license_info | sed 's/^/  /'
    else
        print_info "Community edition (no enterprise license)"
        echo "  • Contact owner@phanesguild.llc for Pro features"
        echo "  • Advanced reporting, centralized management, and more"
    fi
}

# Enhanced main menu
main_menu() {
    # Check license before allowing access to main menu
    if ! require_license; then
        echo
        print_error "HakPak requires a valid license to proceed"
        echo
        print_info "To activate your license:"
        echo "  sudo hakpak --activate YOUR_LICENSE_KEY"
        echo
        print_info "Purchase HakPak at: https://phanesguild.llc/hakpak"
        exit 1
    fi
    
    while true; do
        echo -e "\n${BOLD}${GREEN}HAKPAK MAIN FORGE${NC}"
        echo "═══════════════════════════════════════"
        echo "1) Install Essential Security Tools"
        echo "2) Install Comprehensive Toolset"
        echo "3) Install Individual Tool"
        echo "4) List Available Tools"
        echo "5) Show System Status"
        echo "6) Setup Kali Repository"
        echo "7) Remove Kali Repository"
        echo "8) Fix Dependencies"
        echo "9) Custom Toolkits Manager"
        echo "10) Offline Installer Mode"
        echo "11) Container Isolation Mode"
        echo "12) View Installation Log"
        
        # Pro features section
        if is_pro_valid; then
            echo "──────── HakPak Pro Features ────────"
            echo "14) Install Pro Security Suite"
            echo "15) Launch Pro Analytics Dashboard"
            echo "16) Enterprise License Status"
            echo "17) Exit"
        else
            echo "14) Enterprise License Status"
            echo "15) Exit"
        fi
        echo "═══════════════════════════════════════"
        if is_pro_valid; then
            read -rp "Select an option [1-17]: " choice
        else
            read -rp "Select an option [1-15]: " choice
        fi

        case $choice in
            1) install_kali_top10 ;;
            2) install_kali_full ;;
            3) 
                read -rp "Enter tool name: " toolname
                [[ -n $toolname ]] && install_individual_tool "$toolname"
                ;;
                       4) list_available_tools ;;
            5) show_system_status ;;
            6) setup_kali_repository ;;
            7) remove_kali_repository ;;
            8) fix_dependencies ;;
            9) custom_toolkits_manager ;;
            
            10) offline_installer_mode ;;
            11) container_isolation_mode ;;
            12)
                if [[ -f "$LOG_FILE" ]]; then
                    echo -e "\n${BOLD}Recent log entries:${NC}"
                    tail -20 "$LOG_FILE"
                else
                    print_info "No log file found"
                fi
                ;;
            13)
                print_success "Exiting Hakpak — Forge wisely."
                exit 0
                ;;
            14)
                if is_pro_valid; then
                    # Pro feature: Install Pro Security Suite
                    require_pro || continue
                    install_pro_tools
                else
                    # Show enterprise license status
                    show_enterprise_status
                fi
                ;;
            15)
                if is_pro_valid; then
                    # Pro feature: Launch Analytics Dashboard
                    require_pro || continue
                    launch_pro_dashboard
                else
                    # Exit option for non-Pro users
                    print_success "Exiting Hakpak — Forge wisely."
                    exit 0
                fi
                ;;
            16)
                if is_pro_valid; then
                    # Pro user: Show enterprise license status
                    show_enterprise_status
                else
                    print_error "Invalid option."
                fi
                ;;
            17)
                if is_pro_valid; then
                    # Pro user: Exit
                    print_success "Exiting Hakpak Pro — Forge wisely."
                    exit 0
                else
                    print_error "Invalid option."
                fi
                ;;
            *)
                if is_pro_valid; then
                    print_error "Invalid option. Please select 1-17."
                else
                    print_error "Invalid option. Please select 1-15."
                fi
                ;;
        esac
        
        # Pause before showing menu again
        echo ""
        read -rp "Press Enter to continue..."
    done
}

fix_dependencies() {
    print_info "Diagnosing and fixing dependency issues..."
    
    # Check for actually broken packages
    # dpkg status: first char = desired state, second = status, third = error flag
    # We want packages that are NOT "ii " (install, installed, no error)
    local broken_packages
    broken_packages=$(dpkg -l 2>/dev/null | awk '/^[^+|]/ && !/^ii / {count++} END {print count+0}')
    
    # Check for packages in error states specifically
    local error_packages  
    error_packages=$(dpkg -l 2>/dev/null | grep -E "^i[^i]|^.[^i]" | wc -l)
    
    # Only consider it a problem if we have actual errors, not just uninstalled packages
    if [[ $broken_packages -gt 50 ]] || [[ $error_packages -gt 10 ]]; then
        print_warning "Found $error_packages packages that may need attention"
        print_info "Attempting to fix package database..."
        
        # Fix broken packages
        apt --fix-broken install -y
        dpkg --configure -a
        apt clean
        apt autoclean
        
        print_success "Package database maintenance completed"
    else
        print_success "Package database is healthy"
    fi
    
    # Advanced dependency resolution for version conflicts
    print_info "Resolving version conflicts..."
    
    # Handle Ruby version conflicts
    if dpkg -l | grep -q "ruby.*3.2"; then
        print_info "Attempting to resolve Ruby version conflicts..."
        apt install -y --allow-downgrades ruby=1:3.2* ruby-dev=1:3.2* || true
        apt-mark hold ruby ruby-dev
    fi
    
    # Handle Python version conflicts
    if command -v python3.13 >/dev/null 2>&1; then
        print_info "Python 3.13 detected, creating compatibility links..."
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 || true
        update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 2 || true
    fi
    
    # Fix library version mismatches
    print_info "Updating library dependencies..."
    apt install -y --fix-missing libssl3 libgcrypt20 || true
    
    # Handle specific Kali package conflicts
    print_info "Resolving Kali package conflicts..."
    apt install -y --no-install-recommends \
        python3-impacket=0.11.0-2 \
        python3-cryptography \
        python3-pydantic \
        python3-sqlalchemy \
        python3-paramiko \
        samba-common-bin || true
    
    # Mark problematic packages as held to prevent version conflicts
    apt-mark hold python3-impacket python3-pytz || true
    
    # Update package lists
    print_info "Updating package lists..."
    apt update
    
    print_success "Advanced dependency resolution completed"
}

# List available tools function
list_available_tools() {
    print_info "Available Security Tools"
    
    while true; do
        echo -e "\n${BOLD}${BLUE}AVAILABLE SECURITY TOOLS${NC}"
        echo "═══════════════════════════════════════"
        echo "1) Network Analysis & Scanning"
        echo "2) Web Application Security"
        echo "3) Password & Authentication"
        echo "4) Vulnerability Assessment"
        echo "5) Forensics & Analysis"
        echo "6) Wireless Security"
        echo "7) Exploitation & Penetration"
        echo "8) Information Gathering"
        echo "9) Popular Individual Tools"
        echo "10) All Available Packages (Search)"
        echo "11) Back to Main Menu"
        echo "═══════════════════════════════════════"
        read -rp "Select category [1-11]: " category_choice

        case $category_choice in
            1) show_network_tools ;;
            2) show_web_tools ;;
            3) show_password_tools ;;
            4) show_vulnerability_tools ;;
            5) show_forensics_tools ;;
            6) show_wireless_tools ;;
            7) show_exploitation_tools ;;
            8) show_information_tools ;;
            9) show_popular_tools ;;
            10) search_all_packages ;;
            11) return 0 ;;
            *) print_error "Invalid option. Please select 1-11." ;;
        esac
        
        echo ""
        read -rp "Press Enter to continue..."
    done
}

# Tool category functions
show_network_tools() {
    echo -e "\n${GREEN}${BOLD}NETWORK ANALYSIS & SCANNING TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• nmap${NC}              - Network scanner and service detection"
    echo -e "${BLUE}• masscan${NC}           - High-speed port scanner"
    echo -e "${BLUE}• zmap${NC}              - Internet-wide network scanner"
    echo -e "${BLUE}• wireshark${NC}         - Network protocol analyzer (GUI)"
    echo -e "${BLUE}• tshark${NC}            - Network protocol analyzer (CLI)"
    echo -e "${BLUE}• tcpdump${NC}           - Packet analyzer and capture"
    echo -e "${BLUE}• netcat-traditional${NC} - Network utility for connections"
    echo -e "${BLUE}• netdiscover${NC}       - Network address discovery"
    echo -e "${BLUE}• arp-scan${NC}          - ARP-based network scanner"
    echo -e "${BLUE}• unicornscan${NC}       - Flexible network scanner"
    echo -e "${BLUE}• hping3${NC}            - Network packet crafting tool"
    echo -e "${BLUE}• ettercap-text-only${NC} - Network sniffing and MITM"
    echo -e "${BLUE}• dnsutils${NC}          - DNS lookup utilities"
    echo -e "${BLUE}• whois${NC}             - Domain and IP information lookup"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install nmap"
}

show_web_tools() {
    echo -e "\n${GREEN}${BOLD}WEB APPLICATION SECURITY TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• burpsuite${NC}         - Professional web security scanner"
    echo -e "${BLUE}• zaproxy${NC}           - OWASP ZAP web application scanner"
    echo -e "${BLUE}• sqlmap${NC}            - SQL injection detection and exploitation"
    echo -e "${BLUE}• nikto${NC}             - Web server vulnerability scanner"
    echo -e "${BLUE}• dirb${NC}              - Web directory brute forcer"
    echo -e "${BLUE}• gobuster${NC}          - Fast directory/file brute forcer"
    echo -e "${BLUE}• wfuzz${NC}             - Web application fuzzer"
    echo -e "${BLUE}• ffuf${NC}              - Fast web fuzzer written in Go"
    echo -e "${BLUE}• whatweb${NC}           - Web technology identifier"
    echo -e "${BLUE}• wpscan${NC}            - WordPress vulnerability scanner"
    echo -e "${BLUE}• joomscan${NC}          - Joomla vulnerability scanner"
    echo -e "${BLUE}• skipfish${NC}          - Web application security scanner"
    echo -e "${BLUE}• w3af${NC}              - Web application attack and audit framework"
    echo -e "${BLUE}• commix${NC}            - Command injection exploitation tool"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install sqlmap"
}

show_password_tools() {
    echo -e "\n${GREEN}${BOLD}PASSWORD & AUTHENTICATION TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• john${NC}              - John the Ripper password cracker"
    echo -e "${BLUE}• hashcat${NC}           - Advanced password recovery utility"
    echo -e "${BLUE}• hydra${NC}             - Network login brute forcer"
    echo -e "${BLUE}• medusa${NC}            - Parallel network login brute forcer"
    echo -e "${BLUE}• ncrack${NC}            - Network authentication cracker"
    echo -e "${BLUE}• hashid${NC}            - Hash identifier tool"
    echo -e "${BLUE}• hash-identifier${NC}   - Identify hash types"
    echo -e "${BLUE}• wordlists${NC}         - Collection of password wordlists"
    echo -e "${BLUE}• crunch${NC}            - Wordlist generator"
    echo -e "${BLUE}• cewl${NC}              - Website wordlist generator"
    echo -e "${BLUE}• patator${NC}           - Multi-purpose brute forcer"
    echo -e "${BLUE}• crowbar${NC}           - Brute forcing tool for protocols"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install hydra"
}

show_vulnerability_tools() {
    echo -e "\n${GREEN}${BOLD}VULNERABILITY ASSESSMENT TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• openvas${NC}           - Comprehensive vulnerability scanner"
    echo -e "${BLUE}• nexpose${NC}           - Rapid7 vulnerability scanner"
    echo -e "${BLUE}• lynis${NC}             - Security auditing tool for Unix systems"
    echo -e "${BLUE}• chkrootkit${NC}        - Rootkit detection tool"
    echo -e "${BLUE}• rkhunter${NC}          - Rootkit hunter security scanner"
    echo -e "${BLUE}• tiger${NC}             - Security audit and intrusion detection"
    echo -e "${BLUE}• unix-privesc-check${NC} - Unix privilege escalation checker"
    echo -e "${BLUE}• linux-exploit-suggester${NC} - Linux exploit suggester"
    echo -e "${BLUE}• searchsploit${NC}      - Exploit database search tool"
    echo -e "${BLUE}• exploitdb${NC}         - Exploit database"
    echo -e "${BLUE}• metasploit-framework${NC} - Penetration testing framework"
    echo -e "${BLUE}• vuls${NC}              - Vulnerability scanner written in Go"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install lynis"
}

show_forensics_tools() {
    echo -e "\n${GREEN}${BOLD}FORENSICS & ANALYSIS TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• autopsy${NC}           - Digital forensics platform"
    echo -e "${BLUE}• sleuthkit${NC}         - Digital investigation tools"
    echo -e "${BLUE}• volatility${NC}        - Memory analysis framework"
    echo -e "${BLUE}• foremost${NC}          - File carving and recovery tool"
    echo -e "${BLUE}• scalpel${NC}           - Fast file carver"
    echo -e "${BLUE}• binwalk${NC}           - Firmware analysis tool"
    echo -e "${BLUE}• strings${NC}           - Extract strings from files"
    echo -e "${BLUE}• exiftool${NC}          - Metadata analysis tool"
    echo -e "${BLUE}• steghide${NC}          - Steganography hiding tool"
    echo -e "${BLUE}• stegosuite${NC}        - Steganography suite"
    echo -e "${BLUE}• hashdeep${NC}          - File integrity checking"
    echo -e "${BLUE}• dc3dd${NC}             - Enhanced version of dd for forensics"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install foremost"
}

show_wireless_tools() {
    echo -e "\n${GREEN}${BOLD}WIRELESS SECURITY TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• aircrack-ng${NC}       - WiFi security assessment suite"
    echo -e "${BLUE}• airodump-ng${NC}       - WiFi packet capture"
    echo -e "${BLUE}• aireplay-ng${NC}       - WiFi packet injection"
    echo -e "${BLUE}• airmon-ng${NC}         - WiFi monitor mode activation"
    echo -e "${BLUE}• reaver${NC}            - WPS brute force attack tool"
    echo -e "${BLUE}• bully${NC}             - WPS brute force tool"
    echo -e "${BLUE}• kismet${NC}            - Wireless network detector"
    echo -e "${BLUE}• wifite${NC}            - Automated WiFi auditing tool"
    echo -e "${BLUE}• fern-wifi-cracker${NC} - WiFi security testing tool"
    echo -e "${BLUE}• pixiewps${NC}          - WPS pixie dust attack tool"
    echo -e "${BLUE}• macchanger${NC}        - MAC address manipulation utility"
    echo -e "${BLUE}• hostapd${NC}           - Access point management"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install aircrack-ng"
}

show_exploitation_tools() {
    echo -e "\n${GREEN}${BOLD}EXPLOITATION & PENETRATION TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• metasploit-framework${NC} - Comprehensive penetration testing"
    echo -e "${BLUE}• armitage${NC}          - Graphical interface for Metasploit"
    echo -e "${BLUE}• beef-xss${NC}          - Browser exploitation framework"
    echo -e "${BLUE}• social-engineer-toolkit${NC} - Social engineering attacks"
    echo -e "${BLUE}• exploitdb${NC}         - Exploit database and tools"
    echo -e "${BLUE}• shellnoob${NC}         - Shellcode writing toolkit"
    echo -e "${BLUE}• commix${NC}            - Command injection exploitation"
    echo -e "${BLUE}• weevely${NC}           - Web shell and backdoor"
    echo -e "${BLUE}• empire${NC}            - PowerShell post-exploitation agent"
    echo -e "${BLUE}• powersploit${NC}       - PowerShell exploitation framework"
    echo -e "${BLUE}• veil${NC}              - Payload generation framework"
    echo -e "${BLUE}• theharvester${NC}      - Information gathering tool"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install metasploit-framework"
}

show_information_tools() {
    echo -e "\n${GREEN}${BOLD}INFORMATION GATHERING TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• recon-ng${NC}          - Web reconnaissance framework"
    echo -e "${BLUE}• theharvester${NC}      - Email and domain information gathering"
    echo -e "${BLUE}• maltego${NC}           - Link analysis and data mining"
    echo -e "${BLUE}• spiderfoot${NC}        - Automated OSINT reconnaissance"
    echo -e "${BLUE}• fierce${NC}            - Domain scanner and IP locator"
    echo -e "${BLUE}• dmitry${NC}            - Deepmagic information gathering"
    echo -e "${BLUE}• metagoofil${NC}        - Metadata extraction tool"
    echo -e "${BLUE}• enum4linux${NC}        - Linux/Unix enumeration tool"
    echo -e "${BLUE}• smbclient${NC}         - SMB/CIFS client"
    echo -e "${BLUE}• nbtscan${NC}           - NetBIOS name scanner"
    echo -e "${BLUE}• dnsrecon${NC}          - DNS enumeration and reconnaissance"
    echo -e "${BLUE}• dnsenum${NC}           - DNS enumeration tool"
    echo ""
    echo -e "${YELLOW}Install example:${NC} sudo hakpak --install recon-ng"
}

show_popular_tools() {
    echo -e "\n${GREEN}${BOLD}POPULAR INDIVIDUAL TOOLS${NC}"
    echo "─────────────────────────────────────────────────────────"
    echo -e "${BLUE}• nmap${NC}              - Most popular network scanner"
    echo -e "${BLUE}• sqlmap${NC}            - Top SQL injection testing tool"
    echo -e "${BLUE}• burpsuite${NC}         - Industry standard web security"
    echo -e "${BLUE}• metasploit-framework${NC} - Leading penetration testing framework"
    echo -e "${BLUE}• wireshark${NC}         - Premier network protocol analyzer"
    echo -e "${BLUE}• john${NC}              - Famous password cracker"
    echo -e "${BLUE}• hashcat${NC}           - Advanced password recovery"
    echo -e "${BLUE}• hydra${NC}             - Network login brute forcer"
    echo -e "${BLUE}• nikto${NC}             - Web vulnerability scanner"
    echo -e "${BLUE}• dirb${NC}              - Directory brute forcer"
    echo -e "${BLUE}• gobuster${NC}          - Fast directory enumeration"
    echo -e "${BLUE}• aircrack-ng${NC}       - WiFi security testing suite"
    echo -e "${BLUE}• recon-ng${NC}          - Information gathering framework"
    echo -e "${BLUE}• exploitdb${NC}         - Exploit database"
    echo -e "${BLUE}• searchsploit${NC}      - Exploit search tool"
    echo ""
    echo -e "${YELLOW}Install any tool:${NC} sudo hakpak --install <toolname>"
}

search_all_packages() {
    echo -e "\n${GREEN}${BOLD}SEARCH ALL AVAILABLE PACKAGES${NC}"
    echo "─────────────────────────────────────────────────────────"
    
    # Check if repository is set up
    if [[ ! -f /etc/apt/sources.list.d/kali.list ]]; then
        print_warning "Kali repository not configured. Setting up..."
        setup_kali_repository || return 1
    fi
    
    read -rp "Enter search term (or press Enter for all Kali tools): " search_term
    
    if [[ -z "$search_term" ]]; then
        print_info "Showing all available Kali tools (this may take a moment)..."
        echo -e "\n${BLUE}Available Kali Linux packages:${NC}"
        apt-cache search kali- | grep "^kali-" | head -50
        echo ""
        print_info "Showing first 50 packages. Use specific search terms for targeted results."
    else
        print_info "Searching for packages containing: $search_term"
        echo -e "\n${BLUE}Search results:${NC}"
        apt-cache search "$search_term" | head -20
        echo ""
        if [[ $(apt-cache search "$search_term" | wc -l) -gt 20 ]]; then
            print_info "Showing first 20 results. Refine search for better results."
        fi
    fi
}

# Cleanup function for script interruption
cleanup() {
    print_info "Cleaning up..."
    exit 1
}

# Trap signals for cleanup
trap cleanup SIGINT SIGTERM

# Terms of use acceptance
show_terms_and_accept() {
    clear
    echo -e "${BOLD}${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${RED}║                           ⚠️  LEGAL DISCLAIMER  ⚠️                          ║${NC}"
    echo -e "${BOLD}${RED}║                         READ CAREFULLY BEFORE PROCEEDING                    ║${NC}"
    echo -e "${BOLD}${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BOLD}${YELLOW}HakPak installs penetration testing and security assessment tools.${NC}"
    echo -e "${BOLD}${YELLOW}By using this software, you acknowledge and agree that:${NC}"
    echo
    echo -e "${GREEN}✅ You have explicit authorization to test the systems you intend to scan${NC}"
    echo -e "${GREEN}✅ You will only use these tools on systems you own or have written permission to test${NC}"
    echo -e "${GREEN}✅ You understand that unauthorized scanning/testing may violate laws${NC}"
    echo -e "${GREEN}✅ You accept full responsibility for your actions and consequences${NC}"
    echo
    echo -e "${BOLD}${RED}⚠️  IMPORTANT WARNINGS:${NC}"
    echo -e "${RED}• Unauthorized network scanning is ILLEGAL in many jurisdictions${NC}"
    echo -e "${RED}• Always obtain proper written authorization before testing${NC}"
    echo -e "${RED}• These tools can cause system instability if misused${NC}"
    echo -e "${RED}• PhanesGuild Software LLC disclaims ALL liability for misuse${NC}"
    echo
    echo -e "${BOLD}${BLUE}INTENDED USE:${NC}"
    echo -e "${BLUE}• Authorized penetration testing and security assessments${NC}"
    echo -e "${BLUE}• Educational purposes in controlled environments${NC}"
    echo -e "${BLUE}• Security research with proper authorization${NC}"
    echo -e "${BLUE}• Defensive security improvements on owned systems${NC}"
    echo
    echo -e "${BOLD}${CYAN}By proceeding, you certify that you will use these tools ethically and legally.${NC}"
    echo
    echo -ne "${BOLD}${YELLOW}Do you accept these terms and agree to use these tools responsibly? [y/N]: ${NC}"
    
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            print_success "Terms accepted. Proceeding with HakPak installation..."
            log_message "INFO" "User accepted terms of use - proceeding with installation"
            return 0
            ;;
        *)
            print_info "Terms not accepted. Exiting HakPak."
            print_info "For questions about terms of use, contact: owner@phanesguild.llc"
            log_message "INFO" "User declined terms of use - exiting"
            exit 0
            ;;
    esac
}

# Check and display license mode - elegant conditional pattern
check_license_mode() {
    if is_pro_valid; then
        print_info "Pro license validated. Enabling Pro features..."
        return 0
    else
        print_info "Running in Community mode."
        return 1
    fi
}

# Initialize HakPak with license mode detection
initialize_hakpak() {
    print_info "Initializing HakPak Security Toolkit..."
    
    # Elegant Pro/Community mode detection - silent check
    if is_pro_valid; then
        print_info "Pro license validated. Enabling Pro features..."
        print_success "HakPak Pro mode activated"
        echo "🚀 Pro features available:"
        echo "   • Additional Kali metapackage installation"
        echo "   • Extended security tool collections" 
        echo "   • Priority email support"
        echo "   • Commercial usage license"
        echo "   • Multi-machine deployment rights"
        echo "   • Advanced system overview dashboard"
    else
        print_info "Running in Community mode."
        print_info "Core security tools and basic features available"
        echo "💡 Upgrade to HakPak Pro for enhanced capabilities:"
        echo "   • Visit: https://phanesguild.llc/hakpak"
        echo "   • Contact: owner@phanesguild.llc | Discord: PhanesGuildSoftware"
    fi
    echo
}

# Pro Tools Suite Installation - example Pro feature
install_pro_tools() {
    print_info "Installing HakPak Pro Security Suite..."
    echo "========================================"
    echo
    
    # Real Pro tool installation - install additional Kali metapackages
    local pro_metapackages=(
        "kali-tools-web"
        "kali-tools-wireless" 
        "kali-tools-forensics"
        "kali-tools-crypto-stego"
        "kali-tools-vulnerability"
        "kali-tools-exploitation"
        "kali-tools-post-exploitation"
        "kali-tools-reverse-engineering"
    )
    
    echo "Installing Pro metapackages:"
    for package in "${pro_metapackages[@]}"; do
        echo "  • $package"
    done
    echo
    
    print_info "Installing additional security tool collections..."
    echo
    
    # Install the metapackages
    for package in "${pro_metapackages[@]}"; do
        print_info "Installing: $package"
        
        if DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends "$package"; then
            print_success "✓ $package installed successfully"
        else
            print_warning "⚠ $package installation failed or partially completed"
        fi
    done
    
    echo
    print_success "HakPak Pro Security Suite installation complete!"
    print_info "Additional security tools are now available."
    echo
    print_info "To see all available tools, run:"
    echo "  • hakpak --list-tools"
    echo "  • hakpak --pro-report        (Enterprise Reporting)"
    echo "  • hakpak --pro-compliance    (Compliance Auditing)"
}

# Pro Analytics Dashboard - example Pro feature
launch_pro_dashboard() {
    print_info "HakPak Pro System Overview"
    echo "=============================="
    echo
    
    # Real system analytics
    print_info "Gathering system security information..."
    echo
    
    echo "📊 Installed Security Tools:"
    local security_tools=0
    
    # Count actual installed security tools
    for tool in nmap sqlmap nikto dirb gobuster hydra john hashcat wireshark wfuzz ffuf aircrack-ng burpsuite; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "   ✓ $tool"
            ((security_tools++))
        fi
    done
    
    echo
    echo "📈 System Statistics:"
    echo "   • Total security tools installed: $security_tools"
    echo "   • Kali repositories: $(ls -1 /etc/apt/sources.list.d/ 2>/dev/null | grep -c kali || echo "0")"
    echo "   • System architecture: $(uname -m)"
    echo "   • Kernel version: $(uname -r)"
    echo "   • Available disk space: $(df -h / | awk 'NR==2 {print $4}')"
    echo
    
    echo "🛡️ Security Status:"
    echo "   • HakPak license status: $(is_pro_valid && echo "✓ Valid Pro License" || echo "✗ No Pro License")"
    echo "   • Repository status: $(apt list --upgradable 2>/dev/null | wc -l) packages can be upgraded"
    echo "   • Last update check: $(stat -c %y /var/lib/apt/periodic/update-success-stamp 2>/dev/null | cut -d' ' -f1 || echo "Unknown")"
    echo
    
    print_info "For detailed tool documentation, run: hakpak --help"
}

# --- BEGIN LICENSE CHECK BLOCK ---
# Requires: openssl, base64, jq (jq recommended)
PUBLIC_KEY_PATH="/usr/share/hakpak/public.pem"  # Production installation path
LICENSE_TARGET_SYSTEM="/etc/hakpak/license.lic"
USER_LICENSE_PATH="$HOME/.config/hakpak/license.lic"
WATERMARK_DIR="/var/lib/hakpak"
WATERMARK_USER_DIR="$HOME/.local/share/hakpak"

# Ensure directories exist (best-effort)
mkdir -p "$WATERMARK_USER_DIR"
if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$WATERMARK_DIR"
fi

license_error() { echo "HakPak: ERROR: $*" >&2; }
license_info()  { echo "HakPak: $*"; }

# Locate license file function
_find_license_file() {
  if [ -f "$LICENSE_TARGET_SYSTEM" ]; then
    echo "$LICENSE_TARGET_SYSTEM"
    return 0
  elif [ -f "$USER_LICENSE_PATH" ]; then
    echo "$USER_LICENSE_PATH"
    return 0
  else
    return 1
  fi
}

# Verify license file signed by private key; returns 0 if valid
verify_license_file() {
  local licfile
  licfile="$1"
  # Parse our custom bundle format
  local payload_b64 sig_b64 payload_file sig_file
  payload_file=$(mktemp)
  sig_file=$(mktemp)

  awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$payload_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 2; }
  awk '/-----SIGNATURE-----/,/-----END HAKPAK LICENSE-----/' "$licfile" | sed 's/-----SIGNATURE-----//;s/-----END HAKPAK LICENSE-----//' | tr -d '\n' | base64 -d > "$sig_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 3; }

  if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    license_error "Public key not found at ${PUBLIC_KEY_PATH}. Cannot verify license."
    rm -f "$payload_file" "$sig_file"
    return 4
  fi

  if openssl dgst -sha256 -verify "$PUBLIC_KEY_PATH" -signature "$sig_file" "$payload_file" >/dev/null 2>&1; then
    # signature valid — parse expiry and return valid code 0
    if command -v jq >/dev/null 2>&1; then
      local expires_at
      expires_at=$(jq -r '.expires_at' < "$payload_file")
      if [ -n "$expires_at" ] && [ "$expires_at" != "null" ]; then
        # compare times (UTC)
        local now ts_exp
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        ts_exp=$(date -d "$expires_at" +"%s" 2>/dev/null || echo 0)
        ts_now=$(date -d "$now" +"%s" 2>/dev/null || echo 0)
        if [ "$ts_now" -gt "$ts_exp" ]; then
          rm -f "$payload_file" "$sig_file"
          return 5  # expired
        fi
      fi
    fi
    # store payload to watermark file
    _store_license_watermark "$payload_file"
    rm -f "$payload_file" "$sig_file"
    return 0
  else
    rm -f "$payload_file" "$sig_file"
    return 6
  fi
}

_store_license_watermark() {
  local payload_file="$1"
  # extract buyer info for watermark
  if command -v jq >/dev/null 2>&1; then
    local buyer_email buyer_name license_id
    buyer_email=$(jq -r '.buyer_email' < "$payload_file")
    buyer_name=$(jq -r '.buyer_name' < "$payload_file")
    license_id=$(jq -r '.license_id' < "$payload_file")
    local target="${WATERMARK_USER_DIR}/watermark.txt"
    local systarget="${WATERMARK_DIR}/watermark.txt"
    echo "HakPak Pro License" > "$target"
    echo "buyer_name: $buyer_name" >> "$target"
    echo "buyer_email: $buyer_email" >> "$target"
    echo "license_id: $license_id" >> "$target"
    echo "installed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$target"
    # Also write system-wide watermark if running as root
    if [ "$(id -u)" -eq 0 ]; then
      echo "HakPak Pro License" > "$systarget"
      echo "buyer_name: $buyer_name" >> "$systarget"
      echo "buyer_email: $buyer_email" >> "$systarget"
      echo "license_id: $license_id" >> "$systarget"
      echo "installed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$systarget"
      chmod 600 "$systarget"
    fi
  else
    # If jq isn't present, still write a simple fingerprint
    local fingerprint
    fingerprint=$(sha256sum "$payload_file" | awk '{print $1}')
    echo "HakPak Pro License - fingerprint: $fingerprint" > "${WATERMARK_USER_DIR}/watermark.txt"
  fi
}

# Public helper: is_pro_valid
is_pro_valid() {
  local licfile
  if licfile=$(_find_license_file); then
    verify_license_file "$licfile"
    case $? in
      0) return 0 ;;    # valid
      5) license_error "License expired"; return 1 ;;
      2|3) license_error "Invalid license format"; return 1 ;;
      4) license_error "Missing public key"; return 1 ;;
      6) license_error "Signature verification failed"; return 1 ;;
      *) license_error "License verification error"; return 1 ;;
    esac
  else
    return 1
  fi
}

# Gate for Pro-only functions. Usage:
#   require_pro || exit 1
require_pro() {
  if is_pro_valid; then
    return 0
  else
    echo
    print_warning "HakPak Pro feature requires a valid Pro license."
    print_info "Place your license file at one of these locations:"
    print_info "  $LICENSE_TARGET_SYSTEM"
    print_info "  $USER_LICENSE_PATH"
    echo
    print_info "To obtain a license, visit: https://phanesguild.llc/hakpak"
    print_info "Contact: owner@phanesguild.llc | Discord: PhanesGuildSoftware"
    return 1
  fi
}

# Get license information for display
get_license_info() {
  local licfile
  if licfile=$(_find_license_file); then
    local payload_file
    payload_file=$(mktemp)
    
    # Extract payload
    awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$payload_file" 2>/dev/null || {
      rm -f "$payload_file"
      echo "Invalid license format"
      return 1
    }
    
    if command -v jq >/dev/null 2>&1; then
      jq -r '
      "License ID: " + .license_id,
      "Buyer: " + .buyer_name + " (" + .buyer_email + ")",
      "Product: " + .product + " v" + .version,
      "Issued: " + .issued_at,
      "Expires: " + .expires_at,
      "Notes: " + .notes
      ' "$payload_file"
    else
      echo "License information available (install jq for details)"
      cat "$payload_file"
    fi
    
    rm -f "$payload_file"
  else
    echo "No license file found"
    return 1
  fi
}

# Enterprise status display
show_enterprise_status() {
  print_info "HakPak Pro License Status:"
  echo "================================"
  
  if is_pro_valid; then
    print_success "Valid HakPak Pro license found"
    get_license_info | sed 's/^/  /'
    
    # Show watermark info if available
    if [ -f "${WATERMARK_DIR}/watermark.txt" ] || [ -f "${WATERMARK_USER_DIR}/watermark.txt" ]; then
      echo
      print_info "License Installation Details:"
      if [ -f "${WATERMARK_DIR}/watermark.txt" ]; then
        cat "${WATERMARK_DIR}/watermark.txt" | sed 's/^/  /'
      elif [ -f "${WATERMARK_USER_DIR}/watermark.txt" ]; then
        cat "${WATERMARK_USER_DIR}/watermark.txt" | sed 's/^/  /'
      fi
    fi
  else
    print_warning "No valid HakPak Pro license found"
    echo
    print_info "HakPak Pro features available with license:"
    echo "  • Additional Kali metapackage installation"
    echo "  • Extended security tool collections"
    echo "  • Priority email support"
    echo "  • Commercial usage license"
    echo "  • Multi-machine deployment rights"
    echo "  • Advanced system overview dashboard"
    echo
    print_info "License file locations:"
    echo "  • System-wide: $LICENSE_TARGET_SYSTEM"
    echo "  • User-specific: $USER_LICENSE_PATH"
    echo
    print_info "Contact owner@phanesguild.llc for licensing information"
    print_info "Visit: https://phanesguild.llc/hakpak"
  fi
}

# Source the license verification library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/license.sh"

# Main execution with argument parsing
main() {
    # Show professional header
    show_header
    
    # Parse command line arguments
    case "${1:-}" in
        --gui)
            # Launch GUI interface
            HAKPAK_DIR="$(dirname "$(readlink -f "$0")")"
            if [[ -f "${HAKPAK_DIR}/hakpak-gui.sh" ]]; then
                exec "${HAKPAK_DIR}/hakpak-gui.sh" --gui
            else
                print_error "GUI launcher not found. Run install-desktop.sh first."
                exit 1
            fi
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -v|--version)
            print_version
            exit 0
            ;;
        -s|--status)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            perform_safety_checks
            check_dependencies
            show_system_status
            exit 0
            ;;
        --setup-repo)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            perform_safety_checks
            check_dependencies
            setup_kali_repository
            exit 0
            ;;
        --remove-repo)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            remove_kali_repository
            exit 0
            ;;
        --fix-deps)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            perform_safety_checks
            fix_dependencies
            exit 0
            ;;
        --list-metapackages)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            perform_safety_checks
            list_metapackages
            exit 0
            ;;
        --install)
            if [[ -z "${2:-}" ]]; then
                print_error "Package name required. Use: hakpak --install PACKAGE_NAME"
                exit 1
            fi
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            detect_distribution
            perform_safety_checks
            install_individual_tool "$2"
            exit 0
            ;;
        --license-status|--enterprise-status)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            show_enterprise_status
            exit 0
            ;;
        --validate-license|--enterprise-validate)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            if [[ -n "${2:-}" ]]; then
                if verify_license_file "$2"; then
                    print_success "License file is valid: $2"
                    get_license_info
                else
                    print_error "Invalid license file: $2"
                    exit 1
                fi
            else
                if is_licensed; then
                    print_success "HakPak license is valid"
                    get_license_info
                else
                    print_error "No valid HakPak license found"
                    exit 1
                fi
            fi
            exit 0
            ;;
        --activate)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            if [[ -z "${2:-}" ]]; then
                print_error "License key is required"
                print_info "Usage: hakpak --activate <LICENSE_KEY>"
                print_info "Example: hakpak --activate eyJsaWNlbnNl..."
                exit 1
            fi
            
            print_info "Activating HakPak license..."
            if activate_license "$2"; then
                # Check if license was successfully activated
                if [[ "$(get_license_tier)" == "Licensed" ]]; then
                    print_success "🎉 HakPak activated successfully!"
                    echo
                    print_info "You can now access all HakPak features:"
                    echo "  • sudo hakpak --license-status"
                    echo "  • sudo hakpak --install-comprehensive"
                    echo "  • sudo hakpak (main menu)"
                else
                    print_error "License activation failed"
                    exit 1
                fi
            else
                print_error "License activation failed"
                exit 1
            fi
            exit 0
            ;;
        --pro-dashboard)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            require_pro || exit 1
            launch_pro_dashboard
            exit 0
            ;;
        --install-pro-suite)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            # Example usage inside your CLI flow:
            if [ "$1" = "--install-pro-suite" ]; then
                require_pro || exit 1
                # proceed with pro-only installs
                install_pro_tools
            fi
            exit 0
            ;;
        --init)
            touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/hakpak.log"
            # Elegant conditional pattern demonstration
            initialize_hakpak
            exit 0
            ;;
        --interactive|"")
            # Default interactive mode
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use 'hakpak --help' for usage information"
            exit 1
            ;;
    esac
    
    # Create log file
    touch "$LOG_FILE" 2>/dev/null || {
        print_warning "Cannot create log file at $LOG_FILE"
        LOG_FILE="/tmp/hakpak.log"
        touch "$LOG_FILE"
    }
    
    # Initialize system
    detect_distribution
    perform_safety_checks
    check_dependencies
    
    print_banner
    log_message "INFO" "Hakpak v$HAKPAK_VERSION started on $DISTRO_NAME $DISTRO_VERSION"
    
    # Show terms and get acceptance for interactive mode
    show_terms_and_accept
    
    main_menu
}

# Run main function
main "$@"
