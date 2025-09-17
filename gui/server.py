#!/usr/bin/env python3
import os
import json
import shutil
import subprocess
from pathlib import Path
from flask import Flask, jsonify, request, send_from_directory

ROOT = Path(__file__).resolve().parent
APP = Flask(__name__, static_folder=str(ROOT / "static"), static_url_path="/static")


def _hakpak2_cmd():
    # Prefer installed binary, else local repo wrapper
    return os.environ.get("HAKPAK2_BIN", "hakpak2") if shutil.which("hakpak2") else str(Path(__file__).parents[1] / "hakpak2")


def _run(cmd: list[str]) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False, text=True)
        return p.returncode, p.stdout
    except Exception as e:
        return 1, f"error: {e}"


@APP.route("/")
def index():
    return send_from_directory(APP.static_folder, "index.html")


@APP.get("/api/detect")
def api_detect():
    rc, out = _run(["hakpak2", "detect"])  # rely on PATH or wrapper
    return jsonify({"ok": rc == 0, "output": out})


@APP.get("/api/tools")
def api_tools():
    rc, out = _run(["hakpak2", "list"])  # text lines "name: methods=..."
    tools = []
    for line in out.splitlines():
        if ":" in line:
            name, rest = line.split(":", 1)
            methods = rest.split("methods=")[-1].strip()
            tools.append({"name": name.strip(), "methods": methods.split(",") if methods else []})
    return jsonify({"ok": rc == 0, "tools": tools, "raw": out})


def _read_state() -> dict:
    # Try installed state first
    for path in [Path("/opt/hakpak2/state.json"), Path(__file__).parents[1] / "v2" / "state.json"]:
        if path.exists():
            try:
                return json.loads(path.read_text())
            except Exception:
                return {"installed": {}}
    return {"installed": {}}


@APP.get("/api/status")
def api_status():
    return jsonify({"ok": True, "state": _read_state()})


@APP.post("/api/install")
def api_install():
    data = request.get_json(force=True)
    tool = data.get("tool")
    method = data.get("method", "auto")
    if not tool:
        return jsonify({"ok": False, "error": "tool required"}), 400
    cmd = ["hakpak2", "install", tool, "--method", method]
    if data.get("dryRun"):
        cmd.append("--dry-run")
    rc, out = _run(cmd)
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


@APP.post("/api/uninstall")
def api_uninstall():
    data = request.get_json(force=True)
    tool = data.get("tool")
    if not tool:
        return jsonify({"ok": False, "error": "tool required"}), 400
    rc, out = _run(["hakpak2", "uninstall", tool])
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


@APP.post("/api/repo")
def api_repo():
    data = request.get_json(force=True)
    action = data.get("action")
    if action not in ("add", "remove", "status"):
        return jsonify({"ok": False, "error": "action must be add|remove|status"}), 400
    rc, out = _run(["hakpak2", "repo", action])
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


def run():
    host = os.environ.get("HAKPAK2_GUI_HOST", "127.0.0.1")
    port = int(os.environ.get("HAKPAK2_GUI_PORT", "8787"))
    APP.run(host=host, port=port, debug=False)


if __name__ == "__main__":
    run()
