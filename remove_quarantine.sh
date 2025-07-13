#!/bin/bash

# WhisperMe Quarantine Removal Script
# This script removes macOS quarantine attributes that prevent the app from opening

echo "🔓 WhisperMe Quarantine Removal Tool"
echo "====================================="

APP_PATH="/Applications/whisperme.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: whisperme.app not found in /Applications/"
    echo "Please install WhisperMe first by dragging it to Applications folder"
    exit 1
fi

echo "🔍 Checking quarantine attributes..."

# Check if app has quarantine attributes
if xattr -l "$APP_PATH" | grep -q "com.apple.quarantine"; then
    echo "⚠️  App has quarantine attributes - removing them..."
    
    # Remove quarantine attributes
    xattr -d com.apple.quarantine "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        echo "✅ Quarantine attributes removed successfully!"
        echo "🎉 WhisperMe should now open properly"
    else
        echo "❌ Failed to remove quarantine attributes"
        echo "You may need to run this script with sudo:"
        echo "sudo ./remove_quarantine.sh"
        exit 1
    fi
else
    echo "✅ App has no quarantine attributes - it should open normally"
fi

echo ""
echo "📋 Alternative methods if app still won't open:"
echo "1. Right-click whisperme.app → Open → Open (bypass Gatekeeper)"
echo "2. System Preferences → Security & Privacy → Allow apps downloaded from: Anywhere"
echo "3. Or run: sudo spctl --master-disable"
echo ""
echo "🚀 Try opening WhisperMe now!" 