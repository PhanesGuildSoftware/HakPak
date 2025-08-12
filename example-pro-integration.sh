#!/usr/bin/env bash
# example-pro-integration.sh
# Demonstrates how to integrate HakPak Pro license checking into your own tools

# Source just the license functions from HakPak
HAKPAK_DIR="$(dirname "$0")"

# We need to extract just the license checking functions
# In a real integration, you'd copy these functions to your own script
# or create a separate license checking library

# Simulate the license checking functions for this example
source_license_functions() {
    # These would be copied from hakpak.sh or provided as a separate library
    PUBLIC_KEY_PATH="./keys/public.pem"
    LICENSE_TARGET_SYSTEM="/etc/hakpak/license.lic"
    USER_LICENSE_PATH="$HOME/.config/hakpak/license.lic"
    
    # Find license file
    _find_license_file() {
        if [ -f "$LICENSE_TARGET_SYSTEM" ]; then
            echo "$LICENSE_TARGET_SYSTEM"
            return 0
        elif [ -f "$USER_LICENSE_PATH" ]; then
            echo "$USER_LICENSE_PATH"
            return 0
        else
            return 1
        fi
    }
    
    # Quick license validation check
    is_pro_valid() {
        local licfile
        if licfile=$(_find_license_file); then
            # Simple check - in production you'd do full crypto verification
            if [ -f "$PUBLIC_KEY_PATH" ] && [ -f "$licfile" ]; then
                # For demo purposes, assume valid if files exist
                return 0
            fi
        fi
        return 1
    }
    
    # Require Pro license
    require_pro() {
        if is_pro_valid; then
            return 0
        else
            echo
            echo "⚠️  HakPak Pro feature requires a valid Pro license."
            echo "📁 Place your license file at one of these locations:"
            echo "   $LICENSE_TARGET_SYSTEM"
            echo "   $USER_LICENSE_PATH"
            echo
            echo "🌐 To obtain a license, visit: https://phanesguild.llc/hakpak"
            echo "📧 Contact: enterprise@phanesguild.llc"
            return 1
        fi
    }
}

# Load the license functions
source_license_functions

# Example CLI application with Pro features
echo "=== Example Pro Feature Integration ==="
echo

# Simulate different actions based on user input
ACTION="${1:-help}"

case "$ACTION" in
    "install_pro_suite")
        echo "User requested Pro Suite installation..."
        
        # Example usage inside your CLI flow:
        if [ "$ACTION" = "install_pro_suite" ]; then
            require_pro || exit 1
            # proceed with pro-only installs
            echo "🔧 Installing Pro Security Suite..."
            echo "   • Advanced Vulnerability Scanner"
            echo "   • Enterprise Reporting Engine" 
            echo "   • Centralized Management Console"
            echo "   • Custom Payload Generator"
            echo "✅ Pro Suite installation completed!"
        fi
        ;;
        
    "generate_report")
        echo "User requested enterprise reporting..."
        
        # Another Pro feature example
        if [ "$ACTION" = "generate_report" ]; then
            require_pro || {
                echo "Enterprise reporting requires HakPak Pro license"
                echo "Falling back to basic report..."
                echo "Basic system scan results: 12 tools installed"
                exit 0
            }
            # Pro reporting features would go here
            echo "🔍 Generating comprehensive enterprise security report..."
            echo "📊 Advanced analytics enabled"
            echo "📈 Compliance metrics included"
            echo "✅ Enterprise report generated successfully"
        fi
        ;;
        
    "advanced_scan")
        echo "User requested advanced security scan..."
        
        # Pro scanning features
        if [ "$ACTION" = "advanced_scan" ]; then
            if require_pro; then
                echo "🎯 Launching Pro scanning engine..."
                echo "🔬 Deep vulnerability analysis enabled"
                echo "🌐 Network topology mapping active"
                echo "📋 Custom payload generation ready"
                echo "✅ Advanced scan completed"
            else
                echo "⚠️  Advanced scanning requires Pro license"
                echo "🔍 Running basic scan instead..."
                echo "ℹ️  Basic scan: nmap port scan completed"
            fi
        fi
        ;;
        
    "compliance_audit")
        echo "User requested compliance audit..."
        
        # Compliance features - Pro only
        require_pro || {
            echo "❌ Compliance auditing is a Pro-exclusive feature"
            echo "📞 Contact enterprise@phanesguild.llc for licensing"
            exit 1
        }
        
        echo "🛡️  Starting SOC 2 compliance audit..."
        echo "📋 Checking NIST framework alignment..."
        echo "🔍 ISO 27001 assessment in progress..."
        echo "✅ Compliance audit completed"
        ;;
        
    "init_mode")
        echo "Demonstrating elegant conditional license checking..."
        echo
        
        # Your requested pattern: elegant conditional check
        if require_pro; then
            echo "ℹ️  Pro license validated. Enabling Pro features..."
            echo "🚀 Initializing HakPak Pro mode..."
            echo "   ✅ Advanced vulnerability scanning enabled"
            echo "   ✅ Enterprise reporting dashboard available"
            echo "   ✅ Compliance audit framework loaded"
            echo "   ✅ Custom security bundles accessible"
            echo "   ✅ API access configured"
            echo "   ✅ Priority support activated"
        else
            echo "ℹ️  Running in Community mode."
            echo "🛠️  Initializing HakPak Community edition..."
            echo "   ✅ Core security tools available"
            echo "   ✅ Basic installation features enabled"
            echo "   ✅ Community documentation accessible"
            echo "   💡 Upgrade to Pro for enhanced capabilities"
        fi
        ;;
        
    "help"|*)
        echo "Available actions:"
        echo "  install_pro_suite  - Install Pro Security Suite (requires Pro license)"
        echo "  generate_report    - Enterprise reporting (Pro license with graceful fallback)"
        echo "  advanced_scan      - Advanced scanning (Pro license with basic fallback)"
        echo "  compliance_audit   - Compliance auditing (Pro license required)"
        echo "  init_mode          - Initialize with elegant mode detection"
        echo
        echo "Pro License Status:"
        if is_pro_valid; then
            echo "  ✅ Valid HakPak Pro license detected"
            echo "  🚀 All Pro features available"
        else
            echo "  ⚠️  No valid Pro license found"
            echo "  📞 Contact enterprise@phanesguild.llc for licensing"
        fi
        ;;
esac

echo
echo "Example completed. This demonstrates the Pro licensing integration pattern."
