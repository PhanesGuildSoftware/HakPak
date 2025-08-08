#!/bin/bash

# Hakpak Test Suite
# Tests the functionality of Hakpak installation

# Note: Not using set -e here as we want tests to continue even if some fail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

print_test_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      HAKPAK TEST SUITE                      ║"
    echo "║                  Verification & Validation                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++)) || true
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++)) || true
}

test_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

test_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test 1: File Existence
test_file_existence() {
    test_info "Testing file existence..."
    
    local files=(
        "hakpak.sh"
        "install.sh"
        "README.md"
        "LICENSE"
        "hakpak.desktop"
        "hakpak.svg"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            test_pass "File exists: $file"
        else
            test_fail "File missing: $file"
        fi
    done
}

# Test 2: Script Permissions
test_permissions() {
    test_info "Testing file permissions..."
    
    if [[ -x "$SCRIPT_DIR/hakpak.sh" ]]; then
        test_pass "hakpak.sh is executable"
    else
        test_fail "hakpak.sh is not executable"
    fi
    
    if [[ -x "$SCRIPT_DIR/install.sh" ]]; then
        test_pass "install.sh is executable"
    else
        test_fail "install.sh is not executable"
    fi
}

# Test 3: Syntax Check
test_syntax() {
    test_info "Testing script syntax..."
    
    if bash -n "$SCRIPT_DIR/hakpak.sh" 2>/dev/null; then
        test_pass "hakpak.sh syntax is valid"
    else
        test_fail "hakpak.sh has syntax errors"
    fi
    
    if bash -n "$SCRIPT_DIR/install.sh" 2>/dev/null; then
        test_pass "install.sh syntax is valid"
    else
        test_fail "install.sh has syntax errors"
    fi
}

# Test 4: Required Commands
test_required_commands() {
    test_info "Testing required system commands..."
    
    local commands=(
        "apt"
        "curl"
        "gpg"
        "ping"
        "df"
        "grep"
    )
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            test_pass "Command available: $cmd"
        else
            test_fail "Command missing: $cmd"
        fi
    done
}

# Test 5: System Compatibility
test_system_compatibility() {
    test_info "Testing system compatibility..."
    
    # Check if running on Linux
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        test_pass "Running on Linux"
    else
        test_warn "Not running on Linux (detected: $OSTYPE)"
    fi
    
    # Check for systemd (common on Ubuntu)
    if command -v systemctl &> /dev/null; then
        test_pass "Systemd detected"
    else
        test_warn "Systemd not detected"
    fi
    
    # Check for APT package manager
    if command -v apt &> /dev/null; then
        test_pass "APT package manager available"
    else
        test_fail "APT package manager not found"
    fi
}

# Test 6: Network Connectivity
test_network() {
    test_info "Testing network connectivity..."
    
    # Test basic connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        test_pass "Internet connectivity available"
    else
        test_warn "No internet connectivity (some features may not work)"
    fi
    
    # Test Kali repository accessibility
    if curl -s --connect-timeout 5 "http://http.kali.org/kali/dists/kali-rolling/Release" &> /dev/null; then
        test_pass "Kali repository accessible"
    else
        test_warn "Kali repository not accessible (network or server issue)"
    fi
}

# Test 7: Desktop Integration
test_desktop_integration() {
    test_info "Testing desktop integration files..."
    
    if [[ -f "$SCRIPT_DIR/hakpak.desktop" ]]; then
        test_pass "Desktop entry file exists"
        
        # Check for required desktop entry fields
        if grep -q "Name=" "$SCRIPT_DIR/hakpak.desktop"; then
            test_pass "Desktop entry has Name field"
        else
            test_warn "Desktop entry missing Name field"
        fi
        
        if grep -q "Exec=" "$SCRIPT_DIR/hakpak.desktop"; then
            test_pass "Desktop entry has Exec field"
        else
            test_warn "Desktop entry missing Exec field"
        fi
        
        if grep -q "Icon=" "$SCRIPT_DIR/hakpak.desktop"; then
            test_pass "Desktop entry has Icon field"
        else
            test_warn "Desktop entry missing Icon field"
        fi
    else
        test_fail "Desktop entry file missing"
    fi
    
    # Check for icon files
    local icon_files=(
        "hakpak.svg"
        "hakpak-16.png"
        "hakpak-32.png"
        "hakpak-48.png"
        "hakpak-64.png"
        "hakpak-128.png"
    )
    
    for icon in "${icon_files[@]}"; do
        if [[ -f "$SCRIPT_DIR/$icon" ]]; then
            test_pass "Icon exists: $icon"
        else
            test_warn "Icon missing: $icon"
        fi
    done
}

# Test 8: Documentation
test_documentation() {
    test_info "Testing documentation completeness..."
    
    if [[ -f "$SCRIPT_DIR/README.md" ]]; then
        # Check for key sections
        local sections=(
            "Installation"
            "Usage"
            "Features"
            "Requirements"
            "Troubleshooting"
        )
        
        for section in "${sections[@]}"; do
            if grep -qi "$section" "$SCRIPT_DIR/README.md"; then
                test_pass "README contains: $section"
            else
                test_warn "README missing section: $section"
            fi
        done
    else
        test_fail "README.md not found"
    fi
}

# Test 9: Security Features
test_security_features() {
    test_info "Testing security features in script..."
    
    # Check for set -euo pipefail (enhanced error handling)
    if grep -q "set -euo pipefail" "$SCRIPT_DIR/hakpak.sh"; then
        test_pass "Enhanced error handling enabled (set -euo pipefail)"
    else
        test_warn "Enhanced error handling not enabled"
    fi
    
    # Check for input validation
    if grep -q "read -r" "$SCRIPT_DIR/hakpak.sh"; then
        test_pass "Safe input reading (read -r)"
    else
        test_warn "Input reading may be unsafe"
    fi
    
    # Check for root check
    if grep -q "EUID" "$SCRIPT_DIR/hakpak.sh"; then
        test_pass "Root privilege check implemented"
    else
        test_fail "Root privilege check missing"
    fi
    
    # Check for logging
    if grep -q "log_message" "$SCRIPT_DIR/hakpak.sh"; then
        test_pass "Logging functionality implemented"
    else
        test_warn "Logging functionality missing"
    fi
    
    # Check for distribution detection
    if grep -q "detect_distribution" "$SCRIPT_DIR/hakpak.sh"; then
        test_pass "Distribution detection implemented"
    else
        test_warn "Distribution detection missing"
    fi
}

# Summary
print_summary() {
    echo
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}          TEST SUMMARY${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "${BLUE}Total Tests:  $((TESTS_PASSED + TESTS_FAILED))${NC}"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! Hakpak is ready to use.${NC}"
        echo -e "${BLUE}Run: sudo ./hakpak.sh${NC}"
    elif [[ $TESTS_FAILED -lt 3 ]]; then
        echo -e "${YELLOW}⚠️  Minor issues detected, but Hakpak should work.${NC}"
        echo -e "${BLUE}Review warnings above and run: sudo ./hakpak.sh${NC}"
    else
        echo -e "${RED}❌ Critical issues detected. Please fix before using.${NC}"
        echo -e "${RED}Review failed tests above before proceeding.${NC}"
    fi
}

# Main execution
main() {
    print_test_header
    
    test_file_existence
    test_permissions
    test_syntax
    test_required_commands
    test_system_compatibility
    test_network
    test_desktop_integration
    test_documentation
    test_security_features
    
    print_summary
}

# Run tests
main "$@"
