# 🗄️ Supabase Setup Guide for WhisperMe

## Overview
This guide will help you set up Supabase as the database backend for your WhisperMe application, replacing the local SQLite database with a powerful cloud PostgreSQL database.

## 🔧 Prerequisites
- Supabase account at [supabase.com](https://supabase.com)
- Your Supabase project credentials (already provided)

## 📋 Step 1: Access Your Supabase Dashboard

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Navigate to your project: **esbsipsmfauncatuskwy**
3. Go to the **SQL Editor** in the left sidebar

## 🏗️ Step 2: Create Database Schema

1. In the SQL Editor, copy and paste the entire contents of `supabase_schema.sql`
2. Click **Run** to execute the SQL commands
3. This will create:
   - `users` table (for macOS app device-based authentication)
   - `web_users` table (for Next.js web app email/password authentication)
   - Necessary indexes for performance
   - Helper functions for the backend
   - Row Level Security policies

## 🔑 Step 3: Verify Environment Variables

### Python Backend (`.env` in `whisperme-python/`)
```env
SUPABASE_URL=https://esbsipsmfauncatuskwy.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzYnNpcHNtZmF1bmNhdHVza3d5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MTQ5MzE5NiwiZXhwIjoyMDY3MDY5MTk2fQ.NyROISextWQP88Wt4TlUAasLaTmRqruhO2JUUp_H9-k
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzYnNpcHNtZmF1bmNhdHVza3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTMxOTYsImV4cCI6MjA2NzA2OTE5Nn0.kG6dlLMfQH6I03Y_gmyFibP_OFT29lX3pA0GVevfsGU
SUPABASE_DATABASE_PASSWORD=tagko1-dEtxoj-mukhyg
```

### Next.js App (`.env.local` in `whisperme-nextapp/`)
```env
NEXT_PUBLIC_SUPABASE_URL=https://esbsipsmfauncatuskwy.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzYnNpcHNtZmF1bmNhdHVza3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0OTMxOTYsImV4cCI6MjA2NzA2OTE5Nn0.kG6dlLMfQH6I03Y_gmyFibP_OFT29lX3pA0GVevfsGU
```

## 🚀 Step 4: Test the Setup

### Start the Backend
```bash
cd whisperme-python
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Start the Next.js App
```bash
cd whisperme-nextapp
npm run dev
```

### Test the Endpoints
1. **Backend Health Check**: http://localhost:8000
2. **Next.js App**: http://localhost:3000

## 🧪 Step 5: Test User Registration

### Web App Registration
1. Go to http://localhost:3000/auth/register
2. Create a test account
3. Login at http://localhost:3000/auth/login
4. Check the dashboard at http://localhost:3000/dashboard

### macOS App (Device-based)
The macOS app will automatically register devices when they make their first transcription request.

## 📊 Step 6: Verify Data in Supabase

1. Go to **Table Editor** in your Supabase dashboard
2. Check the `web_users` table for web app registrations
3. Check the `users` table for device registrations
4. Monitor the **Logs** section for any errors

## 🔒 Security Notes

- The **service role key** is used by the backend for full database access
- The **anon key** is used by the frontend for limited access
- Row Level Security (RLS) is enabled on both tables
- All passwords are hashed using bcrypt

## 🎯 Database Schema Overview

### `users` Table (Device Authentication)
- `id`: Primary key
- `device_id`: Unique device identifier from macOS app
- `email`: Optional email (can be null)
- `subscription_tier`: 'free' or 'premium'
- `transcriptions_used`: Daily usage counter
- `last_reset`: Last daily reset date

### `web_users` Table (Email Authentication)
- `id`: Primary key  
- `name`: User's full name
- `email`: Unique email address
- `password_hash`: Bcrypt-hashed password
- `subscription_tier`: 'free' or 'premium'
- `transcriptions_used`: Daily usage counter
- `last_reset`: Last daily reset date

## 🔧 Troubleshooting

### Backend Won't Start
- Check that all environment variables are set correctly
- Verify the Supabase URL and keys are valid
- Ensure the database schema has been created

### Authentication Fails
- Verify the JWT secret keys match between backend and frontend
- Check that the Supabase service role key has the correct permissions
- Look at the browser network tab for error details

### Database Connection Issues
- Confirm the Supabase URL is accessible
- Check the service role key has sufficient permissions
- Review the Supabase dashboard logs for connection errors

## 🎉 You're Ready!

Once everything is set up:
- ✅ Your macOS app will store user data in Supabase
- ✅ The web app allows users to register and manage accounts
- ✅ Usage tracking works across both platforms
- ✅ Premium upgrades are supported
- ✅ All data is securely stored in the cloud

Your WhisperMe application now has a production-ready database backend with Supabase! 🚀 