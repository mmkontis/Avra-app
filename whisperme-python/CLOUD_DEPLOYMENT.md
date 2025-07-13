# 🚀 WhisperMe Backend - Cloud Deployment Guide

This guide helps you deploy the WhisperMe Python backend to cloud platforms like Sevalla, Railway, Heroku, and others.

## 📋 Quick Start

1. **Run the deployment helper:**
   ```bash
   cd whisperme-python
   python deploy.py
   ```

2. **Configure environment variables (see below)**

3. **Deploy to your cloud platform**

## 🌐 Sevalla Deployment

### Step 1: Prepare Your Files
```bash
# Navigate to the backend directory
cd whisperme-python

# Run the deployment helper
python deploy.py

# This will check all files and create .env template
```

### Step 2: Set Environment Variables in Sevalla
In your Sevalla dashboard, set these environment variables:

```bash
# Required
OPENAI_API_KEY=sk-...your_actual_openai_key
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...your_service_role_key

# Optional but recommended
SECRET_KEY=your-super-secure-jwt-secret-key-change-this
PORT=8000
HOST=0.0.0.0
ENVIRONMENT=production
FREE_TRANSCRIPTION_LIMIT=10
WORKERS=1
```

### Step 3: Upload and Install
```bash
# Upload the whisperme-python/ folder to Sevalla

# SSH into your Sevalla instance and run:
cd whisperme-python
pip install -r requirements.txt

# Start the server
python start_server.py
```

### Step 4: Test Deployment
```bash
# Test health endpoint
curl https://your-sevalla-domain.com/status

# Should return:
{
  "status": "healthy",
  "message": "WhisperMe Backend API v1.0.0",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## 🚄 Railway Deployment

### Method 1: Direct Upload
1. Create new Railway project
2. Upload `whisperme-python/` folder
3. Set environment variables in Railway dashboard
4. Railway will auto-detect and run `start_server.py`

### Method 2: GitHub Integration
1. Push `whisperme-python/` to a GitHub repo
2. Connect Railway to the GitHub repo
3. Set environment variables
4. Deploy

## 🟣 Heroku Deployment

Create these additional files in `whisperme-python/`:

### Procfile
```bash
web: python start_server.py
```

### runtime.txt
```
python-3.11.0
```

Deploy:
```bash
# Login to Heroku
heroku login

# Create app
heroku create your-whisperme-backend

# Set environment variables
heroku config:set OPENAI_API_KEY=your_key
heroku config:set SUPABASE_URL=your_url
heroku config:set SUPABASE_SERVICE_ROLE_KEY=your_key

# Deploy
git add .
git commit -m "Deploy backend"
git push heroku main
```

## 🔧 Environment Variables Reference

### Required Variables
- `OPENAI_API_KEY`: Your OpenAI API key
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase service role key

### Optional Variables
- `SECRET_KEY`: JWT secret key (generates random if not set)
- `PORT`: Server port (default: 8000)
- `HOST`: Server host (default: 0.0.0.0)
- `ENVIRONMENT`: production/development (default: development)
- `FREE_TRANSCRIPTION_LIMIT`: Free user limit (default: 10)
- `WORKERS`: Number of worker processes (default: 1)
- `CORS_ORIGINS`: Allowed CORS origins (default: *)

## 📱 Update Your Apps

After deploying, update your client applications:

### Next.js App
Update environment variables:
```bash
# In whisperme-nextapp/.env.local
NEXT_PUBLIC_BACKEND_URL=https://your-sevalla-domain.com
```

### macOS App
Update the base URL in `whisperme/Constants.swift`:
```swift
static let baseURL = "https://your-sevalla-domain.com"
```

Also update `whisperme/Services/APIService.swift`:
```swift
private let baseURL = "https://your-sevalla-domain.com"
```

And `whisperme/whispermeApp.swift` (multiple locations):
```swift
let url = URL(string: "https://your-sevalla-domain.com/transcribe")!
```

## 🔍 Testing Your Deployment

### Health Check
```bash
curl https://your-domain.com/status
```

### API Documentation
Visit: `https://your-domain.com/docs`

### Test Transcription
```bash
curl -X POST "https://your-domain.com/register" \
  -H "Content-Type: application/json" \
  -d '{"device_id": "test-device-123"}'

# Response should show user registration
```

## 🚨 Troubleshooting

### Common Issues

**1. "Missing environment variables"**
- Check that all required env vars are set in your cloud platform
- Verify the variable names match exactly (case-sensitive)

**2. "Database connection failed"**
- Verify SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
- Check Supabase project is active and accessible

**3. "OpenAI API errors"**
- Verify OPENAI_API_KEY is valid and has sufficient credits
- Check OpenAI API key permissions

**4. "CORS errors from frontend"**
- Update CORS_ORIGINS if needed
- Verify frontend is using correct backend URL

**5. "Port binding errors"**
- Ensure PORT environment variable matches platform requirements
- Railway: Usually auto-assigned
- Heroku: Uses $PORT automatically
- Sevalla: Usually 8000 or specified port

### Debug Mode
Add these environment variables for debugging:
```bash
ENVIRONMENT=development
LOG_LEVEL=debug
```

## 📊 Performance Tips

### Production Optimization
```bash
# Use multiple workers for better performance
WORKERS=2  # or more based on your plan

# Enable production mode
ENVIRONMENT=production

# Optimize CORS for specific domains (more secure)
CORS_ORIGINS=https://your-frontend.com,https://your-app.com
```

### Monitoring
- Monitor `/status` endpoint for health checks
- Check logs for API usage and errors
- Monitor Supabase usage for database performance

## 🔄 Updates and Maintenance

### Updating the Backend
1. Update code locally
2. Test with `python start_server.py`
3. Upload to cloud platform
4. Restart service

### Database Migrations
- Database schema is managed by Supabase
- Use Supabase dashboard for schema changes
- No manual migrations needed for SQLite → Supabase

## 🆘 Support

If you encounter issues:
1. Check the logs in your cloud platform dashboard
2. Verify all environment variables are set correctly
3. Test the health endpoint: `/status`
4. Check Supabase connection and API keys
5. Ensure your domain/URL is accessible

Your WhisperMe backend is now ready for production! 🎉 