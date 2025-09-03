# HakPak vX.Y.Z Release

> Replace X.Y.Z with the actual version. Use this template when drafting the GitHub Release.

## 🚀 Summary

Concise paragraph summarizing the release purpose (e.g. open source transition, new tools, safety improvements).

## ✨ Highlights

- Feature / change 1
- Feature / change 2
- Feature / change 3

## 🔐 Security / Stability

- Note about repository pinning adjustments
- Removed deprecated or unsafe components
- Any CVE impact assessment (if relevant)

## 🧪 Distribution Support

| Tier | Distributions |
|------|---------------|
| Fully Tested | Ubuntu 24.04 LTS |
| Baseline Tested | Ubuntu 22.04, Ubuntu 20.04, Debian 11+, Debian 12 |
| Experimental | Pop!_OS, Linux Mint, Parrot OS |

## 🛠 New / Updated Commands

| Flag | Description |
|------|-------------|
| `--verify-pins` | Validate pin priority for base vs Kali repos |
| `--self-test` | Read-only environment & package availability check |

## 📦 Artifacts

Expect these attachments:

- `hakpak-vX.Y.Z.tar.gz`
- `hakpak-vX.Y.Z.zip` (if built)
- `hakpak-vX.Y.Z.sha256` (combined checksums)
- `hakpak-vX.Y.Z-sbom.json` (CycloneDX or fallback minimal SBOM)

## ✅ Integrity

```bash
# Verify checksums
sha256sum -c hakpak-vX.Y.Z.tar.gz.sha256
sha256sum -c hakpak-vX.Y.Z.zip.sha256   # if present
```

(Optional) GPG signature if provided.

## 🔄 Upgrade Notes

- Run `scripts/clean-reset.sh --force` for a pristine environment
- Reinstall with `./hakpak.sh --install`
- Remove deprecated automation using legacy license flags

## 🧩 Deprecations / Removals

- Legacy licensing flags now inert; removal planned for >=2.0
- Note any soon-to-be removed experimental code paths

## 📣 Call for Feedback

Looking for feedback on: experimental distro stability, additional tool requests, SBOM format preference.

## 🙌 Credits

Thanks to community contributors and testers.

---
MIT Licensed. Forge wisely. Strike precisely.
