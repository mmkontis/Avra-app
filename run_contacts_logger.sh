#!/bin/bash

# WhisperMe Contacts Logger Server Runner
# This script starts the localhost server to receive contacts from the macOS app

echo "🚀 Starting WhisperMe Contacts Logger Server..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 to run the contacts logger."
    exit 1
fi

# Check if the contacts logger script exists
if [ ! -f "contacts_logger.py" ]; then
    echo "❌ contacts_logger.py not found in current directory."
    echo "Please make sure you're running this script from the WhisperMe project root."
    exit 1
fi

# Make the Python script executable
chmod +x contacts_logger.py

# Start the server
echo "📡 Starting server on localhost:3001..."
python3 contacts_logger.py

echo "👋 Contacts Logger Server stopped." 