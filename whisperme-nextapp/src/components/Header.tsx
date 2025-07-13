import Link from "next/link"

export default function Header() {
  return (
    <header className="bg-white shadow-sm">
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center py-6 md:py-8">
          {/* Logo/Brand */}
          <div className="flex items-center">
            <Link href="/" className="text-2xl font-bold text-indigo-600">
              WhisperMe
            </Link>
          </div>

          {/* Navigation Links */}
          <div className="hidden md:flex items-center space-x-8">
            <Link 
              href="/test" 
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              API Test
            </Link>
            <Link 
              href="/auth/login" 
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              Sign In
            </Link>
            <Link 
              href="/auth/register" 
              className="text-gray-600 hover:text-gray-900 transition-colors"
            >
              Register
            </Link>
          </div>

          {/* Download Button */}
          <div className="flex items-center space-x-4">
            <Link
              href="/download"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <svg className="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-4-4m4 4l4-4m-6 8h8a2 2 0 002-2V7a2 2 0 00-2-2H6a2 2 0 00-2 2v11a2 2 0 002 2z" />
              </svg>
              Download App
            </Link>
          </div>
        </div>

        {/* Mobile menu button */}
        <div className="md:hidden">
          <div className="flex items-center justify-between py-3 border-t border-gray-200">
            <div className="flex space-x-4">
              <Link 
                href="/test" 
                className="text-gray-600 hover:text-gray-900 text-sm"
              >
                API Test
              </Link>
              <Link 
                href="/auth/login" 
                className="text-gray-600 hover:text-gray-900 text-sm"
              >
                Sign In
              </Link>
              <Link 
                href="/auth/register" 
                className="text-gray-600 hover:text-gray-900 text-sm"
              >
                Register
              </Link>
            </div>
          </div>
        </div>
      </nav>
    </header>
  )
} 