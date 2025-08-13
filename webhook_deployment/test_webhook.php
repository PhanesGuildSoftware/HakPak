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
