# 🛡️ HakPak v2.0 - Universal Kali Tools Installer

**Transform Any Debian-Based System into a Professional Security Workstation**

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://phanesguild.com)
[![Platform](https://img.shields.io/badge/platform-debian--based-brightgreen.svg)](https://github.com/PhanesGuildSoftware/hakpak)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

HakPak is a comprehensive installer that brings the full power of Kali Linux security tools to any Debian-based system. Whether you're running Ubuntu, Pop!_OS, Linux Mint, or pure Debian, HakPak makes professional penetration testing tools accessible with a single command.

## 🚀 Quick Start

```bash
# Download and install
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak
chmod +x install.sh hakpak.sh

# Install HakPak
./install.sh --desktop    # Full install with desktop integration
# OR
./install.sh --system     # Command-line only

# Run HakPak
hakpak
```

## 📋 Features

- **🎯 Complete Tool Suite**: Access to 600+ professional security tools
- **🔧 Interactive Menu**: User-friendly interface for all skill levels  
- **⚡ Quick Setup**: One-command installation and configuration
- **🔄 Smart Management**: Automatic dependency resolution and updates
- **🛡️ Safe Installation**: Non-destructive, easily removable
- **📱 Multi-Platform**: Works on Ubuntu, Debian, Pop!_OS, Linux Mint, Parrot OS

## 🖥️ Supported Systems

- **Ubuntu** (18.04+)
- **Debian** (10+)  
- **Pop!_OS** (20.04+)
- **Linux Mint** (19+)
- **Parrot OS** (4.0+)

## 📚 Usage

### Installation Options
```bash
./install.sh                 # Interactive installation
./install.sh --desktop       # Full install with desktop integration
./install.sh --system        # System-wide command-line only
./install.sh --quick         # Quick install with defaults
./install.sh --check         # Check installation status
```

### Using HakPak
```bash
hakpak                       # Launch interactive menu
hakpak --help               # Show help and options
```

### Uninstallation
```bash
./uninstall.sh              # Interactive removal
./uninstall.sh --force      # Force removal without prompts
```

## 🛠️ What Gets Installed

HakPak provides organized access to:

- **Information Gathering**: nmap, masscan, dmitry, theharvester
- **Vulnerability Analysis**: openvas, nikto, sqlmap, wpscan  
- **Web Applications**: burpsuite, owasp-zap, gobuster, dirb
- **Database Assessment**: sqlmap, sqlninja, bbqsql
- **Password Attacks**: hashcat, john, hydra, medusa
- **Wireless Attacks**: aircrack-ng, reaver, wifite, kismet
- **Reverse Engineering**: radare2, ghidra, binwalk, strings
- **Exploitation Tools**: metasploit, armitage, beef-xss
- **Forensics**: autopsy, volatility, foremost, binwalk
- **Social Engineering**: setoolkit, maltego

## 🔧 System Requirements

- **OS**: Debian-based Linux distribution
- **RAM**: 2GB minimum (4GB+ recommended)
- **Storage**: 2GB free space (8GB+ for full toolset)
- **Network**: Internet connection for downloads
- **Privileges**: sudo access required

## 📖 Documentation

After installation, HakPak provides:
- Interactive help system (`hakpak --help`)
- Tool descriptions and usage examples
- Automatic dependency management
- Installation logs and status checking

## 🤝 Contributing

We welcome contributions! Please feel free to:
- Report bugs and issues
- Suggest new features or tools
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Teyvone Wells @ PhanesGuild Software LLC**
- Website: [phanesguild.com](https://phanesguild.com)
- GitHub: [@PhanesGuildSoftware](https://github.com/PhanesGuildSoftware)

## ⚖️ Legal Notice

HakPak is intended for authorized security testing and educational purposes only. Users are responsible for complying with all applicable laws and regulations. The authors assume no liability for misuse of this software.

---

**🛡️ Forge Wisely. Strike Precisely.**
