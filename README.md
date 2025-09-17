# ⚡ HakPak — Security Tools Supercharged

**One Command. Every Tool You Need.**  
HakPak is the ultimate Linux security toolkit installer — built for professionals, pentesters, and sysadmins who value speed, precision, and stability.  
No more hunting for packages, battling broken dependencies, or wasting time on setup.  
HakPak delivers **a curated, fully-vetted security arsenal in minutes** — so you can focus on the mission, not the prep work.

---

## 🌟 Why HakPak?

- **Corporate-Ready** — Stable, signed releases with enterprise-level reliability.
- **Blazing Fast Setup** — Installs dozens of tools in a fraction of the time.
- **No Bloat** — Every included tool is vetted for relevance and security.
- **Open Source** — MIT licensed. No paywalls, no feature locks.
- **Privacy First** — No telemetry, no tracking.

---

> As of September 2025 HakPak is **fully open source**. All former “Pro” features are now included. Legacy activation flags are inert and will be removed in a future major release.

![HakPak Logo](https://img.shields.io/badge/HakPak-v1.0.0-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Ubuntu%2024.04-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
[![GitHub](https://img.shields.io/badge/GitHub-PhanesGuildSoftware-black?style=for-the-badge&logo=github)](https://github.com/PhanesGuildSoftware)

[Quick Start](#quick-start) • [Documentation](#documentation) • [Included Tools](#included-tools) • [Legal](#important-legal-disclaimer)

---

## Important Legal Disclaimer

### Read Carefully Before Proceeding

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

## v2 Preview — Cross‑Distro Dependency Handler

HakPak v2 focuses on installing tools (prefer native packages, fall back to source) across multiple distros, not just Kali-on-Ubuntu. It’s like Katoolin + git‑source automation, but safer. See `docs/V2_OVERVIEW.md`.

Quick try:

```bash
sudo ./bin/install-hakpak2.sh
hakpak2 detect
hakpak2 list
sudo hakpak2 install ffuf --method auto
```

Contributors: tools are defined in `v2/tools-map.yaml`.

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
wget https://releases.phanesguild.llc/hakpak-v1.0.0.tar.gz
tar -xzf hakpak-v1.0.0.tar.gz
cd hakpak/

# Option B: Clone from GitHub
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak/
```

### Direct Forum Download (Single File)

If you're downloading from the community forum where a single self-extracting `.run` file is posted:

```bash
wget https://releases.phanesguild.llc/hakpak-v1.0.0.run
sha256sum -c hakpak-v1.0.0.run.sha256  # (optional integrity check if .sha256 posted)
chmod +x hakpak-v1.0.0.run
./hakpak-v1.0.0.run
cd hakpak-v1.0.0
sudo ./hakpak.sh --install
```

One-liner (trust on first use – verify checksum separately if possible):

```bash
bash <(curl -fsSL https://releases.phanesguild.llc/hakpak-v1.0.0.run) || ./hakpak-v1.0.0.run
```

If the above streaming execution fails due to shell restrictions, just download and execute manually as shown first. Always prefer verifying the accompanying `.sha256` file:

```bash
curl -fsSLO https://releases.phanesguild.llc/hakpak-v1.0.0.run{,.sha256}
sha256sum -c hakpak-v1.0.0.run.sha256
```

Expected output:

```text
hakpak-v1.0.0.run: OK
```

If the checksum does NOT match, do **not** run the installer—re-download or notify maintainers.

**Step 2:** Install HakPak to system

```bash
sudo ./hakpak.sh --install
```

### One-Line (Fetch + Install Latest Release)

Recommended for most users who just want it set up quickly:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
```

This will:

- Detect latest release tag
- Clone (or update) into /opt/hakpak
- Run the installer


Afterwards:

```bash
hakpak --status
hakpak            # interactive menu
```

**Step 3:** Start using HakPak

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

### Legacy Flags (Deprecated)

Historical flags (`--activate`, `--license-status`, `--pro-dashboard`, `--install-pro-suite`) now emit a warning only. Remove them from automation before the next major release.

### Cleanup / Reset Utility

To fully remove a prior install (repo, pins, binaries, state) and optionally reinstall:

```bash
sudo scripts/clean-reset.sh --help
sudo scripts/clean-reset.sh --force                    # cleanup only
sudo scripts/clean-reset.sh --auto-install --force     # cleanup + fetch release + reinstall
```

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

### External / Optional Tools

Not bundled directly (licensing / size / scope) but compatible with the curated environment:

- Burp Suite Professional
- Metasploit Framework
- OWASP ZAP
- Maltego
- Recon-ng

---

## 🖥️ Screenshots

### Interactive Menu

```text
╔══════════════════════════════════════════════════════════════╗
║                        HAKPAK v1.0.0                        ║
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
 
## 📦 Release Packaging

Create a clean distributable archive (tar.gz + optional zip) using the provided script:

```bash
./scripts/package-release.sh        # auto-detects version from hakpak.sh
./scripts/package-release.sh 1.0.0  # explicit version
ls dist/
```

Contents exclude deprecated licensing artifacts. Use the generated archive for publishing on external download portals.

### Authenticity & Verification

You should always verify what you download:

```bash
# 1. Validate checksum
sha256sum -c hakpak-v1.0.0.tar.gz.sha256
sha256sum -c hakpak-v1.0.0.run.sha256

# 2. (If signatures provided)
curl -fsSLO https://releases.phanesguild.llc/PGSOFTWARE-PUBLIC.asc
gpg --import PGSOFTWARE-PUBLIC.asc
gpg --verify hakpak-v1.0.0.tar.gz.sig hakpak-v1.0.0.tar.gz
gpg --verify hakpak-v1.0.0.sha256.asc
```

If verification fails: DO NOT run the file—re-download or contact maintainers.

---

## 🧵 Forum Release Post Template

When posting to the community forum, you can use this template:

```text
Title: HakPak v1.0.0 – Open Source Security Toolkit (Ubuntu/Debian)

HakPak 1.0.0 is now available as a single-file installer or standard archive.

What’s Included:
 - 15 essential, vetted security tools
 - Safe Kali repository integration with pin protections
 - Open source (MIT) – no activation, no telemetry
 - Self-test & pin verification modes

Download:
 - Self-extracting: hakpak-v1.0.0.run
 - Archive: hakpak-v1.0.0.tar.gz
 - Checksums: hakpak-v1.0.0.sha256 / hakpak-v1.0.0.run.sha256
 - SBOM: hakpak-v1.0.0-sbom.json

Verify Integrity:
 sha256sum -c hakpak-v1.0.0.run.sha256

Quick Install:
 chmod +x hakpak-v1.0.0.run && ./hakpak-v1.0.0.run
 cd hakpak-v1.0.0 && sudo ./hakpak.sh --install

CLI Examples:
 hakpak --status
 hakpak --self-test
 hakpak --install-tool nmap

Supported Distros:
 Ubuntu 24.04 (primary), Ubuntu 22.04/20.04 + Debian 11/12 (baseline)
 Experimental: Pop!_OS, Linux Mint, Parrot OS

Legal Reminder: Use only with explicit authorization. Unauthorized testing may be illegal.

Report Issues: https://github.com/PhanesGuildSoftware/hakpak/issues
```


```text
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
| Ubuntu | 24.04 LTS | ✅ Fully Tested (Primary) |
| Ubuntu | 22.04 LTS | ✅ Baseline Tested |
| Ubuntu | 20.04 LTS | ✅ Baseline Tested |
| Debian | 12 (Bookworm) | ✅ Baseline Tested |
| Debian | 11 (Bullseye) | ✅ Baseline Tested |
| Pop!_OS | 22.04+ | ⚠️ Experimental |
| Linux Mint | 21+ | ⚠️ Experimental |
| Parrot OS | 5.0+ | ⚠️ Experimental |

Experimental: passes distro detection + basic logic; advanced pinning and conflict mitigation not fully validated. Use snapshots/VM and review pin file before large installs.

---

## 🔄 Open Source Transition

In September 2025 HakPak was relicensed as **fully open source (MIT)**. All previously gated features are now available without activation. The decision was driven by:

- Lowering adoption friction for defenders & researchers
- Encouraging community contributions & third-party audits
- Simplifying maintenance by removing license edge cases

## 🧩 Legacy License System (Deprecated)

HakPak still contains vestigial license handling code to avoid breaking older automation scripts. Current behavior:

- Activation commands are no-ops (exit 0, no stored state)
- Status commands report "Open Source Mode"
- No feature restrictions are enforced

Planned removal: A future major version (≥2.0) will purge inactive licensing code. If you have a use case for preserving a lightweight attribution token, open an issue to discuss before removal.

If you encounter a prompt or message referring to “license” please file an issue so we can finish scrubbing the reference.

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
- 🔒 **Security Issues**: Email [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

---

## 📝 Changelog

### v1.1.0 (Current)

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
- 💬 **Discord**: PhanesGuildSoftware
- 💼 **Enterprise**: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

### Author

**Teyvone Wells ("Phanes")**  
*Founder & Principal Engineer – PhanesGuild Software LLC*

Building HakPak to eliminate the grind between intent and execution in security operations. I focus on:

- Frictionless operational tooling for defenders & red teams
- Repeatable, stable installs on production-friendly distros
- Open ecosystem sustainability (community-driven)
- Pragmatic curation: fewer, sharper tools over noisy bloat

If something in HakPak adds drag instead of leverage, I want to know. Reach out, challenge assumptions, or propose improvements—collaborators welcome.

Contact: [owner@phanesguild.llc](mailto:owner@phanesguild.llc) (or open a Discussion / Issue)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright © 2025 PhanesGuild Software LLC

---

Made with ❤️ by PhanesGuild Software LLC

Empowering cybersecurity professionals with enterprise-grade tools

[⭐ Star this repository](https://github.com/PhanesGuildSoftware/hakpak) if HakPak helps you!
