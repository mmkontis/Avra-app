#!/usr/bin/env python3
"""
WhisperMe Backend Deployment Helper
Helps configure the backend for cloud deployment
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  {text}")
    print(f"{'='*60}")

def print_step(step, text):
    print(f"\n{step}. {text}")

def check_file_exists(filepath):
    return os.path.exists(filepath) and os.path.getsize(filepath) > 0

def main():
    print_header("🚀 WhisperMe Backend Cloud Deployment Setup")
    
    # Step 1: Check current directory
    print_step(1, "Checking environment...")
    current_dir = os.getcwd()
    if not current_dir.endswith("whisperme-python"):
        print("❌ Please run this script from the whisperme-python directory")
        print(f"   Current directory: {current_dir}")
        print("   Expected: .../whisperme-python")
        sys.exit(1)
    print("✅ Running from correct directory")
    
    # Step 2: Check required files
    print_step(2, "Checking required files...")
    required_files = ["main.py", "config.py", "requirements.txt", "start_server.py"]
    missing_files = []
    
    for file in required_files:
        if check_file_exists(file):
            print(f"   ✅ {file}")
        else:
            print(f"   ❌ {file} (missing or empty)")
            missing_files.append(file)
    
    if missing_files:
        print(f"\n❌ Missing required files: {', '.join(missing_files)}")
        sys.exit(1)
    
    # Step 3: Environment configuration
    print_step(3, "Environment configuration...")
    env_file = ".env"
    env_example = ".env.example"
    
    if not check_file_exists(env_file):
        if check_file_exists(env_example):
            print(f"   📋 Copying {env_example} to {env_file}")
            shutil.copy(env_example, env_file)
            print(f"   ⚠️  Please edit {env_file} with your actual values")
        else:
            print(f"   ❌ Neither {env_file} nor {env_example} found")
            print("   Creating basic .env file...")
            with open(env_file, 'w') as f:
                f.write("""# WhisperMe Backend Environment Configuration
OPENAI_API_KEY=your_openai_api_key_here
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
SECRET_KEY=your_secure_jwt_secret_key
PORT=8000
HOST=0.0.0.0
ENVIRONMENT=production
""")
        print(f"   📝 Please edit {env_file} with your actual configuration")
    else:
        print(f"   ✅ {env_file} already exists")
    
    # Step 4: Dependencies check
    print_step(4, "Checking Python dependencies...")
    try:
        # Check if uv is available
        result = subprocess.run(["uv", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print("   ✅ uv package manager found")
            print("   📦 To install dependencies: uv sync")
        else:
            raise FileNotFoundError
    except FileNotFoundError:
        print("   ⚠️  uv not found, checking pip...")
        try:
            result = subprocess.run(["pip", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                print("   ✅ pip found")
                print("   📦 To install dependencies: pip install -r requirements.txt")
        except FileNotFoundError:
            print("   ❌ Neither uv nor pip found")
    
    # Step 5: Test configuration
    print_step(5, "Testing configuration...")
    print("   🧪 To test locally: python start_server.py")
    print("   🌐 To test API: curl http://localhost:8000/status")
    
    # Step 6: Cloud deployment instructions
    print_step(6, "Cloud deployment ready!")
    print_header("📋 DEPLOYMENT INSTRUCTIONS")
    
    print("""
🔧 For Sevalla deployment:
   1. Upload the whisperme-python/ folder to your Sevalla instance
   2. Set environment variables in Sevalla dashboard:
      - OPENAI_API_KEY
      - SUPABASE_URL  
      - SUPABASE_SERVICE_ROLE_KEY
      - SECRET_KEY
      - PORT (usually 8000)
      - ENVIRONMENT=production
   
   3. Install dependencies:
      pip install -r requirements.txt
   
   4. Start the server:
      python start_server.py
   
   5. Your API will be available at: https://your-sevalla-domain.com

🔄 For other platforms (Railway, Heroku, etc.):
   1. Set the same environment variables
   2. Use the start_server.py script as your entry point
   3. Ensure PORT is set correctly for the platform

🔗 Update your apps:
   1. Replace localhost:8000 with your Sevalla URL in:
      - Next.js app: NEXT_PUBLIC_BACKEND_URL
      - macOS app: Update baseURL in Constants.swift
      - iOS app: Update APIService.swift baseURL

📊 Health check endpoint: GET /status
📚 API docs: GET /docs (Swagger UI)
""")
    
    print_header("✅ Setup Complete!")
    print("Your WhisperMe backend is ready for cloud deployment!")

if __name__ == "__main__":
    main() 