# 🛡️ HakPak v2.0 - Universal Kali Tools Installer

**Transform Any Debian-Based System into a Professional Security Workstation**

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://phanesguild.com)
[![Platform](https://img.sh### **Monitoring & Maintenance**

#### **System Health Monitoring**
```bash
# Check HakPak system status
hakpak --status

# View recent activity logs
hakpak     # Option 11: View Installation Log

# Monitor disk space usage
df -h /

# Check installed Kali packages
dpkg -l | grep kali
```

#### **Regular Maintenance Tasks**
```bash
# Update package repositories
sudo apt update

# Fix any dependency issues
hakpak     # Option 7: Fix Dependencies

# Clean up unnecessary packages
sudo apt autoremove
sudo apt autoclean
```

#### **Troubleshooting Common Issues**
```bash
# If tools fail to install:
hakpak     # Option 7: Fix Dependencies
sudo hakpak --fix-deps

# If repository issues occur:
hakpak     # Option 6: Remove Kali Repository
hakpak     # Option 5: Setup Kali Repository

# Check logs for detailed error information:
sudo tail -f /var/log/hakpak.log
```

---

## 🖥️ **Desktop Application Features**ds.io/badge/platform-linux-lightgrey.svg)](https://phanesguild.com)
[![License](https://img.shields.io/badge/license-commercial-green.svg)](https://phanesguild.com)

*Developed by Teyvone Wells @ PhanesGuild Software LLC*

---

## 🎯 **Product Overview**

HakPak is a revolutionary desktop application that brings the complete arsenal of Kali Linux security tools to any Debian-based system. With enterprise-grade dependency resolution, advanced conflict management, and a Windows-like installation experience, HakPak makes professional penetration testing accessible to everyone.

### **Why Choose HakPak?**

- ✅ **Zero Configuration** - Works out of the box on any supported system
- ✅ **Professional Grade** - Enterprise dependency resolution and conflict management  
- ✅ **Windows-Like Experience** - Familiar installation and usage patterns
- ✅ **Advanced Features** - Custom toolkits, offline installation, container isolation
- ✅ **Production Ready** - Comprehensive logging, error handling, and recovery
- ✅ **Secure by Design** - PolicyKit authentication, no hardcoded credentials

---

## 🚀 **Installation Guide**

### **Simple 4-Step Process (Just Like Windows)**

1. **📥 Download** - Get HakPak from [PhanesGuild.com](https://phanesguild.com)
2. **📂 Extract** - Right-click the ZIP file → "Extract All"
3. **⚙️ Install** - Run the installation wizard
4. **🖥️ Launch** - Double-click the desktop icon to start

### **Detailed Installation Instructions**

#### **Step 1: Download & Extract**
```bash
# Download HakPak-v2.0.zip from https://phanesguild.com
# Extract to your preferred location
unzip HakPak-v2.0.zip
cd HakPak
```

#### **Step 2: Run Installation Wizard**
```bash
# Make installer executable
chmod +x install.sh

# Launch installation wizard
./install.sh
```

> 📋 **Need a visual guide?** See our [Quick Start Guide](QUICK-START.md) for step-by-step screenshots and detailed walkthrough.

#### **Step 3: Choose Installation Type**
The installer presents three professional options:

**🖥️ Option 1: Desktop Application (Recommended)**
- Complete Windows-like experience
- Desktop shortcut with professional icon
- Application menu integration
- GUI authentication dialogs
- Right-click quick actions
- Perfect for desktop workstations

**💻 Option 2: Command Line Only** 
- Minimal server installation
- Terminal-only interface
- Smaller system footprint
- Ideal for headless systems

**📦 Option 3: Portable Mode**
- No system installation required
- Run from any directory
- Perfect for testing or demonstrations

#### **Step 4: Authentication & Completion**
- Enter **your system password** when prompted
- Installation completes automatically
- HakPak icon appears on desktop
- Application is ready to use

---

## � **How to Use HakPak Effectively**

### **First Launch & Getting Started**

#### **Desktop Users (Recommended)**
1. **Find Your Icon** - Look for the HakPak icon on your desktop or in Applications menu
2. **Launch Application** - Double-click the icon (you'll be prompted for your password)
3. **Main Menu** - Navigate through the professional interface with numbered options
4. **Start Small** - Begin with Option 1: "Install Kali Top 10 Tools" (~500MB)

#### **Command Line Users**
```bash
# Launch interactive menu
hakpak

# Or run specific commands directly
sudo hakpak --install kali-linux-top10
```

### **Understanding the Main Menu**

When you launch HakPak, you'll see this professional interface:

```
═══════════════════════════════════════
HAKPAK MAIN FORGE
═══════════════════════════════════════
1) Install Kali Top 10 Tools
2) Install Full Kali Toolset  
3) Install Individual Tool
4) Show System Status
5) Setup Kali Repository
6) Remove Kali Repository
7) Fix Dependencies
8) Custom Toolkits Manager
9) Offline Installer Mode
10) Container Isolation Mode
11) View Installation Log
12) Exit
═══════════════════════════════════════
```

### **Recommended First-Time Workflow**

#### **Step 1: Check System Status (Option 4)**
Always start by checking your system status:
- Verifies your distribution is supported
- Shows available disk space
- Displays current repository configuration
- Identifies any existing issues

#### **Step 2: Install Top 10 Tools (Option 1)**
Perfect starting point for new users:
- Contains the most essential security tools
- Moderate download size (~500MB)
- Tests your system compatibility
- Provides immediate value

**Tools included in Top 10:**
- Nmap (network scanner)
- Wireshark (network analyzer)
- Burp Suite (web security)
- Metasploit (exploitation framework)
- John the Ripper (password cracker)
- And 5 more essential tools

#### **Step 3: Verify Installation Success**
After installation completes:
```bash
# Test that tools are working
nmap --version
wireshark --version
burpsuite --version
```

### **Progressive Tool Installation Strategy**

#### **Beginner → Intermediate**
```bash
1. kali-linux-top10                    # Start here (500MB)
2. kali-tools-web-application          # Web security focus (1GB)
3. kali-tools-vulnerability-assessment # Security scanning (1.5GB)
```

#### **Intermediate → Advanced**
```bash
4. kali-tools-wireless                 # Wireless security (800MB)
5. kali-tools-forensics               # Digital forensics (2GB)
6. kali-tools-exploitation            # Advanced exploitation (2GB)
```

#### **Advanced → Expert**
```bash
7. kali-linux-large                   # Comprehensive collection (8GB)
8. kali-linux-everything              # Complete arsenal (15GB)
```

### **Using Advanced Features**

#### **Custom Toolkits Manager (Option 8)**
Create project-specific tool collections:
1. Select "Create New Toolkit"
2. Name your toolkit (e.g., "WebPenTest2024")
3. Add specific tools for your project
4. Export toolkit for team sharing
5. Import colleague's toolkits

#### **Offline Installation Mode (Option 9)**
Perfect for air-gapped environments:
1. Download packages on internet-connected system
2. Transfer to offline target system
3. Install without internet connectivity
4. Create local repository mirrors

#### **Container Isolation (Option 10)**
Advanced users can isolate tools in containers:
1. Create isolated Kali containers
2. Install tools in sandbox environments
3. Test dangerous tools safely
4. Export/import container configurations

### **Daily Workflow Examples**

#### **Web Application Penetration Testing**
```bash
# Launch HakPak
hakpak

# Install web security tools (Option 3 → enter package name)
kali-tools-web-application

# Tools now available:
burpsuite      # Professional web scanner
sqlmap         # SQL injection testing
dirb           # Directory brute forcing
nikto          # Web vulnerability scanner
```

#### **Network Security Assessment**
```bash
# Install network tools
sudo hakpak --install nmap
sudo hakpak --install wireshark
sudo hakpak --install aircrack-ng

# Use tools:
nmap -sV target.com           # Service version detection
wireshark &                   # GUI network analyzer
airmon-ng start wlan0         # Wireless monitoring
```

#### **Digital Forensics Investigation**
```bash
# Install forensics toolkit
sudo hakpak --install kali-tools-forensics

# Tools available:
autopsy        # Digital forensics platform  
volatility     # Memory analysis
foremost       # File carving
hashdeep       # File integrity checking
```

---

## �🖥️ **Desktop Application Features**

HakPak provides a complete professional desktop application experience:

### **🎯 Instant Access Methods**
- **Desktop Shortcut** - Professional HakPak icon on your desktop
- **Application Menu** - Available under System Tools/Administration  
- **Search Integration** - Type "HakPak" in your system launcher
- **Terminal Access** - Run `hakpak` from any command line

### **🔐 Enterprise Authentication**
- **PolicyKit Integration** - Secure GUI password prompts (like Windows UAC)
- **Smart Detection** - Automatic GUI/terminal authentication switching
- **Zero Hardcoded Credentials** - Always uses your personal system password
- **Audit Trail** - Complete logging of all authentication events

### **⚡ Professional Quick Actions**
Right-click the desktop icon for instant access to:
- **Install Kali Top 10** - Most popular security tools
- **Install Web Security Tools** - Complete web application testing suite
- **Open Interactive Menu** - Full application interface  
- **System Status Check** - Health monitoring and diagnostics

---

## 📁 **System Integration**

HakPak installs as a complete professional application suite:

```
System Installation Layout:
├── /usr/local/bin/
│   ├── hakpak                    # Main application executable
│   └── hakpak-launcher           # Desktop launcher with authentication
├── /usr/share/applications/
│   └── hakpak.desktop            # System application menu entry
├── /usr/share/icons/hicolor/
│   ├── 16x16/apps/hakpak.png     # High-DPI icon support
│   ├── 32x32/apps/hakpak.png     # Standard resolution icons
│   ├── 48x48/apps/hakpak.png     # Application menu icons
│   ├── 64x64/apps/hakpak.png     # Taskbar icons
│   ├── 128x128/apps/hakpak.png   # Large icon displays
│   └── scalable/apps/hakpak.svg  # Vector icon (infinite scaling)
├── /usr/share/polkit-1/actions/
│   └── com.phanesguild.hakpak.policy  # Enterprise authentication policy
└── ~/Desktop/
    └── HakPak.desktop            # Personal desktop shortcut
```

---

## 🔧 **System Requirements**

### **Supported Operating Systems**
- **Ubuntu** 20.04+ (LTS releases recommended for stability)
- **Debian** 11+ (Bullseye and newer versions)
- **Pop!_OS** 20.04+ (System76's Ubuntu-based distribution)
- **Linux Mint** 20+ (Ubuntu-based desktop distribution)
- **Parrot OS** 4.11+ (Security-focused distribution)

### **Hardware Requirements**
- **Memory:** 2GB RAM minimum (4GB+ recommended for optimal performance)
- **Storage:** 2GB free disk space minimum (8GB+ recommended for full toolsets)
- **Network:** Stable internet connection required for installation
- **Privileges:** Administrator/sudo access required

### **Desktop Environment Compatibility**
HakPak seamlessly integrates with all major desktop environments:
- **Primary Support:** GNOME, KDE Plasma, XFCE, MATE
- **Additional Support:** Cinnamon, LXQt, Budgie, Pantheon
- **Window Managers:** i3, Openbox, Awesome, dwm, and others

---

## 🛠️ **Professional Tool Collections**

### **📦 Core Metapackages**
- **`kali-linux-core`** - Essential Kali base system and foundations
- **`kali-linux-top10`** - Top 10 most popular tools (~500MB)
- **`kali-linux-default`** - Standard desktop installation (~2GB)  
- **`kali-linux-large`** - Comprehensive collection (~8GB)
- **`kali-linux-everything`** - Complete arsenal (~15GB)

### **🎯 Specialized Security Collections**

#### **Information Gathering & OSINT**
- **`kali-tools-information-gathering`** - Reconnaissance and intelligence tools
- **`kali-tools-social-engineering`** - Social engineering frameworks

#### **Vulnerability Assessment**  
- **`kali-tools-vulnerability-assessment`** - Security scanners and analyzers
- **`kali-tools-web-application`** - Web application security testing

#### **Exploitation & Penetration Testing**
- **`kali-tools-exploitation`** - Penetration testing frameworks
- **`kali-tools-post-exploitation`** - Post-compromise tools

#### **Specialized Security Domains**
- **`kali-tools-wireless`** - Wireless security and analysis
- **`kali-tools-forensics`** - Digital forensics and incident response
- **`kali-tools-passwords`** - Password attacks and analysis
- **`kali-tools-database`** - Database security assessment
- **`kali-tools-reverse-engineering`** - Binary analysis and reverse engineering
- **`kali-tools-hardware`** - Hardware hacking and analysis
- **`kali-tools-crypto-stego`** - Cryptography and steganography
- **`kali-tools-gpu`** - GPU-accelerated security tools

---

## 🚀 **Advanced Professional Features**

### **🛠️ Custom Toolkit Manager**
Create and manage personalized security tool collections:
```bash
# Access through: HakPak → Custom Toolkits Manager
✓ Create custom tool collections for specific projects
✓ Import/Export toolkits for team collaboration  
✓ Share standardized toolsets across your organization
✓ Version control your security toolkit configurations
```

### **📦 Offline Installation System**
Enterprise-grade offline deployment capabilities:
```bash
# Access through: HakPak → Offline Installer Mode
✓ Download complete tool collections for offline use
✓ Create portable local repositories  
✓ Deploy in air-gapped environments
✓ Install without internet connectivity
```

### **🐳 Container Isolation Mode**
Advanced containerized security testing:
```bash
# Access through: HakPak → Container Isolation Mode
✓ Run tools in isolated Docker containers
✓ Safe testing environment with no host contamination
✓ Export/Import container configurations
✓ Multiple Kali versions simultaneously
```

### **⚙️ Advanced Dependency Management**
Enterprise-grade package conflict resolution:
```bash
✓ Automatic version conflict detection and resolution
✓ Ruby/Python version compatibility management
✓ Smart repository pinning and prioritization
✓ Rollback capabilities for failed installations
```

### **💡 Best Practices & Pro Tips**

#### **Installation Best Practices**
- ⭐ **Start Small** - Always begin with `kali-linux-top10` before larger collections
- ⭐ **Check Space** - Ensure sufficient disk space before large installations
- ⭐ **System Updates** - Run `sudo apt update && sudo apt upgrade` before installation
- ⭐ **Backup Important Data** - Always backup before major system changes
- ⭐ **Test Environment** - Try on virtual machine first if unsure

#### **Performance Optimization**
- 🚀 **SSD Storage** - Install on SSD for optimal performance
- 🚀 **RAM Allocation** - 8GB+ RAM recommended for large toolsets
- 🚀 **Clean Installs** - Remove unused tools periodically to save space
- 🚀 **Container Isolation** - Use containers for resource-intensive tools

#### **Security Best Practices**
- 🔒 **Regular Updates** - Keep both system and tools updated
- 🔒 **Audit Logs** - Regularly review `/var/log/hakpak.log`
- 🔒 **Tool Verification** - Verify tool integrity before use
- 🔒 **Network Segmentation** - Use isolated networks for testing

#### **Team Collaboration**
- 👥 **Custom Toolkits** - Create standardized toolkits for your team
- 👥 **Export/Import** - Share toolkit configurations across team members
- 👥 **Documentation** - Document custom toolkit purposes and usage
- 👥 **Version Control** - Maintain toolkit versions for consistency

#### **Learning & Development**
- 📚 **Start with Documentation** - Read tool documentation before use
- 📚 **Practice Safely** - Always test on authorized systems only
- 📚 **Legal Compliance** - Ensure all testing is authorized and legal
- 📚 **Community Resources** - Join Kali Linux and security communities

---

## 💻 **Usage Examples**

### **Desktop Application Interface**
```bash
# Launch Methods:
Double-click desktop icon           # GUI launch with authentication
Search "HakPak" in app menu        # System launcher integration  
Right-click icon → Quick Actions   # Instant tool installation
```

### **Command Line Interface**
```bash
# Interactive Operations:
hakpak                             # Launch interactive menu
hakpak --status                    # System health check
hakpak --help                      # Complete usage guide

# Direct Installation Commands:
sudo hakpak --install kali-linux-top10              # Install top tools
sudo hakpak --install kali-tools-web-application    # Web security suite
sudo hakpak --install nmap                          # Individual tool
sudo hakpak --install burpsuite                     # Professional scanner

# System Management:
hakpak --setup-repo               # Configure Kali repositories
hakpak --fix-deps                 # Resolve dependency conflicts  
hakpak --list-metapackages       # Browse available collections
hakpak --remove-repo             # Clean repository configuration
```

### **Professional Workflow Examples**
```bash
# Penetration Testing Setup:
sudo hakpak --install kali-tools-web-application
sudo hakpak --install kali-tools-vulnerability-assessment
sudo hakpak --install kali-tools-exploitation

# Digital Forensics Workstation:
sudo hakpak --install kali-tools-forensics
sudo hakpak --install kali-tools-reverse-engineering

# Wireless Security Analysis:
sudo hakpak --install kali-tools-wireless
sudo hakpak --install kali-tools-hardware
```bash
git clone https://github.com/PhanesGuild/Hakpak.git
cd Hakpak
chmod +x hakpak.sh
sudo ./hakpak.sh
```

### Manual Install
```bash
wget https://raw.githubusercontent.com/PhanesGuild/Hakpak/main/hakpak.sh
chmod +x hakpak.sh
sudo ./hakpak.sh
```

## Usage

### Command Line Options
```bash
---

## 🔐 **Security & Authentication**

### **How Authentication Works**
HakPak implements enterprise-grade authentication protocols:

1. **Desktop Launch** → Uses PolicyKit for secure GUI authentication (similar to Windows UAC)
2. **Terminal Launch** → Uses standard sudo authentication protocols
3. **Your Password** → Always uses YOUR personal system password, never hardcoded credentials
4. **Privilege Escalation** → Temporary elevation only when needed for specific operations

### **Security Features**
- ✅ **Zero Hardcoded Passwords** - No backdoors or developer access
- ✅ **Temporary Privilege Escalation** - Minimal time in elevated mode
- ✅ **Secure PolicyKit Integration** - Industry-standard authentication
- ✅ **Complete Audit Logging** - All actions logged to `/var/log/hakpak.log`
- ✅ **Package Signature Verification** - All packages cryptographically verified
- ✅ **Repository Integrity** - GPG signature validation for all sources

### **Privacy & Data Protection**
- 🔒 **No Data Collection** - HakPak does not collect or transmit user data
- 🔒 **Local Operation** - All processing happens on your local system
- 🔒 **No Phone Home** - No telemetry or analytics transmission
- 🔒 **Open Architecture** - All operations are transparent and auditable

---

## 🛠️ **Troubleshooting Guide**

### **Common Installation Issues**

#### **"Permission denied" Error**
```bash
# Ensure you're NOT running as root
whoami  # Should NOT show 'root'

# Run installer as regular user, NOT with sudo
./install.sh  # NOT: sudo ./install.sh
```

#### **Desktop Icon Not Appearing**
```bash
# Method 1: Refresh desktop environment
killall nautilus  # For GNOME/Ubuntu
kbuildsycoca5     # For KDE

# Method 2: Log out and back in
# Method 3: Restart your system
```

#### **Authentication Not Working**
```bash
# Check PolicyKit service status
systemctl status polkit

# Verify sudo access works
sudo -v

# Check if your user is in sudo group
groups $USER | grep sudo
```

#### **Package Installation Conflicts**
```bash
# Run HakPak's dependency resolver
sudo hakpak --fix-deps

# Reset and reconfigure repositories
sudo hakpak --remove-repo
sudo hakpak --setup-repo
```

#### **Application Not Found in Menu**
```bash
# Update desktop database
sudo update-desktop-database /usr/share/applications/

# Update icon cache
sudo gtk-update-icon-cache -t /usr/share/icons/hicolor/

# Refresh application menu (varies by desktop environment)
```

### **Performance Optimization**

#### **Slow Installation Speeds**
```bash
# Use closest mirror (automatic in HakPak v2.0)
# Close other applications during large installations
# Ensure stable internet connection
```

#### **High Memory Usage During Installation**
```bash
# Close unnecessary applications
# Install smaller collections first:
sudo hakpak --install kali-linux-top10  # Instead of kali-linux-everything
```

### **Advanced Diagnostics**

#### **Check HakPak Installation Status**
```bash
hakpak --status                  # Complete system status
cat /var/log/hakpak.log         # Review installation logs
dpkg -l | grep kali             # List installed Kali packages
```

#### **Verify System Integrity**
```bash
# Check for broken packages
sudo apt --fix-broken install

# Verify package signatures
apt-key list | grep -i kali

# Check repository configuration
cat /etc/apt/sources.list.d/kali.list
```

---

## 🔄 **Uninstallation Guide**

### **Complete Removal Process**
```bash
# Remove all HakPak components
sudo rm -f /usr/local/bin/hakpak
sudo rm -f /usr/local/bin/hakpak-launcher
sudo rm -f /usr/share/applications/hakpak.desktop
sudo rm -f /usr/share/polkit-1/actions/com.phanesguild.hakpak.policy

# Remove all icons
sudo rm -rf /usr/share/icons/hicolor/*/apps/hakpak.*

# Remove desktop shortcut
rm -f ~/Desktop/HakPak.desktop

# Update system caches
sudo update-desktop-database /usr/share/applications/
sudo gtk-update-icon-cache -t /usr/share/icons/hicolor/

# Optional: Remove Kali repository (run before removing HakPak)
sudo hakpak --remove-repo
```

### **Selective Removal**
```bash
# Remove only Kali tools (keep HakPak installed)
sudo hakpak --remove-repo
sudo apt autoremove

# Remove specific tool packages
sudo apt remove kali-linux-top10
sudo apt remove nmap burpsuite
```

---

## 🆘 **Getting Help & Support**

### **Built-in Help Resources**
```bash
# Comprehensive help documentation
hakpak --help

# System status and diagnostics  
hakpak --status

# View installation logs for troubleshooting
hakpak     # Option 11: View Installation Log

# Check log file directly
sudo tail -f /var/log/hakpak.log
```

### **Common Questions & Answers**

#### **Q: How do I know if HakPak is working correctly?**
```bash
# Run system status check
hakpak --status

# This shows:
# - Your distribution compatibility
# - Available disk space
# - Repository configuration
# - Installed Kali packages count
```

#### **Q: What if my desktop environment isn't recognized?**
HakPak supports all major desktop environments. If you experience issues:
1. Try logging out and back in
2. Restart your system
3. Run `hakpak --status` to check configuration

#### **Q: Can I use HakPak on a server without a desktop?**
Yes! Choose "Command Line Only" during installation:
```bash
./install.sh  # Select option 2
```

#### **Q: How do I update my installed tools?**
```bash
# Update package repositories
sudo apt update

# Upgrade installed tools
sudo apt upgrade

# For major updates, reinstall tool collections
sudo hakpak --install kali-linux-top10
```

### **Professional Support**

#### **Documentation Resources**
- 📖 **[Quick Start Guide](QUICK-START.md)** - Visual installation walkthrough
- 📖 **Built-in Help** - `hakpak --help` for complete command reference
- 📖 **System Logs** - `/var/log/hakpak.log` for detailed operation history

#### **Community & Enterprise Support**
- 🏢 **Enterprise Licensing** - Commercial support available for organizations
- 👥 **Community Forums** - Join security professionals using HakPak
- 🛠️ **Custom Development** - Specialized toolkit development services

#### **Developer Information**
- **Author:** Teyvone Wells
- **Company:** PhanesGuild Software LLC  
- **Focus:** Professional security tool integration and enterprise solutions
- **Experience:** Specialized in Debian-based security distributions and enterprise deployment

---

## 📜 **License & Legal**

### **Commercial Software License**
HakPak v2.0 is commercial software developed by PhanesGuild Software LLC. 

**Licensed Use Includes:**
- ✅ Personal and professional use on unlimited systems
- ✅ Installation of open-source Kali Linux tools
- ✅ Creation and sharing of custom toolkits
- ✅ Enterprise deployment and team collaboration
- ✅ Commercial penetration testing and security assessment

**Important Legal Notes:**
- 🔒 **Tool Usage Responsibility** - Users responsible for legal and authorized use of installed security tools
- 🔒 **Authorized Testing Only** - Security tools must only be used on systems you own or have explicit authorization to test
- 🔒 **Compliance Requirements** - Ensure compliance with local laws and regulations
- 🔒 **No Malicious Use** - Software intended for legitimate security testing and education only

### **Third-Party Components**
HakPak installs tools from the official Kali Linux repositories. Each tool maintains its individual license terms:
- **Kali Linux Tools** - Various open-source licenses (GPL, MIT, BSD, etc.)
- **Package Management** - Uses standard Debian package management systems
- **Desktop Integration** - Leverages standard Linux desktop technologies

---

## 🎯 **Ready to Get Started?**

### **Download HakPak Today**
Transform your Debian-based system into a professional security workstation with the most comprehensive Kali Linux tool installer available.

**🌟 What You Get:**
- ✅ Professional Windows-like installation experience
- ✅ Complete Kali Linux security tool arsenal  
- ✅ Advanced features like custom toolkits and offline installation
- ✅ Enterprise-grade dependency management and conflict resolution
- ✅ Professional desktop integration with authentication systems
- ✅ Comprehensive logging, monitoring, and troubleshooting tools

**📥 Download Link:** [PhanesGuild.com](https://phanesguild.com)

**💬 Questions?** Review our [Quick Start Guide](QUICK-START.md) or use `hakpak --help` after installation.

---

*HakPak v2.0 - Developed with ❤️ by Teyvone Wells @ PhanesGuild Software LLC*
*Making professional security tools accessible to everyone.*
# Keep HakPak but remove specific tools
sudo apt remove kali-linux-top10

# Keep tools but remove HakPak desktop integration only
sudo rm -f /usr/share/applications/hakpak.desktop
rm -f ~/Desktop/HakPak.desktop
```

---

## 📞 **Professional Support**

### **Documentation & Resources**
- **📖 Complete Documentation** - This README and `hakpak --help`
- **📊 Installation Logs** - Check `/var/log/hakpak.log` for detailed information
- **🌐 Official Website** - Visit [PhanesGuild.com](https://phanesguild.com) for updates and support
- **💼 Enterprise Support** - Available for commercial deployments

### **Self-Service Support**

#### **Before Contacting Support**
1. ✅ Review system requirements and compatibility
2. ✅ Check `/var/log/hakpak.log` for error details
3. ✅ Try running `sudo hakpak --fix-deps`
4. ✅ Verify internet connectivity and system updates
5. ✅ Include your distribution name and version in any support requests

#### **Diagnostic Information to Include**
```bash
# Gather system information for support requests
lsb_release -a                   # Distribution information
uname -a                        # Kernel and system architecture  
df -h                           # Disk space availability
free -h                         # Memory availability
hakpak --status                 # HakPak system status
tail -50 /var/log/hakpak.log    # Recent log entries
```

### **Enterprise & Commercial Support**
For organizations requiring dedicated support, custom deployment assistance, or enterprise licensing:

**📧 Contact:** [enterprise@phanesguild.com](mailto:enterprise@phanesguild.com)  
**🌐 Website:** [https://phanesguild.com](https://phanesguild.com)  
**🏢 Company:** PhanesGuild Software LLC

---

## 📄 **License & Legal**

### **Product License**
HakPak v2.0 is proprietary software developed by PhanesGuild Software LLC. All rights reserved.

### **Terms of Use**
- ✅ Personal and educational use permitted
- ✅ Commercial evaluation permitted
- ⚠️ Commercial deployment requires appropriate licensing
- ⚠️ Redistribution prohibited without written permission

### **Disclaimer**
This software is provided for legitimate security testing and educational purposes. Users are responsible for ensuring compliance with all applicable laws and regulations in their jurisdiction.

---

## 👨‍💻 **About the Developer**

**Teyvone Wells**  
*Founder & Lead Developer*  
**PhanesGuild Software LLC**

- 🌐 **Website:** [PhanesGuild.com](https://phanesguild.com)
- 💼 **LinkedIn:** [Teyvone Wells](https://linkedin.com/in/teyvonewells)
- 📧 **Contact:** [info@phanesguild.com](mailto:info@phanesguild.com)
- 🏢 **Company:** Specializing in cybersecurity software and professional security tools

---

## 🎯 **Get Started Today**

### **Download HakPak v2.0**
Ready to transform your system into a professional security workstation?

**🔗 [Download from PhanesGuild.com](https://phanesguild.com/hakpak)**

### **Installation Summary**
1. **📥 Download** HakPak-v2.0.zip
2. **📂 Extract** the package
3. **⚙️ Run** `./install.sh`
4. **🖥️ Launch** from desktop icon

---

**🛡️ Ready to forge your ultimate security toolkit! ⚒️**

*Transform any Debian-based system into a professional penetration testing workstation with HakPak v2.0 - The most advanced Kali tools installer available.*
- **Debian**: 11 (Bullseye), 12 (Bookworm), and newer
- **Pop!_OS**: 20.04, 22.04, and newer
- **Linux Mint**: 20, 21, and newer  
- **Parrot OS**: 4.11 and newer

## Technical Details

### Repository Configuration
Hakpak adds the Kali Rolling repository with proper pinning:

```
# Repository
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware

# Pinning Policy
Package: *
Pin: release o=Kali
Pin-Priority: 50

Package: kali-*
Pin: release o=Kali
Pin-Priority: 500
```

This ensures:
- System packages maintain priority (Pin-Priority: 500 default)
- Kali packages have low priority (Pin-Priority: 50) 
- Only explicitly requested Kali tools can be installed

### File Locations
- **Main Script**: `/usr/local/bin/hakpak` (when installed) or `./hakpak.sh`
- **Repository File**: `/etc/apt/sources.list.d/kali.list`
- **Pinning File**: `/etc/apt/preferences.d/kali.pref`
- **GPG Key**: `/etc/apt/trusted.gpg.d/kali-archive.gpg`
- **Log File**: `/var/log/hakpak.log`
- **Backup Files**: `/etc/apt/sources.list.backup.YYYYMMDD_HHMMSS`

## Safety Features

### Distribution Detection
- Automatic detection of supported distributions
- Version compatibility checking
- Architecture validation
- Graceful handling of unsupported systems

### Enhanced Error Handling
- Comprehensive input validation
- Network connectivity checks  
- Package availability verification
- Graceful failure handling with detailed error messages
- Comprehensive logging with timestamps

### System Protection
- Repository pinning prevents system corruption
- Selective package installation only from Kali
- System package integrity maintained
- Safe removal process for cleanup

## Troubleshooting

### Common Issues

**Permission Denied**
```bash
sudo chmod +x hakpak.sh
sudo ./hakpak.sh
```

**Network Issues**
- Check internet connectivity
- Verify DNS resolution
- Consider using alternative mirror

**Package Not Found**
- Update package lists: `sudo apt update`
- Verify package name spelling
- Check if package exists in Kali repository

**Repository Conflicts**
- Remove conflicting repositories
- Run repository cleanup: `sudo hakpak --remove-repo`

### Log Analysis
View detailed logs for troubleshooting:
```bash
sudo tail -f /var/log/hakpak.log
```

### Getting Help
```bash
sudo hakpak --help        # Show help information
sudo hakpak --status      # Check system status
sudo hakpak --fix-deps    # Fix dependency issues
```

## Comparison with Legacy Tools

| Feature | Katoolin | Kabuntool | Hakpak v1.0 |
|---------|----------|-----------|-------------|
| Repository Pinning | ❌ No | ✅ Yes | ✅ Enhanced |
| Multi-Distro Support | ❌ No | ❌ Ubuntu Only | ✅ 5+ Distros |
| Error Handling | ❌ Basic | ✅ Advanced | ✅ Comprehensive |
| Logging | ❌ None | ✅ Basic | ✅ Advanced |
| CLI Interface | ❌ No | ❌ No | ✅ Full CLI |
| Status Monitoring | ❌ No | ✅ Yes | ✅ Enhanced |
| Desktop Integration | ❌ No | ❌ No | ✅ Yes |
| Modular Architecture | ❌ No | ❌ No | ✅ Yes |

## Roadmap

### Upcoming Features (Pro/Premium)
- **Custom Toolkits Manager**: Create and manage custom tool collections
- **Offline Installer Mode**: Support for air-gapped environments  
- **Container Isolation Mode**: Sandboxed installations via Docker/chroot
- **Automated Updates**: Scheduled tool updates and maintenance
- **Team Management**: Multi-user configurations and profiles

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly on supported distributions
4. Submit a pull request with detailed description

## Commercial Support

For commercial licensing, enterprise support, or custom features, contact:
**PhanesGuild Software LLC**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Teyvone Wells**  
PhanesGuild Software LLC  
Email: [teyvone@phanesguild.com]  
GitHub: [@PhanesGuild](https://github.com/PhanesGuild)

## Disclaimer

This tool is for educational and authorized penetration testing purposes only. Users are responsible for compliance with all applicable laws and regulations. The authors assume no liability for misuse of this software.

---

*Forge wisely. Strike precisely.*

**Stay sharp! 🛡️**
