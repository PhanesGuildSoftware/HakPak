#!/usr/bin/env bash
# lib/server_license.sh
# Server-based license verification for HakPak Pro
# This provides additional security through server-side validation

# Server configuration
LICENSE_SERVER_URL="${HAKPAK_LICENSE_SERVER:-https://license.phanesguild.llc}"
CLIENT_CACHE_DIR="$HOME/.cache/hakpak"
TOKEN_CACHE_FILE="$CLIENT_CACHE_DIR/license_token"
MACHINE_ID_FILE="$CLIENT_CACHE_DIR/machine_id"

# Ensure cache directory exists
mkdir -p "$CLIENT_CACHE_DIR"

# Generate or retrieve machine fingerprint
get_machine_fingerprint() {
    if [ -f "$MACHINE_ID_FILE" ]; then
        cat "$MACHINE_ID_FILE"
    else
        # Generate unique machine fingerprint
        local fingerprint
        fingerprint=$(cat /etc/machine-id 2>/dev/null || \
                     hostid 2>/dev/null || \
                     hostname | sha256sum | cut -d' ' -f1)
        
        # Add some hardware info for uniqueness
        if command -v dmidecode >/dev/null 2>&1; then
            fingerprint="${fingerprint}-$(sudo dmidecode -s system-uuid 2>/dev/null | head -1)"
        fi
        
        # Hash the final fingerprint
        fingerprint=$(echo "$fingerprint" | sha256sum | cut -d' ' -f1)
        echo "$fingerprint" > "$MACHINE_ID_FILE"
        chmod 600 "$MACHINE_ID_FILE"
        echo "$fingerprint"
    fi
}

# Check if cached token is still valid
is_token_valid() {
    if [ ! -f "$TOKEN_CACHE_FILE" ]; then
        return 1
    fi
    
    # Check if token is expired (simple check)
    local token_age
    token_age=$(( $(date +%s) - $(stat -c %Y "$TOKEN_CACHE_FILE" 2>/dev/null || echo 0) ))
    
    # Tokens are valid for 24 hours, but we refresh after 20 hours
    if [ "$token_age" -gt 72000 ]; then  # 20 hours
        return 1
    fi
    
    return 0
}

# Validate license with server
validate_license_server() {
    local license_id="$1"
    
    if [ -z "$license_id" ]; then
        echo "ERROR: License ID required for server validation" >&2
        return 1
    fi
    
    # Check if we have a valid cached token first
    if is_token_valid; then
        return 0
    fi
    
    local machine_fp
    machine_fp=$(get_machine_fingerprint)
    
    if [ -z "$machine_fp" ]; then
        echo "ERROR: Could not generate machine fingerprint" >&2
        return 1
    fi
    
    # Prepare request payload
    local payload
    payload=$(cat << EOF
{
    "license_id": "$license_id",
    "machine_fingerprint": "$machine_fp"
}
EOF
)
    
    # Make API request to license server
    local response
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -w "\\n%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            -H "User-Agent: HakPak-Pro/1.0" \
            -d "$payload" \
            "$LICENSE_SERVER_URL/api/v1/validate" 2>/dev/null)
    else
        echo "ERROR: curl is required for server license validation" >&2
        return 1
    fi
    
    if [ -z "$response" ]; then
        echo "WARN: Could not reach license server, falling back to offline validation" >&2
        return 2  # Fallback to offline validation
    fi
    
    # Parse response
    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | head -n -1)
    
    case "$http_code" in
        200)
            # Valid license - cache the token
            echo "$body" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 > "$TOKEN_CACHE_FILE"
            chmod 600 "$TOKEN_CACHE_FILE"
            echo "INFO: License validated successfully with server" >&2
            return 0
            ;;
        403)
            # Invalid license
            local reason
            reason=$(echo "$body" | grep -o '"reason":"[^"]*"' | cut -d'"' -f4)
            echo "ERROR: License validation failed: ${reason:-Invalid license}" >&2
            return 1
            ;;
        429)
            # Rate limited
            echo "WARN: License server rate limited, falling back to offline validation" >&2
            return 2
            ;;
        *)
            # Server error or other issue
            echo "WARN: License server error (HTTP $http_code), falling back to offline validation" >&2
            return 2
            ;;
    esac
}

# Enhanced license validation that tries server first, then falls back to offline
validate_license_enhanced() {
    local license_file="$1"
    
    # First, validate offline to get license data
    if ! verify_license_file "$license_file"; then
        return 1  # Invalid license file
    fi
    
    # Extract license ID from the license file
    local license_id
    if command -v jq >/dev/null 2>&1; then
        # Parse license file to get license ID
        local payload_b64 sig_b64 payload_file
        payload_file=$(mktemp)
        
        awk '/-----BEGIN HAKPAK LICENSE-----/{p=1;next} /-----SIGNATURE-----/{p=2;next} /-----END HAKPAK LICENSE-----/{p=0} p==1{print}' "$license_file" | base64 -d > "$payload_file" 2>/dev/null
        
        if [ -f "$payload_file" ]; then
            license_id=$(jq -r '.license_id' < "$payload_file" 2>/dev/null)
            rm -f "$payload_file"
        fi
    fi
    
    # If we have a license ID, try server validation
    if [ -n "$license_id" ] && [ "$license_id" != "null" ]; then
        case "$(validate_license_server "$license_id"; echo $?)" in
            0)
                # Server validation successful
                return 0
                ;;
            1)
                # Server says license is invalid
                return 1
                ;;
            2)
                # Server unavailable, fallback to offline validation
                echo "INFO: Using offline license validation" >&2
                return 0  # Already validated offline above
                ;;
        esac
    else
        # No license ID found, use offline validation only
        echo "INFO: Using offline license validation" >&2
        return 0
    fi
}

# Check if server validation is enabled
is_server_validation_enabled() {
    # Server validation is optional and can be disabled
    [ "${HAKPAK_OFFLINE_ONLY:-false}" != "true" ]
}

# Enhanced Pro validation that includes server check
is_pro_valid_enhanced() {
    local licfile
    if licfile=$(_find_license_file); then
        if is_server_validation_enabled; then
            validate_license_enhanced "$licfile"
        else
            verify_license_file "$licfile"
        fi
        
        case $? in
            0) return 0 ;;    # valid
            5) license_error "License expired"; return 1 ;;
            2|3) license_error "Invalid license format"; return 1 ;;
            4) license_error "Missing public key"; return 1 ;;
            6) license_error "Signature verification failed"; return 1 ;;
            *) license_error "License verification error"; return 1 ;;
        esac
    else
        return 1
    fi
}

# Server-aware Pro requirement check
require_pro_enhanced() {
    if is_pro_valid_enhanced; then
        return 0
    else
        echo
        print_warning "HakPak Pro feature requires a valid Pro license."
        print_info "Place your license file at one of these locations:"
        print_info "  $LICENSE_TARGET_SYSTEM"
        print_info "  $USER_LICENSE_PATH"
        echo
        print_info "To obtain a license, visit: https://phanesguild.llc/hakpak"
        print_info "Contact: owner@phanesguild.llc"
        echo
        return 1
    fi
}
