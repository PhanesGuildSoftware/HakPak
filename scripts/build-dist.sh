#!/usr/bin/env bash
set -euo pipefail

# build-dist.sh
# Create a clean distribution archive for HakPak2.
# The archive contains only the files required to install and run hakpak2.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/release-dist"
VERSION_FILE="$ROOT_DIR/v2/hakpak2.py"
VERSION="$(grep -E '^VERSION =' "$VERSION_FILE" | sed -E "s/.*'([0-9.]+)'.*/\1/;s/.*\"([0-9.]+)\".*/\1/")"
STAMP="$(date -u +%Y%m%d%H%M%S)"
ARCHIVE_NAME="hakpak2-${VERSION}.tar.gz"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR"/* || true

# File / directory whitelist (relative to repo root)
whitelist=(
  LICENSE
  README.md
  CONTRIBUTING.md
  bin/install-hakpak2.sh
  hakpak.sh
  hakpak-gui.sh
  scripts/quick-install.sh
  v2/hakpak2.py
  v2/tools-map.yaml
  docs/VENDOR_TOOLS.md
  docs/SECURITY.md
  docs/EULA.md
  assets/brand/hakpak-logo.svg
  assets/brand/hakpak-icon-256.png
)

TMP_STAGE="$DIST_DIR/stage"
rm -rf "$TMP_STAGE"
mkdir -p "$TMP_STAGE"

for item in "${whitelist[@]}"; do
  if [[ -e "$ROOT_DIR/$item" ]]; then
    mkdir -p "$TMP_STAGE/$(dirname "$item")"
    cp -a "$ROOT_DIR/$item" "$TMP_STAGE/$item"
  fi
done

# Generate checksum manifest (sha256)
(
  cd "$TMP_STAGE"
  find . -type f -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)

# Create archive
(
  cd "$TMP_STAGE"
  tar -czf "$DIST_DIR/$ARCHIVE_NAME" .
)

# Top-level convenience checksum
(
  cd "$DIST_DIR"
  sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
)

echo "Created: $DIST_DIR/$ARCHIVE_NAME"
cat "$DIST_DIR/${ARCHIVE_NAME}.sha256"
