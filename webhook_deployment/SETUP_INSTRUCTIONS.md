# HakPak Automated License Delivery - Quick Setup

## 🚀 Upload Files to Your Server

1. **Upload this entire folder** to your web server:
   ```bash
   scp -r webhook_deployment/ user@phanesguild.llc:/var/www/html/hakpak/
   ```

2. **Set permissions:**
   ```bash
   ssh user@phanesguild.llc
   cd /var/www/html/hakpak
   chmod +x generate_license.sh generate_keys.sh
   chmod 644 shopify_webhook.php
   chmod 755 .
   ```

## 🔧 Configure the Webhook

3. **Edit shopify_webhook.php and update:**
   ```php
   define('WEBHOOK_SECRET', 'your_secure_secret_here_2025');  // Change this!
   define('FROM_EMAIL', 'licensing@phanesguild.llc');         // Your email
   define('ADMIN_EMAIL', 'owner@phanesguild.llc');           // Your admin email
   ```

## 🔑 Generate Keys (if needed)

4. **If no keys exist, generate them:**
   ```bash
   cd /var/www/html/hakpak
   ./generate_keys.sh
   ```

## 🌐 Set Up Shopify Webhook

5. **In your Shopify Admin:**
   - Go to Settings → Notifications
   - Scroll to "Webhooks" section
   - Click "Create webhook"
   - **Event:** Order creation
   - **Format:** JSON
   - **URL:** `https://phanesguild.llc/hakpak/shopify_webhook.php`
   - **Secret:** (use the same secret from step 3)

## 🧪 Test the System

6. **Test with the included script:**
   ```bash
   cd /var/www/html/hakpak
   php test_webhook.php
   ```

7. **Check the logs:**
   ```bash
   tail -f license_delivery.log
   tail -f webhook_errors.log
   ```

8. **Place a test order** in your Shopify store

## 📊 Monitor Operations

- **License delivery log:** `license_delivery.log`
- **Error log:** `webhook_errors.log`
- **Generated licenses:** `*.lic` files (auto-deleted after email)

## 🛠️ Troubleshooting

### Webhook not triggering:
- Verify webhook URL is accessible: `curl https://phanesguild.llc/hakpak/shopify_webhook.php`
- Check Shopify webhook secret matches your configuration
- Review webhook_errors.log

### License generation fails:
- Ensure generate_license.sh is executable
- Check that keys/private.pem exists
- Verify file permissions

### Email not sending:
- Test server email: `echo "test" | mail -s "test" your@email.com`
- Check server mail configuration
- Verify FROM_EMAIL is valid

## ✅ Success Indicators

When working correctly, you should see:
- New entries in license_delivery.log for each order
- Customers receiving professional license emails immediately
- Admin notifications for each successful delivery

---

**Need help?** Check the logs first, then contact owner@phanesguild.llc
