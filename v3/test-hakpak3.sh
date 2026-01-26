#!/usr/bin/env bash
#
# HakPak3 Test Script
# Validates installation and basic functionality
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}HakPak3 Test Suite${NC}\n"

PASSED=0
FAILED=0

test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

# Test 1: Check Python 3
echo -n "Testing Python 3 availability... "
if command -v python3 &> /dev/null; then
    VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    test_pass "Python $VERSION found"
else
    test_fail "Python 3 not found"
fi

# Test 2: Check Python version
echo -n "Testing Python version >= 3.8... "
if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)" 2>/dev/null; then
    test_pass "Python version OK"
else
    test_fail "Python 3.8+ required"
fi

# Test 3: Check core files exist
echo -n "Testing core files exist... "
if [[ -f "$SCRIPT_DIR/hakpak3.py" ]] && \
   [[ -f "$SCRIPT_DIR/hakpak3_core.py" ]] && \
   [[ -f "$SCRIPT_DIR/kali-tools-db.yaml" ]]; then
    test_pass "All core files present"
else
    test_fail "Missing core files"
fi

# Test 4: Check files are executable
echo -n "Testing files are executable... "
if [[ -x "$SCRIPT_DIR/hakpak3.sh" ]] && \
   [[ -x "$SCRIPT_DIR/install-hakpak3.sh" ]]; then
    test_pass "Scripts are executable"
else
    test_fail "Scripts not executable (run: chmod +x *.sh)"
fi

# Test 5: Check YAML syntax
echo -n "Testing YAML database syntax... "
if python3 -c "import yaml; yaml.safe_load(open('$SCRIPT_DIR/kali-tools-db.yaml'))" 2>/dev/null; then
    test_pass "YAML syntax valid"
else
    test_fail "YAML syntax error (PyYAML may not be installed)"
fi

# Test 6: Count tools in database
echo -n "Testing tool database content... "
TOOL_COUNT=$(python3 -c "import yaml; db=yaml.safe_load(open('$SCRIPT_DIR/kali-tools-db.yaml')); print(sum(len(v) if isinstance(v, dict) else 0 for v in db.values()))" 2>/dev/null || echo "0")
if [[ "$TOOL_COUNT" -gt 50 ]]; then
    test_pass "$TOOL_COUNT tools in database"
else
    test_fail "Tool database incomplete ($TOOL_COUNT tools)"
fi

# Test 7: Test version command
echo -n "Testing --version flag... "
if python3 "$SCRIPT_DIR/hakpak3.py" --version 2>&1 | grep -q "3.0.0"; then
    test_pass "Version command works"
else
    test_fail "Version command failed"
fi

# Test 8: Check documentation
echo -n "Testing documentation files... "
if [[ -f "$SCRIPT_DIR/README.md" ]] && \
   [[ -f "$SCRIPT_DIR/QUICKSTART.md" ]] && \
   [[ -f "$SCRIPT_DIR/CHANGELOG.md" ]]; then
    test_pass "Documentation complete"
else
    test_fail "Missing documentation"
fi

# Test 9: Validate Python syntax
echo -n "Testing Python syntax... "
if python3 -m py_compile "$SCRIPT_DIR/hakpak3.py" 2>/dev/null && \
   python3 -m py_compile "$SCRIPT_DIR/hakpak3_core.py" 2>/dev/null; then
    test_pass "Python syntax valid"
else
    test_fail "Python syntax errors detected"
fi

# Test 10: Check imports
echo -n "Testing Python imports (without PyYAML)... "
if python3 -c "import sys; sys.path.insert(0, '$SCRIPT_DIR'); from hakpak3 import Shell, SystemInfo, Tool, ToolCategory" 2>/dev/null; then
    test_pass "Core imports successful"
else
    test_fail "Import errors (may be normal without PyYAML)"
fi

# Summary
echo ""
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}Test Results${NC}"
echo -e "${CYAN}================================${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo -e "${CYAN}HakPak3 is ready to use.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Install PyYAML: pip3 install pyyaml"
    echo "  2. Run installer: sudo bash install-hakpak3.sh"
    echo "  3. Launch HakPak3: sudo hakpak3"
    exit 0
else
    echo -e "${YELLOW}Some tests failed${NC}"
    echo "Please review the failures above."
    echo ""
    echo "Common fixes:"
    echo "  - Install Python 3.8+: sudo apt install python3"
    echo "  - Install PyYAML: pip3 install pyyaml"
    echo "  - Make scripts executable: chmod +x *.sh *.py"
    exit 1
fi
