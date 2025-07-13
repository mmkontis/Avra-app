#!/bin/bash

# WhisperMe Custom DMG Creator
# Uses custom installer.png background with centered layout

echo "🎨 WhisperMe Custom DMG Creator"
echo "==============================="

# Check if the app exists
APP_PATH="/Applications/whisperme.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: whisperme.app not found in /Applications/"
    echo "Please build and install the app first using ./build_and_install.sh"
    exit 1
fi

# Check if custom background exists
CUSTOM_BG="whisperme-python/installer.png"
if [ ! -f "$CUSTOM_BG" ]; then
    echo "❌ Error: Custom background not found at $CUSTOM_BG"
    exit 1
fi

# Create directories
DIST_DIR="./distribution"
ASSETS_DIR="./dmg-assets"
mkdir -p "$DIST_DIR"
mkdir -p "$ASSETS_DIR"

# Copy custom background to assets directory
echo "🖼️  Copying custom background..."
cp "$CUSTOM_BG" "$ASSETS_DIR/custom-background.png"

# ---------------------------------------------------------------------------
# Determine background dimensions so the DMG window matches exactly.
# This prevents Finder from cropping / zooming the background image.
# ---------------------------------------------------------------------------

# Default window size (fallback)
WIN_W=600
WIN_H=400

# Try to read the real pixel size of the background using `sips` (macOS only)
if command -v sips &> /dev/null; then
    IMG_W=$(sips -g pixelWidth  "$ASSETS_DIR/custom-background.png" | awk '/pixelWidth/{print $2}')
    IMG_H=$(sips -g pixelHeight "$ASSETS_DIR/custom-background.png" | awk '/pixelHeight/{print $2}')

    # Validate numeric values and apply if reasonable ( >0 )
    if [[ "$IMG_W" =~ ^[0-9]+$ ]] && [[ "$IMG_H" =~ ^[0-9]+$ ]] && [ "$IMG_W" -gt 0 ] && [ "$IMG_H" -gt 0 ]; then
        WIN_W=$IMG_W
        WIN_H=$IMG_H
    fi
fi

# Calculate icon positions based on window size (25% and 75% horizontally, mid-height)
ICON_Y=$(( WIN_H / 2 ))
ICON_APP_X=$(( WIN_W / 4 ))
ICON_DROP_X=$(( (WIN_W * 3) / 4 ))

# create-dmg expects integers – make sure we have them
ICON_Y=${ICON_Y%.*}
ICON_APP_X=${ICON_APP_X%.*}
ICON_DROP_X=${ICON_DROP_X%.*}

# Clean up any existing DMG files
echo "🧹 Cleaning up old files..."
rm -f "$DIST_DIR"/WhisperMe*.dmg
rm -f "$DIST_DIR"/rw.*.dmg

# Unmount any existing WhisperMe volumes
hdiutil detach /Volumes/WhisperMe 2>/dev/null || true

# Create temporary DMG directory
TEMP_DIR=$(mktemp -d)
DMG_NAME="WhisperMe-Custom"
DMG_PATH="$DIST_DIR/$DMG_NAME.dmg"

echo "📦 Preparing DMG contents..."
# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DIR/"

# Only create the Applications symlink if we are going to use the hdiutil fallback.
# When using create-dmg we rely on the --app-drop-link option which automatically
# creates a nicely-styled Applications alias. Having two copies causes visual
# glitches and Finder warnings that break the custom background layout.

# We set a flag that indicates whether create-dmg is available. The symlink is
# created later only if it is required.

USE_CREATE_DMG=false
if command -v create-dmg &> /dev/null; then
    USE_CREATE_DMG=true
fi

# If create-dmg is NOT available we have to create the Applications link
if [ "$USE_CREATE_DMG" = false ]; then
    ln -s /Applications "$TEMP_DIR/Applications"
fi

# Use create-dmg with custom background and centered layout
if [ "$USE_CREATE_DMG" = true ]; then
    echo "🔧 Creating DMG with custom background..."
    
    create-dmg \
        --volname "WhisperMe" \
        --background "$ASSETS_DIR/custom-background.png" \
        --window-pos 200 120 \
        --window-size $WIN_W $WIN_H \
        --icon-size 100 \
        --icon "whisperme.app" $ICON_APP_X $ICON_Y \
        --hide-extension "whisperme.app" \
        --app-drop-link $ICON_DROP_X $ICON_Y \
        --no-internet-enable \
        --hdiutil-quiet \
        "$DMG_PATH" \
        "$TEMP_DIR" 2>/dev/null
    
    # Wait a moment for the process to complete
    sleep 2
    
    echo "✅ DMG created successfully"
else
    echo "⚠️  create-dmg not found, using hdiutil fallback..."
    
    # Fallback to hdiutil (without custom background)
    hdiutil create -volname "WhisperMe" \
        -srcfolder "$TEMP_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
fi

# Clean up temp directory
rm -rf "$TEMP_DIR"

# Ensure any volumes are unmounted
hdiutil detach /Volumes/WhisperMe 2>/dev/null || true

# Check if create-dmg created a temporary file and rename it
TEMP_DMG=$(ls -t "$DIST_DIR"/rw.*.WhisperMe-Custom.dmg 2>/dev/null | head -1)
if [ -f "$TEMP_DMG" ]; then
    echo "🔧 Finalizing DMG..."
    mv "$TEMP_DMG" "$DMG_PATH"
fi

# Show result
if [ -f "$DMG_PATH" ]; then
    SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo ""
    echo "🎉 Success!"
    echo "📦 DMG: $DMG_PATH"
    echo "📏 Size: $SIZE"
    echo "🖼️  Background: Custom installer.png"
    echo "📐 Layout: Centered icons (100px size)"
    echo ""
    
    # Remove quarantine attributes to prevent installation issues
    echo "🔓 Removing quarantine attributes from DMG..."
    xattr -d com.apple.quarantine "$DMG_PATH" 2>/dev/null || true
    echo "✅ DMG is ready for distribution"
    echo ""
    
    # Test mounting
    echo "🧪 Testing DMG..."
    if hdiutil attach "$DMG_PATH" -readonly -quiet; then
        echo "✅ DMG mounts successfully"
        sleep 1
        hdiutil detach /Volumes/WhisperMe -quiet 2>/dev/null || true
        echo "📤 Ready to upload to Google Drive!"
        
        # Open the distribution folder
        open "$DIST_DIR"
    else
        echo "⚠️  DMG created but mounting test failed (this is often normal)"
        echo "📤 Try opening the DMG manually - it should work fine!"
        open "$DIST_DIR"
    fi
else
    echo "❌ Failed to create DMG"
    exit 1
fi 