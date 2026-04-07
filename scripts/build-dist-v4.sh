#!/usr/bin/env bash
set -euo pipefail

# build-dist-v4.sh
# Create a clean distribution archive for HakPak4.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/release-dist-v4"
VERSION_FILE="$ROOT_DIR/v4/VERSION"
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
ARCHIVE_NAME="hakpak4-${VERSION}.tar.gz"

mkdir -p "$DIST_DIR"
rm -rf "$DIST_DIR"/* || true

# File / directory whitelist (relative to repo root)
whitelist=(
  LICENSE
  README.md
  CONTRIBUTING.md
  v4/README.md
  v4/QUICKSTART.md
  v4/CHANGELOG.md
  v4/hakpak4.py
  v4/hakpak4_core.py
  v4/version.py
  v4/VERSION
  v4/hakpak4.sh
  v4/install-hakpak4.sh
  v4/kali-tools-db.yaml
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

# Fail packaging if the staged tool DB diverges from source.
"$ROOT_DIR/scripts/check-tool-db-sync.sh" \
  "$ROOT_DIR/v4/kali-tools-db.yaml" \
  "$TMP_STAGE/v4/kali-tools-db.yaml"

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