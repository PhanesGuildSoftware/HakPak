#!/usr/bin/env bash
# tools/validate_license.sh
# Validates enterprise license signatures for HakPak Pro features

set -euo pipefail

# Colors for output
declare -r GREEN='\033[0;32m'
declare -r RED='\033[0;31m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r NC='\033[0m'

# Output functions
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1" >&2; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# Configuration
readonly PUBLIC_KEY_PATH="./keys/public.pem"
readonly LICENSE_DIR="/etc/hakpak/licenses"
readonly LICENSE_FILE="${LICENSE_DIR}/enterprise.lic"

# Check if public key exists
check_public_key() {
    if [[ ! -f "$PUBLIC_KEY_PATH" ]]; then
        print_error "Public key not found at $PUBLIC_KEY_PATH"
        print_info "Run ./tools/generate_keys.sh to create keys"
        return 1
    fi
    return 0
}

# Validate license file format and signature
validate_license() {
    local license_file="$1"
    
    if [[ ! -f "$license_file" ]]; then
        print_error "License file not found: $license_file"
        return 1
    fi
    
    print_info "Validating license file: $license_file"
    
    # Extract license data and signature
    local license_data
    local signature
    
    if ! license_data=$(head -n -1 "$license_file" 2>/dev/null); then
        print_error "Failed to read license data"
        return 1
    fi
    
    if ! signature=$(tail -n 1 "$license_file" 2>/dev/null); then
        print_error "Failed to read license signature"
        return 1
    fi
    
    # Decode signature from base64
    local signature_file="/tmp/hakpak_signature_$$"
    if ! echo "$signature" | base64 -d > "$signature_file" 2>/dev/null; then
        print_error "Invalid signature format"
        rm -f "$signature_file"
        return 1
    fi
    
    # Verify signature
    local data_file="/tmp/hakpak_data_$$"
    echo "$license_data" > "$data_file"
    
    if openssl dgst -sha256 -verify "$PUBLIC_KEY_PATH" -signature "$signature_file" "$data_file" &>/dev/null; then
        print_success "License signature is valid"
        rm -f "$signature_file" "$data_file"
        return 0
    else
        print_error "License signature is invalid"
        rm -f "$signature_file" "$data_file"
        return 1
    fi
}

# Parse and display license information
parse_license() {
    local license_file="$1"
    
    print_info "License Information:"
    echo "=================================="
    
    # Extract license data (all lines except the last one)
    local license_data
    license_data=$(head -n -1 "$license_file" 2>/dev/null)
    
    # Parse JSON license data
    if command -v jq &>/dev/null; then
        echo "$license_data" | jq -r '
        "Company: " + .company,
        "License Type: " + .license_type,
        "Valid From: " + .valid_from,
        "Valid Until: " + .valid_until,
        "Max Users: " + (.max_users | tostring),
        "Features: " + (.features | join(", ")),
        "Support Level: " + .support_level
        '
    else
        # Fallback parsing without jq
        echo "$license_data" | sed 's/[{}"]//g' | tr ',' '\n' | while IFS=':' read -r key value; do
            case "$key" in
                *company*) echo "Company: ${value# }" ;;
                *license_type*) echo "License Type: ${value# }" ;;
                *valid_from*) echo "Valid From: ${value# }" ;;
                *valid_until*) echo "Valid Until: ${value# }" ;;
                *max_users*) echo "Max Users: ${value# }" ;;
                *support_level*) echo "Support Level: ${value# }" ;;
            esac
        done
    fi
}

# Check if license is expired
check_expiration() {
    local license_file="$1"
    local license_data
    local valid_until
    
    license_data=$(head -n -1 "$license_file" 2>/dev/null)
    
    if command -v jq &>/dev/null; then
        valid_until=$(echo "$license_data" | jq -r '.valid_until')
    else
        # Fallback extraction
        valid_until=$(echo "$license_data" | grep -o '"valid_until":"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [[ -z "$valid_until" ]]; then
        print_warning "Cannot determine license expiration date"
        return 1
    fi
    
    local expiry_timestamp
    local current_timestamp
    
    # Convert dates to timestamps for comparison
    if ! expiry_timestamp=$(date -d "$valid_until" +%s 2>/dev/null); then
        print_warning "Invalid date format in license: $valid_until"
        return 1
    fi
    
    current_timestamp=$(date +%s)
    
    if [[ $current_timestamp -gt $expiry_timestamp ]]; then
        print_error "License has expired on $valid_until"
        return 1
    else
        local days_remaining=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        if [[ $days_remaining -lt 30 ]]; then
            print_warning "License expires in $days_remaining days ($valid_until)"
        else
            print_success "License is valid until $valid_until ($days_remaining days remaining)"
        fi
        return 0
    fi
}

# Main validation function
main() {
    local license_file="${1:-$LICENSE_FILE}"
    
    print_info "HakPak Enterprise License Validator"
    echo "======================================"
    
    # Check dependencies
    if ! command -v openssl &>/dev/null; then
        print_error "OpenSSL is required for license validation"
        exit 1
    fi
    
    # Check public key
    if ! check_public_key; then
        exit 1
    fi
    
    # Validate license
    if ! validate_license "$license_file"; then
        print_error "License validation failed"
        exit 1
    fi
    
    # Parse and display license info
    parse_license "$license_file"
    echo
    
    # Check expiration
    if ! check_expiration "$license_file"; then
        exit 1
    fi
    
    print_success "License validation completed successfully"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [LICENSE_FILE]"
    echo ""
    echo "Validates HakPak Enterprise license files"
    echo ""
    echo "Arguments:"
    echo "  LICENSE_FILE    Path to license file (default: $LICENSE_FILE)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Validate default license"
    echo "  $0 /path/to/enterprise.lic      # Validate specific license file"
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
