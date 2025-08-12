# --- BEGIN LICENSE CHECK BLOCK ---
# Requires: openssl, base64, jq (jq recommended)
PUBLIC_KEY_PATH="/usr/share/hakpak/public.pem" # change if you store elsewhere
LICENSE_TARGET_SYSTEM="/etc/hakpak/license.lic"
USER_LICENSE_PATH="$HOME/.config/hakpak/license.lic"
WATERMARK_DIR="/var/lib/hakpak"
WATERMARK_USER_DIR="$HOME/.local/share/hakpak"

# Ensure directories exist (best-effort)
mkdir -p "$WATERMARK_USER_DIR"
if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$WATERMARK_DIR"
fi

error() { echo "HakPak: ERROR: $*" >&2; }
info()  { echo "HakPak: $*"; }

# Locate license file function
_find_license_file() {
  if [ -f "$LICENSE_TARGET_SYSTEM" ]; then
    echo "$LICENSE_TARGET_SYSTEM"
    return 0
  elif [ -f "$USER_LICENSE_PATH" ]; then
    echo "$USER_LICENSE_PATH"
    return 0
  else
    return 1
  fi
}

# Verify license file signed by private key; returns 0 if valid
verify_license_file() {
  local licfile
  licfile="$1"
  # Parse our custom bundle format
  local payload_b64 sig_b64 payload_file sig_file
  payload_file=$(mktemp)
  sig_file=$(mktemp)

  awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$payload_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 2; }
  awk '/-----SIGNATURE-----/{p=1; next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$sig_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 3; }

  if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    error "Public key not found at ${PUBLIC_KEY_PATH}. Cannot verify license."
    rm -f "$payload_file" "$sig_file"
    return 4
  fi

  if openssl dgst -sha256 -verify "$PUBLIC_KEY_PATH" -signature "$sig_file" "$payload_file" >/dev/null 2>&1; then
    # signature valid — parse expiry and return valid code 0
    if command -v jq >/dev/null 2>&1; then
      local expires_at
      expires_at=$(jq -r '.expires_at' < "$payload_file")
      if [ -n "$expires_at" ] && [ "$expires_at" != "null" ]; then
        # compare times (UTC)
        local now ts_exp
        now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        ts_exp=$(date -d "$expires_at" +"%s" 2>/dev/null || echo 0)
        ts_now=$(date -d "$now" +"%s" 2>/dev/null || echo 0)
        if [ "$ts_now" -gt "$ts_exp" ]; then
          rm -f "$payload_file" "$sig_file"
          return 5  # expired
        fi
      fi
    fi
    # store payload to watermark file
    _store_license_watermark "$payload_file"
    rm -f "$payload_file" "$sig_file"
    return 0
  else
    rm -f "$payload_file" "$sig_file"
    return 6
  fi
}

_store_license_watermark() {
  local payload_file="$1"
  # extract buyer info for watermark
  if command -v jq >/dev/null 2>&1; then
    local buyer_email buyer_name license_id
    buyer_email=$(jq -r '.buyer_email' < "$payload_file")
    buyer_name=$(jq -r '.buyer_name' < "$payload_file")
    license_id=$(jq -r '.license_id' < "$payload_file")
    local target="${WATERMARK_USER_DIR}/watermark.txt"
    local systarget="${WATERMARK_DIR}/watermark.txt"
    echo "HakPak Pro License" > "$target"
    echo "buyer_name: $buyer_name" >> "$target"
    echo "buyer_email: $buyer_email" >> "$target"
    echo "license_id: $license_id" >> "$target"
    echo "installed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$target"
    # Also write system-wide watermark if running as root
    if [ "$(id -u)" -eq 0 ]; then
      echo "HakPak Pro License" > "$systarget"
      echo "buyer_name: $buyer_name" >> "$systarget"
      echo "buyer_email: $buyer_email" >> "$systarget"
      echo "license_id: $license_id" >> "$systarget"
      echo "installed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$systarget"
      chmod 600 "$systarget"
    fi
  else
    # If jq isn't present, still write a simple fingerprint
    local fingerprint
    fingerprint=$(sha256sum "$payload_file" | awk '{print $1}')
    echo "HakPak Pro License - fingerprint: $fingerprint" > "${WATERMARK_USER_DIR}/watermark.txt"
  fi
}

# Public helper: is_pro_valid
is_pro_valid() {
  local licfile
  if licfile=$(_find_license_file); then
    verify_license_file "$licfile"
    case $? in
      0) return 0 ;;    # valid
      5) error "License expired"; return 1 ;;
      2|3) error "Invalid license format"; return 1 ;;
      4) error "Missing public key"; return 1 ;;
      6) error "Signature verification failed"; return 1 ;;
      *) error "License verification error"; return 1 ;;
    esac
  else
    return 1
  fi
}

# Gate for Pro-only functions. Usage:
#   require_pro || exit 1
require_pro() {
  if is_pro_valid; then
    return 0
  else
    echo
    echo "HakPak Pro feature requires a valid Pro license."
    echo "Place your license file at one of these locations:"
    echo "  $LICENSE_TARGET_SYSTEM"
    echo "  $USER_LICENSE_PATH"
    echo
    echo "To obtain a license, visit: https://phanesguild.llc/hakpak (or contact support)"
    return 1
  fi
}
# --- END LICENSE CHECK BLOCK ---
