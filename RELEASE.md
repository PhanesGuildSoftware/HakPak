# HakPak2 Release & Distribution Guide

This document describes how to package, verify, publish, and validate a HakPak2 release.

---

## 1. Pre-Flight Checklist

- [ ] All tests pass: `hakpak2 test --all` (non-vendor only should succeed)
- [ ] README reflects HakPak2 architecture & quick start
- [ ] `v2/tools-map.yaml` updated and validated (YAML parses)
- [ ] Changelog entry added (if version bump) in `docs/CHANGELOG.md` or root `CHANGELOG.md`
- [ ] Backup tag created (e.g. `vYYYY.MM.DD-backup`)

---

## 2. Versioning

Version is defined in `v2/hakpak2.py` (`VERSION = "YYYY.MM.DD"`). Update before packaging if releasing.

Recommended tag format: `v<date>` or `v<semver>`.

---

## 3. Build Distribution Archive

```bash
./scripts/build-dist.sh
ls release-dist/
```

Outputs:

- `hakpak2-<VERSION>.tar.gz`
- `hakpak2-<VERSION>.tar.gz.sha256`
- `SHA256SUMS` (inside archive)

---

## 4. Verify Integrity

```bash
cd release-dist
sha256sum -c hakpak2-<VERSION>.tar.gz.sha256
```

Optional GPG signing:

```bash
gpg --detach-sign --armor hakpak2-<VERSION>.tar.gz
```

Publish accompanying `.asc` signature if used.

---

## 5. Publish

Upload the archive (and signature if applicable) to:

- GitHub Release assets
- Internal artifact store (if applicable)
- Optional mirror/CDN

Release notes should include:

- Summary of changes
- Added / removed tools
- Known issues / cautions
- Quick start snippet

Template:

```text
## HakPak2 <VERSION>

Highlights:
- ...

Quick Start:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/PhanesGuildSoftware/hakpak/main/scripts/quick-install.sh)
```

Integrity:
```bash
sha256sum -c hakpak2-<VERSION>.tar.gz.sha256
```
```

---

## 6. Fresh Install Validation

Simulate a clean environment:

```bash
sudo ./scripts/uninstall-hakpak2.sh || true
sudo rm -rf /opt/hakpak2
sudo tar -xzf release-dist/hakpak2-<VERSION>.tar.gz -C /tmp/hakpak2-test
mkdir -p /tmp/hakpak2-test && cd /tmp/hakpak2-test || exit 1
sudo ./bin/install-hakpak2.sh
hakpak2 test --all --json | jq '.results | map(select(.ok==false))'
```

Expected: Only vendor (burpsuite / maltego / nessus) show as not found.

---

## 7. Post-Release

- Create support issue label for the new version (if workflow uses labels)
- Monitor early adopter feedback
- Triage install edge cases (especially distro/version specific)

---

## 8. Rollback

If a regression is discovered:

1. Tag previous stable as `v<prev>-stable-hotfix` (optional)
2. Announce deprecation of faulty release in release notes
3. Provide downgrade instructions:

```bash
sudo ./scripts/uninstall-hakpak2.sh
# reinstall previous archive
```

---

## 9. Security Notes

- Never ship private keys
- Validate third-party repo additions (`hakpak2 repo add` is opt-in)
- Keep Ruby, Python, Go tool source pinned via internal process review (no lockfiles shipped intentionally to allow upstream security updates)

---

## 10. Support Channels

- Issues: GitHub
- Security: [owner@phanesguild.llc](mailto:owner@phanesguild.llc)
- Discussions: GitHub Discussions

---

Prepared for: HakPak2 operational distribution lifecycle.
