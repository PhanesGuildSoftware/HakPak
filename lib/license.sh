#!/usr/bin/env bash
# lib/license.sh
# HakPak Pro License Verification Library
# This file contains all license checki# Public helper: is_licensed (all HakPak users need valid license)
is_licensed() {
  local licfile
  if licfile=$(_find_license_file); then
    verify_license_file "$licfile"
    case $? in
      0) return 0 ;;    # valid
      5) license_error "License expired"; return 1 ;;
      2|3) license_error "Invalid license format"; return 1 ;;
      4) license_error "Missing public key"; return 1 ;;
      6) license_error "Signature verification failed"; return 1 ;;
      *) license_error "License verification error"; return 1 ;;
    esac
  else
    return 1  # no license file found
  fi
}

# Legacy compatibility - all features now require license
is_pro_valid() {
  is_licensedn functions

# --- BEGIN LICENSE CHECK BLOCK ---
# Requires: openssl, base64, jq (jq recommended)
# For development, use relative path; for production use /usr/share/hakpak/public.pem
if [ -f "./keys/public.pem" ]; then
    PUBLIC_KEY_PATH="./keys/public.pem"  # Development path
else
    PUBLIC_KEY_PATH="/usr/share/hakpak/public.pem"  # Production installation path
fi
LICENSE_TARGET_SYSTEM="/etc/hakpak/license.lic"
USER_LICENSE_PATH="$HOME/.config/hakpak/license.lic"
WATERMARK_DIR="/var/lib/hakpak"
WATERMARK_USER_DIR="$HOME/.local/share/hakpak"

# Ensure directories exist (best-effort)
mkdir -p "$WATERMARK_USER_DIR"
if [ "$(id -u)" -eq 0 ]; then
  mkdir -p "$WATERMARK_DIR"
fi

license_error() { echo "HakPak: ERROR: $*" >&2; }
license_info()  { echo "HakPak: $*"; }

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
  
  # Parse the license file format using the same method as working validation script
  local payload_b64 sig_b64 payload_file sig_file
  payload_file=$(mktemp)
  sig_file=$(mktemp)

  awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$payload_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 2; }
  awk '/-----SIGNATURE-----/,/-----END HAKPAK LICENSE-----/' "$licfile" | sed 's/-----SIGNATURE-----//;s/-----END HAKPAK LICENSE-----//' | tr -d '\n' | base64 -d > "$sig_file" 2>/dev/null || { rm -f "$payload_file" "$sig_file"; return 3; }

  if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    license_error "Public key not found at ${PUBLIC_KEY_PATH}. Cannot verify license."
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

# Public helper: is_pro_valid (offline validation only)
is_pro_valid() {
  local licfile
  if licfile=$(_find_license_file); then
    verify_license_file "$licfile"
    case $? in
      0) return 0 ;;    # valid
      5) license_error "License expired"; return 1 ;;
      2|3) license_error "Invalid license format"; return 1 ;;
      4) license_error "Missing public key"; return 1 ;;
      6) license_error "Signature verification failed"; return 1 ;;
      *) license_error "License verification error"; return 1 ;;
    esac
  else
    return 1
  fi
}

# Get license tier - all users need license now
get_license_tier() {
  if is_licensed; then
    echo "Licensed"
  else
    echo "Unlicensed"
  fi
}

# Gate for any HakPak function - all require license now
require_license() {
  if is_licensed; then
    return 0
  else
    echo
    print_warning "HakPak requires a valid license to use all features."
    print_info "Place your license file at one of these locations:"
    print_info "  $LICENSE_TARGET_SYSTEM"
    print_info "  $USER_LICENSE_PATH"
    echo
    print_info "To obtain a license, visit: https://phanesguild.llc/hakpak"
    print_info "Contact: owner@phanesguild.llc"
    echo
    return 1
  fi
}

# Legacy compatibility - all features now require license
require_pro() {
  require_license
}

# Get license information for display
get_license_info() {
  local licfile
  if licfile=$(_find_license_file); then
    local payload_file
    payload_file=$(mktemp)
    
    # Extract payload
    awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$licfile" | base64 -d > "$payload_file" 2>/dev/null || {
      rm -f "$payload_file"
      echo "Invalid license format"
      return 1
    }
    
    if command -v jq >/dev/null 2>&1; then
      jq -r '
      "License ID: " + .license_id,
      "Buyer: " + .buyer_name + " (" + .buyer_email + ")",
      "Product: " + .product + " v" + .version,
      "Issued: " + .issued_at,
      "Expires: " + .expires_at,
      "Notes: " + .notes
      ' "$payload_file"
    else
      echo "License information available (install jq for details)"
      cat "$payload_file"
    fi
    
    rm -f "$payload_file"
  else
    echo "No license file found"
    return 1
  fi
}

# License status display
show_enterprise_status() {
  print_info "HakPak License Status:"
  echo "========================"
  
  if is_licensed; then
    print_success "Valid HakPak license found"
    get_license_info | sed 's/^/  /'
    
    # Show watermark info if available
    if [ -f "${WATERMARK_DIR}/watermark.txt" ] || [ -f "${WATERMARK_USER_DIR}/watermark.txt" ]; then
      echo
      print_info "License Installation Details:"
      if [ -f "${WATERMARK_DIR}/watermark.txt" ]; then
        cat "${WATERMARK_DIR}/watermark.txt" | sed 's/^/  /'
      elif [ -f "${WATERMARK_USER_DIR}/watermark.txt" ]; then
        cat "${WATERMARK_USER_DIR}/watermark.txt" | sed 's/^/  /'
      fi
    fi
  else
    print_warning "No valid HakPak license found"
    echo
    print_info "HakPak features require a valid license:"
    echo "  • 15+ essential security tools"
    echo "  • Advanced tool collections"
    echo "  • Extended Kali metapackages"
    echo "  • System overview dashboard"
    echo "  • Priority email support"
    echo "  • Commercial use rights"
    echo
    print_info "License file locations:"
    echo "  • System-wide: $LICENSE_TARGET_SYSTEM"
    echo "  • User-specific: $USER_LICENSE_PATH"
    echo
    print_info "To activate your license:"
    echo "  sudo hakpak --activate YOUR_LICENSE_KEY"
    echo
    print_info "Purchase HakPak at: https://phanesguild.llc/hakpak"
  fi
}

# Activate license from license key
activate_license() {
  local license_key="$1"
  
  if [ -z "$license_key" ]; then
    license_error "License key is required"
    return 1
  fi
  
  # For now, we'll treat the license key as a base64-encoded license file
  # In a real implementation, this would decode/decrypt the key and create the license file
  
  # Validate the license key format (should be base64)
  if ! echo "$license_key" | base64 -d >/dev/null 2>&1; then
    license_error "Invalid license key format"
    return 1
  fi
  
  # Decode the license key to create the license file
  local temp_license=$(mktemp)
  if ! echo "$license_key" | base64 -d > "$temp_license"; then
    license_error "Failed to decode license key"
    rm -f "$temp_license"
    return 1
  fi
  
  # Verify the decoded license is valid
  if ! verify_license_file "$temp_license"; then
    license_error "Invalid license key - verification failed"
    rm -f "$temp_license"
    return 1
  fi
  
  # Determine installation location
  local install_path
  if [ "$(id -u)" -eq 0 ]; then
    install_path="$LICENSE_TARGET_SYSTEM"
    mkdir -p "$(dirname "$install_path")"
  else
    install_path="$USER_LICENSE_PATH"
    mkdir -p "$(dirname "$install_path")"
  fi
  
  # Install the license file
  if cp "$temp_license" "$install_path"; then
    chmod 600 "$install_path"
    rm -f "$temp_license"
    
    # Create watermark file
    local watermark_dir
    if [ "$(id -u)" -eq 0 ]; then
      watermark_dir="$WATERMARK_DIR"
    else
      watermark_dir="$WATERMARK_USER_DIR"
    fi
    
    # Extract license info for watermark
    get_license_info "$install_path" > "$watermark_dir/watermark.txt" 2>/dev/null || {
      echo "HakPak Pro License" > "$watermark_dir/watermark.txt"
      echo "activated_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$watermark_dir/watermark.txt"
    }
    
    license_info "License activated successfully!"
    license_info "License installed to: $install_path"
    
    # Show license status
    echo
    get_license_info "$install_path"
    
    return 0
  else
    license_error "Failed to install license file"
    rm -f "$temp_license"
    return 1
  fi
}

# --- END LICENSE CHECK BLOCK ---
