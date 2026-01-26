# ⚡ HakPak2 — Cross‑Distro Kali Tool Dependency Manager

HakPak2 is the evolution of the original HakPak (v1). The first release (v1.x) focused on a monolithic Bash installer that pulled Kali packages into Ubuntu/Debian with manual conflict handling. Since then the problem space changed: teams want *selective*, *repeatable*, *distro‑agnostic* access to Kali‑class tooling **without** turning their workstation into “FrankenKali”.

**HakPak2 solves this by treating each tool as a unit with two potential paths:**

1. Prefer a native package on your host distro (apt / dnf / yum / pacman / zypper)
2. Fallback cleanly to an isolated, reproducible source install (Go module, Python venv, Ruby Bundler, or Git + bash wrapper)

No global Python contamination, no Ruby gem conflicts, no system package carnage. Everything lives under `/opt/hakpak2` with lightweight symlinks in `/usr/local/bin`.

---

## 🔄 From HakPak v1 → HakPak2

| Aspect | v1 (Legacy Bash) | v2 (Current) |
|--------|------------------|--------------|
| Architecture | Single Bash script | Python CLI + optional Flask GUI |
| Install Mode | Bulk “Kali style” | Per‑tool with auto native→source fallback |
| Dependency Handling | Coarse pins | Smart per-method strategy + retries |
| Python/Ruby Isolation | None (system) | Per‑tool virtualenv / Bundler sandbox |
| Update Strategy | Re-run script | `hakpak2 update <tool>` / `hakpak2 update all` |
| Tool State | Implicit | Tracked in `/opt/hakpak2/state.json` |
| Uninstall | Limited | Precise (native or source) |
| Wireshark Privilege Fix | Manual | Automated (group + capabilities) |

Legacy v1 is kept only for historical reference. New users should start with HakPak2. If you previously automated v1, migrate by switching any `hakpak ...` calls to the new subcommands shown below.

---

## ✅ Core Guarantees

- **Cross‑Distro**: Works on Ubuntu/Debian, Fedora/RHEL/CentOS/Rocky, Arch, openSUSE.
- **Predictable**: Native when clean; otherwise isolated, controlled source build.
- **Reversible**: Uninstall leaves host package database sane; source clones live under one root.
- **Low Risk**: Apt retries with `--allow-downgrades` only when strictly necessary; no blind overwrites.
- **Auditable**: Tool definitions are declarative in `v2/tools-map.yaml`.

---

## 🚀 Quick Start

```bash
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak
sudo ./bin/install-hakpak2.sh
hakpak2 detect
hakpak2 list
sudo hakpak2 install nmap sqlmap gobuster --method auto
hakpak2 test
```

Graphical (Flask) UI:

```bash
hakpak2-gui
```

Run with no arguments to open the interactive menu:

```bash
hakpak2
```

One‑liner install (latest main):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
```

---

## 🖥️ GUI Permissions & Troubleshooting

- Launch: Use the desktop icon “HakPak2” or run `hakpak2-gui`. The launcher auto-elevates with `sudo -E` so privileged actions (install/update/uninstall, repo add/remove) work without additional prompts.
- Manual: If you prefer a terminal, run:

```bash
sudo -E hakpak2-gui
```

- URL: The GUI serves at `http://127.0.0.1:8787` by default and prints the URL up front. If a browser doesn’t open automatically, copy that URL into your browser.
- Env vars: Tune host/port/TLS if needed:
  - `HAKPAK2_GUI_HOST` (default `127.0.0.1`)
  - `HAKPAK2_GUI_PORT` (default `8787`)
  - `HAKPAK2_GUI_SSL=1` to enable ad‑hoc HTTPS (self‑signed)

Example:

```bash
HAKPAK2_GUI_PORT=8888 sudo -E hakpak2-gui
```

- Browser opening under sudo: The launcher tries to re‑use your user session to open the browser (even when elevated). If nothing opens, it’s safe to open your browser manually to the printed URL.
- Venv: The GUI uses `/opt/hakpak2/.venv-gui` when available; otherwise it creates a user‑space venv at `~/.local/share/hakpak2/.venv-gui` and installs Flask as needed.
- Logs: Start from a terminal to see startup messages. For extra detail:

```bash
bash -x /usr/local/bin/hakpak2-gui 2>&1 | tee /tmp/hakpak2-gui.log
```

- Desktop entry: File is at `/usr/share/applications/hakpak2.desktop` pointing to `/usr/local/bin/hakpak2-gui`. If the icon/menu entry doesn’t appear, refresh caches:

```bash
sudo update-desktop-database /usr/share/applications || true
sudo gtk-update-icon-cache -q /usr/share/icons/hicolor || true
```

- Sudo prompts: The backend prefers to run privileged operations without re‑prompt when launched via the auto‑elevating launcher. If you intentionally run the GUI without elevation, install an askpass helper (e.g., `ssh-askpass`) or configure `sudoers` for passwordless execution of `hakpak2` subcommands.

---

## 🧠 How It Works

1. Detects your package manager.
2. For each requested tool:

    - If a native package mapping exists for your PM → install it.
    - If native fails (or no mapping) → invoke the source strategy (Go / Python Git / Ruby Git / Git Bash wrapper).

3. Records install metadata (method + binary path) into `state.json`.
4. Provides a lightweight runtime test using `hakpak2 test`.

### Source Isolation Strategies

| Type | Use Case | Isolation | Example Tools |
|------|----------|-----------|---------------|
| Go module | Modern Go-based utilities | GOPATH build then copied | `gobuster`, `ffuf` |
| Python Git | App/scripts needing Python deps | Per-tool venv `/opt/hakpak2/venv/<tool>` | `sqlmap`, `set`, `king-phisher` |
| Ruby Git | Large Ruby frameworks | Bundler vendor path inside clone | `metasploit`, `wpscan`, `beef` |
| Git Bash | Pure shell frameworks | Shim wrapper in `/opt/hakpak2/bin` | `fluxion`, `exploitdb` |

---

## 🛠️ Common Commands

```bash
hakpak2 list                 # Show all known tools + methods
sudo hakpak2 install ffuf --method auto
sudo hakpak2 install beef --method source
hakpak2 test                 # Test only installed tools
hakpak2 test --all --json    # Test every defined tool (JSON)
sudo hakpak2 uninstall ffuf
sudo hakpak2 update ffuf     # Refresh tool (native upgrade or source pull)
sudo hakpak2 repo add        # (apt only) add Kali repo with pinning
hakpak2 repo status
sudo hakpak2 repo remove
```

Bulk install (all non-vendor tools):

```bash
sudo hakpak2 install $(hakpak2 list --json | jq -r '.tools[].name' | grep -v -E 'burpsuite|maltego|nessus') --method auto
```

Menu-driven bulk (type `all` when prompted) is also supported.

---

## ▶️ Using Installed Tools

- Direct usage: After installing, run tools normally — no need to mention `hakpak2`.
- Paths: Native packages land on your system PATH; source installs are linked into `/usr/local/bin`.
- Examples:

```bash
sudo hakpak2 install gobuster --method auto
gobuster -h
nmap --version
```

- Troubleshooting PATH: If a tool isn’t found after install, ensure `/usr/local/bin` is in your PATH.

```bash
export PATH=/usr/local/bin:$PATH
```

- Vendor tools: Nessus, Maltego, and Burp Suite are vendor-delivered; use the GUI “Get” button to open the official download pages.

---

## 🔐 Permissions (Wireshark Example)

On installing `wireshark`, HakPak2 will:

- Create/ensure `wireshark` group
- Set group & mode on `dumpcap`
- Apply capabilities `cap_net_admin,cap_net_raw=eip`

Add your user:

```bash
sudo usermod -aG wireshark "$USER" && newgrp wireshark
```

---

## 📦 Included & Supported Tools

See definitive mapping in `v2/tools-map.yaml`. Below are the tools organized by purpose:

### Network Scanning & Reconnaissance
- **nmap** - Network scanner, port scanning, service detection
- **tcpdump** - Network packet analyzer and sniffer
- **wireshark** - GUI network protocol analyzer

### Web Application Testing
- **gobuster** - Directory/file/DNS brute-forcing
- **ffuf** - Fast web fuzzer for discovering hidden files/directories
- **nikto** - Web server scanner
- **dirb** - Web content scanner
- **wfuzz** - Web application fuzzer
- **sqlmap** - Automated SQL injection detection & exploitation
- **wpscan** - WordPress vulnerability scanner
- **skipfish** - Web application security scanner

### Password Cracking & Authentication
- **hydra** - Network login cracker (brute force)
- **john** - John the Ripper password cracker
- **hashcat** - Advanced password recovery/cracking

### Wireless Attacks
- **aircrack-ng** - WiFi security auditing suite
- **reaver** - WPS brute-force attack tool
- **fluxion** - Wireless security testing toolkit

### Exploitation & Frameworks
- **metasploit** - Penetration testing framework
- **exploitdb** - Searchable exploit database (searchsploit)
- **beef** - Browser Exploitation Framework
- **set** - Social Engineering Toolkit

### Security Auditing
- **lynis** - Security auditing tool for Unix systems
- **tiger** - Security audit & intrusion detection system
- **yersinia** - Network protocol security testing

### Utilities
- **netcat** - Network utility for reading/writing network connections
- **autopsy** - Digital forensics platform
- **king-phisher** - Phishing campaign toolkit

### Vendor Tools (Manual Install Required)
- **burpsuite** - Web app security testing (PortSwigger)
- **maltego** - Data mining/link analysis (Paterva)
- **nessus** - Vulnerability scanner (Tenable)

For vendor tool installation guides, see `docs/VENDOR_TOOLS.md`.

---

## 🧪 Testing & Health

`hakpak2 test` tries a lightweight invocation matrix (`--version`, `-h`, help, etc.). Some tools intentionally return non‑zero on help; custom test profiles normalize that (e.g., `fluxion`, `king-phisher`). JSON output allows CI gating.

```bash
hakpak2 test --all --json | jq '.results[] | select(.ok==false)'
```

---

## ♻️ Uninstall / Reset

```bash
sudo hakpak2 uninstall sqlmap
sudo hakpak2 uninstall metasploit
```

Full wipe (state + venvs + clones) — provided by forthcoming cleanup script (see `scripts/clean-reset.sh`).

---

## 🔐 Legal & Ethical Use

Use only on systems you own or have explicit, written authorization to test. Unauthorized use may be illegal. You assume all responsibility. See `docs/SECURITY.md` and `docs/EULA.md` for extended language.

---

## 🧩 Migration Notes (If You Used v1)

- Replace `hakpak --install-tool nmap` with `sudo hakpak2 install nmap`.
- Repo management now lives under `hakpak2 repo (add|status|remove)`.
- Bulk meta “essential” groups are replaced by menu‑driven multi-select or `all` shortcut.
- License / activation commands are gone (project is MIT + open ecosystem now).

---

## 🤝 Contributing

PRs welcome. Add new tools by editing `v2/tools-map.yaml` and (if source) choosing the correct strategy block (`source: {type: ...}`). Keep additions minimal & high-signal; HakPak2 favors *quality over quantity*.

---

## 📄 License

MIT — see `LICENSE`.

© 2025 PhanesGuild Software LLC — Built to reduce operational friction for security engineers.

---

Questions / ideas? Open an Issue or Discussion, or email: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)

If HakPak2 saves you time, ⭐ the repo.
