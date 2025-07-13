#!/bin/bash

# WhisperMe Release Script
# This script automates the release process using release-it

set -e

echo "🚀 WhisperMe Release Manager"
echo "============================"

# Check if Node.js and npm are installed
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if release-it is installed
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if GITHUB_TOKEN is set for GitHub releases
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠️  Warning: GITHUB_TOKEN not set"
    echo "GitHub releases will not be created automatically"
    echo "To enable GitHub releases, set GITHUB_TOKEN environment variable"
    echo ""
fi

# Show current version
CURRENT_VERSION=$(node -p "require('./package.json').version")
echo "📋 Current version: $CURRENT_VERSION"
echo ""

# Ask user what type of release they want
echo "Select release type:"
echo "1) Patch (bug fixes) - increments 1.0.1 → 1.0.2"
echo "2) Minor (new features) - increments 1.0.1 → 1.1.0"
echo "3) Major (breaking changes) - increments 1.0.1 → 2.0.0"
echo "4) Custom version"
echo "5) Dry run (see what would happen)"

read -p "Choice (1-5): " choice

case $choice in
    1)
        echo "🔧 Running patch release..."
        npm run release -- patch
        ;;
    2)
        echo "✨ Running minor release..."
        npm run release -- minor
        ;;
    3)
        echo "💥 Running major release..."
        npm run release -- major
        ;;
    4)
        read -p "Enter custom version (e.g., 1.2.3): " custom_version
        echo "🎯 Running custom release to version $custom_version..."
        npm run release -- "$custom_version"
        ;;
    5)
        echo "🧪 Running dry run..."
        npm run release -- --dry-run
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Release process completed!"
echo ""
echo "📝 Next steps:"
echo "1. Check the GitHub release was created successfully"
echo "2. Verify the ZIP file was uploaded as an asset"
echo "3. Test the AppUpdater by running the app and checking for updates"
echo "4. Announce the release to users!" 