#!/bin/bash

# HakPak Development Environment Setup
# Sets up this directory as the primary HakPak development environment

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🛡️  Setting up HakPak Primary Directory${NC}"
echo "=================================================="

# Get current directory
HAKPAK_DIR="$(pwd)"
echo -e "${GREEN}Primary Directory:${NC} $HAKPAK_DIR"

# Source the configuration
if [ -f ".hakpak-config" ]; then
    source .hakpak-config
    echo -e "${GREEN}✓${NC} Loaded project configuration"
else
    echo -e "${YELLOW}⚠${NC} No configuration file found"
fi

# Verify essential files
essential_files=(
    "hakpak.sh"
    "install.sh"
    "README.md"
    "LICENSE"
)

echo -e "\n${BLUE}Checking essential files:${NC}"
for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file (missing)"
    fi
done

# Set proper permissions
echo -e "\n${BLUE}Setting permissions:${NC}"
chmod +x *.sh 2>/dev/null || true
echo -e "${GREEN}✓${NC} Made shell scripts executable"

# Check git status
echo -e "\n${BLUE}Git repository status:${NC}"
if [ -d ".git" ]; then
    echo -e "${GREEN}✓${NC} Git repository initialized"
    git status --short
else
    echo -e "${YELLOW}⚠${NC} No git repository found"
fi

# Create symbolic link to main script in PATH (optional)
echo -e "\n${BLUE}Optional: Create system-wide access${NC}"
echo "To make HakPak available system-wide, run:"
echo "  sudo ln -sf $HAKPAK_DIR/hakpak.sh /usr/local/bin/hakpak"

echo -e "\n${GREEN}🎉 HakPak primary directory setup complete!${NC}"
echo -e "You can now run: ${BLUE}./hakpak.sh${NC} to start HakPak"
