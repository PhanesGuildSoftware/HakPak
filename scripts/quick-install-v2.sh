#!/usr/bin/env bash
set -euo pipefail

# Quick installer for HakPak v2 (cross-distro)
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install-v2.sh)

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then exec sudo -E bash "$0" "$@"; else echo "Run as root" >&2; exit 1; fi
fi

command -v git >/dev/null 2>&1 || {
  echo "[i] Installing git"; 
  for pm in apt dnf yum pacman zypper; do
    if command -v "$pm" >/dev/null 2>&1; then
      case "$pm" in
        apt) apt update -y && apt install -y git ;;
        dnf|yum) "$pm" -y install git ;;
        pacman) pacman -Sy --noconfirm git ;;
        zypper) zypper --non-interactive refresh && zypper --non-interactive install git ;;
      esac; break
    fi
  done
}

INSTALL_DIR="/opt/hakpak"
REPO_URL="https://github.com/PhanesGuildSoftware/hakpak.git"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[i] Updating $INSTALL_DIR"
  (cd "$INSTALL_DIR" && git fetch --depth 1 origin main && git checkout main && git pull --ff-only origin main)
else
  echo "[i] Cloning into $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 --branch main "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
./bin/install-hakpak2.sh

echo "[✓] Installed: hakpak2, hakpak2-gui"
echo "Try: hakpak2 detect   |   hakpak2-gui"
