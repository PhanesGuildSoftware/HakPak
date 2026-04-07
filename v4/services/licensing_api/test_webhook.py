#!/usr/bin/env python3
"""
Test script: sends a properly HMAC-signed fake Shopify orders/paid webhook
to the HakPak4 licensing API and prints the full response.

Usage:
    python3 test_webhook.py --secret <SHOPIFY_WEBHOOK_SECRET> --email <your@email.com>

The --secret value must match SHOPIFY_WEBHOOK_SECRET set in Railway (or your .env).
Get it from: Shopify Admin → Settings → Notifications → Webhooks (top of page).
"""
import argparse
import base64
import hashlib
import hmac
import json
import sys
import urllib.request

RAILWAY_URL = "https://hakpak-production.up.railway.app/v1/webhooks/shopify/orders-paid"

FAKE_ORDER = {
    "id": 99887766552,
    "email": "",  # filled in from --email arg
    "financial_status": "paid",
    "customer": {"first_name": "Test", "last_name": "Buyer"},
    "billing_address": {"first_name": "Test"},
    "line_items": [
        {
            "id": 1,
            "title": "HakPak4 Pro",
            "sku": "HPAK-PRO",
            "quantity": 1,
            "price": "19.99",
        }
    ],
}


def sign(secret: str, body: bytes) -> str:
    digest = hmac.new(secret.encode(), body, hashlib.sha256).digest()
    return base64.b64encode(digest).decode()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--secret", required=True, help="SHOPIFY_WEBHOOK_SECRET value from Railway/.env")
    parser.add_argument("--email", required=True, help="Email address to receive the license key")
    parser.add_argument("--sku", default="HPAK-PRO", help="SKU to test (default: HPAK-PRO)")
    parser.add_argument("--url", default=RAILWAY_URL, help="Override API URL (default: Railway production)")
    args = parser.parse_args()

    order = dict(FAKE_ORDER)
    order["email"] = args.email
    order["line_items"][0]["sku"] = args.sku

    body = json.dumps(order).encode()
    sig = sign(args.secret, body)

    print(f"Sending test webhook to: {args.url}")
    print(f"  Email : {args.email}")
    print(f"  SKU   : {args.sku}")
    print(f"  HMAC  : {sig[:12]}...")

    req = urllib.request.Request(
        args.url,
        data=body,
        headers={
            "Content-Type": "application/json",
            "X-Shopify-Hmac-Sha256": sig,
            "X-Shopify-Webhook-Id": "test-webhook-hakpak4-001",
            "X-Shopify-Topic": "orders/paid",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            status = resp.status
            response_body = resp.read().decode()
    except urllib.error.HTTPError as e:
        status = e.code
        response_body = e.read().decode()

    print(f"\nHTTP {status}")
    try:
        print(json.dumps(json.loads(response_body), indent=2))
    except Exception:
        print(response_body)

    if status == 200:
        print("\n✓ Success — check your email for the license key.")
    elif status == 401:
        print("\n✗ Signature rejected — the --secret value doesn't match SHOPIFY_WEBHOOK_SECRET.")
    else:
        print(f"\n✗ Unexpected status {status}")


if __name__ == "__main__":
    main()
