#!/usr/bin/env python3
"""
HakPak4 – Secure GitHub Integration
Clones GitHub repositories through a multi-layer security scanner, performs
automatic dependency resolution via HakPak4's existing infrastructure, and
records the installation in HakPak4's state file.

OWASP-aware: detects reverse shells, obfuscation, persistence, and supply-chain
attack patterns before any code is executed on the host.
"""

import os
import re
import sys
import stat
import shutil
import tempfile
import subprocess
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Tuple


# ── Risk levels ───────────────────────────────────────────────────────────────

class RiskLevel(Enum):
    INFO     = "INFO"
    LOW      = "LOW"
    MEDIUM   = "MEDIUM"
    HIGH     = "HIGH"
    CRITICAL = "CRITICAL"


_RISK_ORDER = [
    RiskLevel.CRITICAL,
    RiskLevel.HIGH,
    RiskLevel.MEDIUM,
    RiskLevel.LOW,
    RiskLevel.INFO,
]

_COLORS = {
    RiskLevel.INFO:     "\x1b[0;37m",
    RiskLevel.LOW:      "\x1b[1;34m",
    RiskLevel.MEDIUM:   "\x1b[1;33m",
    RiskLevel.HIGH:     "\x1b[1;31m",
    RiskLevel.CRITICAL: "\x1b[1;35m",
}
_RESET = "\x1b[0m"


# ── Pattern definitions ───────────────────────────────────────────────────────

@dataclass
class Pattern:
    level: RiskLevel
    regex: str
    description: str


# Patterns are ordered from most critical to least.  Only the first match per
# source line is recorded so a single line does not flood the report.
_PATTERNS: List[Pattern] = [
    # ── CRITICAL ──────────────────────────────────────────────────────────────
    Pattern(
        RiskLevel.CRITICAL,
        r"bash\s+-i\s+>&?\s*/dev/(tcp|udp)",
        "Reverse shell via /dev/tcp or /dev/udp",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"nc(at)?\s+.*(--sh-exec|-e\s+/bin/(ba)?sh|-c\s+/bin/(ba)?sh)",
        "Netcat/ncat reverse shell",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"python[23]?\s+-c\s+['\"].*socket.*connect.*SOCK_STREAM",
        "Python socket-based reverse shell",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"\brm\s+-[rRf]{1,3}f?\s+/?(\s|$|;)",
        "Dangerous rm -rf / (potential filesystem wipe)",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r">\s*/etc/(passwd|shadow|sudoers)",
        "Overwriting critical system authentication files",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"chmod\s+(4[0-9]{3}|[0-9]{3,4}s|\+s)\s",
        "Setting setuid/setgid bit on a file",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"(minerd|xmrig|cpuminer|stratum\+tcp://|cryptonight|xmr\.pool)",
        "Cryptocurrency miner signature",
    ),
    Pattern(
        RiskLevel.CRITICAL,
        r"eval\s*\(\s*compile\s*\(.*base64|\bexec\s*\(\s*__import__\s*\(\s*['\"]base64",
        "Eval/exec of base64-compiled payload (Python)",
    ),

    # ── HIGH ──────────────────────────────────────────────────────────────────
    Pattern(
        RiskLevel.HIGH,
        r"(curl|wget|fetch)\s+[^\|]*\|\s*(ba)?sh",
        "Remote code execution via pipe to shell (curl/wget | bash)",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"eval\s*[\(\$]\s*(base64[_\-]?decode|hex[_\-]?decode|unhexlify)",
        "Eval of base64/hex-decoded payload",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"echo\s+[A-Za-z0-9+/]{40,}={0,2}\s*\|\s*base64\s+-d\s*\|",
        "Embedded base64 blob piped to shell",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"\.git/hooks/[a-z-]+",
        "Reference to a git hook path (executes on git operations)",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"(crontab\s+-[le]|/etc/cron\.(d|daily|hourly|weekly|monthly)|echo.*cron)",
        "Cron-based persistence mechanism",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"(visudo|/etc/sudoers\.d/|NOPASSWD\s*:)",
        "Sudoers or NOPASSWD modification",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"(systemctl\s+enable|/etc/systemd/system/|/etc/init\.d/|/etc/rc\.d/)",
        "Systemd/init service installation (persistence)",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"(exec|system|popen|passthru|shell_exec)\s*\(\s*\$_(GET|POST|REQUEST|COOKIE)",
        "PHP remote code execution via user-controlled parameter",
    ),
    Pattern(
        RiskLevel.HIGH,
        r"os\.system\s*\(|subprocess\.(call|Popen|run)\s*\(.*shell\s*=\s*True",
        "Shell=True subprocess invocation (injection risk)",
    ),

    # ── MEDIUM ────────────────────────────────────────────────────────────────
    Pattern(
        RiskLevel.MEDIUM,
        r"base64\.(b64decode|decodestring)|binascii\.unhexlify|codecs\.decode.*hex",
        "Base64/hex decoding (potential obfuscation)",
    ),
    Pattern(
        RiskLevel.MEDIUM,
        r"__import__\s*\(\s*['\"]os['\"]",
        "Dynamic import of os module",
    ),
    Pattern(
        RiskLevel.MEDIUM,
        r"echo\s+.*>>\s*~?\s*/(root|home)/[^/]*/\.(bashrc|bash_profile|profile|zshrc)",
        "Shell profile modification (persistence)",
    ),
    Pattern(
        RiskLevel.MEDIUM,
        r"(curl|wget)\s+(https?://[^\s'\"]+)\s+-[oO-]",
        "Downloading file from the internet at runtime",
    ),
    Pattern(
        RiskLevel.MEDIUM,
        r"/proc/self/mem|PTRACE_POKETEXT|\bptrace\b",
        "Direct memory manipulation via /proc or ptrace",
    ),
    Pattern(
        RiskLevel.MEDIUM,
        r"dd\s+if=/dev/(sda|hda|nvme|random|urandom)\s+of=",
        "Disk/device write via dd (possible data destruction)",
    ),

    # ── LOW ───────────────────────────────────────────────────────────────────
    Pattern(
        RiskLevel.LOW,
        r"\b(?:25[0-5]|2[0-4]\d|[01]?\d\d?)(?:\.(?:25[0-5]|2[0-4]\d|[01]?\d\d?)){3}\b",
        "Hardcoded IP address",
    ),
    Pattern(
        RiskLevel.LOW,
        r"kill\s+-9\s+|pkill\s+-9\s+|killall\s+-9\s+",
        "Forceful process termination (SIGKILL)",
    ),
    Pattern(
        RiskLevel.LOW,
        r"(iptables|ip6tables|nftables|ufw)\s+",
        "Firewall rule modification",
    ),
]

_COMPILED: List[Tuple[Pattern, re.Pattern]] = [
    (p, re.compile(p.regex, re.IGNORECASE)) for p in _PATTERNS
]


# ── Data classes ──────────────────────────────────────────────────────────────

@dataclass
class Finding:
    level: RiskLevel
    file: str
    line_num: int
    snippet: str
    description: str


@dataclass
class ScanReport:
    repo_url: str
    commit_sha: str
    files_scanned: int
    binary_files: List[str] = field(default_factory=list)
    git_hooks: List[str] = field(default_factory=list)
    findings: List[Finding] = field(default_factory=list)

    @property
    def max_risk(self) -> RiskLevel:
        for level in _RISK_ORDER:
            if any(f.level == level for f in self.findings):
                return level
        return RiskLevel.INFO

    @property
    def has_critical(self) -> bool:
        return any(f.level == RiskLevel.CRITICAL for f in self.findings)

    @property
    def has_high(self) -> bool:
        return any(f.level == RiskLevel.HIGH for f in self.findings)


# ── Dependency detection ──────────────────────────────────────────────────────

_DEP_FILES: Dict[str, str] = {
    "requirements.txt": "pip",
    "setup.py":         "pip",
    "setup.cfg":        "pip",
    "pyproject.toml":   "pip",
    "Gemfile":          "bundler",
    "go.mod":           "go",
    "package.json":     "npm",
    "Cargo.toml":       "cargo",
    "CMakeLists.txt":   "cmake",
    "Makefile":         "make",
    "makefile":         "make",
    "configure.ac":     "autoconf",
    "configure":        "autoconf",
}


def detect_dependencies(repo_path: Path) -> Dict[str, str]:
    """Return {relative_path: dep_type} for manifests found within 2 levels."""
    found: Dict[str, str] = {}
    for fname, dep_type in _DEP_FILES.items():
        for candidate in repo_path.rglob(fname):
            rel = candidate.relative_to(repo_path)
            if len(rel.parts) <= 2 and str(rel) not in found:
                found[str(rel)] = dep_type
    return found


# ── File scanner ──────────────────────────────────────────────────────────────

_TEXT_SUFFIXES = {
    ".sh", ".bash", ".py", ".rb", ".pl", ".php", ".js", ".ts",
    ".yaml", ".yml", ".json", ".toml", ".cfg", ".conf", ".ini",
    ".mk", ".cmake", "",
}
_TEXT_NAMES = {
    "makefile", "dockerfile", "vagrantfile", "rakefile",
    "gemfile", "procfile", "brewfile", "configure",
}


def _is_binary(path: Path) -> bool:
    try:
        with open(path, "rb") as fh:
            return b"\x00" in fh.read(8192)
    except OSError:
        return False


def scan_repo(repo_path: Path, repo_url: str) -> ScanReport:
    """Recursively scan *repo_path* for security issues."""
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_path), "rev-parse", "HEAD"],
            capture_output=True, text=True, check=True,
        )
        commit_sha = result.stdout.strip()
    except subprocess.CalledProcessError:
        commit_sha = "unknown"

    report = ScanReport(
        repo_url=repo_url,
        commit_sha=commit_sha,
        files_scanned=0,
    )

    # ── Check for executable git hooks (run on clone/checkout) ───────────────
    hooks_dir = repo_path / ".git" / "hooks"
    if hooks_dir.exists():
        for hook in sorted(hooks_dir.iterdir()):
            if hook.is_file() and (hook.stat().st_mode & stat.S_IXUSR):
                report.git_hooks.append(hook.name)
                report.findings.append(Finding(
                    level=RiskLevel.HIGH,
                    file=f".git/hooks/{hook.name}",
                    line_num=0,
                    snippet="(executable git hook)",
                    description="Executable git hook will run on git operations",
                ))

    # ── Walk all repository files ─────────────────────────────────────────────
    for fpath in sorted(repo_path.rglob("*")):
        if ".git" in fpath.parts or not fpath.is_file():
            continue

        if _is_binary(fpath):
            report.binary_files.append(str(fpath.relative_to(repo_path)))
            continue

        suffix = fpath.suffix.lower()
        name_lower = fpath.name.lower()
        if suffix not in _TEXT_SUFFIXES and name_lower not in _TEXT_NAMES:
            continue

        try:
            lines = fpath.read_text(encoding="utf-8", errors="ignore").splitlines()
        except OSError:
            continue

        report.files_scanned += 1
        rel = str(fpath.relative_to(repo_path))

        for lineno, line in enumerate(lines, 1):
            for pattern, compiled in _COMPILED:
                if compiled.search(line):
                    report.findings.append(Finding(
                        level=pattern.level,
                        file=rel,
                        line_num=lineno,
                        snippet=line.strip()[:120],
                        description=pattern.description,
                    ))
                    break  # First match per line – highest priority wins

    return report


# ── Report display ────────────────────────────────────────────────────────────

def print_scan_report(report: ScanReport) -> None:
    print("\n" + "=" * 72)
    print("  HAKPAK SECURITY SCAN REPORT")
    print("=" * 72)
    print(f"  Repo:          {report.repo_url}")
    print(f"  Commit:        {report.commit_sha}")
    print(f"  Files Scanned: {report.files_scanned}")

    if report.binary_files:
        print(f"\n  Binary files ({len(report.binary_files)}) – not code-scanned:")
        for bf in report.binary_files[:10]:
            print(f"    ⚠ {bf}")
        if len(report.binary_files) > 10:
            print(f"    … and {len(report.binary_files) - 10} more")

    if not report.findings:
        print(f"\n  {_COLORS[RiskLevel.INFO]}✓ No suspicious patterns detected.{_RESET}")
    else:
        for level in _RISK_ORDER:
            found = [f for f in report.findings if f.level == level]
            if not found:
                continue
            color = _COLORS[level]
            print(f"\n  {color}[{level.value}]{_RESET} — {len(found)} finding(s):")
            for f in found[:15]:
                loc = f"{f.file}:{f.line_num}" if f.line_num else f.file
                print(f"    {color}●{_RESET} {loc}")
                print(f"      Reason:  {f.description}")
                if f.snippet:
                    print(f"      Code:    {f.snippet}")
            if len(found) > 15:
                print(f"    … and {len(found) - 15} more {level.value} finding(s)")

    color = _COLORS[report.max_risk]
    print(f"\n  Overall Risk: {color}{report.max_risk.value}{_RESET}")
    print("=" * 72)


# ── Dependency installation ───────────────────────────────────────────────────

def install_repo_dependencies(
    repo_path: Path,
    deps: Dict[str, str],
    system_info,
    shell,
) -> None:
    """Install detected dependencies using HakPak4's infrastructure."""
    if not deps:
        return

    from hakpak4 import PackageInstaller

    installer = PackageInstaller(shell, system_info)

    for manifest, dep_type in deps.items():
        manifest_path = repo_path / manifest
        print(f"\n  [{dep_type}] Installing from {manifest} …")

        if dep_type == "pip":
            if not shell.which("pip3") and not shell.which("pip"):
                installer.install_packages(["python3-pip"])
            pip = shell.which("pip3") or "pip3"
            if manifest_path.name == "requirements.txt":
                shell.run([pip, "install", "--user", "-r", str(manifest_path)], check=False)
            else:
                shell.run([pip, "install", "--user", str(repo_path)], check=False)

        elif dep_type == "bundler":
            if not shell.which("bundle"):
                installer.install_packages(["ruby-bundler"])
            shell.run(
                ["bundle", "install", "--path", str(repo_path / ".bundle")],
                check=False,
            )

        elif dep_type == "npm":
            if not shell.which("npm"):
                installer.install_packages(["nodejs", "npm"])
            shell.run(["npm", "install", "--prefix", str(repo_path)], check=False)

        elif dep_type == "go":
            if not shell.which("go"):
                installer.install_packages(["golang"])
            shell.run(["go", "mod", "download"], check=False)

        elif dep_type == "cargo":
            if not shell.which("cargo"):
                installer.install_packages(["cargo"])
            shell.run(["cargo", "build", "--release"], check=False)

        elif dep_type == "make":
            if not shell.which("make"):
                installer.install_packages(["make", "build-essential"])
            shell.run(["make"], check=False)

        elif dep_type == "cmake":
            for pkg in ["cmake", "make", "build-essential"]:
                if not shell.which(pkg):
                    installer.install_packages(["cmake", "make", "build-essential"])
                    break
            shell.run(["cmake", "."], check=False)
            shell.run(["make"], check=False)

        elif dep_type == "autoconf":
            for pkg in ["autoconf", "automake", "make", "build-essential"]:
                if not shell.which(pkg):
                    installer.install_packages(["autoconf", "automake", "make", "build-essential"])
                    break
            if (repo_path / "configure.ac").exists():
                shell.run(["autoreconf", "-fi"], check=False)
            if (repo_path / "configure").exists():
                shell.run(["./configure"], check=False)
            shell.run(["make"], check=False)


# ── URL validation ────────────────────────────────────────────────────────────

_GITHUB_RE = re.compile(
    r"^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$"
)


def validate_github_url(url: str) -> Tuple[bool, str]:
    """
    Validate and normalise a GitHub HTTPS clone URL.
    Only github.com HTTPS URLs are accepted.  SSH URLs and arbitrary hosts are
    rejected to prevent SSRF / local-file-read via git-clone.
    Returns (is_valid, normalised_url).
    """
    url = url.strip().rstrip("/")
    if not url.endswith(".git"):
        url += ".git"
    return bool(_GITHUB_RE.match(url)), url


# ── Public CLI entry point ────────────────────────────────────────────────────

def cmd_gitclone(
    repo_url: str,
    system_info,
    shell,
    install_dir: Optional[Path] = None,
    force: bool = False,
) -> int:
    """
    Main entry point for ``hakpak4 gitclone <url>``.

    Steps:
      1. Validate GitHub URL (HTTPS only, github.com only)
      2. Shallow-clone into an isolated temp directory
      3. Run multi-pattern security scan
      4. Detect dependency manifests
      5. Block on CRITICAL findings (unless --force)
      6. Prompt user for confirmation on HIGH/MEDIUM findings
      7. Move repo to final location
      8. Install dependencies via HakPak4 infrastructure
      9. Record installation in HakPak4 state.json
    """
    from hakpak4 import StateManager

    # 1. Validate URL
    valid, norm_url = validate_github_url(repo_url)
    if not valid:
        print(f"\nERROR: Invalid GitHub URL: {repo_url!r}")
        print("  Only https://github.com/owner/repo URLs are accepted.")
        return 1

    # 2. Ensure git
    if not shell.which("git"):
        print("\nERROR: git is not installed.")
        print("  Install with: sudo apt install git")
        return 1

    repo_name = norm_url.rstrip("/").removesuffix(".git").rsplit("/", 1)[-1]

    print(f"\n{'=' * 72}")
    print("  HAKPAK SECURE GIT CLONE")
    print(f"{'=' * 72}")
    print(f"  URL:  {norm_url}")
    print(f"  Name: {repo_name}")
    print("\n  Step 1/4 – Shallow-cloning into sandbox …")

    tmpdir = tempfile.mkdtemp(prefix="hakpak4_clone_")
    try:
        result = subprocess.run(
            ["git", "clone", "--depth=1", norm_url, tmpdir],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"\nERROR: git clone failed:\n{result.stderr.strip()}")
            return 1
    except OSError as exc:
        print(f"\nERROR: {exc}")
        return 1
    finally:
        # tmpdir cleanup is deferred; we clean on failure paths below
        pass

    try:
        # 3. Security scan
        print("  Step 2/4 – Running security scan …")
        report = scan_repo(Path(tmpdir), norm_url)
        print_scan_report(report)

        # 4. Dependency detection
        deps = detect_dependencies(Path(tmpdir))
        if deps:
            print(f"\n  Step 3/4 – Dependency manifests found:")
            for fname, dtype in deps.items():
                print(f"    • {fname}  [{dtype}]")
        else:
            print("\n  Step 3/4 – No dependency manifests detected.")

        # 5. Block on CRITICAL
        if report.has_critical and not force:
            print(
                f"\n  {_COLORS[RiskLevel.CRITICAL]}[BLOCKED]{_RESET} "
                "Critical security issues found in this repository."
            )
            print("  Installation aborted.")
            print("  Re-run with --force to override (strongly discouraged).")
            return 2

        # 6. Require explicit confirmation for non-clean scans
        if report.findings and not force:
            color = _COLORS[report.max_risk]
            print(f"\n  Risk level: {color}{report.max_risk.value}{_RESET}")
            try:
                ans = input(
                    "\n  Proceed with installation? "
                    "(type 'yes' to confirm, anything else cancels): "
                ).strip().lower()
            except (EOFError, KeyboardInterrupt):
                ans = ""
            if ans != "yes":
                print("  Cancelled.")
                return 0
        elif not report.findings:
            print("\n  ✓ Clean scan. No user confirmation required.")

        # 7. Move to final destination
        base_dir = install_dir or Path(
            os.environ.get("HAKPAK4_REPOS", "/opt/hakpak4/repos")
        )
        dest = base_dir / repo_name

        print(f"\n  Step 4/4 – Installing to {dest} …")

        if dest.exists():
            print(f"  Destination already exists: {dest}")
            try:
                ans = input("  Overwrite? (yes/N): ").strip().lower()
            except (EOFError, KeyboardInterrupt):
                ans = ""
            if ans != "yes":
                print("  Cancelled.")
                return 0
            shutil.rmtree(dest, ignore_errors=True)

        base_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(tmpdir, str(dest))
        tmpdir = None  # Ownership transferred – skip cleanup

        # 8. Dependency installation
        if deps:
            print("\n  Installing dependencies …")
            install_repo_dependencies(dest, deps, system_info, shell)

        # 9. Record in state
        state = StateManager.load_state()
        state.setdefault("git_repos", {})[repo_name] = {
            "url":      norm_url,
            "commit":   report.commit_sha,
            "path":     str(dest),
            "risk":     report.max_risk.value,
            "findings": len(report.findings),
            "deps":     deps,
        }
        StateManager.save_state(state)

        print(f"\n\x1b[1;32m✓ '{repo_name}' installed successfully.\x1b[0m")
        print(f"  Location: {dest}")
        if deps:
            print(f"  Dep types: {', '.join(sorted(set(deps.values())))}")
        print()
        return 0

    except Exception as exc:
        print(f"\nERROR: Unexpected failure: {exc}")
        return 1
    finally:
        if tmpdir and Path(tmpdir).exists():
            shutil.rmtree(tmpdir, ignore_errors=True)


# ── Menu helper for interactive mode ─────────────────────────────────────────

def menu_gitclone(system_info, shell) -> None:
    """Interactive git-clone sub-menu."""
    print("\n" + "=" * 60)
    print("  SECURE GIT CLONE")
    print("=" * 60)
    print("  Clone a GitHub repository with:")
    print("    • Multi-layer security scanning")
    print("    • Automatic dependency resolution")
    print("    • HakPak state tracking")
    print("-" * 60)
    print("  Only https://github.com URLs are accepted.")
    print("=" * 60)

    try:
        url = input("\n  GitHub URL (or 0 to cancel): ").strip()
    except (EOFError, KeyboardInterrupt):
        return

    if url == "0" or not url:
        return

    force = False
    try:
        f = input("  Skip auto-block for CRITICAL findings? (not recommended) (y/N): ").strip().lower()
        force = f == "y"
    except (EOFError, KeyboardInterrupt):
        pass

    rc = cmd_gitclone(url, system_info, shell, force=force)
    if rc not in (0, 2):
        print(f"\nGit clone exited with code {rc}")
    input("\n  Press Enter to continue …")
