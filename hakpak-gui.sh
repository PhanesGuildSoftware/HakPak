#!/usr/bin/env bash
set -euo pipefail

# Auto-elevate the GUI for privileged operations when not root
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E "$0" "$@"
  else
    echo "[!] sudo is required. Install sudo or run as root." >&2
    exit 1
  fi
fi

# HakPak v2 GUI Launcher (Web UI)
SELF_DIR="$(dirname "$(readlink -f "$0")")"
# Prefer installed location
if [ -f "/opt/hakpak2/gui/server.py" ]; then
  ROOT_DIR="/opt/hakpak2"
else
  # Fallback: running from repo
  ROOT_DIR="$SELF_DIR"
fi
GUI_DIR="$ROOT_DIR/gui"

# Select a writable venv location: use /opt if writable, else per-user data dir
DEFAULT_VENV_DIR="$ROOT_DIR/.venv-gui"
USER_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/hakpak2"
if [ -w "$ROOT_DIR" ] || [ -w "$(dirname "$DEFAULT_VENV_DIR")" ]; then
  VENV_DIR="$DEFAULT_VENV_DIR"
else
  mkdir -p "$USER_DATA_DIR" >/dev/null 2>&1 || true
  VENV_DIR="$USER_DATA_DIR/.venv-gui"
fi

GUI_URL="http://127.0.0.1:8787"
SERVER_PID=""

echo "[i] HakPak2 GUI will be available at: $GUI_URL" >&2
if command -v notify-send >/dev/null 2>&1; then
  notify-send -a "HakPak2" "Starting HakPak2 GUI" "$GUI_URL" || true
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[!] Python3 is required for the HakPak2 GUI." >&2
  echo "    Install: sudo apt install -y python3 python3-pip" >&2
  exit 1
fi

use_venv() {
  [ -x "$VENV_DIR/bin/python" ]
}

install_system_flask() {
  echo "[i] Attempting to install Flask via system packages..." >&2
  if [ "${EUID:-$(id -u)}" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else SUDO=""; fi
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y >/dev/null 2>&1 || true
    $SUDO apt-get install -y python3-flask >/dev/null 2>&1 || true
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y python3-flask >/dev/null 2>&1 || true
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y python3-flask >/dev/null 2>&1 || true
  elif command -v pacman >/dev/null 2>&1; then
    $SUDO pacman -Sy --noconfirm python-flask >/dev/null 2>&1 || true
  elif command -v zypper >/dev/null 2>&1; then
    $SUDO zypper -n in python3-Flask >/dev/null 2>&1 || true
  fi
}

open_in_browser() {
  local url="$1"
  # Try multiple launchers to maximize compatibility from .desktop environments
  for opener in \
    "xdg-open" \
    "gio open" \
    "gnome-open" \
    "kde-open" \
    "sensible-browser"; do
    if [ "$opener" = "xdg-open" ] && command -v xdg-open >/dev/null 2>&1; then
      if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        U_UID=$(id -u "$SUDO_USER")
        USER_DISPLAY=$(sudo -u "$SUDO_USER" sh -lc 'printf "%s" "${DISPLAY:-:0}"')
        sudo -u "$SUDO_USER" DISPLAY="$USER_DISPLAY" XDG_RUNTIME_DIR="/run/user/$U_UID" xdg-open "$url" >/dev/null 2>&1 && return 0 || true
        su -l "$SUDO_USER" -c "xdg-open '$url'" >/dev/null 2>&1 && return 0 || true
        sudo -u "$SUDO_USER" xdg-open "$url" >/dev/null 2>&1 && return 0 || true
      else
        xdg-open "$url" >/dev/null 2>&1 && return 0 || true
      fi
    elif [ "$opener" = "gio open" ] && command -v gio >/dev/null 2>&1; then
      gio open "$url" >/dev/null 2>&1 && return 0 || true
    elif [ "$opener" = "gnome-open" ] && command -v gnome-open >/dev/null 2>&1; then
      gnome-open "$url" >/dev/null 2>&1 && return 0 || true
    elif [ "$opener" = "kde-open" ] && command -v kde-open >/dev/null 2>&1; then
      kde-open "$url" >/dev/null 2>&1 && return 0 || true
    elif [ "$opener" = "sensible-browser" ] && command -v sensible-browser >/dev/null 2>&1; then
      sensible-browser "$url" >/dev/null 2>&1 && return 0 || true
    fi
  done
  # As a last resort, print the URL (may be unseen if Terminal=false)
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import webbrowser,sys
url=sys.argv[1]
try:
    webbrowser.open(url)
except Exception:
    pass
PY
  fi
  echo "[i] Open your browser to: $url" >&2
}

wait_for_server() {
  local url="$1"
  local host="${url#http://}"
  host="${host#https://}"
  host="${host%%/*}"
  local port="${host#*:}"
  if [ "$host" = "$port" ]; then port=80; fi
  for i in $(seq 1 40); do
    if command -v curl >/dev/null 2>&1 && curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if command -v wget >/dev/null 2>&1 && wget -qO- "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done
  return 1
}

use_venv() {
  [ -x "$VENV_DIR/bin/python" ]
}

# Prefer prepared venv first (installed by the installer)
if use_venv; then
  if "$VENV_DIR/bin/python" - <<'PY'
import sys
try:
    import flask  # noqa
    sys.exit(0)
except Exception:
    sys.exit(1)
PY
  then
  echo "[i] Starting HakPak v2 web GUI on $GUI_URL (venv)" >&2
  (cd "$GUI_DIR" && exec "$VENV_DIR/bin/python" server.py) &
  SERVER_PID=$!
  else
    echo "[!] Venv exists but Flask is missing; attempting repair..." >&2
    "$VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || true
    "$VENV_DIR/bin/python" -m pip install -q --upgrade pip setuptools wheel || true
    "$VENV_DIR/bin/python" -m pip install -q flask || true
  echo "[i] Starting HakPak v2 web GUI on $GUI_URL (venv)" >&2
  (cd "$GUI_DIR" && exec "$VENV_DIR/bin/python" server.py) &
  SERVER_PID=$!
  fi
else
  # If no venv, try to create one silently; otherwise fallback to system Flask
  if ! use_venv; then
  echo "[i] Preparing isolated Python environment for GUI..." >&2
  if ! python3 -m venv "$VENV_DIR" >/dev/null 2>&1; then
    echo "[!] python3-venv may be missing. Attempting to install it..." >&2
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update -y >/dev/null 2>&1 || true
      apt-get install -y python3-venv python3-pip >/dev/null 2>&1 || true
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y python3-venv python3-pip >/dev/null 2>&1 || true
    elif command -v yum >/dev/null 2>&1; then
      yum install -y python3-venv python3-pip >/dev/null 2>&1 || true
    elif command -v pacman >/dev/null 2>&1; then
      pacman -Sy --noconfirm python-virtualenv python-pip >/dev/null 2>&1 || true
    elif command -v zypper >/dev/null 2>&1; then
      zypper -n in python3-virtualenv python3-pip >/dev/null 2>&1 || true
    fi
    python3 -m venv "$VENV_DIR" >/dev/null 2>&1 || true
  fi
  fi

  if use_venv; then
  "$VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || true
  if ! "$VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
    echo "[i] Bootstrapping pip in venv..." >&2
    curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$VENV_DIR/get-pip.py" >/dev/null 2>&1 || true
    "$VENV_DIR/bin/python" "$VENV_DIR/get-pip.py" >/dev/null 2>&1 || true
    rm -f "$VENV_DIR/get-pip.py" || true
  fi
  if "$VENV_DIR/bin/python" -m pip --version >/dev/null 2>&1; then
    "$VENV_DIR/bin/python" -m pip install -q --upgrade pip setuptools wheel || true
    "$VENV_DIR/bin/python" -m pip install -q flask || true
  fi
  if "$VENV_DIR/bin/python" - <<'PY'
import sys
try:
    import flask  # noqa
    sys.exit(0)
except Exception:
    sys.exit(1)
PY
  then
    echo "[i] Starting HakPak2 web GUI on $GUI_URL (venv)" >&2
    (cd "$GUI_DIR" && exec "$VENV_DIR/bin/python" server.py) &
    SERVER_PID=$!
  else
    install_system_flask
    if python3 -c 'import flask' >/dev/null 2>&1; then
      echo "[i] Starting HakPak v2 web GUI on $GUI_URL" >&2
      (cd "$GUI_DIR" && exec python3 server.py) &
      SERVER_PID=$!
    else
      echo "[!] Flask is not available. Try: pip3 install flask" >&2
      exit 1
    fi
  fi
fi
fi

wait_for_server "$GUI_URL" || true
open_in_browser "$GUI_URL"

if [ -n "$SERVER_PID" ]; then
  wait "$SERVER_PID" || true
else
  echo "[!] GUI server did not start; try: $VENV_DIR/bin/python $GUI_DIR/server.py" >&2
  exit 1
fi
