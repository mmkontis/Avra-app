"use client"

import { useSession, signOut } from "next-auth/react"
import { useRouter } from "next/navigation"
import { useEffect, useState } from "react"
import axios from "axios"

interface UserStats {
  usage_count: number
  usage_limit: number
  is_premium: boolean
  reset_date: string
}

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "http://localhost:8000"

export default function DashboardPage() {
  const { data: session, status } = useSession()
  const router = useRouter()
  const [stats, setStats] = useState<UserStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (status === "unauthenticated") {
      router.push("/auth/login")
    } else if (session) {
      fetchUserStats()
    }
  }, [session, status, router])

  const fetchUserStats = async () => {
    try {
      const response = await axios.get(`${BACKEND_URL}/user/stats`, {
        headers: {
          Authorization: `Bearer ${session?.accessToken}`
        }
      })
      setStats(response.data)
    } catch (error) {
      console.error("Failed to fetch user stats:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleSignOut = () => {
    signOut({ callbackUrl: "/" })
  }

  const handleUpgrade = async () => {
    try {
      const response = await axios.post(`${BACKEND_URL}/user/upgrade`, {}, {
        headers: {
          Authorization: `Bearer ${session?.accessToken}`
        }
      })
      if (response.data.success) {
        fetchUserStats() // Refresh stats
        alert("Successfully upgraded to premium!")
      }
    } catch (error) {
      console.error("Upgrade failed:", error)
      alert("Upgrade failed. Please try again.")
    }
  }

  if (status === "loading" || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-indigo-600"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (!session) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-6">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-gray-900">WhisperMe Dashboard</h1>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-700">
                Welcome, {session.user?.name || session.user?.email}
              </span>
              <button
                onClick={handleSignOut}
                className="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-md text-sm font-medium"
              >
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {/* Usage Statistics */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="w-8 h-8 bg-indigo-500 rounded-md flex items-center justify-center">
                      <span className="text-white text-sm font-medium">📊</span>
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Transcriptions Used
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {stats ? `${stats.usage_count} / ${stats.usage_limit}` : "Loading..."}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            {/* Account Type */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                      <span className="text-white text-sm font-medium">👤</span>
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Account Type
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {stats?.is_premium ? "Premium" : "Free"}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            {/* Reset Date */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="w-8 h-8 bg-yellow-500 rounded-md flex items-center justify-center">
                      <span className="text-white text-sm font-medium">🔄</span>
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Usage Resets
                      </dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {stats?.reset_date ? new Date(stats.reset_date).toLocaleDateString() : "N/A"}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Upgrade Section */}
          {stats && !stats.is_premium && (
            <div className="mt-8 bg-white shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <h3 className="text-lg leading-6 font-medium text-gray-900">
                  Upgrade to Premium
                </h3>
                <div className="mt-2 max-w-xl text-sm text-gray-500">
                  <p>
                    Get unlimited transcriptions and priority support with our premium plan.
                  </p>
                </div>
                <div className="mt-5">
                  <button
                    onClick={handleUpgrade}
                    className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium"
                  >
                    Upgrade Now
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* API Key Section */}
          <div className="mt-8 bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Device Integration
              </h3>
              <div className="mt-2 max-w-xl text-sm text-gray-500">
                <p>
                  Your WhisperMe app is automatically configured to use our backend service.
                  No additional setup required!
                </p>
              </div>
              <div className="mt-4 p-4 bg-gray-50 rounded-md">
                <p className="text-sm text-gray-600">
                  <strong>Backend URL:</strong> {BACKEND_URL}
                </p>
                <p className="text-sm text-gray-600 mt-1">
                  <strong>Status:</strong> <span className="text-green-600">Connected</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
} 