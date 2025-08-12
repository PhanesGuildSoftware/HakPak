#!/usr/bin/env bash
# Debug license verification

LICENSE_FILE="$HOME/.config/hakpak/license.lic"
PUBLIC_KEY_PATH="./keys/public.pem"

echo "=== DEBUG LICENSE VERIFICATION ==="
echo "License file: $LICENSE_FILE"
echo "Public key: $PUBLIC_KEY_PATH"
echo

# Check if files exist
if [ ! -f "$LICENSE_FILE" ]; then
    echo "ERROR: License file not found"
    exit 1
fi

if [ ! -f "$PUBLIC_KEY_PATH" ]; then
    echo "ERROR: Public key not found"
    exit 1
fi

echo "=== LICENSE FILE CONTENT ==="
cat "$LICENSE_FILE"
echo
echo "=== PARSING TEST ==="

# Parse payload
payload_file=$(mktemp)
sig_file=$(mktemp)

echo "Extracting payload..."
awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$LICENSE_FILE" | base64 -d > "$payload_file" 2>/dev/null

if [ -s "$payload_file" ]; then
    echo "✓ Payload extracted successfully"
    echo "Payload content:"
    cat "$payload_file"
    echo
else
    echo "✗ Failed to extract payload"
    exit 1
fi

echo "Extracting signature..."
awk '/-----SIGNATURE-----/{p=1; next} /-----END HAKPAK LICENSE-----/{p=0} p==1{gsub(/^[ \t]+|[ \t]+$/, "", $0); line=line $0} END{print line}' "$LICENSE_FILE" | base64 -d > "$sig_file" 2>/dev/null

if [ -s "$sig_file" ]; then
    echo "✓ Signature extracted successfully"
    echo "Signature size: $(stat -c%s "$sig_file") bytes"
else
    echo "✗ Failed to extract signature"
    exit 1
fi

echo
echo "=== VERIFICATION TEST ==="
if openssl dgst -sha256 -verify "$PUBLIC_KEY_PATH" -signature "$sig_file" "$payload_file"; then
    echo "✓ Signature verification PASSED"
else
    echo "✗ Signature verification FAILED"
fi

# Cleanup
rm -f "$payload_file" "$sig_file"
