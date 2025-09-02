# Contributing to HakPak

Thanks for your interest in improving HakPak! This guide explains how to propose changes, add tools, report issues, and help maintain quality.

---

## 🔍 Philosophy

HakPak focuses on:

- Reliable, repeatable installs on production-friendly distros
- Minimal, high‑value tool set (quality over quantity)
- Predictable, auditable Bash
- Zero licensing / telemetry overhead (fully MIT open source)

Additions must strengthen one of: stability, clarity, maintainability, or essential capability.

---

## 🧪 Quick Start (Development)

```bash
# Fork + clone your fork
 git clone https://github.com/<your-user>/hakpak.git
 cd hakpak

# (Optional) Run a packaging dry build
 ./scripts/package-release.sh

# Run main script in help mode
 ./hakpak.sh --help
```

Use an Ubuntu 24.04 (or Debian 12) environment for validation. Containers / WSL are fine for most changes.

---

## 🧱 Project Structure (Key Paths)

| Path | Purpose |
|------|---------|
| `hakpak.sh` | Main CLI / installer logic |
| `bin/` | Legacy install wrappers & desktop helpers |
| `scripts/` | Release packaging & smoke helpers |
| `assets/` | Branding / logos |
| `admin/` | (Future) admin / service side experiments |
| `README.md` | Primary user documentation |
| `LICENSE` | MIT license |

---

## 🗂 Branch & PR Flow

1. Create a feature branch: `feature/<short-topic>` or `fix/<issue-id>`
2. Commit logically grouped changes (see commit style below)
3. Rebase on latest `main` if needed (avoid merge commits)
4. Run basic QA (see below)
5. Open a Pull Request (PR) with:
   - Problem statement
   - Summary of changes
   - Testing notes
   - Screenshots (if UI / output changes)
6. Await review; incorporate feedback via additional commits (no squashing until approval)

Protected expectations (even if not yet enforced in CI):

- No secrets committed
- No external network calls during install unless explicitly necessary for package retrieval
- No licensing / telemetry logic reintroduced

---

## 📝 Commit Message Style (Conventional Commits)

Use prefixes:

- `feat:` new user‑visible capability
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` code restructuring (no behavior change)
- `perf:` performance improvement
- `build:` packaging / release scripting
- `ci:` continuous integration adjustments
- `chore:` misc / maintenance
- `test:` (future) test scaffolding

Examples:

```text
feat: add gobuster to selectable install tools
fix: guard repo setup when sources list already present
build: add sbom generation step to packaging script
```

---

## 🧪 Quality Checklist (Pre-PR)

Before opening / updating a PR:

- `./hakpak.sh --help` exits 0
- Installation dry run succeeds on a clean Ubuntu 24.04 container / VM
- `scripts/package-release.sh` produces an archive without errors
- Added tool names appear in help output (if applicable)
- README updated for user-facing changes
- Version bumped only if release‑worthy (see versioning)

Optional (if available locally):

- Run `shellcheck hakpak.sh` and address warnings where practical (never sacrifice clarity for micro‑style purity)

---

## 🧵 Bash Style Guidelines

- Shebang: `#!/usr/bin/env bash`
- Set safe defaults near top: `set -euo pipefail` (or explicit error handling wrappers)
- Quote all variable expansions unless word splitting is intentional
- Prefer `local var` inside functions
- Use uppercase for readonly constants: `readonly HAKPAK_VERSION="1.1.0"`
- Functions: `snake_case`, verbs first (e.g. `install_nmap`, `show_status_panel`)
- Avoid subshells in tight loops when simple parameter expansion works
- Keep functions focused; extract long case arms (> ~25 lines)

---

## ➕ Adding a New Tool

1. Validate the package exists in Kali or base repos
2. Confirm install won’t auto-pull massive dependency chains unless justified
3. Add install logic (or extend a category function) in `hakpak.sh`
4. Update usage/help output if new flags or categories apply
5. Update README (Included Tools section)
6. Consider adding to a curated “essential” group only if broadly useful
7. If tool introduces large external services (DBs, frameworks), open an issue first for discussion

Avoid adding niche, unstable, or GUI-heavy tools without clear justification.

---

## 🔢 Versioning (Semantic)

- Patch (x.y.Z): docs / minor fixes / internal refactors
- Minor (x.Y.z): new tools, notable features, deprecations
- Major (X.y.z): removals / breaking flag changes / structural shifts

Only bump in the same PR if you intend to cut a release soon after. Otherwise leave version unchanged.

---

## 🚀 Release Process (Manual for now)

```bash
# Ensure working tree clean, on main
scripts/package-release.sh            # builds dist/hakpak-vX.Y.Z.tar.gz
sha256sum dist/hakpak-vX.Y.Z.tar.gz > dist/hakpak-vX.Y.Z.sha256
# (optional) zip created automatically if 'zip' installed
# Tag & push
git tag vX.Y.Z
git push origin vX.Y.Z
# Draft GitHub Release attaching tar.gz, zip, sha256 file
```

Include summary, highlights, and any deprecation reminders.

---

## 🛡 Security & Responsible Use

HakPak itself is an installer/orchestrator. If you discover a security issue (e.g. command injection vector, unsafe file permission handling) DO NOT open a public issue first. Instead email: `owner@phanesguild.llc` with details and reproduction steps.

---

## 📄 Legal / Licensing

HakPak is MIT licensed. Do not introduce code that restricts usage or adds phoning-home behavior. Any third-party snippet must be MIT-compatible and attributed if required.

---

## 🧪 Future Testing Direction (Planned)

- Lightweight shell test harness for argument parsing
- Mocked repository configuration tests
- Cross-distro smoke via container matrix (GitHub Actions)

Contributors interested in bootstrapping this are very welcome—open an issue to coordinate.

---

## 🤝 Communication

- Feature proposals: GitHub Issues (`enhancement` label)
- Roadmap debates: Discussions
- Security: Private email (see above)
- Larger refactors: Draft PR early for alignment

---

## ✅ PR Acceptance Criteria (Summary)

- Clear problem & solution statement
- Fits scope & philosophy
- No regression in core flows (`--install`, `--status`, repo setup)
- Docs updated where user impact exists
- Clean diff (unrelated whitespace churn avoided)

---

## 🧹 Anti-Goals

These will typically be declined unless a compelling case is made:

- Bundling extremely niche / overlapping tools without broad demand
- Adding heavy language runtimes unnecessarily
- Reintroducing license enforcement or telemetry
- Obscuring install steps behind opaque wrappers

---

## ❤️ Thank You

Every improvement—small or large—helps make security operations faster and cleaner for others. Your time and expertise are appreciated.

Forge wisely. Strike precisely.
