-- WhisperMe Supabase Database Schema
-- Run this in your Supabase SQL Editor to create the required tables

-- Create public users table that references auth.users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) UNIQUE,
    full_name VARCHAR(255),
    subscription_tier VARCHAR(50) DEFAULT 'free',
    transcriptions_used INTEGER DEFAULT 0,
    monthly_limit INTEGER DEFAULT 10,
    last_reset DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create transcriptions table
CREATE TABLE IF NOT EXISTS public.transcriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    device_id VARCHAR(255),
    filename VARCHAR(255),
    file_path TEXT,
    file_size BIGINT,
    duration REAL,
    language VARCHAR(10) DEFAULT 'auto',
    model VARCHAR(50) DEFAULT 'gpt-4o-transcribe',
    prompt TEXT,
    active_app VARCHAR(255),
    status VARCHAR(20) DEFAULT 'processing',
    progress INTEGER DEFAULT 0,
    result TEXT,
    error_message TEXT,
    processing_time REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_device_id ON public.users(device_id);
CREATE INDEX IF NOT EXISTS idx_users_subscription_tier ON public.users(subscription_tier);
CREATE INDEX IF NOT EXISTS idx_transcriptions_user_id ON public.transcriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_transcriptions_device_id ON public.transcriptions(device_id);
CREATE INDEX IF NOT EXISTS idx_transcriptions_status ON public.transcriptions(status);
CREATE INDEX IF NOT EXISTS idx_transcriptions_created_at ON public.transcriptions(created_at);

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transcriptions_updated_at BEFORE UPDATE ON public.transcriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to handle automatic user creation when auth.users is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.created_at,
        NEW.updated_at
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to automatically create public.users when auth.users is created
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create RPC functions for the backend
CREATE OR REPLACE FUNCTION public.get_or_create_user_by_device_id(device_id_param TEXT)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Try to find existing user by device_id
    SELECT id INTO user_uuid FROM public.users WHERE device_id = device_id_param;
    
    -- If not found, create a new auth user and public user
    IF user_uuid IS NULL THEN
        -- Create anonymous auth user (for device-based authentication)
        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            recovery_sent_at,
            last_sign_in_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            device_id_param || '@device.whisperme.local',
            crypt('device-auth', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            '{"provider":"device","providers":["device"]}'::jsonb,
            ('{"device_id":"' || device_id_param || '"}')::jsonb,
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        ) RETURNING id INTO user_uuid;
        
        -- Update the public.users record with device_id
        UPDATE public.users SET device_id = device_id_param WHERE id = user_uuid;
    END IF;
    
    RETURN user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to increment transcriptions (used by the backend)
CREATE OR REPLACE FUNCTION public.increment_transcriptions(device_id_param TEXT)
RETURNS INTEGER AS $$
DECLARE
    new_count INTEGER;
    user_uuid UUID;
BEGIN
    -- Get or create user
    SELECT public.get_or_create_user_by_device_id(device_id_param) INTO user_uuid;
    
    -- Increment transcriptions count
    UPDATE public.users 
    SET transcriptions_used = transcriptions_used + 1
    WHERE id = user_uuid
    RETURNING transcriptions_used INTO new_count;
    
    RETURN COALESCE(new_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a new transcription record
CREATE OR REPLACE FUNCTION public.create_transcription(
    device_id_param TEXT,
    filename_param VARCHAR DEFAULT NULL,
    language_param VARCHAR DEFAULT 'auto',
    model_param VARCHAR DEFAULT 'gpt-4o-transcribe',
    prompt_param TEXT DEFAULT NULL,
    active_app_param VARCHAR DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    user_uuid UUID;
    transcription_uuid UUID;
BEGIN
    -- Get or create user
    SELECT public.get_or_create_user_by_device_id(device_id_param) INTO user_uuid;
    
    -- Create transcription record
    INSERT INTO public.transcriptions (
        user_id,
        device_id,
        filename,
        language,
        model,
        prompt,
        active_app,
        status
    ) VALUES (
        user_uuid,
        device_id_param,
        filename_param,
        language_param,
        model_param,
        prompt_param,
        active_app_param,
        'processing'
    ) RETURNING id INTO transcription_uuid;
    
    RETURN transcription_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update transcription result
CREATE OR REPLACE FUNCTION public.update_transcription_result(
    transcription_id_param UUID,
    result_param TEXT,
    status_param VARCHAR DEFAULT 'completed',
    processing_time_param REAL DEFAULT NULL,
    error_message_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.transcriptions 
    SET 
        result = result_param,
        status = status_param,
        processing_time = processing_time_param,
        error_message = error_message_param,
        completed_at = CASE WHEN status_param = 'completed' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE id = transcription_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Row Level Security (RLS) for security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transcriptions ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own data" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Allow service role to access all user data (for backend functions)
CREATE POLICY "Service role can access all users" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

-- Create policies for transcriptions table
CREATE POLICY "Users can view their own transcriptions" ON public.transcriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transcriptions" ON public.transcriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own transcriptions" ON public.transcriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow service role to access all transcriptions (for backend functions)
CREATE POLICY "Service role can access all transcriptions" ON public.transcriptions
    FOR ALL USING (auth.role() = 'service_role');

-- Connection tokens table (for deep linking to macOS app)
CREATE TABLE IF NOT EXISTS connection_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security for connection_tokens
ALTER TABLE connection_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies for connection_tokens
CREATE POLICY "Users can insert own connection tokens" ON connection_tokens FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own connection tokens" ON connection_tokens FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow service role to view all connection tokens" ON connection_tokens FOR SELECT USING (auth.role() = 'service_role');

-- Create index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_connection_tokens_hash ON connection_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_connection_tokens_expires ON connection_tokens(expires_at);

-- Insert some test data (optional)
-- Note: Users will be automatically created via auth.users and triggers
-- You can create test users via the Supabase dashboard or API 