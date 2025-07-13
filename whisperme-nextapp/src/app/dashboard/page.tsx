"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { supabase } from "@/lib/supabase"
import type { User } from "@supabase/supabase-js"

export default function Dashboard() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [connectingApp, setConnectingApp] = useState(false)
  const [connectMessage, setConnectMessage] = useState("")
  const router = useRouter()

  useEffect(() => {
    const getUser = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (session?.user) {
        setUser(session.user)
      } else {
        router.push("/auth/login")
      }
      setLoading(false)
    }

    getUser()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_OUT' || !session) {
        router.push("/auth/login")
      } else if (session?.user) {
        setUser(session.user)
      }
    })

    return () => subscription.unsubscribe()
  }, [router])

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push("/")
  }

  const handleConnectApp = async () => {
    if (!user) return

    setConnectingApp(true)
    setConnectMessage("")

    try {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session?.access_token) {
        setConnectMessage("Please refresh the page and try again.")
        return
      }

      const response = await fetch('/api/auth/connect-token', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${session.access_token}`,
          'Content-Type': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error('Failed to generate connection token')
      }

      const data = await response.json()
      
      // Try to open the deep link
      window.location.href = data.deep_link_url

      setConnectMessage(
        "If the WhisperMe app didn't open automatically, please make sure it's installed and try again. The connection link expires in 5 minutes."
      )
    } catch (error) {
      console.error('Connection error:', error)
      setConnectMessage("Failed to connect to the app. Please try again.")
    } finally {
      setConnectingApp(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-semibold text-gray-900">WhisperMe Dashboard</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-gray-700">Welcome, {user.email}</span>
              <button
                onClick={handleSignOut}
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {/* Connect App Section */}
          <div className="bg-gradient-to-r from-indigo-500 to-purple-600 rounded-lg shadow-lg mb-8 p-6 text-white">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold mb-2">Connect macOS App</h2>
                <p className="text-indigo-100 mb-4">
                  Connect your WhisperMe macOS app to sync transcriptions and enjoy seamless push-to-talk functionality.
                </p>
                {connectMessage && (
                  <div className="bg-white/20 rounded-md p-3 mb-4">
                    <p className="text-sm">{connectMessage}</p>
                  </div>
                )}
              </div>
              <div className="ml-6">
                <button
                  onClick={handleConnectApp}
                  disabled={connectingApp}
                  className="bg-white text-indigo-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed px-6 py-3 rounded-lg font-semibold flex items-center space-x-2 transition-colors"
                >
                  {connectingApp ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-indigo-600"></div>
                      <span>Connecting...</span>
                    </>
                  ) : (
                    <>
                      <span>📱</span>
                      <span>Connect App</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>

          <div className="border-4 border-dashed border-gray-200 rounded-lg min-h-96 p-8">
            <div className="text-center">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">
                Welcome to WhisperMe!
              </h2>
              <p className="text-gray-600 mb-8">
                Your transcription dashboard is ready. Start transcribing your audio files with our powerful AI technology.
              </p>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-3xl mb-4">🎤</div>
                  <h3 className="text-lg font-semibold mb-2">Quick Transcribe</h3>
                  <p className="text-gray-600 text-sm mb-4">
                    Upload an audio file and get instant transcription
                  </p>
                  <button className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                    Start Transcribing
                  </button>
                </div>

                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-3xl mb-4">📁</div>
                  <h3 className="text-lg font-semibold mb-2">My Files</h3>
                  <p className="text-gray-600 text-sm mb-4">
                    View and manage your transcription history
                  </p>
                  <button className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                    View Files
                  </button>
                </div>

                <div className="bg-white rounded-lg shadow p-6">
                  <div className="text-3xl mb-4">⚙️</div>
                  <h3 className="text-lg font-semibold mb-2">Settings</h3>
                  <p className="text-gray-600 text-sm mb-4">
                    Configure your transcription preferences
                  </p>
                  <button className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
                    Open Settings
                  </button>
                </div>
              </div>

              {/* API Test Section */}
              <div className="bg-white rounded-lg shadow p-6 mt-8">
                <h3 className="text-lg font-semibold mb-4 flex items-center">
                  <span className="mr-2">🧪</span>
                  API Testing
                </h3>
                <p className="text-gray-600 text-sm mb-4">
                  Test the transcription API directly with custom parameters, file upload, and recording capabilities
                </p>
                <button
                  onClick={() => router.push('/test')}
                  className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium flex items-center"
                >
                  <span className="mr-2">🚀</span>
                  Open API Test Interface
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
} 