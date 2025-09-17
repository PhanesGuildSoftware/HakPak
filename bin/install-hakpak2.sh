#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "[!] Run as root (sudo)." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="python3"
PIP="pip3"

detect_pm() {
  for c in apt dnf yum pacman zypper; do
    command -v "$c" >/dev/null 2>&1 && { echo "$c"; return; }
  done
  echo ""; return 1
}

PM=$(detect_pm || true)

install_pkgs() {
  case "$PM" in
    apt)
      apt update -y
      apt install -y "$@"
      ;;
    dnf|yum)
      "$PM" -y install "$@"
      ;;
    pacman)
      pacman -Sy --noconfirm
      pacman -S --noconfirm "$@"
      ;;
    zypper)
      zypper --non-interactive refresh
      zypper --non-interactive install "$@"
      ;;
    *)
      echo "[!] Unsupported package manager. Ensure python3 + pip + pyyaml are installed." >&2
      ;;
  esac
}

if ! command -v "$PY" >/dev/null 2>&1; then
  echo "[i] Installing python3 (via $PM)"
  case "$PM" in
    apt) install_pkgs python3 ;;
    dnf|yum) install_pkgs python3 ;;
    pacman) install_pkgs python ;;
    zypper) install_pkgs python3 ;;
  esac
fi

if ! command -v "$PIP" >/dev/null 2>&1; then
  echo "[i] Installing pip (via $PM)"
  case "$PM" in
    apt) install_pkgs python3-pip ;;
    dnf|yum) install_pkgs python3-pip ;;
    pacman) install_pkgs python-pip ;;
    zypper) install_pkgs python3-pip ;;
  esac
fi

if ! "$PY" -c "import yaml" 2>/dev/null; then
  echo "[i] Installing PyYAML"
  "$PIP" install --upgrade pip >/dev/null 2>&1 || true
  "$PIP" install pyyaml
fi

install -Dm755 "$ROOT_DIR/v2/hakpak2.py" /opt/hakpak2/hakpak2.py
install -Dm644 "$ROOT_DIR/v2/tools-map.yaml" /opt/hakpak2/tools-map.yaml
install -Dm755 /dev/stdin /usr/local/bin/hakpak2 <<'EOF'
#!/usr/bin/env bash
exec python3 /opt/hakpak2/hakpak2.py "$@"
EOF

echo "[✓] hakpak2 installed. Try: hakpak2 detect && hakpak2 list"
