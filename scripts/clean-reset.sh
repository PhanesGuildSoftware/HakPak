#!/usr/bin/env bash
# HakPak Clean Reset & (Optional) Reinstall Helper
# Purpose: Automate full removal of a previous HakPak install + optional fresh reinstall.
# Safe defaults: does NOT auto-download or reinstall unless --auto-install specified.
#
# Usage:
#   sudo scripts/clean-reset.sh [options]
#
# Options:
#   --auto-install            After cleanup, fetch and install HakPak automatically
#   --source <release|git>    When auto-installing: choose release tarball or git clone (default: release)
#   --version <X.Y.Z>         Release version to fetch (default: 1.1.0)
#   --purge-cache             Run apt autoremove/autoclean/clean after removal
#   --remove-toolkits         Delete any custom toolkits under /var/lib/hakpak/toolkits
#   --keep-logs               Preserve /var/log/hakpak.log (default is remove)
#   --force                   Skip confirmation prompt
#   --quiet                   Suppress non-essential output
#   --help                    Show help
#
# Examples:
#   sudo scripts/clean-reset.sh --force
#   sudo scripts/clean-reset.sh --auto-install --source git --force
#   sudo scripts/clean-reset.sh --auto-install --version 1.1.0 --purge-cache --remove-toolkits --force
#
set -euo pipefail

VERSION_DEFAULT="1.1.0"
CHOICE_SOURCE="release"
CHOICE_VERSION="$VERSION_DEFAULT"
AUTO_INSTALL=0
PURGE_CACHE=0
REMOVE_TOOLKITS=0
KEEP_LOGS=0
FORCE=0
QUIET=0

log() { [[ $QUIET -eq 1 ]] || echo -e "$1"; }
info() { log "[INFO] $1"; }
success() { log "[ OK ] $1"; }
warn() { log "[WARN] $1"; }
error() { echo "[ERR ] $1" >&2; }

die() { error "$1"; exit 1; }

show_help() { grep '^# ' "$0" | sed 's/^# \{0,1\}//'; }

require_root() { [[ $EUID -eq 0 ]] || die "Run as root (sudo)."; }

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --auto-install) AUTO_INSTALL=1 ; shift ;;
            --source) CHOICE_SOURCE="${2:-}"; shift 2 ;;
            --version) CHOICE_VERSION="${2:-}"; shift 2 ;;
            --purge-cache) PURGE_CACHE=1 ; shift ;;
            --remove-toolkits) REMOVE_TOOLKITS=1 ; shift ;;
            --keep-logs) KEEP_LOGS=1 ; shift ;;
            --force) FORCE=1 ; shift ;;
            --quiet) QUIET=1 ; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

confirm() {
    local prompt="$1"; shift || true
    if [[ $FORCE -eq 1 ]]; then
        return 0
    fi
    read -rp "$prompt [y/N]: " ans
    [[ $ans =~ ^[Yy]$ ]]
}

remove_binary_links() {
    for p in /usr/local/bin/hakpak /usr/bin/hakpak; do
        if [[ -f $p || -L $p ]]; then
            rm -f "$p" && success "Removed binary link: $p" || warn "Failed to remove $p"
        fi
    done
}

remove_repo_and_pins() {
    local removed=0
    for f in /etc/apt/sources.list.d/kali.list /etc/apt/preferences.d/kali.pref /etc/apt/preferences.d/ubuntu-stability.pref /etc/apt/trusted.gpg.d/kali-archive.gpg; do
        if [[ -f $f ]]; then rm -f "$f" && ((removed++)); fi
    done
    if [[ $removed -gt 0 ]]; then success "Removed Kali repository + pin files"; else info "No Kali repo artifacts found"; fi
}

remove_state_dirs() {
    [[ -d /var/lib/hakpak ]] && rm -rf /var/lib/hakpak && success "Removed /var/lib/hakpak" || info "No /var/lib/hakpak directory"
    if [[ $REMOVE_TOOLKITS -eq 1 ]]; then
        [[ -d /var/lib/hakpak/toolkits ]] && rm -rf /var/lib/hakpak/toolkits && success "Removed custom toolkits" || true
    fi
    if [[ $KEEP_LOGS -eq 0 ]]; then
        [[ -f /var/log/hakpak.log ]] && rm -f /var/log/hakpak.log && success "Removed log file" || true
    else
        info "Preserving log file (/var/log/hakpak.log)"
    fi
}

apt_cleanup() {
    if [[ $PURGE_CACHE -eq 1 ]]; then
        info "Running apt cleanups (autoremove/autoclean/clean)" || true
        apt-get autoremove -y >/dev/null 2>&1 || true
        apt-get autoclean -y >/dev/null 2>&1 || true
        apt-get clean -y >/dev/null 2>&1 || true
    fi
    apt-get update -o Acquire::Retries=2 >/dev/null 2>&1 || warn "apt-get update encountered issues"
}

uninstall_legacy_script() {
    if command -v hakpak >/dev/null 2>&1; then
        if [[ -x ./bin/uninstall-hakpak.sh ]]; then
            info "Running bundled uninstaller"; ./bin/uninstall-hakpak.sh || warn "Bundled uninstaller returned non-zero"
        else
            info "No bundled uninstaller found, proceeding with manual cleanup"
        fi
    else
        info "hakpak binary not in PATH (skipping bundled uninstall)"
    fi
}

download_release() {
    local url="https://releases.phanesguild.llc/hakpak-v${CHOICE_VERSION}.tar.gz"
    info "Fetching release: $url"
    curl -fSL "$url" -o "hakpak-v${CHOICE_VERSION}.tar.gz" || die "Release download failed"
    tar -xzf "hakpak-v${CHOICE_VERSION}.tar.gz" || die "Extraction failed"
    cd hakpak* || die "Extracted directory not found"
}

clone_git() {
    info "Cloning git repository (main branch)"
    git clone https://github.com/PhanesGuildSoftware/hakpak.git hakpak-latest || die "Git clone failed"
    cd hakpak-latest || die "Clone directory missing"
}

perform_install() {
    info "Installing HakPak (--install)"
    ./hakpak.sh --install || die "Install step failed"
    success "HakPak installed successfully"
    success "Run: sudo hakpak --status && sudo hakpak --self-test"
}

main_flow() {
    require_root
    parse_args "$@"

    info "HakPak Clean Reset Starting"

    if ! confirm "Proceed with full cleanup of existing HakPak installation?"; then
        warn "Aborted by user"
        exit 1
    fi

    uninstall_legacy_script
    remove_binary_links
    remove_repo_and_pins
    remove_state_dirs
    apt_cleanup

    success "Cleanup phase complete"

    if [[ $AUTO_INSTALL -eq 1 ]]; then
        info "Auto-install enabled"
        workdir=$(mktemp -d)
        pushd "$workdir" >/dev/null || die "Failed to enter temp dir"
        case "$CHOICE_SOURCE" in
            release) download_release ;;
            git) clone_git ;;
            *) die "Invalid source: $CHOICE_SOURCE (use release|git)" ;;
        esac
        perform_install
        popd >/dev/null || true
        info "Temporary workspace: $workdir (not removed for inspection)"
    else
        info "Auto-install not requested. You may now fetch a fresh copy manually."
    fi

    success "Reset complete."
}

main_flow "$@"
