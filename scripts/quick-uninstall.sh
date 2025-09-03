#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  else
    echo "[!] Must run as root (sudo)." >&2
    exit 1
  fi
fi

echo "[i] Removing HakPak binary link (if present)"
rm -f /usr/local/bin/hakpak 2>/dev/null || true

if [[ -d /opt/hakpak ]]; then
  echo "[i] Removing /opt/hakpak"
  rm -rf /opt/hakpak
fi

echo "[i] Cleaning Kali repository + pinning rules (if present)"
rm -f /etc/apt/sources.list.d/kali.list 2>/dev/null || true
rm -f /etc/apt/preferences.d/ubuntu-stability.pref 2>/dev/null || true
rm -f /etc/apt/preferences.d/kali-block-core.pref 2>/dev/null || true

echo "[i] Updating apt index (optional)"
apt update -y >/dev/null 2>&1 || true

echo "[✓] HakPak uninstall complete"
echo "[i] Optional: remove /var/log/hakpak.log manually if desired"