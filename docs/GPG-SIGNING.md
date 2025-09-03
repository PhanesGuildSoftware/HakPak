# GPG Signing Guide (HakPak Releases)

Simple steps to create a signing key, sign release artifacts, and let users verify authenticity.

## 1. Create a GPG Key (One Time)

Interactive (recommended):

```bash
gpg --full-generate-key
```
Choose: RSA 4096, 1y expiry (or none), your name/email.

List keys and note the LONG key ID:

```bash
gpg --list-secret-keys --keyid-format=long
```
Example output snippet:

```text
sec   rsa4096/ABCD1234EF567890 2025-09-03 [SC]
```
Key ID here is: `ABCD1234EF567890`.

## 2. Export Your Public Key

```bash
gpg --armor --export ABCD1234EF567890 > PGSOFTWARE-PUBLIC.asc
```
Publish `PGSOFTWARE-PUBLIC.asc` alongside the release.

## 3. Build & Sign Artifacts

From repo root:

```bash
rm -rf dist
SIGN=1 SIGN_KEY_ID=ABCD1234EF567890 MAKE_SELF_EXTRACT=1 \
  ./scripts/package-release.sh 1.1.0
```
Generated signatures:

- Detached signatures: `.tar.gz.asc`, `.zip.asc`, `.run.asc`, `-sbom.json.asc`
- Clear-signed combined checksums: `hakpak-v1.1.0.sha256.asc`

## 4. What to Upload

Minimum:

- hakpak-v1.1.0.run
- hakpak-v1.1.0.run.sha256
- hakpak-v1.1.0.sha256 (and .sha256.asc)
- PGSOFTWARE-PUBLIC.asc

Optional extras:

- hakpak-v1.1.0.tar.gz (+ its .asc + .tar.gz.sha256)
- hakpak-v1.1.0-sbom.json (+ .asc)

## 5. User Verification Instructions

Tell users to do:

```bash
curl -fsSLO https://your.site/PGSOFTWARE-PUBLIC.asc
gpg --import PGSOFTWARE-PUBLIC.asc
curl -fsSLO https://your.site/hakpak-v1.1.0.run{,.sha256,.asc}
curl -fsSLO https://your.site/hakpak-v1.1.0.sha256{,.asc}

# Verify signature on checksum list
gpg --verify hakpak-v1.1.0.sha256.asc

# Verify the run file signature (optional extra assurance)
gpg --verify hakpak-v1.1.0.run.asc hakpak-v1.1.0.run

# Verify checksum integrity
sha256sum -c hakpak-v1.1.0.run.sha256
```

If any verify/OK step fails: DO NOT run the file—re-download or report.

## 6. Rotating Keys

- Generate a fresh key yearly (or earlier if compromised)
- Publish a revocation certificate (created at key generation time)
- Keep old public keys available for historical release validation

## 7. Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `gpg: no default secret key` | No key created or agent not seeing it | Run key generation; ensure correct user |
| `BAD signature` | Wrong key or tampered file | Re-download, compare hashes from another mirror |
| `sha256sum: FAILED` | Corruption or tampering | Delete file and re-fetch |

## 8. Automation (Optional CI)

In CI, import a private key via environment variable:

```bash
echo "$GPG_PRIVATE_KEY" | gpg --batch --import
echo "$GPG_PASSPHRASE" > pass.txt
SIGN=1 SIGN_KEY_ID=$GPG_KEY_ID ./scripts/package-release.sh 1.1.0
```
Use ephemeral keys if you don’t trust the runner long term.

Short version:

1. Create key
2. Export public key
3. Run build with SIGN=1 SIGN_KEY_ID=...
4. Upload artifacts + public key + .asc files
5. Post verification snippet
