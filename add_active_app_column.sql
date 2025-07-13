-- Add active_app column to existing transcriptions table
ALTER TABLE public.transcriptions 
ADD COLUMN IF NOT EXISTS active_app VARCHAR(255);

-- Create index for better performance on active_app queries
CREATE INDEX IF NOT EXISTS idx_transcriptions_active_app ON public.transcriptions(active_app);

-- Update the create_transcription function to accept active_app parameter
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

-- Add some sample queries to test the new functionality
-- Query to see transcriptions by app
-- SELECT active_app, COUNT(*) as count, MAX(created_at) as last_used 
-- FROM public.transcriptions 
-- WHERE active_app IS NOT NULL 
-- GROUP BY active_app 
-- ORDER BY count DESC;

-- Query to see recent transcriptions with app context
-- SELECT created_at, active_app, language, model, 
--        LEFT(result, 100) as preview
-- FROM public.transcriptions 
-- WHERE active_app IS NOT NULL 
-- ORDER BY created_at DESC 
-- LIMIT 20; 