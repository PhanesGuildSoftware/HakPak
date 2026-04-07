#!/usr/bin/env python3
import base64
import datetime as dt
import hashlib
import hmac
import json
import os
import secrets
import sqlite3
from pathlib import Path
from typing import Any, Dict, Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from pydantic import BaseModel, Field


def utc_now() -> dt.datetime:
    return dt.datetime.utcnow().replace(tzinfo=dt.timezone.utc)


def utc_now_iso() -> str:
    return utc_now().isoformat().replace("+00:00", "Z")


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def parse_json_env(name: str, default: Dict[str, Any]) -> Dict[str, Any]:
    raw = os.getenv(name, "").strip()
    if not raw:
        return default
    try:
        obj = json.loads(raw)
        return obj if isinstance(obj, dict) else default
    except Exception:
        return default


BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = Path(os.getenv("HAKPAK_LICENSE_DATA_DIR", str(BASE_DIR / "data")))
DB_PATH = Path(os.getenv("HAKPAK_LICENSE_DB_PATH", str(DATA_DIR / "licensing.db")))

ADMIN_TOKEN = os.getenv("HAKPAK_ADMIN_TOKEN", "")
CLIENT_TOKEN = os.getenv("HAKPAK_CLIENT_AUTH_TOKEN", "")
SHOPIFY_WEBHOOK_SECRET = os.getenv("SHOPIFY_WEBHOOK_SECRET", "")

DEFAULT_TIER_MAX_DEVICES = {"pro": 3}
TIER_MAX_DEVICES = parse_json_env("HAKPAK_TIER_MAX_DEVICES", DEFAULT_TIER_MAX_DEVICES)
SKU_TIER_MAP = parse_json_env("SHOPIFY_SKU_TIER_MAP", {})

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
SMTP_FROM = os.getenv("SMTP_FROM", "")
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "PhanesGuild Software")

app = FastAPI(title="HakPak4 Licensing API", version="1.0.0")


def _send_license_email(
    to_email: str,
    order_id: str,
    licenses: list,
    customer_name: str = "",
) -> None:
    """Send license key delivery email via Resend API. Non-fatal — failures are logged."""
    if not (RESEND_API_KEY and to_email):
        print(f"[EMAIL SKIP] RESEND_API_KEY not set or no recipient", flush=True)
        return

    greeting = f"Hi {customer_name}," if customer_name else "Hello,"

    key_lines_text = ""
    key_rows_html = ""
    for i, lic in enumerate(licenses, 1):
        key_lines_text += f"  Key {i}: {lic['key']}  ({lic['tier'].title()} tier)\n"
        key_rows_html += (
            f"<tr>"
            f"<td style='padding:8px 14px;font-family:monospace;font-size:15px;"
            f"background:#0d1117;color:#58e6d9;border-radius:4px;letter-spacing:1px'>"
            f"{lic['key']}</td>"
            f"<td style='padding:8px 14px;color:#aaa;font-size:13px'>{lic['tier'].title()}</td>"
            f"</tr>\n"
        )

    text_body = (
        f"{greeting}\n\n"
        f"Thank you for purchasing HakPak4!\n"
        f"Your license key(s) for order #{order_id}:\n\n"
        f"{key_lines_text}\n"
        f"To activate:\n"
        f"  1. Open HakPak4 and launch the GUI (hakpak4 gui).\n"
        f"  2. Click the License tab and enter your key.\n"
        f"  3. Click Activate — done.\n\n"
        f"Each key is hardware-bound to the number of devices allowed for its tier.\n\n"
        f"Need help? Contact us at support@phanesguild.com\n\n"
        f"— PhanesGuild Software"
    )

    html_body = (
        "<!DOCTYPE html><html><head><meta charset='utf-8'></head>"
        "<body style='background:#0d0d1a;color:#e0e0e0;font-family:Arial,sans-serif;margin:0;padding:24px'>"
        "<div style='max-width:560px;margin:0 auto'>"
        "<h2 style='color:#58e6d9;margin-bottom:4px'>Your HakPak4 License</h2>"
        f"<p style='color:#aaa;margin-top:0;font-size:13px'>Order #{order_id}</p>"
        f"<p>{greeting}<br>Thank you for purchasing HakPak4. Your license key(s) are ready.</p>"
        "<table cellpadding='0' cellspacing='6' style='margin:20px 0;width:100%'>"
        "<tr>"
        "<th style='text-align:left;color:#58e6d9;padding:4px 14px;font-size:12px'>License Key</th>"
        "<th style='text-align:left;color:#58e6d9;padding:4px 14px;font-size:12px'>Tier</th>"
        "</tr>"
        f"{key_rows_html}"
        "</table>"
        "<h3 style='color:#58e6d9'>How to activate</h3>"
        "<ol style='color:#ccc;line-height:1.8'>"
        "<li>Open <strong>HakPak4</strong> and run <code>hakpak4 gui</code>.</li>"
        "<li>Click the <strong>License</strong> tab and enter your key.</li>"
        "<li>Click <strong>Activate</strong> &#8212; done.</li>"
        "</ol>"
        "<p style='color:#888;font-size:12px'>Each key is hardware-bound to the allowed number of devices for its tier.</p>"
        "<p style='color:#888;font-size:12px'>Need help? "
        "<a href='mailto:support@phanesguild.com' style='color:#58e6d9'>support@phanesguild.com</a></p>"
        "<p style='color:#555;font-size:11px;margin-top:32px'>&#8212; PhanesGuild Software</p>"
        "</div></body></html>"
    )

    from_addr = f"{SMTP_FROM_NAME} <{SMTP_FROM}>" if SMTP_FROM else f"{SMTP_FROM_NAME} <onboarding@resend.dev>"

    payload = json.dumps({
        "from": from_addr,
        "to": [to_email],
        "subject": f"Your HakPak4 License Key \u2014 Order #{order_id}",
        "text": text_body,
        "html": html_body,
    }).encode()

    import urllib.request as _urlreq
    req = _urlreq.Request(
        "https://api.resend.com/emails",
        data=payload,
        headers={
            "Authorization": f"Bearer {RESEND_API_KEY}",
            "Content-Type": "application/json",
            "User-Agent": "hakpak4-licensing/1.0",
        },
        method="POST",
    )
    try:
        with _urlreq.urlopen(req, timeout=15) as resp:
            print(f"[EMAIL OK] Sent to {to_email}, status={resp.status}", flush=True)
    except Exception as _e:
        print(f"[EMAIL ERROR] Failed to send to {to_email}: {_e}", flush=True)


def db_conn() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    conn = db_conn()
    try:
        conn.executescript(
            """
            PRAGMA journal_mode=WAL;

            CREATE TABLE IF NOT EXISTS licenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                key_hash TEXT NOT NULL UNIQUE,
                key_mask TEXT NOT NULL,
                tier TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                max_devices INTEGER NOT NULL,
                expires_at TEXT,
                order_id TEXT,
                created_at TEXT NOT NULL,
                revoked_at TEXT,
                metadata_json TEXT NOT NULL DEFAULT '{}'
            );

            CREATE TABLE IF NOT EXISTS license_devices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                license_id INTEGER NOT NULL,
                device_hash TEXT NOT NULL,
                first_seen_at TEXT NOT NULL,
                last_seen_at TEXT NOT NULL,
                UNIQUE(license_id, device_hash),
                FOREIGN KEY(license_id) REFERENCES licenses(id)
            );

            CREATE TABLE IF NOT EXISTS shopify_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                webhook_id TEXT NOT NULL UNIQUE,
                topic TEXT NOT NULL,
                received_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS orders (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id TEXT NOT NULL UNIQUE,
                email TEXT,
                created_at TEXT NOT NULL,
                payload_json TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS order_licenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                order_id TEXT NOT NULL,
                license_id INTEGER NOT NULL,
                FOREIGN KEY(license_id) REFERENCES licenses(id)
            );
            """
        )
        conn.commit()
    finally:
        conn.close()


@app.on_event("startup")
def on_startup() -> None:
    init_db()


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8089"))
    uvicorn.run("app:app", host="0.0.0.0", port=port)


class ValidateRequest(BaseModel):
    license_key: str = Field(min_length=8, max_length=128)
    hwid: str = Field(min_length=8, max_length=128)
    app: str = Field(default="hakpak4")
    version: str = Field(default="4.0.0")


class IssueRequest(BaseModel):
    tier: str = Field(default="pro")
    max_devices: Optional[int] = None
    expires_at: Optional[str] = None
    order_id: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class RevokeRequest(BaseModel):
    license_key: str = Field(min_length=8, max_length=128)


def require_admin(authorization: Optional[str] = Header(default=None)) -> None:
    if not ADMIN_TOKEN:
        raise HTTPException(status_code=500, detail="Server misconfigured: admin token missing")
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if not hmac.compare_digest(token, ADMIN_TOKEN):
        raise HTTPException(status_code=401, detail="Invalid bearer token")


def require_client_token(x_hakpak_client_token: Optional[str] = Header(default=None)) -> None:
    if not CLIENT_TOKEN:
        return
    token = (x_hakpak_client_token or "").strip()
    if not token or not hmac.compare_digest(token, CLIENT_TOKEN):
        raise HTTPException(status_code=401, detail="Invalid client token")


def webhook_signature_valid(raw_body: bytes, signature_header: str) -> bool:
    if not SHOPIFY_WEBHOOK_SECRET:
        return False
    digest = hmac.new(SHOPIFY_WEBHOOK_SECRET.encode(), raw_body, hashlib.sha256).digest()
    expected = base64.b64encode(digest).decode()
    return hmac.compare_digest(expected, signature_header or "")


def generate_license_key() -> str:
    alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    parts = ["".join(secrets.choice(alphabet) for _ in range(4)) for _ in range(4)]
    return "HPAK-" + "-".join(parts)


def mask_key(key: str) -> str:
    if len(key) < 10:
        return "***"
    return key[:9] + "***"


def tier_max_devices(tier: str) -> int:
    value = TIER_MAX_DEVICES.get(tier, DEFAULT_TIER_MAX_DEVICES.get(tier, 1))
    try:
        return max(1, int(value))
    except Exception:
        return 1


@app.get("/v1/health")
def health() -> Dict[str, Any]:
    return {"ok": True, "time": utc_now_iso(), "sku_map_keys": list(SKU_TIER_MAP.keys())}


@app.post("/v1/license/validate")
def validate_license(payload: ValidateRequest, _auth: None = Depends(require_client_token)) -> Dict[str, Any]:
    key_hash = sha256_hex(payload.license_key.strip().upper())
    device_hash = sha256_hex(payload.hwid.strip())

    conn = db_conn()
    try:
        row = conn.execute(
            "SELECT id, tier, status, max_devices, expires_at FROM licenses WHERE key_hash = ?",
            (key_hash,),
        ).fetchone()

        if not row:
            return {"valid": False, "reason": "license_not_found"}

        if row["status"] != "active":
            return {"valid": False, "reason": "license_revoked"}

        expires_at = row["expires_at"]
        if expires_at:
            try:
                exp = dt.datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
                if exp <= utc_now():
                    return {"valid": False, "reason": "license_expired"}
            except Exception:
                return {"valid": False, "reason": "license_expiry_invalid"}

        device = conn.execute(
            "SELECT id FROM license_devices WHERE license_id = ? AND device_hash = ?",
            (row["id"], device_hash),
        ).fetchone()

        now = utc_now_iso()
        if device:
            conn.execute(
                "UPDATE license_devices SET last_seen_at = ? WHERE id = ?",
                (now, device["id"]),
            )
        else:
            count = conn.execute(
                "SELECT COUNT(*) AS c FROM license_devices WHERE license_id = ?",
                (row["id"],),
            ).fetchone()["c"]
            if count >= int(row["max_devices"]):
                return {"valid": False, "reason": "device_limit_exceeded"}
            conn.execute(
                "INSERT INTO license_devices (license_id, device_hash, first_seen_at, last_seen_at) VALUES (?, ?, ?, ?)",
                (row["id"], device_hash, now, now),
            )

        conn.commit()
        return {"valid": True, "reason": "ok", "tier": row["tier"]}
    finally:
        conn.close()


@app.post("/v1/admin/licenses/issue")
def admin_issue_license(req: IssueRequest, _admin: None = Depends(require_admin)) -> Dict[str, Any]:
    key = generate_license_key()
    row = {
        "key_hash": sha256_hex(key),
        "key_mask": mask_key(key),
        "tier": req.tier,
        "status": "active",
        "max_devices": req.max_devices if req.max_devices is not None else tier_max_devices(req.tier),
        "expires_at": req.expires_at,
        "order_id": req.order_id,
        "created_at": utc_now_iso(),
        "metadata_json": json.dumps(req.metadata or {}),
    }

    conn = db_conn()
    try:
        conn.execute(
            """
            INSERT INTO licenses (key_hash, key_mask, tier, status, max_devices, expires_at, order_id, created_at, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                row["key_hash"],
                row["key_mask"],
                row["tier"],
                row["status"],
                row["max_devices"],
                row["expires_at"],
                row["order_id"],
                row["created_at"],
                row["metadata_json"],
            ),
        )
        conn.commit()
        return {
            "success": True,
            "license_key": key,
            "tier": row["tier"],
            "max_devices": row["max_devices"],
            "expires_at": row["expires_at"],
            "order_id": row["order_id"],
        }
    finally:
        conn.close()


@app.post("/v1/admin/licenses/revoke")
def admin_revoke_license(req: RevokeRequest, _admin: None = Depends(require_admin)) -> Dict[str, Any]:
    key_hash = sha256_hex(req.license_key.strip().upper())
    conn = db_conn()
    try:
        cur = conn.execute(
            "UPDATE licenses SET status = 'revoked', revoked_at = ? WHERE key_hash = ?",
            (utc_now_iso(), key_hash),
        )
        conn.commit()
        if cur.rowcount == 0:
            return {"success": False, "reason": "license_not_found"}
        return {"success": True}
    finally:
        conn.close()


@app.get("/v1/admin/orders/{order_id}/licenses")
def admin_get_order_licenses(order_id: str, _admin: None = Depends(require_admin)) -> Dict[str, Any]:
    conn = db_conn()
    try:
        rows = conn.execute(
            """
            SELECT l.key_mask, l.tier, l.status, l.max_devices, l.expires_at, l.created_at
            FROM order_licenses ol
            JOIN licenses l ON l.id = ol.license_id
            WHERE ol.order_id = ?
            ORDER BY l.id ASC
            """,
            (order_id,),
        ).fetchall()
        return {
            "success": True,
            "order_id": order_id,
            "licenses": [dict(r) for r in rows],
        }
    finally:
        conn.close()


@app.post("/v1/admin/email-test")
def admin_email_test(
    to_email: str,
    _admin: None = Depends(require_admin),
) -> Dict[str, Any]:
    """Send a test email via Resend to verify email configuration."""
    if not to_email:
        raise HTTPException(status_code=400, detail="to_email is required")
    if not RESEND_API_KEY:
        return {"success": False, "reason": "RESEND_API_KEY not set"}

    from_addr = f"{SMTP_FROM_NAME} <{SMTP_FROM}>" if SMTP_FROM else f"{SMTP_FROM_NAME} <onboarding@resend.dev>"
    import urllib.request as _urlreq, urllib.error as _urlerr
    payload = json.dumps({
        "from": from_addr,
        "to": [to_email],
        "subject": "HakPak4 Email Test",
        "text": "This is a test email from the HakPak4 licensing API (Resend).",
    }).encode()
    req = _urlreq.Request(
        "https://api.resend.com/emails",
        data=payload,
        headers={"Authorization": f"Bearer {RESEND_API_KEY}", "Content-Type": "application/json", "User-Agent": "hakpak4-licensing/1.0"},
        method="POST",
    )
    try:
        with _urlreq.urlopen(req, timeout=15) as resp:
            body = json.loads(resp.read().decode())
            return {"success": True, "sent_to": to_email, "resend": body}
    except _urlerr.HTTPError as e:
        err_body = e.read().decode()
        return {"success": False, "status": e.code, "error": err_body}
    except Exception as e:
        return {"success": False, "error": str(e)}


@app.post("/v1/webhooks/shopify/orders-paid")
async def shopify_orders_paid(
    request: Request,
    x_shopify_hmac_sha256: Optional[str] = Header(default=None),
    x_shopify_webhook_id: Optional[str] = Header(default=None),
    x_shopify_topic: Optional[str] = Header(default="orders/paid"),
) -> Dict[str, Any]:
    raw = await request.body()

    if not x_shopify_webhook_id:
        raise HTTPException(status_code=400, detail="Missing webhook id")

    if not webhook_signature_valid(raw, x_shopify_hmac_sha256 or ""):
        raise HTTPException(status_code=401, detail="Invalid Shopify webhook signature")

    try:
        payload = json.loads(raw.decode() or "{}")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    order_id = str(payload.get("id") or "").strip()
    if not order_id:
        raise HTTPException(status_code=400, detail="Missing order id")

    email = (payload.get("email") or "").strip()
    line_items = payload.get("line_items") or []

    conn = db_conn()
    try:
        existing = conn.execute(
            "SELECT id FROM shopify_events WHERE webhook_id = ?",
            (x_shopify_webhook_id,),
        ).fetchone()
        if existing:
            return {"success": True, "duplicate": True, "order_id": order_id}

        conn.execute(
            "INSERT INTO shopify_events (webhook_id, topic, received_at) VALUES (?, ?, ?)",
            (x_shopify_webhook_id, x_shopify_topic or "orders/paid", utc_now_iso()),
        )

        conn.execute(
            "INSERT OR IGNORE INTO orders (order_id, email, created_at, payload_json) VALUES (?, ?, ?, ?)",
            (order_id, email, utc_now_iso(), json.dumps(payload)),
        )

        created_count = 0
        issued_keys: list = []
        for item in line_items:
            sku = (item.get("sku") or "").strip()
            qty_raw = item.get("quantity", 1)
            try:
                qty = max(1, int(qty_raw))
            except Exception:
                qty = 1

            tier = SKU_TIER_MAP.get(sku)
            if not tier:
                continue

            for _ in range(qty):
                key = generate_license_key()
                cur = conn.execute(
                    """
                    INSERT INTO licenses (key_hash, key_mask, tier, status, max_devices, expires_at, order_id, created_at, metadata_json)
                    VALUES (?, ?, ?, 'active', ?, NULL, ?, ?, ?)
                    """,
                    (
                        sha256_hex(key),
                        mask_key(key),
                        tier,
                        tier_max_devices(tier),
                        order_id,
                        utc_now_iso(),
                        json.dumps({"source": "shopify", "sku": sku}),
                    ),
                )
                license_id = cur.lastrowid
                conn.execute(
                    "INSERT INTO order_licenses (order_id, license_id) VALUES (?, ?)",
                    (order_id, license_id),
                )
                issued_keys.append({"key": key, "tier": tier, "sku": sku})
                created_count += 1

        conn.commit()
    finally:
        conn.close()

    customer_name = (
        (payload.get("billing_address") or {}).get("first_name")
        or (payload.get("customer") or {}).get("first_name")
        or ""
    ).strip()
    if email and issued_keys:
        _send_license_email(email, order_id, issued_keys, customer_name)

    return {
        "success": True,
        "order_id": order_id,
        "created_licenses": created_count,
    }


@app.post("/v1/webhooks/shopify/orders-cancelled")
async def shopify_orders_cancelled(
    request: Request,
    x_shopify_hmac_sha256: Optional[str] = Header(default=None),
    x_shopify_webhook_id: Optional[str] = Header(default=None),
    x_shopify_topic: Optional[str] = Header(default="orders/cancelled"),
) -> Dict[str, Any]:
    """Revoke all licenses associated with a cancelled Shopify order."""
    raw = await request.body()

    if not x_shopify_webhook_id:
        raise HTTPException(status_code=400, detail="Missing webhook id")

    if not webhook_signature_valid(raw, x_shopify_hmac_sha256 or ""):
        raise HTTPException(status_code=401, detail="Invalid Shopify webhook signature")

    try:
        payload = json.loads(raw.decode() or "{}")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    order_id = str(payload.get("id") or "").strip()
    if not order_id:
        raise HTTPException(status_code=400, detail="Missing order id")

    conn = db_conn()
    try:
        existing = conn.execute(
            "SELECT id FROM shopify_events WHERE webhook_id = ?",
            (x_shopify_webhook_id,),
        ).fetchone()
        if existing:
            return {"success": True, "duplicate": True, "order_id": order_id}

        conn.execute(
            "INSERT INTO shopify_events (webhook_id, topic, received_at) VALUES (?, ?, ?)",
            (x_shopify_webhook_id, x_shopify_topic or "orders/cancelled", utc_now_iso()),
        )

        now = utc_now_iso()
        cur = conn.execute(
            """
            UPDATE licenses SET status = 'revoked', revoked_at = ?
            WHERE order_id = ? AND status = 'active'
            """,
            (now, order_id),
        )
        revoked_count = cur.rowcount
        conn.commit()
    finally:
        conn.close()

    return {
        "success": True,
        "order_id": order_id,
        "revoked_licenses": revoked_count,
    }
