#!/usr/bin/env bash
# tools/generate_keys.sh
# Generates RSA keypair for signing licenses.
# Keep private.pem secret. Commit public.pem to repo.

set -euo pipefail

OUTDIR="./keys"
mkdir -p "$OUTDIR"

echo "Generating 4096-bit RSA keypair..."
openssl genpkey -algorithm RSA -out "${OUTDIR}/private.pem" -pkeyopt rsa_keygen_bits:4096
openssl rsa -pubout -in "${OUTDIR}/private.pem" -out "${OUTDIR}/public.pem"

chmod 600 "${OUTDIR}/private.pem"
chmod 644 "${OUTDIR}/public.pem"

echo "Keys created in ${OUTDIR}/ (private.pem is secret)"
