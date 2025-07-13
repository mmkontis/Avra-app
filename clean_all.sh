#!/bin/bash

# WhisperMe Complete Cleanup Script
# This script removes all build artifacts, preferences, and temporary files

echo "🧹 WhisperMe Complete Cleanup"
echo "============================="

# Stop any running instances
echo "⏹️  Stopping any running WhisperMe instances..."
killall whisperme 2>/dev/null || true
killall "Avra" 2>/dev/null || true

# Clean Xcode build data
echo "🗑️  Cleaning Xcode build data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/whisperme-*
rm -rf build/

# Clean installed app
echo "🗑️  Removing installed app..."
rm -rf /Applications/whisperme.app
rm -rf /Applications/Avra.app

# Clean app preferences and data
echo "🗑️  Cleaning app preferences and data..."
rm -rf ~/Library/Preferences/com.yourcompany.whisperme.plist 2>/dev/null || true
rm -rf ~/Library/Preferences/humanlike.whisperme.plist 2>/dev/null || true
rm -rf ~/Library/Application\ Support/whisperme/ 2>/dev/null || true
rm -rf ~/Library/Application\ Support/humanlike.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Caches/com.yourcompany.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Caches/humanlike.whisperme/ 2>/dev/null || true
rm -rf ~/Library/Saved\ Application\ State/com.yourcompany.whisperme.savedState/ 2>/dev/null || true
rm -rf ~/Library/Saved\ Application\ State/humanlike.whisperme.savedState/ 2>/dev/null || true

# Clean up temporary files
echo "🗑️  Cleaning temporary files..."
find ~/Documents -name "recording_*.wav" -delete 2>/dev/null || true
find ~/Downloads -name "whisperme-*.zip" -delete 2>/dev/null || true
find ~/Downloads -name "Avra-*.zip" -delete 2>/dev/null || true
find ~/Downloads -name "WhisperMe-*.dmg" -delete 2>/dev/null || true

# Clean up quarantine attributes
echo "🗑️  Removing quarantine attributes..."
find . -name "*.app" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find . -name "*.dmg" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find . -name "*.zip" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

# Clean up build artifacts
echo "🗑️  Cleaning build artifacts..."
rm -rf distribution/ 2>/dev/null || true
rm -rf releases/ 2>/dev/null || true

# Clean up additional files
echo "🗑️  Cleaning additional files..."
rm -rf Avra-*.zip 2>/dev/null || true
rm -rf WhisperMe-*.dmg 2>/dev/null || true
rm -rf *.dmg 2>/dev/null || true

echo "✅ Complete cleanup finished!"
echo "You can now run ./build_and_install.sh to build fresh." 