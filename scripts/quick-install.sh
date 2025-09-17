#!/usr/bin/env bash
set -euo pipefail

# HakPak Quick Installer
# Usage (remote): bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
# Optional env vars:
#   HAKPAK_DIR=/opt/hakpak   (install location)
#   HAKPAK_BRANCH=main       (override branch/tag)
#   HAKPAK_NONINTERACTIVE=1  (skip prompts)

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  else
    echo "[!] This installer must run as root (sudo)." >&2
    exit 1
  fi
fi

command -v git >/dev/null 2>&1 || { echo "[i] Installing git"; apt update -y >/dev/null 2>&1 && apt install -y git >/dev/null 2>&1 || { echo "[✗] Failed to install git" >&2; exit 1; }; }
command -v curl >/dev/null 2>&1 || { echo "[i] Installing curl"; apt update -y >/dev/null 2>&1 && apt install -y curl >/dev/null 2>&1 || { echo "[✗] Failed to install curl" >&2; exit 1; }; }

INSTALL_DIR="${HAKPAK_DIR:-/opt/hakpak}"
BRANCH_OR_TAG="${HAKPAK_BRANCH:-}"
REPO_URL="https://github.com/PhanesGuildSoftware/hakpak.git"

if [[ -z "$BRANCH_OR_TAG" ]]; then
  echo "[i] Resolving latest release tag..."
  TAG=$(curl -fsSL https://api.github.com/repos/PhanesGuildSoftware/hakpak/releases/latest 2>/dev/null | grep -m1 '"tag_name"' | sed -E 's/.*"v?([0-9.]+)".*/v\1/' || true)
  if [[ -n "${TAG:-}" ]]; then
    BRANCH_OR_TAG="$TAG"
  else
    echo "[!] Could not resolve latest release tag (falling back to main)" >&2
    BRANCH_OR_TAG="main"
  fi
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[i] Existing install found at $INSTALL_DIR"
  echo "[i] Pulling updates..."
  (cd "$INSTALL_DIR" && git fetch --depth 1 origin "$BRANCH_OR_TAG" && git checkout "$BRANCH_OR_TAG" && git pull --ff-only origin "$BRANCH_OR_TAG")
else
  echo "[i] Cloning $BRANCH_OR_TAG -> $INSTALL_DIR"
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 --branch "$BRANCH_OR_TAG" "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

if [[ -f bin/install-hakpak2.sh ]]; then
  echo "[i] Running v2 system installer..."
  bash bin/install-hakpak2.sh || { echo "[✗] Install failed" >&2; exit 1; }
else
  echo "[✗] v2 installer not found after clone" >&2
  exit 1
fi

echo "[✓] HakPak installed"
echo "[i] Try: hakpak2 detect | hakpak2 list"
[[ -z "${HAKPAK_NONINTERACTIVE:-}" ]] && echo "[i] Interactive menu: hakpak2"
