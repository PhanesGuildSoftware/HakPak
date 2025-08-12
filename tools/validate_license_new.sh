#!/usr/bin/env bash
# tools/validate_license.sh
# Validates HakPak Pro licenses in the new format
set -euo pipefail

KEYDIR="./keys"
PUB="${KEYDIR}/public.pem"

if [ ! -f "$PUB" ]; then
  echo "Public key not found. Ensure keys/public.pem exists."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 license_file.lic"
  exit 1
fi

LICENSE_FILE="$1"
if [ ! -f "$LICENSE_FILE" ]; then
  echo "License file not found: $LICENSE_FILE"
  exit 1
fi

# Parse the license file format
if ! grep -q "BEGIN HAKPAK LICENSE" "$LICENSE_FILE"; then
  echo "Invalid license file format"
  exit 1
fi

# Extract payload and signature
payload_b64=$(awk '/-----BEGIN HAKPAK LICENSE-----/,/-----SIGNATURE-----/' "$LICENSE_FILE" | grep -v "BEGIN\|SIGNATURE" | tr -d '\n')
sig_b64=$(awk '/-----SIGNATURE-----/,/-----END HAKPAK LICENSE-----/' "$LICENSE_FILE" | sed 's/-----SIGNATURE-----//;s/-----END HAKPAK LICENSE-----//' | tr -d '\n')

# Decode to temp files
payload_file=$(mktemp)
sig_file=$(mktemp)
echo "$payload_b64" | base64 -d > "$payload_file"
echo "$sig_b64" | base64 -d > "$sig_file"

# Verify signature
if openssl dgst -sha256 -verify "$PUB" -signature "$sig_file" "$payload_file" >/dev/null 2>&1; then
  echo "✓ License signature is valid"
  
  # Display license info
  echo "License Information:"
  echo "==================="
  if command -v jq >/dev/null 2>&1; then
    jq -r '
    "License ID: " + .license_id,
    "Buyer: " + .buyer_name + " (" + .buyer_email + ")",
    "Product: " + .product + " v" + .version,
    "Issued: " + .issued_at,
    "Expires: " + .expires_at,
    "Notes: " + .notes
    ' "$payload_file"
    
    # Check expiration
    expires_at=$(jq -r '.expires_at' "$payload_file")
    current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$expires_at" > "$current_time" ]]; then
      echo "✓ License is currently valid"
    else
      echo "✗ License has expired"
      rm -f "$payload_file" "$sig_file"
      exit 1
    fi
  else
    cat "$payload_file"
    echo "Install 'jq' for better formatting"
  fi
else
  echo "✗ License signature is invalid"
  rm -f "$payload_file" "$sig_file"
  exit 1
fi

rm -f "$payload_file" "$sig_file"
echo "✓ License validation complete"
