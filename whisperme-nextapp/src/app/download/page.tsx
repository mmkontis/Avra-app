"use client"

import { useEffect } from 'react'
import Link from 'next/link'

export default function DownloadPage() {
  useEffect(() => {
    // Trigger the download once the component mounts
    window.location.href = '/api/download'
  }, [])

  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 py-20 px-4">
      {/* Animated background elements */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_25%_25%,rgba(120,119,198,0.3),transparent_50%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_75%_75%,rgba(236,72,153,0.3),transparent_50%)]" />
      
      {/* Floating orbs with subtle animation */}
      <div className="absolute top-1/4 left-1/4 w-72 h-72 bg-gradient-to-r from-violet-500/20 to-purple-500/20 rounded-full blur-3xl animate-pulse pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-to-r from-indigo-500/20 to-cyan-500/20 rounded-full blur-3xl animate-pulse pointer-events-none" style={{animationDelay: '1s'}} />

      <div className="relative max-w-2xl w-full">
        {/* Main card with premium glassmorphism */}
        <div className="bg-white/[0.08] backdrop-blur-xl border border-white/[0.15] rounded-3xl shadow-2xl p-12 text-center relative overflow-hidden">
          {/* Subtle inner glow */}
          <div className="absolute inset-0 bg-gradient-to-r from-purple-500/5 to-pink-500/5 rounded-3xl" />
          
          {/* Premium download icon */}
          <div className="relative mb-8">
            <div className="mx-auto w-24 h-24 bg-gradient-to-br from-violet-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-2xl">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                className="w-12 h-12 text-white"
              >
                <path
                  fillRule="evenodd"
                  d="M11.47 12.53a.75.75 0 0 1 1.06 0l4.724 4.723a.75.75 0 0 1-1.06 1.06l-3.19-3.189V21a.75.75 0 0 1-1.5 0v-5.876l-3.19 3.189a.75.75 0 0 1-1.06-1.06l4.724-4.723Z"
                  clipRule="evenodd"
                />
                <path
                  fillRule="evenodd"
                  d="M4.5 3.75A2.25 2.25 0 0 1 6.75 1.5h10.5A2.25 2.25 0 0 1 19.5 3.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-3a.75.75 0 0 1 0-1.5h3a.75.75 0 0 0 .75-.75V3.75a.75.75 0 0 0-.75-.75H6.75a.75.75 0 0 0-.75.75v10.5a.75.75 0 0 0 .75.75h3a.75.75 0 0 1 0 1.5h-3A2.25 2.25 0 0 1 4.5 14.25V3.75Z"
                  clipRule="evenodd"
                />
              </svg>
            </div>
          </div>

          <h1 className="text-5xl font-bold bg-gradient-to-r from-white to-gray-300 bg-clip-text text-transparent mb-4 tracking-tight">
            Premium Download
          </h1>
          <p className="text-xl text-gray-300 mb-10 leading-relaxed">
            Your WhisperMe app download will begin automatically.<br />
            <span className="text-gray-400 text-lg">Professional voice transcription at your fingertips.</span>
          </p>

          {/* Free Account Notice */}
          <div className="bg-gradient-to-r from-green-500/20 to-emerald-500/20 border border-green-400/30 rounded-2xl p-6 mb-8">
            <div className="flex items-center justify-center mb-4">
              <div className="w-12 h-12 bg-gradient-to-br from-green-400 to-emerald-500 rounded-full flex items-center justify-center">
                <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>
            <h3 className="text-2xl font-bold text-white mb-2">Free Account Required</h3>
            <p className="text-gray-300 mb-6">
              To use WhisperMe, you&apos;ll need to create a free account. Get started with transcription immediately after signing up!
            </p>
            
            {/* Big Login/Register Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/auth/login"
                className="group relative inline-flex items-center justify-center gap-3 rounded-2xl bg-gradient-to-r from-indigo-600 via-blue-600 to-purple-600 hover:from-indigo-500 hover:via-blue-500 hover:to-purple-500 text-white font-semibold py-4 px-8 text-lg transition-all duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-400 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900 shadow-2xl hover:shadow-blue-500/25 hover:scale-105 transform"
              >
                <span className="relative z-10 flex items-center gap-3">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                  </svg>
                  Sign In
                </span>
                <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-indigo-600 to-purple-600 blur-lg opacity-50 group-hover:opacity-75 transition-opacity duration-300" />
              </Link>
              
              <Link
                href="/auth/register"
                className="group relative inline-flex items-center justify-center gap-3 rounded-2xl bg-gradient-to-r from-emerald-600 via-green-600 to-teal-600 hover:from-emerald-500 hover:via-green-500 hover:to-teal-500 text-white font-semibold py-4 px-8 text-lg transition-all duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-green-400 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900 shadow-2xl hover:shadow-green-500/25 hover:scale-105 transform"
              >
                <span className="relative z-10 flex items-center gap-3">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                  </svg>
                  Create Free Account
                </span>
                <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-emerald-600 to-teal-600 blur-lg opacity-50 group-hover:opacity-75 transition-opacity duration-300" />
              </Link>
            </div>
          </div>

          {/* Premium download button */}
          <a
            href="/api/download"
            className="group relative inline-flex items-center justify-center gap-3 rounded-2xl bg-gradient-to-r from-violet-600 via-purple-600 to-indigo-600 hover:from-violet-500 hover:via-purple-500 hover:to-indigo-500 text-white font-semibold py-4 px-8 text-lg transition-all duration-300 focus:outline-none focus-visible:ring-2 focus-visible:ring-purple-400 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-900 shadow-2xl hover:shadow-purple-500/25 hover:scale-105 transform"
          >
            <span className="relative z-10 flex items-center gap-3">
              <span className="text-2xl">⬇️</span>
              Download WhisperMe.dmg
            </span>
            {/* Button glow effect */}
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-violet-600 to-indigo-600 blur-lg opacity-50 group-hover:opacity-75 transition-opacity duration-300" />
          </a>

          {/* File info */}
          <div className="mt-8 text-gray-400 text-sm">
            <span className="inline-flex items-center gap-2 bg-white/5 rounded-full px-4 py-2">
              <span className="w-2 h-2 bg-green-400 rounded-full"></span>
              2.0 MB • macOS Compatible • Free Account Required
            </span>
          </div>
        </div>

        {/* Back link */}
        <Link
          href="/"
          className="mt-8 inline-flex items-center gap-2 text-gray-300 hover:text-white transition-colors duration-200 mx-auto"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Home
        </Link>
      </div>
    </div>
  )
} 