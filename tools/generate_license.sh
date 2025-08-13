#!/usr/bin/env bash
# tools/generate_license.sh
# Usage:
#   ./generate_license.sh "Buyer Name" "buyer@example.com" "notes(optional)" "duration_days"
#
# Generates HakPak v1.0.0 licenses (all HakPak now requires licensing)
# Produces: buyer_email.lic (contains base64 of JSON payload + signature)
set -euo pipefail

KEYDIR="./keys"
PRIV="${KEYDIR}/private.pem"
if [ ! -f "$PRIV" ]; then
  echo "Private key not found. Run tools/generate_keys.sh first."
  exit 1
fi

if [ $# -lt 3 ]; then
  echo "Usage: $0 \"Buyer Name\" \"buyer@example.com\" \"notes\" [duration_days]"
  echo ""
  echo "Example:"
  echo "  $0 \"John Doe\" \"john@example.com\" \"HakPak License\""
  exit 1
fi

BUYER_NAME="$1"
BUYER_EMAIL="$2"
NOTES="$3"
DAYS=${4:-365}

ISSUED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EXPIRES_AT=$(date -u -d "+${DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")
LICENSE_ID=$(xxd -l 8 -p /dev/urandom) # short random id

payload=$(cat <<JSON
{
  "license_id": "${LICENSE_ID}",
  "buyer_name": "$(echo "$BUYER_NAME" | sed 's/"/\\"/g')",
  "buyer_email": "$(echo "$BUYER_EMAIL" | sed 's/"/\\"/g')",
  "product": "HakPak",
  "notes": "$(echo "$NOTES" | sed 's/"/\\"/g')",
  "issued_at": "${ISSUED_AT}",
  "expires_at": "${EXPIRES_AT}",
  "version": "1.0.0"
}
JSON
)

# sign payload (detached signature, binary)
payload_file=$(mktemp)
sig_file=$(mktemp)
echo "$payload" > "$payload_file"
openssl dgst -sha256 -sign "$PRIV" -out "$sig_file" "$payload_file"

# bundle payload + signature into single base64 file
bundle_file="${BUYER_EMAIL}.lic"
{
  echo "-----BEGIN HAKPAK LICENSE-----"
  base64 -w0 "$payload_file"
  echo
  echo "-----SIGNATURE-----"
  base64 -w0 "$sig_file"
  echo "-----END HAKPAK LICENSE-----"
} > "$bundle_file"

chmod 600 "$bundle_file"
rm -f "$payload_file" "$sig_file"

echo "License created: $bundle_file"
echo "Give this file to the buyer. Keep private.pem secure."
