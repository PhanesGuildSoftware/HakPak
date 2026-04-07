#!/usr/bin/env python3
"""
HakPak4 GUI Server – Script Builder & Repository Manager
Flask backend that exposes HakPak4's installed-tool state, kali-tools metadata,
and git-clone repo records to the Web-based script builder UI.

Security: binds to 127.0.0.1 only by default; no authentication tokens are
needed because the server accepts only local connections.  All user-supplied
strings are validated before being written to disk.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from flask import Flask, Response, jsonify, request, send_from_directory

try:
    import yaml
except ImportError:
    yaml = None

# ── Marketing icon directory (served at /icons/<filename>) ────────────────────
_MARKETING_ICONS = Path(os.path.expanduser("~/Marketing/Icons"))

# ── Paths ─────────────────────────────────────────────────────────────────────
_GUI_DIR   = Path(__file__).resolve().parent
_V4_DIR    = _GUI_DIR.parent
_STATIC    = _GUI_DIR / "static"
_STATE     = Path(os.environ.get("HAKPAK4_ROOT", "/opt/hakpak4")) / "state.json"
_REPOS_DIR = Path(os.environ.get("HAKPAK4_REPOS", "/opt/hakpak4/repos"))

# Add v4 root to sys.path so we can import hakpak4 modules directly
if str(_V4_DIR) not in sys.path:
    sys.path.insert(0, str(_V4_DIR))

# Import tool profiles for automatic command generation
try:
    from tool_profiles import TOOL_PROFILES
except ImportError:
    TOOL_PROFILES = {}

# Import license manager
try:
    from gui.lib import license_manager as _lm
except ImportError:
    try:
        from lib import license_manager as _lm
    except ImportError:
        _lm = None  # type: ignore

# ── Flask app ─────────────────────────────────────────────────────────────────
APP = Flask(__name__, static_folder=str(_STATIC), static_url_path="/static")
APP.config["SEND_FILE_MAX_AGE_DEFAULT"] = 0

_TOOL_GROUP_CACHE: dict[str, str] | None = None


# ── Helpers ───────────────────────────────────────────────────────────────────

def _load_state() -> tuple[dict, bool]:
    """Load state.json and indicate whether it was read successfully."""
    try:
        data = json.loads(_STATE.read_text())
        if "script_commands" not in data:
            data["script_commands"] = {}
        return data, True
    except Exception:
        return {"installed": {}, "custom": {}, "git_repos": {}, "script_commands": {}}, False


def _save_state(state: dict) -> bool:
    try:
        _STATE.parent.mkdir(parents=True, exist_ok=True)
        _STATE.write_text(json.dumps(state, indent=2), encoding="utf-8")
        return True
    except Exception:
        return False


def _safe_name(value: str, default: str = "script") -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_\-]", "_", str(value or "")).strip("_")
    return (cleaned or default)[:64]


def _scripts_dir() -> Path:
    return Path.home() / "hakpak4-scripts"


def _bin_dir() -> Path:
    return Path(os.environ.get("HAKPAK4_BIN", "/usr/local/bin"))


def _list_script_commands() -> dict:
    state, _ = _load_state()
    commands = state.get("script_commands", {}) if isinstance(state, dict) else {}
    result = {}
    for cmd_name, meta in commands.items():
        bin_path = Path(meta.get("bin_path", str(_bin_dir() / cmd_name)))
        script_path = Path(meta.get("script_path", ""))
        result[cmd_name] = {
            "command": cmd_name,
            "bin_path": str(bin_path),
            "script_path": str(script_path),
            "exists": bin_path.exists() or bin_path.is_symlink(),
            "script_exists": script_path.exists(),
            "installed_at": meta.get("installed_at", ""),
        }
    return result


def _format_group_label(group_name: str) -> str:
    return group_name.replace("_", " ").strip().title()


def _load_tool_groups() -> dict[str, str]:
    """Map tool names to their YAML top-level group/category label."""
    global _TOOL_GROUP_CACHE
    if _TOOL_GROUP_CACHE is not None:
        return _TOOL_GROUP_CACHE

    groups: dict[str, str] = {}
    if yaml is None:
        _TOOL_GROUP_CACHE = groups
        return groups

    try:
        raw = yaml.safe_load((_V4_DIR / "kali-tools-db.yaml").read_text()) or {}
        for group_name, group_tools in raw.items():
            if not isinstance(group_tools, dict):
                continue

            # Some tools are declared directly at the top level.
            if any(key in group_tools for key in ["binary", "description", "packages", "metrics", "tags"]):
                groups[group_name] = "Utilities"
                continue

            label = _format_group_label(group_name)
            for tool_name, spec in group_tools.items():
                if isinstance(spec, dict):
                    groups[tool_name] = label
    except Exception:
        groups = {}

    _TOOL_GROUP_CACHE = groups
    return groups


def _tokenize_prompt(text: str) -> list[str]:
    return re.findall(r"[a-z0-9][a-z0-9_\-]{1,}", text.lower())


def _find_best_use_case(tool_name: str, prompt_terms: list[str]) -> dict | None:
    use_cases = TOOL_PROFILES.get(tool_name, {}).get("use_cases", [])
    if not use_cases:
        return None

    def score_use_case(use_case: dict) -> int:
        haystack = " ".join([
            use_case.get("label", ""),
            use_case.get("description", ""),
            use_case.get("template", ""),
            " ".join(param.get("label", "") for param in use_case.get("params", [])),
        ]).lower()
        return sum(3 for term in prompt_terms if term in haystack)

    ranked = sorted(use_cases, key=score_use_case, reverse=True)
    return ranked[0] if ranked else None


def _build_use_case_args(tool_name: str, use_case: dict | None) -> str:
    if not use_case:
        return ""

    template = str(use_case.get("template", ""))
    binary = re.escape(tool_name)
    binary_regex = re.compile(rf"^(sudo\s+)?{binary}\s*")
    for param in use_case.get("params", []):
        key = param.get("key", "")
        if key:
            template = template.replace(f"{{{key}}}", f"${key}")
    return binary_regex.sub("", template).strip()


def _find_use_case_by_id(tool_name: str, use_case_id: str) -> dict | None:
    if not use_case_id:
        return None
    use_cases = TOOL_PROFILES.get(tool_name, {}).get("use_cases", [])
    for uc in use_cases:
        if uc.get("id") == use_case_id:
            return uc
    return None


def _advisor_hint_tools(prompt_terms: list[str]) -> set[str]:
    hints = {
        "recon": {"nmap", "amass", "theharvester", "dnsrecon", "masscan"},
        "subdomain": {"amass", "dnsrecon", "gobuster", "ffuf"},
        "web": {"nikto", "gobuster", "ffuf", "sqlmap", "wpscan"},
        "wordpress": {"wpscan", "nikto", "gobuster"},
        "sql": {"sqlmap"},
        "injection": {"sqlmap"},
        "bruteforce": {"hydra", "john", "hashcat"},
        "password": {"hydra", "john", "hashcat"},
        "wireless": {"aircrack-ng", "wifite", "reaver"},
        "wifi": {"aircrack-ng", "wifite", "reaver"},
        "traffic": {"tcpdump", "mitmproxy", "responder"},
        "sniff": {"tcpdump", "mitmproxy", "responder"},
        "firmware": {"binwalk"},
        "exploit": {"msfconsole", "netcat", "socat"},
        "shell": {"netcat", "socat", "msfconsole"},
        "port": {"nmap", "masscan", "rustscan"},
    }
    boosted: set[str] = set()
    for term in prompt_terms:
        boosted.update(hints.get(term, set()))
    return boosted


def _build_blocks_from_suggestions(prompt: str, suggestions: list[dict]) -> list[dict]:
    blocks: list[dict] = []
    seen_vars: set[str] = set()

    if prompt.strip():
        blocks.append({"type": "comment", "text": f"Advisor plan: {prompt.strip()}"})

    for suggestion in suggestions[:3]:
        use_case = suggestion.get("use_case") or {}
        for param in use_case.get("params", []):
            key = str(param.get("key", "")).strip()
            if not key or key in seen_vars:
                continue
            seen_vars.add(key)
            blocks.append({
                "type": "var",
                "name": key,
                "value": str(param.get("placeholder", "")),
            })

        blocks.append({
            "type": "tool",
            "tool": suggestion.get("tool", ""),
            "use_case": use_case.get("id", ""),
            "args": suggestion.get("args_preview", ""),
            "capture": False,
            "output_var": "",
        })

    return blocks


def _build_llm_prompt(prompt: str, tools: dict, installed_only: bool) -> str:
    """Create a constrained prompt for local LLM planning."""
    catalog_lines = []
    for name, meta in sorted(tools.items()):
        if installed_only and not meta.get("installed"):
            continue
        profile_cases = TOOL_PROFILES.get(name, {}).get("use_cases", [])
        case_ids = ", ".join(case.get("id", "") for case in profile_cases[:6] if case.get("id"))
        catalog_lines.append(
            f"- tool={name}; group={meta.get('tool_group','Other')}; tags={','.join(meta.get('tags', []))}; "
            f"desc={meta.get('description','')}; use_cases={case_ids or 'none'}"
        )

    catalog = "\n".join(catalog_lines[:120])
    return (
        "You are a local HakPak script advisor.\n"
        "Return ONLY JSON (no markdown) with this schema:\n"
        "{\n"
        "  \"suggestions\": [\n"
        "    {\"tool\":\"name\",\"use_case\":\"use_case_id_or_empty\",\"args_preview\":\"args\",\"why\":\"reason\"}\n"
        "  ],\n"
        "  \"notes\": [\"text\"]\n"
        "}\n"
        "Use only tools from the catalog below. Keep suggestions to 3-5 items.\n\n"
        f"USER GOAL:\n{prompt}\n\n"
        f"TOOL CATALOG:\n{catalog}\n"
    )


def _build_advisor_plan_with_llm(prompt: str, installed_only: bool, model: str) -> dict | None:
    """Try local LLM (Ollama). Return None when unavailable/failure."""
    if not shutil.which("ollama"):
        return None

    tools = _load_tools()
    llm_prompt = _build_llm_prompt(prompt, tools, installed_only=installed_only)

    try:
        proc = subprocess.run(
            ["ollama", "run", model, llm_prompt],
            capture_output=True,
            text=True,
            timeout=45,
            check=False,
        )
        if proc.returncode != 0:
            return None

        raw = (proc.stdout or "").strip()
        if not raw:
            return None

        # Extract first JSON object if the model included extra text.
        start = raw.find("{")
        end = raw.rfind("}")
        if start == -1 or end == -1 or end <= start:
            return None
        payload = json.loads(raw[start:end + 1])

        llm_suggestions = payload.get("suggestions", []) if isinstance(payload, dict) else []
        notes = payload.get("notes", []) if isinstance(payload, dict) else []
        suggestions: list[dict] = []

        for row in llm_suggestions[:5]:
            if not isinstance(row, dict):
                continue
            tool_name = str(row.get("tool", "")).strip()
            if not tool_name or tool_name not in tools:
                continue
            meta = tools[tool_name]
            use_case_id = str(row.get("use_case", "")).strip()
            use_case = _find_use_case_by_id(tool_name, use_case_id)
            args_preview = str(row.get("args_preview", "")).strip()
            if not args_preview and use_case:
                args_preview = _build_use_case_args(tool_name, use_case)

            suggestions.append({
                "tool": tool_name,
                "group": meta.get("tool_group", "Other"),
                "description": meta.get("description", ""),
                "installed": meta.get("installed", False),
                "use_case": use_case,
                "args_preview": args_preview,
                "why": str(row.get("why", "LLM-selected based on your goal.")).strip(),
            })

        if not suggestions:
            return None

        if not notes:
            notes = ["Generated by local LLM. Review and adjust arguments before export/execution."]

        return {
            "planner": "llm",
            "model": model,
            "suggestions": suggestions,
            "blocks": _build_blocks_from_suggestions(prompt, suggestions),
            "notes": notes,
        }
    except Exception:
        return None


def _build_advisor_plan(prompt: str, installed_only: bool = True) -> dict:
    tools = _load_tools()
    prompt_terms = _tokenize_prompt(prompt)
    boosted = _advisor_hint_tools(prompt_terms)

    ranked: list[tuple[int, dict]] = []
    for tool_name, meta in tools.items():
        if installed_only and not meta.get("installed"):
            continue

        use_case = _find_best_use_case(tool_name, prompt_terms)
        haystack = " ".join([
            tool_name,
            meta.get("description", ""),
            meta.get("tool_group", ""),
            " ".join(meta.get("tags", [])),
            use_case.get("label", "") if use_case else "",
            use_case.get("description", "") if use_case else "",
        ]).lower()

        score = 0
        for term in prompt_terms:
            if term in tool_name.lower():
                score += 5
            elif term in haystack:
                score += 2

        if tool_name in boosted:
            score += 7
        if use_case:
            score += 2
        if meta.get("installed"):
            score += 1

        if score > 0:
            ranked.append((score, {
                "tool": tool_name,
                "group": meta.get("tool_group", "Other"),
                "description": meta.get("description", ""),
                "installed": meta.get("installed", False),
                "use_case": use_case,
                "args_preview": _build_use_case_args(tool_name, use_case),
                "why": f"Matched prompt terms against {meta.get('tool_group', 'tool')} metadata and use-case templates.",
            }))

    ranked.sort(key=lambda item: item[0], reverse=True)
    suggestions = [item[1] for item in ranked[:5]]

    notes = []

    if not suggestions:
        notes.append("No strong local matches found. Try a more specific goal like 'web recon', 'subdomain enumeration', or 'SSH brute force'.")
    else:
        notes.append("Advisor suggestions are heuristic and local-only. Review arguments before export or execution.")

    return {
        "planner": "heuristic",
        "model": None,
        "suggestions": suggestions,
        "blocks": _build_blocks_from_suggestions(prompt, suggestions),
        "notes": notes,
    }


def _load_tools() -> dict:
    """Load kali-tools-db and merge with installed state.

    Installed status uses two sources in priority order:
      1. state.json written by the HakPak4 CLI (single source of truth)
      2. Live PATH check via shutil.which() as a fallback when state.json
         does not yet exist (e.g. dev environment before first install).
    The GUI and CLI therefore share the same backend state.
    """
    try:
        # ToolLoader is defined in hakpak4_core; OS/Shell live in hakpak4.
        from hakpak4_core import ToolLoader
    except ImportError:
        return {}

    try:
        all_tools = ToolLoader.load_kali_tools()
    except BaseException:
        return {}

    state, state_loaded = _load_state()
    installed_in_state = state.get("installed", {}) if isinstance(state, dict) else {}

    results = {}
    for name, tool in all_tools.items():
        # Prefer CLI-managed state; keep PATH fallback so toolbox is never empty
        # when state.json is missing/unreadable in dev contexts.
        in_state = name in installed_in_state
        on_path = bool(shutil.which(tool.binary or name))
        is_installed = bool(in_state or on_path)

        results[name] = {
            "name":        tool.name,
            "binary":      tool.binary,
            "description": tool.description,
            "tags":        tool.tags,
            "category":    tool.category.value,
            "tool_group":  _load_tool_groups().get(name, "Other"),
            "installed":   is_installed,
            "packages":    tool.packages,
            "size_mb":     round(
                tool.metrics.estimated_size_mb + tool.metrics.dependencies_size_mb, 1
            ),
            "has_profile": name in TOOL_PROFILES,
            "_installed_source": "state" if in_state else ("path" if on_path else "none"),
            "_state_loaded": state_loaded,
        }
    return results


def _validate_block_cmd(cmd: str) -> bool:
    """
    Reject commands that contain shell-injection characters when they appear
    in a pipeline or substitution context that the user did not explicitly
    request.  This is a best-effort lint, not a sandbox.
    """
    # We allow most characters; block raw stdin-redirect exploits
    dangerous = re.compile(r">\s*/etc/|>\s*/dev/sd|>\s*/proc/self")
    return not dangerous.search(cmd)


# ── Routes ────────────────────────────────────────────────────────────────────

@APP.route("/")
def index():
    return send_from_directory(str(_STATIC), "index.html")


@APP.get("/icons/<path:filename>")
def marketing_icons(filename: str):
    """Serve marketing/brand icons from ~/Marketing/Icons/.

    Only PNG files with safe names are served to prevent path traversal.
    """
    # Validate: basename only, PNG files
    safe = re.fullmatch(r"[A-Za-z0-9_\-]+\.png", filename)
    if not safe:
        return jsonify({"ok": False, "error": "Invalid icon name"}), 400
    if not _MARKETING_ICONS.is_dir():
        return jsonify({"ok": False, "error": "Icons directory not found"}), 404
    return send_from_directory(str(_MARKETING_ICONS), filename)


_PICTURES_DIR = Path(os.path.expanduser("~/Pictures"))


@APP.get("/pictures/<path:filename>")
def pictures_file(filename: str):
    """Serve image files from ~/Pictures/.

    Only PNG/JPG/JPEG/SVG files with safe names are served.
    """
    safe = re.fullmatch(r"[A-Za-z0-9_\-]+\.(png|jpg|jpeg|svg)", filename, re.IGNORECASE)
    if not safe:
        return jsonify({"ok": False, "error": "Invalid file name"}), 400
    if not _PICTURES_DIR.is_dir():
        return jsonify({"ok": False, "error": "Pictures directory not found"}), 404
    return send_from_directory(str(_PICTURES_DIR), filename)


@APP.get("/api/tools")
def api_tools():
    """Return all known tools with installed status."""
    tools = _load_tools()
    return jsonify({"ok": True, "tools": tools})


@APP.get("/api/installed")
def api_installed():
    """Return only installed tools (from state.json + PATH check)."""
    state, _ = _load_state()
    installed = state.get("installed", {})
    tools = _load_tools()
    result = {
        name: meta
        for name, meta in tools.items()
        if name in installed or shutil.which(meta.get("binary", name))
    }
    return jsonify({"ok": True, "tools": result})


@APP.get("/api/repos")
def api_repos():
    """Return git repos installed via hakpak4 gitclone."""
    state, _ = _load_state()
    repos = state.get("git_repos", {})
    # Attach liveness check (does the path still exist?)
    for name, meta in repos.items():
        meta["exists"] = Path(meta.get("path", "")).exists()
    return jsonify({"ok": True, "repos": repos})


@APP.get("/api/tool/profile/<tool_name>")
def api_tool_profile(tool_name: str):
    """Return use-case profiles for a tool (for automatic command generation)."""
    safe_name = re.sub(r"[^A-Za-z0-9_\-]", "", tool_name)
    profile = TOOL_PROFILES.get(safe_name)
    if profile is None:
        return jsonify({"ok": True, "use_cases": []})
    return jsonify({"ok": True, "tool": safe_name, "use_cases": profile["use_cases"]})


@APP.get("/api/tool/profiles")
def api_all_profiles():
    """Return the list of tools that have profiles (for sidebar badge)."""
    return jsonify({"ok": True, "tools": list(TOOL_PROFILES.keys())})


@APP.post("/api/advisor/plan")
def api_advisor_plan():
    """Local heuristic advisor for suggesting tools, args, and script structure."""
    data = request.get_json(force=True) or {}
    prompt = str(data.get("prompt") or "").strip()
    installed_only = bool(data.get("installed_only", True))
    mode = str(data.get("mode") or "auto").strip().lower()
    model = str(data.get("model") or "llama3.1:8b").strip()

    if not prompt:
        return jsonify({"ok": False, "error": "prompt is required"}), 400

    plan = None

    if mode in {"auto", "llm"}:
        plan = _build_advisor_plan_with_llm(prompt, installed_only=installed_only, model=model)

    if plan is None:
        if mode == "llm":
            # User forced LLM mode but local model path is unavailable/failing.
            fallback = _build_advisor_plan(prompt, installed_only=installed_only)
            fallback["notes"] = [
                "Local LLM planner unavailable (Ollama/model missing or failed).",
                *fallback.get("notes", []),
            ]
            plan = fallback
        else:
            plan = _build_advisor_plan(prompt, installed_only=installed_only)

    return jsonify({"ok": True, **plan})


@APP.get("/api/ollama/status")
def api_ollama_status():
    """Return whether ollama is installed and the service is reachable."""
    installed = bool(shutil.which("ollama"))
    running = False
    models: list[str] = []
    if installed:
        try:
            r = subprocess.run(
                ["ollama", "list"],
                capture_output=True, text=True, timeout=5,
            )
            running = r.returncode == 0
            if running:
                for line in r.stdout.splitlines()[1:]:  # skip header
                    parts = line.split()
                    if parts:
                        models.append(parts[0])
        except Exception:
            pass
    return jsonify({"ok": True, "installed": installed, "running": running, "models": models})


@APP.post("/api/ollama/install")
def api_ollama_install():
    """
    Stream Ollama installation output via Server-Sent Events.
    Runs the official install script (curl pipe sh) in a subprocess.
    Requires the server process to have sufficient privileges; on most
    systems this means running as root or via sudo.
    """
    import urllib.request

    def generate():
        yield "data: Starting Ollama installation…\n\n"
        try:
            # Download the install script to a temp file — never pipe curl directly to sh
            with tempfile.NamedTemporaryFile(
                suffix=".sh", delete=False, mode="wb"
            ) as tmp:
                tmp_path = tmp.name
                req = urllib.request.urlopen(  # noqa: S310 — HTTPS only
                    "https://ollama.com/install.sh", timeout=30
                )
                tmp.write(req.read())

            os.chmod(tmp_path, 0o700)

            proc = subprocess.Popen(
                ["bash", tmp_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            for line in proc.stdout:
                yield f"data: {line.rstrip()}\n\n"
            proc.wait()
            os.unlink(tmp_path)
            if proc.returncode == 0:
                yield "data: \n\n"
                yield "data: ✔ Ollama installed successfully.\n\n"
                yield "event: done\ndata: ok\n\n"
            else:
                yield "data: \n\n"
                yield f"data: ✘ Install exited with code {proc.returncode}.\n\n"
                yield "event: done\ndata: error\n\n"
        except Exception as exc:
            yield f"data: ERROR: {exc}\n\n"
            yield "event: done\ndata: error\n\n"

    return APP.response_class(generate(), mimetype="text/event-stream")


@APP.get("/api/sysinfo")
def api_sysinfo():
    """Return basic system information."""
    try:
        from hakpak4 import OSDetector, Shell
        shell = Shell()
        info = OSDetector.get_system_info(shell)
        return jsonify({
            "ok": True,
            "os":    info.os_name,
            "arch":  info.architecture,
            "pm":    info.package_manager,
            "ram":   info.available_ram_mb,
            "disk":  info.available_disk_gb,
        })
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc)}), 500


@APP.post("/api/script/build")
def api_script_build():
    """
    Build a bash script from a list of blocks.

    Request body:
    {
      "name": "my_scan",
      "description": "Optional banner comment",
      "blocks": [
        {"type": "tool",    "tool": "nmap", "args": "-sV -p 1-1000 $TARGET"},
        {"type": "raw",     "code": "echo Done"},
        {"type": "comment", "text": "Section header"},
        {"type": "var",     "name": "TARGET", "value": "192.168.1.1"},
        {"type": "if",      "condition": "[ $? -eq 0 ]", "then": "echo success"},
      ]
    }

    Returns:
    {
      "ok": true,
      "script": "#!/bin/bash\n..."
    }
    """
    data = request.get_json(force=True) or {}
    name        = re.sub(r"[^A-Za-z0-9_\-]", "_", (data.get("name") or "hakpak_script"))[:64]
    description = str(data.get("description") or "")[:512]
    blocks      = data.get("blocks") or []

    if not isinstance(blocks, list):
        return jsonify({"ok": False, "error": "blocks must be a list"}), 400

    lines = [
        "#!/usr/bin/env bash",
        "# ─────────────────────────────────────────────────────────────────",
        f"#  Script: {name}",
    ]
    if description:
        lines.append(f"#  {description}")
    lines += [
        "#  Generated by HakPak4 Script Builder",
        "# ─────────────────────────────────────────────────────────────────",
        'set -euo pipefail',
        "",
    ]

    for i, block in enumerate(blocks):
        btype = str(block.get("type", "raw")).lower()

        if btype == "comment":
            text = str(block.get("text", "")).replace("\n", " ")[:200]
            lines.append(f"\n# ── {text}")

        elif btype == "var":
            var_name  = re.sub(r"[^A-Za-z0-9_]", "_", str(block.get("name", f"VAR{i}")))
            var_value = str(block.get("value", ""))
            # Shell-quote the value simply by wrapping in single quotes and
            # escaping any embedded single quotes.
            safe_val = var_value.replace("'", "'\\''")
            lines.append(f"{var_name}='{safe_val}'")

        elif btype == "tool":
            tool_name = re.sub(r"[^A-Za-z0-9_\-]", "", str(block.get("tool", "")))
            args      = str(block.get("args", ""))
            capture   = block.get("capture", False)
            output_var = re.sub(r"[^A-Za-z0-9_]", "_", str(block.get("output_var", "")))

            if not tool_name:
                continue

            if not _validate_block_cmd(f"{tool_name} {args}"):
                return jsonify({
                    "ok":    False,
                    "error": f"Block {i}: command targets protected system paths",
                }), 400

            cmd_line = f"{tool_name} {args}".rstrip()
            if capture and output_var:
                lines.append(f'{output_var}=$({cmd_line})')
            else:
                lines.append(cmd_line)

        elif btype == "raw":
            code = str(block.get("code", ""))
            if not _validate_block_cmd(code):
                return jsonify({
                    "ok":    False,
                    "error": f"Block {i}: raw command targets protected system paths",
                }), 400
            lines.append(code)

        elif btype == "if":
            condition = str(block.get("condition", "true"))
            then_cmd  = str(block.get("then", "echo ok"))
            else_cmd  = str(block.get("else", ""))
            lines.append(f"if {condition}; then")
            lines.append(f"  {then_cmd}")
            if else_cmd:
                lines.append("else")
                lines.append(f"  {else_cmd}")
            lines.append("fi")

        elif btype == "for":
            var      = re.sub(r"[^A-Za-z0-9_]", "_", str(block.get("var", "item")))
            iterable = str(block.get("in", '"$@"'))
            body     = str(block.get("do", "echo $item"))
            lines.append(f"for {var} in {iterable}; do")
            lines.append(f"  {body}")
            lines.append("done")

        elif btype == "python":
            code       = str(block.get("code", "")).strip()
            capture    = block.get("capture", False)
            output_var = re.sub(r"[^A-Za-z0-9_]", "_", str(block.get("output_var", "")))

            if not code:
                continue

            # Use a quoted heredoc so bash won't expand $ inside Python source.
            heredoc_token = "PYPAK_EOF"
            if capture and output_var:
                lines.append(f"{output_var}=$(python3 << '{heredoc_token}'")
            else:
                lines.append(f"python3 << '{heredoc_token}'")
            lines.extend(code.splitlines())
            lines.append(heredoc_token)
            if capture and output_var:
                lines.append(")")

        else:
            # Unknown block type – skip
            continue

        lines.append("")  # blank line between blocks

    script = "\n".join(lines) + "\n"
    return jsonify({"ok": True, "script": script, "name": name})


@APP.post("/api/script/save")
def api_script_save():
    """
    Save a generated script to disk.

    Request body: { "name": "my_scan", "script": "#!/usr/bin/env bash\n..." }
    Saves to ~/hakpak4-scripts/<name>.sh
    """
    data   = request.get_json(force=True) or {}
    name   = re.sub(r"[^A-Za-z0-9_\-]", "_", str(data.get("name") or "script"))[:64]
    script = str(data.get("script") or "")

    if not script:
        return jsonify({"ok": False, "error": "script is empty"}), 400

    save_dir = Path.home() / "hakpak4-scripts"
    save_dir.mkdir(parents=True, exist_ok=True)
    dest = save_dir / f"{name}.sh"
    dest.write_text(script, encoding="utf-8")
    dest.chmod(0o750)

    return jsonify({"ok": True, "path": str(dest)})


@APP.get("/api/script/commands")
def api_script_commands():
    """List command links created from exported scripts."""
    bdir = _bin_dir()
    commands = _list_script_commands()
    return jsonify({
        "ok": True,
        "bin_dir": str(bdir),
        "bin_dir_writable": os.access(str(bdir), os.W_OK),
        "commands": commands,
    })


@APP.post("/api/script/command/install")
def api_script_command_install():
    """Save script and optionally install it as a host command."""
    data = request.get_json(force=True) or {}
    base_name = _safe_name(data.get("name") or "script", default="script")
    command_name = _safe_name(data.get("command_name") or base_name, default=base_name)
    script = str(data.get("script") or "")
    replace = bool(data.get("replace", True))

    if not script:
        return jsonify({"ok": False, "error": "script is empty"}), 400

    scripts_dir = _scripts_dir()
    scripts_dir.mkdir(parents=True, exist_ok=True)
    script_path = scripts_dir / f"{base_name}.sh"
    script_path.write_text(script, encoding="utf-8")
    script_path.chmod(0o750)

    bdir = _bin_dir()
    bin_path = bdir / command_name

    try:
        if bin_path.exists() or bin_path.is_symlink():
            if not replace:
                return jsonify({
                    "ok": False,
                    "error": f"Command already exists: {bin_path}",
                    "path": str(script_path),
                }), 409
            bin_path.unlink()

        bdir.mkdir(parents=True, exist_ok=True)
        bin_path.symlink_to(script_path)
    except PermissionError:
        return jsonify({
            "ok": False,
            "error": f"Permission denied writing to {bdir}",
            "path": str(script_path),
            "requires_sudo": True,
            "manual_install": f"sudo ln -sf {script_path} {bin_path}",
        }), 403
    except Exception as exc:
        return jsonify({
            "ok": False,
            "error": str(exc),
            "path": str(script_path),
        }), 500

    state, _ = _load_state()
    state.setdefault("script_commands", {})[command_name] = {
        "bin_path": str(bin_path),
        "script_path": str(script_path),
        "installed_at": subprocess.check_output(["date", "+%Y-%m-%d %H:%M:%S"], text=True).strip(),
    }
    _save_state(state)

    return jsonify({
        "ok": True,
        "command": command_name,
        "path": str(script_path),
        "bin_path": str(bin_path),
    })


@APP.post("/api/script/command/remove")
def api_script_command_remove():
    """Remove a host command link from /usr/local/bin (or configured bin dir)."""
    data = request.get_json(force=True) or {}
    command_name = _safe_name(data.get("command_name") or "", default="")
    if not command_name:
        return jsonify({"ok": False, "error": "command_name is required"}), 400

    bdir = _bin_dir()
    bin_path = bdir / command_name

    if not (bin_path.exists() or bin_path.is_symlink()):
        # Still clean state in case of stale metadata
        state, _ = _load_state()
        if command_name in state.get("script_commands", {}):
            del state["script_commands"][command_name]
            _save_state(state)
        return jsonify({"ok": True, "removed": False, "message": "Command not found on host path."})

    try:
        bin_path.unlink()
    except PermissionError:
        return jsonify({
            "ok": False,
            "error": f"Permission denied removing {bin_path}",
            "requires_sudo": True,
            "manual_remove": f"sudo rm -f {bin_path}",
        }), 403
    except Exception as exc:
        return jsonify({"ok": False, "error": str(exc)}), 500

    state, _ = _load_state()
    if command_name in state.get("script_commands", {}):
        del state["script_commands"][command_name]
        _save_state(state)

    return jsonify({"ok": True, "removed": True, "command": command_name})


@APP.post("/api/script/test")
def api_script_test():
    """
    Run a safe, non-executing syntax check on the provided shell script.
    Uses 'bash -n' (syntax-only, never executes) and 'shellcheck' if available.
    Returns a list of results with level: ok | warning | error | info.
    """
    data   = request.get_json(force=True) or {}
    script = str(data.get("script") or "").strip()
    if not script:
        return jsonify({"ok": False, "error": "No script provided"}), 400

    results = []
    passed  = True

    fd, tmp_path = tempfile.mkstemp(suffix=".sh", prefix="hakpak4_test_")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(script)

        # ── 1. bash -n: pure syntax check, never runs the script ─────────────
        bash_proc = subprocess.run(
            ["bash", "-n", tmp_path],
            capture_output=True, text=True, timeout=10,
        )
        if bash_proc.returncode != 0:
            passed = False
            results.append({
                "tool": "bash -n",
                "level": "error",
                "output": (bash_proc.stderr or bash_proc.stdout).strip(),
            })
        else:
            results.append({"tool": "bash -n", "level": "ok", "output": "Syntax OK"})

        # ── 2. shellcheck: optional deeper static analysis ───────────────────
        sc_bin = shutil.which("shellcheck")
        if sc_bin:
            sc_proc = subprocess.run(
                [sc_bin, "--format=gcc", "--shell=bash", tmp_path],
                capture_output=True, text=True, timeout=20,
            )
            sc_out = (sc_proc.stdout + sc_proc.stderr).strip()
            # exit 0 = clean, exit 1 = errors, exit 2 = warnings only
            if sc_proc.returncode == 0:
                results.append({"tool": "shellcheck", "level": "ok", "output": "No issues found"})
            elif sc_proc.returncode == 1:
                passed = False
                results.append({"tool": "shellcheck", "level": "error", "output": sc_out})
            else:
                # warnings but not errors – don't block export
                results.append({"tool": "shellcheck", "level": "warning", "output": sc_out})
        else:
            results.append({
                "tool": "shellcheck",
                "level": "info",
                "output": "shellcheck not installed. Install it for deeper analysis:\n  sudo apt install shellcheck",
            })

    except subprocess.TimeoutExpired:
        passed = False
        results.append({"tool": "test runner", "level": "error", "output": "Timed out during analysis."})
    except Exception as exc:  # pragma: no cover
        passed = False
        results.append({"tool": "test runner", "level": "error", "output": str(exc)})
    finally:
        Path(tmp_path).unlink(missing_ok=True)

    return jsonify({"ok": True, "passed": passed, "results": results})


@APP.post("/api/gitclone")
def api_gitclone():
    """
    Trigger a secure git-clone operation from the GUI.
    Runs in a subprocess so the HTTP response returns immediately with a job ID.
    The result is written to a temp log that the client can poll.

    Request body: { "url": "https://github.com/owner/repo" }
    """
    data = request.get_json(force=True) or {}
    url  = str(data.get("url") or "").strip()

    if not url:
        return jsonify({"ok": False, "error": "url is required"}), 400

    # Validate URL at the API layer before spawning subprocess
    from gitclone import validate_github_url
    valid, norm_url = validate_github_url(url)
    if not valid:
        return jsonify({
            "ok":    False,
            "error": "Only https://github.com/owner/repo URLs are accepted.",
        }), 400

    # Spawn hakpak4 gitclone as a subprocess so we can stream output later
    hakpak4_py = str(_V4_DIR / "hakpak4.py")
    proc = None
    try:
        proc = subprocess.Popen(
            [sys.executable, hakpak4_py, "gitclone", norm_url, "--yes"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        out, _ = proc.communicate(timeout=300)
        ok = proc.returncode == 0
    except subprocess.TimeoutExpired:
        if proc is not None:
            proc.kill()
        out = "ERROR: git clone timed out after 5 minutes."
        ok  = False
    except Exception as exc:
        out = f"ERROR: {exc}"
        ok  = False

    return jsonify({"ok": ok, "output": out})


@APP.post("/api/repo/test")
def api_repo_test():
    """
    Static analysis of all shell scripts found in a cloned repo directory.
    Uses bash -n (syntax, never executes) and shellcheck (if installed).
    Returns per-file results so the UI can show a risk summary.

    Request body: { "repo_name": "owner/repo" }
    """
    data      = request.get_json(force=True) or {}
    repo_name = str(data.get("repo_name") or "").strip()

    # Validate: only allow safe path components
    if not re.fullmatch(r"[A-Za-z0-9_.\-]+(/[A-Za-z0-9_.\-]+)?", repo_name):
        return jsonify({"ok": False, "error": "Invalid repo name"}), 400

    repo_dir = _REPOS_DIR / repo_name.replace("/", "_")
    # Also try the basename variant used by some clone implementations
    if not repo_dir.is_dir():
        repo_dir = _REPOS_DIR / Path(repo_name).name
    if not repo_dir.is_dir():
        return jsonify({"ok": False, "error": f"Repo directory not found: {repo_dir}"}), 404

    # Collect all .sh files (limit to 50 to avoid abuse)
    sh_files = sorted(repo_dir.rglob("*.sh"))[:50]

    if not sh_files:
        return jsonify({
            "ok": True,
            "passed": True,
            "file_count": 0,
            "results": [],
            "summary": "No shell scripts found in this repo.",
        })

    sc_bin  = shutil.which("shellcheck")
    results = []
    passed  = True

    for sh in sh_files:
        rel = str(sh.relative_to(repo_dir))
        file_result = {"file": rel, "checks": []}

        # ── bash -n ──────────────────────────────────────────────────────────
        try:
            bp = subprocess.run(
                ["bash", "-n", str(sh)],
                capture_output=True, text=True, timeout=10,
            )
            if bp.returncode != 0:
                passed = False
                file_result["checks"].append({
                    "tool": "bash -n", "level": "error",
                    "output": (bp.stderr or bp.stdout).strip(),
                })
            else:
                file_result["checks"].append({
                    "tool": "bash -n", "level": "ok", "output": "Syntax OK",
                })
        except subprocess.TimeoutExpired:
            passed = False
            file_result["checks"].append({
                "tool": "bash -n", "level": "error", "output": "Timed out",
            })

        # ── shellcheck ───────────────────────────────────────────────────────
        if sc_bin:
            try:
                sp = subprocess.run(
                    [sc_bin, "--format=gcc", "--shell=bash", str(sh)],
                    capture_output=True, text=True, timeout=20,
                )
                sc_out = (sp.stdout + sp.stderr).strip()
                if sp.returncode == 0:
                    file_result["checks"].append({
                        "tool": "shellcheck", "level": "ok", "output": "No issues",
                    })
                elif sp.returncode == 1:
                    passed = False
                    file_result["checks"].append({
                        "tool": "shellcheck", "level": "error", "output": sc_out,
                    })
                else:
                    file_result["checks"].append({
                        "tool": "shellcheck", "level": "warning", "output": sc_out,
                    })
            except subprocess.TimeoutExpired:
                file_result["checks"].append({
                    "tool": "shellcheck", "level": "warning", "output": "Timed out",
                })
        else:
            file_result["checks"].append({
                "tool": "shellcheck", "level": "info",
                "output": "Not installed (sudo apt install shellcheck for deeper analysis)",
            })

        results.append(file_result)

    error_count   = sum(1 for r in results for c in r["checks"] if c["level"] == "error")
    warning_count = sum(1 for r in results for c in r["checks"] if c["level"] == "warning")

    return jsonify({
        "ok":            True,
        "passed":        passed,
        "file_count":    len(sh_files),
        "error_count":   error_count,
        "warning_count": warning_count,
        "results":       results,
        "summary": (
            f"{len(sh_files)} script(s) checked — "
            f"{error_count} error(s), {warning_count} warning(s)."
        ),
    })



# ── License routes ────────────────────────────────────────────────────────────

@APP.get("/api/license/status")
def api_license_status():
    if _lm is None:
        return jsonify({"tier": "free", "activated": False, "error": "license module unavailable"})
    return jsonify(_lm.get_status())


@APP.post("/api/license/activate")
def api_license_activate():
    if _lm is None:
        return jsonify({"success": False, "message": "License module unavailable."}), 500
    body = request.get_json(silent=True) or {}
    key = str(body.get("key", "")).strip()
    if not key:
        return jsonify({"success": False, "message": "No license key provided."}), 400
    result = _lm.activate(key)
    return jsonify(result)


@APP.post("/api/license/deactivate")
def api_license_deactivate():
    if _lm is None:
        return jsonify({"success": False, "message": "License module unavailable."}), 500
    _lm.deactivate()
    return jsonify({"success": True})


@APP.get("/api/license/hwid")
def api_license_hwid():
    if _lm is None:
        return jsonify({"hardware_id": "unavailable"})
    return jsonify({"hardware_id": _lm.get_hwid()})


# ── Entry point ───────────────────────────────────────────────────────────────

def run() -> None:
    host = os.environ.get("HAKPAK4_GUI_HOST", "127.0.0.1")
    port = int(os.environ.get("HAKPAK4_GUI_PORT", "8788"))
    print(f"\nHakPak4 Script Builder GUI → http://{host}:{port}")
    print("Press Ctrl-C to stop.\n")
    APP.run(host=host, port=port, debug=False)


if __name__ == "__main__":
    run()
