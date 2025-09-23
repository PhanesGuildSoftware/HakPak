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

# Ensure venv and Flask are available for GUI (best effort)
case "$PM" in
  apt)
    echo "[i] Installing python3-venv and python3-flask (via apt)"
    install_pkgs python3-venv python3-flask || true
    ;;
  dnf|yum)
    echo "[i] Installing python3-flask (via $PM)"
    install_pkgs python3-flask || true
    ;;
  pacman)
    echo "[i] Installing python-flask (via pacman)"
    install_pkgs python-flask || true
    ;;
  zypper)
    echo "[i] Installing python3-Flask (via zypper)"
    install_pkgs python3-Flask || true
    ;;
esac

if ! "$PY" -c "import yaml" 2>/dev/null; then
  echo "[i] Installing PyYAML"
  "$PIP" install --upgrade pip >/dev/null 2>&1 || true
  "$PIP" install pyyaml
fi

install -Dm755 "$ROOT_DIR/v2/hakpak2.py" /opt/hakpak2/hakpak2.py
install -Dm644 "$ROOT_DIR/v2/tools-map.yaml" /opt/hakpak2/tools-map.yaml
install -Dm755 /dev/stdin /usr/local/bin/hakpak2 <<'EOF'
#!/usr/bin/env bash
PYBIN="/opt/hakpak2/.venv-gui/bin/python"
if [ -x "$PYBIN" ]; then
  exec "$PYBIN" /opt/hakpak2/hakpak2.py "$@"
else
  exec python3 /opt/hakpak2/hakpak2.py "$@"
fi
EOF

# Copy GUI assets
install -d /opt/hakpak2/gui/static
install -Dm755 "$ROOT_DIR/gui/server.py" /opt/hakpak2/gui/server.py
install -Dm644 "$ROOT_DIR/gui/static/index.html" /opt/hakpak2/gui/static/index.html
install -Dm644 "$ROOT_DIR/gui/static/style.css" /opt/hakpak2/gui/static/style.css
install -Dm644 "$ROOT_DIR/gui/static/main.js" /opt/hakpak2/gui/static/main.js
install -Dm644 "$ROOT_DIR/gui/static/favicon.svg" /opt/hakpak2/gui/static/favicon.svg
install -Dm644 "$ROOT_DIR/assets/brand/hakpak2-icon.svg" /opt/hakpak2/gui/static/hakpak2.svg

# Prep GUI venv (do not run GUI)
if command -v python3 >/dev/null 2>&1; then
  if python3 -m venv /opt/hakpak2/.venv-gui >/dev/null 2>&1; then
    /opt/hakpak2/.venv-gui/bin/python -m ensurepip --upgrade >/dev/null 2>&1 || true
    if /opt/hakpak2/.venv-gui/bin/python -m pip --version >/dev/null 2>&1; then
      /opt/hakpak2/.venv-gui/bin/python -m pip install -q --upgrade pip setuptools wheel || true
      /opt/hakpak2/.venv-gui/bin/python -m pip install -q flask pyyaml || true
    fi
  fi
fi

# Install GUI launcher and uninstall script
install -Dm755 "$ROOT_DIR/hakpak-gui.sh" /usr/local/bin/hakpak2-gui
if [[ -f "$ROOT_DIR/scripts/uninstall-hakpak2.sh" ]]; then
  install -Dm755 "$ROOT_DIR/scripts/uninstall-hakpak2.sh" /usr/local/bin/uninstall-hakpak2
elif [[ -f "$ROOT_DIR/bin/uninstall-hakpak2.sh" ]]; then
  # backward compatibility if location changes again
  install -Dm755 "$ROOT_DIR/bin/uninstall-hakpak2.sh" /usr/local/bin/uninstall-hakpak2
fi

# Install desktop entry and icon for GUI launcher
install -d /usr/share/applications /usr/share/pixmaps /usr/share/icons/hicolor
install -Dm644 "$ROOT_DIR/assets/brand/hakpak2-icon.svg" /usr/share/pixmaps/hakpak2-icon.svg || true
# No longer install legacy PNG as the primary icon; SVG is canonical

# Generate PNG icons in common sizes under hicolor
SIZES=(32 64 128 256)
for sz in "${SIZES[@]}"; do
  install -d "/usr/share/icons/hicolor/${sz}x${sz}/apps"
done

if command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT_DIR/assets/brand/hakpak2-icon.svg" <<'PY' || true
import sys,io
from PIL import Image,ImageOps
try:
  import cairosvg
except Exception:
  cairosvg=None
svg_path=sys.argv[1]
if cairosvg is None:
  raise SystemExit(0)
png_bytes=cairosvg.svg2png(url=svg_path, output_width=512, output_height=512)
img=Image.open(io.BytesIO(png_bytes)).convert('RGBA')
for sz in (32,64,128,256):
  out=ImageOps.contain(img, (sz,sz))
  out.save(f'/usr/share/icons/hicolor/{sz}x{sz}/apps/hakpak2.png','PNG')
PY
fi

# Fallback: if PNGs not created, copy the base PNG into each size
# If PNG sizes were not created (no cairosvg), that's OK; DEs will use the SVG
cat > /usr/share/applications/hakpak2.desktop <<'DESK'
[Desktop Entry]
Type=Application
Name=HakPak2
Comment=HakPak2 GUI
Exec=/usr/local/bin/hakpak2-gui
TryExec=/usr/local/bin/hakpak2-gui
Icon=/usr/share/pixmaps/hakpak2-icon.svg
Terminal=false
Categories=Security;Utility;
Keywords=HakPak;Security;Tools;
StartupNotify=true
X-GNOME-UsesNotifications=true
DESK

echo "[✓] hakpak2 installed. Try: hakpak2 (menu) | hakpak2-gui (web UI)"

# Refresh desktop and icon caches (best-effort)
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q /usr/share/icons/hicolor >/dev/null 2>&1 || true
