#!/usr/bin/env python3
"""
HakPak4 License Manager
=======================
Offline HMAC-SHA256 license validation with two tiers:
  free  — no key required; limited feature set
  pro   — requires a valid HPAK-XXXX-XXXX-XXXX-XXXX key

Key format: HPAK-SSSS-C1C1-C2C2-C3C3  (24 chars)
  HPAK  = static product prefix
  SSSS  = 4-char alphanumeric serial (chosen at key-gen time)
  C1C1-C2C2-C3C3 = first 12 uppercase hex chars of
                   HMAC-SHA256( _SECRET, b'HPAK-<SSSS>' )

Valid keys can be generated offline with the companion keygen.py in this
directory.  This file is intended to be obfuscated with PyArmor before
shipping production builds (see docs/SECURITY.md).
"""

import hashlib
import hmac
import json
import re
from datetime import datetime, timezone
from pathlib import Path

# ── Product secret ─────────────────────────────────────────────────────────────
# Change before production distribution and re-gen all keys.
_SECRET: bytes = b"hakpak4-license-secret-v1-2026"

# ── Key pattern ────────────────────────────────────────────────────────────────
_KEY_RE = re.compile(r"^HPAK-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$")

# ── Storage ────────────────────────────────────────────────────────────────────
_LICENSE_FILE = Path.home() / ".hakpak4" / "license.json"


# ─────────────────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────────────────

def _check_segments(serial: str) -> tuple[str, str, str]:
    """Return the three expected 4-char check segments for a given serial."""
    msg = f"HPAK-{serial}".encode()
    digest = hmac.new(_SECRET, msg, hashlib.sha256).hexdigest().upper()
    return digest[0:4], digest[4:8], digest[8:12]


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def validate_key(key: str) -> bool:
    """True if *key* has the correct format and valid HMAC segments."""
    key = key.strip().upper()
    if not _KEY_RE.match(key):
        return False
    parts = key.split("-")          # ['HPAK', serial, c1, c2, c3]
    s1, s2, s3 = _check_segments(parts[1])
    return parts[2] == s1 and parts[3] == s2 and parts[4] == s3


def activate(key: str) -> dict:
    """Validate *key* and, if valid, persist it.  Returns activation result."""
    key = key.strip().upper()
    if not validate_key(key):
        return {"success": False, "message": "Invalid license key."}
    _LICENSE_FILE.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "key": key,
        "tier": "pro",
        "activated_at": datetime.now(timezone.utc).isoformat(),
    }
    _LICENSE_FILE.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return {"success": True, "tier": "pro"}


def get_status() -> dict:
    """Return the current license status dict."""
    try:
        if _LICENSE_FILE.exists():
            data = json.loads(_LICENSE_FILE.read_text(encoding="utf-8"))
            key = data.get("key", "")
            if validate_key(key):
                return {
                    "tier": "pro",
                    "activated": True,
                    "key_hint": key[:9] + "****",
                    "activated_at": data.get("activated_at"),
                }
    except Exception:
        pass
    return {"tier": "free", "activated": False}


def deactivate() -> None:
    """Remove the stored license file (resets to free tier)."""
    try:
        _LICENSE_FILE.unlink(missing_ok=True)
    except Exception:
        pass


# ─────────────────────────────────────────────────────────────────────────────
# Keygen (run this file directly to generate a key)
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import secrets as _secrets
    serial = _secrets.token_hex(2).upper()   # 4 uppercase hex chars
    s1, s2, s3 = _check_segments(serial)
    key = f"HPAK-{serial}-{s1}-{s2}-{s3}"
    print(key)
    assert validate_key(key), "BUG: generated key failed self-validation"
