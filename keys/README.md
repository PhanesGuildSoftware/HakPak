# HakPak Pro Keys Directory

This directory contains the cryptographic keys for HakPak Pro license verification.

## For License Vendors

If you're selling HakPak Pro licenses, you'll need to:

1. **Generate your own key pair:**
   ```bash
   cd tools/
   ./generate_keys.sh
   ```

2. **Move the public key:**
   ```bash
   mv keys/public.pem keys/public.pem
   ```

3. **Keep private key secure:**
   - Store `keys/private.pem` in a secure location
   - Never commit private keys to version control
   - Use the private key to sign customer licenses

## For End Users

After purchasing HakPak Pro, you'll receive:
- A license key to activate with `hakpak --activate <key>`
- The public key will be automatically installed during HakPak installation

## Security Notes

- Public keys are safe to distribute
- Private keys must be kept secure and never shared
- License verification happens offline using these keys

---

**PhanesGuild Software LLC**  
Contact: owner@phanesguild.llc
