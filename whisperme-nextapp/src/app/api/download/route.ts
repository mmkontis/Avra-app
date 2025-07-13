import { NextResponse } from 'next/server'

export const dynamic = 'force-dynamic'

const DRIVE_FILE_URL = 'https://drive.google.com/uc?export=download&id=1rWvdjy6BTMDAA9_caVloV_MotY_nvluv'

// Handle CORS preflight requests
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': 'https://whisperme-piih0.sevalla.app',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  })
}

export async function GET() {
  // Proxy the Google Drive file so the browser downloads it immediately without visiting Drive UI
  const driveRes = await fetch(DRIVE_FILE_URL)
  if (!driveRes.ok) {
    return NextResponse.json({ error: 'Failed to fetch file' }, { status: 500 })
  }

  const headers = new Headers(driveRes.headers)
  // Ensure correct attachment headers
  headers.set('Content-Type', 'application/octet-stream')
  headers.set('Content-Disposition', 'attachment; filename="AvraWhisper.dmg"')
  // Add CORS headers
  headers.set('Access-Control-Allow-Origin', 'https://whisperme-piih0.sevalla.app')

  return new NextResponse(driveRes.body, {
    headers,
    status: 200,
  })
} 