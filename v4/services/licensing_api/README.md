# HakPak4 Licensing API

Automated license key delivery service for HakPak4. When a customer buys HakPak4 Pro on Shopify, this service instantly generates a unique license key and emails it to them — no manual steps required.

**Live service:** `https://hakpak-production.up.railway.app`

---

## Business Overview

### What It Does

1. **Customer purchases** HakPak4 Pro on the Shopify storefront.
2. Shopify fires a signed webhook to this service.
3. The service validates the purchase, generates a unique license key, and emails it to the customer within seconds.
4. The customer enters their key in the HakPak4 app to activate Pro features on up to 3 devices.
5. If a purchase is refunded or cancelled, the license is automatically revoked.

### Purchase Flow

```
Customer pays on Shopify
        ↓
Shopify sends signed webhook → hakpak-production.up.railway.app
        ↓
Signature verified (tamper-proof)
        ↓
License key generated (HPAK-XXXX-XXXX-XXXX-XXXX)
        ↓
Key emailed to customer via Resend
        ↓
Customer activates in HakPak4 GUI
```

### Pricing & Tiers

HakPak4 currently has one tier:

| Plan | Devices | Shopify SKU | Price |
|------|--------:|-------------|-------|
| Pro  | 3       | `HPAK-PRO`  | TBD   |

### Key Features for the Business

- **Fully automated** — zero manual work per sale
- **Instant delivery** — key emailed within seconds of payment
- **Fraud-resistant** — Shopify HMAC signature verification; replay attack protection
- **Revocation support** — cancel/refund in Shopify → license deactivated automatically
- **Device binding** — each key locks to hardware, preventing sharing
- **No raw keys stored** — only cryptographic hashes in the database

---

## Technical Overview

### Stack

| Layer | Technology |
|-------|-----------|
| API framework | FastAPI 0.115 + uvicorn |
| Storage | SQLite (WAL mode) |
| Email | Resend API |
| Hosting | Railway (NIXPACKS, auto-HTTPS) |
| Webhook auth | Shopify HMAC-SHA256 |

### Architecture

```
Shopify Webhook (HMAC-signed)
        ↓
POST /v1/webhooks/shopify/orders-paid
        ↓
  ┌─────────────────────────────────┐
  │  1. Verify HMAC signature       │
  │  2. Check idempotency (webhook  │
  │     ID deduplication)           │
  │  3. Map SKU → tier              │
  │  4. Generate HPAK-XXXX key      │
  │  5. Store sha256(key) in DB     │
  │  6. Send email via Resend       │
  └─────────────────────────────────┘
        ↓
Customer activates in HakPak4
        ↓
POST /v1/license/validate
  - Verifies key hash
  - Binds to device HWID
  - Enforces device limit
```

### Database Schema (SQLite)

- `licenses` — key hash, tier, status, device limit, order reference
- `devices` — HWID hash, license reference, first seen timestamp
- `orders` — Shopify order ID, customer email, raw payload
- `order_licenses` — order ↔ license mapping
- `shopify_events` — webhook ID deduplication log

### API Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/v1/health` | None | Uptime + SKU map check |
| `POST` | `/v1/license/validate` | Client token | Activate/verify key from app |
| `POST` | `/v1/webhooks/shopify/orders-paid` | HMAC | Issue license on purchase |
| `POST` | `/v1/webhooks/shopify/orders-cancelled` | HMAC | Revoke license on refund |
| `POST` | `/v1/admin/licenses/issue` | Admin token | Manual key issuance |
| `POST` | `/v1/admin/licenses/revoke` | Admin token | Manual revocation |
| `GET` | `/v1/admin/orders/{order_id}/licenses` | Admin token | Look up keys by order |
| `POST` | `/v1/admin/email-test` | Admin token | Test email delivery |

### Security Design

- Shopify webhook requests verified with `X-Shopify-Hmac-Sha256`
- Webhook replay blocked by `X-Shopify-Webhook-Id` idempotency check
- Raw license keys are never stored — only `sha256(key)`
- Public `/v1/license/validate` protected by `X-Hakpak-Client-Token`
- Admin endpoints require `Authorization: Bearer <HAKPAK_ADMIN_TOKEN>`
- No secrets hardcoded anywhere — all via env vars

---

## Railway Environment Variables

| Variable | Value |
|---|---|
| `HAKPAK_ADMIN_TOKEN` | Strong random token for admin endpoints |
| `HAKPAK_CLIENT_AUTH_TOKEN` | Token the desktop app sends on validate calls |
| `RESEND_API_KEY` | From Resend dashboard |
| `SMTP_FROM` | `noreply@phanesguild.com` |
| `SMTP_FROM_NAME` | `HakPak4 Licensing` |
| `SHOPIFY_WEBHOOK_SECRET` | Unique secret from Shopify webhook settings |
| `SHOPIFY_SKU_TIER_MAP` | `{"HPAK-PRO":"pro"}` |

---

## Deploy

```bash
cd v4/services/licensing_api
railway link   # select HakPak project + production + service
railway up     # upload and deploy
```

---

## Local Development

```bash
cd v4/services/licensing_api
source .venv/bin/activate        # .venv already created
cp .env.example .env             # fill in real values
uvicorn app:app --host 127.0.0.1 --port 8089
```

Test the full flow without a real Shopify order:
```bash
python3 test_webhook.py \
  --secret "$SHOPIFY_WEBHOOK_SECRET" \
  --email owner@phanesguild.llc \
  --url https://hakpak-production.up.railway.app/v1/webhooks/shopify/orders-paid
```

---

## Shopify Setup

1. Shopify Admin → Settings → Notifications → Webhooks → Add webhook
2. Event: `Order payment` (`orders/paid`)
3. URL: `https://hakpak-production.up.railway.app/v1/webhooks/shopify/orders-paid`
4. Copy the secret → add to Railway as `SHOPIFY_WEBHOOK_SECRET`
5. Set product variant SKU in Shopify to exactly `HPAK-PRO`
6. (Optional) Add cancellations webhook → `/v1/webhooks/shopify/orders-cancelled`

---

## Hardening Checklist

- HTTPS only — Railway provides this automatically
- Rotate `HAKPAK_ADMIN_TOKEN`, `HAKPAK_CLIENT_AUTH_TOKEN`, and webhook secret regularly
- Back up `data/licensing.db` or migrate to managed Postgres at scale
- Monitor 401/400 spikes for misconfiguration or attack signals
