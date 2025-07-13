export default function HomePage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          🎤 WhisperMe
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Professional Voice Transcription Service
        </p>
        <div className="space-y-4">
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold mb-4">Features</h2>
            <ul className="text-left space-y-2">
              <li>✅ High-quality AI transcription</li>
              <li>✅ macOS app with push-to-talk</li>
              <li>✅ Web dashboard for account management</li>
              <li>✅ Free tier with premium upgrades</li>
              <li>✅ Secure cloud storage with Supabase</li>
            </ul>
          </div>
          <div className="bg-white p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-semibold mb-4">Getting Started</h2>
            <p className="text-gray-600">
              Download the macOS app to start transcribing with push-to-talk functionality,
              or sign up for web access to manage your account.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
} 