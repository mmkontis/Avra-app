#!/bin/bash

# WhisperMe Build and Install Script
# This script builds WhisperMe and installs it to /Applications

echo "🔨 Building WhisperMe..."

# Stop any running instances
killall whisperme 2>/dev/null || true

# Clean old builds and app data
rm -rf ~/Library/Developer/Xcode/DerivedData/whisperme-*
rm -rf /Applications/whisperme.app
rm -rf build/

# Clean app preferences and data to ensure fresh start
rm -rf ~/Library/Preferences/com.yourcompany.whisperme.plist 2>/dev/null || true
rm -rf ~/Library/Preferences/humanlike.whisperme.plist 2>/dev/null || true
rm -rf ~/Library/Application\ Support/whisperme/ 2>/dev/null || true
rm -rf ~/Library/Application\ Support/humanlike.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Caches/com.yourcompany.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Caches/humanlike.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Saved\ Application\ State/com.yourcompany.whisperme.savedState/ 2>/dev/null || true
rm -rf ~/Library/Saved\ Application\ State/humanlike.whisperme.savedState/ 2>/dev/null || true

# Clean up any temporary audio files
find ~/Documents -name "recording_*.wav" -delete 2>/dev/null || true
find ~/Downloads -name "whisperme-*.zip" -delete 2>/dev/null || true
find ~/Downloads -name "Avra-*.zip" -delete 2>/dev/null || true

# Clean up any quarantine attributes from current directory
find . -name "*.app" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find . -name "*.dmg" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find . -name "*.zip" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

# Clean up build artifacts
rm -rf distribution/ 2>/dev/null || true
rm -rf releases/ 2>/dev/null || true

echo "🧹 Cleaned old builds, app data, preferences, and temp files"

# Build the app
xcodebuild -scheme whisperme -configuration Release -workspace whisperme.xcodeproj/project.xcworkspace -destination "platform=macOS,arch=arm64" clean build

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded!"
    
    # Find the built app
    DERIVED_DATA_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "whisperme-*" -type d | head -1)
    
    if [ -n "$DERIVED_DATA_PATH" ]; then
        # Install to Applications
        echo "📦 Installing to /Applications..."
        cp -R "$DERIVED_DATA_PATH/Build/Products/Release/whisperme.app" /Applications/
        
        echo "🚀 Launching WhisperMe..."
        open /Applications/whisperme.app
        
        echo "🎉 WhisperMe updated and launched successfully!"
        echo "Look for the microphone icon (🎤) in your menu bar."
    else
        echo "❌ Could not find built app"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi 