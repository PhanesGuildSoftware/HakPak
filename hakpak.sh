#!/usr/bin/env bash
set -euo pipefail
echo "[!] 'hakpak.sh' has moved to legacy/. Use 'hakpak2' or 'hakpak2-gui'." >&2
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/hakpak2" "$@"
