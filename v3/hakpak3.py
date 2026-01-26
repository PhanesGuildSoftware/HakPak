#!/usr/bin/env python3
"""
HakPak3 - The Ultimate Cross-Distro Hacking Tool Installer & Dependency Handler
Developer: Teyvone Wells
Company: PhanesGuild Software LLC
Version: 3.0.0
"""

import os
import sys
import subprocess
import shutil
import platform
import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from textwrap import dedent
from dataclasses import dataclass, asdict
from enum import Enum

try:
    import yaml
except ImportError:
    yaml = None

# Configuration
HAKPAK3_ROOT = Path(os.environ.get("HAKPAK3_ROOT", "/opt/hakpak3")).resolve()
TOOLS_MAP_PATH = Path(__file__).parent / "tools-map.yaml"
KALI_TOOLS_PATH = Path(__file__).parent / "kali-tools-db.yaml"
BIN_LINK_DIR = Path(os.environ.get("HAKPAK3_BIN", "/usr/local/bin"))
STATE_FILE = HAKPAK3_ROOT / "state.json"
VERSION = "3.0.0"


class ToolCategory(Enum):
    """Tool categories for organization"""
    STANDARD = "standard"  # Bundled with HakPak
    CUSTOM = "custom"      # User-installed from Kali repos
    INSTALLED = "installed"  # Currently installed tools


@dataclass
class SystemInfo:
    """System information for compatibility checking"""
    os_name: str
    os_version: str
    os_id: str
    os_id_like: str
    kernel: str
    architecture: str
    cpu_count: int
    total_ram_mb: int
    available_ram_mb: int
    total_disk_gb: float
    available_disk_gb: float
    package_manager: str


@dataclass
class ToolMetrics:
    """Resource requirements for a tool"""
    estimated_size_mb: float
    dependencies_size_mb: float
    ram_required_mb: int
    compatibility_score: int  # 0-100 based on OS match


@dataclass
class Tool:
    """Unified tool representation"""
    name: str
    binary: str
    category: ToolCategory
    description: str
    packages: Dict[str, str]
    source: Optional[Dict[str, str]]
    dependencies: List[str]
    metrics: ToolMetrics
    kali_metapackage: Optional[str]
    tags: List[str]


@dataclass
class InstallParams:
    """Installation filter parameters"""
    min_compatibility: int = 0  # Minimum compatibility score (0-100)
    max_compatibility: int = 100  # Maximum compatibility score
    max_size_mb: Optional[float] = None  # Maximum total size in MB
    max_ram_mb: Optional[int] = None  # Maximum RAM required in MB
    tags_filter: Optional[List[str]] = None  # Only install tools with these tags
    exclude_tags: Optional[List[str]] = None  # Exclude tools with these tags
    max_count: Optional[int] = None  # Maximum number of tools to install
    
    def matches(self, tool: Tool, system_info: SystemInfo) -> bool:
        """Check if tool matches the filter parameters"""
        from hakpak3 import CompatibilityScorer
        
        # Check compatibility score
        score = CompatibilityScorer.score_tool(tool, system_info)
        if score < self.min_compatibility or score > self.max_compatibility:
            return False
        
        # Check size
        if self.max_size_mb is not None:
            total_size = tool.metrics.estimated_size_mb + tool.metrics.dependencies_size_mb
            if total_size > self.max_size_mb:
                return False
        
        # Check RAM
        if self.max_ram_mb is not None:
            if tool.metrics.ram_required_mb > self.max_ram_mb:
                return False
        
        # Check tags filter (include)
        if self.tags_filter:
            if not any(tag in tool.tags for tag in self.tags_filter):
                return False
        
        # Check tags exclude
        if self.exclude_tags:
            if any(tag in tool.tags for tag in self.exclude_tags):
                return False
        
        return True


class Shell:
    """Command execution wrapper"""
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    def run(self, cmd: List[str], check: bool = True, capture: bool = False):
        if self.dry_run:
            print(f"[dry-run] $ {' '.join(cmd)}")
            return subprocess.CompletedProcess(cmd, 0, b"", b"")
        if capture:
            return subprocess.run(cmd, check=check, stdout=subprocess.PIPE, 
                                stderr=subprocess.PIPE, text=True)
        return subprocess.run(cmd, check=check)

    def which(self, name: str) -> Optional[str]:
        return shutil.which(name)


class HardwareDetector:
    """Detect system hardware capabilities"""
    
    @staticmethod
    def get_cpu_info() -> Dict[str, any]:
        """Get CPU information"""
        cpu_count = os.cpu_count() or 1
        cpu_info = {"count": cpu_count, "architecture": platform.machine()}
        
        # Try to get more detailed CPU info
        try:
            with open("/proc/cpuinfo", "r") as f:
                cpuinfo = f.read()
                if "model name" in cpuinfo:
                    model = re.search(r"model name\s*:\s*(.+)", cpuinfo)
                    if model:
                        cpu_info["model"] = model.group(1).strip()
        except:
            pass
        
        return cpu_info
    
    @staticmethod
    def get_memory_info() -> Dict[str, int]:
        """Get system memory information in MB"""
        try:
            with open("/proc/meminfo", "r") as f:
                meminfo = f.read()
            
            total = re.search(r"MemTotal:\s+(\d+)", meminfo)
            available = re.search(r"MemAvailable:\s+(\d+)", meminfo)
            
            return {
                "total_mb": int(total.group(1)) // 1024 if total else 0,
                "available_mb": int(available.group(1)) // 1024 if available else 0
            }
        except:
            return {"total_mb": 0, "available_mb": 0}
    
    @staticmethod
    def get_disk_info(path: str = "/") -> Dict[str, float]:
        """Get disk space information in GB"""
        try:
            stat = os.statvfs(path)
            total = (stat.f_blocks * stat.f_frsize) / (1024**3)
            available = (stat.f_bavail * stat.f_frsize) / (1024**3)
            return {
                "total_gb": round(total, 2),
                "available_gb": round(available, 2)
            }
        except:
            return {"total_gb": 0, "available_gb": 0}


class OSDetector:
    """Detect operating system details"""
    
    @staticmethod
    def read_os_release() -> Dict[str, str]:
        """Read /etc/os-release"""
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
    
    @staticmethod
    def detect_package_manager(shell: Shell) -> str:
        """Detect the system package manager"""
        osr = OSDetector.read_os_release()
        pm_order = []
        distro_id = osr.get("ID", "").lower()
        
        # Prioritize based on distro
        if distro_id in ("ubuntu", "debian", "raspbian", "linuxmint", "pop", "kali"):
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
        
        # Fallback detection
        if Path("/etc/debian_version").exists():
            return "apt"
        
        raise SystemExit("No supported package manager found (apt/dnf/pacman/zypper)")
    
    @staticmethod
    def get_system_info(shell: Shell) -> SystemInfo:
        """Get comprehensive system information"""
        osr = OSDetector.read_os_release()
        mem_info = HardwareDetector.get_memory_info()
        disk_info = HardwareDetector.get_disk_info()
        cpu_info = HardwareDetector.get_cpu_info()
        
        return SystemInfo(
            os_name=osr.get("NAME", "Unknown"),
            os_version=osr.get("VERSION", "Unknown"),
            os_id=osr.get("ID", "unknown"),
            os_id_like=osr.get("ID_LIKE", ""),
            kernel=platform.release(),
            architecture=platform.machine(),
            cpu_count=cpu_info["count"],
            total_ram_mb=mem_info["total_mb"],
            available_ram_mb=mem_info["available_mb"],
            total_disk_gb=disk_info["total_gb"],
            available_disk_gb=disk_info["available_gb"],
            package_manager=OSDetector.detect_package_manager(shell)
        )


class CompatibilityScorer:
    """Calculate tool compatibility scores based on system info"""
    
    @staticmethod
    def score_tool(tool: Tool, system_info: SystemInfo) -> int:
        """
        Calculate compatibility score (0-100)
        Higher score = better match for the system
        """
        score = 0
        pm = system_info.package_manager
        os_id = system_info.os_id
        
        # Package manager compatibility (40 points)
        if pm in tool.packages:
            score += 40
        elif tool.source:
            score += 20  # Can be built from source
        
        # OS-specific packages (30 points)
        if os_id in ("kali", "parrot"):
            score += 30  # Perfect match for security distros
        elif os_id in ("ubuntu", "debian"):
            if "apt" in tool.packages:
                score += 25
        elif os_id in ("arch", "manjaro"):
            if "pacman" in tool.packages:
                score += 25
        elif os_id in ("fedora", "rhel", "centos"):
            if "dnf" in tool.packages:
                score += 25
        
        # Resource availability (30 points)
        if system_info.available_ram_mb > tool.metrics.ram_required_mb * 2:
            score += 15
        elif system_info.available_ram_mb > tool.metrics.ram_required_mb:
            score += 10
        else:
            score += 0
        
        total_required_gb = (tool.metrics.estimated_size_mb + 
                            tool.metrics.dependencies_size_mb) / 1024
        if system_info.available_disk_gb > total_required_gb * 3:
            score += 15
        elif system_info.available_disk_gb > total_required_gb:
            score += 10
        else:
            score += 0
        
        return min(score, 100)


class StateManager:
    """Manage installed tools state"""
    
    @staticmethod
    def load_state() -> Dict:
        """Load installation state"""
        if not STATE_FILE.exists():
            return {"installed": {}, "custom": {}}
        try:
            with open(STATE_FILE, "r") as f:
                return json.load(f)
        except:
            return {"installed": {}, "custom": {}}
    
    @staticmethod
    def save_state(state: Dict):
        """Save installation state"""
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    
    @staticmethod
    def mark_installed(tool_name: str, method: str, category: str):
        """Mark a tool as installed"""
        state = StateManager.load_state()
        state["installed"][tool_name] = {
            "method": method,
            "category": category,
            "installed_at": subprocess.check_output(
                ["date", "+%Y-%m-%d %H:%M:%S"], text=True
            ).strip()
        }
        StateManager.save_state(state)
    
    @staticmethod
    def mark_uninstalled(tool_name: str):
        """Mark a tool as uninstalled"""
        state = StateManager.load_state()
        if tool_name in state["installed"]:
            del state["installed"][tool_name]
        if tool_name in state.get("custom", {}):
            del state["custom"][tool_name]
        StateManager.save_state(state)
    
    @staticmethod
    def get_installed_tools() -> List[str]:
        """Get list of installed tool names"""
        state = StateManager.load_state()
        return list(state.get("installed", {}).keys())
    
    @staticmethod
    def get_custom_tools() -> List[str]:
        """Get list of custom tool names"""
        state = StateManager.load_state()
        return list(state.get("custom", {}).keys())


def banner() -> str:
    """HakPak3 banner"""
    return (
        "\n"
        "\x1b[1;32m██╗  ██╗ █████╗ ██╗  ██╗██████╗  █████╗ ██╗  ██╗██████╗ \x1b[0m\n"
        "\x1b[1;32m██║  ██║██╔══██╗██║ ██╔╝██╔══██╗██╔══██╗██║ ██╔╝╚════██╗\x1b[0m\n"
        "\x1b[1;32m███████║███████║█████╔╝ ██████╔╝███████║█████╔╝  █████╔╝\x1b[0m\n"
        "\x1b[1;32m██╔══██║██╔══██║██╔═██╗ ██╔═══╝ ██╔══██║██╔═██╗  ╚═══██╗\x1b[0m\n"
        "\x1b[1;32m██║  ██║██║  ██║██║  ██╗██║     ██║  ██║██║  ██╗██████╔╝\x1b[0m\n"
        "\x1b[34m╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ \x1b[0m\n"
        "\x1b[1;33m    Ultimate Cross-Distro Hacking Tool Installer v3.0    \x1b[0m\n"
    )


def disclaimer() -> str:
    """Legal disclaimer"""
    return (
        "\n"
        "\x1b[1;31mLEGAL DISCLAIMER\x1b[0m\n"
        "Use these tools only on systems you own or have\n"
        "explicit, written permission to test. Unauthorized use\n"
        "may be illegal. You accept full responsibility.\n"
    )


def developer_info() -> str:
    """Developer information"""
    return (
        "\n"
        "HakPak v3 — Ultimate Cross‑Distro Hacking Tool Installer\n"
        "\n"
        "Developers:\n"
        "  - Creator: Teyvone Wells\n"
        "  - Company: PhanesGuild Software LLC\n"
        "\n"
        "Contact:\n"
        "  - Email: owner@phanesguild.llc\n"
        "  - GitHub: https://github.com/PhanesGuildSoftware\n"
        "\n"
        "Features:\n"
        "  - Automated dependency resolution\n"
        "  - 200+ Kali Linux tools\n"
        "  - Smart OS compatibility scoring\n"
        "  - Real-time resource metrics\n"
        "  - Custom tool management\n"
    )


def format_size(mb: float) -> str:
    """Format size in MB to human-readable"""
    if mb < 1:
        return f"{mb * 1024:.0f} KB"
    elif mb < 1024:
        return f"{mb:.1f} MB"
    else:
        return f"{mb / 1024:.2f} GB"


def format_compatibility(score: int) -> str:
    """Format compatibility score with color"""
    if score >= 80:
        return f"\x1b[1;32m{score}%\x1b[0m"
    elif score >= 60:
        return f"\x1b[1;33m{score}%\x1b[0m"
    else:
        return f"\x1b[1;31m{score}%\x1b[0m"


def display_system_info(system_info: SystemInfo):
    """Display comprehensive system information"""
    print("\n" + "="*70)
    print(f"  \x1b[1;36mSYSTEM INFORMATION\x1b[0m")
    print("="*70)
    print(f"  OS:              {system_info.os_name} {system_info.os_version}")
    print(f"  Distro ID:       {system_info.os_id}")
    print(f"  Kernel:          {system_info.kernel}")
    print(f"  Architecture:    {system_info.architecture}")
    print(f"  Package Mgr:     {system_info.package_manager}")
    print(f"  CPU Cores:       {system_info.cpu_count}")
    print(f"  Total RAM:       {system_info.total_ram_mb} MB "
          f"({system_info.available_ram_mb} MB available)")
    print(f"  Total Disk:      {system_info.total_disk_gb} GB "
          f"({system_info.available_disk_gb} GB available)")
    print("="*70 + "\n")


if __name__ == "__main__":
    # Import core functionality
    try:
        from hakpak3_core import main
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted. Goodbye!")
        sys.exit(0)
    except Exception as e:
        print(f"\nFATAL ERROR: {e}")
        sys.exit(1)
