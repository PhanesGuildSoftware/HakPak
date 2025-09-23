# HakPak2 v2025.09.17 Release Notes

## Highlights
- HakPak2 is a full rewrite: cross-distro Kali tool dependency manager
- Per-tool install: native package preferred, source fallback (Go, Python venv, Ruby Bundler, Git Bash)
- No global Python/Ruby pollution; all source installs isolated under /opt/hakpak2
- Interactive CLI and Flask GUI (dark theme)
- Bulk install, uninstall, and update flows
- Automated Wireshark group/cap setup
- Vendor/manual tools (burpsuite, maltego, nessus) documented separately

## Tooling & Packaging
- New build script: `scripts/build-dist.sh` for clean distributable tarballs
- Uninstall/cleanup: `scripts/uninstall-hakpak2.sh` removes all symlinks, venvs, and state
- Expanded `.gitignore` for venvs, state, build artifacts
- Release documentation: `RELEASE.md` with packaging, validation, and rollback steps
- Refactored README for HakPak2 positioning, migration, and quick start

## Testing
- `hakpak2 test` and `hakpak2 test --all --json` for CI/validation
- Custom test profiles for tools with non-standard exit codes

## Migration
- v1 (legacy Bash) is deprecated; v2 is default
- All legacy license/activation code removed

## Contributors
- See [CONTRIBUTING.md] for guidelines

---

## Install/Upgrade

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
```

## Integrity

```bash
cd release-dist
sha256sum -c hakpak2-2025.09.17.tar.gz.sha256
```

## Fresh Install Validation

See `RELEASE.md` for full validation and rollback steps.
