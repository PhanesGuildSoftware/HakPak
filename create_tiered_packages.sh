#!/bin/bash
# create_tiered_packages.sh
# Creates properly tiered HakPak packages for digital download platforms

set -eo pipefail

PACKAGE_DIR="./downloads_tiered"
TEMP_DIR="./temp_tiered"
VERSION="1.0.0"
DATE=$(date +%Y%m%d)

echo "Creating tiered HakPak packages..."

# Clean directories
rm -rf "$PACKAGE_DIR" "$TEMP_DIR"
mkdir -p "$PACKAGE_DIR" "$TEMP_DIR"

# Create base package function
create_base_package() {
    local tier="$1"
    local temp_path="$TEMP_DIR/hakpak-$tier"
    
    mkdir -p "$temp_path"
    
    # Copy core files
    cp hakpak.sh "$temp_path/"
    cp install.sh "$temp_path/"
    cp uninstall-hakpak.sh "$temp_path/"
    cp -r lib/ "$temp_path/"
    cp README.md "$temp_path/"
    cp LICENSE "$temp_path/"
    cp EULA.md "$temp_path/"
    cp SECURITY.md "$temp_path/"
    cp CHANGELOG.md "$temp_path/"
    
    echo "$temp_path"
}

# =============================================================================
# SOLO PACKAGE (License-Free)
# =============================================================================
echo "Creating Solo Ops package (license-free)..."
SOLO_PATH=$(create_base_package "solo")

# Remove licensing requirements for Solo
cp hakpak.sh "$SOLO_PATH/hakpak-solo.sh"

# Modify Solo version to remove Pro checks
sed -i 's/if is_pro_valid; then/if true; then/g' "$SOLO_PATH/hakpak-solo.sh"
sed -i 's/--activate LICENSE_KEY  Activate HakPak Pro with license key/--activate         [SOLO: License activation not required]/g' "$SOLO_PATH/hakpak-solo.sh"
sed -i '/activate_license/d' "$SOLO_PATH/hakpak-solo.sh"
sed -i '/--activate/,+10d' "$SOLO_PATH/hakpak-solo.sh"

# Create Solo-specific configuration
mkdir -p "$SOLO_PATH/config"
cat > "$SOLO_PATH/config/tier.conf" << 'EOF'
HAKPAK_TIER=solo
HAKPAK_VERSION=1.0.0
MAX_TOOLS=15
SUPPORT_LEVEL=community
UPDATE_CHANNEL=stable
LICENSE_REQUIRED=false
EOF

# Create Solo README
cat > "$SOLO_PATH/README_SOLO.md" << 'EOF'
# HakPak Solo Ops - License-Free Security Toolkit

## What You've Received

✅ **No License Required** - Solo Ops is completely free to use!

This package contains:
- Core HakPak installation files (15+ essential tools)
- Complete documentation and security guidelines
- Community support access
- No activation required - ready to use immediately

## Quick Start

1. Extract this package: `tar -xzf hakpak-solo-*.tar.gz`
2. Enter directory: `cd hakpak-solo/`
3. Install HakPak: `./install.sh`
4. Start using: `./hakpak-solo.sh --list-tools`

## Solo Features

✅ **Core Security Tools:**
- Network reconnaissance (nmap, masscan)
- Web application testing (dirb, nikto)
- Basic exploitation tools
- Documentation and guides

✅ **What's Included:**
- 15+ essential security tools
- Automatic installation and updates
- Cross-platform compatibility
- Community support via GitHub

✅ **No Restrictions:**
- No license keys needed
- No activation required
- No expiration dates
- Ready to use immediately

## Upgrade Options

Want more tools and features?

**🔥 Field Agent Pro ($49)**
- 50+ professional tools
- Custom profiles and bulk installation
- Priority email support
- Advanced features

**⚡ Black Ops Enterprise ($99)**
- Unlimited tools and experimental modules
- Multi-machine deployment
- SLA-level support
- Commercial licensing

Visit our store to upgrade!

## Support

- **GitHub Issues**: https://github.com/PhanesGuildSoftware/hakpak/issues
- **Documentation**: Complete guides included
- **Community**: GitHub discussions and wiki

---
© 2025 PhanesGuild Software LLC. Solo Ops is free for personal and educational use.
EOF

# Remove licensing library for Solo (keep a stub for compatibility)
mkdir -p "$SOLO_PATH/lib"
cat > "$SOLO_PATH/lib/license.sh" << 'EOF'
#!/usr/bin/env bash
# lib/license.sh - Solo Edition (No licensing required)

# Solo edition doesn't require licensing - all functions return "valid"
is_pro_valid() {
    return 0  # Always return true for Solo
}

activate_license() {
    echo "HakPak Solo: No license activation required!"
    echo "Solo edition is free to use immediately."
    return 0
}

license_status() {
    echo "HakPak Solo Edition - License Free"
    echo "Status: Active (No license required)"
    echo "Tier: Solo Ops"
    echo "Tools: 15+ core security tools"
    echo "Support: Community (GitHub)"
}
EOF

# =============================================================================
# PRO PACKAGE (License Required)
# =============================================================================
echo "Creating Field Agent Pro package..."
PRO_PATH=$(create_base_package "pro")

# Keep full licensing for Pro
cp -r keys/ "$PRO_PATH/"

mkdir -p "$PRO_PATH/config" "$PRO_PATH/profiles"
cat > "$PRO_PATH/config/tier.conf" << 'EOF'
HAKPAK_TIER=pro
HAKPAK_VERSION=1.0.0
MAX_TOOLS=50
SUPPORT_LEVEL=priority
UPDATE_CHANNEL=stable
PRO_FEATURES=enabled
ANALYTICS=enabled
LICENSE_REQUIRED=true
EOF

# Add Pro sample profiles
cat > "$PRO_PATH/profiles/web-pentest.json" << 'EOF'
{
  "name": "Web Penetration Testing",
  "description": "Complete web application security testing suite",
  "tools": [
    "nmap", "dirb", "nikto", "sqlmap", "burpsuite", 
    "wfuzz", "gobuster", "ffuf", "whatweb", "wpscan"
  ]
}
EOF

cat > "$PRO_PATH/README_PRO.md" << 'EOF'
# HakPak Field Agent Pro - Professional Security Toolkit

## License Activation Required

Your Pro license key has been sent to your email. Activate it to unlock all Pro features.

## Quick Start

1. Extract: `tar -xzf hakpak-pro-*.tar.gz`
2. Install: `cd hakpak-pro && ./install.sh`
3. **Activate license**: `./hakpak.sh --activate "YOUR_LICENSE_KEY"`
4. Verify: `./hakpak.sh --license-status`

## Pro Features (License Required)

✅ **50+ Professional Tools**
✅ **Custom Installation Profiles** 
✅ **Priority Email Support (24-48hr)**
✅ **Advanced Analytics Dashboard**
✅ **Lifetime Updates**
✅ **Commercial Use License**

## Support
- **Priority Email**: owner@phanesguild.llc
- **Response Time**: 24-48 hours
- **Discord**: PhanesGuildSoftware

License issues? Contact: licensing@phanesguild.llc
EOF

# =============================================================================
# ENTERPRISE PACKAGE (License Required)
# =============================================================================
echo "Creating Black Ops Enterprise package..."
ENTERPRISE_PATH=$(create_base_package "enterprise")

# Full Enterprise features
cp -r keys/ "$ENTERPRISE_PATH/"
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
LICENSE_REQUIRED=true
EOF

# Enterprise deployment tools
cat > "$ENTERPRISE_PATH/enterprise/bulk-deploy.sh" << 'EOF'
#!/bin/bash
# HakPak Enterprise Bulk Deployment Tool
echo "Enterprise bulk deployment requires license activation"
echo "Run: ./hakpak.sh --activate YOUR_LICENSE_KEY"
EOF
chmod +x "$ENTERPRISE_PATH/enterprise/bulk-deploy.sh"

cat > "$ENTERPRISE_PATH/README_ENTERPRISE.md" << 'EOF'
# HakPak Black Ops Enterprise - Ultimate Security Platform

## Enterprise License Activation Required

Your Enterprise license key enables multi-machine deployment and SLA support.

## Quick Start

1. Extract: `tar -xzf hakpak-enterprise-*.tar.gz`
2. Install: `cd hakpak-enterprise && ./install.sh`
3. **Activate license**: `./hakpak.sh --activate "YOUR_ENTERPRISE_KEY"`
4. Deploy: `./enterprise/bulk-deploy.sh servers.json`

## Enterprise Features (License Required)

✅ **Unlimited Tools + Experimental Modules**
✅ **Multi-Machine Deployment**
✅ **SLA-Level Support (4-12hr response)**
✅ **Commercial Organizational License**
✅ **Custom Tool Integration**
✅ **Enterprise Analytics & Reporting**

## Support
- **SLA Email**: owner@phanesguild.llc  
- **Response Time**: 4-12 hours guaranteed
- **Phone Support**: Available upon request
- **Discord Priority**: PhanesGuildSoftware

Enterprise support: licensing@phanesguild.llc
EOF

# Create verification scripts for each tier
for tier in solo pro enterprise; do
    tier_upper=$(echo "$tier" | tr '[:lower:]' '[:upper:]')
    tier_path_var="${tier_upper}_PATH"
    tier_path=${!tier_path_var}
    
    cat > "$tier_path/verify-installation.sh" << EOF
#!/bin/bash
echo "Verifying HakPak $tier installation..."

# Check core files
if [ ! -f "hakpak.sh" ]; then
    echo "❌ hakpak.sh not found"
    exit 1
fi

# Check tier-specific files
if [ "$tier" = "solo" ]; then
    if [ ! -f "hakpak-solo.sh" ]; then
        echo "❌ hakpak-solo.sh not found"
        exit 1
    fi
    echo "✅ Solo edition verified (license-free)"
else
    if [ ! -d "keys" ]; then
        echo "❌ License keys directory not found"
        exit 1
    fi
    echo "✅ $tier edition verified (license activation required)"
fi

echo "✅ HakPak $tier package verification complete"
EOF

    chmod +x "$tier_path/verify-installation.sh"
done

# Create compressed packages
echo "Creating compressed packages..."
cd "$TEMP_DIR"

tar -czf "../$PACKAGE_DIR/hakpak-solo-v${VERSION}-${DATE}.tar.gz" hakpak-solo/
tar -czf "../$PACKAGE_DIR/hakpak-pro-v${VERSION}-${DATE}.tar.gz" hakpak-pro/
tar -czf "../$PACKAGE_DIR/hakpak-enterprise-v${VERSION}-${DATE}.tar.gz" hakpak-enterprise/

cd ..

# Create checksums
cd "$PACKAGE_DIR"
sha256sum *.tar.gz > checksums.sha256
cd ..

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ Tiered packages created successfully!"
echo ""
echo "📦 Package Structure:"
echo "├── Solo Ops (FREE) - No license required"
echo "├── Field Agent Pro ($49) - License activation required"  
echo "└── Black Ops Enterprise ($99) - License activation required"
echo ""
echo "Upload to your digital download platform:"
ls -la "$PACKAGE_DIR"
