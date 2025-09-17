#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import platform
import argparse
import json
from pathlib import Path

try:
    import yaml  # type: ignore
except Exception:
    yaml = None

HAKPAK2_ROOT = Path(os.environ.get("HAKPAK2_ROOT", "/opt/hakpak2")).resolve()
TOOLS_MAP_PATH = Path(__file__).parent / "tools-map.yaml"
BIN_LINK_DIR = Path(os.environ.get("HAKPAK2_BIN", "/usr/local/bin"))


class Shell:
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    def run(self, cmd: list[str], check: bool = True, capture: bool = False):
        if self.dry_run:
            print(f"[dry-run] $ {' '.join(cmd)}")
            return subprocess.CompletedProcess(cmd, 0, b"", b"")
        if capture:
            return subprocess.run(cmd, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return subprocess.run(cmd, check=check)

    def which(self, name: str) -> str | None:
        return shutil.which(name)


def read_os_release() -> dict:
    data = {}
    try:
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    k, v = line.split('=', 1)
                    data[k] = v.strip('"')
    except FileNotFoundError:
        pass
    return data


def detect_pm(shell: Shell) -> str:
    # Priority by distro, but fall back to available command
    osr = read_os_release()
    pm_order = []
    distro_id = osr.get("ID", "").lower()
    if distro_id in ("ubuntu", "debian", "raspbian", "linuxmint", "pop"):
        pm_order = ["apt"]
    elif distro_id in ("fedora", "rhel", "centos", "rocky", "almalinux"):
        pm_order = ["dnf", "yum"]
    elif distro_id in ("arch", "manjaro"):
        pm_order = ["pacman"]
    elif distro_id in ("opensuse", "opensuse-tumbleweed", "sles"):
        pm_order = ["zypper"]
    else:
        pm_order = ["apt", "dnf", "yum", "pacman", "zypper"]

    for pm in pm_order:
        if shell.which(pm):
            return pm
    # Last resort: try to guess by presence of files
    if Path("/etc/debian_version").exists():
        return "apt"
    raise SystemExit("No supported package manager found (apt/dnf/pacman/zypper)")


def load_tools_map() -> dict:
    if yaml is None:
        raise SystemExit("PyYAML is required. Install with: pip install pyyaml")
    if not TOOLS_MAP_PATH.exists():
        raise SystemExit(f"tools map not found: {TOOLS_MAP_PATH}")
    with open(TOOLS_MAP_PATH, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def ensure_root():
    if os.geteuid() != 0:
        raise SystemExit("This command must be run as root (sudo)")


def apt_install(shell: Shell, pkgs: list[str]):
    shell.run(["apt", "update", "-y"])  # tolerant across derivatives
    shell.run(["apt", "install", "-y", "--no-install-recommends", *pkgs])


def dnf_install(shell: Shell, pkgs: list[str]):
    shell.run(["dnf", "-y", "install", *pkgs])


def pacman_install(shell: Shell, pkgs: list[str]):
    shell.run(["pacman", "-Sy", "--noconfirm"])
    shell.run(["pacman", "-S", "--noconfirm", *pkgs])


def zypper_install(shell: Shell, pkgs: list[str]):
    shell.run(["zypper", "--non-interactive", "refresh"])
    shell.run(["zypper", "--non-interactive", "install", "--no-recommends", *pkgs])


PM_INSTALLERS = {
    "apt": apt_install,
    "dnf": dnf_install,
    "yum": dnf_install,  # treat as dnf
    "pacman": pacman_install,
    "zypper": zypper_install,
}


def link_binary(src: Path, name: str):
    BIN_LINK_DIR.mkdir(parents=True, exist_ok=True)
    dst = BIN_LINK_DIR / name
    if dst.exists() or dst.is_symlink():
        try:
            if dst.is_symlink() or dst.is_file():
                dst.unlink()
        except Exception:
            pass
    os.chmod(src, 0o755)
    dst.symlink_to(src)
    print(f"[✓] Linked {dst} -> {src}")


def go_install(shell: Shell, module: str, bin_name: str):
    if not shell.which("go"):
        pm = detect_pm(shell)
        print(f"[i] Installing Go toolchain via {pm}…")
        PM_INSTALLERS[pm](shell, ["golang", "golang-go"] if pm == "apt" else ["golang"])
    gopath = os.environ.get("GOPATH") or str(Path.home() / "go")
    bin_dir = Path(gopath) / "bin"
    shell.run(["go", "install", f"{module}@latest"])
    candidate = bin_dir / bin_name
    if not candidate.exists():
        raise SystemExit(f"go install did not produce {candidate}")
    target = HAKPAK2_ROOT / "bin" / bin_name
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(candidate, target)
    link_binary(target, bin_name)


def git_clone_update(url: str, dest: Path, shell: Shell):
    if dest.exists():
        shell.run(["git", "-C", str(dest), "pull", "--ff-only"])
    else:
        shell.run(["git", "clone", "--depth", "1", url, str(dest)])


def python_project_install(repo_url: str, entry: str, shell: Shell):
    # entry is the command to create a shim for (python script or module)
    ensure_root()
    src_dir = HAKPAK2_ROOT / "src" / Path(repo_url).stem
    git_clone_update(repo_url, src_dir, shell)
    # try pip in editable or standard mode into system (or venv in future)
    pip = shell.which("pip3") or shell.which("pip")
    if not pip:
        pm = detect_pm(shell)
        PM_INSTALLERS[pm](shell, ["python3-pip" if pm == "apt" else "python-pip"])
        pip = shell.which("pip3") or shell.which("pip")
    shell.run([pip, "install", "-r", str(src_dir / "requirements.txt")]) if (src_dir / "requirements.txt").exists() else None
    # Create shim that executes the repo entry
    shim_target = HAKPAK2_ROOT / "bin" / entry
    shim_target.parent.mkdir(parents=True, exist_ok=True)
    content = f"#!/usr/bin/env bash\nexec python3 '{src_dir}/{entry}' \"$@\"\n"
    shim_target.write_text(content, encoding="utf-8")
    link_binary(shim_target, entry)


def load_state() -> dict:
    state_path = HAKPAK2_ROOT / "state.json"
    if state_path.exists():
        return json.loads(state_path.read_text())
    return {"installed": {}}


def save_state(state: dict):
    HAKPAK2_ROOT.mkdir(parents=True, exist_ok=True)
    (HAKPAK2_ROOT / "state.json").write_text(json.dumps(state, indent=2))


def cmd_detect(args):
    osr = read_os_release()
    shell = Shell()
    pm = detect_pm(shell)
    print("Distribution:", osr.get("PRETTY_NAME", platform.platform()))
    print("Package manager:", pm)


def cmd_list(args):
    tools = load_tools_map().get("tools", {})
    for name, spec in sorted(tools.items()):
        methods = []
        if any(k in spec.get("packages", {}) for k in ("apt", "dnf", "pacman", "zypper")):
            methods.append("native")
        if "source" in spec:
            methods.append("source")
        print(f"{name}: methods={','.join(methods) or 'unknown'}")


def cmd_status(args):
    state = load_state()
    installed = state.get("installed", {})
    if not installed:
        print("No tools installed yet.")
        return
    for name, meta in installed.items():
        print(f"{name}: method={meta.get('method')} at={meta.get('path')}")


def install_native(shell: Shell, pm: str, name: str, spec: dict):
    pkgs_map = spec.get("packages", {})
    pkg = pkgs_map.get(pm)
    if not pkg:
        raise SystemExit(f"No native package mapping for {name} on {pm}")
    PM_INSTALLERS[pm](shell, [pkg])
    # assume binary available equals name, optionally override later with spec
    binary = spec.get("binary", name)
    if not shutil.which(binary):
        # As last attempt, check candidate paths
        candidate = Path(f"/usr/bin/{binary}")
        if not candidate.exists():
            print(f"[!] Installed {pkg} but binary '{binary}' not found in PATH")
    return {"method": "native", "path": shutil.which(binary) or f"/usr/bin/{binary}"}


def install_source(shell: Shell, name: str, spec: dict):
    src = spec.get("source", {})
    kind = src.get("type")
    if kind == "go":
        module = src["module"]
        bin_name = spec.get("binary", name)
        go_install(shell, module, bin_name)
        return {"method": "source-go", "path": str(BIN_LINK_DIR / bin_name)}
    if kind == "python-git":
        repo = src["repo"]
        entry = spec.get("binary", name)
        python_project_install(repo, entry, shell)
        return {"method": "source-python", "path": str(BIN_LINK_DIR / entry)}
    raise SystemExit(f"Unsupported source type for {name}: {kind}")


def cmd_install(args):
    ensure_root()
    shell = Shell(dry_run=args.dry_run)
    pm = detect_pm(shell)
    tools = load_tools_map().get("tools", {})
    name = args.tool
    if name not in tools:
        raise SystemExit(f"Unknown tool: {name}. Try 'hakpak2 list'.")
    spec = tools[name]

    method = args.method
    if method == "auto":
        method = "native" if pm in spec.get("packages", {}) else ("source" if "source" in spec else None)
        if not method:
            raise SystemExit(f"No install method for {name} on this system")

    state = load_state()

    if method == "native":
        meta = install_native(shell, pm, name, spec)
    elif method == "source":
        meta = install_source(shell, name, spec)
    else:
        raise SystemExit("method must be auto|native|source")

    if not args.dry_run:
        state.setdefault("installed", {})[name] = meta
        save_state(state)
        print(f"[✓] Installed {name} via {meta['method']}")
    else:
        print(f"[dry-run] Would install {name} via {method}")


def uninstall_native(shell: 'Shell', pm: str, name: str, spec: dict):
    pkgs_map = spec.get("packages", {})
    pkg = pkgs_map.get(pm)
    if not pkg:
        print(f"[!] No native mapping for {name} on {pm}")
        return
    if pm == 'apt':
        shell.run(["apt", "remove", "-y", pkg])
        shell.run(["apt", "autoremove", "-y"])  # optional cleanup
    elif pm in ('dnf', 'yum'):
        shell.run([pm, "-y", "remove", pkg])
    elif pm == 'pacman':
        shell.run(["pacman", "-Rns", "--noconfirm", pkg])
    elif pm == 'zypper':
        shell.run(["zypper", "--non-interactive", "remove", pkg])


def uninstall_source(name: str, spec: dict):
    binary = spec.get("binary", name)
    link = BIN_LINK_DIR / binary
    try:
        if link.is_symlink() or link.exists():
            link.unlink()
            print(f"[✓] Unlinked {link}")
    except Exception as e:
        print(f"[!] Could not unlink {link}: {e}")
    # Remove internal built binary/shim
    local_bin = HAKPAK2_ROOT / "bin" / binary
    try:
        if local_bin.exists():
            local_bin.unlink()
            print(f"[✓] Removed {local_bin}")
    except Exception as e:
        print(f"[!] Could not remove {local_bin}: {e}")
    # Leave sources in /opt/hakpak2/src for now (keeps clones cached)


def cmd_uninstall(args):
    ensure_root()
    shell = Shell()
    pm = detect_pm(shell)
    tools = load_tools_map().get("tools", {})
    name = args.tool
    if name not in tools:
        raise SystemExit(f"Unknown tool: {name}")
    spec = tools[name]

    state = load_state()
    meta = state.get("installed", {}).get(name)
    if not meta:
        print("[i] Not recorded as installed; attempting best-effort removal…")

    # Try to remove both sides based on availability/method
    method = (meta or {}).get("method")
    if method == "native" or (pm in spec.get("packages", {})):
        uninstall_native(shell, pm, name, spec)
    if method and method.startswith("source") or ("source" in spec):
        uninstall_source(name, spec)

    # Update state
    if name in state.get("installed", {}):
        del state["installed"][name]
        save_state(state)
        print(f"[✓] Uninstalled {name}")
    else:
        print("[i] No state entry to update.")


def build_parser():
    p = argparse.ArgumentParser(prog="hakpak2", description="HakPak v2 — Cross-distro dependency handler")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("detect", help="Show detected distro and package manager").set_defaults(func=cmd_detect)
    sub.add_parser("list", help="List known tools").set_defaults(func=cmd_list)
    sub.add_parser("status", help="Show install status").set_defaults(func=cmd_status)

    pi = sub.add_parser("install", help="Install a tool")
    pi.add_argument("tool", help="Tool name (see 'list')")
    pi.add_argument("--method", choices=["auto", "native", "source"], default="auto")
    pi.add_argument("--dry-run", action="store_true")
    pi.set_defaults(func=cmd_install)

    pu = sub.add_parser("uninstall", help="Uninstall a tool")
    pu.add_argument("tool", help="Tool name (see 'list')")
    pu.set_defaults(func=cmd_uninstall)

    # Repo management (apt-based only)
    pr = sub.add_parser("repo", help="Manage optional Kali repo (apt only)")
    pr_sub = pr.add_subparsers(dest="repo_cmd", required=True)
    pra = pr_sub.add_parser("add", help="Add Kali repo with safe pinning")
    pra.set_defaults(func=cmd_repo_add)
    prr = pr_sub.add_parser("remove", help="Remove Kali repo and pinning")
    prr.set_defaults(func=cmd_repo_remove)
    prs = pr_sub.add_parser("status", help="Show repo status")
    prs.set_defaults(func=cmd_repo_status)

    return p


def cmd_repo_add(args):
    ensure_root()
    shell = Shell()
    pm = detect_pm(shell)
    if pm != "apt":
        raise SystemExit("Repo management supported on apt-based systems only")
    # ensure tools
    if not shell.which("curl") or not shell.which("gpg"):
        PM_INSTALLERS[pm](shell, ["curl", "gnupg", "ca-certificates"])
    # Keyring and sources
    key_url = "https://archive.kali.org/archive-key.asc"
    keyring = Path("/usr/share/keyrings/kali-archive-keyring.gpg")
    if not keyring.exists():
        shell.run(["curl", "-fsSL", key_url, "-o", "/tmp/kali.key"])
        shell.run(["gpg", "--dearmor", "/tmp/kali.key"])
        shell.run(["install", "-Dm644", "/tmp/kali.key.gpg", str(keyring)])
    list_path = Path("/etc/apt/sources.list.d/kali.list")
    list_path.write_text("deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware\n")
    pref_path = Path("/etc/apt/preferences.d/kali.pref")
    pref_path.write_text(
        """Package: *\nPin: release o=Kali\nPin-Priority: 100\n\nPackage: kali-archive-keyring\nPin: release o=Kali\nPin-Priority: 1000\n"""
    )
    subprocess.run(["apt", "update"], check=False)
    print("[✓] Kali repo added with safe pinning (low priority)")


def cmd_repo_remove(args):
    shell = Shell()
    pm = detect_pm(shell)
    if pm != "apt":
        raise SystemExit("Repo management supported on apt-based systems only")
    for p in (Path("/etc/apt/sources.list.d/kali.list"), Path("/etc/apt/preferences.d/kali.pref")):
        try:
            p.unlink()
        except FileNotFoundError:
            pass
    subprocess.run(["apt", "update"], check=False)
    print("[✓] Kali repo removed")


def cmd_repo_status(args):
    # Show whether source + pinning exist, and policy header
    exists = Path("/etc/apt/sources.list.d/kali.list").exists()
    pinned = Path("/etc/apt/preferences.d/kali.pref").exists()
    print(f"source: {'present' if exists else 'absent'}; pinning: {'present' if pinned else 'absent'}")
    subprocess.run(["apt-cache", "policy"], check=False)


def main(argv: list[str]) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        args.func(args)
        return 0
    except SystemExit as e:
        raise
    except KeyboardInterrupt:
        print("Interrupted", file=sys.stderr)
        return 130
    except Exception as e:
        print(f"[error] {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
