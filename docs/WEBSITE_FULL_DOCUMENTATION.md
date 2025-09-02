# HakPak – Unified Product & Technical Documentation

Last updated: 2025-09-01

## 1. Hero & Positioning

**One Command. Operational Security Toolkit.**  
From blank Ubuntu/Debian host to a calibrated offensive + diagnostic environment in minutes. Curated tools, conflict‑aware setup. Fully open source (MIT) since September 2025.

### Taglines

- Forge Wisely. Strike Precisely.
- Clean Installs. Dirty Findings.
- Less Setup. More Signal.
- Provision Less. Discover More.
- Curated. Fast. Ruthless.

### Problem → Solution

| Pain | Typical Outcome | HakPak Answer |
|------|-----------------|---------------|
| Dependency hell | Wasted billable hours | Smart pinning & safety checks |
| Bloated mega-scripts | Tool sprawl, version drift | Curated essential baseline |
| Untrusted copy/paste | Supply-chain risk | Auditable open source code |
| Telemetry & lock-in | Privacy concerns | No telemetry, no lock-in |
| Environment drift | Inconsistent results | Deterministic curated install |

---

## 2. Open Source Unification

HakPak previously shipped with a dual "Community / Pro" model. All feature gates were removed and the project is now a single MIT-licensed distribution. Legacy activation commands remain temporarily (no-op) to avoid breaking automation and will be removed ≥2.0.

Formerly gated features now universally available:
- Batch / suite orchestration
- Enriched status & diagnostics
- Self-test mode
- Optional tool grouping logic

---

## 3. Core Value Differentiators
1. Deterministic Baseline – Same sharp curated set every run.
2. Safety First – APT pinning & dependency conflict mitigation.
3. Minimal Surface – Cuts bloat; keeps only operationally relevant tools.
4. Operational Speed – From clone to recon in minutes.
5. Privacy – No telemetry, no activation, no callbacks.
6. Clean Removal – Uninstall leaves the host tidy.

---

## 4. Quick Start

```bash
git clone https://github.com/PhanesGuildSoftware/hakpak.git
cd hakpak
sudo ./hakpak.sh --install
sudo hakpak --status
sudo hakpak            # Interactive menu
```

## 5. Self-Test (Distro Validation)

Use on new Ubuntu / Debian releases before full deployment.
```bash
sudo ./hakpak.sh --self-test
```
Checks: distro detection, core binaries, package availability, sample dry-runs.

---

## 6. Distribution Support

| Distro | Minimum | Notes |
|--------|---------|-------|
| Ubuntu | 20.04 | Tuned for 24.04; future releases validated via self-test |
| Debian | 11 | Preparing for 13 (Trixie) via self-test |
| Pop!_OS | 22.04 | Ubuntu derivative path |
| Linux Mint | 21 | Ubuntu derivative path |
| Parrot OS | 5.x | Recognized & allowed |

---

## 7. Safety & Dependency Handling

- Repository conflict avoidance & pinning templates
- Disk space threshold warnings
- Bootstrap of essential network/crypto tools
- Optional dry-run simulation before bulk installs

---

## 8. Tool Installation Modes

| Mode | Description |
|------|-------------|
| Single Tool | `--install-tool TOOLNAME` idempotent install |
| Essential Batch | Interactive menu core set |
| Suite Orchestration | Former Pro; now included |
| Metapackage List | Enumerate supported Kali packages |

---

## 9. Legacy License Flags (Deprecated)

Flags `--activate`, `--license-status`, `--paste-license`, `--pro-dashboard`, `--install-pro-suite` now emit a warning only. Remove them from automation; final removal planned for the next major release.

---

## 10. Uninstall

```bash
sudo bin/uninstall-hakpak.sh --force
# Optional hard clean
sudo rm -rf /usr/local/bin/hakpak /usr/share/hakpak /opt/hakpak \
  /var/lib/hakpak /etc/hakpak ~/.config/hakpak
```

---

## 11. Operational Patterns

| Scenario | Steps |
|----------|-------|
| Fresh consultant laptop | Clone → install → self-test → essential batch |
| Ephemeral cloud node | Cloud-init triggers clone & install; run essential batch |
| Air-gapped | Pre-stage package mirror; run install with local sources |
| Rapid rebuild | Keep repo cached; rerun install (minutes) |

---

## 12. FAQ

**Does it phone home?** No – only standard APT traffic.

**Unlimited machines?** Yes – MIT licensed.

**Non-root usage?** Install operations need root; read-only queries may expand later.

**Package rename?** Self-test flags missing packages for mapping updates.

**Activation?** Not required; legacy commands are inert.

---

## 13. Roadmap (Indicative)

| Phase | Candidates |
|-------|-----------|
| Short Term | Kali key fingerprint assertion; extended self-test report |
| Mid Term | JSON status/export; profile diffing |
| Long Term | Pluggable signed module registry; remove legacy licensing code |

---

## 14. Support & Contact

- Email: owner@phanesguild.llc
- Website: [https://www.phanesguild.llc](https://www.phanesguild.llc)
- GitHub: [https://github.com/PhanesGuildSoftware](https://github.com/PhanesGuildSoftware)
- Discord: PhanesGuildSoftware

Commercial support offerings may appear separately; core remains open source.

---

## 15. Legal & Ethical Use

Use only on systems you own or have explicit written authorization to test. You accept responsibility for compliance with applicable laws. No liability assumed for misuse.

Key Principles: Authorization • Privacy Respect • Responsible Disclosure • Documentation Discipline.

License: MIT. Prior proprietary licensing is sunset.

---

## 16. At a Glance

| Category | Summary |
|----------|---------|
| Purpose | Rapid, repeatable provisioning of curated security tools |
| Core Tools | 15 essential offensive / diagnostic utilities |
| Former Pro Adds | Suite orchestration, enriched status, self-test |
| Security | No telemetry; controlled repo integration |
| Speed | Baseline ready in minutes |
| Uninstall | Clean removal script available |
| Activation | Not required |

---

## 17. Publication Guidance

1. Keep Hero + Quick Start prominent.
2. Collapse FAQ & Roadmap if space constrained.
3. Keep Legal & Ethical Use visible.
4. Replace old purchase CTAs with contribution / support guidance.

---

End of Document
