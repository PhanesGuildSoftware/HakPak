#!/usr/bin/env bash
set -euo pipefail

# Simple release packaging script for HakPak
# Creates a clean tar.gz excluding deprecated and dev artifacts
# Usage: ./scripts/package-release.sh [version]

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  # Attempt to extract from hakpak.sh
  if grep -q 'readonly HAKPAK_VERSION=' hakpak.sh; then
    VERSION=$(grep 'readonly HAKPAK_VERSION=' hakpak.sh | sed -E "s/.*=\"([0-9.]+)\"/\1/")
  else
    echo "[!] Could not auto-detect version. Provide explicitly: ./scripts/package-release.sh 1.1.0" >&2
    exit 1
  fi
fi

PKG_NAME="hakpak-v${VERSION}"
OUT_DIR="dist"
mkdir -p "$OUT_DIR"
TMP_DIR="$(mktemp -d)" 

copy_root() {
  local path="$1"; shift
  install -Dm644 "$path" "$TMP_DIR/$path"
}
copy_exec() {
  local path="$1"; shift
  install -Dm755 "$path" "$TMP_DIR/$path"
}

# Core runtime files
copy_exec hakpak.sh
copy_exec hakpak-gui.sh || true
copy_root README.md
copy_root LICENSE
copy_root INSTALL.md || true

# Essential docs
mkdir -p "$TMP_DIR/docs"
cp docs/CHANGELOG.md "$TMP_DIR/docs/" 2>/dev/null || true
cp LICENSING-SYSTEM.md "$TMP_DIR/" 2>/dev/null || true
cp webhook-setup-guide.md "$TMP_DIR/" 2>/dev/null || true

# Support scripts
mkdir -p "$TMP_DIR/bin"
cp bin/install.sh "$TMP_DIR/bin/" 2>/dev/null || true
cp bin/install-desktop.sh "$TMP_DIR/bin/" 2>/dev/null || true
cp bin/uninstall-hakpak.sh "$TMP_DIR/bin/" 2>/dev/null || true

# Assets (only brand logo)
mkdir -p "$TMP_DIR/assets/brand"
cp assets/brand/hakpak-logo.* "$TMP_DIR/assets/brand/" 2>/dev/null || true
cp assets/brand/hakpak-icon-64.png "$TMP_DIR/assets/brand/" 2>/dev/null || true
cp assets/brand/hakpak-icon-256.png "$TMP_DIR/assets/brand/" 2>/dev/null || true

# Remove any accidental license remnants
rm -f "$TMP_DIR"/lib/license.sh 2>/dev/null || true

# Produce archive
( cd "$TMP_DIR" && tar -czf "../$OUT_DIR/${PKG_NAME}.tar.gz" . )

# Optional zip
if command -v zip >/dev/null 2>&1; then
  ( cd "$TMP_DIR" && zip -qr "../$OUT_DIR/${PKG_NAME}.zip" . )
fi

rm -rf "$TMP_DIR"

echo "[✓] Release artifacts created in $OUT_DIR/:"
ls -1 "$OUT_DIR" | sed 's/^/  • /'
