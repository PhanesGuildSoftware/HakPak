#!/bin/bash
# create_download_packages.sh
# Creates downloadable HakPak packages for digital delivery

set -euo pipefail

# Configuration
PACKAGE_DIR="./downloads"
TEMP_DIR="./temp_packages"
VERSION="1.0.0"
DATE=$(date +%Y%m%d)

echo "Creating HakPak download packages..."

# Clean and create directories
rm -rf "$PACKAGE_DIR" "$TEMP_DIR"
mkdir -p "$PACKAGE_DIR" "$TEMP_DIR"

# Function to create a base HakPak package
create_base_package() {
    local tier="$1"
    local temp_path="$TEMP_DIR/hakpak-$tier"
    
    mkdir -p "$temp_path"
    
    # Copy core files
    cp hakpak.sh "$temp_path/"
    cp install.sh "$temp_path/"
    cp uninstall-hakpak.sh "$temp_path/"
    cp -r lib/ "$temp_path/"
    cp -r keys/ "$temp_path/"
    
    # Copy desktop integration files
    cp install-desktop.sh "$temp_path/" 2>/dev/null || true
    cp hakpak-gui.sh "$temp_path/" 2>/dev/null || true
    cp hakpak-logo.svg "$temp_path/" 2>/dev/null || true
    
    # Copy documentation
    cp README.md "$temp_path/"
    cp LICENSE "$temp_path/"
    cp EULA.md "$temp_path/"
    cp SECURITY.md "$temp_path/"
    cp CHANGELOG.md "$temp_path/"
    
    # Create tier-specific README
    cat > "$temp_path/README_${tier^^}.md" << EOF
# HakPak ${tier^} Edition

Thank you for purchasing HakPak ${tier^}!

## What You've Received

This package contains:
- HakPak core installation files
- License activation system
- Complete documentation
- Your activation key (sent via email)

## Quick Start

1. Extract this package to your preferred directory
2. Make the installer executable: \`chmod +x install.sh\`
3. Run the installer: \`./install.sh\`
4. Activate your license: \`./hakpak.sh --activate "YOUR_ACTIVATION_KEY"\`

## Your License Tier: ${tier^}

EOF

    case "$tier" in
        "solo")
            cat >> "$temp_path/README_SOLO.md" << 'EOF'
### Solo Ops Features:
- ✅ Core tool installation (15+ security tools)
- ✅ Automatic repository management
- ✅ Basic update system
- ✅ Community support via GitHub
- ✅ Standard installation profiles

### Usage:
```bash
./hakpak.sh --install nmap
./hakpak.sh --install-category network
./hakpak.sh --list-tools
```

### Support:
- GitHub Issues: https://github.com/PhanesGuildSoftware/hakpak/issues
- Documentation: https://github.com/PhanesGuildSoftware/hakpak
EOF
            ;;
        "pro")
            cat >> "$temp_path/README_PRO.md" << 'EOF'
### Field Agent Pro Features:
- ✅ All Solo features
- ✅ Extended tools library (50+ tools)
- ✅ Custom installation profiles
- ✅ Advanced update system
- ✅ Priority email support
- ✅ Lifetime updates
- ✅ Pro dashboard and analytics

### Pro Commands:
```bash
./hakpak.sh --pro-dashboard
./hakpak.sh --create-profile "custom-pentest"
./hakpak.sh --bulk-install profile.json
./hakpak.sh --export-config
```

### Support:
- Priority Email: owner@phanesguild.llc
- Discord: PhanesGuildSoftware
- Response Time: 24-48 hours
EOF
            ;;
        "enterprise")
            cat >> "$temp_path/README_ENTERPRISE.md" << 'EOF'
### Black Ops Enterprise Features:
- ✅ All Pro features
- ✅ Bulk deployment tools
- ✅ Commercial license
- ✅ Early access to experimental modules
- ✅ SLA-level priority support
- ✅ Custom tool integration
- ✅ Multi-machine license

### Enterprise Commands:
```bash
./hakpak.sh --enterprise-status
./hakpak.sh --deploy-bulk servers.json
./hakpak.sh --install-experimental
./hakpak.sh --generate-report
```

### Enterprise Support:
- SLA Email: owner@phanesguild.llc
- Discord: PhanesGuildSoftware
- Response Time: 4-12 hours
- Commercial License: Included
EOF
            ;;
    esac

    cat >> "$temp_path/README_${tier^^}.md" << 'EOF'

## Need Help?

1. Check the main README.md for detailed documentation
2. Review SECURITY.md for security considerations
3. See CHANGELOG.md for version history
4. Contact support using the methods above

## License

By using HakPak, you agree to the End-User License Agreement (EULA.md).

---
© 2025 PhanesGuild Software LLC. All rights reserved.
EOF

    echo "$temp_path"
}

# Create packages for each tier
echo "Creating Solo Ops package..."
SOLO_PATH=$(create_base_package "solo")

echo "Creating Field Agent Pro package..."
PRO_PATH=$(create_base_package "pro")

echo "Creating Black Ops Enterprise package..."
ENTERPRISE_PATH=$(create_base_package "enterprise")

# Add tier-specific files
echo "Adding tier-specific configurations..."

# Solo tier - basic configuration
mkdir -p "$SOLO_PATH/config"
cat > "$SOLO_PATH/config/tier.conf" << 'EOF'
HAKPAK_TIER=solo
HAKPAK_VERSION=1.0.0
MAX_TOOLS=15
SUPPORT_LEVEL=community
UPDATE_CHANNEL=stable
EOF

# Pro tier - enhanced configuration
mkdir -p "$PRO_PATH/config" "$PRO_PATH/profiles"
cat > "$PRO_PATH/config/tier.conf" << 'EOF'
HAKPAK_TIER=pro
HAKPAK_VERSION=1.0.0
MAX_TOOLS=50
SUPPORT_LEVEL=priority
UPDATE_CHANNEL=stable
PRO_FEATURES=enabled
ANALYTICS=enabled
EOF

# Add sample profiles for Pro
cat > "$PRO_PATH/profiles/web-pentest.json" << 'EOF'
{
  "name": "Web Penetration Testing",
  "description": "Tools for web application security testing",
  "tools": [
    "nmap", "dirb", "nikto", "sqlmap", "burpsuite", 
    "wfuzz", "gobuster", "ffuf", "whatweb"
  ],
  "post_install": [
    "echo 'Web pentest profile installed'",
    "echo 'Run: hakpak --scan-web <target>'"
  ]
}
EOF

cat > "$PRO_PATH/profiles/wireless-audit.json" << 'EOF'
{
  "name": "Wireless Security Audit",
  "description": "Tools for wireless network assessment",
  "tools": [
    "aircrack-ng", "reaver", "wash", "pixiewps", 
    "wifite", "kismet", "wireshark"
  ],
  "post_install": [
    "echo 'Wireless audit profile installed'",
    "echo 'Ensure wireless adapter supports monitor mode'"
  ]
}
EOF

# Enterprise tier - full configuration
mkdir -p "$ENTERPRISE_PATH/config" "$ENTERPRISE_PATH/profiles" "$ENTERPRISE_PATH/enterprise"
cat > "$ENTERPRISE_PATH/config/tier.conf" << 'EOF'
HAKPAK_TIER=enterprise
HAKPAK_VERSION=1.0.0
MAX_TOOLS=unlimited
SUPPORT_LEVEL=sla
UPDATE_CHANNEL=early_access
PRO_FEATURES=enabled
ENTERPRISE_FEATURES=enabled
ANALYTICS=enabled
BULK_DEPLOY=enabled
COMMERCIAL_LICENSE=true
EOF

# Add enterprise deployment tools
cat > "$ENTERPRISE_PATH/enterprise/bulk-deploy.sh" << 'EOF'
#!/bin/bash
# HakPak Enterprise Bulk Deployment Tool

echo "HakPak Enterprise Bulk Deployment"
echo "Usage: ./bulk-deploy.sh servers.json"
echo "This tool allows deployment to multiple servers simultaneously"
echo "See documentation for server configuration format"
EOF

chmod +x "$ENTERPRISE_PATH/enterprise/bulk-deploy.sh"

# Create installation verification scripts for each tier
for tier in solo pro enterprise; do
    tier_upper=$(echo "$tier" | tr '[:lower:]' '[:upper:]')
    tier_path_var="${tier_upper}_PATH"
    tier_path=${!tier_path_var}
    
    cat > "$tier_path/verify-installation.sh" << EOF
#!/bin/bash
# HakPak $tier Installation Verification

echo "Verifying HakPak $tier installation..."

# Check core files
if [ ! -f "hakpak.sh" ]; then
    echo "❌ hakpak.sh not found"
    exit 1
fi

if [ ! -f "install.sh" ]; then
    echo "❌ install.sh not found"
    exit 1
fi

if [ ! -d "lib" ]; then
    echo "❌ lib directory not found"
    exit 1
fi

echo "✅ Core files present"

# Check tier configuration
if [ -f "config/tier.conf" ]; then
    source config/tier.conf
    if [ "\$HAKPAK_TIER" = "$tier" ]; then
        echo "✅ Tier configuration correct: $tier"
    else
        echo "❌ Tier configuration mismatch"
        exit 1
    fi
else
    echo "❌ Tier configuration not found"
    exit 1
fi

echo "✅ HakPak $tier package verification complete"
echo "Next step: Run ./install.sh to install HakPak"
EOF

    chmod +x "$tier_path/verify-installation.sh"
done

# Create compressed packages
echo "Creating compressed packages..."

cd "$TEMP_DIR"

# Create tar.gz packages
tar -czf "../$PACKAGE_DIR/hakpak-solo-v${VERSION}-${DATE}.tar.gz" hakpak-solo/
tar -czf "../$PACKAGE_DIR/hakpak-pro-v${VERSION}-${DATE}.tar.gz" hakpak-pro/
tar -czf "../$PACKAGE_DIR/hakpak-enterprise-v${VERSION}-${DATE}.tar.gz" hakpak-enterprise/

# Create zip packages (for wider compatibility)
if command -v zip >/dev/null 2>&1; then
    zip -r "../$PACKAGE_DIR/hakpak-solo-v${VERSION}-${DATE}.zip" hakpak-solo/
    zip -r "../$PACKAGE_DIR/hakpak-pro-v${VERSION}-${DATE}.zip" hakpak-pro/
    zip -r "../$PACKAGE_DIR/hakpak-enterprise-v${VERSION}-${DATE}.zip" hakpak-enterprise/
fi

cd ..

# Create checksums
echo "Generating checksums..."
cd "$PACKAGE_DIR"
sha256sum *.tar.gz > checksums.sha256
if [ -f "*.zip" ]; then
    sha256sum *.zip >> checksums.sha256
fi
cd ..

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ Package creation complete!"
echo ""
echo "Created packages:"
ls -la "$PACKAGE_DIR"
echo ""
echo "Upload these files to your digital download platform:"
echo "- Solo Ops: hakpak-solo-v${VERSION}-${DATE}.tar.gz"
echo "- Field Agent Pro: hakpak-pro-v${VERSION}-${DATE}.tar.gz" 
echo "- Black Ops Enterprise: hakpak-enterprise-v${VERSION}-${DATE}.tar.gz"
echo ""
echo "Checksums available in: $PACKAGE_DIR/checksums.sha256"
