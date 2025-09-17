#!/usr/bin/env bash
set -euo pipefail

# uninstall-hakpak2.sh
# Remove HakPak2 installation: symlinks, /opt/hakpak2, and optional Kali repo pinning.

if [[ $EUID -ne 0 ]]; then
  echo "[!] Must run as root (sudo)." >&2
  exit 1
fi

ROOT_DIR="/opt/hakpak2"
BIN_LINK_DIR="/usr/local/bin"
STATE_FILE="$ROOT_DIR/state.json"

remove_link() {
  local n="$1"
  local p="$BIN_LINK_DIR/$n"
  if [[ -L $p || -f $p ]]; then
    rm -f "$p" && echo "[✓] Removed link $p"
  fi
}

echo "[i] Removing HakPak2 tool links (best-effort)"
if [[ -f "$STATE_FILE" ]]; then
  mapfile -t TOOLS < <(jq -r '.installed | keys[]' "$STATE_FILE" 2>/dev/null || true)
  for t in "${TOOLS[@]}"; do
    bin_name=$(jq -r --arg t "$t" '.installed[$t].path' "$STATE_FILE" 2>/dev/null || echo "")
    # Derive binary name from path if available
    if [[ -n "$bin_name" ]]; then
      base=$(basename "$bin_name")
      remove_link "$base"
    else
      remove_link "$t"
    fi
  done
else
  # fallback: remove known wrappers if state missing
  for b in hakpak2 hakpak2-gui setoolkit sqlmap gobuster ffuf searchsploit msfconsole wpscan beef-xss king-phisher fluxion; do
    remove_link "$b" || true
  done
fi

# Remove root directory
if [[ -d "$ROOT_DIR" ]]; then
  rm -rf "$ROOT_DIR"
  echo "[✓] Removed $ROOT_DIR"
fi

# Optional: remove Kali repo files if present and flag passed
if [[ ${1:-} == "--remove-kali-repo" ]]; then
  echo "[i] Removing Kali apt sources (if present)"
  rm -f /etc/apt/sources.list.d/kali.list /etc/apt/preferences.d/kali.pref || true
  apt update -y || true
  echo "[✓] Kali repo entries removed"
fi

echo "[✓] HakPak2 uninstall complete"
