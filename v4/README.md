# HakPak4

HakPak4 is the next major generation of HakPak. This directory is a standalone v4 runtime scaffold derived from v3 so development can proceed without destabilizing current v3 release packaging.

## Current Version

- Defined in `VERSION` (single source of truth)

## Included v4 Runtime Files

- `hakpak4.py`: shared models, detection, and UI helpers
- `hakpak4_core.py`: install logic, menu flow, and CLI entrypoint
- `gitclone.py`: secure GitHub clone workflow with static threat scanning
- `gui/server.py`: Flask backend for Script Builder GUI
- `gui/static/`: Script Builder frontend assets
- `hakpak4.sh`: shell launcher
- `install-hakpak4.sh`: system installer (`/opt/hakpak4`, `/usr/local/bin/hakpak4`, desktop icon + launcher)
- `hakpak4.desktop`: desktop launcher entry (installed to `/usr/share/applications/`)
- `../assets/brand/hakpak4-icon.svg`: desktop icon — floating "HakPak" wordmark in Nabla font (orange) with cyan superscript "4" (installed to `/usr/share/pixmaps/`)
- `test-hakpak4.sh`: baseline smoke tests
- `kali-tools-db.yaml`: tool database (currently synced from v3)

## Quick Start (Dev)

```bash
cd v4
python3 hakpak4_core.py --version
sudo bash hakpak4.sh
```

## GUI Script Builder

Use either command style:

```bash
hakpak4 --gui
```

or

```bash
hakpak4 gui
```

Defaults to `http://127.0.0.1:8788`.

## Secure GitHub Clone

Clone repositories through HakPak threat scanning and dependency handling:

```bash
hakpak4 gitclone https://github.com/owner/repo
```

Optional flags:

- `--force`: override CRITICAL auto-block (not recommended)
- `--yes`: non-interactive confirmation
- `--install-dir /path`: custom destination path

## System Install (Dev)

```bash
cd v4
sudo bash install-hakpak4.sh
hakpak4 --version
```

## Notes

- This is an initial scaffold to begin v4 work quickly.
- v3 and v4 can coexist because install roots and command names are distinct.
- Release scripts at repository root are still v3-oriented and have not been switched to v4 yet.

## Build v4 Release Artifact

```bash
bash scripts/build-dist-v4.sh
```

Outputs are written to `release-dist-v4/`.

## Desktop Icon & Launcher

After running `sudo bash install-hakpak4.sh`, HakPak4 appears in your application launcher with its branded icon:

- **Icon**: floating "HakPak" in the Nabla variable font (orange, neon glow) with a cyan superscript "4" — Nabla is embedded directly in the SVG so it renders correctly on any system without internet or font dependencies
- **Exec**: `hakpak4 gui` — launches the Script Builder GUI directly
- **Icon paths**: `/usr/share/pixmaps/hakpak4-icon.svg` and hicolor PNG sizes (16–256px)
- **Desktop entry**: `/usr/share/applications/hakpak4.desktop`

To manually refresh the launcher after install:

```bash
update-desktop-database /usr/share/applications
gtk-update-icon-cache -q /usr/share/icons/hicolor
```

## Immediate Next Steps

1. Define v4 feature delta versus v3.
2. Add/adjust tests for new behavior in `test-hakpak4.sh` and Python unit tests.
3. Introduce v4 release pipeline updates once runtime changes stabilize.
