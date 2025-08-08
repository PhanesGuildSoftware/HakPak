# 🛡️ Hakpak - Universal Kali Tools for Debian Systems

**The easiest way to install Kali Linux security tools on any Debian-based distribution**

*Developed by PhanesGuild Software LLC*

---

## 🚀 What is Hakpak?

Hakpak is a professional-grade, universal tool installer that brings the power of Kali Linux's security toolkit to all major Debian-based distributions. Whether you're a cybersecurity professional, penetration tester, or security enthusiast, Hakpak provides a clean, controlled way to install and manage Kali tools across Ubuntu, Debian, Pop!_OS, Linux Mint, and Parrot OS.

## ✨ Key Features

- **� Universal Multi-Distro Support** - Works on 5+ Debian-based distributions
- **�🎯 Complete Metapackage Support** - Install official Kali metapackages with ease
- **🔧 Smart Dependency Resolution** - Handles conflicts and dependencies automatically  
- **🛡️ Safe Repository Management** - Properly configured Kali repositories with pinning
- **📊 Advanced System Monitoring** - Track installations, disk usage, and system health
- **🔄 Intelligent Cleanup** - Remove repositories and fix dependency issues
- **💻 Professional CLI Interface** - Full command-line support with interactive menus
- **📦 Modular Architecture** - Extensible design for future premium features
- **🖥️ Desktop Integration** - Application menu integration with professional icons

## 🎯 Perfect For

- **Cybersecurity Professionals** - Get your tools without the overhead of a full Kali system
- **Penetration Testers** - Essential toolkit on your preferred Linux distribution
- **Security Students** - Learn with industry-standard tools across platforms
- **System Administrators** - Security auditing and monitoring tools on any Debian-based system
- **Developers** - Security testing tools for your development environment

## 📋 System Requirements

### Supported Distributions
- **Ubuntu 20.04+ (LTS recommended)**
- **Debian 11+ (Bullseye and newer)**
- **Pop!_OS 20.04+ (System76)**
- **Linux Mint 20+ (Cinnamon/MATE/Xfce)**
- **Parrot OS 4.11+ (Security Edition)**

### Hardware Requirements
- **2GB+ available disk space (8GB+ for large packages)**
- **Internet connection**
- **Root/sudo access**
- **x86_64 (amd64) architecture**

## 🔧 Installation

### Professional Install
```bash
# Download and run the commercial installer
sudo ./commercial-install.sh
```

### Quick Setup
```bash
# Copy files to system locations
sudo cp hakpak.sh /usr/local/bin/hakpak
sudo cp hakpak.desktop /usr/share/applications/
sudo cp hakpak-*.png /usr/share/icons/hicolor/*/apps/
sudo chmod +x /usr/local/bin/hakpak
sudo update-desktop-database
```

## 🎮 Usage

### From Applications Menu
- Open your applications menu
- Search for "Hakpak"
- Click to launch

### From Terminal
```bash
# Interactive mode
sudo hakpak

# Command-line options
sudo hakpak --help                       # Show help
sudo hakpak --status                     # System status
sudo hakpak --install kali-linux-default # Install package
sudo hakpak --setup-repo                 # Setup repository
```

## 📦 Available Tool Collections

### Metapackage Collections
- **kali-linux-core** - Essential Kali base system
- **kali-linux-default** - Standard desktop tools
- **kali-linux-top10** - Most popular security tools
- **kali-linux-large** - Comprehensive toolset (~8GB)
- **kali-linux-everything** - Complete collection (~15GB)

### Security Tools
- **Information Gathering** - OSINT and reconnaissance
- **Vulnerability Assessment** - Security scanning tools
- **Web Application Testing** - Web security tools
- **Password Attacks** - Credential testing tools
- **Wireless Security** - Wi-Fi and Bluetooth tools
- **Digital Forensics** - Investigation and analysis
- **Exploitation Tools** - Penetration testing frameworks

### Specialized Categories
- **GPU-Accelerated Tools** - Hardware-optimized security tools
- **Hardware Hacking** - Physical security testing
- **Cryptography & Steganography** - Data protection tools
- **Reverse Engineering** - Binary analysis tools

## 🛡️ Safety Features

- **Repository Pinning** - Prevents Ubuntu package conflicts
- **Dependency Checking** - Pre-installation conflict detection
- **Backup Creation** - Automatic sources.list backup
- **Rollback Support** - Easy repository removal
- **System Monitoring** - Disk space and status tracking

## 📞 Support & Documentation

### Quick Help
```bash
# View system status
kabuntool # Choose option 4

# Fix dependency issues
kabuntool # Choose option 6

# Remove Kali repository
kabuntool # Choose option 7
```

### Professional Support
- **Email**: support@phanesguild.com
- **Documentation**: Available in application and via `hakpak --help`
- **Updates**: Automatic notifications for new versions
- **Commercial Support**: Enterprise licensing available

## 🚀 Roadmap & Premium Features

### Coming Soon (Pro/Premium)
- **Custom Toolkits Manager** - Create and share custom tool collections
- **Offline Installer Mode** - Air-gapped environment support
- **Container Isolation Mode** - Sandboxed installations via Docker
- **Team Management** - Multi-user configurations and profiles
- **Automated Updates** - Scheduled maintenance and updates

## 📄 License & Legal

- **Commercial License**: Professional use permitted
- **Copyright**: © 2025 PhanesGuild Software LLC
- **Version**: 1.0
- **Platform**: Multi-distribution Debian-based systems (x64)

## ⚠️ Important Notes

- Requires sudo/root privileges for package installation
- Some tools may require additional hardware (GPU, SDR, etc.)
- Large metapackages require significant disk space
- Always backup important data before installing security tools
- Intended for legitimate security testing and education only
- Multi-distribution support - tested on 5+ major Debian-based distros

---

## 🔄 Uninstallation

```bash
# Remove Hakpak (keeps installed tools)
sudo hakpak-uninstall

# Or manually remove
sudo rm /usr/local/bin/hakpak
sudo rm /usr/share/applications/hakpak.desktop
sudo rm /usr/share/icons/hicolor/*/apps/hakpak.png
```

---

*Forge wisely. Strike precisely.*

**PhanesGuild Software LLC** - Professional Security Tools for Linux
sudo kabuntool-uninstall

# To also remove Kali repository
sudo kabuntool  # Choose option 7, then uninstall
```

---

**Kabuntool - Professional Security Tools Made Simple**

*PhanesGuild Software LLC - Empowering Cybersecurity Professionals*
