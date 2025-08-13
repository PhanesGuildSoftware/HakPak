#!/bin/bash
# create_licensed_package.sh
# Creates HakPak as a fully licensed product

set -euo pipefail

VERSION="1.0.0"
DATE=$(date +%Y%m%d)
PACKAGE_DIR="downloads"
TEMP_DIR="temp_packages"

echo "📦 Creating HakPak Licensed Package..."
echo ""

# Clean up and prepare
rm -rf "$TEMP_DIR" "$PACKAGE_DIR"
mkdir -p "$TEMP_DIR" "$PACKAGE_DIR"

# Create HakPak package
echo "Creating HakPak v1.0.0 (Licensed Edition)..."
HAKPAK_PATH="$TEMP_DIR/hakpak"

mkdir -p "$HAKPAK_PATH"

# Core files
cp hakpak.sh "$HAKPAK_PATH/"
cp install.sh "$HAKPAK_PATH/"
cp install-desktop.sh "$HAKPAK_PATH/"
cp hakpak-gui.sh "$HAKPAK_PATH/"
cp -r lib/ "$HAKPAK_PATH/"

# License and keys
cp -r keys/ "$HAKPAK_PATH/"

# Logo files
cp hakpak-logo.svg "$HAKPAK_PATH/"
cp hakpak-logo.png "$HAKPAK_PATH/"
cp hakpak-icon-256.png "$HAKPAK_PATH/"
cp hakpak-icon-64.png "$HAKPAK_PATH/"

# Create README for licensed version
cat > "$HAKPAK_PATH/README.md" << 'EOF'
# HakPak v1.0.0 - Professional Security Toolkit

## ⚠️ License Activation Required

HakPak requires a valid license for all operations. Your license key has been sent to your email.

## Quick Start

1. Extract: `tar -xzf hakpak-v1.0.0-*.tar.gz`
2. Install: `cd hakpak && sudo ./install.sh`
3. **Activate license**: `sudo ./hakpak.sh --activate "YOUR_LICENSE_KEY"`
4. Verify: `sudo ./hakpak.sh --license-status`

## What's Included

✅ **15+ Essential Security Tools** (nmap, sqlmap, nikto, dirb, gobuster, hydra, john, hashcat, wireshark, wfuzz, ffuf, aircrack-ng, and more)
✅ **Advanced Tool Collections** - Extended security toolkit
✅ **Kali Metapackages** - Access to comprehensive Kali repository
✅ **System Dashboard** - Overview of installed tools and system status
✅ **Priority Email Support** - 24-48 hour response time
✅ **Commercial License** - Use in business environments
✅ **Multi-machine Rights** - Deploy on multiple systems

## Installation

```bash
# Extract and install
tar -xzf hakpak-v1.0.0-*.tar.gz
cd hakpak
sudo ./install.sh

# IMPORTANT: Activate your license
sudo ./hakpak.sh --activate "YOUR_LICENSE_KEY"

# Verify activation
sudo ./hakpak.sh --license-status

# Launch HakPak
sudo ./hakpak.sh
```

## Features (License Required)

- **Security Tool Installation** - One-click setup of 15+ essential tools
- **Dependency Management** - Automatic resolution of package conflicts
- **Kali Repository Integration** - Access to full Kali Linux toolkit
- **System Status Dashboard** - Monitor installations and system health
- **Desktop Integration** - GUI launcher and system tray integration
- **Offline Operation** - No internet required after license activation

## License Management

```bash
# Check license status
sudo ./hakpak.sh --license-status

# Validate license file
sudo ./hakpak.sh --validate-license

# View help
sudo ./hakpak.sh --help
```

## Support

- **Priority Email**: owner@phanesguild.llc
- **Response Time**: 24-48 hours
- **Business Hours**: Monday-Friday, 9 AM - 6 PM EST

License issues? Contact: licensing@phanesguild.llc

---

## License Activation Troubleshooting

### License File Not Found
```bash
# Check license file locations:
ls -la /etc/hakpak/license.lic          # System-wide
ls -la ~/.config/hakpak/license.lic     # User-specific
```

### Invalid License Error
- Verify you're using the correct license key from your email
- Ensure you're running as root: `sudo hakpak --activate KEY`
- Contact support if issues persist

### RSA Key Missing
The package includes the public key needed for validation. If you see this error, reinstall HakPak.

---
© 2025 PhanesGuild Software LLC. All rights reserved.
EOF

# Create compressed package
echo "Creating compressed package..."
cd "$TEMP_DIR"

tar -czf "../$PACKAGE_DIR/hakpak-v${VERSION}-${DATE}.tar.gz" hakpak/

cd ..

# Create checksums
cd "$PACKAGE_DIR"
sha256sum *.tar.gz > checksums.sha256
cd ..

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ HakPak Licensed package created successfully!"
echo ""
echo "📦 Package Details:"
echo "   File: hakpak-v${VERSION}-${DATE}.tar.gz"
echo "   Type: Fully Licensed Product"
echo "   Price: \$49.99"
echo "   Features: All tools, priority support, commercial license"
echo ""
echo "📋 Ready for Shopify:"
ls -la "$PACKAGE_DIR"
echo ""
echo "🎯 Single product ready for your store!"
echo ""
echo "🔑 Customer workflow:"
echo "1. Purchase HakPak (\$49.99)"
echo "2. Receive license key via email"
echo "3. Download package"
echo "4. Install and activate: sudo hakpak --activate LICENSE_KEY"
echo "5. Full access to all features"
