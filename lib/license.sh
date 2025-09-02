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
#!/usr/bin/env bash
# Minimal stub: legacy licensing fully deprecated. All functions no-op.

is_licensed() { return 0; }
is_pro_valid() { return 0; }
get_license_tier() { echo "Open Source"; }
require_license() { return 0; }
require_pro() { return 0; }
get_license_info() { echo "Open Source Mode (no license required)"; }
activate_license() { echo "Activation deprecated (open source)." >&2; return 1; }
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
