import { NextRequest, NextResponse } from 'next/server'
import { supabase } from '@/lib/supabase'
import { supabaseAdmin } from '@/lib/supabase-admin'
import { createHash, randomBytes } from 'crypto'

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

export async function POST(request: NextRequest) {
  try {
    const user = await verifyAuth(request)
    if (!user) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // Generate a secure temporary token
    const connectionToken = randomBytes(32).toString('hex')
    const hashedToken = createHash('sha256').update(connectionToken).digest('hex')
    
    // Store the connection token in database with expiration (5 minutes)
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000) // 5 minutes from now
    
    const { error: insertError } = await supabaseAdmin
      .from('connection_tokens')
      .insert({
        user_id: user.id,
        token_hash: hashedToken,
        expires_at: expiresAt.toISOString(),
        used: false,
        created_at: new Date().toISOString()
      })

    if (insertError) {
      console.error('Failed to store connection token:', insertError)
      return NextResponse.json(
        { error: 'Failed to generate connection token', details: insertError.message },
        { status: 500 }
      )
    }

    // Return the connection token and deep link URL
    const deepLinkUrl = `whisperme://connect?token=${connectionToken}&email=${encodeURIComponent(user.email || '')}`

    return NextResponse.json({
      connection_token: connectionToken,
      deep_link_url: deepLinkUrl,
      expires_at: expiresAt.toISOString(),
      expires_in_seconds: 300 // 5 minutes
    })
  } catch (error) {
    console.error('Connection token generation error:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}

// GET endpoint to verify connection token (for macOS app)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const connectionToken = searchParams.get('token')

    if (!connectionToken) {
      return NextResponse.json(
        { error: 'Connection token is required' },
        { status: 400 }
      )
    }

    const hashedToken = createHash('sha256').update(connectionToken).digest('hex')

    // Find and verify the connection token
    const { data: tokenData, error } = await supabaseAdmin
      .from('connection_tokens')
      .select('user_id, expires_at, used')
      .eq('token_hash', hashedToken)
      .single()

    if (error || !tokenData) {
      return NextResponse.json(
        { error: 'Invalid connection token' },
        { status: 401 }
      )
    }

    // Check if token is expired
    if (new Date() > new Date(tokenData.expires_at)) {
      return NextResponse.json(
        { error: 'Connection token has expired' },
        { status: 401 }
      )
    }

    // Check if token has already been used
    if (tokenData.used) {
      return NextResponse.json(
        { error: 'Connection token has already been used' },
        { status: 401 }
      )
    }

    // Mark token as used
    await supabaseAdmin
      .from('connection_tokens')
      .update({ used: true, used_at: new Date().toISOString() })
      .eq('token_hash', hashedToken)

    // Get user data from auth.users table
    const { data: { user }, error: userError } = await supabaseAdmin.auth.admin.getUserById(tokenData.user_id)

    if (userError || !user) {
      // Fallback: return basic user info without full user object
      return NextResponse.json({
        user: {
          id: tokenData.user_id,
          email: 'connected_user@whisperme.app' // Placeholder since we can't get the real email without admin access
        },
        message: 'Connection successful. User authenticated.',
        access_token: 'use_supabase_session' // Signal to macOS app to create its own session
      })
    }

    return NextResponse.json({
      user: {
        id: user.id,
        email: user.email,
        created_at: user.created_at
      },
      message: 'Connection successful. User authenticated.',
      access_token: 'use_supabase_session' // Signal to macOS app to create its own session
    })
  } catch (error) {
    console.error('Connection token verification error:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
} 