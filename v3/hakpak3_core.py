#!/usr/bin/env python3
"""
HakPak3 Core Functionality - Installation, Dependency Resolution, and Menu System
"""

from dataclasses import dataclass

from hakpak3 import *


class DependencyResolver:
    """Advanced dependency resolution for tool installation"""
    
    def __init__(self, shell: Shell, system_info: SystemInfo):
        self.shell = shell
        self.system_info = system_info
        self.resolved_cache = {}

    def map_dependency_package(self, dep: str) -> Optional[str]:
        """Map a logical dependency to a package for the current package manager"""
        pm = self.system_info.package_manager
        pkg_map = {
            "python3": {"apt": "python3", "dnf": "python3", "pacman": "python", "zypper": "python3"},
            "python3-pip": {"apt": "python3-pip", "dnf": "python3-pip", "pacman": "python-pip", "zypper": "python3-pip"},
            "python3-venv": {"apt": "python3-venv", "dnf": "python3-virtualenv", "pacman": "python-virtualenv", "zypper": "python3-virtualenv"},
            "ruby": {"apt": "ruby-full", "dnf": "ruby", "pacman": "ruby", "zypper": "ruby"},
            "ruby-bundler": {"apt": "ruby-bundler", "dnf": "rubygem-bundler", "pacman": "ruby-bundler", "zypper": "rubygem-bundler"},
            "java": {"apt": "default-jdk", "dnf": "java-11-openjdk", "pacman": "jdk-openjdk", "zypper": "java-11-openjdk"},
            "perl": {"apt": "perl", "dnf": "perl", "pacman": "perl", "zypper": "perl"},
            "wine": {"apt": "wine", "dnf": "wine", "pacman": "wine", "zypper": "wine"},
            "postgresql": {"apt": "postgresql", "dnf": "postgresql-server", "pacman": "postgresql", "zypper": "postgresql-server"},
            "git": {"apt": "git", "dnf": "git", "pacman": "git", "zypper": "git"},
            "golang": {"apt": "golang", "dnf": "golang", "pacman": "go", "zypper": "go"},
            "wget": {"apt": "wget", "dnf": "wget", "pacman": "wget", "zypper": "wget"},
            "curl": {"apt": "curl", "dnf": "curl", "pacman": "curl", "zypper": "curl"},
            "unzip": {"apt": "unzip", "dnf": "unzip", "pacman": "unzip", "zypper": "unzip"},
        }
        if dep in pkg_map and pm in pkg_map[dep]:
            return pkg_map[dep][pm]
        return None
    
    def resolve_dependencies(self, tool: Tool) -> List[str]:
        """
        Resolve all dependencies for a tool
        Returns list of package names to install
        """
        deps = []
        pm = self.system_info.package_manager
        
        # Add explicit dependencies
        for dep in tool.dependencies:
            if dep not in self.resolved_cache:
                # Check if dependency is available
                if self.shell.which(dep):
                    self.resolved_cache[dep] = True
                    continue
                
                pkg = self.map_dependency_package(dep)
                if pkg:
                    deps.append(pkg)
                    self.resolved_cache[dep] = True
        
        return deps

    def source_base_dependencies(self, tool: Tool) -> List[str]:
        """Base dependencies needed for source installs"""
        if not tool.source:
            return []

        source_type = tool.source.get("type")
        if not source_type:
            return []
        base = {
            "python-git": ["python3", "python3-venv", "python3-pip", "git"],
            "ruby-git": ["ruby", "ruby-bundler", "git"],
            "go": ["golang", "git"],
            "git-bash": ["git"],
            "git": ["git"],
            "pip": ["python3", "python3-pip"],
            "deb": ["wget"],
            "wine-binary": ["wine", "wget", "unzip"],
        }.get(source_type, [])

        packages = []
        for dep in base:
            pkg = self.map_dependency_package(dep)
            if pkg:
                packages.append(pkg)
        return packages
    
    def calculate_total_size(self, tool: Tool) -> float:
        """Calculate total installation size in MB"""
        return tool.metrics.estimated_size_mb + tool.metrics.dependencies_size_mb
    
    def check_resources(self, tool: Tool) -> Dict[str, object]:
        """Check if system has enough resources"""
        total_size_gb = self.calculate_total_size(tool) / 1024
        
        return {
            "disk_ok": self.system_info.available_disk_gb >= total_size_gb,
            "ram_ok": self.system_info.available_ram_mb >= tool.metrics.ram_required_mb,
            "disk_available": self.system_info.available_disk_gb,
            "disk_required": total_size_gb,
            "ram_available": self.system_info.available_ram_mb,
            "ram_required": tool.metrics.ram_required_mb
        }


class PackageInstaller:
    """Handles package installation across different package managers"""
    
    def __init__(self, shell: Shell, system_info: SystemInfo):
        self.shell = shell
        self.system_info = system_info
        self._updated = False

    @staticmethod
    def _as_text(value) -> str:
        if isinstance(value, (bytes, bytearray)):
            return value.decode(errors="ignore")
        return value or ""
    
    def ensure_root(self):
        """Ensure running as root"""
        if os.geteuid() != 0:
            raise SystemExit("ERROR: This operation requires root privileges. Please run with sudo.")
    
    def apt_install(self, packages: List[str]):
        """Install packages using apt"""
        if not self._updated:
            self.shell.run(["apt", "update", "-y"])
            self._updated = True
        try:
            self.shell.run([
                "env", "DEBIAN_FRONTEND=noninteractive",
                "apt", "install", "-y", "--no-install-recommends", *packages
            ])
        except subprocess.CalledProcessError:
            # Retry with downgrades
            self.shell.run([
                "env", "DEBIAN_FRONTEND=noninteractive",
                "apt", "install", "-y", "--allow-downgrades", 
                "--no-install-recommends", *packages
            ])
    
    def dnf_install(self, packages: List[str]):
        """Install packages using dnf"""
        self.shell.run(["dnf", "-y", "install", *packages])
    
    def pacman_install(self, packages: List[str]):
        """Install packages using pacman"""
        if not self._updated:
            self.shell.run(["pacman", "-Sy", "--noconfirm"])
            self._updated = True
        self.shell.run(["pacman", "-S", "--noconfirm", *packages])
    
    def zypper_install(self, packages: List[str]):
        """Install packages using zypper"""
        if not self._updated:
            self.shell.run(["zypper", "--non-interactive", "refresh"])
            self._updated = True
        self.shell.run(["zypper", "--non-interactive", "install", 
                       "--no-recommends", *packages])
    
    def install_packages(self, packages: List[str]):
        """Install packages using detected package manager"""
        pm = self.system_info.package_manager
        installers = {
            "apt": self.apt_install,
            "dnf": self.dnf_install,
            "yum": self.dnf_install,
            "pacman": self.pacman_install,
            "zypper": self.zypper_install
        }
        
        if pm not in installers:
            raise SystemExit(f"Unsupported package manager: {pm}")
        
        print(f"\nInstalling {len(packages)} package(s) using {pm}...")
        installers[pm](packages)
        print("Package installation complete")

    def is_package_available(self, package: str) -> bool:
        """Check if a package is available in the detected package manager"""
        pm = self.system_info.package_manager

        if pm == "apt":
            result = self.shell.run(["apt-cache", "policy", package], check=False, capture=True)
            output = self._as_text(result.stdout) + self._as_text(result.stderr)
            if "Unable to locate package" in output or "N: Unable to locate package" in output:
                return False
            if "Candidate: (none)" in output:
                return False
            if "Candidate:" in output:
                return True

            result = self.shell.run(["apt-cache", "show", package], check=False, capture=True)
            output = self._as_text(result.stdout) + self._as_text(result.stderr)
            if "No packages found" in output or "Unable to locate package" in output:
                return False
            return result.returncode == 0 and bool(output.strip())

        if pm in {"dnf", "yum"}:
            result = self.shell.run([pm, "list", "available", package], check=False, capture=True)
            output = self._as_text(result.stdout) + self._as_text(result.stderr)
            if "No matching Packages" in output:
                return False
            return result.returncode == 0

        if pm == "pacman":
            result = self.shell.run(["pacman", "-Si", package], check=False, capture=True)
            output = self._as_text(result.stdout) + self._as_text(result.stderr)
            if "error: package" in output and "was not found" in output:
                return False
            return result.returncode == 0

        if pm == "zypper":
            result = self.shell.run(["zypper", "--non-interactive", "info", package], check=False, capture=True)
            output = self._as_text(result.stdout) + self._as_text(result.stderr)
            if "not found" in output.lower():
                return False
            return result.returncode == 0

        # Default to True for other package managers
        return True


class ToolLoader:
    """Load and manage tools from database"""
    
    @staticmethod
    def load_kali_tools() -> Dict[str, Tool]:
        """Load tools from Kali tools database"""
        if yaml is None:
            raise SystemExit("PyYAML is required. Install with: pip install pyyaml")
        
        if not KALI_TOOLS_PATH.exists():
            raise SystemExit(f"Kali tools database not found: {KALI_TOOLS_PATH}")
        
        with open(KALI_TOOLS_PATH, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        
        tools = {}
        for category, category_tools in data.items():
            if not isinstance(category_tools, dict):
                continue

            # If this looks like a single tool spec (top-level tool), load it directly
            if any(key in category_tools for key in ["binary", "description", "packages", "metrics", "tags"]):
                spec = category_tools
                metrics_data = spec.get("metrics", {})
                tools[category] = Tool(
                    name=category,
                    binary=spec.get("binary", category),
                    category=ToolCategory.STANDARD,
                    description=spec.get("description", ""),
                    packages=spec.get("packages", {}),
                    source=spec.get("source"),
                    dependencies=spec.get("dependencies", []),
                    metrics=ToolMetrics(
                        estimated_size_mb=metrics_data.get("estimated_size_mb", 10.0),
                        dependencies_size_mb=metrics_data.get("dependencies_size_mb", 5.0),
                        ram_required_mb=metrics_data.get("ram_required_mb", 128),
                        compatibility_score=0  # Will be calculated
                    ),
                    kali_metapackage=spec.get("kali_metapackage"),
                    tags=spec.get("tags", [])
                )
                continue
            
            # Otherwise, treat as a category with tools inside
            for name, spec in category_tools.items():
                if not isinstance(spec, dict):
                    continue
                
                metrics_data = spec.get("metrics", {})
                tools[name] = Tool(
                    name=name,
                    binary=spec.get("binary", name),
                    category=ToolCategory.STANDARD,
                    description=spec.get("description", ""),
                    packages=spec.get("packages", {}),
                    source=spec.get("source"),
                    dependencies=spec.get("dependencies", []),
                    metrics=ToolMetrics(
                        estimated_size_mb=metrics_data.get("estimated_size_mb", 10.0),
                        dependencies_size_mb=metrics_data.get("dependencies_size_mb", 5.0),
                        ram_required_mb=metrics_data.get("ram_required_mb", 128),
                        compatibility_score=0  # Will be calculated
                    ),
                    kali_metapackage=spec.get("kali_metapackage"),
                    tags=spec.get("tags", [])
                )
        
        return tools
    
    @staticmethod
    def get_installed_tools(all_tools: Dict[str, Tool]) -> List[Tool]:
        """Get list of currently installed tools"""
        installed_names = StateManager.get_installed_tools()
        return [all_tools[name] for name in installed_names if name in all_tools]
    
    @staticmethod
    def get_standard_tools(all_tools: Dict[str, Tool]) -> List[Tool]:
        """Get list of standard HakPak tools"""
        # Standard tools are the core set
        standard_names = [
            "nmap", "netcat", "hydra", "john", "sqlmap", "nikto",
            "metasploit-framework", "wireshark", "aircrack-ng", 
            "burpsuite", "gobuster", "ffuf", "hashcat", "ipcalc",
            "msfconsole", "scapy", "hping3", "slowloris", "wifite2",
            "responder"
        ]
        return [all_tools[name] for name in standard_names if name in all_tools]
    
    @staticmethod
    def get_custom_tools(all_tools: Dict[str, Tool]) -> List[Tool]:
        """Get list of custom/extended Kali tools"""
        custom_names = StateManager.get_custom_tools()
        return [all_tools[name] for name in custom_names if name in all_tools]


@dataclass
class InstallPlanItem:
    tool: Tool
    method: str  # native | source | skip
    package: Optional[str]
    dependencies: List[str]
    reason: Optional[str] = None


@dataclass
class InstallPlan:
    items: List[InstallPlanItem]
    dependency_packages: List[str]
    skipped: List[InstallPlanItem]
    low_ram: List[InstallPlanItem]
    insufficient_disk: List[InstallPlanItem]


def build_install_plan(tools: List[Tool], system_info: SystemInfo, shell: Shell) -> InstallPlan:
    """Preflight checks for all selected tools and build an install plan"""
    resolver = DependencyResolver(shell, system_info)
    installer = PackageInstaller(shell, system_info)
    pm = system_info.package_manager

    items: List[InstallPlanItem] = []
    dep_packages: List[str] = []
    skipped: List[InstallPlanItem] = []
    low_ram: List[InstallPlanItem] = []
    insufficient_disk: List[InstallPlanItem] = []

    for tool in tools:
        resources = resolver.check_resources(tool)
        if not resources["disk_ok"]:
            item = InstallPlanItem(tool=tool, method="skip", package=None, dependencies=[],
                                   reason="insufficient disk")
            items.append(item)
            skipped.append(item)
            insufficient_disk.append(item)
            continue

        pkg = tool.packages.get(pm) if tool.packages else None
        method = None
        if pkg and installer.is_package_available(pkg):
            method = "native"
        elif tool.source:
            method = "source"
        else:
            method = "skip"

        deps = resolver.resolve_dependencies(tool)
        if method == "source":
            deps.extend(resolver.source_base_dependencies(tool))

        deps = [d for d in deps if d]
        if deps:
            dep_packages.extend(deps)

        if method == "skip":
            reason = "no supported install method for this system"
            if pkg and not installer.is_package_available(pkg):
                reason = f"package '{pkg}' not available via {pm}"
            item = InstallPlanItem(tool=tool, method=method, package=pkg, dependencies=deps, reason=reason)
            items.append(item)
            skipped.append(item)
            continue

        item = InstallPlanItem(tool=tool, method=method, package=pkg, dependencies=deps)
        items.append(item)
        if not resources["ram_ok"]:
            low_ram.append(item)

    # Deduplicate dependency packages and filter unavailable ones
    unique_deps = []
    seen = set()
    for dep in dep_packages:
        if dep in seen:
            continue
        seen.add(dep)
        if installer.is_package_available(dep):
            unique_deps.append(dep)
    return InstallPlan(items=items, dependency_packages=unique_deps,
                       skipped=skipped, low_ram=low_ram, insufficient_disk=insufficient_disk)


def execute_install_plan(plan: InstallPlan, system_info: SystemInfo, shell: Shell):
    """Install dependencies first, then tools based on plan"""
    installable = [i for i in plan.items if i.method in {"native", "source"}]
    if not installable:
        print("\nNo installable tools after preflight checks.")
        return

    print("\n" + "="*70)
    print("  PRE-INSTALL SUMMARY")
    print("="*70)
    print(f"  Total selected: {len(plan.items)}")
    print(f"  Installable:    {len(installable)}")
    print(f"  Native:         {len([i for i in installable if i.method == 'native'])}")
    print(f"  Source:         {len([i for i in installable if i.method == 'source'])}")
    print(f"  Skipped:        {len(plan.skipped)}")
    if plan.skipped:
        print("\n  Skipped tools:")
        for item in plan.skipped:
            print(f"   - {item.tool.name}: {item.reason}")
    if plan.low_ram:
        print("\n  Low RAM warnings:")
        for item in plan.low_ram:
            print(f"   - {item.tool.name} (requires {format_size(item.tool.metrics.ram_required_mb)})")

    confirm = input("\nProceed with dependency optimization and install? (y/N): ").strip().lower()
    if confirm != "y":
        return

    installer = PackageInstaller(shell, system_info)
    installer.ensure_root()

    # Install dependencies up front
    if plan.dependency_packages:
        print("\nOptimizing dependencies before tool installs...")
        installer.install_packages(plan.dependency_packages)

    # Install tools
    for item in installable:
        try:
            if item.method == "native":
                pkg = item.package
                if not pkg:
                    print(f"\nERROR: Missing package mapping for {item.tool.name}")
                    continue
                if not installer.is_package_available(pkg):
                    if item.tool.source:
                        print(f"\nPackage '{pkg}' not available via {system_info.package_manager}. Falling back to source...")
                        install_from_source(item.tool, shell, system_info)
                        StateManager.mark_installed(item.tool.name, "source", "custom")
                        print(f"\nSuccessfully installed {item.tool.name} from source")
                    else:
                        print(f"\nSKIPPED: Package '{pkg}' not available via {system_info.package_manager}")
                    continue

                print(f"\nInstalling native package for {item.tool.name}...")
                installer.install_packages([pkg])
                StateManager.mark_installed(item.tool.name, "native", "standard")
                print(f"\nSuccessfully installed {item.tool.name}")
            else:
                print(f"\nInstalling {item.tool.name} from source...")
                install_from_source(item.tool, shell, system_info)
                StateManager.mark_installed(item.tool.name, "source", "custom")
                print(f"\nSuccessfully installed {item.tool.name} from source")
        except Exception as e:
            print(f"\nERROR: Installation failed for {item.tool.name}: {e}")


def print_tool_list(tools: List[Tool], system_info: SystemInfo, title: str):
    """Display formatted tool list with metrics"""
    if not tools:
        print(f"\n{title}: None\n")
        return

    state = StateManager.load_state()
    installed_state = state.get("installed", {})
    
    print(f"\n{'='*80}")
    print(f"  {title}")
    print('='*80)
    print(f"{'Tool':<20} {'Compat':<10} {'Size':<12} {'RAM':<10} {'Method':<10} {'Description':<25}")
    print('-'*90)
    
    for tool in sorted(tools, key=lambda t: t.name):
        score = CompatibilityScorer.score_tool(tool, system_info)
        tool.metrics.compatibility_score = score
        
        size = format_size(tool.metrics.estimated_size_mb + 
                          tool.metrics.dependencies_size_mb)
        ram = format_size(tool.metrics.ram_required_mb)
        compat = format_compatibility(score)
        desc = tool.description[:25] + "..." if len(tool.description) > 25 else tool.description
        
        method = installed_state.get(tool.name, {}).get("method", "-")
        print(f"{tool.name:<20} {compat:<18} {size:<12} {ram:<10} {method:<10} {desc:<25}")
    
    print('='*90 + '\n')


def menu_list_tools(system_info: SystemInfo):
    """Enhanced list tools menu with categorization"""
    all_tools = ToolLoader.load_kali_tools()
    
    while True:
        print("\n" + "="*60)
        print("  LIST TOOLS")
        print("="*60)
        print("  1) Installed Tools")
        print("  2) Standard Tools (HakPak core)")
        print("  3) Custom Tools (Extended Kali)")
        print("  4) All Available Tools")
        print("  5) Search Tools by Name/Tag")
        print("  0) Back to Main Menu")
        print("="*60)
        
        choice = input("\nYour choice: ").strip()
        
        if choice == '1':
            installed = ToolLoader.get_installed_tools(all_tools)
            print_tool_list(installed, system_info, 
                          f"INSTALLED TOOLS ({len(installed)})")
        
        elif choice == '2':
            standard = ToolLoader.get_standard_tools(all_tools)
            print_tool_list(standard, system_info,
                          f"STANDARD TOOLS ({len(standard)})")
        
        elif choice == '3':
            custom = ToolLoader.get_custom_tools(all_tools)
            custom_available = [t for t in all_tools.values() 
                               if t.name not in [x.name for x in ToolLoader.get_standard_tools(all_tools)]]
            print_tool_list(custom_available, system_info,
                          f"CUSTOM/EXTENDED TOOLS ({len(custom_available)})")
        
        elif choice == '4':
            print_tool_list(list(all_tools.values()), system_info,
                          f"ALL AVAILABLE TOOLS ({len(all_tools)})")
        
        elif choice == '5':
            query = input("\nEnter search term (name/tag): ").strip().lower()
            if query:
                matches = [t for t in all_tools.values() 
                          if query in t.name.lower() or 
                          any(query in tag for tag in t.tags)]
                print_tool_list(matches, system_info,
                              f"SEARCH RESULTS: '{query}' ({len(matches)} matches)")
        
        elif choice == '0':
            break
        
        input("\nPress Enter to continue...")


def configure_install_params() -> InstallParams:
    """Interactive parameter configuration for installation filters"""
    print("\n" + "="*70)
    print("  INSTALLATION FILTER PARAMETERS")
    print("="*70)
    print("Configure filters to customize which tools to install.")
    print("Press Enter to skip any parameter (use default).\n")
    
    params = InstallParams()
    
    # Compatibility filter
    print("\nCompatibility Score Filter:")
    print("   Filter tools by compatibility with your system (0-100)")
    min_compat = input("   Minimum compatibility % [0]: ").strip()
    if min_compat and min_compat.isdigit():
        params.min_compatibility = max(0, min(100, int(min_compat)))
    
    max_compat = input("   Maximum compatibility % [100]: ").strip()
    if max_compat and max_compat.isdigit():
        params.max_compatibility = max(0, min(100, int(max_compat)))
    
    # Size filter
    print("\nSize Filter:")
    print("   Limit tools by installation size")
    max_size = input("   Maximum size in MB [no limit]: ").strip()
    if max_size and max_size.replace('.', '').isdigit():
        params.max_size_mb = float(max_size)
    
    # RAM filter
    print("\nRAM Filter:")
    print("   Limit tools by RAM requirements")
    max_ram = input("   Maximum RAM in MB [no limit]: ").strip()
    if max_ram and max_ram.isdigit():
        params.max_ram_mb = int(max_ram)
    
    # Tag filters
    print("\nTag Filter:")
    print("   Filter by tool tags (e.g., 'web', 'network', 'crypto')")
    tags_input = input("   Include tags (comma-separated) [all]: ").strip()
    if tags_input:
        params.tags_filter = [t.strip() for t in tags_input.split(',') if t.strip()]
    
    exclude_input = input("   Exclude tags (comma-separated) [none]: ").strip()
    if exclude_input:
        params.exclude_tags = [t.strip() for t in exclude_input.split(',') if t.strip()]
    
    # Count limit
    print("\nCount Limit:")
    print("   Maximum number of tools to install")
    max_count = input("   Maximum tools [no limit]: ").strip()
    if max_count and max_count.isdigit():
        params.max_count = int(max_count)
    
    # Display summary
    print("\n" + "="*70)
    print("  FILTER SUMMARY")
    print("="*70)
    print(f"  Compatibility:   {params.min_compatibility}% - {params.max_compatibility}%")
    print(f"  Max Size:        {params.max_size_mb if params.max_size_mb else 'No limit'} MB")
    print(f"  Max RAM:         {params.max_ram_mb if params.max_ram_mb else 'No limit'} MB")
    print(f"  Include Tags:    {', '.join(params.tags_filter) if params.tags_filter else 'All'}")
    print(f"  Exclude Tags:    {', '.join(params.exclude_tags) if params.exclude_tags else 'None'}")
    print(f"  Max Count:       {params.max_count if params.max_count else 'No limit'}")
    print("="*70)
    
    confirm = input("\nUse these filters? (Y/n): ").strip().lower()
    if confirm == 'n':
        return InstallParams()  # Return defaults
    
    return params


def menu_install_tools(system_info: SystemInfo, params: Optional[InstallParams] = None):
    """Enhanced install tools menu with smart ranking and parameter filtering"""
    shell = Shell()
    all_tools = ToolLoader.load_kali_tools()
    installed_names = set(StateManager.get_installed_tools())
    
    # Use provided params or defaults
    if params is None:
        params = InstallParams()
    
    # Apply parameter filters
    filtered_tools = [
        tool for tool in all_tools.values()
        if params.matches(tool, system_info)
    ]
    
    if not filtered_tools:
        print("\nERROR: No tools match the current filter parameters!")
        print("Try adjusting your filters or use default settings.")
        input("\nPress Enter to continue...")
        return

    # Remove already installed tools
    not_installed = [
        tool for tool in filtered_tools
        if tool.name not in installed_names and not shell.which(tool.binary)
    ]

    if not not_installed:
        print("\nAll matching tools are already installed.")
        input("\nPress Enter to continue...")
        return
    
    # Rank tools by compatibility
    ranked_tools = sorted(
        not_installed,
        key=lambda t: CompatibilityScorer.score_tool(t, system_info),
        reverse=True
    )
    
    # Apply max count limit
    if params.max_count:
        ranked_tools = ranked_tools[:params.max_count]
    
    print("\n" + "="*80)
    print("  INSTALL TOOLS (Best matches for your system listed first)")
    print("="*80)
    
    # Display active filters
    if params.min_compatibility > 0 or params.max_size_mb or params.max_ram_mb or params.tags_filter or params.exclude_tags:
        print("\nActive Filters:")
        if params.min_compatibility > 0:
            print(f"   • Compatibility ≥ {params.min_compatibility}%")
        if params.max_compatibility < 100:
            print(f"   • Compatibility ≤ {params.max_compatibility}%")
        if params.max_size_mb:
            print(f"   • Size ≤ {params.max_size_mb} MB")
        if params.max_ram_mb:
            print(f"   • RAM ≤ {params.max_ram_mb} MB")
        if params.tags_filter:
            print(f"   • Include tags: {', '.join(params.tags_filter)}")
        if params.exclude_tags:
            print(f"   • Exclude tags: {', '.join(params.exclude_tags)}")
        if params.max_count:
            print(f"   • Max count: {params.max_count}")
        print(f"\n   {len(ranked_tools)} tools match your filters (not installed)")
    
    # Show top matches (up to 20)
    display_count = min(20, len(ranked_tools))
    print(f"\nTop {display_count} Recommended Tools for Your System:\n")
    for i, tool in enumerate(ranked_tools[:display_count], 1):
        score = CompatibilityScorer.score_tool(tool, system_info)
        size = format_size(tool.metrics.estimated_size_mb + 
                          tool.metrics.dependencies_size_mb)
        print(f"  {i:2}. {tool.name:<20} {format_compatibility(score):<18} "
              f"{size:<12} {tool.description[:35]}")
    
    print("\n" + "-"*80)
    print("Enter tool names (comma or space separated)")
    print(f"   Type 'all' to install ALL {len(ranked_tools)} available tools (not installed, within filter parameters)")
    print(f"   Type 'best20' to install top 20 best for your system")
    print(f"   Type 'top5' to install top 5 best for your system")
    print("   Type 'search' to find specific tools | 'filter' to configure parameters")
    print("-"*80)
    
    raw = input("\nEnter tools to install: ").strip()
    
    if not raw:
        return
    
    if raw.lower() == 'filter':
        new_params = configure_install_params()
        menu_install_tools(system_info, new_params)
        return
    
    if raw.lower() == 'search':
        query = input("Search for: ").strip().lower()
        matches = [t for t in filtered_tools 
                  if query in t.name.lower() or any(query in tag for tag in t.tags)]
        print_tool_list(matches, system_info, f"Search: '{query}'")
        return
    
    # Parse tool selection
    if raw.lower() == 'all':
        # Install ALL available tools (within filter parameters if set)
        selected_names = [t.name for t in ranked_tools]
    elif raw.lower() == 'best20':
        # Install top 20 best tools for the system
        selected_names = [t.name for t in ranked_tools[:min(20, len(ranked_tools))]]
    elif raw.lower() == 'top5':
        # Install top 5 best tools for the system
        selected_names = [t.name for t in ranked_tools[:min(5, len(ranked_tools))]]
    else:
        selected_names = [p.strip() for chunk in raw.split(',') 
                         for p in chunk.split() if p.strip()]
    
    # Validate selection
    selected_tools = []
    for name in selected_names:
        if name not in all_tools:
            print(f"ERROR: Unknown tool: {name}")
            continue
        selected_tools.append(all_tools[name])

    if not selected_tools:
        return

    # Preflight and batch install with dependency optimization
    plan = build_install_plan(selected_tools, system_info, shell)
    execute_install_plan(plan, system_info, shell)


def install_tool(tool: Tool, system_info: SystemInfo, shell: Shell):
    """Install a single tool with dependency resolution"""
    print(f"\n{'='*70}")
    print(f"  Installing: {tool.name}")
    print('='*70)
    
    # Check resources
    resolver = DependencyResolver(shell, system_info)
    resources = resolver.check_resources(tool)
    
    print(f"  Description:  {tool.description}")
    print(f"  Size:         {format_size(resolver.calculate_total_size(tool))}")
    print(f"  RAM Required: {format_size(tool.metrics.ram_required_mb)}")
    print(f"  Disk:         {resources['disk_available']:.2f} GB available, "
          f"{resources['disk_required']:.2f} GB required")
    print(f"  RAM:          {resources['ram_available']} MB available, "
          f"{resources['ram_required']} MB required")
    
    if not resources['disk_ok']:
        print(f"\nERROR: Insufficient disk space!")
        return
    
    if not resources['ram_ok']:
        print(f"\nWARNING: Low RAM may cause installation issues")
        confirm = input("Continue anyway? (y/N): ").strip().lower()
        if confirm != 'y':
            return
    
    # Resolve dependencies
    print(f"\nResolving dependencies...")
    deps = resolver.resolve_dependencies(tool)
    if tool.source:
        deps.extend(resolver.source_base_dependencies(tool))
    if deps:
        print(f"  Dependencies: {', '.join(deps)}")
    
    # Install
    try:
        installer = PackageInstaller(shell, system_info)
        installer.ensure_root()
        
        pm = system_info.package_manager
        if pm in tool.packages:
            # Native installation
            pkg = tool.packages[pm]
            if not installer.is_package_available(pkg):
                if tool.source:
                    print(f"\nPackage '{pkg}' not available via {pm}. Falling back to source install...")
                    install_from_source(tool, shell, system_info)
                    StateManager.mark_installed(tool.name, "source", "custom")
                    print(f"\nSuccessfully installed {tool.name} from source")
                else:
                    print(f"\nSKIPPED: Package '{pkg}' not available via {pm} and no source fallback is defined.")
                return

            all_packages = deps + [pkg]
            installer.install_packages(all_packages)
            
            # Mark as installed
            StateManager.mark_installed(tool.name, "native", "standard")
            print(f"\nSuccessfully installed {tool.name}")
        
        elif tool.source:
            # Source installation
            print(f"\nInstalling from source...")
            if deps:
                installer.install_packages(deps)
            install_from_source(tool, shell, system_info)
            StateManager.mark_installed(tool.name, "source", "custom")
            print(f"\nSuccessfully installed {tool.name} from source")
        
        else:
            print(f"\nERROR: No installation method available for {tool.name} on {pm}")
    
    except Exception as e:
        print(f"\nERROR: Installation failed: {e}")


def install_from_source(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install tool from source"""
    if not tool.source:
        raise ValueError("No source installation method defined")
    
    source_type = tool.source.get("type")
    
    if source_type == "go":
        install_go_tool(tool, shell, system_info)
    elif source_type == "python-git":
        install_python_git_tool(tool, shell, system_info)
    elif source_type == "ruby-git":
        install_ruby_git_tool(tool, shell, system_info)
    elif source_type == "git-bash":
        install_git_bash_tool(tool, shell, system_info)
    elif source_type == "git":
        install_git_repo(tool, shell, system_info)
    elif source_type == "pip":
        install_pip_tool(tool, shell, system_info)
    elif source_type == "deb":
        install_deb_package(tool, shell, system_info)
    elif source_type == "wine-binary":
        install_wine_binary(tool, shell, system_info)
    else:
        raise ValueError(f"Unknown source type: {source_type}")


def install_go_tool(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install Go-based tool"""
    source = tool.source or {}
    if not shell.which("go"):
        print("  Installing Go toolchain...")
        installer = PackageInstaller(shell, system_info)
        pm = system_info.package_manager
        go_pkg = {"apt": "golang", "dnf": "golang", "pacman": "go", "zypper": "go"}
        installer.install_packages([go_pkg.get(pm, "golang")])
    
    module = source.get("module")
    if not module:
        raise ValueError("Missing Go module for source install")
    print(f"  Building from Go module: {module}")
    shell.run(["go", "install", f"{module}@latest"])
    
    # Link binary
    gopath = os.environ.get("GOPATH") or str(Path.home() / "go")
    bin_src = Path(gopath) / "bin" / tool.binary
    if bin_src.exists():
        bin_dst = BIN_LINK_DIR / tool.binary
        bin_dst.parent.mkdir(parents=True, exist_ok=True)
        if bin_dst.exists():
            bin_dst.unlink()
        bin_dst.symlink_to(bin_src)


def install_python_git_tool(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install Python tool from Git"""
    source = tool.source or {}
    repo = source.get("repo")
    if not repo:
        raise ValueError("Missing repo for python-git source install")
    src_dir = HAKPAK3_ROOT / "src" / tool.name
    entry = source.get("entry") or tool.binary
    
    # Clone repository
    if src_dir.exists():
        shell.run(["git", "-C", str(src_dir), "pull"])
    else:
        shell.run(["git", "clone", "--depth", "1", repo, str(src_dir)])
    
    # Create virtual environment
    venv_dir = HAKPAK3_ROOT / "venv" / tool.name
    venv_dir.parent.mkdir(parents=True, exist_ok=True)
    shell.run(["python3", "-m", "venv", str(venv_dir)])
    
    # Install requirements
    pip = venv_dir / "bin" / "pip"
    shell.run([str(pip), "install", "--upgrade", "pip"])
    
    req_file = src_dir / "requirements.txt"
    if req_file.exists():
        shell.run([str(pip), "install", "-r", str(req_file)])
    
    # Create wrapper script
    wrapper = BIN_LINK_DIR / tool.binary
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        f"#!/bin/bash\n"
        f"exec {venv_dir}/bin/python {src_dir}/{entry} \"$@\"\n"
    )
    wrapper.chmod(0o755)


def install_ruby_git_tool(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install Ruby tool from Git"""
    # Similar to Python, but using bundler
    source = tool.source or {}
    repo = source.get("repo")
    if not repo:
        raise ValueError("Missing repo for ruby-git source install")
    src_dir = HAKPAK3_ROOT / "src" / tool.name
    
    if src_dir.exists():
        shell.run(["git", "-C", str(src_dir), "pull"])
    else:
        shell.run(["git", "clone", "--depth", "1", repo, str(src_dir)])
    
    # Install with bundler
    shell.run(["bash", "-c", f"cd {src_dir} && bundle install"], check=False)
    
    # Create wrapper
    entry = source.get("entry") or tool.binary
    wrapper = BIN_LINK_DIR / tool.binary
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        f"#!/bin/bash\n"
        f"cd {src_dir}\n"
        f"exec bundle exec {entry} \"$@\"\n"
    )
    wrapper.chmod(0o755)


def install_git_bash_tool(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install bash-based tool from Git"""
    source = tool.source or {}
    repo = source.get("repo")
    entry = source.get("entry")
    if not repo:
        raise ValueError("Missing repo for git-bash source install")
    if not entry:
        raise ValueError("Missing entry for git-bash source install")
    src_dir = HAKPAK3_ROOT / "src" / tool.name
    
    if src_dir.exists():
        shell.run(["git", "-C", str(src_dir), "pull"])
    else:
        shell.run(["git", "clone", "--depth", "1", repo, str(src_dir)])
    
    # Create wrapper
    wrapper = BIN_LINK_DIR / tool.binary
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        f"#!/bin/bash\n"
        f"exec bash {src_dir}/{entry} \"$@\"\n"
    )
    wrapper.chmod(0o755)


def install_git_repo(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Clone a generic git repo and optionally create a wrapper if entry is defined"""
    source = tool.source or {}
    repo = source.get("repo")
    entry = source.get("entry")
    if not repo:
        raise ValueError("Missing repo for git source install")
    src_dir = HAKPAK3_ROOT / "src" / tool.name

    if src_dir.exists():
        shell.run(["git", "-C", str(src_dir), "pull"])
    else:
        shell.run(["git", "clone", "--depth", "1", repo, str(src_dir)])

    if entry:
        wrapper = BIN_LINK_DIR / tool.binary
        wrapper.parent.mkdir(parents=True, exist_ok=True)
        wrapper.write_text(
            f"#!/bin/bash\n"
            f"cd {src_dir}\n"
            f"exec bash {src_dir}/{entry} \"$@\"\n"
        )
        wrapper.chmod(0o755)
    else:
        print(f"  Installed repo to {src_dir}. No entry point provided; wrapper not created.")


def install_pip_tool(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Install tool via pip"""
    source = tool.source or {}
    package = source.get("package") or source.get("module")
    if not package:
        raise ValueError("Missing package for pip source install")
    shell.run(["pip3", "install", "--user", package])


def install_deb_package(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Download and install .deb package"""
    source = tool.source or {}
    url = source.get("url")
    if not url:
        raise ValueError("Missing URL for deb source install")
    deb_file = source.get("file") or f"{tool.name}.deb"
    download_path = HAKPAK3_ROOT / "downloads" / deb_file
    
    # Create downloads directory
    download_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Download if not already present
    if not download_path.exists():
        print(f"  Downloading from {url}...")
        shell.run(["wget", "-O", str(download_path), url])
    else:
        print(f"  Using cached download: {download_path}")
    
    # Install the .deb package
    print(f"  Installing {deb_file}...")
    shell.run(["dpkg", "-i", str(download_path)])
    
    # Fix any dependency issues
    print(f"  Fixing dependencies...")
    shell.run(["apt-get", "install", "-f", "-y"], check=False)


def install_wine_binary(tool: Tool, shell: Shell, system_info: SystemInfo):
    """Download and setup Windows binary to run via Wine"""
    source = tool.source or {}
    url = source.get("url")
    archive_file = source.get("file")
    binary_path = source.get("binary_path")
    if not url or not archive_file or not binary_path:
        raise ValueError("Missing fields for wine-binary source install")
    download_path = HAKPAK3_ROOT / "downloads" / archive_file
    extract_dir = HAKPAK3_ROOT / "wine-apps" / tool.name
    
    # Create directories
    download_path.parent.mkdir(parents=True, exist_ok=True)
    extract_dir.parent.mkdir(parents=True, exist_ok=True)
    
    # Download if not already present
    if not download_path.exists():
        print(f"  Downloading from {url}...")
        shell.run(["wget", "-O", str(download_path), url])
    else:
        print(f"  Using cached download: {download_path}")
    
    # Extract archive
    print(f"  Extracting {archive_file}...")
    if archive_file.endswith('.zip'):
        shell.run(["unzip", "-o", str(download_path), "-d", str(extract_dir)])
    elif archive_file.endswith('.tar.gz') or archive_file.endswith('.tgz'):
        shell.run(["tar", "xzf", str(download_path), "-C", str(extract_dir)])
    
    # Create wrapper script
    wine_binary = extract_dir / binary_path
    wrapper = BIN_LINK_DIR / tool.binary
    wrapper.parent.mkdir(parents=True, exist_ok=True)
    wrapper.write_text(
        f"#!/bin/bash\n"
        f"# Wine wrapper for {tool.name}\n"
        f"cd {wine_binary.parent}\n"
        f"exec wine {wine_binary} \"$@\"\n"
    )
    wrapper.chmod(0o755)
    print(f"  Created Wine wrapper: {wrapper}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="HakPak3 - Ultimate Cross-Distro Hacking Tool Installer"
    )
    parser.add_argument("--version", action="store_true", 
                       help="Show version information")
    
    args = parser.parse_args()
    
    if args.version:
        print(f"HakPak3 v{VERSION}")
        return
    
    # Start interactive menu
    cmd_menu()


def cmd_menu():
    """Interactive menu system"""
    shell = Shell()
    system_info = OSDetector.get_system_info(shell)
    
    while True:
        print(banner())
        display_system_info(system_info)
        
        print("="*70)
        print("  MAIN MENU")
        print("="*70)
        print("  1) List Tools")
        print("  2) Install Tools")
        print("  3) Install Tools with Filters (Advanced)")
        print("  4) Uninstall Tools")
        print("  5) Status & Installed Tools")
        print("  6) Repository Management (APT)")
        print("  7) About HakPak3")
        print("  0) Exit")
        print("="*70)
        
        try:
            choice = input("\nYour choice: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n\nGoodbye!")
            return 0
        
        if choice == '' or choice.lower() == 'm':
            continue
        
        if choice == '1':
            menu_list_tools(system_info)
        
        elif choice == '2':
            menu_install_tools(system_info)
        
        elif choice == '3':
            # Install with custom parameters
            params = configure_install_params()
            menu_install_tools(system_info, params)
        
        elif choice == '4':
            print("\nUninstall feature coming soon...")
            input("\nPress Enter to continue...")
        
        elif choice == '5':
            all_tools = ToolLoader.load_kali_tools()
            installed = ToolLoader.get_installed_tools(all_tools)
            print_tool_list(installed, system_info, 
                          f"INSTALLED TOOLS ({len(installed)})")
            input("\nPress Enter to continue...")
        
        elif choice == '6':
            print("\nRepository management coming soon...")
            input("\nPress Enter to continue...")
        
        elif choice == '7':
            print(banner())
            print(developer_info())
            print(disclaimer())
            input("\nPress Enter to continue...")
        
        elif choice == '0':
            print("\nThank you for using HakPak3!")
            return 0
        
        else:
            print("ERROR: Invalid option")
            input("\nPress Enter to continue...")


if __name__ == "__main__":
    main()
