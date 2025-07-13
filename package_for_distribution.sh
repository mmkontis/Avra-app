#!/bin/bash

# WhisperMe App Packaging Script for Distribution
# This script creates distributable formats compatible with AppUpdater

VERSION=${1:-"1.0.2"}  # Accept version as parameter, default to 1.0.2

echo "📦 WhisperMe Distribution Packager v$VERSION"
echo "============================================="

# Check if the app exists
APP_PATH="/Applications/whisperme.app"
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: whisperme.app not found in /Applications/"
    echo "Please build and install the app first using ./build_and_install.sh"
    exit 1
fi

# Create distribution directory
DIST_DIR="./distribution"
mkdir -p "$DIST_DIR"

echo "🔧 Creating distribution packages for version $VERSION..."

# AppUpdater-compatible ZIP file (Primary distribution method)
echo "1️⃣ Creating AppUpdater-compatible ZIP archive..."
cd /Applications

# AppUpdater requires naming format: {name}-{version}.zip
APPUPDATER_ZIP="whisperme-${VERSION}-arm64.zip"
zip -r "$OLDPWD/$DIST_DIR/$APPUPDATER_ZIP" whisperme.app

cd "$OLDPWD"
echo "✅ Created: $DIST_DIR/$APPUPDATER_ZIP (AppUpdater compatible)"

# Traditional ZIP for manual distribution
echo "2️⃣ Creating traditional ZIP archive..."
cd /Applications
zip -r "$OLDPWD/$DIST_DIR/WhisperMe-${VERSION}.zip" whisperme.app
cd "$OLDPWD"
echo "✅ Created: $DIST_DIR/WhisperMe-${VERSION}.zip"

# DMG file (Professional Distribution)
echo "3️⃣ Creating DMG installer..."
DMG_NAME="WhisperMe-${VERSION}-Installer"
DMG_PATH="$DIST_DIR/$DMG_NAME.dmg"

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create a symbolic link to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Create the DMG
hdiutil create -volname "$DMG_NAME" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG_PATH"

# Clean up
rm -rf "$TEMP_DIR"
echo "✅ Created: $DMG_PATH"

# Get file sizes
echo ""
echo "📊 Distribution Package Sizes:"
echo "------------------------------"
ls -lh "$DIST_DIR"

echo ""
echo "🎉 Distribution packages created successfully!"
echo ""
echo "📤 Upload Instructions:"
echo "----------------------"
echo "• AppUpdater ZIP ($APPUPDATER_ZIP): Upload to GitHub releases for automatic updates"
echo "• Traditional ZIP: Best for Google Drive, Dropbox, direct downloads"
echo "• DMG file: Professional installer for Mac distribution"
echo ""
echo "📝 For GitHub releases (AppUpdater):"
echo "1. Upload $APPUPDATER_ZIP as a release asset"
echo "2. Tag the release as v$VERSION"
echo "3. AppUpdater will automatically find and install updates"
echo ""
echo "📝 For manual installation:"
echo "1. Download the ZIP or DMG file"
echo "2. For ZIP: Double-click to extract, drag whisperme.app to Applications"
echo "3. For DMG: Double-click, drag whisperme.app to Applications folder"
echo "4. First run: Right-click → Open (to bypass Gatekeeper)" 