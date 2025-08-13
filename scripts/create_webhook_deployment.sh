#!/bin/bash
# create_webhook_deployment.sh
# Creates a deployment package for automated license delivery

set -euo pipefail

DEPLOY_DIR="../webhook_deployment"
DATE=$(date +%Y%m%d_%H%M%S)

echo "📦 Creating HakPak Webhook Deployment Package..."
echo ""

# Clean up and prepare
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

echo "📁 Copying essential files..."

# Copy the enhanced webhook
cp ../tools/shopify_webhook.php "$DEPLOY_DIR/"

# Copy license generation tools
cp ../tools/generate_license.sh "$DEPLOY_DIR/"
cp ../tools/generate_keys.sh "$DEPLOY_DIR/"

# Copy RSA keys
mkdir -p "$DEPLOY_DIR/keys"
cp ../keys/* "$DEPLOY_DIR/keys/" 2>/dev/null || echo "Note: No keys found - will need to generate"

# Create test script
cat > "$DEPLOY_DIR/test_webhook.php" << 'EOF'
<?php
/**
 * Test script for HakPak webhook
 * Run this to verify your webhook setup
 */

// Simulate a Shopify order
$testOrder = [
    'id' => 'TEST12345',
    'email' => 'test@phanesguild.llc',  // Change this to your test email
    'customer' => [
        'first_name' => 'Test',
        'last_name' => 'Customer',
        'email' => 'test@phanesguild.llc'
    ],
    'line_items' => [
        [
            'name' => 'HakPak Professional Security Toolkit',
            'title' => 'HakPak',
            'product_title' => 'HakPak'
        ]
    ]
];

echo "Testing HakPak License Delivery...\n";

// Set up test environment
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['HTTP_X_SHOPIFY_HMAC_SHA256'] = 'test_signature';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';

// Override webhook verification for testing
function verifyWebhook($data, $hmac) { return true; }

// Capture output
ob_start();
include 'shopify_webhook.php';
$output = ob_get_clean();

echo "Webhook Output: $output\n";
echo "Check license_delivery.log for detailed logs\n";
EOF

# Create setup instructions
cat > "$DEPLOY_DIR/SETUP_INSTRUCTIONS.md" << 'EOF'
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
EOF

# Create a simple status checker
cat > "$DEPLOY_DIR/check_status.php" << 'EOF'
<?php
/**
 * HakPak License Delivery Status Checker
 * Quick health check for your webhook system
 */

echo "<h2>HakPak License Delivery System Status</h2>\n";

// Check files
$files = [
    'shopify_webhook.php' => 'Main webhook handler',
    'generate_license.sh' => 'License generator',
    'keys/private.pem' => 'Private RSA key',
    'keys/public.pem' => 'Public RSA key'
];

echo "<h3>📁 File Check:</h3>\n";
foreach ($files as $file => $desc) {
    $exists = file_exists($file);
    $status = $exists ? '✅' : '❌';
    echo "$status $desc ($file)\n";
    if (!$exists) echo "   → Missing! Please upload $file\n";
}

// Check permissions
echo "\n<h3>🔒 Permission Check:</h3>\n";
$executable = is_executable('generate_license.sh');
echo ($executable ? '✅' : '❌') . " generate_license.sh executable\n";

// Check logs
echo "\n<h3>📊 Recent Activity:</h3>\n";
if (file_exists('license_delivery.log')) {
    $lines = array_slice(file('license_delivery.log'), -5);
    echo "Last 5 log entries:\n";
    foreach ($lines as $line) echo "  " . trim($line) . "\n";
} else {
    echo "No license_delivery.log found (webhook not used yet)\n";
}

// Check configuration
echo "\n<h3>⚙️ Configuration:</h3>\n";
include_once 'shopify_webhook.php';
echo "Webhook secret: " . (defined('WEBHOOK_SECRET') ? 'Set' : 'Not set') . "\n";
echo "From email: " . (defined('FROM_EMAIL') ? FROM_EMAIL : 'Not set') . "\n";
echo "Admin email: " . (defined('ADMIN_EMAIL') ? ADMIN_EMAIL : 'Not set') . "\n";

echo "\n<p><strong>Status URL:</strong> " . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'] . "</p>";
echo "<p><strong>Webhook URL:</strong> " . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']) . "/shopify_webhook.php</p>";
EOF

# Create quick setup script
cat > "$DEPLOY_DIR/quick_setup.sh" << 'EOF'
#!/bin/bash
# quick_setup.sh - Run this on your server after uploading files

echo "🚀 HakPak Automated License Delivery - Quick Setup"
echo "=================================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "shopify_webhook.php" ]]; then
    echo "❌ Error: shopify_webhook.php not found"
    echo "Please run this script in the webhook deployment directory"
    exit 1
fi

echo "✅ Found webhook files"

# Set permissions
echo "🔧 Setting file permissions..."
chmod +x generate_license.sh generate_keys.sh 2>/dev/null || true
chmod 644 shopify_webhook.php test_webhook.php check_status.php
chmod 755 .

# Check for RSA keys
echo "🔑 Checking RSA keys..."
if [[ ! -f "keys/private.pem" ]]; then
    echo "⚠️  No RSA keys found. Generating new keys..."
    mkdir -p keys
    if [[ -f "generate_keys.sh" ]]; then
        ./generate_keys.sh
        echo "✅ RSA keys generated"
    else
        echo "❌ Cannot generate keys - generate_keys.sh missing"
        exit 1
    fi
else
    echo "✅ RSA keys found"
fi

# Test license generation
echo "🧪 Testing license generation..."
if ./generate_license.sh "Test User" "test@example.com" "Test License" &>/dev/null; then
    echo "✅ License generation working"
    # Clean up test file
    rm -f test_example_com.lic 2>/dev/null || true
else
    echo "❌ License generation failed"
    echo "Check that generate_license.sh has proper permissions and dependencies"
    exit 1
fi

# Check email configuration
echo "📧 Testing email capability..."
if command -v mail &>/dev/null; then
    echo "✅ Mail command available"
elif command -v sendmail &>/dev/null; then
    echo "✅ Sendmail available"
else
    echo "⚠️  No mail command found - emails may not work"
    echo "Consider installing mailutils: apt-get install mailutils"
fi

# Show configuration that needs to be updated
echo ""
echo "📝 IMPORTANT: Update these settings in shopify_webhook.php:"
echo "============================================================"
echo "1. WEBHOOK_SECRET - Change from default to secure value"
echo "2. FROM_EMAIL - Set to your licensing email (e.g., licensing@phanesguild.llc)"
echo "3. ADMIN_EMAIL - Set to your admin email (e.g., owner@phanesguild.llc)"
echo ""

# Show webhook URL
CURRENT_DIR=$(pwd)
if [[ "$CURRENT_DIR" == *"/var/www/"* ]]; then
    WEBHOOK_PATH=${CURRENT_DIR#/var/www/html}
    echo "🌐 Your webhook URL will be: https://phanesguild.llc${WEBHOOK_PATH}/shopify_webhook.php"
else
    echo "🌐 Your webhook URL will be: https://your-domain.com/path/to/shopify_webhook.php"
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Edit shopify_webhook.php with your settings"
echo "2. Test with: php test_webhook.php"
echo "3. Check status with: php check_status.php"
echo "4. Set up Shopify webhook to your URL"
echo "5. Place a test order!"
echo ""
echo "📊 Monitor with:"
echo "   tail -f license_delivery.log"
echo "   tail -f webhook_errors.log"
echo ""
echo "✅ Setup complete! Your automated license delivery is ready."
EOF

chmod +x "$DEPLOY_DIR/quick_setup.sh"

# Create compressed deployment package
cd ..
tar -czf "hakpak_webhook_deployment_${DATE}.tar.gz" webhook_deployment/

echo "✅ Webhook deployment package created!"
echo ""
echo "📦 Package: hakpak_webhook_deployment_${DATE}.tar.gz"
echo "📁 Directory: webhook_deployment/"
echo ""
echo "🚀 Next steps:"
echo "1. Upload the package to your server: scp hakpak_webhook_deployment_${DATE}.tar.gz user@phanesguild.llc:~/"
echo "2. Extract on server: tar -xzf hakpak_webhook_deployment_${DATE}.tar.gz"
echo "3. Follow SETUP_INSTRUCTIONS.md"
echo "4. Configure Shopify webhook"
echo "5. Test with test_webhook.php"
echo ""
echo "🎯 Your automated license delivery system is ready to deploy!"
