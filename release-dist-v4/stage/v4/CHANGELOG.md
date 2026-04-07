# HakPak4 Changelog

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
