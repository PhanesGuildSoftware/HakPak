#!/bin/bash

# Create PNG version of HakPak logo
# Since we don't have converters, we'll create a PNG using ImageMagick if available

echo "🎨 Creating HakPak PNG logo..."

# Check if ImageMagick convert is available
if command -v convert >/dev/null 2>&1; then
    echo "Using ImageMagick to create PNG..."
    
    # Create PNG with ImageMagick
    convert -size 256x256 xc:"#0d1117" \
        -fill "#21262d" -draw "rectangle 0,0 256,32" \
        -fill "#ff5f56" -draw "circle 16,16 16,11" \
        -fill "#ffbd2e" -draw "circle 36,16 36,11" \
        -fill "#27ca3f" -draw "circle 56,16 56,11" \
        -fill "#00ff41" -font "DejaVu-Sans-Mono-Bold" -pointsize 32 \
        -draw "text 20,150 '\$HakPak'" \
        -fill "none" -stroke "#00ff41" -strokewidth 2 \
        -draw "rectangle 170,125 186,153" \
        hakpak-logo.png
    
    echo "✅ PNG logo created successfully!"
    ls -la hakpak-logo.png
else
    echo "❌ ImageMagick not available"
    echo "📋 Manual PNG creation needed"
    echo ""
    echo "To create PNG manually:"
    echo "1. Install inkscape: sudo apt install inkscape"
    echo "2. Run: inkscape hakpak-logo.svg --export-type=png --export-filename=hakpak-logo.png --export-width=256"
    echo ""
    echo "Or install imagemagick: sudo apt install imagemagick"
fi
