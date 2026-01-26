#!/usr/bin/env bash
#
# HakPak3 Launcher Script
# Automatically handles Python environment and launches HakPak3
#

set -e

# Resolve the real script directory (follow symlinks)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
    [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
HAKPAK3_PY="$SCRIPT_DIR/hakpak3_core.py"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}ERROR: Python 3 is not installed!${NC}"
    echo "Please install Python 3 first:"
    echo "  Ubuntu/Debian: sudo apt install python3"
    echo "  Fedora/RHEL:   sudo dnf install python3"
    echo "  Arch:          sudo pacman -S python"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.8"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
    echo -e "${RED}ERROR: Python 3.8+ required (found $PYTHON_VERSION)${NC}"
    exit 1
fi

# Check for PyYAML
if ! python3 -c "import yaml" 2>/dev/null; then
    echo -e "${YELLOW}WARNING: PyYAML not found. Installing...${NC}"
    if [ "$EUID" -eq 0 ]; then
        python3 -m pip install pyyaml --break-system-packages 2>/dev/null || python3 -m pip install pyyaml
    else
        python3 -m pip install --user pyyaml
    fi
fi

# Launch HakPak3

exec python3 "$HAKPAK3_PY" "$@"
