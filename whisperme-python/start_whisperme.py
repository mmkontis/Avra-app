#!/usr/bin/env python3
"""
🚀 WhisperMe - Starting Point Script

This script helps you get started with WhisperMe by directing you to the appropriate backend setup.
"""

import os
import sys
import subprocess
from pathlib import Path

def print_banner():
    print("""
╔══════════════════════════════════════════════════════════════╗
║                           🎤 WhisperMe                       ║
║                    Audio Transcription Platform              ║
╚══════════════════════════════════════════════════════════════╝
    """)

def print_section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

def check_directory_exists(path):
    return os.path.exists(path) and os.path.isdir(path)

def main():
    print_banner()
    
    print("Welcome to WhisperMe! Let's get your backend up and running.")
    
    # Check current working directory
    current_dir = os.getcwd()
    print(f"\n📍 Current directory: {current_dir}")
    
    # Check for the Python backend directory
    python_backend_dir = "whisperme-python"
    
    if not check_directory_exists(python_backend_dir):
        print(f"\n❌ Python backend directory '{python_backend_dir}' not found!")
        print("Please ensure you're running this script from the WhisperMe project root.")
        sys.exit(1)
    
    print(f"✅ Found Python backend directory: {python_backend_dir}")
    
    print_section("🐍 Python Backend Setup")
    print(f"Your WhisperMe Python backend is located in: {python_backend_dir}/")
    print("\nTo set up and run the backend:")
    print(f"1. cd {python_backend_dir}")
    print("2. python deploy.py              # Setup deployment")
    print("3. python start_server.py        # Start server locally")
    
    print_section("☁️ Cloud Deployment")
    print("For cloud deployment (Sevalla, Railway, Heroku):")
    print(f"1. cd {python_backend_dir}")
    print("2. python deploy.py              # Deployment helper")
    print("3. Follow the cloud deployment guide in CLOUD_DEPLOYMENT.md")
    
    print_section("📱 Client Apps")
    print("After setting up the backend, update your client apps:")
    print("\n🖥️  macOS App:")
    print("   - Update baseURL in whisperme/Constants.swift")
    print("   - Replace localhost:8000 with your cloud URL")
    
    print("\n🌐 Next.js App:")
    print("   - Update NEXT_PUBLIC_BACKEND_URL in environment variables")
    print("   - Located in whisperme-nextapp/")
    
    print_section("🚀 Quick Start")
    choice = input("\nWould you like to navigate to the Python backend directory now? (y/n): ").lower().strip()
    
    if choice in ['y', 'yes']:
        print(f"\n📂 Changing to {python_backend_dir} directory...")
        try:
            # Change to the Python backend directory
            os.chdir(python_backend_dir)
            print(f"✅ Now in: {os.getcwd()}")
            
            # Ask if they want to run the deployment helper
            deploy_choice = input("\nRun the deployment helper now? (y/n): ").lower().strip()
            if deploy_choice in ['y', 'yes']:
                print("\n🔧 Running deployment helper...")
                subprocess.run([sys.executable, "deploy.py"])
            else:
                print("\n📋 Manual setup:")
                print("   python deploy.py        # Setup deployment")
                print("   python start_server.py  # Start server")
                
        except Exception as e:
            print(f"❌ Error changing directory: {e}")
            print(f"Please manually navigate to {python_backend_dir} and run: python deploy.py")
    else:
        print(f"\n📋 Next steps:")
        print(f"1. cd {python_backend_dir}")
        print("2. python deploy.py")
        print("3. python start_server.py")
    
    print_section("📚 Documentation")
    print(f"📖 Backend README: {python_backend_dir}/README.md")
    print(f"☁️  Cloud Guide: {python_backend_dir}/CLOUD_DEPLOYMENT.md")
    print("🌐 API Docs: http://localhost:8000/docs (after starting server)")
    
    print("\n🎉 Happy transcribing!")

if __name__ == "__main__":
    main() 