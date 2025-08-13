# HakPak Automated License Delivery Setup

## 🎯 Overview
This guide helps you automate license delivery so customers get their license keys immediately after purchase.

## 📋 Prerequisites
- Your website/server (phanesguild.llc) with PHP support
- Shopify store with HakPak product
- SSH/FTP access to upload files

## 🚀 Setup Steps

### Step 1: Upload Files to Your Server

1. **Upload the webhook handler:**
   ```bash
   # Upload to your web server
   scp tools/shopify_webhook.php user@phanesguild.llc:/var/www/html/
   ```

2. **Upload HakPak tools:**
   ```bash
   # Create directory for HakPak tools
   ssh user@phanesguild.llc
   mkdir -p /var/www/hakpak
   
   # Upload license generation tools
   scp -r tools/ keys/ user@phanesguild.llc:/var/www/hakpak/
   ```

### Step 2: Configure the Webhook

1. **Edit the webhook file:**
   ```php
   // In shopify_webhook.php, update these lines:
   define('WEBHOOK_SECRET', 'your_secure_secret_here');
   define('HAKPAK_PATH', '/var/www/hakpak');
   define('FROM_EMAIL', 'noreply@phanesguild.llc');
   ```

2. **Make tools executable:**
   ```bash
   chmod +x /var/www/hakpak/tools/generate_license.sh
   ```

### Step 3: Configure Shopify Webhook

1. **Go to your Shopify Admin** → Settings → Notifications

2. **Create new webhook:**
   - **Event:** Order creation
   - **Format:** JSON
   - **URL:** `https://phanesguild.llc/shopify_webhook.php`
   - **Secret:** (use the same secret from Step 2)

3. **Test the webhook** with a test order

### Step 4: Test the System

1. **Create a test order** in your Shopify store
2. **Check the log file:** `/var/www/hakpak/license_deliveries.log`
3. **Verify email delivery** to test customer

## 🔧 Alternative: Manual Process

If you prefer manual delivery for now:

```bash
# When you receive an order notification:
cd /path/to/hakpak
./tools/generate_license.sh "Customer Name" "customer@email.com" "HakPak License"

# Email the generated .lic file to customer with these instructions:
```

### Manual Email Template:
```
Subject: Your HakPak License - Ready to Activate!

Hi [Customer Name],

Thank you for purchasing HakPak! Here's your license key:

[ATTACH LICENSE FILE]

Quick Activation:
1. Download your HakPak package
2. Extract: tar -xzf hakpak-v1.0.0-*.tar.gz
3. Install: cd hakpak && sudo ./install.sh
4. Activate: sudo ./hakpak.sh --activate [LICENSE_KEY]

Need help? Reply to this email.

Best regards,
PhanesGuild Software
```

## 📊 Monitoring

### Check License Deliveries:
```bash
tail -f /var/www/hakpak/license_deliveries.log
```

### Check Generated Licenses:
```bash
ls /var/www/hakpak/*.lic
```

## 🛠️ Troubleshooting

### Common Issues:
- **Webhook not triggering:** Check Shopify webhook URL and secret
- **License generation fails:** Check file permissions and paths  
- **Email not sending:** Verify server email configuration
- **Wrong product triggering:** Ensure product name contains "hakpak"

### Debug Mode:
Add this to webhook file for debugging:
```php
error_log("HakPak webhook: " . $input);  // Add after line 82
```

## 🔒 Security Notes

- Use HTTPS for webhook URL
- Keep webhook secret secure
- Regularly rotate secrets
- Monitor license delivery logs
- Backup license keys safely

---

**Ready to automate?** Upload the webhook and configure Shopify!
**Prefer manual?** Use the email template above for now.
