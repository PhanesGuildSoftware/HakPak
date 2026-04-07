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
mkdir -p "$INSTALL_DIR/gui/static"

# Copy files
echo -e "${GREEN}[2/5]${NC} Copying HakPak4 files..."
cp "$SCRIPT_DIR/hakpak4.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak4_core.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/gitclone.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/version.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/VERSION" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/kali-tools-db.yaml" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/hakpak4.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/gui/server.py" "$INSTALL_DIR/gui/"
cp "$SCRIPT_DIR/gui/static/index.html" "$INSTALL_DIR/gui/static/"
cp "$SCRIPT_DIR/gui/static/main.js" "$INSTALL_DIR/gui/static/"
cp "$SCRIPT_DIR/gui/static/style.css" "$INSTALL_DIR/gui/static/"

# Set permissions
chmod +x "$INSTALL_DIR/hakpak4.sh"
chmod +x "$INSTALL_DIR/hakpak4.py"
chmod +x "$INSTALL_DIR/hakpak4_core.py"
chmod +x "$INSTALL_DIR/gitclone.py"
chmod +x "$INSTALL_DIR/gui/server.py"

# Install dependencies
echo -e "${GREEN}[3/5]${NC} Installing Python dependencies..."
python3 -m pip install pyyaml flask --break-system-packages 2>/dev/null || python3 -m pip install pyyaml flask

# Create symlink
echo -e "${GREEN}[4/6]${NC} Creating system symlink..."
ln -sf "$INSTALL_DIR/hakpak4.sh" "$BIN_DIR/hakpak4"
chmod +x "$BIN_DIR/hakpak4"

# Install desktop icon and launcher entry
echo -e "${GREEN}[5/6]${NC} Installing desktop icon and launcher..."
# Copy icon to /opt/hakpak4 for in-tree use
cp "$SCRIPT_DIR/../assets/brand/hakpak4-icon.svg" "$INSTALL_DIR/hakpak4-icon.svg" 2>/dev/null || true
# Install to standard pixmaps so desktops can find it
install -Dm644 "$SCRIPT_DIR/../assets/brand/hakpak4-icon.svg" /usr/share/pixmaps/hakpak4-icon.svg || true
# Generate PNG icons in common sizes under hicolor (best-effort; requires python3-pillow or cairosvg)
for sz in 16 24 32 48 64 128 256; do
  install -d "/usr/share/icons/hicolor/${sz}x${sz}/apps"
  python3 - "$SCRIPT_DIR/../assets/brand/hakpak4-icon.svg" "/usr/share/icons/hicolor/${sz}x${sz}/apps/hakpak4.png" "$sz" <<'PY' 2>/dev/null || true
import sys
try:
    import cairosvg
    cairosvg.svg2png(url=sys.argv[1], write_to=sys.argv[2],
                     output_width=int(sys.argv[3]), output_height=int(sys.argv[3]))
except Exception:
    try:
        from PIL import Image
        import io
        import subprocess
        svg = sys.argv[1]; out = sys.argv[2]; sz = int(sys.argv[3])
        r = subprocess.run(['rsvg-convert', '-w', str(sz), '-h', str(sz), svg],
                           capture_output=True)
        if r.returncode == 0:
            with open(out, 'wb') as f: f.write(r.stdout)
    except Exception:
        pass
PY
done
# Install .desktop entry
install -Dm644 "$SCRIPT_DIR/hakpak4.desktop" /usr/share/applications/hakpak4.desktop || true
# Refresh icon/desktop caches (best-effort)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q /usr/share/applications 2>/dev/null || true
command -v gtk-update-icon-cache   >/dev/null 2>&1 && gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
echo -e "  ${GREEN}✓ Desktop icon and launcher entry installed${NC}"

# Verify installation
echo -e "${GREEN}[6/6]${NC} Verifying installation..."
if command -v hakpak4 &> /dev/null; then
    echo -e "\n${GREEN}HakPak4 installed successfully!${NC}\n"
    echo -e "${CYAN}Usage:${NC}"
    echo "  Run 'hakpak4' to start HakPak4"
    echo "  Run 'hakpak4 --gui' (or 'hakpak4 gui') to launch Script Builder GUI"
    echo "  Run 'hakpak4 gitclone <github-url>' for secure repository installs"
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
