#!/usr/bin/env python3
"""
WhisperMe Backend - Entry Point for Cloud Deployment
"""

import os
import sys

# Add the whisperme-python directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'whisperme-python'))

def main():
    # Change to whisperme-python directory
    os.chdir('whisperme-python')
    
    # Import and run the start_server
    from start_server import main as start_main
    start_main()

if __name__ == "__main__":
    main() 