# HakPak3 Quick Start Guide

##  Get Started in 3 Minutes

### Step 1: Install HakPak3

```bash
cd /home/pgsw/PhanesGuild/HakPak/v3
sudo bash install-hakpak3.sh
```

### Step 2: Launch HakPak3

```bash
sudo hakpak3
```

### Step 3: Install Your First Tools

1. Select **2) Install Tools**
2. Review the top 20 recommended tools for your system
3. Enter tool names (e.g., `nmap hydra sqlmap`)
   - Or type `all` to install ALL available tools
   - Or type `best20` to install top 20 best for your system
   - Or type `top5` to install top 5 best
4. Watch HakPak3 automatically handle dependencies and installation!

---

##  Common Tasks

### View All Available Tools

```
Main Menu → 1) List Tools → 4) All Available Tools
```

### Search for a Specific Tool

```
Main Menu → 1) List Tools → 5) Search Tools
Enter: metasploit  (or any keyword/tag)
```

### Install Web Testing Tools

```
Main Menu → 2) Install Tools
Enter: burpsuite sqlmap nikto gobuster ffuf
```

### Install Wireless Tools

```
Main Menu → 2) Install Tools  
Enter: aircrack-ng reaver wifite kismet
```

### Check What's Installed

```
Main Menu → 4) Status & Installed Tools
```

---

##  Pro Tips

### Smart Compatibility Ranking
- Tools are automatically ranked by compatibility with your system
-  Green (80-100%): Perfect match, install recommended
-  Yellow (60-79%): Good match, may need source build
-  Red (<60%): Limited compatibility, may have issues

### Resource Awareness
- HakPak3 shows you disk and RAM requirements before installing
- Prevents installations that would fail due to resource limits
- Warns if RAM is low but allows override

### Batch Installation
- Install multiple tools at once: `nmap wireshark metasploit-framework`
- Separate with spaces or commas
- Dependencies handled automatically

### Source Builds
- If native packages aren't available, HakPak3 builds from source
- Supports Go, Python, Ruby, and bash-based tools
- Automatically creates isolated environments (venv for Python)

---

##  Understanding Metrics

When viewing tools, you'll see:

```
Tool                 Compat     Size        RAM        Description
--------------------------------------------------------------------------------
nmap                 95%       20.5 MB     128 MB     Network exploration...
metasploit-framework 88%       800.0 MB    2 GB       Penetration testing...
```

- **Compat**: How well the tool matches your OS (higher = better)
- **Size**: Total disk space needed (tool + dependencies)
- **RAM**: Minimum RAM required to run the tool
- **Description**: What the tool does

---

##  Troubleshooting

### "No supported package manager found"
- Ensure you're on a supported distro (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE)
- Install your distro's package manager

### "PyYAML is required"
```bash
pip3 install pyyaml
# or
sudo apt install python3-yaml
```

### "This operation requires root privileges"
```bash
# Always use sudo
sudo hakpak3
```

### Tool not found after installation
```bash
# Reload your shell
hash -r
# or
source ~/.bashrc
```

---

##  Learning Path

### Beginner: Start with Core Tools
```
nmap, netcat, hydra, john, wireshark
```

### Intermediate: Add Web Testing
```
burpsuite, sqlmap, nikto, gobuster, wpscan
```

### Advanced: Full Arsenal
```
metasploit-framework, aircrack-ng, beef-xss
reaver, exploitdb, social-engineer-toolkit
```

---

##  Next Steps

1. **Read the full README** - `/v3/README.md`
2. **Check tool documentation** - Most tools have `--help` or `man` pages
3. **Practice in labs** - Set up virtual environments for safe testing
4. **Join the community** - Contribute to HakPak development

---

##  Remember

**Only use these tools on systems you own or have written permission to test!**

Unauthorized use is illegal and unethical. HakPak3 is designed for:
- Security professionals
- Penetration testers
- Students in authorized labs
- Researchers with proper authorization

---

Happy hacking! 

*For issues or questions: owner@phanesguild.llc*
