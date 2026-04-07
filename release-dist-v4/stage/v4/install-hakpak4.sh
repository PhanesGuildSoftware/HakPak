#!/usr/bin/env bash
#
# HakPak4 Installation Script
# Installs HakPak4 system-wide
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/hakpak4"
BIN_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
APP_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE" 2>/dev/null || echo "unknown")"

echo -e "${CYAN}"
cat << "EOF"
██╗  ██╗ █████╗ ██╗  ██╗██████╗  █████╗ ██╗  ██╗██████╗ 
██║  ██║██╔══██╗██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝╚════██╗
███████║███████║█████╔╝ ██████╔╝███████║█████╔╝  █████╔╝
██╔══██║██╔══██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗  ╚═══██╗
██║  ██║██║  ██║██║  ██╗██║     ██║  ██║██║  ██╗██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
                Installation Script v${APP_VERSION}                
EOF
echo -e "${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

echo -e "${CYAN}Installing HakPak4...${NC}\n"

# Create installation directory
echo -e "${GREEN}[1/5]${NC} Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/venv"

# Copy files
echo -e "${GREEN}[2/5]${NC} Copying HakPak4 files..."
cp "$SCRIPT_DIR/hakpak4.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak4_core.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/version.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/VERSION" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/kali-tools-db.yaml" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak4.sh" "$INSTALL_DIR/"

# Set permissions
chmod +x "$INSTALL_DIR/hakpak4.sh"
chmod +x "$INSTALL_DIR/hakpak4.py"
chmod +x "$INSTALL_DIR/hakpak4_core.py"

# Install dependencies
echo -e "${GREEN}[3/5]${NC} Installing Python dependencies..."
python3 -m pip install pyyaml --break-system-packages 2>/dev/null || python3 -m pip install pyyaml

# Create symlink
echo -e "${GREEN}[4/5]${NC} Creating system symlink..."
ln -sf "$INSTALL_DIR/hakpak4.sh" "$BIN_DIR/hakpak4"
chmod +x "$BIN_DIR/hakpak4"

# Verify installation
echo -e "${GREEN}[5/5]${NC} Verifying installation..."
if command -v hakpak4 &> /dev/null; then
    echo -e "\n${GREEN}HakPak4 installed successfully!${NC}\n"
    echo -e "${CYAN}Usage:${NC}"
    echo "  Run 'sudo hakpak4' to start HakPak4"
    echo "  Run 'hakpak4 --version' to check version"
    echo "  Installed version: ${APP_VERSION}"
    echo ""
    echo -e "${CYAN}Installation location:${NC} $INSTALL_DIR"
    echo -e "${CYAN}Executable:${NC} $BIN_DIR/hakpak4"
    echo ""
    echo -e "${YELLOW}NOTE: HakPak4 requires root privileges for installing tools${NC}"
else
    echo -e "\n${RED}ERROR: Installation verification failed${NC}"
    exit 1
fi
