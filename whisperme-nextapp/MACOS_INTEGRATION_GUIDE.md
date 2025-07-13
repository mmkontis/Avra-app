# macOS App Integration Guide

This guide explains how to connect your macOS WhisperMe app to the Next.js web API endpoints, including deep linking support.

## Deep Linking Setup (NEW!)

### 1. Configure URL Scheme in macOS App

Add this to your macOS app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.whisperme</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>whisperme</string>
        </array>
    </dict>
</array>
```

### 2. Handle Deep Links in AppDelegate

```swift
// AppDelegate.swift
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            return
        }
        
        handleDeepLink(url)
    }
    
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "whisperme" else { return }
        
        switch url.host {
        case "connect":
            handleConnectDeepLink(url)
        case "auth-success":
            handleAuthSuccess()
        default:
            break
        }
    }
    
    func handleConnectDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              let email = components.queryItems?.first(where: { $0.name == "email" })?.value else {
            showError("Invalid connection link")
            return
        }
        
        Task {
            await authenticateWithConnectionToken(token: token, email: email)
        }
    }
    
    func handleAuthSuccess() {
        // Show success message or navigate to main screen
        DispatchQueue.main.async {
            // Update UI to show successful connection
            NotificationCenter.default.post(name: .authenticationSucceeded, object: nil)
        }
    }
    
    func authenticateWithConnectionToken(token: String, email: String) async {
        do {
            let connectionResult = try await verifyConnectionToken(token: token)
            
            // Store user information securely
            KeychainHelper.shared.store(user: connectionResult.user)
            
            // Show success message
            DispatchQueue.main.async {
                self.showSuccessMessage("Successfully connected to your WhisperMe account!")
            }
        } catch {
            DispatchQueue.main.async {
                self.showError("Failed to connect: \(error.localizedDescription)")
            }
        }
    }
}

extension Notification.Name {
    static let authenticationSucceeded = Notification.Name("authenticationSucceeded")
}
```

### 3. Connection Token Verification

```swift
func verifyConnectionToken(token: String) async throws -> ConnectionResult {
    let url = URL(string: "http://localhost:3000/api/auth/connect-token?token=\(token)")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw ConnectionError.invalidToken
    }
    
    return try JSONDecoder().decode(ConnectionResult.self, from: data)
}

struct ConnectionResult: Codable {
    let user: User
    let auth_url: String?
    let message: String
}

enum ConnectionError: Error {
    case invalidToken
    case tokenExpired
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .invalidToken:
            return "Invalid or expired connection token"
        case .tokenExpired:
            return "Connection token has expired"
        case .networkError:
            return "Network connection failed"
        }
    }
}
```

## Authentication Flow

### 1. User Login via API

**Endpoint:** `POST /api/auth/login`

```swift
// Swift example for macOS app
func loginUser(email: String, password: String) async throws -> AuthResponse {
    let url = URL(string: "http://localhost:3000/api/auth/login")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["email": email, "password": password]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw AuthError.loginFailed
    }
    
    return try JSONDecoder().decode(AuthResponse.self, from: data)
}

struct AuthResponse: Codable {
    let user: User
    let session: Session
}

struct User: Codable {
    let id: String
    let email: String
    let created_at: String
}

struct Session: Codable {
    let access_token: String
    let refresh_token: String
    let expires_at: Int
}
```

### 2. Session Verification

**Endpoint:** `GET /api/auth/session`

```swift
func verifySession(accessToken: String) async throws -> Bool {
    let url = URL(string: "http://localhost:3000/api/auth/session")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (_, response) = try await URLSession.shared.data(for: request)
    
    return (response as? HTTPURLResponse)?.statusCode == 200
}
```

## Audio Upload and Transcription

### 3. Upload Audio File

**Endpoint:** `POST /api/transcribe/upload`

```swift
func uploadAudio(audioData: Data, filename: String, language: String = "en", accessToken: String) async throws -> UploadResponse {
    let url = URL(string: "http://localhost:3000/api/transcribe/upload")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // Add audio file
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
    body.append(audioData)
    body.append("\r\n".data(using: .utf8)!)
    
    // Add language
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
    body.append("\(language)\r\n".data(using: .utf8)!)
    
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw TranscriptionError.uploadFailed
    }
    
    return try JSONDecoder().decode(UploadResponse.self, from: data)
}

struct UploadResponse: Codable {
    let transcription_id: Int
    let status: String
    let message: String
    let file_path: String
    let created_at: String
}
```

### 4. Check Transcription Status

**Endpoint:** `GET /api/transcribe/status/{id}`

```swift
func checkTranscriptionStatus(transcriptionId: Int, accessToken: String) async throws -> TranscriptionStatus {
    let url = URL(string: "http://localhost:3000/api/transcribe/status/\(transcriptionId)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw TranscriptionError.statusCheckFailed
    }
    
    return try JSONDecoder().decode(TranscriptionStatus.self, from: data)
}

struct TranscriptionStatus: Codable {
    let id: Int
    let status: String // "pending", "processing", "completed", "failed"
    let progress: Int
    let result: String?
    let error: String?
    let created_at: String
    let completed_at: String?
    let language: String
    let duration: Double?
}
```

### 5. List User Transcriptions

**Endpoint:** `GET /api/transcribe/list`

```swift
func listTranscriptions(page: Int = 1, limit: Int = 20, status: String? = nil, accessToken: String) async throws -> TranscriptionList {
    var components = URLComponents(string: "http://localhost:3000/api/transcribe/list")!
    components.queryItems = [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "limit", value: "\(limit)")
    ]
    
    if let status = status {
        components.queryItems?.append(URLQueryItem(name: "status", value: status))
    }
    
    var request = URLRequest(url: components.url!)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw TranscriptionError.listFailed
    }
    
    return try JSONDecoder().decode(TranscriptionList.self, from: data)
}

struct TranscriptionList: Codable {
    let transcriptions: [TranscriptionItem]
    let pagination: Pagination
}

struct TranscriptionItem: Codable {
    let id: Int
    let filename: String
    let status: String
    let progress: Int
    let language: String
    let duration: Double?
    let file_size: Int
    let created_at: String
    let completed_at: String?
    let error_message: String?
}

struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let has_more: Bool
}
```

### 6. Get User Profile and Stats

**Endpoint:** `GET /api/user/profile`

```swift
func getUserProfile(accessToken: String) async throws -> UserProfile {
    let url = URL(string: "http://localhost:3000/api/user/profile")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw UserError.profileFetchFailed
    }
    
    return try JSONDecoder().decode(UserProfile.self, from: data)
}

struct UserProfile: Codable {
    let user: User
    let profile: Profile
    let statistics: Statistics
}

struct Profile: Codable {
    let plan: String
    let monthly_limit: Int
    let created_at: String
}

struct Statistics: Codable {
    let total_transcriptions: Int
    let completed_transcriptions: Int
    let failed_transcriptions: Int
    let pending_transcriptions: Int
    let total_duration_seconds: Double
    let monthly_transcriptions: Int
    let monthly_limit: Int
}
```

## Secure Storage Helper

```swift
import Security
import Foundation

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    private let service = "com.yourcompany.whisperme"
    
    func store(user: User) {
        let userData = try! JSONEncoder().encode(user)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "current_user",
            kSecValueData as String: userData
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieveUser() -> User? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "current_user",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data {
            return try? JSONDecoder().decode(User.self, from: data)
        }
        
        return nil
    }
    
    func deleteUser() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "current_user"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
```

## Integration Workflow

### Typical macOS App Flow (Updated with Deep Linking):

1. **App Launch:**
   - Check if user has stored user data in Keychain
   - If not authenticated, show welcome screen with "Connect via Web" button
   - If authenticated, verify session is still valid

2. **Connection via Web Dashboard:**
   - User clicks "Connect App" in web dashboard
   - Deep link opens macOS app: `whisperme://connect?token=...&email=...`
   - App verifies token and authenticates automatically

3. **Alternative: Manual Login:**
   - User can still login manually with email/password
   - Use `/api/auth/login` to authenticate
   - Store access token securely (Keychain)

4. **Record Audio:**
   - Use macOS AVAudioRecorder
   - Save as WAV/M4A format

5. **Upload for Transcription:**
   - Use `/api/transcribe/upload`
   - Get transcription ID

6. **Poll for Results:**
   - Use `/api/transcribe/status/{id}` every 2-3 seconds
   - Stop polling when status is "completed" or "failed"

7. **Display Results:**
   - Show transcription text from `result` field
   - Handle errors appropriately

## Environment Configuration

Add these to your `.env.local`:

```env
# Supabase Configuration (existing)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key

# Python Service Configuration
PYTHON_SERVICE_API_KEY=your-secure-api-key-for-python-service
```

## Error Handling

```swift
enum TranscriptionError: Error {
    case uploadFailed
    case statusCheckFailed
    case listFailed
    case invalidResponse
}

enum AuthError: Error {
    case loginFailed
    case invalidToken
    case sessionExpired
}

enum UserError: Error {
    case profileFetchFailed
}
```

## Security Considerations

1. **Store user data securely** in macOS Keychain
2. **Handle token expiration** - refresh or re-authenticate
3. **Use HTTPS in production** - update URLs to https://
4. **Validate SSL certificates** in production
5. **Don't log sensitive data** (tokens, user data)
6. **Validate deep link parameters** before processing

## Python Service Integration

Your Python service should:

1. **Poll for new transcriptions:**
   ```python
   # Check for pending transcriptions in Supabase
   # Download audio files from Supabase Storage
   # Process with Whisper
   # Update status via PUT /api/transcribe/status/{id}
   ```

2. **Use API Key authentication:**
   ```python
   headers = {
       'X-API-Key': 'your-secure-api-key',
       'Content-Type': 'application/json'
   }
   ```

## Database Schema (Supabase)

You'll need these tables in Supabase:

```sql
-- Transcriptions table
CREATE TABLE transcriptions (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    language TEXT DEFAULT 'en',
    status TEXT DEFAULT 'pending',
    progress INTEGER DEFAULT 0,
    result TEXT,
    error_message TEXT,
    duration REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- User profiles table (optional)
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) UNIQUE,
    plan TEXT DEFAULT 'free',
    monthly_limit INTEGER DEFAULT 10,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Connection tokens table (for deep linking)
CREATE TABLE connection_tokens (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Storage bucket for audio files
-- Create this in Supabase Dashboard: Storage > Create Bucket > "audio-files"
```

## Testing

Test the API endpoints with curl:

```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Check session
curl -X GET http://localhost:3000/api/auth/session \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Generate connection token (from authenticated web session)
curl -X POST http://localhost:3000/api/auth/connect-token \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# Verify connection token (from macOS app)
curl -X GET "http://localhost:3000/api/auth/connect-token?token=CONNECTION_TOKEN"

# Upload audio (replace with actual file)
curl -X POST http://localhost:3000/api/transcribe/upload \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "audio=@audio.wav" \
  -F "language=en"
```

## Deep Linking Testing

Test the deep linking functionality:

1. **From web dashboard:** Click "Connect App" button
2. **Manual testing:** Open this URL in browser: `whisperme://connect?token=test_token&email=test@example.com`
3. **Verify:** The macOS app should open and handle the connection

Your macOS app is now ready to integrate with the Next.js API with full deep linking support! 