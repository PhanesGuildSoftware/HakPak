#!/usr/bin/env python3
"""
email_service.py - Multi-provider email service for HakPak Pro
Supports SendGrid, AWS SES, and SMTP
"""

import os
import logging
from typing import Optional, Dict, Any
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
import ssl

# Optional imports - only import if modules are available
try:
    from sendgrid import SendGridAPIClient
    from sendgrid.helpers.mail import Mail
    SENDGRID_AVAILABLE = True
except ImportError:
    SENDGRID_AVAILABLE = False

try:
    import boto3
    from botocore.exceptions import ClientError
    AWS_SES_AVAILABLE = True
except ImportError:
    AWS_SES_AVAILABLE = False

logger = logging.getLogger(__name__)

class EmailService:
    """Multi-provider email service"""
    
    def __init__(self):
        self.service = os.getenv('EMAIL_SERVICE', 'sendgrid').lower()
        self.from_email = os.getenv('FROM_EMAIL', 'owner@phanesguild.llc')
        self.from_name = os.getenv('FROM_NAME', 'Phanes Guild Software')
        self.support_email = os.getenv('SUPPORT_EMAIL', 'owner@phanesguild.llc')
        
        # Initialize the selected service
        if self.service == 'sendgrid':
            self._init_sendgrid()
        elif self.service == 'aws_ses':
            self._init_aws_ses()
        elif self.service == 'smtp':
            self._init_smtp()
        elif self.service == 'file':
            self._init_file()
        else:
            raise ValueError(f"Unsupported email service: {self.service}")
    
    def _init_file(self):
        """Initialize file-based email service for testing"""
        self.email_dir = os.getenv('LICENSES_DIR', './licenses')
        os.makedirs(self.email_dir, exist_ok=True)
        logger.info("Initialized file-based email service for testing")
    
    def _init_sendgrid(self):
        """Initialize SendGrid client"""
        if not SENDGRID_AVAILABLE:
            raise ImportError("SendGrid package not installed. Run: pip install sendgrid")
        
        api_key = os.getenv('SENDGRID_API_KEY')
        if not api_key:
            raise ValueError("SENDGRID_API_KEY environment variable is required")
        
        self.client = SendGridAPIClient(api_key=api_key)
        logger.info("Initialized SendGrid email service")
    
    def _init_aws_ses(self):
        """Initialize AWS SES client"""
        if not AWS_SES_AVAILABLE:
            raise ImportError("boto3 package not installed. Run: pip install boto3")
        
        self.client = boto3.client(
            'ses',
            region_name=os.getenv('AWS_REGION', 'us-east-1'),
            aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY')
        )
        logger.info("Initialized AWS SES email service")
    
    def _init_smtp(self):
        """Initialize SMTP settings"""
        self.smtp_server = os.getenv('SMTP_SERVER', 'smtp.gmail.com')
        self.smtp_port = int(os.getenv('SMTP_PORT', '587'))
        self.smtp_username = os.getenv('SMTP_USERNAME')
        self.smtp_password = os.getenv('SMTP_PASSWORD')
        
        if not self.smtp_username or not self.smtp_password:
            raise ValueError("SMTP_USERNAME and SMTP_PASSWORD environment variables are required")
        
        logger.info(f"Initialized SMTP email service: {self.smtp_server}:{self.smtp_port}")
    
    def send_activation_email(self, customer_email: str, customer_name: str, 
                            activation_key: str, order_id: str) -> bool:
        """Send license activation email to customer"""
        
        subject = "Your HakPak Pro License - Ready to Activate!"
        
        # Create email content
        html_content = self._create_html_email(customer_name, activation_key, order_id)
        text_content = self._create_text_email(customer_name, activation_key, order_id)
        
        try:
            if self.service == 'sendgrid':
                return self._send_via_sendgrid(customer_email, subject, html_content, text_content)
            elif self.service == 'aws_ses':
                return self._send_via_aws_ses(customer_email, subject, html_content, text_content)
            elif self.service == 'smtp':
                return self._send_via_smtp(customer_email, subject, html_content, text_content)
            elif self.service == 'file':
                return self._send_via_file(customer_email, subject, html_content, text_content, order_id)
        except Exception as e:
            logger.error(f"Failed to send email to {customer_email}: {str(e)}")
            return False
    
    def _send_via_sendgrid(self, to_email: str, subject: str, 
                          html_content: str, text_content: str) -> bool:
        """Send email via SendGrid"""
        message = Mail(
            from_email=(self.from_email, self.from_name),
            to_emails=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=text_content
        )
        
        response = self.client.send(message)
        success = response.status_code == 202
        
        if success:
            logger.info(f"Email sent successfully via SendGrid to {to_email}")
        else:
            logger.error(f"SendGrid error: {response.status_code} - {response.body}")
        
        return success
    
    def _send_via_aws_ses(self, to_email: str, subject: str,
                         html_content: str, text_content: str) -> bool:
        """Send email via AWS SES"""
        try:
            response = self.client.send_email(
                Destination={'ToAddresses': [to_email]},
                Message={
                    'Body': {
                        'Html': {'Charset': 'UTF-8', 'Data': html_content},
                        'Text': {'Charset': 'UTF-8', 'Data': text_content}
                    },
                    'Subject': {'Charset': 'UTF-8', 'Data': subject}
                },
                Source=f"{self.from_name} <{self.from_email}>"
            )
            
            logger.info(f"Email sent successfully via AWS SES to {to_email}")
            return True
            
        except ClientError as e:
            logger.error(f"AWS SES error: {e.response['Error']['Message']}")
            return False
    
    def _send_via_smtp(self, to_email: str, subject: str,
                      html_content: str, text_content: str) -> bool:
        """Send email via SMTP"""
        
        # Create message
        message = MIMEMultipart("alternative")
        message["Subject"] = subject
        message["From"] = f"{self.from_name} <{self.from_email}>"
        message["To"] = to_email
        
        # Add text and HTML parts
        text_part = MIMEText(text_content, "plain")
        html_part = MIMEText(html_content, "html")
        
        message.attach(text_part)
        message.attach(html_part)
        
        # Send email
        try:
            context = ssl.create_default_context()
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls(context=context)
                server.login(self.smtp_username, self.smtp_password)
                server.sendmail(self.from_email, to_email, message.as_string())
            
            logger.info(f"Email sent successfully via SMTP to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"SMTP error: {str(e)}")
            return False
    
    def _send_via_file(self, to_email: str, subject: str,
                      html_content: str, text_content: str, order_id: str) -> bool:
        """Save email to file for testing"""
        
        email_file = os.path.join(self.email_dir, f"email_{order_id}_{to_email.replace('@', '_at_')}.html")
        
        try:
            with open(email_file, 'w') as f:
                f.write(f"To: {to_email}\n")
                f.write(f"From: {self.from_name} <{self.from_email}>\n")
                f.write(f"Subject: {subject}\n\n")
                f.write(html_content)
            
            logger.info(f"Email saved to file: {email_file}")
            return True
            
        except Exception as e:
            logger.error(f"File email error: {str(e)}")
            return False
    
    def _create_html_email(self, customer_name: str, activation_key: str, order_id: str) -> str:
        """Create HTML email content"""
        return f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Your HakPak Pro License</title>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: #2c3e50; color: white; padding: 20px; text-align: center; }}
        .content {{ padding: 20px; background: #f9f9f9; }}
        .activation-key {{ background: #e8f4f8; padding: 15px; border-left: 4px solid #3498db; margin: 20px 0; font-family: monospace; word-break: break-all; }}
        .features {{ background: white; padding: 15px; margin: 15px 0; border-radius: 5px; }}
        .footer {{ background: #34495e; color: white; padding: 15px; text-align: center; font-size: 12px; }}
        .button {{ background: #3498db; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Your HakPak Pro License is Ready!</h1>
        </div>
        
        <div class="content">
            <p>Dear {customer_name},</p>
            
            <p>Thank you for purchasing HakPak Pro! Your license has been generated and is ready for activation.</p>
            
            <h3>🔑 Your Activation Key:</h3>
            <div class="activation-key">
                {activation_key}
            </div>
            
            <h3>📋 Installation Instructions:</h3>
            <ol>
                <li><strong>Download HakPak</strong> (if not already installed):
                    <br><code>wget https://github.com/PhanesGuildSoftware/hakpak/raw/main/install.sh</code>
                    <br><code>chmod +x install.sh && ./install.sh</code>
                </li>
                <li><strong>Activate your Pro license</strong>:
                    <br><code>./hakpak.sh --activate "YOUR_ACTIVATION_KEY"</code>
                </li>
                <li><strong>Verify activation</strong>:
                    <br><code>./hakpak.sh --enterprise-status</code>
                </li>
            </ol>
            
            <div class="features">
                <h3>✅ Your HakPak Pro License Includes:</h3>
                <ul>
                    <li>🚀 All Enterprise Features</li>
                    <li>♾️ Unlimited Usage</li>
                    <li>🎯 Priority Support</li>
                    <li>🔄 1 Year of Updates</li>
                    <li>📊 Pro Dashboard & Analytics</li>
                    <li>🛡️ Enterprise Security Suite</li>
                </ul>
            </div>
            
            <h3>📞 Need Help?</h3>
            <p>Our support team is here to help:</p>
            <ul>
                <li>📧 Email: <a href="mailto:{self.support_email}">{self.support_email}</a></li>
                <li>💬 Discord: PhanesGuildSoftware</li>
                <li>🐙 GitHub: <a href="https://github.com/PhanesGuildSoftware">PhanesGuildSoftware</a></li>
            </ul>
            
            <p>Order ID: <strong>{order_id}</strong></p>
        </div>
        
        <div class="footer">
            <p>Thank you for choosing HakPak Pro!</p>
            <p>© 2025 Phanes Guild Software LLC. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
        """
    
    def _create_text_email(self, customer_name: str, activation_key: str, order_id: str) -> str:
        """Create plain text email content"""
        return f"""
Dear {customer_name},

Thank you for purchasing HakPak Pro! Your license is ready for activation.

ACTIVATION KEY:
{activation_key}

INSTALLATION INSTRUCTIONS:

1. Download HakPak (if not already installed):
   wget https://github.com/PhanesGuildSoftware/hakpak/raw/main/install.sh
   chmod +x install.sh && ./install.sh

2. Activate your Pro license:
   ./hakpak.sh --activate "{activation_key}"

3. Verify activation:
   ./hakpak.sh --enterprise-status

Your HakPak Pro License Includes:
✓ All Enterprise Features
✓ Unlimited Usage  
✓ Priority Support
✓ 1 Year of Updates
✓ Pro Dashboard & Analytics
✓ Enterprise Security Suite

SUPPORT:
If you need assistance, contact us at:
• Email: {self.support_email}
• Discord: PhanesGuildSoftware
• GitHub: https://github.com/PhanesGuildSoftware

Order ID: {order_id}

Thank you for choosing HakPak Pro!

Best regards,
The Phanes Guild Team

© 2025 Phanes Guild Software LLC. All rights reserved.
        """

# Test function
def test_email_service():
    """Test the email service configuration"""
    try:
        email_service = EmailService()
        print(f"✓ Email service initialized: {email_service.service}")
        return True
    except Exception as e:
        print(f"✗ Email service error: {str(e)}")
        return False

if __name__ == "__main__":
    # Load environment variables
    from dotenv import load_dotenv
    load_dotenv()
    
    # Test the service
    test_email_service()
