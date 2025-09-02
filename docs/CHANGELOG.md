# Changelog

All notable changes to HakPak will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Additional distribution self-test coverage
- Packaging refinements (deb/rpm exploration)

## [1.1.0] - 2025-09-01

### Changed

- Project fully transitioned to Open Source edition (MIT) — all former "Pro" features unlocked
- Removed legacy licensing subsystem (`lib/license.sh`, activation, validation code paths)
- Simplified dashboard (formerly Pro dashboard) now universally available
- Updated help text and CLI to mark legacy flags as deprecated no-ops

### Added (1.1.0)

- Release packaging script: `scripts/package-release.sh` for clean distributable archives
- Deprecation notice in `lib/README.md`

### Removed

- License verification logic, activation flow, watermarking, RSA key distribution
- Pro suite installer and upgrade prompts

### Security

- Eliminated dead code related to cryptographic verification reducing surface area

### Migration Notes

- Any automation invoking legacy flags (`--activate`, `--license-status`, `--pro-dashboard`, `--install-pro-suite`) will still succeed but perform no action and emit a warning. Plan to remove these flags in the next major release.


### Added (1.0.0)
- Terms of use acceptance prompt for legal compliance
- Comprehensive README.md with screenshots and documentation
- Contributing guidelines for community development
- Enterprise support contact information

### Changed (1.0.0)
- Enhanced legal disclaimers throughout application
- Improved professional presentation and branding

### Security (1.0.0)
- Added mandatory terms acceptance before tool installation
- Enhanced legal liability protection measures

## [1.0.0] - 2025-01-11

### Added
- Initial release of HakPak Professional Security Toolkit
- Support for Ubuntu 24.04 LTS (primary platform)
- Support for Debian 11+ and other Debian-based distributions
- 15 essential security tools from Kali Linux repositories
- Intelligent dependency resolution and conflict prevention
- Professional logging system with detailed status reporting
- Interactive menu system for ease of use
- Command-line interface with comprehensive options
- Repository management with proper GPG key handling
- System safety checks and environment validation

#### Security Tools Included
- **Network Analysis**: nmap, wireshark, tcpdump, netcat
- **Web Testing**: sqlmap, nikto, dirb, gobuster, wfuzz, ffuf
- **Password Tools**: hydra, john, hashcat
- **Exploitation**: exploitdb, searchsploit

#### Command-Line Features
- `--help` - Comprehensive help documentation
- `--version` - Version and system information
- `--status` - Detailed system and package status
- `--setup-repo` - Kali repository configuration only
- `--remove-repo` - Complete repository cleanup
- `--install TOOL` - Individual tool installation
- `--fix-deps` - Dependency conflict resolution
- `--list-metapackages` - Available package listing
- `--interactive` - Interactive menu (default mode)

#### Enterprise Features
- Professional branding and presentation
- Comprehensive error handling and logging
- Support for corporate environments
- Stable, tested configurations
- Repository pinning for system stability

### Technical Implementation
- Bash scripting with strict error handling (`set -euo pipefail`)
- Modular function design for maintainability
- APT preference pinning for repository management
- Comprehensive distribution detection
- Professional logging to `/var/log/hakpak.log`
- Color-coded output for better user experience

### Security & Legal
- MIT License for open-source compatibility
- Legal disclaimers for responsible use
- Professional author attribution
- Corporate liability protection

### System Requirements
- Ubuntu 24.04 LTS (fully tested)
- Debian 11+ (supported)
- Root/sudo privileges required
- Internet connection for package downloads
- Minimum 5GB available disk space
- amd64 architecture support

### Known Issues
- Some Kali packages may have dependency conflicts on certain systems
- Network connectivity required for all operations
- Limited to Debian-based distributions only

### Compatibility
- **Fully Tested**: Ubuntu 24.04 LTS
- **Supported**: Ubuntu 22.04+, Debian 11+, Pop!_OS 22.04+
- **Community Tested**: Linux Mint 21+, Parrot OS 5.0+

---

## Version History Summary

| Version | Release Date | Key Features | Status |
|---------|--------------|--------------|---------|
| 1.0.0 | 2025-01-11 | Initial release, 15 tools, Ubuntu 24.04 support | Current |

---

## Upgrade Notes

### From Pre-Release to 1.0.0
This is the initial stable release. No upgrade path needed.

### Future Upgrades
- Backup your system before major version upgrades
- Check compatibility with your distribution version
- Review changelog for breaking changes
- Test in non-production environment first

---

## Support Timeline

| Version | Release Date | End of Support | Security Fixes |
|---------|--------------|----------------|----------------|
| 1.0.x | 2025-01-11 | 2026-01-11 | Yes |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on contributing to HakPak development.

## Security Advisories

Security issues are tracked separately. For security-related concerns:
- Email: security@phanesguild.llc
- GPG Key: Available on request
- Response Time: 72 hours maximum

---

*HakPak is developed and maintained by PhanesGuild Software LLC*  
*For enterprise support and professional services: enterprise@phanesguild.llc*
