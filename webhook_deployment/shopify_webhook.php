<?php
/**
 * HakPak Automated License Delivery System
 * Automatically generates and emails license keys when customers purchase HakPak
 * 
 * Setup Instructions:
 * 1. Upload this entire directory to your web server
 * 2. Update configuration below
 * 3. Set up Shopify webhook pointing to this file
 * 4. Test with a small order
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/webhook_errors.log');

// Configuration - UPDATE THESE VALUES
define('WEBHOOK_SECRET', 'hakpak_webhook_secret_2025_phanesguild');  // Change this!
define('HAKPAK_PATH', __DIR__);  // Current directory contains tools
define('FROM_EMAIL', 'licensing@phanesguild.llc');
define('FROM_NAME', 'PhanesGuild Software');
define('ADMIN_EMAIL', 'owner@phanesguild.llc');  // For notifications

// Enhanced logging
function writeLog($message, $level = 'INFO') {
    $timestamp = date('Y-m-d H:i:s');
    $logMessage = "[$timestamp] [$level] $message\n";
    file_put_contents(__DIR__ . '/license_delivery.log', $logMessage, FILE_APPEND | LOCK_EX);
}

// Verify webhook authenticity
function verifyWebhook($data, $hmacHeader) {
    $calculatedHmac = base64_encode(hash_hmac('sha256', $data, WEBHOOK_SECRET, true));
    return hash_equals($calculatedHmac, $hmacHeader);
}

// Generate license for customer
function generateLicense($customerName, $customerEmail, $orderId) {
    writeLog("Generating license for: $customerName ($customerEmail) - Order: $orderId");
    
    $safeEmail = escapeshellarg($customerEmail);
    $safeName = escapeshellarg($customerName);
    $safeNotes = escapeshellarg("HakPak License - Order #$orderId");
    
    // Run license generation
    $command = "cd " . HAKPAK_PATH . " && chmod +x ./generate_license.sh && ./generate_license.sh $safeName $safeEmail $safeNotes 365 2>&1";
    writeLog("Executing: $command");
    
    $output = shell_exec($command);
    writeLog("License generation output: " . ($output ?: 'No output'));
    
    // Find generated license file - it should be in current directory
    $possibleFiles = [
        HAKPAK_PATH . "/" . str_replace(['@', '.', '+'], '_', $customerEmail) . ".lic",
        HAKPAK_PATH . "/" . preg_replace('/[^a-zA-Z0-9_-]/', '_', $customerEmail) . ".lic"
    ];
    
    foreach ($possibleFiles as $licenseFile) {
        if (file_exists($licenseFile)) {
            writeLog("Found license file: $licenseFile");
            $content = file_get_contents($licenseFile);
            // Clean up the file after reading
            unlink($licenseFile);
            return $content;
        }
    }
    
    // Check if any .lic files were created recently
    $recentFiles = glob(HAKPAK_PATH . "/*.lic");
    if (!empty($recentFiles)) {
        $latestFile = $recentFiles[0];
        writeLog("Using most recent license file: $latestFile");
        $content = file_get_contents($latestFile);
        unlink($latestFile);
        return $content;
    }
    
    writeLog("ERROR: No license file found after generation", 'ERROR');
    return false;
}

// Send license email
function sendLicenseEmail($customerEmail, $customerName, $licenseContent, $orderId) {
    writeLog("Sending license email to: $customerEmail");
    
    $subject = "🔑 Your HakPak License - Ready to Activate! (Order #$orderId)";
    
    $message = "
    <html>
    <head>
        <title>Your HakPak License</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; background: #f9f9f9; }
            .license-key { background: #fff; padding: 15px; border: 2px solid #3498db; border-radius: 8px; font-family: monospace; word-break: break-all; margin: 20px 0; }
            .steps { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .step { margin: 10px 0; padding: 10px; background: #ecf0f1; border-radius: 4px; }
            .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
            .important { color: #e74c3c; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <h1>🛡️ Welcome to HakPak!</h1>
                <p>Professional Security Toolkit</p>
            </div>
            
            <div class='content'>
                <h2>Hello {$customerName}!</h2>
                
                <p>Thank you for purchasing HakPak! Your professional security toolkit is ready to activate.</p>
                
                <div class='steps'>
                    <h3>📋 Quick Activation Steps:</h3>
                    <div class='step'><strong>1. Download</strong> your HakPak package from your order confirmation</div>
                    <div class='step'><strong>2. Extract</strong>: <code>tar -xzf hakpak-v1.0.0-*.tar.gz</code></div>
                    <div class='step'><strong>3. Install</strong>: <code>cd hakpak && sudo ./install.sh</code></div>
                    <div class='step'><strong>4. Activate</strong>: <code>sudo ./hakpak.sh --activate YOUR_LICENSE_KEY</code></div>
                    <div class='step'><strong>5. Verify</strong>: <code>sudo ./hakpak.sh --license-status</code></div>
                </div>
                
                <h3>🔑 Your License Key:</h3>
                <div class='license-key'>
                    " . htmlspecialchars($licenseContent) . "
                </div>
                
                <p class='important'>⚠️ IMPORTANT: Save this license key! You'll need it to activate HakPak.</p>
                
                <h3>🚀 What You Get:</h3>
                <ul>
                    <li>15+ Essential Security Tools (nmap, sqlmap, nikto, hydra, etc.)</li>
                    <li>Advanced Tool Collections</li>
                    <li>Extended Kali Metapackages</li>
                    <li>System Overview Dashboard</li>
                    <li>Priority Email Support (24-48hr response)</li>
                    <li>Commercial Use License</li>
                    <li>Multi-machine Deployment Rights</li>
                </ul>
                
                <h3>💡 Need Help?</h3>
                <ul>
                    <li><strong>Support Email:</strong> owner@phanesguild.llc</li>
                    <li><strong>Response Time:</strong> 24-48 hours</li>
                    <li><strong>Documentation:</strong> Complete guides included in package</li>
                </ul>
                
                <p><strong>Order Details:</strong><br>
                   Order #: $orderId<br>
                   License Type: HakPak Professional<br>
                   Valid Until: " . date('Y-m-d', strtotime('+1 year')) . "</p>
            </div>
            
            <div class='footer'>
                <p>© 2025 PhanesGuild Software LLC | Professional Security Solutions</p>
                <p>This license is valid for one user and includes all HakPak features.</p>
                <p>Need assistance? Reply to this email or contact owner@phanesguild.llc</p>
            </div>
        </div>
    </body>
    </html>
    ";
    
    $headers = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=UTF-8\r\n";
    $headers .= "From: " . FROM_NAME . " <" . FROM_EMAIL . ">\r\n";
    $headers .= "Reply-To: " . ADMIN_EMAIL . "\r\n";
    $headers .= "X-Mailer: HakPak License Delivery System\r\n";
    
    $success = mail($customerEmail, $subject, $message, $headers);
    
    if ($success) {
        writeLog("License email sent successfully to: $customerEmail");
        // Send admin notification
        $adminSubject = "HakPak License Delivered - Order #$orderId";
        $adminMessage = "License successfully delivered to $customerName ($customerEmail)\nOrder: #$orderId\nTime: " . date('Y-m-d H:i:s');
        mail(ADMIN_EMAIL, $adminSubject, $adminMessage);
    } else {
        writeLog("Failed to send license email to: $customerEmail", 'ERROR');
    }
    
    return $success;
}

// Log transaction
function logTransaction($customerEmail, $customerName, $orderId) {
    $logEntry = date('Y-m-d H:i:s') . " - License generated for: $customerName ($customerEmail) - Order: $orderId\n";
    file_put_contents(HAKPAK_PATH . '/license_deliveries.log', $logEntry, FILE_APPEND);
}

// Main webhook handler
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    writeLog("Received webhook request from: " . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    
    $hmacHeader = $_SERVER['HTTP_X_SHOPIFY_HMAC_SHA256'] ?? '';
    $input = file_get_contents('php://input');
    
    writeLog("Webhook payload size: " . strlen($input) . " bytes");
    
    // Verify webhook authenticity
    if (!verifyWebhook($input, $hmacHeader)) {
        writeLog("Webhook verification failed - unauthorized request", 'ERROR');
        http_response_code(401);
        exit('Unauthorized');
    }
    
    writeLog("Webhook verified successfully");
    
    $order = json_decode($input, true);
    
    if (!$order) {
        writeLog("Failed to parse JSON payload", 'ERROR');
        http_response_code(400);
        exit('Invalid JSON');
    }
    
    // Check if this is a HakPak order
    $isHakPakOrder = false;
    $hakpakItems = [];
    
    foreach ($order['line_items'] as $item) {
        if (stripos($item['name'], 'hakpak') !== false || 
            stripos($item['title'], 'hakpak') !== false ||
            stripos($item['product_title'], 'hakpak') !== false) {
            $isHakPakOrder = true;
            $hakpakItems[] = $item;
        }
    }
    
    if (!$isHakPakOrder) {
        writeLog("Not a HakPak order - skipping");
        http_response_code(200);
        exit('Not a HakPak order');
    }
    
    writeLog("HakPak order detected with " . count($hakpakItems) . " items");
    
    // Extract customer information
    $customerEmail = $order['email'] ?? $order['customer']['email'] ?? '';
    $customer = $order['customer'] ?? [];
    $customerName = trim(($customer['first_name'] ?? '') . ' ' . ($customer['last_name'] ?? ''));
    $customerName = $customerName ?: ($customer['name'] ?? $customerEmail);
    $orderId = $order['id'] ?? $order['order_number'] ?? 'unknown';
    
    if (empty($customerEmail)) {
        writeLog("No customer email found in order", 'ERROR');
        http_response_code(400);
        exit('No customer email');
    }
    
    writeLog("Processing order for: $customerName ($customerEmail) - Order: $orderId");
    
    // Generate and deliver license for each HakPak item
    $successCount = 0;
    foreach ($hakpakItems as $item) {
        writeLog("Generating license for item: " . $item['name']);
        
        $licenseContent = generateLicense($customerName, $customerEmail, $orderId);
        
        if ($licenseContent === false) {
            writeLog("License generation failed for order $orderId", 'ERROR');
            // Send admin alert
            mail(ADMIN_EMAIL, "HakPak License Generation Failed", 
                 "Failed to generate license for order #$orderId\nCustomer: $customerName ($customerEmail)\nTime: " . date('Y-m-d H:i:s'));
            continue;
        }
        
        // Send email with license
        if (sendLicenseEmail($customerEmail, $customerName, $licenseContent, $orderId)) {
            logTransaction($customerEmail, $customerName, $orderId);
            $successCount++;
            writeLog("License delivered successfully for item: " . $item['name']);
        } else {
            writeLog("Email delivery failed for order $orderId", 'ERROR');
            // Send admin alert
            mail(ADMIN_EMAIL, "HakPak Email Delivery Failed", 
                 "Failed to email license for order #$orderId\nCustomer: $customerName ($customerEmail)\nTime: " . date('Y-m-d H:i:s'));
        }
    }
    
    if ($successCount > 0) {
        writeLog("Successfully processed $successCount licenses for order $orderId");
        http_response_code(200);
        echo "Licenses delivered successfully ($successCount items)";
    } else {
        writeLog("Failed to process any licenses for order $orderId", 'ERROR');
        http_response_code(500);
        echo 'License delivery failed';
    }
    
} else {
    writeLog("Invalid request method: " . $_SERVER['REQUEST_METHOD'], 'WARN');
    http_response_code(405);
    echo 'Method not allowed - POST required';
}
?>
