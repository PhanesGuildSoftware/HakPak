# Contributing to HakPak

Thank you for your interest in contributing to HakPak! This document provides guidelines for contributors to help maintain the quality and security of this project.

## 🔒 Security First

Before contributing, please understand that HakPak deals with security tools that could be misused. All contributions must:

- Follow ethical security practices
- Include proper documentation for responsible use
- Not introduce vulnerabilities or backdoors
- Maintain the professional, enterprise-ready quality standard

## 🚀 Getting Started

### Development Environment Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/PhanesGuildSoftware/hakpak.git
   cd hakpak
   ```

2. **Development Setup**
   ```bash
   sudo ./dev-setup.sh
   ```

3. **Testing Environment**
   - Use a VM or container for testing
   - Test on Ubuntu 24.04 LTS (primary target)
   - Test on Debian 11+ (secondary target)

## 📋 Contribution Types

### 🐛 Bug Reports

Use the bug report template with:
- Detailed reproduction steps
- System information (OS, version, architecture)
- Expected vs actual behavior
- Log files when applicable

### 💡 Feature Requests

For new features, consider:
- Does it align with enterprise/professional use cases?
- Is it a security tool commonly used in penetration testing?
- Does it maintain system stability?
- Is there sufficient demand?

### 🛠️ Code Contributions

#### Tool Additions
New security tools must:
- Be widely recognized in the cybersecurity community
- Have stable package versions in Kali repositories
- Include proper documentation and usage examples
- Pass integration testing on supported platforms

#### Code Standards
- Follow existing bash scripting patterns
- Include comprehensive error handling
- Add logging for all significant operations
- Maintain backward compatibility
- Include unit tests where applicable

## 🧪 Testing Requirements

### Manual Testing Checklist
- [ ] Installation on clean Ubuntu 24.04 LTS
- [ ] Installation on clean Debian 11+
- [ ] All menu options functional
- [ ] Dependency resolution working
- [ ] Repository cleanup working
- [ ] Status reporting accurate
- [ ] Log file generation proper

### Automated Testing
```bash
# Run test suite
./tests/run-tests.sh

# Lint check
shellcheck hakpak.sh
```

## 📝 Pull Request Process

1. **Branch Naming**
   - `feature/tool-name` - New tool additions
   - `bugfix/issue-description` - Bug fixes
   - `docs/improvement-description` - Documentation updates

2. **Commit Messages**
   ```
   type(scope): Brief description
   
   Detailed explanation if needed
   
   Fixes #issue-number
   ```

3. **PR Requirements**
   - Clear description of changes
   - Testing results on supported platforms
   - Documentation updates if applicable
   - No breaking changes without major version bump

## 🔍 Code Review Standards

### Security Review
All PRs undergo security review for:
- No hardcoded credentials or sensitive data
- Proper input validation
- Safe handling of user data
- No introduction of vulnerabilities

### Quality Standards
- Code follows existing patterns
- Comprehensive error handling
- Proper logging implementation
- Performance considerations
- Maintainability and readability

## 📚 Documentation Standards

### Code Documentation
- Function headers with purpose and parameters
- Inline comments for complex logic
- Clear variable naming
- Usage examples where helpful

### User Documentation
- Update README.md for new features
- Add command examples
- Include troubleshooting information
- Maintain accuracy of tool lists

## 🏢 Enterprise Considerations

HakPak targets enterprise environments, so consider:
- Corporate firewall and proxy compatibility
- Stability over bleeding-edge features
- Professional support requirements
- Compliance and audit considerations

## 📞 Getting Help

### Development Questions
- GitHub Discussions for general questions
- GitHub Issues for bug reports
- Email owner@phanesguild.llc for complex technical discussions
- Discord: PhanesGuildSoftware for real-time chat

### Security Concerns
- Email owner@phanesguild.llc for security-related issues
- Include GPG encryption for sensitive reports
- Allow reasonable time for assessment and response

## 🏆 Recognition

Contributors are recognized through:
- Contributors section in README.md
- Release notes acknowledgments
- Hall of Fame for significant contributions
- Professional references for quality contributions

## 📋 Development Roadmap

### Short Term (v1.x)
- Enhanced error handling
- Additional tool integrations
- Improved dependency management
- Better logging and reporting

### Medium Term (v2.x)
- Configuration management
- Custom tool bundles
- Enterprise authentication
- Automated updates

### Long Term (v3.x)
- Web interface
- Centralized management
- Advanced reporting
- API integration

## 🤝 Code of Conduct

### Professional Standards
- Maintain respectful and professional communication
- Focus on technical merit in discussions
- Respect different perspectives and experience levels
- Help newcomers learn and contribute effectively

### Ethical Requirements
- Only contribute to legitimate security research
- Do not submit malicious code or backdoors
- Respect intellectual property rights
- Follow responsible disclosure for security issues

## 📄 Legal Considerations

### Licensing
- All contributions subject to MIT license
- Ensure you have rights to contribute submitted code
- No proprietary or copyrighted code without proper licensing

### Liability
- Contributors acknowledge the security nature of this tool
- PhanesGuild Software LLC not liable for contributor actions
- Contributors responsible for their code's security implications

---

**Thank you for contributing to HakPak! Together we're building the premier enterprise security toolkit.**

*For complex questions or partnership opportunities:*
- **Email**: owner@phanesguild.llc  
- **Discord**: PhanesGuildSoftware
- **GitHub**: [PhanesGuildSoftware](https://github.com/PhanesGuildSoftware)
