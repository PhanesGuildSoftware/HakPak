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
