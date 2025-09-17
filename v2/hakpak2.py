#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil
import platform
import argparse
import json
from pathlib import Path
from typing import Tuple

try:
    import yaml  # type: ignore
except Exception:
    yaml = None

HAKPAK2_ROOT = Path(os.environ.get("HAKPAK2_ROOT", "/opt/hakpak2")).resolve()
TOOLS_MAP_PATH = Path(__file__).parent / "tools-map.yaml"
BIN_LINK_DIR = Path(os.environ.get("HAKPAK2_BIN", "/usr/local/bin"))
VERSION = "2025.09.17"


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


def banner() -> str:
    return (
        "\n"
        "\x1b[1;32m██╗  ██╗ █████╗ ██╗  ██╗██████╗  █████╗ ██╗  ██╗\x1b[0m\n"
        "\x1b[1;32m██║  ██║██╔══██╗██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝\x1b[0m\n"
        "\x1b[1;32m███████║███████║█████╔╝ ██████╔╝███████║█████╔╝ \x1b[0m\n"
        "\x1b[1;32m██╔══██║██╔══██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗ \x1b[0m\n"
        "\x1b[1;32m██║  ██║██║  ██║██║  ██╗██║     ██║  ██║██║  ██╗\x1b[0m\n"
        "\x1b[34m╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝\x1b[0m\n"
    )


def disclaimer() -> str:
    return (
        "\n"
        "Use these tools only on systems you own or have\n"
        "explicit, written permission to test. Unauthorized use\n"
        "may be illegal. You accept full responsibility.\n"
    )


def developer_info() -> str:
    return (
        "\n"
        "HakPak v2 — Cross‑distro dependency handler\n"
        "\n"
        "Developers:\n"
        "  - Creator: Teyvone Wells\n"
        "  - Company: PhanesGuild Software LLC\n"
        "\n"
        "Contact:\n"
        "  - Email: owner@phanesguild.llc\n"
        "  - GitHub: https://github.com/PhanesGuildSoftware\n"
    )


def cmd_about(args=None):
    print(banner())
    print(developer_info())
    print(disclaimer())


def menu_print_header(shell: 'Shell'):
    osr = read_os_release()
    pm = detect_pm(shell)
    print(banner())
    print("Distribution:", osr.get("PRETTY_NAME", platform.platform()))
    print("Package manager:", pm)
    print("Options:\n  1) List tools\n  2) Install Tools (multi)\n  3) Uninstall Tools (multi)\n  4) Status\n  5) Repo (apt): add/status/remove\n  6) About\n  0) Exit")
    print("\nTip: Press Enter to refresh menu. Use 0 to exit.")


def cmd_menu(args=None):
    shell = Shell()
    while True:
        menu_print_header(shell)
        try:
            choice = input("Your choice: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye.")
            return 0
        # Empty input or 'm' just refreshes the menu without noise
        if choice == '' or choice.lower() == 'm':
            continue
        if choice.lower() == 'q':
            print("Bye.")
            return 0
        if choice == '1':
            cmd_list(argparse.Namespace())
        elif choice == '2':
            tools_map = load_tools_map().get("tools", {})
            names = sorted(list(tools_map.keys()))
            print("\nAvailable tools (comma or space separated). Type 'all' to install everything:")
            print(" ".join(names))
            raw = input("Enter tools to install: ").strip()
            if not raw:
                print("No tools entered.")
                continue
            # 'all' installs everything
            if raw.lower() == 'all':
                parts = names
            else:
                # split by commas and spaces
                parts = [p.strip() for chunk in raw.split(',') for p in chunk.split() if p.strip()]
            method = input("Method [auto|native|source] (default auto): ").strip() or 'auto'
            for name in parts:
                if name not in tools_map:
                    print(f"[!] Unknown tool: {name} (skipping)")
                    continue
                try:
                    cmd_install(argparse.Namespace(tool=name, method=method, dry_run=False))
                except SystemExit as e:
                    print(f"[!] Failed {name}: {e}")
                    continue
        elif choice == '3':
            st = load_state().get('installed', {})
            if st:
                print("\nInstalled tools:")
                print(" ".join(sorted(st.keys())))
            raw = input("Enter tools to uninstall (comma/space separated): ").strip()
            if not raw:
                print("No tools entered.")
                continue
            parts = [p.strip() for chunk in raw.split(',') for p in chunk.split() if p.strip()]
            for name in parts:
                try:
                    cmd_uninstall(argparse.Namespace(tool=name))
                except SystemExit as e:
                    print(f"[!] Failed {name}: {e}")
        elif choice == '4':
            cmd_status(argparse.Namespace())
        elif choice == '5':
            sub = input("repo action [add|status|remove]: ").strip()
            if sub == 'add': cmd_repo_add(argparse.Namespace())
            elif sub == 'status': cmd_repo_status(argparse.Namespace())
            elif sub == 'remove': cmd_repo_remove(argparse.Namespace())
            else: print("Unknown repo action")
        elif choice == '6':
            cmd_about(argparse.Namespace())
        elif choice == '0':
            print("Bye.")
            return 0
        else:
            print("Unknown option")
        input("\nPress Enter to continue...")

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
    try:
        shell.run(["env", "DEBIAN_FRONTEND=noninteractive", "apt", "install", "-y", "--no-install-recommends", *pkgs])
    except subprocess.CalledProcessError as e:
        rc = getattr(e, 'returncode', None)
        print("[i] apt install failed (rc=", rc, ") — retrying with --allow-downgrades…", sep='')
        shell.run(["env", "DEBIAN_FRONTEND=noninteractive", "apt", "install", "-y", "--allow-downgrades", "--no-install-recommends", *pkgs])


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
    # Install Python project from git into an isolated venv and create a shim
    ensure_root()
    name = Path(repo_url).stem
    src_dir = HAKPAK2_ROOT / "src" / name
    venv_dir = HAKPAK2_ROOT / "venv" / name
    git_clone_update(repo_url, src_dir, shell)
    pm = detect_pm(shell)
    # Ensure venv capability on apt; others typically ship venv in python3
    if pm == "apt":
        ensure_packages(shell, pm, ["python3-venv"])  # best-effort
    venv_dir.parent.mkdir(parents=True, exist_ok=True)
    # Create venv if missing
    if not (venv_dir / "bin" / "python").exists():
        shell.run(["python3", "-m", "venv", str(venv_dir)], check=True)
    py = str(venv_dir / "bin" / "python")
    # Upgrade pip tooling and install requirements if present
    shell.run([py, "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"], check=False)
    req = src_dir / "requirements.txt"
    if req.exists():
        # Write a patched requirements file replacing deprecated pycrypto with pycryptodome
        patched = src_dir / "requirements.hakpak2.txt"
        try:
            txt = req.read_text(encoding="utf-8", errors="ignore")
            # naive replace handles common forms like 'pycrypto' or 'pycrypto==2.6.1'
            txt = "\n".join(
                [
                    (line.replace("pycrypto==", "pycryptodome==").replace("pycrypto ", "pycryptodome ") if line.strip().startswith("pycrypto") else line)
                    for line in txt.splitlines()
                ]
            )
            # Also handle exact token pycrypto without version spec
            txt = "\n".join(["pycryptodome" if l.strip()=="pycrypto" else l for l in txt.splitlines()])
            patched.write_text(txt, encoding="utf-8")
            shell.run([py, "-m", "pip", "install", "-r", str(patched)], check=True)
        except Exception:
            # fallback to original requirements
            shell.run([py, "-m", "pip", "install", "-r", str(req)], check=True)
    # Create shim that executes the repo entry inside the venv
    shim_target = HAKPAK2_ROOT / "bin" / entry
    shim_target.parent.mkdir(parents=True, exist_ok=True)
    content = (
        f"#!/usr/bin/env bash\n"
        f"VENV=\"{venv_dir}\"\n"
        f"exec \"$VENV/bin/python\" '{src_dir}/{entry}' \"$@\"\n"
    )
    shim_target.write_text(content, encoding="utf-8")
    os.chmod(shim_target, 0o755)
    link_binary(shim_target, entry)


def git_bash_install(repo_url: str, entry: str, bin_name: str, shell: Shell):
    ensure_root()
    src_dir = HAKPAK2_ROOT / "src" / Path(repo_url).stem
    git_clone_update(repo_url, src_dir, shell)
    shim_target = HAKPAK2_ROOT / "bin" / bin_name
    shim_target.parent.mkdir(parents=True, exist_ok=True)
    content = f"#!/usr/bin/env bash\nexec bash '{src_dir}/{entry}' \"$@\"\n"
    shim_target.write_text(content, encoding="utf-8")
    link_binary(shim_target, bin_name)


def ensure_packages(shell: 'Shell', pm: str, pkgs: list[str]):
    try:
        PM_INSTALLERS[pm](shell, pkgs)
    except Exception as e:
        print(f"[i] Package install best-effort failed for {pkgs}: {e}")


def ruby_project_install(repo_url: str, entry: str, bin_name: str, shell: Shell):
    ensure_root()
    pm = detect_pm(shell)
    # Ensure git and ruby toolchain
    base_by_pm = {
        'apt': ["git", "ruby-full", "ruby-dev", "ruby-bundler", "build-essential", "pkg-config", "libffi-dev", "libreadline-dev", "zlib1g-dev", "libssl-dev"],
        'dnf': ["git", "ruby", "rubygems", "rubygem-bundler", "gcc", "gcc-c++", "make", "pkgconf-pkg-config", "libffi-devel", "readline-devel", "zlib-devel", "openssl-devel"],
        'yum': ["git", "ruby", "rubygems", "rubygem-bundler", "gcc", "gcc-c++", "make", "pkgconf-pkg-config", "libffi-devel", "readline-devel", "zlib-devel", "openssl-devel"],
        'pacman': ["git", "ruby", "ruby-bundler", "base-devel", "pkgconf", "libffi", "readline", "zlib", "openssl"],
        'zypper': ["git", "ruby", "rubygem-bundler", "gcc", "make", "pkgconf-pkg-config", "libffi-devel", "readline-devel", "zlib-devel", "libopenssl-devel"],
    }
    ensure_packages(shell, pm, base_by_pm.get(pm, ["git", "ruby"]))
    # Extra native build deps for specific projects (e.g., metasploit-framework)
    if "metasploit-framework" in repo_url:
        msf_deps_by_pm = {
            'apt': ["libyaml-dev", "libpq-dev", "libpcap-dev", "libsqlite3-dev"],
            'dnf': ["libyaml-devel", "postgresql-devel", "libpcap-devel", "sqlite-devel", "ruby-devel"],
            'yum': ["libyaml-devel", "postgresql-devel", "libpcap-devel", "sqlite-devel", "ruby-devel"],
            'pacman': ["libyaml", "postgresql-libs", "libpcap", "sqlite"],
            'zypper': ["libyaml-devel", "postgresql-devel", "libpcap-devel", "sqlite3-devel", "ruby-devel"],
        }
        ensure_packages(shell, pm, msf_deps_by_pm.get(pm, []))
    # Clone/update
    src_dir = HAKPAK2_ROOT / "src" / Path(repo_url).stem
    git_clone_update(repo_url, src_dir, shell)
    # Ensure bundler
    bundler = shell.which("bundle") or shell.which("bundler")
    if not bundler:
        gem = shell.which("gem")
        if gem:
            try:
                shell.run([gem, "install", "bundler"])
            except Exception:
                pass
        bundler = shell.which("bundle") or shell.which("bundler")
    # Install gems (vendor path)
    cmd = f"cd '{src_dir}' && bundle config set --local path vendor/bundle && bundle install --without development test"
    shell.run(["bash", "-lc", cmd], check=False)
    # Create shim
    shim_target = HAKPAK2_ROOT / "bin" / bin_name
    shim_target.parent.mkdir(parents=True, exist_ok=True)
    content = f"#!/usr/bin/env bash\ncd '{src_dir}'\nexec bundle exec {entry} \"$@\"\n"
    shim_target.write_text(content, encoding="utf-8")
    os.chmod(shim_target, 0o755)
    link_binary(shim_target, bin_name)


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
    if getattr(args, 'json', False):
        shell = Shell()
        pm = detect_pm(shell)
        out = []
        for name, spec in sorted(tools.items()):
            pkgs = spec.get("packages", {})
            native_avail = pm in pkgs
            methods = []
            if pkgs:
                methods.append("native")
            if "source" in spec:
                methods.append("source")
            out.append({"name": name, "methods": methods, "nativeAvailable": native_avail})
        print(json.dumps({"tools": out}))
    else:
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


def cmd_version(args):
    here = Path(__file__).resolve()
    print(f"HakPak v2 {VERSION}")
    print(f"Binary: {here}")
    try:
        tm = TOOLS_MAP_PATH.stat().st_mtime
        from datetime import datetime
        print("Tools map:", TOOLS_MAP_PATH, datetime.fromtimestamp(tm).isoformat(timespec='seconds'))
    except Exception:
        pass


def try_tool_invoke(binary: str, extra_paths: list[str] | None = None) -> Tuple[bool, str, int, list[str]]:
    """Attempt several safe invocations to validate a binary is runnable.
    Returns (ok, output, returncode, used_args).
    """
    candidates = [["--version"], ["-V"], ["-v"], ["-h"], ["--help"], []]
    env = os.environ.copy()
    if extra_paths:
        env["PATH"] = os.pathsep.join(extra_paths + [env.get("PATH", "")])
    for args in candidates:
        try:
            cp = subprocess.run([binary, *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=8, env=env)
            text = cp.stdout.decode(errors="ignore")
            # Consider success if exit 0 or typical help/version text present
            if cp.returncode == 0 or any(k in text.lower() for k in ("usage", "version", "help", "wireshark")):
                return True, text[:4000], cp.returncode, args
        except FileNotFoundError:
            return False, "not found", 127, args
        except subprocess.TimeoutExpired:
            return False, "timeout", 124, args
        except Exception as e:
            # try next pattern
            last = str(e)
            _ = last
            continue
    return False, "no successful invocation", 1, []


def cmd_test(args):
    tools = load_tools_map().get("tools", {})
    state = load_state()
    installed = state.get("installed", {})
    names = sorted(tools.keys()) if getattr(args, 'all', False) else sorted(installed.keys())
    results = []
    for name in names:
        spec = tools.get(name, {})
        binary = spec.get("binary", name)
        # Prefer PATH detection; otherwise use recorded path
        path = shutil.which(binary) or (installed.get(name, {}).get("path") if name in installed else None) or binary
        test_spec = spec.get("test", {}) if isinstance(spec, dict) else {}
        if test_spec:
            args_list = test_spec.get("args", ["--version"]) or ["--version"]
            accept_rc = set(test_spec.get("acceptReturnCodes", [0]))
            success_text = [s.lower() for s in test_spec.get("successText", [])]
            try:
                cp = subprocess.run([path, *args_list], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=12)
                output = cp.stdout.decode(errors="ignore")
                used = args_list
                rc = cp.returncode
                # Determine success: return code acceptable OR any success text found
                lowered = output.lower()
                text_ok = any(t in lowered for t in success_text) if success_text else False
                ok = (rc in accept_rc) or text_ok
                out = output[:4000]
            except FileNotFoundError:
                ok, out, rc, used = False, "not found", 127, args_list
            except subprocess.TimeoutExpired:
                ok, out, rc, used = False, "timeout", 124, args_list
            except Exception as e:
                ok, out, rc, used = False, f"error: {e}", 1, args_list
        else:
            ok, out, rc, used = try_tool_invoke(path)
        results.append({
            "name": name,
            "binary": binary,
            "path": path,
            "ok": ok,
            "rc": rc,
            "args": used,
            "snippet": (out or "")[:240].replace('\n',' '),
        })
    if getattr(args, 'json', False):
        print(json.dumps({"results": results}, indent=2))
        return
    # Text summary
    okc = sum(1 for r in results if r["ok"])
    print(f"Tested {len(results)} tools: {okc} OK, {len(results)-okc} with issues")
    for r in results:
        status = "OK" if r["ok"] else "FAIL"
        used = " ".join(r["args"]) if r["args"] else "(none)"
        print(f"- {r['name']}: {status} [{r['binary']} {used}] rc={r['rc']}")


def install_native(shell: Shell, pm: str, name: str, spec: dict):
    pkgs_map = spec.get("packages", {})
    pkg = pkgs_map.get(pm)
    if not pkg:
        raise SystemExit(f"No native package mapping for {name} on {pm}")
    try:
        PM_INSTALLERS[pm](shell, [pkg])
    except subprocess.CalledProcessError as e:
        raise SystemExit(f"native install failed: {e}")
    # assume binary available equals name, optionally override later with spec
    binary = spec.get("binary", name)
    if not shutil.which(binary):
        # As last attempt, check candidate paths
        candidate = Path(f"/usr/bin/{binary}")
        if not candidate.exists():
            print(f"[!] Installed {pkg} but binary '{binary}' not found in PATH")
    return {"method": "native", "path": shutil.which(binary) or f"/usr/bin/{binary}"}


def ensure_wireshark_permissions(shell: 'Shell'):
    try:
        shell.run(["groupadd", "-f", "wireshark"], check=False)
    except Exception:
        pass
    dumpcap = "/usr/bin/dumpcap"
    if Path(dumpcap).exists():
        try:
            shell.run(["chgrp", "wireshark", dumpcap], check=False)
            shell.run(["chmod", "750", dumpcap], check=False)
        except Exception:
            pass
        sc = shell.which("setcap")
        if sc:
            try:
                shell.run([sc, "cap_net_raw,cap_net_admin=eip", dumpcap], check=False)
            except Exception:
                pass


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
    if kind == "git-bash":
        repo = src["repo"]
        entry = src["entry"]
        bin_name = spec.get("binary", name)
        git_bash_install(repo, entry, bin_name, shell)
        return {"method": "source-git-bash", "path": str(BIN_LINK_DIR / bin_name)}
    if kind == "ruby-git":
        repo = src["repo"]
        entry = src.get("entry", spec.get("binary", name))
        bin_name = spec.get("binary", name)
        ruby_project_install(repo, entry, bin_name, shell)
        return {"method": "source-ruby", "path": str(BIN_LINK_DIR / bin_name)}
    raise SystemExit(f"Unsupported source type for {name}: {kind}")


def _install_one(shell: 'Shell', pm: str, name: str, method: str, tools: dict, dry_run: bool):
    if name not in tools:
        print(f"[!] Unknown tool: {name}. Skipping.")
        return
    spec = tools[name]
    chosen = method
    if chosen == "auto":
        chosen = "native" if pm in spec.get("packages", {}) else ("source" if "source" in spec else None)
        if not chosen:
            print(f"[!] No install method for {name} on this system")
            return
    state = load_state()
    meta = None
    try:
        if chosen == "native":
            meta = install_native(shell, pm, name, spec)
        elif chosen == "source":
            meta = install_source(shell, name, spec)
        else:
            print("[!] method must be auto|native|source")
            return
    except SystemExit as e:
        if method == "auto" and chosen == "native" and "source" in spec:
            print(f"[i] Native install failed for {name}; falling back to source…")
            try:
                meta = install_source(shell, name, spec)
            except SystemExit as e2:
                print(f"[!] Source install failed for {name}: {e2}")
                return
        else:
            print(f"[!] Install failed for {name}: {e}")
            return
    if not dry_run:
        state.setdefault("installed", {})[name] = meta
        save_state(state)
        print(f"[✓] Installed {name} via {meta['method']}")
        # Helpful notes for certain tools
        if name.lower() == 'wireshark':
            ensure_wireshark_permissions(shell)
            print("[i] Tip: add your user to the 'wireshark' group to capture without sudo:")
            print("    sudo usermod -aG wireshark $USER && newgrp wireshark")
    else:
        print(f"[dry-run] Would install {name} via {chosen}")


def cmd_install(args):
    ensure_root()
    shell = Shell(dry_run=args.dry_run)
    pm = detect_pm(shell)
    tools = load_tools_map().get("tools", {})
    names = getattr(args, 'tools', None)
    if not names:
        # Back-compat: single positional may be named 'tool'
        single = getattr(args, 'tool', None)
        if not single:
            raise SystemExit("Specify one or more tool names")
        names = [single]
    for name in names:
        try:
            _install_one(shell, pm, name, args.method, tools, args.dry_run)
        except SystemExit as e:
            print(f"[!] Install failed for {name}: {e}")


def uninstall_native(shell: 'Shell', pm: str, name: str, spec: dict):
    pkgs_map = spec.get("packages", {})
    pkg = pkgs_map.get(pm)
    if not pkg:
        print(f"[!] No native mapping for {name} on {pm}")
        return
    if pm == 'apt':
        try:
            shell.run(["env", "DEBIAN_FRONTEND=noninteractive", "apt", "remove", "-y", pkg])
        except subprocess.CalledProcessError as e:
            rc = getattr(e, 'returncode', None)
            print("[i] apt remove failed (rc=", rc, ") — retrying with --allow-downgrades…", sep='')
            shell.run(["env", "DEBIAN_FRONTEND=noninteractive", "apt", "remove", "-y", "--allow-downgrades", pkg])
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


def cmd_update(args):
    ensure_root()
    shell = Shell()
    pm = detect_pm(shell)
    tools = load_tools_map().get("tools", {})
    target = args.tool
    names = [target] if target and target != "all" else list(tools.keys())
    for name in names:
        spec = tools.get(name)
        if not spec:
            print(f"[!] Unknown tool: {name}")
            continue
        pkgs = spec.get("packages", {})
        if pm in pkgs:
            pkg = pkgs[pm]
            # Perform a safe update for the package
            if pm == 'apt':
                try:
                    shell.run(["apt", "update", "-y"]) 
                    shell.run(["apt", "install", "-y", "--only-upgrade", pkg])
                except subprocess.CalledProcessError as e:
                    rc = getattr(e, 'returncode', None)
                    print("[i] apt upgrade failed (rc=", rc, ") — retrying with --allow-downgrades…", sep='')
                    shell.run(["apt", "install", "-y", "--allow-downgrades", "--only-upgrade", pkg])
            elif pm in ('dnf','yum'):
                shell.run([pm, "-y", "upgrade", pkg])
            elif pm == 'pacman':
                shell.run(["pacman", "-Sy", "--noconfirm", pkg])
            elif pm == 'zypper':
                shell.run(["zypper", "--non-interactive", "update", pkg])
            print(f"[✓] Updated (native) {name}")
        elif "source" in spec:
            # Re-install from source to pull latest
            meta = install_source(shell, name, spec)
            print(f"[✓] Updated (source) {name} → {meta.get('path')}")
        else:
            print(f"[i] No update path for {name} on this system")


def _uninstall_one(shell: 'Shell', pm: str, name: str, tools: dict):
    if name not in tools:
        print(f"[!] Unknown tool: {name}")
        return
    spec = tools[name]
    state = load_state()
    meta = state.get("installed", {}).get(name)
    if not meta:
        print("[i] Not recorded as installed; attempting best-effort removal…")
    method = (meta or {}).get("method")
    if method == "native" or (pm in spec.get("packages", {})):
        uninstall_native(shell, pm, name, spec)
    if (method and method.startswith("source")) or ("source" in spec):
        uninstall_source(name, spec)
    if name in state.get("installed", {}):
        del state["installed"][name]
        save_state(state)
        print(f"[✓] Uninstalled {name}")
    else:
        print("[i] No state entry to update.")


def cmd_uninstall(args):
    ensure_root()
    shell = Shell()
    pm = detect_pm(shell)
    tools = load_tools_map().get("tools", {})
    names = getattr(args, 'tools', None)
    if not names:
        single = getattr(args, 'tool', None)
        if not single:
            raise SystemExit("Specify one or more tool names")
        names = [single]
    for name in names:
        try:
            _uninstall_one(shell, pm, name, tools)
        except SystemExit as e:
            print(f"[!] Uninstall failed for {name}: {e}")


def cmd_doctor(args):
    shell = Shell()
    print(banner())
    print("Checking environment…")
    try:
        pm = detect_pm(shell)
        print("- Package manager:", pm)
    except SystemExit as e:
        print("- Package manager: not found (", e, ")")
    print("- HakPak root:", HAKPAK2_ROOT)
    print("- Bin link dir:", BIN_LINK_DIR)
    print("- Tools map:", TOOLS_MAP_PATH, ("present" if TOOLS_MAP_PATH.exists() else "missing"))
    if Path("/etc/apt/sources.list.d/kali.list").exists():
        print("- Kali repo: present (apt)")
    else:
        print("- Kali repo: not configured or not apt-based")
    print("- PyYAML:", ("ok" if yaml is not None else "missing"))
    print("\nIf installs hang on prompts, ensure noninteractive is set or use GUI mode.")


def build_parser():
    p = argparse.ArgumentParser(prog="hakpak2", description="HakPak v2 — Cross-distro dependency handler")
    # Do not require subcommand; we'll route to menu by default
    sub = p.add_subparsers(dest="cmd", required=False)

    sub.add_parser("detect", help="Show detected distro and package manager").set_defaults(func=cmd_detect)
    lp = sub.add_parser("list", help="List known tools")
    lp.add_argument("--json", action="store_true", dest="json")
    lp.set_defaults(func=cmd_list)
    sub.add_parser("status", help="Show install status").set_defaults(func=cmd_status)
    sub.add_parser("about", help="Show About/Developers and disclaimer").set_defaults(func=cmd_about)
    sub.add_parser("version", help="Show HakPak version and paths").set_defaults(func=cmd_version)
    sub.add_parser("doctor", help="Check environment and common issues").set_defaults(func=cmd_doctor)
    pupt = sub.add_parser("update", help="Update a tool or 'all'")
    pupt.add_argument("tool", nargs='?', default="all")
    pupt.set_defaults(func=cmd_update)

    pt = sub.add_parser("test", help="Run sanity tests (version/help) for tools")
    pt.add_argument("--all", action="store_true", dest="all", help="Test all known tools (default: only installed)")
    pt.add_argument("--json", action="store_true", dest="json")
    pt.set_defaults(func=cmd_test)

    pi = sub.add_parser("install", help="Install one or more tools")
    pi.add_argument("tools", nargs='+', help="Tool name(s) (see 'list')")
    pi.add_argument("--method", choices=["auto", "native", "source"], default="auto")
    pi.add_argument("--dry-run", action="store_true")
    pi.set_defaults(func=cmd_install)

    pu = sub.add_parser("uninstall", help="Uninstall one or more tools")
    pu.add_argument("tools", nargs='+', help="Tool name(s) (see 'list')")
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

    # Menu entry
    sub.add_parser("menu", help="Interactive menu").set_defaults(func=cmd_menu)

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
    subprocess.run(["apt", "update", "-y"], check=False)
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
    subprocess.run(["apt", "update", "-y"], check=False)
    print("[✓] Kali repo removed")


def cmd_repo_status(args):
    # Show whether source + pinning exist, and policy header
    exists = Path("/etc/apt/sources.list.d/kali.list").exists()
    pinned = Path("/etc/apt/preferences.d/kali.pref").exists()
    print(f"source: {'present' if exists else 'absent'}; pinning: {'present' if pinned else 'absent'}")
    subprocess.run(["apt-cache", "policy"], check=False)


def main(argv: list[str]) -> int:
    parser = build_parser()
    # If no args, default to menu
    if not argv:
        return cmd_menu(argparse.Namespace()) or 0
    args = parser.parse_args(argv)
    # If no subcommand matched, also drop into menu
    if not getattr(args, 'cmd', None):
        return cmd_menu(argparse.Namespace()) or 0
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
