# Supabase Setup Guide

## Environment Variables

Create a `.env.local` file in the root of your project with the following variables:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# Supabase Service Role Key (for admin operations - keep this secret!)
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key

# Python Service API Key (for transcription processing)
PYTHON_SERVICE_API_KEY=your-secure-api-key-for-python-service
```

## How to get your Supabase credentials:

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Once your project is created, go to Settings > API
3. Copy the Project URL and paste it as `NEXT_PUBLIC_SUPABASE_URL`
4. Copy the `anon` `public` key and paste it as `NEXT_PUBLIC_SUPABASE_ANON_KEY`
5. Copy the `service_role` `secret` key and paste it as `SUPABASE_SERVICE_ROLE_KEY` ⚠️ **Keep this secret!**
6. Generate a secure API key for `PYTHON_SERVICE_API_KEY` (used by Python service to update transcription status)

## Database Setup

Run this SQL in your Supabase SQL Editor to create the required tables:

```sql
-- Transcriptions table
CREATE TABLE transcriptions (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    language TEXT DEFAULT 'en',
    status TEXT DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    result TEXT,
    error_message TEXT,
    duration REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- User profiles table (optional, for premium features)
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) UNIQUE,
    plan TEXT DEFAULT 'free',
    monthly_limit INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Connection tokens table (for deep linking to macOS app)
CREATE TABLE connection_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE transcriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE connection_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies for transcriptions
CREATE POLICY "Users can view own transcriptions" ON transcriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transcriptions" ON transcriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own transcriptions" ON transcriptions FOR UPDATE USING (auth.uid() = user_id);

-- Create policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Create policies for connection_tokens
CREATE POLICY "Users can insert own connection tokens" ON connection_tokens FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own connection tokens" ON connection_tokens FOR SELECT USING (auth.uid() = user_id);

-- Create index for faster token lookups
CREATE INDEX idx_connection_tokens_hash ON connection_tokens(token_hash);
CREATE INDEX idx_connection_tokens_expires ON connection_tokens(expires_at);

-- Auto-cleanup expired tokens (optional, runs daily)
SELECT cron.schedule(
    'cleanup_expired_connection_tokens',
    '0 2 * * *', -- Run at 2 AM daily
    'DELETE FROM connection_tokens WHERE expires_at < NOW() - INTERVAL ''1 day'';'
);
```

## Storage Setup

1. Go to Storage in your Supabase dashboard
2. Create a new bucket called `audio-files`
3. Make it private (not public)
4. Set up bucket policies:

```sql
-- Allow authenticated users to upload files
CREATE POLICY "Users can upload audio files" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'audio-files' AND auth.role() = 'authenticated'
);

-- Allow users to view their own files
CREATE POLICY "Users can view own audio files" ON storage.objects FOR SELECT USING (
    bucket_id = 'audio-files' AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow deletion of own files
CREATE POLICY "Users can delete own audio files" ON storage.objects FOR DELETE USING (
    bucket_id = 'audio-files' AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## Authentication Setup

The app is now configured to use Supabase authentication with:
- Email/password sign up and sign in
- Protected dashboard route
- Automatic session management
- Sign out functionality
- **API endpoints for macOS app integration**
- **Deep linking to macOS app with "Connect App" button**

## API Endpoints Available

For your macOS app integration:

- `POST /api/auth/login` - Authenticate users
- `GET /api/auth/session` - Verify sessions
- `POST /api/auth/connect-token` - Generate deep link connection token
- `GET /api/auth/connect-token` - Verify connection token (for macOS app)
- `POST /api/transcribe/upload` - Upload audio files
- `GET /api/transcribe/status/{id}` - Check transcription status
- `PUT /api/transcribe/status/{id}` - Update status (for Python service)
- `GET /api/transcribe/list` - List user transcriptions
- `GET /api/user/profile` - Get user profile and stats

## Deep Linking Setup

The webapp now includes a "Connect App" button that:
1. Generates a secure temporary connection token (expires in 5 minutes)
2. Creates a deep link: `whisperme://connect?token=...&email=...`
3. Opens the macOS app automatically
4. Allows the macOS app to authenticate without requiring credentials

## Troubleshooting

### "Failed to generate connection token" Error

This error usually means:
1. **Missing environment variables** - Make sure all environment variables are set in `.env.local`
2. **Database table missing** - Run the SQL commands above to create the `connection_tokens` table
3. **RLS policies** - Ensure Row Level Security policies are set up correctly

Check your browser's Network tab for the actual error response details.

### Testing Connection Token Generation

Test with curl:
```bash
# First login to get an access token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your-email@example.com","password":"your-password"}'

# Then use the access token to generate a connection token
curl -X POST http://localhost:3000/api/auth/connect-token \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json"
```

## Next Steps

1. Set up your Supabase project and add the environment variables
2. Run the SQL commands to create tables and policies
3. Set up the storage bucket
4. Run `npm run dev` to start the development server
5. Visit `http://localhost:3000/auth/register` to create an account
6. Visit `http://localhost:3000/auth/login` to sign in
7. Click "Connect App" in the dashboard to test deep linking
8. Check the `MACOS_INTEGRATION_GUIDE.md` for connecting your macOS app

The authentication flow, API endpoints, and deep linking are fully functional with Supabase! 