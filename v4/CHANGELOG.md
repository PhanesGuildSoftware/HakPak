# HakPak4 Changelog

## 4.1.0-dev - 2026-03-31

### Added

- **Secure Git Clone** (`hakpak4 gitclone <url>` / menu item 7):
  - Shallow-clones GitHub HTTPS repos into an isolated sandbox.
  - Multi-layer regex scanner detects reverse shells, obfuscation (base64/eval),
    crypto-miners, persistence (cron/systemd/sudoers), setuid exploits and more.
  - Findings grouped by CRITICAL / HIGH / MEDIUM / LOW; CRITICAL automatically
    blocks installation unless `--force` is supplied.
  - Automatic dependency-manifest detection (`requirements.txt`, `Gemfile`,
    `go.mod`, `package.json`, `Cargo.toml`, `Makefile`, CMake, autoconf) and
    installation via HakPak4's existing dependency infrastructure.
  - Repo metadata (URL, commit SHA, risk level, deps) recorded in `state.json`.
  - New module: `v4/gitclone.py`

- **Script Builder GUI** (`hakpak4 gui` / menu item 8):
  - Dark-themed single-page web app at `http://127.0.0.1:8788`.
  - Left sidebar: palette of installed tools (filterable by name/tag), generic
    block types (Comment, Variable, Raw Bash, If/Else, For Loop), and a live
    list of git-cloned repos with their risk level.
  - Centre canvas: ordered, drag-to-reorder script blocks.
  - Right editor panel: per-type form fields that update block previews live.
  - Exports clean `#!/usr/bin/env bash` scripts with `set -euo pipefail`.
  - Save-to-disk (→ `~/hakpak4-scripts/<name>.sh`) and browser-download export.
  - Clone modal proxies the secure git-clone flow directly from the UI.
  - New files: `v4/gui/server.py`, `v4/gui/static/index.html`,
    `v4/gui/static/main.js`, `v4/gui/static/style.css`

- New CLI subcommands:
  - `hakpak4 gitclone <url> [--force] [--yes] [--install-dir DIR]`
  - `hakpak4 gui [--host HOST] [--port PORT]`

- Interactive menu options 7 and 8 in `cmd_menu()`.

## 4.0.0-dev - 2026-03-31

### Added

- Created new `v4/` runtime scaffold from v3 baseline.
- Added standalone v4 entrypoints:
  - `hakpak4.py`
  - `hakpak4_core.py`
  - `hakpak4.sh`
  - `install-hakpak4.sh`
  - `test-hakpak4.sh`
- Established separate command and install root (`hakpak4`, `/opt/hakpak4`).
- Added concise v4 bootstrap README.

### Changed

- Retargeted names and references from v3 to v4 across runtime and installer scripts.
- Updated runtime banner/installer text to display v4.

### Notes

- Release and distribution scripts in the repository root remain on v3 until v4 promotion.
- Tool database is currently mirrored from v3 for compatibility during early development.
