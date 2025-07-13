# WhisperMe Python Backend

A FastAPI-based backend for WhisperMe that provides API key management, usage tracking, and SaaS functionality for audio transcription.

## Features

🔐 **API Key Management**: Hide your OpenAI API key from client apps  
📊 **Usage Tracking**: Track and limit free user transcriptions  
💰 **SaaS Ready**: Premium subscription support  
🗄️ **Database**: SQLite database for user management  
🌐 **CORS Enabled**: Ready for macOS app integration  
⚡ **Fast**: Built with FastAPI for high performance

## Quick Start

### 1. Navigate to Backend Directory

```bash
cd whisperme-python
```

### 2. Set Up Environment Variables

Create a `.env` file in the `whisperme-python` directory:

```bash
# Create .env file
cat > .env << 'EOF'
OPENAI_API_KEY=your_actual_openai_api_key_here
SECRET_KEY=your_secure_secret_key_change_this
HOST=0.0.0.0
PORT=8000
FREE_TRANSCRIPTION_LIMIT=10
EOF
```

**⚠️ Important**: Replace `your_actual_openai_api_key_here` with your real OpenAI API key!

### 3. Install and Run

```bash
# Install dependencies and run with uv
uv run main.py
```

The server will start at `http://localhost:8000`

## API Endpoints

### 📋 Health Check
```http
GET /
```
Returns API status and version.

### 👤 User Registration
```http
POST /register
```
```json
{
    "device_id": "unique_device_identifier",
    "email": "user@example.com"
}
```

### 📊 User Status
```http
GET /user/{device_id}/status
```
Returns user's subscription tier, usage count, and remaining transcriptions.

### 🎤 Transcribe Audio
```http
POST /transcribe
```
**Form Data:**
- `device_id`: Unique device identifier
- `language`: Language code (or "auto" for auto-detect) 
- `model`: OpenAI model ("gpt-4o-transcribe" or "gpt-4o-mini-transcribe")
- `prompt`: Optional prompt for better transcription
- `audio_file`: WAV audio file

**Response:**
```json
{
    "text": "Transcribed text here",
    "usage_remaining": 9,
    "is_premium": false
}
```

### 💎 Upgrade User
```http
POST /upgrade/{device_id}?tier=premium
```
Upgrade user to premium tier (integrate with payment system).

## Usage Limits

- **Free Users**: 10 transcriptions per day (resets daily)
- **Premium Users**: Unlimited transcriptions

## Integration with Swift App

Update your Swift app to use this backend instead of direct OpenAI calls:

```swift
// Replace direct OpenAI API calls with:
private let backendURL = "http://localhost:8000"  // or your deployed URL

func transcribeWithBackend(audioData: Data, deviceId: String) async {
    // POST to /transcribe endpoint
    // Your API key stays hidden on the server!
}
```

## Database

The backend automatically creates a SQLite database (`whisperme.db`) with user management:

- Device-based authentication (no passwords needed)
- Usage tracking and limits
- Subscription tier management
- Daily usage reset for free users

## Development

### Install Dependencies
```bash
uv add fastapi uvicorn python-multipart openai python-dotenv
```

### Run in Development Mode
```bash
uv run uvicorn main:app --reload --port 8000
```

### API Documentation
Once running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Deployment

### 1. Set Environment Variables
```bash
export OPENAI_API_KEY="your_real_api_key"
export SECRET_KEY="your_secure_secret"
```

### 2. Run Production Server
```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8000
```

### 3. Update Swift App
Update your macOS app to point to your deployed backend URL.

## Security Features

- ✅ API key hidden from client applications
- ✅ Device-based authentication (no passwords to manage)
- ✅ Usage rate limiting for free users
- ✅ CORS properly configured
- ✅ SQL injection protection with parameterized queries

## File Structure

```
whisperme-python/
├── main.py              # FastAPI application
├── config.py            # Configuration management
├── pyproject.toml       # Python dependencies
├── README.md           # This file
├── .env                # Environment variables (create this)
└── whisperme.db        # SQLite database (auto-created)
```

## Troubleshooting

### Common Issues

**"OpenAI API key not configured"**
- Make sure your `.env` file contains a valid `OPENAI_API_KEY`
- Or set it in your shell: `export OPENAI_API_KEY="your_key"`

**CORS errors from Swift app**
- The backend allows all origins by default (`allow_origins=["*"]`)
- For production, update CORS settings in `main.py`

**Database errors**
- The SQLite database is created automatically
- Check file permissions in the backend directory

### Logs
The FastAPI server logs all requests and errors to the console for debugging.

## Next Steps

1. **Deploy to Cloud**: Deploy to AWS, Google Cloud, or DigitalOcean
2. **Add Payment**: Integrate Stripe for premium subscriptions
3. **Add Analytics**: Track usage patterns and popular features
4. **Add Caching**: Redis cache for better performance
5. **Add Monitoring**: Health checks and alerting

Happy transcribing! 🎤✨ 