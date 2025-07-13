import os
from dotenv import load_dotenv

# Load environment variables from root .env file if it exists
load_dotenv(dotenv_path="../.env")
# Also load from local .env file if it exists (for overrides)
load_dotenv()

# Configuration settings
class Config:
    # OpenAI API Configuration
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "your_openai_api_key_here")
    
    # Security Configuration
    SECRET_KEY = os.getenv("SECRET_KEY", "your_secret_key_for_jwt_here_change_this_to_something_secure")
    
    # Server Configuration
    HOST = os.getenv("HOST", "0.0.0.0")
    PORT = int(os.getenv("PORT", 8000))
    
    # Database Configuration
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///whisperme.db")
    
    # Usage Limits
    FREE_TRANSCRIPTION_LIMIT = int(os.getenv("FREE_TRANSCRIPTION_LIMIT", 10))
    
    # CORS Origins (for production, specify your app's origin)
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
    
    # Supabase Configuration (shared with Next.js app)
    SUPABASE_URL = os.getenv("SUPABASE_URL")
    SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
    SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    
    # API Keys
    PYTHON_SERVICE_API_KEY = os.getenv("PYTHON_SERVICE_API_KEY")

# Create config instance
config = Config()

# Instructions for setting up environment variables:
"""
Environment variables are loaded from the root .env file (../env) which is shared
between the Next.js app and Python backend. The root .env file contains:

OPENAI_API_KEY=your_actual_openai_api_key
SECRET_KEY=your_secure_secret_key_for_jwt
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
PYTHON_SERVICE_API_KEY=your_python_service_api_key
HOST=0.0.0.0
PORT=8000
FREE_TRANSCRIPTION_LIMIT=10

You can also create a local .env file in this directory to override any values.
""" 