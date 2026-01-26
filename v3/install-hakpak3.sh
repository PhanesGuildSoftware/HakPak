#!/usr/bin/env bash
#
# HakPak3 Installation Script
# Installs HakPak3 system-wide
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/hakpak3"
BIN_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
cat << "EOF"
██╗  ██╗ █████╗ ██╗  ██╗██████╗  █████╗ ██╗  ██╗██████╗ 
██║  ██║██╔══██╗██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝╚════██╗
███████║███████║█████╔╝ ██████╔╝███████║█████╔╝  █████╔╝
██╔══██║██╔══██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗  ╚═══██╗
██║  ██║██║  ██║██║  ██╗██║     ██║  ██║██║  ██╗██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
                 Installation Script v3.0                 
EOF
echo -e "${NC}\n"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

echo -e "${CYAN}Installing HakPak3...${NC}\n"

# Create installation directory
echo -e "${GREEN}[1/5]${NC} Creating installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin"
mkdir -p "$INSTALL_DIR/src"
mkdir -p "$INSTALL_DIR/venv"

# Copy files
echo -e "${GREEN}[2/5]${NC} Copying HakPak3 files..."
cp "$SCRIPT_DIR/hakpak3.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak3_core.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/kali-tools-db.yaml" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak3.sh" "$INSTALL_DIR/"

# Set permissions
chmod +x "$INSTALL_DIR/hakpak3.sh"
chmod +x "$INSTALL_DIR/hakpak3.py"
chmod +x "$INSTALL_DIR/hakpak3_core.py"

# Install dependencies
echo -e "${GREEN}[3/5]${NC} Installing Python dependencies..."
python3 -m pip install pyyaml --break-system-packages 2>/dev/null || python3 -m pip install pyyaml

# Create symlink
echo -e "${GREEN}[4/5]${NC} Creating system symlink..."
ln -sf "$INSTALL_DIR/hakpak3.sh" "$BIN_DIR/hakpak3"
chmod +x "$BIN_DIR/hakpak3"

# Verify installation
echo -e "${GREEN}[5/5]${NC} Verifying installation..."
if command -v hakpak3 &> /dev/null; then
    echo -e "\n${GREEN}HakPak3 installed successfully!${NC}\n"
    echo -e "${CYAN}Usage:${NC}"
    echo "  Run 'sudo hakpak3' to start HakPak3"
    echo "  Run 'hakpak3 --version' to check version"
    echo ""
    echo -e "${CYAN}Installation location:${NC} $INSTALL_DIR"
    echo -e "${CYAN}Executable:${NC} $BIN_DIR/hakpak3"
    echo ""
    echo -e "${YELLOW}NOTE: HakPak3 requires root privileges for installing tools${NC}"
else
    echo -e "\n${RED}ERROR: Installation verification failed${NC}"
    exit 1
fi
