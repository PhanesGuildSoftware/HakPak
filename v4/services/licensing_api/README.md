# HakPak4 Licensing API

FastAPI service hosted on Railway. Handles license issuance, validation, and
Shopify `orders/paid` webhook processing for HakPak4 Pro license delivery.

## Endpoints

- `GET /v1/health`
- `POST /v1/license/validate`
- `POST /v1/webhooks/shopify/orders-paid`
- `POST /v1/webhooks/shopify/orders-cancelled`
- `POST /v1/admin/licenses/issue`
- `POST /v1/admin/licenses/revoke`
- `GET /v1/admin/orders/{order_id}/licenses`
- `POST /v1/admin/email-test`

## Security Design

- Shopify webhook requests verified with `X-Shopify-Hmac-Sha256`.
- Webhook replay blocked by `X-Shopify-Webhook-Id` idempotency check.
- Raw license keys are never stored — only `sha256(key)`.
- Public `/v1/license/validate` protected by `X-Hakpak-Client-Token`.
- Admin endpoints require `Authorization: Bearer <HAKPAK_ADMIN_TOKEN>`.
- No secrets hardcoded anywhere — all via env vars.

## Tier

HakPak4 has a single tier: **Pro** (default 3 devices).

| Tier | Max Devices | Shopify SKU |
|------|------------:|-------------|
| pro  | 3           | `HPAK-PRO`  |

Override device limit without redeploying:
```
HAKPAK_TIER_MAX_DEVICES={"pro":1}
```

## Railway Environment Variables

Set these in Railway → HakPak4 service → Variables:

| Variable | Notes |
|---|---|
| `HAKPAK_ADMIN_TOKEN` | Strong random token for admin endpoints |
| `HAKPAK_CLIENT_AUTH_TOKEN` | Token the desktop app sends on validate calls |
| `RESEND_API_KEY` | Shared with Kjer — from Resend dashboard |
| `SMTP_FROM` | `noreply@phanesguild.com` |
| `SMTP_FROM_NAME` | `HakPak4 Licensing` |
| `SHOPIFY_WEBHOOK_SECRET` | From Shopify after webhook is created (unique per URL) |
| `SHOPIFY_SKU_TIER_MAP` | `{"HPAK-PRO":"pro"}` |

## Deploy

```bash
cd v4/services/licensing_api
railway link   # select HakPak project + production + service
railway up     # upload and deploy
```

Service URL: `https://hakpak-production.up.railway.app`

## Local Development

```bash
cd v4/services/licensing_api
# .venv already created — just activate it:
source .venv/bin/activate
cp .env.example .env   # fill in real values
uvicorn app:app --host 127.0.0.1 --port 8089
```

## Shopify Webhook Setup

1. Deploy to Railway first — you need the live URL.
2. Shopify Admin → Settings → Notifications → Webhooks → Add webhook.
3. Event: `Order payment` (`orders/paid`).
4. URL: `https://hakpak-production.up.railway.app/v1/webhooks/shopify/orders-paid`.
5. Copy the secret Shopify shows you → paste into Railway as `SHOPIFY_WEBHOOK_SECRET`.
6. Set product variant SKU in Shopify to exactly `HPAK-PRO`.
7. (Optional) Add a cancellations webhook pointing to `/v1/webhooks/shopify/orders-cancelled`.

Verify after a test purchase:
```bash
curl -H "Authorization: Bearer $HAKPAK_ADMIN_TOKEN" \
  "https://hakpak-production.up.railway.app/v1/admin/orders/<ORDER_ID>/licenses"
```

Simulate a webhook locally without a real order:
```bash
python3 test_webhook.py \
  --secret "$SHOPIFY_WEBHOOK_SECRET" \
  --email you@example.com \
  --url http://localhost:8089/v1/webhooks/shopify/orders-paid
```

## Hardening Checklist

- HTTPS only (Railway provides this automatically).
- Rotate tokens and webhook secret regularly.
- Back up `data/licensing.db` or migrate to managed Postgres at scale.
- Monitor 401/400 spikes for misconfiguration or attack signals.
