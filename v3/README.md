# HakPak3 - Ultimate Cross-Distro Hacking Tool Installer

**Version 3.0.0**  
*The next generation of cross-distribution penetration testing tool management*

---

##  What's New in HakPak3

HakPak3 represents a major evolution from HakPak2, transforming from a simple tool installer into the **ultimate hacking tool installer and dependency handler** for any Linux distribution.

### Key Features

####  **Smart Tool Management**
- **100+ Kali Linux Tools** - Full access to Kali's comprehensive security toolset
- **Intelligent Categorization**
  - **Standard Tools**: Core HakPak security tools (nmap, metasploit, burpsuite, etc.)
  - **Custom Tools**: Extended Kali Linux metapackage tools
  - **Installed Tools**: Track what's currently on your system

####  **Advanced Dependency Resolution**
- Automatic dependency detection and installation
- Cross-distribution package mapping
- Source compilation fallback when packages unavailable
- Handles Python, Ruby, Go, Java, and native dependencies

####  **Resource Metrics & Monitoring**
- **Real-time system detection**
  - OS and distribution identification
  - CPU architecture and core count
  - Available RAM and disk space
  - Package manager detection
  
- **Per-tool resource requirements**
  - Estimated installation size
  - Dependency size calculations
  - Required RAM for operation
  - Disk space warnings

####  **OS Compatibility Scoring**
- Each tool rated 0-100% compatibility for your system
- Best-matched tools displayed first
- Package manager availability weighted
- Resource requirements factored in

#### � **Advanced Installation Filtering**  NEW
- Filter by minimum compatibility percentage
- Limit by size and RAM requirements
- Include/exclude tools by tags
- Set maximum installation count
- **Example**: Install only tools with 50%+ compatibility
- See [INSTALL_PARAMETERS.md](INSTALL_PARAMETERS.md) for full details

#### � **Multiple Installation Methods**
- **Native packages** (apt, dnf, pacman, zypper)
- **Go modules** (automated build and install)
- **Python projects** (venv isolation with pip)
- **Ruby gems** (bundler integration)
- **Git repositories** (clone, build, link)

---

##  System Requirements

- **OS**: Any Linux distribution with:
  - `apt` (Debian/Ubuntu/Kali)
  - `dnf`/`yum` (Fedora/RHEL/CentOS)
  - `pacman` (Arch/Manjaro)
  - `zypper` (openSUSE)
  
- **Python**: 3.8 or higher
- **Dependencies**: PyYAML (auto-installed)
- **Privileges**: Root/sudo for tool installation
- **Disk Space**: Varies by tools (1GB-50GB+ for full suite)

---

##  Installation

### Quick Install (Recommended)

```bash
cd v3
sudo bash install-hakpak3.sh
```

**What happens during installation:**
- Installs Python dependencies (PyYAML)
- Copies HakPak3 files to `/opt/hakpak3`
- Creates `hakpak3` system command (symlinked to `/usr/local/bin`)
- Sets up proper permissions

After installation, you can run `hakpak3` from anywhere!

### Manual Installation

```bash
# Clone repository
git clone https://github.com/PhanesGuildSoftware/HakPak.git
cd HakPak/v3

# Install dependencies
pip3 install pyyaml

# Run directly (from project directory)
sudo python3 hakpak3_core.py

# Or use launcher script
sudo bash hakpak3.sh

# Optional: Create system command manually
sudo ln -s $(pwd)/hakpak3.sh /usr/local/bin/hakpak3
```

**Note:** Manual installation won't auto-create the system command unless you run the last step.

### Verify Installation

```bash
hakpak3 --version
```

### Uninstallation

```bash
cd v3
sudo bash uninstall-hakpak3.sh
```

**What happens during uninstall:**
- Removes `/opt/hakpak3` directory
- Removes `hakpak3` command from `/usr/local/bin`
- Cleans up all installed files and symlinks

---

##  Usage

### Launch HakPak3

```bash
sudo hakpak3
```

### Main Menu Options

1. **List Tools** - Browse available tools by category
   - Installed Tools
   - Standard Tools (HakPak core set)
   - Custom Tools (Extended Kali)
   - All Available Tools
   - Search by name/tag

2. **Install Tools** - Install security tools
   - Smart ranking by OS compatibility
   - Top 20 recommended tools shown first
   - Options: 'all' (ALL tools), 'best20' (top 20), 'top5' (top 5)
   - Batch installation support
   - Resource checks before install

3. **Install Tools with Filters (Advanced)** - Filtered installations  NEW
   - Filter by compatibility score (e.g., only 50%+ compatible tools)
   - Filter by size and RAM requirements
   - Filter by tool tags (include/exclude)
   - Limit number of tools to install
   - See [INSTALL_PARAMETERS.md](INSTALL_PARAMETERS.md) for details

4. **Uninstall Tools** - Remove installed tools

4. **Uninstall Tools** - Remove installed tools

5. **Status** - View installed tools and metrics

6. **Repository Management** - Manage apt repositories

7. **About** - Developer info and legal disclaimer

---

##  Tool Categories

### Information Gathering (40+ tools)
- nmap, masscan, unicornscan
- dnsenum, dnsrecon, fierce
- theharvester, recon-ng, maltego
- shodan, spiderfoot

### Vulnerability Analysis (20+ tools)
- nikto, openvas, lynis
- yersinia, unix-privesc-check

### Web Application (30+ tools)
- burpsuite, sqlmap, wpscan
- dirb, gobuster, ffuf
- wfuzz, skipfish, zaproxy
- commix

### Password Attacks (15+ tools)
- john, hashcat, hydra
- medusa, ncrack, ophcrack
- crunch, cewl

### Wireless Attacks (15+ tools)
- aircrack-ng, reaver, bully
- wifite, kismet, pixiewps
- fern-wifi-cracker

### Exploitation (15+ tools)
- metasploit-framework, beef-xss
- armitage, exploitdb
- social-engineer-toolkit

### Sniffing & Spoofing (15+ tools)
- wireshark, tcpdump, ettercap
- bettercap, dsniff, mitmproxy
- responder

### Post Exploitation
- powersploit, mimikatz, weevely

### Forensics
- autopsy, binwalk, bulk-extractor
- volatility

### Reverse Engineering
- radare2, ghidra, ollydbg
- edb-debugger

### Additional Utilities
- netcat, socat, proxychains, tor

---

##  Example Workflows

### Install Top Security Tools

```bash
sudo hakpak3
# Select: 2) Install Tools
# Enter: all       (installs ALL available tools)
# Or: best20       (installs top 20 most compatible)
# Or: top5         (installs top 5 best)
```

### Install Only High-Compatibility Tools (50%+)  NEW

```bash
sudo hakpak3
# Select: 3) Install Tools with Filters (Advanced)
# Minimum compatibility %: 50
# Maximum compatibility %: [Enter]
# [Skip other filters by pressing Enter]
# Enter: all
# Installs all tools with ≥50% compatibility
```

### Install Small Tools Only (Under 100MB)  NEW

```bash
sudo hakpak3
# Select: 3) Install Tools with Filters (Advanced)
# [Skip to size filter]
# Maximum size in MB: 100
# [Skip remaining filters]
# Enter: all
# Installs lightweight tools under 100MB
```

### Install Web Security Toolkit  NEW

```bash
sudo hakpak3
# Select: 3) Install Tools with Filters (Advanced)
# Minimum compatibility %: 60
# [Skip to tag filter]
# Include tags: web,http,webapp
# [Skip remaining]
# Enter: all
# Installs web-focused tools with good compatibility
```

### Search and Install Specific Tool

```bash
sudo hakpak3
# Select: 2) Install Tools
# Enter: search
# Search: metasploit
# Select from results
```

### Check Installed Tools

```bash
sudo hakpak3
# Select: 1) List Tools
# Select: 1) Installed Tools
```

### View System Compatibility

When you launch HakPak3, it automatically displays:
- Your OS and version
- Detected package manager
- Available resources (RAM/disk)
- Architecture and CPU info

All tool listings show compatibility scores for your system!

---

##  Architecture

### Core Components

1. **hakpak3.py** - System detection and data models
   - `SystemInfo` - Hardware/OS detection
   - `Tool` - Tool representation
   - `ToolMetrics` - Resource requirements
   - `HardwareDetector` - CPU/RAM/disk info
   - `OSDetector` - Distribution detection
   - `CompatibilityScorer` - Smart ranking

2. **hakpak3_core.py** - Installation and menu logic
   - `DependencyResolver` - Dependency management
   - `PackageInstaller` - Multi-PM support
   - `ToolLoader` - Tool database loading
   - `StateManager` - Installation tracking
   - Menu system and workflows

3. **kali-tools-db.yaml** - 200+ tool definitions
   - Organized by Kali metapackages
   - Complete package mappings
   - Resource metrics
   - Source build instructions

### State Management

- Installation state: `/opt/hakpak3/state.json`
- Installed binaries: `/opt/hakpak3/bin/`
- Source repositories: `/opt/hakpak3/src/`
- Python venvs: `/opt/hakpak3/venv/`

---

##  Security Considerations

### Legal Disclaimer

** IMPORTANT**: These tools are for authorized security testing only!

- Only use on systems you own or have written permission to test
- Unauthorized access is illegal in most jurisdictions
- You accept full responsibility for your actions
- HakPak3 developers are not liable for misuse

### Best Practices

- Always obtain proper authorization
- Document your testing scope
- Use in isolated lab environments when learning
- Keep tools updated
- Understand laws in your jurisdiction

---

##  Contributing

We welcome contributions!

- Add new tools to `kali-tools-db.yaml`
- Improve compatibility scoring
- Add new package managers
- Enhance dependency resolution
- Report bugs and issues

---

##  Support & Contact

**Developer**: Teyvone Wells  
**Company**: PhanesGuild Software LLC  
**Email**: owner@phanesguild.llc  
**GitHub**: https://github.com/PhanesGuildSoftware

---

##  License

See [LICENSE](../LICENSE) file for details.

---

##  Acknowledgments

- **Kali Linux** - For the comprehensive security tool collection
- **Offensive Security** - For maintaining exploit-db and tooling
- **Security Community** - For developing these essential tools

---

##  Roadmap

### Planned Features

- [ ] GUI mode with web interface
- [ ] Tool update management
- [ ] Automated tool testing/verification
- [ ] Custom tool repository support
- [ ] Docker container support
- [ ] Ansible playbook export
- [ ] Tool usage documentation
- [ ] Automated penetration testing workflows

---

**HakPak3** - *Turning up the notch on security tool management* 
