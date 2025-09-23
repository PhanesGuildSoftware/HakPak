#!/usr/bin/env python3
import os
import json
import shutil
import subprocess
from pathlib import Path
import logging
from flask import Flask, jsonify, request, send_from_directory
try:
    from werkzeug.serving import WSGIRequestHandler  # type: ignore
    _HAVE_WERKZEUG = True
except Exception:  # pragma: no cover - optional at runtime
    WSGIRequestHandler = None  # type: ignore
    _HAVE_WERKZEUG = False

ROOT = Path(__file__).resolve().parent
APP = Flask(__name__, static_folder=str(ROOT / "static"), static_url_path="/static")
APP.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0  # serve fresh static files


if _HAVE_WERKZEUG:
    class _QuietHandler(WSGIRequestHandler):
        def log_request(self, code='-', size='-'):
            try:
                c = int(code)
            except Exception:
                c = None
            if c is not None and 400 <= c < 500:
                return
            super().log_request(code, size)

        def log_message(self, format, *args):
            msg = format % args
            if " 400, message " in msg or "Bad request" in msg:
                return
            return super().log_message(format, *args)
else:
    _QuietHandler = None  # type: ignore


def _hakpak2_cmd():
    # Prefer installed binary, else local repo wrapper
    return os.environ.get("HAKPAK2_BIN", "hakpak2") if shutil.which("hakpak2") else str(Path(__file__).parents[1] / "hakpak2")


def _run(cmd: list[str], env: dict | None = None) -> tuple[int, str]:
    try:
        p = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            text=True,
            env=env or os.environ,
        )
        return p.returncode, p.stdout
    except Exception as e:
        return 1, f"error: {e}"


def _sudo_prefix() -> tuple[list[str], dict]:
    # Prefer GUI password prompt if available
    askpass = None
    for ap in ("ssh-askpass", "ksshaskpass", "lxqt-sudo"):  # common askpass helpers
        p = shutil.which(ap)
        if p:
            askpass = p
            break
    if askpass and os.environ.get("DISPLAY"):
        env = dict(os.environ)
        env["SUDO_ASKPASS"] = askpass
        return ["sudo", "-A"], env
    # Non-interactive fallback (will fail if password is required)
    return ["sudo", "-n"], os.environ


def _run_priv(cmd: list[str]) -> tuple[int, str]:
    # If already root (launcher auto-elevates), run directly
    if os.geteuid() == 0:
        rc, out = _run(cmd)
        return rc, out
    sudo_prefix, env = _sudo_prefix()
    rc, out = _run(sudo_prefix + cmd, env=env)
    low = (out or "").lower()
    if rc != 0 and ("password is required" in low or "no tty present" in low or "permission denied" in low):
        out = (out or "").rstrip() + (
            "\n\nHint: This action requires elevated privileges. "
            "Run the GUI with sudo (sudo -E hakpak2-gui), install a sudo askpass helper (e.g. ssh-askpass), "
            "or configure NOPASSWD for hakpak2 in sudoers."
        )
    return rc, out


@APP.route("/")
def index():
    return send_from_directory(APP.static_folder, "index.html")


@APP.get("/api/detect")
def api_detect():
    rc, out = _run(["hakpak2", "detect"])  # rely on PATH or wrapper
    return jsonify({"ok": rc == 0, "output": out})


@APP.get("/api/tools")
def api_tools():
    rc, out = _run(["hakpak2", "list", "--json"])  # JSON list with nativeAvailable
    try:
        data = json.loads(out)
    except Exception:
        data = {"tools": []}
    return jsonify({"ok": rc == 0, **data})


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
    rc, out = _run_priv(cmd)
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


@APP.post("/api/uninstall")
def api_uninstall():
    data = request.get_json(force=True)
    tool = data.get("tool")
    if not tool:
        return jsonify({"ok": False, "error": "tool required"}), 400
    rc, out = _run_priv(["hakpak2", "uninstall", tool])
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


@APP.post("/api/update")
def api_update():
    data = request.get_json(force=True)
    tool = data.get("tool", "all")
    rc, out = _run_priv(["hakpak2", "update", tool])
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


@APP.post("/api/repo")
def api_repo():
    data = request.get_json(force=True)
    action = data.get("action")
    if action not in ("add", "remove", "status"):
        return jsonify({"ok": False, "error": "action must be add|remove|status"}), 400
    # Repo operations often require root; always try privileged
    rc, out = _run_priv(["hakpak2", "repo", action])
    return jsonify({"ok": rc == 0, "output": out, "rc": rc})


def run():
    host = os.environ.get("HAKPAK2_GUI_HOST", "127.0.0.1")
    port = int(os.environ.get("HAKPAK2_GUI_PORT", "8787"))
    logging.getLogger('werkzeug').setLevel(logging.WARNING)
    ssl_ctx = None
    if os.environ.get("HAKPAK2_GUI_SSL", "").lower() in {"1", "true", "yes"}:
        # Use adhoc self-signed TLS if available; fallback to HTTP if it fails
        ssl_ctx = "adhoc"
    try:
        kwargs = {"host": host, "port": port, "debug": False}
        if _QuietHandler:
            kwargs["request_handler"] = _QuietHandler  # type: ignore
        if ssl_ctx:
            kwargs["ssl_context"] = ssl_ctx
        APP.run(**kwargs)
    except Exception:
        # Last resort: run plain HTTP without custom handler
        APP.run(host=host, port=port, debug=False)


if __name__ == "__main__":
    run()
