#!/usr/bin/env bash
set -euo pipefail

# Verify that HakPak3 tool DB files are in sync.
# Usage:
#   ./scripts/check-tool-db-sync.sh [source_db] [staged_db]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DB="${1:-$ROOT_DIR/v3/kali-tools-db.yaml}"
STAGED_DB="${2:-$ROOT_DIR/release-dist/stage/v3/kali-tools-db.yaml}"

if [[ ! -f "$SOURCE_DB" ]]; then
  echo "[!] Source DB not found: $SOURCE_DB" >&2
  exit 2
fi

if [[ ! -f "$STAGED_DB" ]]; then
  echo "[i] Staged DB not found (skipping check): $STAGED_DB"
  exit 0
fi

if cmp -s "$SOURCE_DB" "$STAGED_DB"; then
  echo "[✓] Tool DB sync check passed"
  exit 0
fi

echo "[!] Tool DB drift detected:" >&2
echo "    source: $SOURCE_DB" >&2
echo "    staged: $STAGED_DB" >&2
echo "[!] Packaging aborted. Sync files before release." >&2

if command -v diff >/dev/null 2>&1; then
  echo "" >&2
  diff -u "$SOURCE_DB" "$STAGED_DB" >&2 || true
fi

exit 1
