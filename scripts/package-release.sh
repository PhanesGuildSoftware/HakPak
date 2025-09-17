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
ROOT_DIR="$(pwd)"
OUT_DIR="${ROOT_DIR}/dist"
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

if [[ "${MINIMAL:-0}" == "1" ]]; then
  copy_exec hakpak.sh
  copy_root LICENSE
  copy_root README.md
else
  # Core runtime files
  copy_exec hakpak.sh
  copy_exec hakpak-gui.sh || true
  copy_root README.md
  copy_root LICENSE
  [[ -f INSTALL.md ]] && copy_root INSTALL.md || true

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
  # Legacy PNG omitted for v2 packages; SVG is canonical
fi

# Remove any accidental license remnants
rm -f "$TMP_DIR"/lib/license.sh 2>/dev/null || true

# Produce archive
( cd "$TMP_DIR" && tar -czf "${OUT_DIR}/${PKG_NAME}.tar.gz" . )

# Optional zip (unless SKIP_ZIP=1)
if [[ "${SKIP_ZIP:-0}" != "1" && "${MINIMAL:-0}" != "1" ]]; then
  if command -v zip >/dev/null 2>&1; then
  ( cd "$TMP_DIR" && zip -qr "${OUT_DIR}/${PKG_NAME}.zip" . )
  else
    echo "[i] zip not installed; skipping zip archive" >&2
  fi
fi

# Generate SHA256 checksums
pushd "$OUT_DIR" >/dev/null || true
sha256sum "${PKG_NAME}.tar.gz" > "${PKG_NAME}.tar.gz.sha256"
if [[ -f "${PKG_NAME}.zip" ]]; then
  sha256sum "${PKG_NAME}.zip" > "${PKG_NAME}.zip.sha256"
fi
{
  cat "${PKG_NAME}.tar.gz.sha256"
  [[ -f "${PKG_NAME}.zip.sha256" ]] && cat "${PKG_NAME}.zip.sha256"
} > "${PKG_NAME}.sha256"

# Verify integrity
sha256sum -c "${PKG_NAME}.tar.gz.sha256" >/dev/null 2>&1 && echo "[✓] tar.gz checksum verified" || echo "[!] tar.gz checksum mismatch" >&2
if [[ -f "${PKG_NAME}.zip.sha256" ]]; then
  sha256sum -c "${PKG_NAME}.zip.sha256" >/dev/null 2>&1 && echo "[✓] zip checksum verified" || echo "[!] zip checksum mismatch" >&2
fi
popd >/dev/null || true

# Optional self-extracting single-file installer (MAKE_SELF_EXTRACT=1)
if [[ "${MAKE_SELF_EXTRACT:-0}" == "1" ]]; then
  SELF_EX="${OUT_DIR}/${PKG_NAME}.run"
  echo "[i] Building self-extracting installer: $(basename "$SELF_EX")"
  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo 'ARCHIVE_LINE=$(awk '\''/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }'\'' "$0")'
    echo 'command -v tar >/dev/null || { echo "[!] tar required"; exit 1; }'
    echo 'command -v base64 >/dev/null || { echo "[!] base64 required"; exit 1; }'
    echo "EMBED_VERSION='${VERSION}'"
    echo 'TARGET_DIR="hakpak-v${EMBED_VERSION}"'
    echo 'rm -rf "$TARGET_DIR"'
    echo 'mkdir -p "$TARGET_DIR"'
    echo 'tail -n +"$ARCHIVE_LINE" "$0" | base64 -d | tar -xz -C "$TARGET_DIR"'
    echo 'echo "[✓] HakPak ${EMBED_VERSION} extracted to ./$TARGET_DIR"'
    echo 'if [[ ${EUID:-$(id -u)} -ne 0 ]]; then prefix="sudo "; else prefix=""; fi'
    echo 'echo "To install system-wide: ${prefix}./hakpak.sh --install"'
    echo 'echo "Or run in-place (no system install): ./hakpak.sh --interactive"'
    echo 'exit 0'
    echo '__ARCHIVE_BELOW__'
    base64 "${OUT_DIR}/${PKG_NAME}.tar.gz"
  } > "$SELF_EX"
  chmod +x "$SELF_EX"
  # checksum for self-extracting file
  ( cd "$OUT_DIR" && sha256sum "$(basename "$SELF_EX")" > "$(basename "$SELF_EX").sha256" )
  # append to combined checksum file if it exists
  if [[ -f "${OUT_DIR}/${PKG_NAME}.sha256" ]]; then
    sha256sum "$SELF_EX" >> "${OUT_DIR}/${PKG_NAME}.sha256"
  fi
  echo "[✓] Self-extracting installer created: $SELF_EX"
fi

# SBOM generation (unless SKIP_SBOM=1)
if [[ "${SKIP_SBOM:-0}" != "1" && "${MINIMAL:-0}" != "1" ]]; then
  SBOM_FORMAT=${SBOM_FORMAT:-cyclonedx-json}
  SBOM_OUT="${OUT_DIR}/${PKG_NAME}-sbom.json"
  echo "[i] Generating SBOM (${SBOM_FORMAT})"
  if command -v syft >/dev/null 2>&1; then
    case "$SBOM_FORMAT" in
      cyclonedx-json) syft "$TMP_DIR" -o cyclonedx-json > "$SBOM_OUT" 2>/dev/null || echo "[!] syft warning" >&2 ;;
      spdx-json) syft "$TMP_DIR" -o spdx-json > "$SBOM_OUT" 2>/dev/null || echo "[!] syft warning" >&2 ;;
      *) echo "[!] Unknown SBOM_FORMAT '$SBOM_FORMAT' (using cyclonedx-json)"; syft "$TMP_DIR" -o cyclonedx-json > "$SBOM_OUT" || true ;;
    esac
    echo "[✓] SBOM created: $SBOM_OUT"
  else
    echo "[i] syft not installed; building minimal fallback SBOM" >&2
    {
      echo '{'
      echo '  "bomFormat": "CycloneDX",'
      echo '  "specVersion": "1.5",'
      echo '  "version": 1,'
      echo '  "metadata": { "component": { "type": "application", "name": "hakpak", "version": "'"$VERSION"'", "licenses": [{"license": {"id": "MIT"}}] } },'
      echo '  "components": ['
      find "$TMP_DIR" -type f -maxdepth 6 | sed 's/^/    {"name": "/;s/$/"},/' | sed '$ s/},$/}/'
      echo '  ]'
      echo '}'
    } > "$SBOM_OUT"
    echo "[✓] Fallback SBOM created: $SBOM_OUT"
  fi
fi

# Optional signing (SIGN=1, optional SIGN_KEY_ID="ABCDEF...")
if [[ "${SIGN:-0}" == "1" ]]; then
  if command -v gpg >/dev/null 2>&1; then
    echo "[i] Signing artifacts with GPG"
    KEY_ARG=()
    [[ -n "${SIGN_KEY_ID:-}" ]] && KEY_ARG=( -u "$SIGN_KEY_ID" )
    artifacts=(
      "${OUT_DIR}/${PKG_NAME}.tar.gz"
      "${OUT_DIR}/${PKG_NAME}.zip"
      "${OUT_DIR}/${PKG_NAME}.run"
      "${OUT_DIR}/${PKG_NAME}-sbom.json"
      "${OUT_DIR}/${PKG_NAME}.sha256"
    )
    for a in "${artifacts[@]}"; do
      [[ -f "$a" ]] || continue
      if [[ "$a" == *.sha256 ]]; then
        gpg --batch --yes --clearsign "${KEY_ARG[@]}" --output "${a}.asc" "$a" && echo "[✓] Cleared-signed: $(basename "$a")" || echo "[!] Failed to clearsign $(basename "$a")" >&2
      else
        gpg --batch --yes --armor --detach-sign "${KEY_ARG[@]}" "$a" && echo "[✓] Signed: $(basename "$a")" || echo "[!] Failed to sign $(basename "$a")" >&2
      fi
    done
    echo "[✓] GPG signing complete"
  else
    echo "[!] SIGN=1 but gpg not found; skipping signing" >&2
  fi
fi

rm -rf "$TMP_DIR"

echo "[✓] Release artifacts created in $OUT_DIR/:"
ls -1 "$OUT_DIR" | sed 's/^/  • /'
echo
echo "Next steps:" 
echo "  1. git tag v${VERSION} && git push origin v${VERSION}"
echo "  2. Draft GitHub Release and attach:"
echo "       - ${PKG_NAME}.tar.gz (+ individual + combined .sha256)"
[[ -f "${OUT_DIR}/${PKG_NAME}.zip" ]] && echo "       - ${PKG_NAME}.zip (+ sha256)"
[[ -f "${OUT_DIR}/${PKG_NAME}.run" ]] && echo "       - ${PKG_NAME}.run (+ .run.sha256)" && echo "         (Self-extracting single-file installer)"
[[ -f "${OUT_DIR}/${PKG_NAME}-sbom.json" ]] && echo "       - ${PKG_NAME}-sbom.json"
echo "  3. Optionally sign checksums: gpg --clearsign ${PKG_NAME}.sha256"
echo "  4. Publish and announce."
