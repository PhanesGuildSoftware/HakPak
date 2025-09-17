#!/usr/bin/env bash
set -euo pipefail
# Thin wrapper to the canonical installer in bin/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/bin/install-hakpak2.sh" "$@"
