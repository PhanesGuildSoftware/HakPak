# HakPak2 v2025.09.22 Release Notes

## Highlights

- GUI launcher now auto-elevates with `sudo -E` for privileged actions
- Quieter startup: upfront URL announcement and optional desktop notification
- Robust browser opening from desktop sessions even when elevated
- GUI backend uses sudo with askpass support and skips sudo if already root
- Modernized GUI header with larger logo and subtitle

## Docs

- README: Added “GUI Permissions & Troubleshooting” section with env vars, desktop entry, and diagnostics

## Packaging

- Included updated GUI launcher, server, and assets in distribution
- Version bumped to `2025.09.22`

## Install/Upgrade

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
```

## Integrity

```bash
cd release-dist
sha256sum -c hakpak2-2025.09.22.tar.gz.sha256
```

## Validation

- Launch: `hakpak2-gui` (desktop icon or terminal)
- URL printed on start: <http://127.0.0.1:8787>
- Privileged flows: install/uninstall/update and repo add/remove succeed without extra prompts when using the launcher

