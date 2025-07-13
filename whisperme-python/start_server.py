#!/usr/bin/env python3
"""
Production server startup script for WhisperMe Backend
Optimized for cloud deployment (Sevalla, Railway, etc.)
"""

import os
import sys
import uvicorn
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def main():
    # Get configuration from environment variables
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", 8000))
    workers = int(os.getenv("WORKERS", 1))
    
    # Production vs Development mode
    is_production = os.getenv("ENVIRONMENT", "development") == "production"
    
    print(f"🚀 Starting WhisperMe Backend Server...")
    print(f"📍 Host: {host}")
    print(f"🔌 Port: {port}")
    print(f"👥 Workers: {workers}")
    print(f"🌍 Environment: {'Production' if is_production else 'Development'}")
    
    # Validate required environment variables
    required_vars = [
        "OPENAI_API_KEY",
        "SUPABASE_URL", 
        "SUPABASE_SERVICE_ROLE_KEY"
    ]
    
    missing_vars = []
    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)
    
    if missing_vars:
        print(f"❌ Missing required environment variables: {', '.join(missing_vars)}")
        print("\n📋 Required environment variables:")
        print("   OPENAI_API_KEY=your_openai_api_key")
        print("   SUPABASE_URL=your_supabase_url") 
        print("   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key")
        print("   SECRET_KEY=your_jwt_secret_key (optional)")
        print("   PORT=8000 (optional)")
        print("   HOST=0.0.0.0 (optional)")
        print("   ENVIRONMENT=production (optional)")
        sys.exit(1)
    
    print("✅ All required environment variables are set")
    
    # Start the server
    if is_production and workers > 1:
        # Use gunicorn for production with multiple workers
        import subprocess
        cmd = [
            "gunicorn",
            "main:app",
            f"--bind={host}:{port}",
            f"--workers={workers}",
            "--worker-class=uvicorn.workers.UvicornWorker",
            "--access-logfile=-",
            "--error-logfile=-",
            "--log-level=info"
        ]
        subprocess.run(cmd)
    else:
        # Use uvicorn for development or single worker
        uvicorn.run(
            "main:app",
            host=host,
            port=port,
            reload=not is_production,
            log_level="info" if is_production else "debug"
        )

if __name__ == "__main__":
    main() 