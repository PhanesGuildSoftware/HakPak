#!/usr/bin/env python3
"""
fulfillment_service.py - Production HakPak Pro License Fulfillment
Integrates license generation with email delivery
"""

import os
import sys
import json
import logging
import subprocess
import tempfile
import base64
import requests
from datetime import datetime, timedelta
from pathlib import Path
from email_service import EmailService

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.getenv('LOG_FILE', './fulfillment.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class FulfillmentService:
    """Production license fulfillment service"""
    
    def __init__(self):
        self.vendor_dir = os.getenv('HAKPAK_VENDOR_DIR', os.path.expanduser('~/hakpak-vendor'))
        self.private_key_path = os.getenv('PRIVATE_KEY_PATH', f'{self.vendor_dir}/keys/private.pem')
        self.licenses_dir = os.getenv('LICENSES_DIR', f'{self.vendor_dir}/licenses')
        
        # License server configuration
        self.license_server_url = os.getenv('LICENSE_SERVER_URL', 'https://license.phanesguild.llc')
        self.api_secret_key = os.getenv('API_SECRET_KEY', 'default-secret')
        
        # Ensure directories exist
        Path(self.licenses_dir).mkdir(parents=True, exist_ok=True)
        Path(os.path.dirname(os.getenv('LOG_FILE', './fulfillment.log'))).mkdir(parents=True, exist_ok=True)
        
        # Initialize email service
        try:
            self.email_service = EmailService()
            logger.info(f"Email service initialized: {self.email_service.service}")
        except Exception as e:
            logger.error(f"Failed to initialize email service: {str(e)}")
            raise
        
        # Verify private key exists
        if not os.path.exists(self.private_key_path):
            raise FileNotFoundError(f"Private key not found: {self.private_key_path}")
    
    def generate_license(self, customer_email: str, customer_name: str, order_id: str) -> str:
        """Generate a signed HakPak Pro license and return activation key"""
        
        logger.info(f"Generating license for {customer_email} (Order: {order_id})")
        
        # Generate unique license ID
        license_id = subprocess.check_output(['openssl', 'rand', '-hex', '8']).decode().strip()
        
        # Create license payload
        issued_at = datetime.utcnow()
        expires_at = issued_at + timedelta(days=365)  # 1 year
        
        license_payload = {
            "license_id": license_id,
            "buyer_name": customer_name,
            "buyer_email": customer_email,
            "product": "HakPak Pro", 
            "version": "1.0",
            "issued_at": issued_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "expires_at": expires_at.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "order_id": order_id,
            "features": ["enterprise", "unlimited", "priority_support"]
        }
        
        # Create temporary files for payload and signature
        with tempfile.NamedTemporaryFile(mode='w', delete=False) as payload_file:
            json.dump(license_payload, payload_file)
            payload_file_path = payload_file.name
        
        # Sign the payload
        sig_file_path = payload_file_path + '.sig'
        subprocess.run([
            'openssl', 'dgst', '-sha256', '-sign', self.private_key_path,
            '-out', sig_file_path, payload_file_path
        ], check=True)
        
        # Create HakPak license file format
        license_file_path = f"{self.licenses_dir}/{customer_email}_{license_id}.lic"
        
        try:
            # Read payload and signature
            with open(payload_file_path, 'rb') as f:
                payload_b64 = base64.b64encode(f.read()).decode()
            
            with open(sig_file_path, 'rb') as f:
                sig_b64 = base64.b64encode(f.read()).decode()
            
            # Create license file
            with open(license_file_path, 'w') as f:
                f.write("-----BEGIN HAKPAK LICENSE-----\\n")
                f.write(payload_b64 + "\\n")
                f.write("-----SIGNATURE-----\\n")
                f.write(sig_b64 + "\\n")
                f.write("-----END HAKPAK LICENSE-----\\n")
            
            # Create activation key (base64 of entire license file)
            with open(license_file_path, 'rb') as f:
                activation_key = base64.b64encode(f.read()).decode()
            
            logger.info(f"License generated: {license_file_path}")
            
            return activation_key
            
        finally:
            # Clean up temporary files
            os.unlink(payload_file_path)
            os.unlink(sig_file_path)
    
    def register_license_server(self, license_payload):
        """Register license with the license server"""
        try:
            headers = {
                'Authorization': f'Bearer {self.api_secret_key}',
                'Content-Type': 'application/json'
            }
            
            response = requests.post(
                f'{self.license_server_url}/api/v1/register',
                json=license_payload,
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.info(f"License registered with server: {license_payload['license_id']}")
                return True
            elif response.status_code == 409:
                logger.warning(f"License already exists on server: {license_payload['license_id']}")
                return True  # Not an error
            else:
                logger.error(f"Server registration failed: {response.status_code} - {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.warning(f"Could not reach license server: {str(e)}")
            return False  # Not fatal - offline licenses still work
    
    def fulfill_order(self, customer_email: str, customer_name: str, order_id: str) -> bool:
        """Complete order fulfillment: generate license and send email"""
        
        logger.info(f"Starting fulfillment for order {order_id}")
        
        try:
            # Validate email format
            if '@' not in customer_email or '.' not in customer_email:
                raise ValueError(f"Invalid email address: {customer_email}")
            
            # Generate license
            activation_key = self.generate_license(customer_email, customer_name, order_id)
            
            # Register license with server (optional - not fatal if it fails)
            license_payload = {
                'license_id': activation_key.split('_')[1] if '_' in activation_key else 'unknown',
                'buyer_email': customer_email,
                'buyer_name': customer_name,
                'order_id': order_id,
                'issued_at': datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
                'expires_at': (datetime.utcnow() + timedelta(days=365)).strftime("%Y-%m-%dT%H:%M:%SZ")
            }
            
            # Extract actual license ID from generated license
            try:
                # Decode activation key to get license file content
                license_content = base64.b64decode(activation_key).decode()
                import re
                # Extract the base64 payload section
                payload_match = re.search(r'-----BEGIN HAKPAK LICENSE-----\n(.*?)\n-----SIGNATURE-----', license_content, re.DOTALL)
                if payload_match:
                    payload_b64 = payload_match.group(1)
                    payload_json = json.loads(base64.b64decode(payload_b64).decode())
                    license_payload['license_id'] = payload_json.get('license_id', 'unknown')
            except Exception as e:
                logger.warning(f"Could not extract license ID for server registration: {str(e)}")
            
            self.register_license_server(license_payload)
            
            # Send activation email
            email_sent = self.email_service.send_activation_email(
                customer_email, customer_name, activation_key, order_id
            )
            
            if email_sent:
                logger.info(f"Fulfillment completed successfully for order {order_id}")
                return True
            else:
                logger.error(f"Email delivery failed for order {order_id}")
                return False
                
        except Exception as e:
            logger.error(f"Fulfillment failed for order {order_id}: {str(e)}")
            return False

def main():
    """Command line interface for fulfillment service"""
    if len(sys.argv) != 4:
        print("Usage: python3 fulfillment_service.py <customer_email> <customer_name> <order_id>")
        print("Example: python3 fulfillment_service.py john@example.com 'John Doe' order_12345")
        sys.exit(1)
    
    # Load environment variables
    from dotenv import load_dotenv
    
    # Load from custom env file if specified
    env_file = os.getenv('DOTENV_PATH', '.env')
    load_dotenv(env_file)
    
    customer_email = sys.argv[1]
    customer_name = sys.argv[2]  
    order_id = sys.argv[3]
    
    try:
        fulfillment = FulfillmentService()
        success = fulfillment.fulfill_order(customer_email, customer_name, order_id)
        
        if success:
            print(f"✓ Order {order_id} fulfilled successfully")
            sys.exit(0)
        else:
            print(f"✗ Order {order_id} fulfillment failed")
            sys.exit(1)
            
    except Exception as e:
        print(f"✗ Fulfillment error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
