import React from 'react'
import './globals.css'

export const metadata = {
  title: 'WhisperMe - Professional Voice Transcription',
  description: 'Professional voice transcription service with AI-powered accuracy',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        {children}
      </body>
    </html>
  )
}
