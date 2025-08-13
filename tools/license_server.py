#!/usr/bin/env python3
"""
license_server.py - HakPak Pro License Validation Server
Provides server-side license verification and activation tracking
"""

import os
import json
import logging
import hashlib
import time
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
import sqlite3
import jwt
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import serialization

app = Flask(__name__)

# Configuration
DATABASE_PATH = os.getenv('LICENSE_DB_PATH', 'licenses.db')
JWT_SECRET = os.getenv('JWT_SECRET', 'your-super-secret-jwt-key')
RATE_LIMIT_WINDOW = 300  # 5 minutes
MAX_REQUESTS_PER_WINDOW = 100

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LicenseServer:
    """Server-side license validation and tracking"""
    
    def __init__(self):
        self.init_database()
        
    def init_database(self):
        """Initialize SQLite database for license tracking"""
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        # License table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS licenses (
                license_id TEXT PRIMARY KEY,
                customer_email TEXT NOT NULL,
                customer_name TEXT NOT NULL,
                order_id TEXT NOT NULL,
                issued_at TIMESTAMP NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                status TEXT DEFAULT 'active',
                max_activations INTEGER DEFAULT 3,
                current_activations INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Activation tracking table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS activations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                license_id TEXT NOT NULL,
                machine_fingerprint TEXT NOT NULL,
                ip_address TEXT,
                user_agent TEXT,
                first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                status TEXT DEFAULT 'active',
                FOREIGN KEY (license_id) REFERENCES licenses (license_id)
            )
        ''')
        
        # Rate limiting table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS rate_limits (
                ip_address TEXT PRIMARY KEY,
                request_count INTEGER DEFAULT 1,
                window_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        logger.info("Database initialized")
    
    def register_license(self, license_data):
        """Register a new license in the database"""
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT INTO licenses 
                (license_id, customer_email, customer_name, order_id, issued_at, expires_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                license_data['license_id'],
                license_data['buyer_email'],
                license_data['buyer_name'],
                license_data['order_id'],
                license_data['issued_at'],
                license_data['expires_at']
            ))
            
            conn.commit()
            logger.info(f"License registered: {license_data['license_id']}")
            return True
            
        except sqlite3.IntegrityError:
            logger.warning(f"License already exists: {license_data['license_id']}")
            return False
        finally:
            conn.close()
    
    def validate_license(self, license_id, machine_fingerprint, ip_address, user_agent):
        """Validate license and track activation"""
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        try:
            # Check license validity
            cursor.execute('''
                SELECT * FROM licenses WHERE license_id = ? AND status = 'active'
            ''', (license_id,))
            
            license_row = cursor.fetchone()
            if not license_row:
                return {'valid': False, 'reason': 'License not found or inactive'}
            
            # Check expiration
            expires_at = datetime.fromisoformat(license_row[5])
            if datetime.utcnow() > expires_at:
                cursor.execute('''
                    UPDATE licenses SET status = 'expired' WHERE license_id = ?
                ''', (license_id,))
                conn.commit()
                return {'valid': False, 'reason': 'License expired'}
            
            # Check machine fingerprint
            cursor.execute('''
                SELECT * FROM activations 
                WHERE license_id = ? AND machine_fingerprint = ?
            ''', (license_id, machine_fingerprint))
            
            activation = cursor.fetchone()
            
            if activation:
                # Update last seen
                cursor.execute('''
                    UPDATE activations 
                    SET last_seen = CURRENT_TIMESTAMP, ip_address = ?, user_agent = ?
                    WHERE license_id = ? AND machine_fingerprint = ?
                ''', (ip_address, user_agent, license_id, machine_fingerprint))
            else:
                # Check activation limit
                cursor.execute('''
                    SELECT COUNT(*) FROM activations 
                    WHERE license_id = ? AND status = 'active'
                ''', (license_id,))
                
                active_count = cursor.fetchone()[0]
                max_activations = license_row[7]  # max_activations column
                
                if active_count >= max_activations:
                    return {
                        'valid': False, 
                        'reason': f'Maximum activations reached ({max_activations})'
                    }
                
                # Register new activation
                cursor.execute('''
                    INSERT INTO activations 
                    (license_id, machine_fingerprint, ip_address, user_agent)
                    VALUES (?, ?, ?, ?)
                ''', (license_id, machine_fingerprint, ip_address, user_agent))
                
                # Update activation count
                cursor.execute('''
                    UPDATE licenses 
                    SET current_activations = current_activations + 1
                    WHERE license_id = ?
                ''', (license_id,))
            
            conn.commit()
            
            # Generate JWT token for this session
            token_payload = {
                'license_id': license_id,
                'machine_fingerprint': machine_fingerprint,
                'exp': datetime.utcnow() + timedelta(hours=24),
                'iat': datetime.utcnow()
            }
            
            token = jwt.encode(token_payload, JWT_SECRET, algorithm='HS256')
            
            return {
                'valid': True,
                'token': token,
                'expires_at': license_row[5],
                'customer_email': license_row[1]
            }
            
        finally:
            conn.close()
    
    def check_rate_limit(self, ip_address):
        """Check if IP address is within rate limits"""
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        try:
            now = time.time()
            window_start = now - RATE_LIMIT_WINDOW
            
            cursor.execute('''
                SELECT request_count, window_start FROM rate_limits WHERE ip_address = ?
            ''', (ip_address,))
            
            row = cursor.fetchone()
            
            if row:
                last_window_start = row[1]
                if now - last_window_start > RATE_LIMIT_WINDOW:
                    # Reset window
                    cursor.execute('''
                        UPDATE rate_limits 
                        SET request_count = 1, window_start = ? 
                        WHERE ip_address = ?
                    ''', (now, ip_address))
                    conn.commit()
                    return True
                elif row[0] >= MAX_REQUESTS_PER_WINDOW:
                    return False
                else:
                    # Increment counter
                    cursor.execute('''
                        UPDATE rate_limits 
                        SET request_count = request_count + 1 
                        WHERE ip_address = ?
                    ''', (ip_address,))
                    conn.commit()
                    return True
            else:
                # First request from this IP
                cursor.execute('''
                    INSERT INTO rate_limits (ip_address, request_count, window_start)
                    VALUES (?, 1, ?)
                ''', (ip_address, now))
                conn.commit()
                return True
                
        finally:
            conn.close()

# Initialize license server
license_server = LicenseServer()

@app.route('/api/v1/validate', methods=['POST'])
def validate_license():
    """License validation endpoint"""
    client_ip = request.remote_addr
    
    # Rate limiting
    if not license_server.check_rate_limit(client_ip):
        return jsonify({
            'error': 'Rate limit exceeded',
            'retry_after': RATE_LIMIT_WINDOW
        }), 429
    
    try:
        data = request.get_json()
        required_fields = ['license_id', 'machine_fingerprint']
        
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        result = license_server.validate_license(
            data['license_id'],
            data['machine_fingerprint'],
            client_ip,
            request.headers.get('User-Agent', '')
        )
        
        if result['valid']:
            return jsonify({
                'status': 'valid',
                'token': result['token'],
                'expires_at': result['expires_at']
            })
        else:
            return jsonify({
                'status': 'invalid',
                'reason': result['reason']
            }), 403
            
    except Exception as e:
        logger.error(f"Validation error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/register', methods=['POST'])
def register_license():
    """Register a new license (for fulfillment system)"""
    # This endpoint should be secured with API key authentication
    auth_header = request.headers.get('Authorization', '')
    expected_token = f"Bearer {os.getenv('API_SECRET_KEY', 'default-secret')}"
    
    if auth_header != expected_token:
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        license_data = request.get_json()
        
        success = license_server.register_license(license_data)
        
        if success:
            return jsonify({'status': 'registered'})
        else:
            return jsonify({'error': 'License already exists'}), 409
            
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/revoke', methods=['POST'])
def revoke_license():
    """Revoke a license (admin endpoint)"""
    # Admin authentication required
    auth_header = request.headers.get('Authorization', '')
    expected_token = f"Bearer {os.getenv('ADMIN_SECRET_KEY', 'admin-secret')}"
    
    if auth_header != expected_token:
        return jsonify({'error': 'Unauthorized'}), 401
    
    try:
        data = request.get_json()
        license_id = data.get('license_id')
        
        if not license_id:
            return jsonify({'error': 'License ID required'}), 400
        
        conn = sqlite3.connect(DATABASE_PATH)
        cursor = conn.cursor()
        
        cursor.execute('''
            UPDATE licenses SET status = 'revoked' WHERE license_id = ?
        ''', (license_id,))
        
        cursor.execute('''
            UPDATE activations SET status = 'revoked' WHERE license_id = ?
        ''', (license_id,))
        
        conn.commit()
        conn.close()
        
        logger.info(f"License revoked: {license_id}")
        return jsonify({'status': 'revoked'})
        
    except Exception as e:
        logger.error(f"Revocation error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/v1/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'hakpak-license-server',
        'timestamp': datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5001))
    debug = os.getenv('FLASK_ENV') == 'development'
    
    logger.info(f"Starting HakPak License Server on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
