#!/bin/bash

# HakPak Directory Validation Script
# Validates that this is the primary HakPak directory

echo "🛡️ HakPak Directory Validation"
echo "=============================="

# Check if we're in a HakPak directory
if [ -f ".hakpak-config" ] && [ -f "hakpak.sh" ]; then
    echo "✅ CONFIRMED: This is a valid HakPak primary directory"
    
    # Source configuration
    source .hakpak-config
    echo "📁 Project: $PROJECT_NAME v$PROJECT_VERSION"
    echo "👤 Author: $PROJECT_AUTHOR"
    echo "📍 Location: $(pwd)"
    
    # Check git status
    if [ -d ".git" ]; then
        echo "🔄 Git: Repository initialized"
        echo "📊 Commits: $(git rev-list --count HEAD 2>/dev/null || echo '0')"
    fi
    
    echo ""
    echo "🚀 Ready to use! Run: ./hakpak.sh"
else
    echo "❌ ERROR: This does not appear to be a HakPak directory"
    echo "Missing required files: .hakpak-config or hakpak.sh"
fi
