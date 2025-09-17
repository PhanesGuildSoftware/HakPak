# HakPak v2 — Cross‑Distro Dependency Handler (Preview)

HakPak v2 shifts from a “Kali-on-Ubuntu” installer to a cross‑distro dependency orchestrator. Think Katoolin + git‑source automation, but faster, safer, and more adaptable.

## Goals

- Universal: install security tools on major distros (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE).
- Smart: prefer native packages; fall back to source builds when needed.
- Safe: no blind Kali repo mixing on non‑Debian; avoid breaking base system.
- Automated: detect OS/pm, resolve deps, build, and link binaries with minimal input.
- Auditable: dry‑run mode to preview actions, clear logs, and simple state under `/opt/hakpak2`.

## Architecture

- `v2/hakpak2.py`: Python CLI with package manager abstraction for `apt`, `dnf`, `pacman`, and `zypper`.
- `v2/tools-map.yaml`: Extensible mapping of tools → native package names per PM and optional source recipes.
- Install prefix: `/opt/hakpak2` (configurable). Source builds live in `/opt/hakpak2/src/<tool>`; binaries linked into `/usr/local/bin`.
- Wrapper: `hakpak2` entry point placed in `/usr/local/bin` by `bin/install-hakpak2.sh`.

## Commands (initial)

- `hakpak2 detect` — Show distro and selected package manager.
- `hakpak2 list` — List known tools and available install methods.
- `hakpak2 status` — Report what’s installed (native or linked from source).
- `hakpak2 install <tool> [--method auto|native|source] [--dry-run]` — Install a tool.

## Source Build Patterns

- Go tools (e.g., ffuf, gobuster): ensure `go`, then `go install <module>@latest`; link resulting binary.
- Python tools (e.g., sqlmap): clone repo, `pip install -r requirements.txt` if present; create shim in `/usr/local/bin`.
- Make/C projects (future): install build deps, `make`/`make install` or project‑specific steps.

## Why Python, not Bash?

- Easier cross‑platform orchestration, structured config (YAML), better error handling/dry‑run, and clearer extensibility.

## Roadmap

- Add more tools and recipes (Metasploit, better Hashcat/John variants, Wireshark options).
- Parallel installs, caching, and SBOM/log export.
- Robust uninstall and health checks per tool.

This is a preview scaffold to enable rapid iteration on v2. Contributions welcome.
