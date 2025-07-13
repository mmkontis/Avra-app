import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'

// Helper function to verify authentication
async function verifyAuth(request: NextRequest) {
  const authHeader = request.headers.get('Authorization')
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null
  }

  const token = authHeader.substring(7)
  const { data: { user }, error } = await supabase.auth.getUser(token)

  if (error || !user) {
    return null
  }

  return user
}

export async function GET(request: NextRequest) {
  try {
    const user = await verifyAuth(request)
    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // Get user profile data
    const { data: profile, error: profileError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.id)
      .single()

    // Get transcription statistics
    const { data: stats, error: statsError } = await supabase
      .from('transcriptions')
      .select('status, created_at, duration')
      .eq('user_id', user.id)

    if (profileError && profileError.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('Profile error:', profileError)
      return NextResponse.json(
        { error: 'Failed to fetch user profile' },
        { status: 500 }
      )
    }

    if (statsError) {
      console.error('Stats error:', statsError)
      return NextResponse.json(
        { error: 'Failed to fetch user statistics' },
        { status: 500 }
      )
    }

    // Calculate statistics
    const totalTranscriptions = stats?.length || 0
    const completedTranscriptions = stats?.filter(s => s.status === 'completed').length || 0
    const failedTranscriptions = stats?.filter(s => s.status === 'failed').length || 0
    const pendingTranscriptions = stats?.filter(s => s.status === 'pending' || s.status === 'processing').length || 0
    
    // Calculate total duration (in seconds)
    const totalDuration = stats?.reduce((acc, s) => acc + (s.duration || 0), 0) || 0
    
    // Calculate usage for current month
    const currentMonth = new Date().getMonth()
    const currentYear = new Date().getFullYear()
    const monthlyTranscriptions = stats?.filter(s => {
      const date = new Date(s.created_at)
      return date.getMonth() === currentMonth && date.getFullYear() === currentYear
    }).length || 0

    return NextResponse.json({
      user: {
        id: user.id,
        email: user.email,
        created_at: user.created_at
      },
      profile: profile || {
        plan: 'free',
        monthly_limit: 10,
        created_at: user.created_at
      },
      statistics: {
        total_transcriptions: totalTranscriptions,
        completed_transcriptions: completedTranscriptions,
        failed_transcriptions: failedTranscriptions,
        pending_transcriptions: pendingTranscriptions,
        total_duration_seconds: totalDuration,
        monthly_transcriptions: monthlyTranscriptions,
        monthly_limit: profile?.monthly_limit || 10
      }
    })
  } catch (error) {
    console.error('Profile error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
} 