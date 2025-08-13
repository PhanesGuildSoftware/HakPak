# ⚡ HakPak — Security Tools, Supercharged.

**One Command. Every Tool You Need.**  
HakPak is the ultimate Linux security toolkit installer — built for professionals, pentesters, and sysadmins who value speed, precision, and stability.  
No more hunting for packages, battling broken dependencies, or wasting time on setup.  
HakPak delivers **a curated, fully-vetted security arse### Professional Support
- 🌐 **Website**: [phanesguild.llc](https://www.phanesguild.llc)
- 📧 **Email**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- 💬 **Discord**: PhanesGuildSoftware
- 🐙 **GitHub**: [PhanesGuildSoftware](https://github.com/PhanesGuildSoftware)
- 💼 **Enterprise**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

### Author
**Teyvone Wells**  
*PhanesGuild Software LLC*  
🐙 [GitHub Organization](https://github.com/PhanesGuildSoftware)minutes — so you can focus on the mission, not the prep work.

---

## 🌟 Why HakPak?
- **Corporate-Ready** — Stable, signed releases with enterprise-level reliability.
- **Blazing Fast Setup** — Installs dozens of tools in a fraction of the time.
- **No Bloat** — Every included tool is vetted for relevance and security.
- **One-Time License** — No subscriptions, no surprises.
- **Privacy First** — Offline-friendly activation, zero telemetry.

---

> **HakPak Pro** gives you the full arsenal.  
> **HakPak Community** keeps you mission-capable for free.

<div align="center">

![HakPak Logo](https://img.shields.io/badge/HakPak-v1.0-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
[![GitHub](https://img.shields.io/badge/GitHub-PhanesGuildSoftware-black?style=for-the-badge&logo=github)](https://github.com/PhanesGuildSoftware)

[🚀 Quick Start](#quick-start) • [📖 Documentation](#documentation) • [🛠️ Tools](#included-tools) • [💼 Enterprise](#enterprise-support) • [🔒 Legal](#legal-disclaimer)

</div>

---

## ⚠️ **IMPORTANT LEGAL DISCLAIMER**

**READ CAREFULLY BEFORE PROCEEDING**

HakPak installs penetration testing and security assessment tools. By using this software, you acknowledge and agree that:

- ✅ **You have explicit authorization** to test the systems you intend to scan
- ✅ **You will only use these tools** on systems you own or have written permission to test
- ✅ **You understand** that unauthorized scanning/testing may violate local, state, and federal laws
- ✅ **You accept full responsibility** for your actions and any consequences thereof

**PhanesGuild Software LLC and the author(s) disclaim all liability for misuse of these tools.**

---

## 🎯 What is HakPak?

HakPak is a professional-grade security toolkit installer that brings essential Kali Linux penetration testing tools to Ubuntu and Debian-based systems. Unlike other installers, HakPak emphasizes:

- **🏢 Corporate-ready**: Stable, tested configurations for professional environments
- **🔧 Curated selection**: 15+ essential tools, carefully selected and tested
- **⚡ Smart installation**: Intelligent dependency resolution and conflict prevention
- **📊 Enterprise features**: Logging, status reporting, and modular installation options

### Why Choose HakPak Over Alternatives?

| Feature | HakPak | Katoolin | Others |
|---------|--------|----------|--------|
| Ubuntu 24.04 Support | ✅ | ❌ | ⚠️ |
| Dependency Management | ✅ Advanced | ⚠️ Basic | ❌ |
| Corporate Stability | ✅ | ❌ | ❌ |
| Professional Support | ✅ | ❌ | ❌ |
| Modular Installation | ✅ | ❌ | ⚠️ |

---

## 🚀 Quick Start

### Prerequisites

- Ubuntu 24.04 LTS (Primary) or Debian 11+ (Supported)
- Root/sudo privileges
- Internet connection
- 5GB+ available disk space

### Simple Installation

**Step 1:** Download and extract HakPak
```bash
# Option A: Download release package
wget https://releases.phanesguild.llc/hakpak-v1.0.zip
unzip hakpak-v1.0.zip
cd hakpak/

# Option B: Clone from GitHub
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak/
```

**Step 2:** Install HakPak to system
```bash
sudo ./hakpak.sh --install
```

**Step 3:** Activate your license
```bash
sudo hakpak --activate YOUR_LICENSE_KEY
```

**Step 4:** Start using HakPak
```bash
sudo hakpak              # Interactive menu
sudo hakpak --gui        # Graphical interface
```

### Legacy Installation (Alternative)

```bash
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak
sudo ./bin/install.sh    # System installation
./bin/install-desktop.sh # Desktop integration
```

### Quick Tool Installation

```bash
# Install specific tools
sudo hakpak --install-tool nmap
sudo hakpak --install-tool sqlmap

# Interactive menu
sudo hakpak

# Show status
sudo hakpak --status
```

### 🚀 Upgrade to HakPak Pro

Unlock enterprise-grade security features with HakPak Pro:

```bash
# Access Pro analytics dashboard
sudo hakpak --pro-dashboard

# Install enterprise security suite
sudo hakpak --install-pro-suite

# Check license status
sudo hakpak --enterprise-status
```

> **💡 Need a license?** Contact [owner@phanesguild.llc](mailto:owner@phanesguild.llc), Discord: PhanesGuildSoftware, or visit [phanesguild.llc/hakpak](https://phanesguild.llc/hakpak)

---

## 📖 Documentation

### Usage Examples

```bash
# Show help
sudo hakpak --help

# System status and installed packages
sudo hakpak --status

# Setup Kali repository only
sudo hakpak --setup-repo

# Install specific tool
sudo hakpak --install-tool hydra

# Fix dependency issues
sudo hakpak --fix-deps

# List all available tools
sudo hakpak --list-metapackages

# Remove Kali repository
sudo hakpak --remove-repo
```

### Command Reference

| Command | Description |
|---------|-------------|
| `--install` | Install HakPak to system (run from download folder) |
| `--help` | Show comprehensive help |
| `--version` | Display version information |
| `--status` | Show system and package status |
| `--setup-repo` | Configure Kali repository only |
| `--remove-repo` | Remove Kali repository and preferences |
| `--install-tool TOOL` | Install specific tool or metapackage |
| `--fix-deps` | Resolve dependency conflicts |
| `--list-metapackages` | Show available Kali packages |
| `--interactive` | Launch interactive menu (default) |

---

## 🛠️ Included Tools

### Network Analysis & Scanning
- **Nmap** - Advanced network discovery and security auditing
- **Wireshark** - Network protocol analyzer with GUI
- **Tcpdump** - Command-line packet analyzer
- **Netcat** - Swiss Army knife for TCP/IP

### Web Application Testing
- **SQLMap** - Automatic SQL injection and database takeover
- **Nikto** - Web server scanner for vulnerabilities
- **Dirb** - Web content scanner (directory brute forcer)
- **Gobuster** - Fast directory/file brute forcer
- **WFUZZ** - Web application fuzzer
- **FFUF** - Fast web fuzzer written in Go

### Password & Authentication
- **Hydra** - Parallelized login cracker
- **John the Ripper** - Fast password cracker
- **Hashcat** - Advanced password recovery

### Exploitation & Research
- **ExploitDB** - Archive of public exploits and vulnerabilities
- **Searchsploit** - Command-line search tool for Exploit-DB

### Enterprise Add-ons (Available)
- **Burp Suite Professional** - Advanced web application security testing
- **Metasploit Framework** - Penetration testing platform
- **OWASP ZAP** - Web application security scanner
- **Maltego** - Link analysis and data mining
- **Recon-ng** - Web reconnaissance framework

---

## 🖥️ Screenshots

### Interactive Menu
```
╔══════════════════════════════════════════════════════════════╗
║                        HAKPAK v1.0                          ║
║            Universal Kali Tools Installer                   ║
║              Forge Wisely. Strike Precisely.                ║
╚══════════════════════════════════════════════════════════════╝

[i] Detected: Ubuntu 24.04 (amd64)

Select an option:
1) Install Essential Security Tools
2) Install Individual Tools
3) Show System Status
4) Configure Repository Only
5) Remove Kali Repository
6) Fix Dependencies
7) Exit

Your choice [1-7]:
```

### Status Report
```
╔══════════════════════════════════════════════════════════════╗
║                    SYSTEM STATUS REPORT                     ║
╚══════════════════════════════════════════════════════════════╝

System Information:
├── OS: Ubuntu 24.04 LTS
├── Architecture: amd64
├── Kernel: 6.8.0-45-generic
└── Available Space: 15.2 GB

Repository Status:
├── Kali Repository: ✓ Configured
├── GPG Key: ✓ Verified
└── Package Cache: ✓ Updated

Installed Security Tools: (8/15)
├── ✓ nmap (7.94)
├── ✓ sqlmap (1.7.11)
├── ✓ nikto (2.5.0)
├── ✓ hydra (9.5)
└── ✗ gobuster (not installed)
```

---

## 🔧 System Requirements

### Minimum Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+
- **RAM**: 2GB (4GB recommended)
- **Storage**: 5GB free space
- **Network**: Broadband internet connection

### Recommended Specifications
- **OS**: Ubuntu 24.04 LTS
- **RAM**: 8GB+
- **Storage**: 20GB+ free space
- **CPU**: Multi-core processor for optimal performance

### Supported Distributions

| Distribution | Version | Status |
|--------------|---------|--------|
| Ubuntu | 24.04 LTS | ✅ Fully Tested |
| Ubuntu | 22.04 LTS | ✅ Supported |
| Ubuntu | 20.04 LTS | ✅ Supported |
| Debian | 12 (Bookworm) | ✅ Supported |
| Debian | 11 (Bullseye) | ✅ Supported |
| Pop!_OS | 22.04+ | ✅ Supported |
| Linux Mint | 21+ | ✅ Supported |
| Parrot OS | 5.0+ | ✅ Supported |

---

## �️ HakPak Editions & Pricing

## 💰 Pricing

🔑 **HakPak** - $49.99 (License Required)
- 15+ essential security tools
- Advanced tool collections  
- Extended Kali metapackages
- System overview dashboard
- Priority email support (24-48hr)
- Commercial use license
- Multi-machine deployment rights

⚠️ **License Required**: HakPak requires a valid license for all operations. No free tier available.

---

### 🔑 How Licensing Works

HakPak uses an **offline-friendly license key system** to prevent unauthorized use while keeping privacy in mind.

1. After purchasing HakPak, you will receive:
   - Your **unique license key**
   - Instructions for offline activation

2. To activate, run:

   ```bash
   sudo hakpak --activate <your-license-key>
   ```

3. **License Features**:
   - ✅ **Offline validation** - No internet required after activation
   - ✅ **Privacy focused** - No telemetry or phone-home
   - ✅ **RSA 4096-bit signatures** - Military-grade security

Contact: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

---

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak
./dev-setup.sh
```

### Reporting Issues

- 🐛 **Bug Reports**: Use GitHub Issues with the bug template
- 💡 **Feature Requests**: Submit enhancement proposals
- 🔒 **Security Issues**: Email owner@phanesguild.llc

---

## 📝 Changelog

### v1.0 (Current)
- Initial release with 15 essential security tools
- Ubuntu 24.04 LTS support
- Intelligent dependency resolution
- Professional logging and status reporting

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

---

## 🔒 Legal Disclaimer

### Terms of Use

By downloading, installing, or using HakPak, you agree to the following terms:

1. **Authorized Use Only**: You may only use these tools on systems you own or have explicit written authorization to test.

2. **Legal Compliance**: You are responsible for compliance with all applicable local, state, federal, and international laws.

3. **No Malicious Intent**: These tools are intended for legitimate security testing, research, and educational purposes only.

4. **Liability Limitation**: PhanesGuild Software LLC and contributors are not liable for any damages, legal issues, or consequences resulting from the use or misuse of this software.

5. **Professional Responsibility**: If using in a professional capacity, ensure proper documentation, authorization, and adherence to industry standards.

### Ethical Guidelines

- Always obtain proper authorization before testing
- Respect privacy and confidentiality
- Follow responsible disclosure practices
- Use tools defensively to improve security
- Document all testing activities appropriately

---

## 📞 Support & Contact

### Community Support
- 📖 **Documentation**: [Wiki](https://github.com/PhanesGuildSoftware/hakpak/wiki)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/PhanesGuildSoftware/hakpak/discussions)
- 🐛 **Issues**: [GitHub Issues](https://github.com/PhanesGuildSoftware/hakpak/issues)

### Professional Support
- 🌐 **Website**: [phanesguild.llc](https://www.phanesguild.llc)
- 📧 **Email**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- � **Discord**: PhanesGuildSoftware
- �💼 **Enterprise**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

### Author
**Teyvone Wells**  
*PhanesGuild Software LLC*  

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright © 2025 PhanesGuild Software LLC**

---

<div align="center">

**Made with ❤️ by PhanesGuild Software LLC**

*Empowering cybersecurity professionals with enterprise-grade tools*

[⭐ Star this repository](https://github.com/PhanesGuildSoftware/hakpak) if HakPak helps you!

</div>
