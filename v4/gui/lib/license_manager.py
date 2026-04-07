#!/usr/bin/env python3
"""
HakPak4 License Manager
=======================
Two-tier offline license system: Free and Pro.

Regular Pro key format: HPAK-SSSS-C1C1-C2C2-C3C3  (24 chars)
  HPAK              = static product prefix
  SSSS              = 4-char alphanumeric serial
  C1C1-C2C2-C3C3   = first 12 uppercase hex chars of HMAC-SHA256(_SECRET, b'HPAK-<SSSS>')

Master key format: HPAK-XXXX-XXXX-XXXX-XXXX  (24 chars, any valid-looking segments)
  Validated by comparing SHA-256(key) against the stored master hash on disk.
  Never HWID-bound — the master key works on any device.
  The hash is NEVER stored in the renderer; only the Flask backend validates it.

Device Binding (HWID):
  Regular Pro keys are bound to the device fingerprint at activation time.
  If the license.json is copied to a different machine the HWID check fails
  and the app falls back to Free tier, mitigating licence-file sharing.

This file is intended to be obfuscated with PyArmor before shipping
production builds (see docs/SECURITY.md).
"""

import hashlib
import hmac
import json
import platform
import re
from datetime import datetime, timezone
from pathlib import Path

# ── Product HMAC secret (change before distribution, re-gen all pro keys) ─────
_SECRET: bytes = b"hakpak4-license-secret-v1-2026"

# ── Master key hash  (SHA-256 of the master key — key itself is NEVER here) ───
# Validated server-side only; the JS frontend never sees this constant.
# Hash written to ~/.hakpak4/.mkh by install-hakpak4.sh as a second on-disk
# check so the hash cannot be patched out of a running Python bytecode image.
_MASTER_KEY_HASH: str = "389cbf92c5c18dedcc2525df9c79d64a9d3e44bbf42f84468497a85e81dcbdb0"

# ── Key patterns ──────────────────────────────────────────────────────────────
_KEY_RE = re.compile(r"^HPAK-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$")

# ── Storage paths ─────────────────────────────────────────────────────────────
_HAKPAK_DIR   = Path.home() / ".hakpak4"
_LICENSE_FILE = _HAKPAK_DIR / "license.json"
_MASTER_HASH_FILE = _HAKPAK_DIR / ".mkh"   # written by installer


# ─────────────────────────────────────────────────────────────────────────────
# Hardware ID  (device fingerprint for licence binding)
# ─────────────────────────────────────────────────────────────────────────────

def get_hwid() -> str:
    """Return a stable 32-char hex device fingerprint."""
    parts: list[str] = []

    # /etc/machine-id — most stable source on systemd Linux
    try:
        mid = Path("/etc/machine-id").read_text(encoding="utf-8").strip()
        if mid:
            parts.append(mid)
    except Exception:
        pass

    # DMI product UUID (root-readable on most bare-metal / VMs)
    for dmi in ("/sys/class/dmi/id/product_uuid", "/sys/class/dmi/id/board_serial"):
        try:
            val = Path(dmi).read_text(encoding="utf-8").strip()
            if val:
                parts.append(val)
                break
        except Exception:
            pass

    # Hostname as fallback
    parts.append(platform.node())

    seed = "|".join(parts).encode("utf-8")
    return hashlib.sha256(seed).hexdigest()[:32]


# ─────────────────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────────────────

def _check_segments(serial: str) -> tuple[str, str, str]:
    """Return the three expected 4-char HMAC check segments for a serial."""
    msg = f"HPAK-{serial}".encode()
    digest = hmac.new(_SECRET, msg, hashlib.sha256).hexdigest().upper()
    return digest[0:4], digest[4:8], digest[8:12]


def _validate_master_key(key: str) -> bool:
    """
    True if key's SHA-256 matches EITHER the compiled-in hash OR the
    on-disk hash file written by the installer.  Two independent checks
    so neither alone is a single point of failure.
    """
    candidate = hashlib.sha256(key.encode("utf-8")).hexdigest()

    # Check 1 — compiled-in hash (never in renderer / JS)
    if hmac.compare_digest(candidate, _MASTER_KEY_HASH):
        return True

    # Check 2 — on-disk hash written by install-hakpak4.sh
    try:
        stored = _MASTER_HASH_FILE.read_text(encoding="utf-8").strip()
        if stored and hmac.compare_digest(candidate, stored):
            return True
    except Exception:
        pass

    return False


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

def validate_key(key: str) -> bool:
    """True if *key* is a valid regular Pro key (HMAC-verified)."""
    key = key.strip().upper()
    if not _KEY_RE.match(key):
        return False
    parts = key.split("-")          # ['HPAK', serial, c1, c2, c3]
    s1, s2, s3 = _check_segments(parts[1])
    return parts[2] == s1 and parts[3] == s2 and parts[4] == s3


def activate(key: str) -> dict:
    """
    Validate *key* and, if valid, persist it.

    Master keys  → tier 'master',  NOT HWID-bound (works on any device).
    Regular keys → tier 'pro',     HWID-bound at activation time.
    """
    key = key.strip().upper()

    is_master = _validate_master_key(key)
    is_pro    = (not is_master) and validate_key(key)

    if not is_master and not is_pro:
        return {"success": False, "message": "Invalid license key."}

    _HAKPAK_DIR.mkdir(parents=True, exist_ok=True)

    payload: dict = {
        "key":          key,
        "tier":         "master" if is_master else "pro",
        "activated_at": datetime.now(timezone.utc).isoformat(),
    }

    # Regular Pro keys are HWID-bound; master keys are not
    if is_pro:
        payload["hwid"] = get_hwid()

    _LICENSE_FILE.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return {
        "success": True,
        "tier":    payload["tier"],
        "is_master": is_master,
    }


def get_status() -> dict:
    """Return the current license status dict (tier, activated, hwid_ok …)."""
    try:
        if _LICENSE_FILE.exists():
            data = json.loads(_LICENSE_FILE.read_text(encoding="utf-8"))
            key  = data.get("key", "")
            tier = data.get("tier", "")

            if tier == "master" and _validate_master_key(key):
                return {
                    "tier":         "master",
                    "activated":    True,
                    "key_hint":     key[:9] + "****",
                    "activated_at": data.get("activated_at"),
                    "hwid_ok":      True,   # master keys have no HWID requirement
                }

            if tier == "pro" and validate_key(key):
                stored_hwid  = data.get("hwid", "")
                current_hwid = get_hwid()
                hwid_ok = (not stored_hwid) or hmac.compare_digest(stored_hwid, current_hwid)
                if hwid_ok:
                    return {
                        "tier":         "pro",
                        "activated":    True,
                        "key_hint":     key[:9] + "****",
                        "activated_at": data.get("activated_at"),
                        "hwid_ok":      True,
                    }
                # HWID mismatch — licence was copied from another machine
                return {
                    "tier":      "free",
                    "activated": False,
                    "hwid_ok":   False,
                    "reason":    "license_bound_to_other_device",
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


def write_master_hash_file() -> None:
    """
    Write the master key hash to ~/.hakpak4/.mkh.
    Called by install-hakpak4.sh after first run so the on-disk check is
    available independently of the compiled-in constant.
    """
    _HAKPAK_DIR.mkdir(parents=True, exist_ok=True)
    _MASTER_HASH_FILE.write_text(_MASTER_KEY_HASH, encoding="utf-8")


# ─────────────────────────────────────────────────────────────────────────────
# CLI helpers (run this file directly)
# ─────────────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import sys as _sys
    import secrets as _secrets

    cmd = _sys.argv[1] if len(_sys.argv) > 1 else "keygen"

    if cmd == "keygen":
        # Generate a new regular Pro key
        serial = _secrets.token_hex(2).upper()
        s1, s2, s3 = _check_segments(serial)
        key = f"HPAK-{serial}-{s1}-{s2}-{s3}"
        print(key)
        assert validate_key(key), "BUG: generated key failed self-validation"

    elif cmd == "write-master-hash":
        # Called by install-hakpak4.sh:
        #   python3 -m v4.gui.lib.license_manager write-master-hash
        write_master_hash_file()
        print(f"Master hash written to {_MASTER_HASH_FILE}")

    elif cmd == "hwid":
        print(get_hwid())

    elif cmd == "status":
        import pprint as _pp
        _pp.pprint(get_status())

    else:
        print(f"Usage: {_sys.argv[0]} [keygen|write-master-hash|hwid|status]")
