# HakPak3 - Website Documentation

**The Ultimate Cross-Distro Hacking Tool Installer**

---

##  Welcome to HakPak3

HakPak3 is a revolutionary security tool management system that brings the power of Kali Linux's 100+ penetration testing tools to **any Linux distribution**. Whether you're running Ubuntu, Fedora, Arch, or openSUSE, HakPak3 makes it effortless to build a complete security testing environment.

### Why HakPak3?

** Smart & Intelligent**  
HakPak3 automatically ranks tools based on compatibility with your system, showing you the best matches first. Our proprietary scoring algorithm (0-100%) ensures you always know which tools will work perfectly on your distribution.

** Dependency-Free Installation**  
Forget about dependency hell. HakPak3 automatically detects, downloads, and installs all required dependencies across Python, Ruby, Go, Java, and native packages. One command, fully working tools.

** Resource-Aware**  
Never run out of space mid-installation again. HakPak3 shows you exactly how much disk space and RAM each tool requires before you install it, with real-time system monitoring.

** Lightning Fast**  
Choose from 6 different installation methods. HakPak3 tries native packages first, then automatically falls back to building from source if needed. You get working tools, guaranteed.

---

##  Key Features

### 100+ Security Tools
Access the complete Kali Linux arsenal:
- **Information Gathering**: nmap, masscan, theharvester, maltego, shodan
- **Web Application Testing**: burpsuite, sqlmap, nikto, gobuster, wpscan  
- **Password Cracking**: john, hashcat, hydra, medusa
- **Wireless Attacks**: aircrack-ng, wifite, reaver, kismet
- **Exploitation**: metasploit-framework, beef-xss, exploitdb
- **Forensics**: autopsy, volatility, binwalk
- **Reverse Engineering**: radare2, ghidra
- And 150+ more!

### Universal Distribution Support
Works seamlessly on:
-  Ubuntu / Debian / Linux Mint
-  Fedora / RHEL / CentOS / Rocky Linux
-  Arch Linux / Manjaro
-  openSUSE / SLES
-  Kali Linux / Parrot OS
-  Any distribution with apt, dnf, pacman, or zypper

### Intelligent Categorization
- **Standard Tools**: 13 essential security tools (nmap, metasploit, burpsuite, etc.)
- **Custom Tools**: 100+ extended Kali metapackage tools
- **Installed Tools**: Real-time tracking of what's on your system

### Smart Installation
-  Automatic dependency detection
-  Native package installation
-  Source compilation when needed
-  Python virtual environments
-  Ruby bundler integration
-  Go module builds

### Real-Time Metrics
Every tool shows you:
- Installation size (tool + dependencies)
- RAM requirements
- OS compatibility score
- Current system resources available

### Advanced Installation Filters  NEW
Precisely control which tools to install:
- **Compatibility Filter**: Install only tools with X% or better compatibility
- **Size Filter**: Limit installations by total size (MB)
- **RAM Filter**: Exclude tools requiring too much RAM
- **Tag Filter**: Include/exclude tools by category (web, network, wireless, etc.)
- **Count Limit**: Install only top N best-matching tools

**Example Use Cases:**
- "Install only tools compatible with my system (50%+)"
- "Install lightweight tools for low-spec VPS"
- "Build a web-focused security toolkit"
- "Install top 10 network tools"

See [INSTALL_PARAMETERS.md](https://github.com/PhanesGuildSoftware/HakPak) for complete guide.

---

##  Download & Installation

### Option 1: Direct Download (Easiest)

**Download HakPak3.zip** from our website: [https://phanesguild.llc/hakpak3](https://phanesguild.llc/hakpak3)

```bash
# Extract the downloaded zip
unzip HakPak3.zip
cd HakPak3

# Run the installer
sudo bash install-hakpak3.sh

# Verify installation
hakpak3 --version
```

**What the installer does:**
- Installs Python dependencies (PyYAML)
- Copies files to `/opt/hakpak3`
- Creates `hakpak3` system command (you can run it from anywhere!)
- Sets up proper permissions

### Option 2: Install from GitHub

```bash
# Clone repository
git clone https://github.com/PhanesGuildSoftware/HakPak.git
cd HakPak/v3

# Install system-wide
sudo bash install-hakpak3.sh

# Verify installation
hakpak3 --version
```

### Option 3: Manual Installation (No System Command)

```bash
# Ensure Python 3.8+ and PyYAML are installed
python3 --version  # Should be 3.8 or higher
pip3 install pyyaml

# Run directly from HakPak3 directory
cd HakPak3
sudo bash hakpak3.sh

# Optional: Create system command manually
sudo ln -s $(pwd)/hakpak3.sh /usr/local/bin/hakpak3
```

### Uninstallation

```bash
# If installed via installer
cd HakPak3
sudo bash uninstall-hakpak3.sh

# This removes:
# - /opt/hakpak3 directory
# - hakpak3 system command
# - All installed files
```

### Requirements
- Linux distribution with apt, dnf, pacman, or zypper
- Python 3.8 or higher
- Root/sudo privileges for tool installation
- Internet connection for downloading tools

---

##  How to Use

### Launch HakPak3

```bash
sudo hakpak3
```

### Interactive Menu

```
══════════════════════════════════════════════════
  MAIN MENU
══════════════════════════════════════════════════
  1) List Tools
  2) Install Tools
  3) Install Tools with Filters (Advanced)  NEW
  4) Uninstall Tools
  5) Status & Installed Tools
  6) Repository Management (APT)
  7) About HakPak3
  0) Exit
══════════════════════════════════════════════════
```

### Quick Examples

**Install Top Security Tools**
```
Main Menu → 2) Install Tools → Enter: all
```
Installs all available tools matching your current filter parameters. For a curated subset, use `best20` (top 20 most compatible) or `top5` (top 5 best) options instead.

**Install Only High-Compatibility Tools (50%+)**  NEW
```
Main Menu → 3) Install Tools with Filters
  Minimum compatibility %: 50
  [Press Enter to skip other filters]
  Enter: all
```
Installs only tools with 50% or better compatibility for your system.

**Install Small Tools (Under 100MB)**  NEW
```
Main Menu → 3) Install Tools with Filters
  Maximum size in MB: 100
  Enter: all
```
Perfect for systems with limited disk space.

**Install Web Security Toolkit**  NEW
```
Main Menu → 3) Install Tools with Filters
  Minimum compatibility %: 60
  Include tags: web,http,webapp
  Enter: all
```
Builds a focused web application security toolkit.

**Search for Web Testing Tools**
```
Main Menu → 1) List Tools → 5) Search → Enter: web
Main Menu → 2) Install Tools → Enter: burpsuite sqlmap nikto
```

**Check What's Installed**
```
Main Menu → 5) Status & Installed Tools
```

**Install Wireless Tools**
```
Main Menu → 2) Install Tools → Enter: aircrack-ng wifite reaver
```

---

##  Tool Categories

### Information Gathering (40+ Tools)

**Network Scanning**
- nmap - Network exploration and security auditing
- masscan - Fast TCP port scanner
- unicornscan - Distributed TCP/IP stack scanner

**DNS Enumeration**
- dnsenum, dnsrecon, fierce - DNS reconnaissance
- dnsmap, dnswalk - DNS mapping and debugging

**OSINT (Open Source Intelligence)**
- theharvester - Email and subdomain harvester
- maltego - Intelligence and forensics application
- recon-ng - Web reconnaissance framework
- shodan - Search engine for Internet-connected devices
- spiderfoot - OSINT automation tool

**Discovery**
- dmitry - Information gathering tool
- netdiscover - ARP reconnaissance tool

### Vulnerability Analysis (20+ Tools)

- nikto - Web server scanner
- openvas - Comprehensive vulnerability scanner
- lynis - Security auditing tool
- yersinia - Layer 2 attack framework
- unix-privesc-check - Privilege escalation checker

### Web Application (30+ Tools)

**Proxies & Interceptors**
- burpsuite - Leading web vulnerability scanner
- zaproxy - OWASP ZAP security scanner

**SQL Injection**
- sqlmap - Automatic SQL injection tool
- commix - Command injection exploiter

**Scanners & Fuzzers**
- nikto - Web server scanner
- wpscan - WordPress security scanner
- skipfish - Active web application scanner
- gobuster - Directory/file & DNS busting
- ffuf - Fast web fuzzer
- wfuzz - Web application fuzzer
- dirb, dirbuster - Directory brute forcing

### Password Attacks (15+ Tools)

**Hash Cracking**
- john - John the Ripper password cracker
- hashcat - Advanced password recovery
- ophcrack - Windows password cracker

**Network Login Attacks**
- hydra - Network logon cracker
- medusa - Speedy parallel login bruter
- ncrack - High-speed authentication cracker

**Wordlist Generation**
- crunch - Wordlist generator
- cewl - Custom wordlist generator

### Wireless Attacks (15+ Tools)

**WiFi Cracking**
- aircrack-ng - WiFi security auditing suite
- wifite - Automated wireless attack tool
- kismet - Wireless network detector

**WPS Attacks**
- reaver - WPS brute force tool
- bully - WPS brute force attack
- pixiewps - Offline WPS brute force

**GUI Tools**
- fern-wifi-cracker - Wireless security auditing (GUI)

### Exploitation (15+ Tools)

- metasploit-framework - Penetration testing framework
- beef-xss - Browser Exploitation Framework
- armitage - GUI for Metasploit
- exploitdb - Exploit database (searchsploit)
- social-engineer-toolkit - Social engineering framework

### Sniffing & Spoofing (15+ Tools)

**Network Analysis**
- wireshark - Network protocol analyzer (GUI)
- tcpdump - Command-line packet analyzer
- ettercap - Man-in-the-middle attack tool

**Advanced MITM**
- bettercap - Swiss army knife for network attacks
- mitmproxy - Interactive HTTPS proxy
- responder - LLMNR, NBT-NS poisoner

**Classic Tools**
- dsniff - Collection of network auditing tools

### Post Exploitation
- powersploit - PowerShell post-exploitation
- mimikatz - Windows credential extraction
- weevely - Weaponized web shell

### Forensics
- autopsy - Digital forensics platform
- volatility - Memory forensics framework
- binwalk - Firmware analysis tool
- bulk-extractor - Fast file carving

### Reverse Engineering
- radare2 - Reverse engineering framework
- ghidra - Software reverse engineering suite
- edb-debugger - Cross-platform debugger
- ollydbg - Windows debugger (via Wine)

### Network Utilities
- netcat, socat - Network Swiss army knives
- tor - Anonymity network
- proxychains - Redirect through proxy servers

---

##  Compatibility Scoring

HakPak3 uses an intelligent algorithm to score each tool's compatibility with your system:

### Score Breakdown
- **Package Manager Match** (40 points)
  - Native package available: +40
  - Source build available: +20

- **OS Optimization** (30 points)
  - Kali/Parrot (security distros): +30
  - Ubuntu/Debian: +25
  - Fedora/RHEL: +25
  - Arch/Manjaro: +25

- **Resource Availability** (30 points)
  - RAM availability: up to +15
  - Disk space: up to +15

### Score Interpretation
-  **80-100%**: Perfect match - Install recommended
-  **60-79%**: Good match - May require source build
-  **<60%**: Limited compatibility - May have issues

Tools are automatically sorted with best matches first!

---

##  Usage Tips

### Batch Installation
Install multiple tools at once:
```
burpsuite sqlmap nikto gobuster wpscan
```
Separate with spaces or commas.

### Search by Tags
Tools are tagged by category:
- Search: "wireless" → All wireless tools
- Search: "web" → Web testing tools
- Search: "password" → Password cracking tools

### Resource Planning
Before installing large tools like Metasploit or Ghidra:
1. Check the size estimate
2. Verify RAM requirements
3. Ensure enough disk space

HakPak3 will warn you if resources are insufficient!

### Install Top Tools
Type `all` in the install menu to install ALL available tools matching your filter parameters. For a smaller curated set, use `best20` (top 20) or `top5` (top 5) instead.

---

##  Security & Legal

###  Legal Disclaimer

**IMPORTANT**: These tools are for authorized security testing only!

-  Use only on systems you own
-  Obtain written permission before testing
-  Comply with local laws and regulations
-  Unauthorized access is illegal
-  You accept full responsibility for your actions

HakPak3 developers are not liable for misuse of these tools.

### Ethical Use Guidelines

1. **Authorization First**: Always get written permission
2. **Know the Law**: Understand legal requirements in your jurisdiction
3. **Use Responsibly**: These are powerful tools for professionals
4. **Learn Safely**: Practice in isolated lab environments
5. **Document Everything**: Keep records of authorized testing

### Recommended For
- Security professionals
- Penetration testers
- Bug bounty hunters
- Security researchers
- Students in authorized labs
- System administrators

---

##  System Requirements

### Minimum Requirements
- **OS**: Any Linux distribution
- **CPU**: 1+ cores (2+ recommended)
- **RAM**: 2GB (4GB+ recommended)
- **Disk**: 10GB free space (50GB+ for full suite)
- **Python**: 3.8 or higher
- **Network**: Internet connection

### Recommended Specifications
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Disk**: 100GB+ SSD
- **OS**: Recent LTS version of your distribution

### Tested Distributions
- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- Fedora 38, 39, 40
- RHEL 8, 9
- Arch Linux (rolling)
- Manjaro (rolling)
- openSUSE Leap, Tumbleweed
- Kali Linux 2023+

---

##  Getting Started Guide

### For Beginners

**Step 1: Install Core Tools**
```bash
sudo hakpak3
# Select: 2) Install Tools
# Enter: nmap netcat hydra john wireshark
```

**Step 2: Learn the Basics**
Each tool has built-in help:
```bash
nmap --help
hydra -h
john --help
```

**Step 3: Practice Safely**
Set up a local lab environment before testing on networks.

### For Intermediate Users

**Install Web Testing Suite**
```bash
# Enter: burpsuite sqlmap nikto gobuster wpscan ffuf
```

**Add Wireless Tools**
```bash
# Enter: aircrack-ng wifite reaver kismet
```

### For Advanced Users

**Install Full Arsenal**
```bash
# Select: 2) Install Tools
# Enter: all
# Then install additional tools as needed
```

**Customize Your Setup**
- Use search to find specific tools
- Install tools by category
- Build comprehensive testing environment

---

## 🆘 Support & Troubleshooting

### Common Issues

**"PyYAML is required"**
```bash
pip3 install pyyaml
# or
sudo apt install python3-yaml
```

**"No supported package manager found"**
Ensure your distribution uses apt, dnf, pacman, or zypper.

**"Insufficient disk space"**
Free up space or install fewer tools at once.

**Tool not found after installation**
```bash
# Reload your shell
hash -r
source ~/.bashrc
```

### Getting Help

**Documentation**
- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [FAQ](#faq) - Frequently asked questions

**Contact Support**
- Email: owner@phanesguild.llc
- GitHub Issues: [Report a bug](https://github.com/PhanesGuildSoftware/HakPak/issues)

**Community**
- Check GitHub discussions
- Review existing issues
- Contribute improvements

---

##  FAQ

**Q: Can I use HakPak3 on non-Kali distributions?**  
A: Yes! That's the whole point. HakPak3 brings Kali tools to any Linux distribution.

**Q: Do I need root privileges?**  
A: Yes, installing system packages requires root/sudo access.

**Q: Will this work on [my distribution]?**  
A: If your distro uses apt, dnf, pacman, or zypper, yes!

**Q: How much disk space do I need?**  
A: Varies by tools. Individual tools: 1-500MB. Full suite: 50GB+. HakPak3 shows you before installing.

**Q: Can I uninstall tools?**  
A: Yes, use the uninstall menu option.

**Q: Is this legal?**  
A: The tools are legal. Using them without authorization is not. Always get permission.

**Q: How is this different from apt-get install?**  
A: HakPak3 handles dependencies automatically, works across distributions, ranks by compatibility, and provides 100+ pre-configured tools.

**Q: Can I use this offline?**  
A: No, HakPak3 requires internet to download tools and dependencies.

**Q: Does this work on WSL (Windows Subsystem for Linux)?**  
A: Some tools work, others require native Linux. Network tools may have limitations.

**Q: How do I update tools?**  
A: Re-run the installation for updated tools. Future versions will have update management.

---

##  Version Information

**Current Version**: 3.0.0  
**Release Date**: January 2026  
**Status**: Production Ready

### What's New in v3.0

 **100+ Tools** - 2.5x increase from HakPak2  
 **Smart Compatibility** - 0-100% OS scoring  
 **Resource Metrics** - Real-time disk/RAM monitoring  
 **Enhanced Menus** - Interactive search and categorization  
 **6 Install Methods** - Native, Go, Python, Ruby, Git, Pip  
 **Complete Docs** - Comprehensive user guides  

### Roadmap

**v3.1 (Q2 2026)**
- Enhanced uninstall functionality
- Tool update checker
- Configuration file support

**v3.2+ (Future)**
- Web-based GUI
- Docker container support
- Ansible playbook export
- Tool usage documentation

---

##  Contributing

We welcome contributions!

### How to Contribute
1. Fork the repository
2. Add new tools to `kali-tools-db.yaml`
3. Improve compatibility scoring
4. Enhance documentation
5. Report bugs
6. Submit pull requests

### Adding New Tools
Tools require:
- Binary name
- Description
- Package mappings (apt/dnf/pacman/zypper)
- Size estimates
- Resource requirements
- Tags/categories

See existing tools in `kali-tools-db.yaml` for examples.

---

##  Contact & Support

### Developer Information
**Name**: Teyvone Wells  
**Company**: PhanesGuild Software LLC  
**Email**: owner@phanesguild.llc  
**GitHub**: https://github.com/PhanesGuildSoftware

### Project Links
- **Repository**: https://github.com/PhanesGuildSoftware/HakPak
- **Issues**: https://github.com/PhanesGuildSoftware/HakPak/issues
- **Website**: https://phanesguild.llc

### Business Inquiries
For enterprise support, custom installations, or business partnerships:  
 owner@phanesguild.llc

---

##  License

HakPak3 is open-source software. See [LICENSE](../LICENSE) for full terms.

**The security tools themselves are licensed individually by their respective authors.**

---

##  Acknowledgments

### Special Thanks
- **Kali Linux Team** - For maintaining the comprehensive security tool ecosystem
- **Offensive Security** - For exploit-db and tool curation
- **Security Community** - For developing these essential tools
- **Open Source Contributors** - For making security testing accessible

### Powered By
- Python 3.8+
- PyYAML
- Linux ecosystem
- Open source security tools

---

##  Download & Get Started

Ready to transform your Linux distribution into a security testing powerhouse?

### Quick Start
```bash
git clone https://github.com/PhanesGuildSoftware/HakPak.git
cd HakPak/v3
sudo bash install-hakpak3.sh
sudo hakpak3
```

### Stay Updated
-  Star the project on GitHub
-  Watch for new releases
-  Subscribe to updates

---

<div align="center">

**HakPak3 v3.0.0**

*The Ultimate Cross-Distro Hacking Tool Installer*

**Developed by PhanesGuild Software LLC**

[Download](https://github.com/PhanesGuildSoftware/HakPak) • [Documentation](README.md) • [Support](mailto:owner@phanesguild.llc)

---

 **For Authorized Security Testing Only** 

</div>
