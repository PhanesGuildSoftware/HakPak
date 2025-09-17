#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "[!] Run as root (sudo)." >&2
  exit 1
fi

rm -f /usr/local/bin/hakpak2 /usr/local/bin/hakpak2-gui || true
rm -rf /opt/hakpak2 || true
rm -f /usr/share/applications/hakpak2.desktop || true
rm -f /usr/share/pixmaps/hakpak2.svg /usr/share/pixmaps/hakpak2.png /usr/share/pixmaps/hakpak2-icon.svg || true
for sz in 32 64 128 256; do
  rm -f "/usr/share/icons/hicolor/${sz}x${sz}/apps/hakpak2.png" || true
done

# Stop any running GUI on default port
PGID=$(pgrep -f "/opt/hakpak2/gui/server.py" -d ' ' || true)
if [ -n "${PGID}" ]; then
  kill ${PGID} || true
fi

echo "[✓] hakpak2 removed."

# Refresh desktop/icon caches (best-effort)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
