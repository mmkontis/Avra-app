#!/bin/bash

# WhisperMe Version Checker
# This script unpacks a zip file and reads the actual version information

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to clean up temporary files
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_status "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup on exit
trap cleanup EXIT

# Function to show usage
show_usage() {
    echo "Usage: $0 <zip_file_path_or_app_bundle>"
    echo ""
    echo "This script reads version information from a WhisperMe update zip file or app bundle."
    echo ""
    echo "Examples:"
    echo "  $0 test_updates/WhisperMe-1.0.3-arm64.zip"
    echo "  $0 ./WhisperMe-1.0.2-arm64.zip"
    echo "  $0 /Applications/WhisperMe.app"
    echo "  $0 ./WhisperMe.app"
    echo ""
}

# Check if file argument is provided
if [ $# -eq 0 ]; then
    print_error "No file provided"
    show_usage
    exit 1
fi

INPUT_FILE="$1"

# Check if input file exists
if [ ! -e "$INPUT_FILE" ]; then
    print_error "File not found: $INPUT_FILE"
    exit 1
fi

# Check if PlistBuddy is available (macOS specific)
if ! command -v /usr/libexec/PlistBuddy &> /dev/null; then
    print_error "PlistBuddy not found. This script requires macOS."
    exit 1
fi

print_status "Checking version information for: $INPUT_FILE"
echo "============================================================"

# Determine if input is a zip file or app bundle
if [[ "$INPUT_FILE" == *.zip ]]; then
    # Handle zip file
    if ! command -v unzip &> /dev/null; then
        print_error "unzip command not found. Please install unzip."
        exit 1
    fi
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    print_status "Created temporary directory: $TEMP_DIR"
    
    # Extract zip file
    print_status "Extracting zip file..."
    if ! unzip -q "$INPUT_FILE" -d "$TEMP_DIR"; then
        print_error "Failed to extract zip file"
        exit 1
    fi
    
    # Find the app bundle
    APP_BUNDLE=$(find "$TEMP_DIR" -name "*.app" -type d | head -1)
    
    if [ -z "$APP_BUNDLE" ]; then
        print_error "No .app bundle found in the zip file"
        print_status "Contents of zip file:"
        ls -la "$TEMP_DIR"
        exit 1
    fi
    
    print_success "Found app bundle: $(basename "$APP_BUNDLE")"
    
elif [[ "$INPUT_FILE" == *.app ]] && [ -d "$INPUT_FILE" ]; then
    # Handle app bundle directly
    APP_BUNDLE="$INPUT_FILE"
    print_success "Using app bundle: $(basename "$APP_BUNDLE")"
    
else
    print_error "Input must be either a .zip file or a .app bundle directory"
    exit 1
fi

# Check if Info.plist exists
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
    print_error "Info.plist not found at: $INFO_PLIST"
    exit 1
fi

print_status "Reading version information from Info.plist..."
echo "============================================================"

# Read version information using PlistBuddy
BUNDLE_VERSION=""
BUNDLE_SHORT_VERSION=""
BUNDLE_IDENTIFIER=""
BUNDLE_NAME=""

# Try to read CFBundleVersion
if /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" &> /dev/null; then
    BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")
fi

# Try to read CFBundleShortVersionString
if /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST" &> /dev/null; then
    BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
fi

# Try to read CFBundleIdentifier
if /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" &> /dev/null; then
    BUNDLE_IDENTIFIER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST")
fi

# Try to read CFBundleName
if /usr/libexec/PlistBuddy -c "Print :CFBundleName" "$INFO_PLIST" &> /dev/null; then
    BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$INFO_PLIST")
fi

# Display results
echo -e "${GREEN}Version Information:${NC}"
echo "  Bundle Name:           ${BUNDLE_NAME:-"Not found"}"
echo "  Bundle Identifier:     ${BUNDLE_IDENTIFIER:-"Not found"}"
echo "  Short Version String:  ${BUNDLE_SHORT_VERSION:-"Not found"}"
echo "  Bundle Version:        ${BUNDLE_VERSION:-"Not found"}"
echo ""

# Additional file information
echo -e "${BLUE}File Information:${NC}"
if [[ "$INPUT_FILE" == *.zip ]]; then
    echo "  Zip File:              $INPUT_FILE"
    echo "  Zip File Size:         $(du -h "$INPUT_FILE" | cut -f1)"
fi
echo "  App Bundle:            $(basename "$APP_BUNDLE")"
echo "  App Bundle Size:       $(du -sh "$APP_BUNDLE" | cut -f1)"
echo ""

# Show executable information if available
EXECUTABLE_PATH="$APP_BUNDLE/Contents/MacOS"
if [ -d "$EXECUTABLE_PATH" ]; then
    echo -e "${BLUE}Executable Information:${NC}"
    EXECUTABLE_FILE=$(find "$EXECUTABLE_PATH" -type f -perm +111 | head -1)
    if [ -n "$EXECUTABLE_FILE" ]; then
        echo "  Executable:            $(basename "$EXECUTABLE_FILE")"
        echo "  Executable Size:       $(du -h "$EXECUTABLE_FILE" | cut -f1)"
        
        # Check if file command is available
        if command -v file &> /dev/null; then
            echo "  File Type:             $(file "$EXECUTABLE_FILE" | cut -d: -f2 | xargs)"
        fi
    fi
    echo ""
fi

# Validate version consistency
echo -e "${YELLOW}Version Validation:${NC}"
if [ -n "$BUNDLE_SHORT_VERSION" ] && [ -n "$BUNDLE_VERSION" ]; then
    if [ "$BUNDLE_SHORT_VERSION" = "$BUNDLE_VERSION" ]; then
        print_success "Version strings are consistent: $BUNDLE_SHORT_VERSION"
    else
        print_warning "Version strings differ:"
        print_warning "  Short Version: $BUNDLE_SHORT_VERSION"
        print_warning "  Bundle Version: $BUNDLE_VERSION"
    fi
else
    print_warning "One or both version strings are missing"
fi

# Check if this matches expected filename version (only for zip files)
if [[ "$INPUT_FILE" == *.zip ]]; then
    FILENAME_VERSION=$(echo "$INPUT_FILE" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    if [ -n "$FILENAME_VERSION" ]; then
        echo ""
        echo -e "${YELLOW}Filename vs Bundle Version:${NC}"
        echo "  Filename Version:      $FILENAME_VERSION"
        echo "  Bundle Version:        ${BUNDLE_SHORT_VERSION:-$BUNDLE_VERSION}"
        
        if [ "$FILENAME_VERSION" = "${BUNDLE_SHORT_VERSION:-$BUNDLE_VERSION}" ]; then
            print_success "Filename and bundle versions match!"
        else
            print_warning "Filename and bundle versions do NOT match!"
        fi
    fi
fi

echo ""
echo "============================================================"
print_success "Version check completed successfully" 