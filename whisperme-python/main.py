from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from typing import Optional, Dict, Any, List
import openai
import os
import tempfile
import hashlib
import jwt
from datetime import datetime, timedelta
import httpx
from dotenv import load_dotenv
import bcrypt
from passlib.context import CryptContext
import logging
import sys
from supabase import create_client, Client
import json
import requests
from urllib.parse import quote
import uuid
import base64
import asyncio
from fastapi import FastAPI, File, UploadFile, Form, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn
from supabase import create_client, Client
from openai import OpenAI
# import aiofiles  # Not needed for current implementation

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('whisperme.log')
    ]
)
logger = logging.getLogger(__name__)

load_dotenv()

logger.info("🚀 Starting WhisperMe Backend Server...")

app = FastAPI(title="WhisperMe Backend", version="1.0.0")

# CORS middleware for your Next.js app and macOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8000", "https://whisperme-piih0.sevalla.app", "*"],  # Add your Next.js app
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("🌐 CORS middleware configured")

# Configuration
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-this")
FREE_TRANSCRIPTION_LIMIT = 10
UNLIMITED_USAGE = 999999  # Large finite number representing unlimited usage (for Pydantic validation)
RATE_LIMITING_ENABLED = False  # Disable rate limiting for development

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

logger.info(f"🔑 OpenAI API Key configured: {'✅ Yes' if OPENAI_API_KEY else '❌ No'}")
logger.info(f"🗄️  Supabase URL configured: {'✅ Yes' if SUPABASE_URL else '❌ No'}")
logger.info(f"📊 Free transcription limit: {FREE_TRANSCRIPTION_LIMIT}")
logger.info("⚠️  RATE LIMITING DISABLED - All users have unlimited transcriptions")

# Initialize OpenAI client with optimizations
openai_client = OpenAI(
    api_key=OPENAI_API_KEY,
    timeout=30.0,  # Timeout for requests
    max_retries=2,  # Reduce retries for faster failure
)

# Initialize Supabase client
if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    logger.error("Supabase configuration missing! Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY")
    raise Exception("Supabase configuration missing")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
logger.info("✅ Supabase client initialized successfully")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Database setup - Using Supabase instead of SQLite
def init_db():
    logger.info("🔍 Checking Supabase database connection...")
    try:
        # Test connection by checking if our tables exist
        response = supabase.table('users').select("id").limit(1).execute()
        logger.info("✅ Supabase database connection successful")
        logger.info("🗄️  Using Supabase database with public.users and public.transcriptions tables")
    except Exception as e:
        logger.error(f"❌ Supabase database connection failed: {str(e)}")
        raise Exception(f"Database connection failed: {str(e)}")

init_db()

# Pydantic models
class TranscriptionRequest(BaseModel):
    device_id: str
    language: Optional[str] = "auto"
    model: Optional[str] = "whisper-1"
    prompt: Optional[str] = ""

class UserRegistration(BaseModel):
    device_id: str
    email: Optional[str] = None

class TranscriptionResponse(BaseModel):
    text: str
    usage_remaining: int
    is_premium: bool

class UserStats(BaseModel):
    usage_count: int
    usage_limit: int
    is_premium: bool
    reset_date: str

class ChatRequest(BaseModel):
    message: str
    model: Optional[str] = "gpt-4o"
    context: Optional[str] = "You are a helpful assistant. Provide concise and accurate responses."
    enable_functions: Optional[bool] = True
    messages: Optional[List[Dict[str, str]]] = None  # Conversation history

class FunctionCall(BaseModel):
    name: str
    arguments: Dict[str, Any]
    result: Optional[str] = None
    status: Optional[str] = "pending"  # pending, executing, completed, failed

class ChatResponse(BaseModel):
    response: str
    function_calls: Optional[List[FunctionCall]] = None
    has_function_calls: bool = False

# Note: Web user models removed - authentication handled by Next.js/Supabase Auth

# Helper functions for password hashing - no longer used
# def verify_password(plain_password: str, hashed_password: str) -> bool:
#     return pwd_context.verify(plain_password, hashed_password)

# def get_password_hash(password: str) -> str:
#     return pwd_context.hash(password)

# JWT token functions
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    logger.info(f"Creating access token for user: {data.get('sub')}")
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)  # 7 day expiration
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
    logger.info(f"Access token created successfully for user: {data.get('sub')}")
    return encoded_jwt

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=["HS256"])
        user_id: int = payload.get("sub")
        if user_id is None:
            logger.warning("Token verification failed: user_id is None")
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
        logger.info(f"Token verified successfully for user: {user_id}")
        return user_id
    except jwt.PyJWTError as e:
        logger.error(f"JWT verification failed: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

# Helper functions using Supabase auth.users (web users handled by Next.js)
# Note: Web user authentication is now handled by Next.js/Supabase Auth
# These functions are kept for backwards compatibility but should use the auth system

# Helper functions for device-based users using Supabase
def get_user_by_device_id(device_id: str) -> Optional[Dict]:
    try:
        response = supabase.table('users').select('*').eq('device_id', device_id).execute()
        if response.data and len(response.data) > 0:
            user = response.data[0]
            return {
                "id": user["id"],
                "device_id": user["device_id"],
                "email": None,  # Email is in auth.users, not public.users
                "subscription_tier": user["subscription_tier"],
                "transcriptions_used": user["transcriptions_used"],
                "created_at": user["created_at"],
                "last_reset": user["last_reset"]
            }
        return None
    except Exception as e:
        logger.error(f"Error getting user by device_id {device_id}: {str(e)}")
        return None

def create_user(device_id: str, email: Optional[str] = None) -> Dict:
    logger.info(f"Creating new user for device ID: {device_id}")
    try:
        # Use the Supabase function to get or create user by device_id
        response = supabase.rpc('get_or_create_user_by_device_id', {'device_id_param': device_id}).execute()
        user_uuid = response.data
        
        # Get the created user details
        user_response = supabase.table('users').select('*').eq('id', user_uuid).execute()
        if user_response.data and len(user_response.data) > 0:
            user = user_response.data[0]
            logger.info(f"User created/retrieved successfully - Device ID: {device_id}, User UUID: {user_uuid}")
            return {
                "id": user["id"],
                "device_id": user["device_id"],
                "email": email,
                "subscription_tier": user["subscription_tier"],
                "transcriptions_used": user["transcriptions_used"]
            }
        else:
            raise Exception("Failed to retrieve created user")
    except Exception as e:
        logger.error(f"Error creating user for device_id {device_id}: {str(e)}")
        raise Exception(f"Failed to create user: {str(e)}")

def increment_usage(device_id: str):
    logger.info(f"Incrementing usage for device ID: {device_id}")
    try:
        # Use the Supabase function to increment transcriptions
        response = supabase.rpc('increment_transcriptions', {'device_id_param': device_id}).execute()
        new_count = response.data
        logger.info(f"Usage incremented for device ID: {device_id}, new count: {new_count}")
        return new_count
    except Exception as e:
        logger.error(f"Error incrementing usage for device_id {device_id}: {str(e)}")
        return 0

def check_daily_reset():
    # Daily reset is now handled by the database schema and triggers
    logger.info("Daily reset is handled automatically by database functions")
    pass

# Function calling definitions and implementations
AVAILABLE_FUNCTIONS = {
    "get_current_weather": {
        "name": "get_current_weather",
        "description": "Get the current weather in a given location",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                },
                "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "The unit of temperature"
                }
            },
            "required": ["location"]
        }
    },
    "search_web": {
        "name": "search_web",
        "description": "Search the web for current information",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "The search query"
                },
                "num_results": {
                    "type": "integer",
                    "description": "Number of results to return (default 3)",
                    "default": 3
                }
            },
            "required": ["query"]
        }
    },
    "get_current_time": {
        "name": "get_current_time",
        "description": "Get the current date and time",
        "parameters": {
            "type": "object",
            "properties": {
                "timezone": {
                    "type": "string",
                    "description": "Timezone (e.g., 'UTC', 'America/New_York')",
                    "default": "UTC"
                }
            },
            "required": []
        }
    },
    "calculate": {
        "name": "calculate",
        "description": "Perform mathematical calculations",
        "parameters": {
            "type": "object",
            "properties": {
                "expression": {
                    "type": "string",
                    "description": "Mathematical expression to evaluate (e.g., '2 + 2', 'sqrt(16)')"
                }
            },
            "required": ["expression"]
        }
    },
    "call_phone_number": {
        "name": "call_phone_number",
        "description": "Make a phone call to a specified phone number",
        "parameters": {
            "type": "object",
            "properties": {
                "phone_number": {
                    "type": "string",
                    "description": "The phone number to call (e.g., '+1-555-123-4567', '(555) 123-4567')"
                },
                "contact_name": {
                    "type": "string",
                    "description": "Optional name of the contact being called"
                }
            },
            "required": ["phone_number"]
        }
    }
}

def execute_function(function_name: str, arguments: Dict[str, Any]) -> str:
    """Execute a function call and return the result"""
    logger.info(f"Executing function: {function_name} with arguments: {arguments}")
    
    try:
        if function_name == "get_current_weather":
            return get_current_weather(arguments.get("location"), arguments.get("unit", "celsius"))
        elif function_name == "search_web":
            return search_web(arguments.get("query"), arguments.get("num_results", 3))
        elif function_name == "get_current_time":
            return get_current_time(arguments.get("timezone", "UTC"))
        elif function_name == "calculate":
            return calculate(arguments.get("expression"))
        elif function_name == "call_phone_number":
            return call_phone_number(arguments.get("phone_number"), arguments.get("contact_name"))
        else:
            return f"Unknown function: {function_name}"
    except Exception as e:
        logger.error(f"Function execution failed: {str(e)}")
        return f"Error executing {function_name}: {str(e)}"

def get_current_weather(location: str, unit: str = "celsius") -> str:
    """Get current weather for a location"""
    # This is a mock implementation. In production, use a real weather API
    # like OpenWeatherMap, WeatherAPI, etc.
    
    # Mock weather data
    weather_data = {
        "location": location,
        "temperature": 22 if unit == "celsius" else 72,
        "unit": "°C" if unit == "celsius" else "°F",
        "condition": "Partly cloudy",
        "humidity": "65%",
        "wind": "10 km/h"
    }
    
    return f"Current weather in {location}: {weather_data['temperature']}{weather_data['unit']}, {weather_data['condition']}, Humidity: {weather_data['humidity']}, Wind: {weather_data['wind']}"

def search_web(query: str, num_results: int = 3) -> str:
    """Search the web for information"""
    # This is a mock implementation. In production, use a real search API
    # like Google Custom Search, Bing Search API, or DuckDuckGo API
    
    mock_results = [
        f"Search result 1 for '{query}': Recent information about {query}",
        f"Search result 2 for '{query}': Latest news and updates on {query}",
        f"Search result 3 for '{query}': Comprehensive guide to {query}"
    ]
    
    results = mock_results[:num_results]
    return f"Web search results for '{query}':\n" + "\n".join(f"{i+1}. {result}" for i, result in enumerate(results))

def get_current_time(timezone: str = "UTC") -> str:
    """Get current date and time"""
    from datetime import datetime
    import pytz
    
    try:
        if timezone == "UTC":
            tz = pytz.UTC
        else:
            tz = pytz.timezone(timezone)
        
        current_time = datetime.now(tz)
        return f"Current time in {timezone}: {current_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    except Exception as e:
        return f"Error getting time for timezone {timezone}: {str(e)}"

def calculate(expression: str) -> str:
    """Safely evaluate mathematical expressions"""
    import ast
    import operator
    
    # Supported operations
    ops = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.Mult: operator.mul,
        ast.Div: operator.truediv,
        ast.Pow: operator.pow,
        ast.USub: operator.neg,
    }
    
    def eval_expr(node):
        if isinstance(node, ast.Constant):  # Python 3.8+
            return node.value
        elif isinstance(node, ast.Num):  # Python < 3.8
            return node.n
        elif isinstance(node, ast.BinOp):
            return ops[type(node.op)](eval_expr(node.left), eval_expr(node.right))
        elif isinstance(node, ast.UnaryOp):
            return ops[type(node.op)](eval_expr(node.operand))
        else:
            raise TypeError(f"Unsupported operation: {type(node)}")
    
    try:
        # Parse the expression
        tree = ast.parse(expression, mode='eval')
        result = eval_expr(tree.body)
        return f"{expression} = {result}"
    except Exception as e:
        return f"Error calculating '{expression}': {str(e)}"

def call_phone_number(phone_number: str, contact_name: str = None) -> str:
    """Make a phone call using macOS system functionality"""
    import subprocess
    import re
    
    try:
        # Clean the phone number - remove all non-digit characters except + at the beginning
        cleaned_number = re.sub(r'[^\d+]', '', phone_number)
        
        # Handle different phone number formats
        if not cleaned_number.startswith('+'):
            if cleaned_number.startswith('1') and len(cleaned_number) == 11:
                # US number starting with 1
                cleaned_number = '+' + cleaned_number
            elif len(cleaned_number) == 10:
                # 10-digit US number
                cleaned_number = '+1' + cleaned_number
            else:
                # Assume it's a valid number, just add + if it looks international
                if len(cleaned_number) > 10:
                    cleaned_number = '+' + cleaned_number
        
        # More lenient validation - allow various international formats
        if len(cleaned_number) < 5 or len(cleaned_number) > 16:
            return f"❌ Invalid phone number format: {phone_number} (too short or too long)"
        
        # Format for display
        display_name = f" ({contact_name})" if contact_name else ""
        
        # Try multiple approaches to initiate the call
        tel_url = f"tel:{cleaned_number}"
        
        logger.info(f"Attempting to call {cleaned_number} using tel: URL scheme")
        
        # First try: Use macOS 'open' command with tel: scheme
        result = subprocess.run(['open', tel_url], capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0:
            logger.info(f"Phone call initiated to {cleaned_number}{display_name}")
            return f"📞 Calling {phone_number}{display_name}... Call initiated successfully! FaceTime or your default phone app should open."
        else:
            logger.warning(f"First attempt failed: {result.stderr}")
            
            # Second try: Use AppleScript to open FaceTime directly
            applescript = f'''
            tell application "FaceTime"
                activate
                open location "{tel_url}"
            end tell
            '''
            
            result2 = subprocess.run(['osascript', '-e', applescript], capture_output=True, text=True, timeout=5)
            
            if result2.returncode == 0:
                logger.info(f"Phone call initiated via AppleScript to {cleaned_number}{display_name}")
                return f"📞 Calling {phone_number}{display_name}... FaceTime opened successfully!"
            else:
                logger.warning(f"AppleScript attempt failed: {result2.stderr}")
                
                # Third try: Just open FaceTime app
                result3 = subprocess.run(['open', '-a', 'FaceTime'], capture_output=True, text=True, timeout=5)
                
                if result3.returncode == 0:
                    logger.info(f"FaceTime app opened for manual calling to {cleaned_number}{display_name}")
                    return f"📞 FaceTime app opened! Please manually call {phone_number}{display_name} (Number: {cleaned_number})"
                else:
                    logger.error(f"All call attempts failed for {cleaned_number}")
                    return f"❌ Unable to initiate call to {phone_number}. Please check if FaceTime is installed and try calling {cleaned_number} manually."
            
    except subprocess.TimeoutExpired:
        logger.error(f"Timeout while trying to call {phone_number}")
        return f"❌ Timeout while trying to call {phone_number}. Please try again."
    except Exception as e:
        logger.error(f"Error making phone call to {phone_number}: {str(e)}")
        return f"❌ Error making phone call to {phone_number}: {str(e)}"

# Transcription helper functions using Supabase
def create_transcription_record(device_id: str, filename: str = None, language: str = "auto", 
                               model: str = "whisper-1", prompt: str = None, active_app: str = None) -> str:
    """Create a new transcription record and return the transcription UUID"""
    logger.info(f"Creating transcription record for device ID: {device_id}")
    if active_app:
        logger.info(f"Active app: {active_app}")
    try:
        response = supabase.rpc('create_transcription', {
            'device_id_param': device_id,
            'filename_param': filename,
            'language_param': language,
            'model_param': model,
            'prompt_param': prompt,
            'active_app_param': active_app,
            'screen_context_param': None
        }).execute()
        transcription_uuid = response.data
        logger.info(f"Transcription record created successfully: {transcription_uuid}")
        return transcription_uuid
    except Exception as e:
        logger.error(f"Error creating transcription record: {str(e)}")
        raise Exception(f"Failed to create transcription record: {str(e)}")

def update_transcription_result(transcription_id: str, result: str, status: str = "completed", 
                               processing_time: float = None, error_message: str = None) -> bool:
    """Update transcription with result"""
    logger.info(f"Updating transcription result for ID: {transcription_id}")
    try:
        response = supabase.rpc('update_transcription_result', {
            'transcription_id_param': transcription_id,
            'result_param': result,
            'status_param': status,
            'processing_time_param': processing_time,
            'error_message_param': error_message
        }).execute()
        success = response.data
        logger.info(f"Transcription result updated successfully: {transcription_id}")
        return success
    except Exception as e:
        logger.error(f"Error updating transcription result: {str(e)}")
        return False

# API Endpoints
@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "WhisperMe Backend API", "status": "🟢 Online", "emoji": "🎤"}

@app.get("/status")
async def get_server_status():
    logger.info("Server status endpoint accessed")
    return {
        "status": "🟢 Online",
        "emoji": "🎤",
        "message": "WhisperMe Backend is running",
        "features": {
            "transcription": "✅ Available",
            "chat": "✅ Available", 
            "translation": "✅ Available",
            "active_app_tracking": "✅ Available"
        }
    }

# Note: Web user authentication is now handled by Next.js/Supabase Auth
# These endpoints are removed in favor of the Next.js authentication system

# Existing endpoints for device-based authentication
@app.post("/register")
async def register_user(registration: UserRegistration):
    """Register a new device/user"""
    logger.info(f"Device registration attempt for device ID: {registration.device_id}")
    existing_user = get_user_by_device_id(registration.device_id)
    if existing_user:
        logger.info(f"Device already registered: {registration.device_id}")
        return {"message": "User already registered", "user": existing_user}
    
    user = create_user(registration.device_id, registration.email)
    logger.info(f"Device registered successfully: {registration.device_id}")
    return {"message": "User registered successfully", "user": user}

@app.get("/user/{device_id}/status")
async def get_user_status(device_id: str):
    """Get user's current status and usage"""
    logger.info(f"Status request for device ID: {device_id}")
    check_daily_reset()
    
    user = get_user_by_device_id(device_id)
    if not user:
        logger.warning(f"User not found for device ID: {device_id}")
        raise HTTPException(status_code=404, detail="User not found")
    
    is_premium = user["subscription_tier"] != "free"
    # Rate limiting disabled - all users have unlimited usage
    usage_remaining = UNLIMITED_USAGE
    
    logger.info(f"Status retrieved for device ID: {device_id} - Premium: {is_premium}, Usage: {user['transcriptions_used']} (unlimited remaining)")
    return {
        "device_id": device_id,
        "subscription_tier": user["subscription_tier"],
        "transcriptions_used": user["transcriptions_used"],
        "usage_remaining": usage_remaining,
        "is_premium": is_premium
    }

# Simplified transcription function - using standard OpenAI API for all models
async def transcribe_audio_file(file_path: str, model: str, language: str, prompt: str = None) -> str:
    """
    Transcribe audio file using standard OpenAI API
    """
    try:
        # openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) # This line is now redundant
        
        with open(file_path, "rb") as audio_file:
            # All models use whisper-1 for now - gpt-4o-transcribe support coming soon
            actual_model = "whisper-1"
            transcription_params = {
                "file": audio_file,
                "model": actual_model
            }
            
            if language and language != "auto":
                transcription_params["language"] = language
            
            if prompt:
                transcription_params["prompt"] = prompt
            
            logger.info(f"Calling OpenAI API with model: {actual_model}")
            response = openai_client.audio.transcriptions.create(**transcription_params)
            return response.text
            
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Transcription failed: {str(e)}")

@app.post("/transcribe")
async def transcribe_audio(
    device_id: str = Form(...),
    language: str = Form("auto"),
    model: str = Form("gpt-4o-transcribe"),  # Default to gpt-4o-transcribe
    prompt: str = Form(""),
    active_app: str = Form(""),
    audio_file: UploadFile = File(...)
):
    """
    Transcribe audio using either Realtime API (gpt-4o models) or standard API (whisper models)
    """
    logger.info(f"Transcription request received - Device ID: {device_id}, Language: {language}, Model: {model}")
    
    if prompt:
        logger.info(f"Custom prompt received: {prompt}")
    if active_app:
        logger.info(f"Active app: {active_app}")
    
    # Verify OpenAI API key
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        raise HTTPException(status_code=500, detail="OpenAI API key not configured")
    
    # Daily usage reset
        logger.info("Daily reset is handled automatically by database functions")
    
    # Get or create user
    user_data = get_user_by_device_id(device_id)
    if not user_data:
        user_data = create_user(device_id)
    user_id = user_data["id"]
    
    # Check rate limiting (if enabled)
    if RATE_LIMITING_ENABLED:
        current_usage = user_data.get("daily_transcriptions", 0)
        if current_usage >= FREE_TRANSCRIPTION_LIMIT:
            logger.warning(f"Rate limit exceeded for device ID: {device_id}")
            raise HTTPException(
                status_code=429,
                detail=f"Daily transcription limit ({FREE_TRANSCRIPTION_LIMIT}) exceeded. Please upgrade to premium or wait for reset."
            )
    else:
        logger.info(f"Rate limiting disabled - allowing transcription for device ID: {device_id}")
    
    # Save uploaded file temporarily
    tmp_file_path = None
    try:
        # Read file content
        file_content = await audio_file.read()
        
        # Log file details
        logger.info(f"Processing audio file - Name: {audio_file.filename}, Size: {len(file_content)} bytes, Type: {audio_file.content_type}")
        
        # Create transcription record
        transcription_id = create_transcription_record(
            device_id=device_id,
            filename=audio_file.filename,
            language=language,
            model=model,
            prompt=prompt,
            active_app=active_app
        )
        
        # Save to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_file:
            tmp_file_path = tmp_file.name
            tmp_file.write(file_content)
        
        logger.info(f"Audio file saved to temporary location: {tmp_file_path}")
        
        # Transcribe using standard OpenAI API
        logger.info(f"Starting transcription with model: {model}")
        
        # Enhanced prompt for better formatting
        if prompt:
            enhanced_prompt = f"If this appears to be an email or formal correspondence, add appropriate line breaks between paragraphs, after greetings, before signatures, and between distinct sections. Maintain natural paragraph structure for better readability. For phone numbers, use the plus country code format. {prompt}"
        else:
            enhanced_prompt = "If this appears to be an email or formal correspondence, add appropriate line breaks between paragraphs, after greetings, before signatures, and between distinct sections. Maintain natural paragraph structure for better readability. For phone numbers, use the plus country code format."
        
        if enhanced_prompt:
            logger.info(f"Enhanced prompt being sent: {enhanced_prompt}")
        
        # Call transcription function
        transcription_text = await transcribe_audio_file(tmp_file_path, model, language, enhanced_prompt)
        
        logger.info(f"Transcription completed successfully - Text length: {len(transcription_text)} characters")
        
        # Update transcription result
        update_transcription_result(transcription_id, transcription_text)
        
        # Clean up temporary file
        if tmp_file_path:
            os.unlink(tmp_file_path)
            logger.info(f"Temporary file cleaned up: {tmp_file_path}")
        
        # Increment usage
        increment_usage(device_id)
        
        logger.info(f"Transcription completed successfully for device ID: {device_id}")
        
        return JSONResponse(content={
            "text": transcription_text,
            "usage_remaining": 999999 if not RATE_LIMITING_ENABLED else max(0, FREE_TRANSCRIPTION_LIMIT - (user_data.get("daily_transcriptions", 0) + 1)),
            "is_premium": False,
            "model_used": model
        })
        
    except Exception as e:
        logger.error(f"Transcription error: {str(e)}")
        
        # Clean up temporary file if it exists
        if tmp_file_path and os.path.exists(tmp_file_path):
            os.unlink(tmp_file_path)
        
        # Try to update transcription with error
        try:
            if 'transcription_id' in locals():
                update_transcription_result(transcription_id, str(e))
        except:
            pass
        
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat", response_model=ChatResponse)
async def chat_completion(request: ChatRequest):
    """Chat completion using OpenAI GPT-4o API with function calling support"""
    logger.info(f"Chat completion request received - Message: {request.message}, Model: {request.model}, Functions enabled: {request.enable_functions}")
    
    if not OPENAI_API_KEY:
        logger.error("OpenAI API key not configured")
        raise HTTPException(status_code=500, detail="OpenAI API key not configured")
    
    try:
        # client = openai.OpenAI(api_key=OPENAI_API_KEY) # This line is now redundant
        
        # Create chat completion request with conversation history
        if request.messages and len(request.messages) > 0:
            # Use the provided conversation history (already includes system message and all previous messages)
            messages = request.messages
            logger.info(f"Using conversation history with {len(messages)} messages")
        else:
            # Fallback to simple message format
            messages = [
                {"role": "system", "content": request.context},
                {"role": "user", "content": request.message}
            ]
            logger.info("Using simple message format (no conversation history)")
        
        logger.info(f"Sending chat completion request to OpenAI with model: {request.model}")
        
        # Prepare function calling parameters
        chat_params = {
            "model": request.model,
            "messages": messages,
            "max_tokens": 1000,
            "temperature": 0.7
        }
        
        # Add function calling support if enabled
        if request.enable_functions:
            chat_params["tools"] = [
                {"type": "function", "function": func_def} 
                for func_def in AVAILABLE_FUNCTIONS.values()
            ]
            chat_params["tool_choice"] = "auto"
        
        response = openai_client.chat.completions.create(**chat_params) # Use openai_client
        
        message = response.choices[0].message
        function_calls = []
        has_function_calls = False
        
        # Handle function calls if present
        if message.tool_calls:
            has_function_calls = True
            logger.info(f"Function calls detected: {len(message.tool_calls)}")
            
            # Execute each function call
            for tool_call in message.tool_calls:
                function_name = tool_call.function.name
                try:
                    function_args = json.loads(tool_call.function.arguments)
                except json.JSONDecodeError:
                    function_args = {}
                
                logger.info(f"Executing function: {function_name} with args: {function_args}")
                
                # Execute the function
                function_result = execute_function(function_name, function_args)
                
                function_calls.append(FunctionCall(
                    name=function_name,
                    arguments=function_args,
                    result=function_result,
                    status="completed"
                ))
                
                # Add function result to conversation
                messages.append({
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [tool_call.dict()]
                })
                messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": function_result
                })
            
            # Get final response from GPT after function execution
            final_response = openai_client.chat.completions.create( # Use openai_client
                model=request.model,
                messages=messages,
                max_tokens=1000,
                temperature=0.7
            )
            
            assistant_response = final_response.choices[0].message.content
            logger.info(f"Chat completion with functions successful - Response length: {len(assistant_response)} characters")
        else:
            # No function calls, use original response
            assistant_response = message.content
            logger.info(f"Chat completion successful - Response length: {len(assistant_response)} characters")
        
        return ChatResponse(
            response=assistant_response,
            function_calls=function_calls if function_calls else None,
            has_function_calls=has_function_calls
        )
        
    except Exception as e:
        logger.error(f"Chat completion failed - Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Chat completion failed: {str(e)}")

@app.get("/functions")
async def get_available_functions():
    """Get list of available functions for the assistant"""
    logger.info("Available functions requested")
    return {
        "functions": list(AVAILABLE_FUNCTIONS.keys()),
        "function_definitions": AVAILABLE_FUNCTIONS
    }

@app.post("/upgrade/{device_id}")
async def upgrade_user(device_id: str, tier: str = "premium"):
    """Upgrade user to premium (integrate with payment system)"""
    # This is a mock endpoint. In a real implementation, verify payment here.
    logger.info(f"Upgrading user {device_id} to {tier}")
    
    try:
        # First, check if the user exists
        user_response = supabase.table('users').select('id').eq('device_id', device_id).execute()
        if not user_response.data:
            logger.warning(f"Upgrade failed: user with device_id {device_id} not found.")
            raise HTTPException(status_code=404, detail="User not found")

        # If user exists, update their subscription tier
        update_response = supabase.table('users').update({'subscription_tier': tier}).eq('device_id', device_id).execute()
        
        if not update_response.data:
             logger.error(f"Failed to upgrade user {device_id} even though they exist.")
             raise HTTPException(status_code=500, detail="Failed to update user subscription")

        logger.info(f"User {device_id} upgraded to {tier} successfully.")
        return {"message": f"User upgraded to {tier}", "device_id": device_id}
        
    except HTTPException:
        raise  # Re-raise HTTPException
    except Exception as e:
        logger.error(f"Error upgrading user {device_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to upgrade user: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    logger.info("🚀 Starting server with uvicorn on 0.0.0.0:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000) 