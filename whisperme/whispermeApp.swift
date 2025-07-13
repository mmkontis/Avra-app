//
//  whispermeApp.swift
//  whisperme
//
//  Created by Minas marios kontis on 2/6/25.
//

import SwiftUI
import AVFoundation
import AppKit
import ApplicationServices
import Contacts
import IOKit
import ServiceManagement
// import Sparkle - removed in favor of SimpleUpdateChecker

// Models are now imported from separate files

// ContentView is now a class and an ObservableObject
class ContentViewModel: ObservableObject {
    @Published var audioLevel: Float = 0.0
    @Published var isRecording: Bool = false
    @Published var permissionStatusMessage: String = "Ready to record"
    @Published var transcriptionText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var selectedLanguage: String = "auto" // Default to auto-detect
    @Published var selectedModel: String = "gpt-4o-transcribe" // Default model
    @Published var customPrompt: String = "" // Custom prompt for better transcription
    @Published var isPremiumUser: Bool = false // Mock subscription status
    @Published var realTimePreviewEnabled: Bool = false // Privacy setting
    @Published var privacyModeEnabled: Bool = true // Privacy setting
    @Published var contacts: [ContactInfo] = [] // Fetched contacts
    @Published var selectedContact: ContactInfo? = nil // Currently selected contact
    @Published var contactsPermissionGranted: Bool = false // Contacts permission status
    @Published var currentRecordingMode: RecordingMode = .transcription // Current recording mode
    @Published var translationEnabled: Bool = false // Translation feature enabled
    @Published var selectedTranslationLanguage: String = "en" // Target translation language
    @Published var autoStartEnabled: Bool = false // Auto-start on login
    @Published var functionCalls: [FunctionCall] = [] // Function calls from chat completion
    @Published var hasFunctionCalls: Bool = false // Whether the last response had function calls
    @Published var enableFunctions: Bool = true // Whether to enable function calling
    @Published var chatModeEnabled: Bool = false // Whether chat mode (Fn+Shift) is enabled
    @Published var showToast: Bool = false // Whether to show toast notification
    @Published var toastMessage: String = "" // Toast message content
    @Published var toastType: ToastType = .info // Toast type for styling
    @Published var userEmail: String? = nil // User email for status bar popup
    
    // Conversation context for chat completion (up to 5 messages)
    @Published var conversationHistory: [ChatMessage] = []
    private let maxConversationHistory = 5
    
    // Track if current chat completion came from voice recording (should be pasted)
    var isVoiceToChat = false
    
    // Build version counter that increments with each build
    private let buildVersionKey = "WhisperMeBuildVersion"
    var currentBuildVersion: Int {
        let currentVersion = UserDefaults.standard.integer(forKey: buildVersionKey)
        let newVersion = currentVersion + 1
        UserDefaults.standard.set(newVersion, forKey: buildVersionKey)
        return newVersion
    }
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var isStartingRecording: Bool = false  // Prevent concurrent recording starts
    
    // Callback for when transcription is complete
    var onTranscriptionComplete: ((String) -> Void)?
    
    // Available transcription models
    let availableModels = ModelConstants.availableModels
    
    // Supported languages for OpenAI transcription API
    let supportedLanguages = LanguageConstants.supportedLanguages
    
    // Available translation target languages
    let translationLanguages = LanguageConstants.translationLanguages
    
    init() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        print("[ContentViewModel INIT] Initialized with AVAudioEngine.")
        
        // Load user preferences
        loadUserPreferences()
        
        // Check contacts permission and fetch contacts
        checkContactsPermissionAndFetch()
    }
    
    private func loadUserPreferences() {
        isPremiumUser = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isPremiumUser)
        realTimePreviewEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.realTimePreviewEnabled)
        privacyModeEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.privacyModeEnabled) as? Bool ?? DefaultValues.privacyModeEnabled
        selectedLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedLanguage) ?? DefaultValues.selectedLanguage
        selectedModel = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModel) ?? DefaultValues.selectedModel
        customPrompt = UserDefaults.standard.string(forKey: UserDefaultsKeys.customPrompt) ?? DefaultValues.customPrompt
        translationEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.translationEnabled)
        selectedTranslationLanguage = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedTranslationLanguage) ?? DefaultValues.selectedTranslationLanguage
        autoStartEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.autoStartEnabled)
        enableFunctions = UserDefaults.standard.object(forKey: UserDefaultsKeys.enableFunctions) as? Bool ?? DefaultValues.enableFunctions
        chatModeEnabled = UserDefaults.standard.object(forKey: UserDefaultsKeys.chatModeEnabled) as? Bool ?? DefaultValues.chatModeEnabled
        
        // Check actual auto-start status on app launch
        checkAutoStartStatus()
    }
    
    func saveUserPreferences() {
        UserDefaults.standard.set(isPremiumUser, forKey: UserDefaultsKeys.isPremiumUser)
        UserDefaults.standard.set(realTimePreviewEnabled, forKey: UserDefaultsKeys.realTimePreviewEnabled)
        UserDefaults.standard.set(privacyModeEnabled, forKey: UserDefaultsKeys.privacyModeEnabled)
        UserDefaults.standard.set(selectedLanguage, forKey: UserDefaultsKeys.selectedLanguage)
        UserDefaults.standard.set(selectedModel, forKey: UserDefaultsKeys.selectedModel)
        UserDefaults.standard.set(customPrompt, forKey: UserDefaultsKeys.customPrompt)
        UserDefaults.standard.set(translationEnabled, forKey: UserDefaultsKeys.translationEnabled)
        UserDefaults.standard.set(selectedTranslationLanguage, forKey: UserDefaultsKeys.selectedTranslationLanguage)
        UserDefaults.standard.set(autoStartEnabled, forKey: UserDefaultsKeys.autoStartEnabled)
        UserDefaults.standard.set(enableFunctions, forKey: UserDefaultsKeys.enableFunctions)
        UserDefaults.standard.set(chatModeEnabled, forKey: UserDefaultsKeys.chatModeEnabled)
    }
    
    // Toast notification methods
    func showToast(message: String, type: ToastType = .info, duration: Double = 3.0) {
        DispatchQueue.main.async {
            self.toastMessage = message
            self.toastType = type
            self.showToast = true
            
            // Notify AppDelegate to show toast window
            NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.toastStateChanged), object: nil)
            
            // Auto-hide toast after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.hideToast()
            }
        }
    }
    
    func hideToast() {
        DispatchQueue.main.async {
            self.showToast = false
            self.toastMessage = ""
            
            // Notify AppDelegate to hide toast window
            NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.toastStateChanged), object: nil)
        }
    }
    
    func isUserAuthenticated() -> Bool {
        let isConnected = UserDefaults.standard.bool(forKey: "is_connected_to_webapp")
        let userEmail = UserDefaults.standard.string(forKey: "connected_user_email")
        
        return isConnected && userEmail != nil && !userEmail!.isEmpty
    }
    
    func showFunctionCallToast(functionCall: FunctionCall) {
        var message = "\(functionCall.displayName)"
        if let result = functionCall.result {
            message += ": \(result)"
        }
        showToast(message: message, type: .functionCall, duration: 5.0)
    }
    
    func checkContactsPermissionAndFetch() {
        let store = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            DispatchQueue.main.async {
                self.contactsPermissionGranted = true
            }
            fetchContacts()
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.contactsPermissionGranted = granted
                    if granted {
                        self?.fetchContacts()
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.contactsPermissionGranted = false
            }
        @unknown default:
            DispatchQueue.main.async {
                self.contactsPermissionGranted = false
            }
        }
    }
    
    func fetchContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var fetchedContacts: [ContactInfo] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with phone numbers
                for phoneNumber in contact.phoneNumbers {
                    let contactInfo = ContactInfo(
                        firstName: contact.givenName,
                        lastName: contact.familyName,
                        phoneNumber: phoneNumber.value.stringValue
                    )
                    fetchedContacts.append(contactInfo)
                }
            }
            
            // Sort contacts by display name
            fetchedContacts.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            
            DispatchQueue.main.async {
                self.contacts = fetchedContacts
                print("[ContentViewModel] Fetched \(fetchedContacts.count) contacts")
            }
            
        } catch {
            print("[ContentViewModel] Error fetching contacts: \(error)")
            DispatchQueue.main.async {
                self.contacts = []
            }
        }
    }
    
    private func getDeviceId() -> String {
        // Check if we already have a stored device ID
        if let existingId = UserDefaults.standard.string(forKey: "whisperme_device_id") {
            return existingId
        }
        
        // Generate new device ID based on hardware UUID
        let platformUUID = IOPlatformUUID() ?? UUID().uuidString
        let deviceId = "whisperme_\(platformUUID)"
        
        // Store for future use
        UserDefaults.standard.set(deviceId, forKey: "whisperme_device_id")
        
        return deviceId
    }
    
    private func IOPlatformUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard platformExpert != 0 else { return nil }
        defer { IOObjectRelease(platformExpert) }
        
        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeUnretainedValue() as? String else {
            return nil
        }
        
        return serialNumberAsCFString
    }
    
    private func getFrontmostApplication() -> String {
        let workspace = NSWorkspace.shared
        if let frontmostApp = workspace.frontmostApplication {
            return frontmostApp.localizedName ?? "Unknown"
        }
        return "Unknown"
    }
    
    private func requestScreenRecordingPermission() {
        // Check if screen recording permission is granted
        if CGPreflightScreenCaptureAccess() {
            print("Screen recording permission already granted")
        } else {
            // Request screen recording permission
            CGRequestScreenCaptureAccess()
        }
    }
    
    private func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    private func checkAutoStartStatus() {
        if #available(macOS 13.0, *) {
            autoStartEnabled = SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, check legacy launch agents
            autoStartEnabled = isLegacyAutoStartEnabled()
        }
    }
    
    func toggleAutoStart() {
        if #available(macOS 13.0, *) {
            if autoStartEnabled {
                disableAutoStart()
            } else {
                enableAutoStart()
            }
        } else {
            // Handle legacy systems
            if autoStartEnabled {
                disableLegacyAutoStart()
            } else {
                enableLegacyAutoStart()
            }
        }
    }
    
    @available(macOS 13.0, *)
    private func enableAutoStart() {
        do {
            try SMAppService.mainApp.register()
            autoStartEnabled = true
            saveUserPreferences()
            print("✅ Auto-start enabled successfully")
        } catch {
            print("❌ Failed to enable auto-start: \(error)")
        }
    }
    
    @available(macOS 13.0, *)
    private func disableAutoStart() {
        do {
            try SMAppService.mainApp.unregister()
            autoStartEnabled = false
            saveUserPreferences()
            print("✅ Auto-start disabled successfully")
        } catch {
            print("❌ Failed to disable auto-start: \(error)")
        }
    }
    
    // Legacy auto-start for macOS < 13.0 - Simplified version
    private func isLegacyAutoStartEnabled() -> Bool {
        // For older macOS versions, we'll just return false for now
        // Users can manually add the app to Login Items in System Preferences
        return false
    }
    
    private func enableLegacyAutoStart() {
        // For older macOS versions, show an alert to manually add to Login Items
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Auto-start Setup"
            alert.informativeText = "On macOS versions before 13.0, please manually add Avra to Login Items in System Preferences > Users & Groups > Login Items."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        autoStartEnabled = false
        saveUserPreferences()
    }
    
    private func disableLegacyAutoStart() {
        // For older macOS versions, show an alert to manually remove from Login Items
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Auto-start Removal"
            alert.informativeText = "On macOS versions before 13.0, please manually remove Avra from Login Items in System Preferences > Users & Groups > Login Items."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        autoStartEnabled = false
        saveUserPreferences()
    }
    
    func togglePremiumSubscription() {
        isPremiumUser.toggle()
        saveUserPreferences()
    }
    
    func checkPermissionAndSetup() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch currentStatus {
        case .authorized:
            DispatchQueue.main.async {
                self.permissionStatusMessage = "Ready to record"
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.permissionStatusMessage = "Ready to record"
                    } else {
                        self?.permissionStatusMessage = "Microphone permission denied"
                    }
                }
            }
        case .denied:
            DispatchQueue.main.async {
                self.permissionStatusMessage = "Microphone permission denied. Enable in Settings."
            }
        case .restricted:
            DispatchQueue.main.async {
                self.permissionStatusMessage = "Microphone access restricted"
            }
        @unknown default:
            DispatchQueue.main.async {
                self.permissionStatusMessage = "Unknown permission status"
            }
        }
    }
    
    func startRecording() {
        NSLog("[ContentViewModel] startRecording called")
        
        // Check if user is authenticated before allowing recording
        if !isUserAuthenticated() {
            NSLog("[ContentViewModel] ❌ User not authenticated, blocking recording")
            showToast(message: "Please log in to use recording features", type: .error)
            return
        }
        
        // Prevent concurrent recording starts
        guard !isStartingRecording else {
            NSLog("[ContentViewModel] Already starting a recording, skipping")
            return
        }
        isStartingRecording = true
        
        // Ensure we reset the flag on any exit
        defer {
            isStartingRecording = false
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        NSLog("[ContentViewModel] Audio authorization status: %d", authStatus.rawValue)
        
        guard authStatus == .authorized else {
            NSLog("[ContentViewModel] ❌ Audio not authorized, calling checkPermissionAndSetup")
            checkPermissionAndSetup()
            return
        }
        
        guard let audioEngine = self.audioEngine,
              let inputNode = self.inputNode else {
            NSLog("[ContentViewModel] ❌ Audio engine not initialized")
            print("[ContentViewModel] Audio engine not initialized")
            return
        }
        
        NSLog("[ContentViewModel] ✅ Audio engine and input node ready")
        
        // Stop the engine if it's already running
        if audioEngine.isRunning {
            NSLog("[ContentViewModel] Audio engine already running, stopping it first")
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
        }
        
        // Create a unique file for this recording
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        recordingURL = audioFilename
        
        NSLog("[ContentViewModel] Recording file: %@", audioFilename.path)
        
        do {
            // Get the input format from the hardware - this is crucial!
            let inputFormat = inputNode.outputFormat(forBus: 0)
            NSLog("[ContentViewModel] Input hardware format: %@ channels, %.0f Hz", 
                  NSNumber(value: inputFormat.channelCount), inputFormat.sampleRate)
            
            // CRITICAL FIX: Use hardware format for tap installation to prevent mismatch
            let tapFormat = inputFormat  // Use actual hardware format for tap
            NSLog("[ContentViewModel] Using tap format: %@ channels, %.0f Hz", 
                  NSNumber(value: tapFormat.channelCount), tapFormat.sampleRate)
            
            // Create 16kHz format for file writing (OpenAI prefers this for speech)
            let fileFormat = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            NSLog("[ContentViewModel] Using file format: %@ channels, %.0f Hz", 
                  NSNumber(value: fileFormat.channelCount), fileFormat.sampleRate)
            
            // Use settings compatible with our chosen format for file writing
            let recordingSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000,  // Use 16kHz for file
                AVNumberOfChannelsKey: 1,   // Mono for speech
                AVLinearPCMBitDepthKey: 16, // 16-bit depth
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            NSLog("[ContentViewModel] Creating audio file with settings: %@", recordingSettings)
            
            // Create the audio file with our chosen settings
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: recordingSettings)
            
            NSLog("[ContentViewModel] ✅ Audio file created successfully")
            
            // Create audio converter to convert from hardware format to file format
            let audioConverter = AVAudioConverter(from: tapFormat, to: fileFormat)
            guard let converter = audioConverter else {
                NSLog("[ContentViewModel] ❌ Failed to create audio converter")
                throw NSError(domain: "AudioConverter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio converter"])
            }
            
            NSLog("[ContentViewModel] ✅ Audio converter created successfully")
            
            // Remove any existing tap before installing a new one
            inputNode.removeTap(onBus: 0)
            NSLog("[ContentViewModel] Removed any existing tap")
            
            // Validate format before installing tap
            guard tapFormat.channelCount > 0 && tapFormat.sampleRate > 0 else {
                NSLog("[ContentViewModel] ❌ Invalid tap format detected")
                throw NSError(domain: "AudioFormat", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid audio format"])
            }
            
            // Install tap using the HARDWARE format (this prevents the mismatch exception)
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { [weak self] (buffer, when) in
                guard let self = self else { return }
                
                // Convert from hardware format to file format
                let frameCount = AVAudioFrameCount(fileFormat.sampleRate * Double(buffer.frameLength) / tapFormat.sampleRate)
                guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: frameCount) else {
                    NSLog("[ContentViewModel] Failed to create converted buffer")
                    return
                }
                
                var error: NSError?
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
                
                if let error = error {
                    NSLog("[ContentViewModel] Conversion error: %@", error.localizedDescription)
                    return
                }
                
                // Write converted audio to file
                do {
                    try self.audioFile?.write(from: convertedBuffer)
                } catch {
                    NSLog("[ContentViewModel] Error writing to file: %@", error.localizedDescription)
                }
                
                // Calculate audio level for visualization using original buffer
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { return }
                
                var sum: Float = 0.0
                let step = max(1, frameLength / 100) // Sample every nth frame for performance
                for i in stride(from: 0, to: frameLength, by: step) {
                    sum += pow(channelData[i], 2)
                }
                let rms = sqrt(sum / Float(frameLength / step))
                let sensitivity: Float = 8.0 // Slightly reduced sensitivity
                let normalizedLevel = min(max(rms * sensitivity, 0.0), 1.0)
                
                DispatchQueue.main.async {
                    self.audioLevel = normalizedLevel
                }
            }
            
            NSLog("[ContentViewModel] ✅ Audio tap installed successfully with hardware format")
            
            // Prepare and start the engine
            audioEngine.prepare()
            NSLog("[ContentViewModel] Audio engine prepared")
            
            try audioEngine.start()
            NSLog("[ContentViewModel] ✅ Audio engine started successfully")
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.permissionStatusMessage = "Recording..."
                self.transcriptionText = ""
                NSLog("[ContentViewModel] ✅ UI updated to recording state")
            }
            
            NSLog("[ContentViewModel] ✅ Recording started successfully with format conversion")
            
        } catch {
            NSLog("[ContentViewModel] ❌ Error starting recording: %@", error.localizedDescription)
            DispatchQueue.main.async {
                self.permissionStatusMessage = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    func stopRecording() {
        guard let audioEngine = self.audioEngine else { return }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            inputNode?.removeTap(onBus: 0)
            audioFile = nil
            
            // Check if we have a recording to transcribe
            if let url = recordingURL, FileManager.default.fileExists(atPath: url.path) {
                // Get file size to ensure we have actual audio
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let fileSize = attributes[.size] as? Int64,
                   fileSize > 1000 { // At least 1KB of audio data
                    
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.audioLevel = 0.0
                        self.permissionStatusMessage = "Recording stopped. Transcribing..."
                        self.isTranscribing = true
                    }
                    
                    print("[ContentViewModel] Recording stopped, file size: \(fileSize) bytes")
                    
                    // Transcribe the audio
                    transcribeAudio(fileURL: url)
                } else {
                    // File too small, no real audio recorded
                    DispatchQueue.main.async {
                        self.isRecording = false
                        self.audioLevel = 0.0
                        self.permissionStatusMessage = "No audio recorded"
                        self.isTranscribing = false
                        // Notify that transcription is complete (with empty text)
                        self.onTranscriptionComplete?("")
                    }
                }
            } else {
                // No recording file
                DispatchQueue.main.async {
                    self.isRecording = false
                    self.audioLevel = 0.0
                    self.permissionStatusMessage = "No audio recorded"
                    self.isTranscribing = false
                    // Notify that transcription is complete (with empty text)
                    self.onTranscriptionComplete?("")
                }
            }
        }
    }
    
    private func transcribeAudio(fileURL: URL) {
        switch currentRecordingMode {
        case .transcription:
            performTranscription(fileURL: fileURL)
        case .chatCompletion:
            performChatCompletion(fileURL: fileURL)
        }
    }
    
    private func performTranscription(fileURL: URL) {
        // Use local backend instead of OpenAI directly
        let url = URL(string: "https://whisperme-piih0.sevalla.app/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // No API key needed - backend handles this
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Generate device ID based on Mac's hardware UUID
        let deviceId = getDeviceId()
        
        // Add device_id parameter (required by backend)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"device_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(deviceId)\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(selectedModel)\r\n".data(using: .utf8)!)
        
        // Add language parameter - when translation is enabled, use target language
        let languageToUse = translationEnabled ? selectedTranslationLanguage : selectedLanguage
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(languageToUse)\r\n".data(using: .utf8)!)
        
        // Add active app parameter
        let activeApp = getFrontmostApplication()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"active_app\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(activeApp)\r\n".data(using: .utf8)!)
        
        // Add prompt parameter - translation takes priority when enabled
        var finalPrompt = ""
        if translationEnabled {
            let targetLanguageName = translationLanguages.first(where: { $0.code == selectedTranslationLanguage })?.name ?? selectedTranslationLanguage
            finalPrompt = "MUST translate to \(targetLanguageName)"
        } else if !customPrompt.isEmpty {
            finalPrompt = customPrompt
        }
        
        // Debug logging
        NSLog("[ContentViewModel] Starting transcription with backend")
        NSLog("[ContentViewModel] Device ID: %@", deviceId)
        NSLog("[ContentViewModel] Model: %@", selectedModel)
        NSLog("[ContentViewModel] Translation enabled: %@", translationEnabled ? "YES" : "NO")
        if translationEnabled {
            NSLog("[ContentViewModel] Translation target: %@ (%@)", selectedTranslationLanguage, translationLanguages.first(where: { $0.code == selectedTranslationLanguage })?.name ?? "Unknown")
        }
        NSLog("[ContentViewModel] Language used: %@", languageToUse)
        if !finalPrompt.isEmpty {
            NSLog("[ContentViewModel] Final prompt being sent: %@", finalPrompt)
        }
        
        if !finalPrompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(finalPrompt)\r\n".data(using: .utf8)!)
        }
        
        // Add audio file (backend expects 'audio_file' not 'file')
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        do {
            let audioData = try Data(contentsOf: fileURL)
            body.append(audioData)
        } catch {
            print("[ContentViewModel] Error reading audio file: \(error)")
            DispatchQueue.main.async {
                self.transcriptionText = "Error reading audio file"
                self.isTranscribing = false
                self.permissionStatusMessage = "Ready to record"
            }
            return
        }
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                
                if let error = error {
                    self?.transcriptionText = "Error: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Transcription failed"
                    
                    // Call completion callback with empty text to ensure UI updates
                    self?.onTranscriptionComplete?("")
                    return
                }
                
                guard let data = data else {
                    self?.transcriptionText = "No data received"
                    self?.permissionStatusMessage = "Transcription failed"
                    
                    // Call completion callback with empty text to ensure UI updates
                    self?.onTranscriptionComplete?("")
                    return
                }
                
                do {
                    // Log the raw response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("[ContentViewModel] Backend Response: %@", responseString)
                    }
                    
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let text = json["text"] as? String {
                            NSLog("[ContentViewModel] ✅ Transcription successful: %@", text)
                            self?.transcriptionText = text
                            
                            // Handle backend-specific response fields
                            if let usageRemaining = json["usage_remaining"] as? Int {
                                NSLog("[ContentViewModel] Usage remaining: %d", usageRemaining)
                            }
                            if let isPremium = json["is_premium"] as? Bool {
                                NSLog("[ContentViewModel] Premium user: %@", isPremium ? "Yes" : "No")
                                self?.isPremiumUser = isPremium
                            }
                            
                            self?.permissionStatusMessage = "Transcription complete"
                            
                            // Call the completion callback
                            self?.onTranscriptionComplete?(text)
                        } else if let errorDetail = json["detail"] as? String {
                            // Backend error format
                            NSLog("[ContentViewModel] ❌ Backend Error: %@", errorDetail)
                            self?.transcriptionText = "Error: \(errorDetail)"
                            self?.permissionStatusMessage = "Transcription failed"
                            
                            // Call completion callback with empty text to ensure UI updates
                            self?.onTranscriptionComplete?("")
                        } else if let error = json["error"] as? [String: Any] {
                            // Fallback for OpenAI-style errors
                            let errorMessage = error["message"] as? String ?? "Unknown error"
                            NSLog("[ContentViewModel] ❌ API Error: %@", errorMessage)
                            self?.transcriptionText = "API Error: \(errorMessage)"
                            self?.permissionStatusMessage = "Transcription failed"
                            
                            // Call completion callback with empty text to ensure UI updates
                            self?.onTranscriptionComplete?("")
                        } else {
                            NSLog("[ContentViewModel] ❌ Unexpected response format")
                            self?.transcriptionText = "Failed to parse response"
                            self?.permissionStatusMessage = "Transcription failed"
                            
                            // Call completion callback with empty text to ensure UI updates
                            self?.onTranscriptionComplete?("")
                        }
                    } else {
                        NSLog("[ContentViewModel] ❌ Invalid JSON response")
                        self?.transcriptionText = "Invalid JSON response"
                        self?.permissionStatusMessage = "Transcription failed"
                        
                        // Call completion callback with empty text to ensure UI updates
                        self?.onTranscriptionComplete?("")
                    }
                } catch {
                    NSLog("[ContentViewModel] ❌ JSON parsing error: %@", error.localizedDescription)
                    self?.transcriptionText = "Error parsing response: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Transcription failed"
                    
                    // Call completion callback with empty text to ensure UI updates
                    self?.onTranscriptionComplete?("")
                }
            }
            
            // Clean up the audio file
            try? FileManager.default.removeItem(at: fileURL)
        }.resume()
    }
    
    private func performChatCompletion(fileURL: URL) {
        // First transcribe the audio to get text
        let transcribeUrl = URL(string: "https://whisperme-piih0.sevalla.app/transcribe")!
        var transcribeRequest = URLRequest(url: transcribeUrl)
        transcribeRequest.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        transcribeRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var transcribeBody = Data()
        
        // Generate device ID based on Mac's hardware UUID
        let deviceId = getDeviceId()
        
        // Add device_id parameter (required by backend)
        transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Disposition: form-data; name=\"device_id\"\r\n\r\n".data(using: .utf8)!)
        transcribeBody.append("\(deviceId)\r\n".data(using: .utf8)!)
        
        // Add model parameter
        transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        transcribeBody.append("\(selectedModel)\r\n".data(using: .utf8)!)
        
        // Add language parameter - when translation is enabled, use target language
        let languageToUse = translationEnabled ? selectedTranslationLanguage : selectedLanguage
        transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        transcribeBody.append("\(languageToUse)\r\n".data(using: .utf8)!)
        
        // Add active app parameter
        let activeApp = getFrontmostApplication()
        transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Disposition: form-data; name=\"active_app\"\r\n\r\n".data(using: .utf8)!)
        transcribeBody.append("\(activeApp)\r\n".data(using: .utf8)!)
        
        // Add prompt parameter - translation takes priority when enabled
        var finalPrompt = ""
        if translationEnabled {
            let targetLanguageName = translationLanguages.first(where: { $0.code == selectedTranslationLanguage })?.name ?? selectedTranslationLanguage
            finalPrompt = "MUST translate to \(targetLanguageName)"
        } else if !customPrompt.isEmpty {
            finalPrompt = customPrompt
        }
        
        if !finalPrompt.isEmpty {
            transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            transcribeBody.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            transcribeBody.append(finalPrompt.data(using: .utf8)!)
            transcribeBody.append("\r\n".data(using: .utf8)!)
        }
        
        // Add audio file (backend expects 'audio_file' not 'audio')
        transcribeBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        transcribeBody.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        do {
            let audioData = try Data(contentsOf: fileURL)
            transcribeBody.append(audioData)
        } catch {
            NSLog("[ContentViewModel] Error reading audio file for chat: \(error)")
            DispatchQueue.main.async {
                self.transcriptionText = "Error reading audio file"
                self.isTranscribing = false
                self.permissionStatusMessage = "Chat completion failed"
                self.onTranscriptionComplete?("")
            }
            return
        }
        
        transcribeBody.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        transcribeRequest.httpBody = transcribeBody
        
        // First perform transcription
        URLSession.shared.dataTask(with: transcribeRequest) { [weak self] data, response, error in
            if let error = error {
                NSLog("[ContentViewModel] ❌ Transcription error for chat: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.transcriptionText = "Error: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.isTranscribing = false
                    self?.onTranscriptionComplete?("")
                }
                return
            }
            
            guard let data = data else {
                NSLog("[ContentViewModel] ❌ No transcription data received")
                DispatchQueue.main.async {
                    self?.transcriptionText = "No data received"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.isTranscribing = false
                    self?.onTranscriptionComplete?("")
                }
                return
            }
            
            // Parse transcription response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let transcription = json["text"] as? String, !transcription.isEmpty {
                        NSLog("[ContentViewModel] 📝 Transcription successful for chat: %@", transcription)
                        
                        // Mark this as voice-to-chat (should be pasted)
                        self?.isVoiceToChat = true
                        
                        // Add transcribed text to conversation history and perform chat completion
                        self?.addMessageToHistory(role: "user", content: transcription)
                        self?.performGPT4oChatCompletion(with: transcription)
                        
                        // NOTE: Do NOT call onTranscriptionComplete here for chat completion
                        // It will be called from performGPT4oChatCompletion after the AI response
                    } else {
                        NSLog("[ContentViewModel] ❌ Empty transcription for chat")
                        DispatchQueue.main.async {
                            self?.transcriptionText = "No speech detected"
                            self?.permissionStatusMessage = "Chat completion failed"
                            self?.isTranscribing = false
                            self?.onTranscriptionComplete?("")
                        }
                    }
                } else {
                    NSLog("[ContentViewModel] ❌ Invalid transcription JSON")
                    DispatchQueue.main.async {
                        self?.transcriptionText = "Invalid response format"
                        self?.permissionStatusMessage = "Chat completion failed"
                        self?.isTranscribing = false
                        self?.onTranscriptionComplete?("")
                    }
                }
            } catch {
                NSLog("[ContentViewModel] ❌ Transcription JSON parsing error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.transcriptionText = "Error parsing transcription: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.isTranscribing = false
                    self?.onTranscriptionComplete?("")
                }
            }
            
            // Clean up the audio file
            try? FileManager.default.removeItem(at: fileURL)
        }.resume()
    }
    
    private func performGPT4oChatCompletion(with transcribedText: String) {
        // Use local backend for chat completion
                    let url = URL(string: "https://whisperme-piih0.sevalla.app/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare conversation history for the request
        var messages: [[String: Any]] = []
        
        // Add system message if custom prompt is set
        if !customPrompt.isEmpty {
            messages.append([
                "role": "system",
                "content": customPrompt
            ])
        } else {
            messages.append([
                "role": "system",
                "content": "You are a helpful assistant. Provide concise and accurate responses."
            ])
        }
        
        // Add all conversation history (the current user message is already in history)
        for message in conversationHistory {
            messages.append([
                "role": message.role,
                "content": message.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "message": transcribedText,
            "messages": messages,
            "model": "gpt-4o",
            "context": customPrompt.isEmpty ? "You are a helpful assistant. Provide concise and accurate responses." : customPrompt,
            "enable_functions": enableFunctions
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            NSLog("[ContentViewModel] ❌ Chat request JSON error: %@", error.localizedDescription)
            DispatchQueue.main.async {
                self.transcriptionText = "Error creating chat request"
                self.permissionStatusMessage = "Chat completion failed"
                self.isTranscribing = false
                self.onTranscriptionComplete?("")
            }
            return
        }
        
        NSLog("[ContentViewModel] 🤖 Sending chat completion request with message: %@", transcribedText)
        NSLog("[ContentViewModel] 💬 Conversation history contains %d messages", conversationHistory.count)
        NSLog("[ContentViewModel] 📤 Sending %d messages to API (including system message)", messages.count)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            NSLog("[ContentViewModel] 🔄 Chat completion response received")
            
            DispatchQueue.main.async {
                self?.isTranscribing = false
            }
            
            if let error = error {
                NSLog("[ContentViewModel] ❌ Chat completion error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.transcriptionText = "Error: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.onTranscriptionComplete?("")
                }
                return
            }
            
            guard let data = data else {
                NSLog("[ContentViewModel] ❌ No chat completion data received")
                DispatchQueue.main.async {
                    self?.transcriptionText = "No response received"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.onTranscriptionComplete?("")
                }
                return
            }
            
            NSLog("[ContentViewModel] 📦 Chat completion data received, size: %d bytes", data.count)
            
            // Parse chat completion response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let response = json["response"] as? String, !response.isEmpty {
                        NSLog("[ContentViewModel] 🤖 Chat completion successful: %@", response)
                        
                        // Parse function calls if present
                        var parsedFunctionCalls: [FunctionCall] = []
                        let hasFunctions = json["has_function_calls"] as? Bool ?? false
                        
                        if hasFunctions, let functionCallsData = json["function_calls"] as? [[String: Any]] {
                            for functionCallData in functionCallsData {
                                if let name = functionCallData["name"] as? String,
                                   let arguments = functionCallData["arguments"] as? [String: Any],
                                   let result = functionCallData["result"] as? String,
                                   let status = functionCallData["status"] as? String {
                                    
                                    let functionCall = FunctionCall(
                                        name: name,
                                        arguments: arguments,
                                        result: result,
                                        status: status
                                    )
                                    parsedFunctionCalls.append(functionCall)
                                    NSLog("[ContentViewModel] 🔧 Function call: %@ -> %@", name, result)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.transcriptionText = response
                            self?.functionCalls = parsedFunctionCalls
                            self?.hasFunctionCalls = hasFunctions
                            self?.permissionStatusMessage = hasFunctions ? "Chat with functions complete" : "Chat completion complete"
                            
                            // Add assistant response to conversation history
                            self?.addMessageToHistory(role: "assistant", content: response)
                            
                            // Show toast notifications for completed function calls
                            for functionCall in parsedFunctionCalls {
                                if functionCall.status == "completed" {
                                    self?.showFunctionCallToast(functionCall: functionCall)
                                }
                            }
                            
                            // For voice-to-chat, call completion callback with the AI response for pasting
                            // This will trigger pasting of the AI response to the active application
                            if self?.isVoiceToChat == true {
                                NSLog("[ContentViewModel] Chat completion done, calling onTranscriptionComplete with AI response for pasting: %@", response)
                                self?.onTranscriptionComplete?(response)
                                // Reset the flag
                                self?.isVoiceToChat = false
                            } else {
                                // For manual chat, don't call onTranscriptionComplete (no pasting)
                                NSLog("[ContentViewModel] Manual chat completion done, not calling onTranscriptionComplete")
                                self?.onTranscriptionComplete?("")
                            }
                        }
                    } else if let errorDetail = json["detail"] as? String {
                        NSLog("[ContentViewModel] ❌ Chat Backend Error: %@", errorDetail)
                        DispatchQueue.main.async {
                            self?.transcriptionText = "Error: \(errorDetail)"
                            self?.permissionStatusMessage = "Chat completion failed"
                            self?.functionCalls = []
                            self?.hasFunctionCalls = false
                            self?.onTranscriptionComplete?("")
                        }
                    } else if let error = json["error"] as? [String: Any] {
                        let errorMessage = error["message"] as? String ?? "Unknown error"
                        NSLog("[ContentViewModel] ❌ Chat API Error: %@", errorMessage)
                        DispatchQueue.main.async {
                            self?.transcriptionText = "API Error: \(errorMessage)"
                            self?.permissionStatusMessage = "Chat completion failed"
                            self?.functionCalls = []
                            self?.hasFunctionCalls = false
                            self?.onTranscriptionComplete?("")
                        }
                    } else {
                        NSLog("[ContentViewModel] ❌ Unexpected chat response format")
                        DispatchQueue.main.async {
                            self?.transcriptionText = "Failed to parse chat response"
                            self?.permissionStatusMessage = "Chat completion failed"
                            self?.functionCalls = []
                            self?.hasFunctionCalls = false
                            self?.onTranscriptionComplete?("")
                        }
                    }
                } else {
                    NSLog("[ContentViewModel] ❌ Invalid chat JSON response")
                    DispatchQueue.main.async {
                        self?.transcriptionText = "Invalid JSON response"
                        self?.permissionStatusMessage = "Chat completion failed"
                        self?.functionCalls = []
                        self?.hasFunctionCalls = false
                        self?.onTranscriptionComplete?("")
                    }
                }
            } catch {
                NSLog("[ContentViewModel] ❌ Chat JSON parsing error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self?.transcriptionText = "Error parsing chat response: \(error.localizedDescription)"
                    self?.permissionStatusMessage = "Chat completion failed"
                    self?.functionCalls = []
                    self?.hasFunctionCalls = false
                    self?.onTranscriptionComplete?("")
                }
            }
        }.resume()
    }
    
    func sendChatMessage(_ message: String) {
        guard !message.isEmpty else { return }
        
        // Set the current recording mode to chat completion for proper UI coloring
        currentRecordingMode = .chatCompletion
        
        // This is manual chat input (not voice-to-chat)
        isVoiceToChat = false
        
        // Add user message to conversation history
        addMessageToHistory(role: "user", content: message)
        
        // Set transcribing state to show loading
        isTranscribing = true
        permissionStatusMessage = "Sending message..."
        
        // Call the existing chat completion method
        performGPT4oChatCompletion(with: message)
    }
    
    private func addMessageToHistory(role: String, content: String) {
        let message = ChatMessage(role: role, content: content)
        conversationHistory.append(message)
        
        // Keep only the last 5 messages (maintaining context)
        if conversationHistory.count > maxConversationHistory {
            conversationHistory.removeFirst(conversationHistory.count - maxConversationHistory)
        }
        
        NSLog("[ContentViewModel] Added %@ message to history. Total messages: %d", role, conversationHistory.count)
    }
    
    func clearConversationHistory() {
        conversationHistory.removeAll()
        NSLog("[ContentViewModel] Conversation history cleared")
    }
    
    deinit {
        if audioEngine?.isRunning == true {
            audioEngine?.stop()
            inputNode?.removeTap(onBus: 0)
        }
        audioEngine = nil
        inputNode = nil
    }
}

@main
struct whispermeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var eventMonitor: EventMonitor?
    var recordingWindow: RecordingWindow?
    var toastWindow: ToastWindow?
    var viewModel: ContentViewModel!
    var hotkeyManager: HotkeyManager!
    private var statusBarManager: StatusBarManager?
    private var updateManager: SimpleUpdateManager
    
    // Prevent multiple instances and handle crashes
    private var isInitialized = false
    private var globalEventMonitors: [Any] = []
    private var isFnPressed = false  // Shared Fn key state
    private var isShiftPressed = false  // Shared Shift key state
    private var isFloatingBarEnabled = true  // Track floating bar state
    
    override init() {
        // Initialize robust update manager
        print("[WhisperMeApp] 🚀 Initializing SimpleUpdateManager...")
        updateManager = SimpleUpdateManager.shared
        print("[WhisperMeApp] ✅ SimpleUpdateManager assigned to updateManager")
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[AppDelegate] Application launching...")
        
        // Prevent multiple instances
        if isInitialized {
            print("[AppDelegate] Already initialized, preventing duplicate launch")
            return
        }
        
        // Hide dock icon (we're a menu bar app)
        NSApp.setActivationPolicy(.accessory)
        
        // Request microphone permission on launch
        requestMicrophonePermission()
        
        // Request contacts permission on launch
        requestContactsPermission()
        
        // Create the status item with better error handling
        createStatusItem()
        
        // Create view model first
        viewModel = ContentViewModel()
        viewModel.onTranscriptionComplete = { [weak self] text in
            NSLog("[AppDelegate] onTranscriptionComplete called with text: '%@', mode: %@, isVoiceToChat: %@", 
                  text, 
                  self?.viewModel.currentRecordingMode == .transcription ? "transcription" : "chatCompletion",
                  self?.viewModel.isVoiceToChat == true ? "true" : "false")
            
            // Paste text if we have text AND we're in transcription mode OR voice-to-chat mode
            if !text.isEmpty && (self?.viewModel.currentRecordingMode == .transcription || self?.viewModel.isVoiceToChat == true) {
                self?.pasteText(text)
                NSLog("[AppDelegate] Pasted transcribed text: %@", text)
            }
            
            // Ensure isTranscribing is reset (it should be reset in the view model already)
            // This ensures the floating bar returns to idle state after transcription
            DispatchQueue.main.async {
                // The window automatically updates based on viewModel.isTranscribing state
                NSLog("[AppDelegate] Transcription complete, window should return to idle state")
            }
        }
        
        // Create toast window
        toastWindow = ToastWindow(viewModel: viewModel)
        
        // Observe toast state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toastStateChanged),
            name: NSNotification.Name("ToastStateChanged"),
            object: nil
        )
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 500) // Increased size for contacts feature
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView(
            viewModel: viewModel, 
            onRestart: { [weak self] in
                self?.restartApplication()
            },
            onCheckForUpdates: { [weak self] in
                self?.checkForUpdates()
            }
        ))
        
        // Set up hotkey manager
        hotkeyManager = HotkeyManager()
        hotkeyManager.setViewModel(viewModel)
        
        // Set up hotkey callbacks
        hotkeyManager.onStartRecording = { [weak self] in
            self?.showRecordingWindow()
        }
        
        hotkeyManager.onStopRecording = { [weak self] in
            self?.stopRecordingAndTranscribe()
        }
        
        hotkeyManager.onCancelRecording = { [weak self] in
            self?.cancelRecording()
        }
        
        hotkeyManager.onRecordingModeChange = { [weak self] mode in
            // The HotkeyManager already updates the viewModel, so we don't need to do anything here
            NSLog("[AppDelegate] Recording mode changed to: %@", mode == .transcription ? "transcription" : "chatCompletion")
        }
        
        // Hotkey monitoring is already started in HotkeyManager init
        
        // Show the idle recording window immediately and keep it persistent
        showIdleRecordingWindow()
        
        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
        // Mark as initialized
        isInitialized = true
        
        // Check authentication status and redirect if not logged in
        checkAuthenticationAndRedirect()
        
        // Check for updates on startup (silently - only shows dialog if update available)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateManager.checkForUpdates(showUI: false)
        }
        
        print("[AppDelegate] ✅ Avra successfully initialized!")
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else {
            print("[AppDelegate] Invalid URL received")
            return
        }
        
        print("[AppDelegate] Received URL: \(urlString)")
        
        // Handle whisperme://connect?token=...&email=...
        if url.scheme == "whisperme", url.host == "connect" {
            handleConnectionURL(url)
        }
    }
    
    func handleConnectionURL(_ url: URL) {
        print("[AppDelegate] Handling connection URL: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            print("[AppDelegate] Invalid URL components")
            return
        }
        
        var token: String?
        var email: String?
        
        for item in queryItems {
            switch item.name {
            case "token":
                token = item.value
            case "email":
                email = item.value
            default:
                break
            }
        }
        
        guard let connectionToken = token else {
            print("[AppDelegate] No connection token found in URL")
            return
        }
        
        print("[AppDelegate] Connection token received: \(connectionToken)")
        if let userEmail = email {
            print("[AppDelegate] User email: \(userEmail)")
        }
        
        // Verify the connection token with the Next.js app
        verifyConnectionToken(connectionToken) { [weak self] success, userInfo in
            DispatchQueue.main.async {
                if success {
                    print("[AppDelegate] ✅ Connection successful!")
                    self?.handleSuccessfulConnection(userInfo)
                } else {
                    print("[AppDelegate] ❌ Connection failed")
                    self?.handleFailedConnection()
                }
            }
        }
    }
    
    func verifyConnectionToken(_ token: String, completion: @escaping (Bool, [String: Any]?) -> Void) {
        // Connect to the Next.js app's verification endpoint
        let urlString = "\(APIConstants.webAppURL)/api/auth/connect-token?token=\(token)"
        guard let url = URL(string: urlString) else {
            print("[AppDelegate] Invalid verification URL")
            completion(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[AppDelegate] Connection verification error: \(error)")
                completion(false, nil)
                return
            }
            
            guard let data = data else {
                print("[AppDelegate] No data received from verification")
                completion(false, nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let user = json["user"] as? [String: Any] {
                        print("[AppDelegate] ✅ Token verified successfully")
                        completion(true, json)
                    } else if let error = json["error"] as? String {
                        print("[AppDelegate] ❌ Token verification failed: \(error)")
                        completion(false, nil)
                    } else {
                        print("[AppDelegate] ❌ Unexpected response format")
                        completion(false, nil)
                    }
                } else {
                    print("[AppDelegate] ❌ Invalid JSON response")
                    completion(false, nil)
                }
            } catch {
                print("[AppDelegate] ❌ JSON parsing error: \(error)")
                completion(false, nil)
            }
        }.resume()
    }
    
    func handleSuccessfulConnection(_ userInfo: [String: Any]?) {
        // Store user authentication info
        if let user = userInfo?["user"] as? [String: Any],
           let userId = user["id"] as? String,
           let email = user["email"] as? String {
            
            // Store user info locally
            UserDefaults.standard.set(userId, forKey: "connected_user_id")
            UserDefaults.standard.set(email, forKey: "connected_user_email")
            UserDefaults.standard.set(true, forKey: "is_connected_to_webapp")
            
            print("[AppDelegate] ✅ User connected: \(email)")
            
            // Update the view model with the new email
            viewModel.userEmail = email
            
            // Show success notification
            showConnectionSuccessNotification(email: email)
        }
    }
    
    func handleFailedConnection() {
        // Show error notification
        showConnectionFailedNotification()
    }
    
    func showConnectionSuccessNotification(email: String) {
        let alert = NSAlert()
        alert.messageText = "Connection Successful!"
                    alert.informativeText = "Avra is now connected to your web account: \(email)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func showConnectionFailedNotification() {
        let alert = NSAlert()
        alert.messageText = "Connection Failed"
        alert.informativeText = "Unable to connect to your web account. Please try again from the web dashboard."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func checkAuthenticationAndRedirect() {
        // Check if user is already connected
        let isConnected = UserDefaults.standard.bool(forKey: "is_connected_to_webapp")
        let userEmail = UserDefaults.standard.string(forKey: "connected_user_email")
        
        if isConnected, let email = userEmail, !email.isEmpty {
            // User is already logged in, load their info
            print("[AppDelegate] ✅ User already logged in: \(email)")
            viewModel.userEmail = email
            return
        }
        
        // User is not logged in, automatically redirect to connect page
        print("[AppDelegate] ❌ User not logged in, redirecting to connect page")
        
        // Show a brief notification about the redirect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = NSAlert()
            alert.messageText = "Login Required"
            alert.informativeText = "WhisperMe requires authentication to function. You will be redirected to the login page."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Continue")
            alert.addButton(withTitle: "Quit")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // User clicked "Continue" - open the connect page
                self.openConnectPage()
            } else {
                // User clicked "Quit" - exit the app
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    func openConnectPage() {
        // Open the connect page in the default browser
        guard let url = URL(string: "\(APIConstants.webAppURL)/connect") else {
            print("[AppDelegate] ❌ Invalid connect URL")
            return
        }
        
        print("[AppDelegate] 🌐 Opening connect page: \(url)")
        NSWorkspace.shared.open(url)
    }
    
    func cleanupExistingInstances() {
        // Safely kill other whisperme processes (not the current one)
        let task = Process()
        task.launchPath = "/usr/bin/pgrep"
        task.arguments = ["-f", "whisperme"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let pids = output.components(separatedBy: .newlines).compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            
            let currentPID = ProcessInfo.processInfo.processIdentifier
            
            for pid in pids {
                if pid != Int(currentPID) {
                    // Kill other instances, not current one
                    let killTask = Process()
                    killTask.launchPath = "/bin/kill"
                    killTask.arguments = ["-9", "\(pid)"]
                    try? killTask.run()
                }
            }
            
            print("[AppDelegate] Cleaned up \(pids.count - 1) other instances")
        } catch {
            print("[AppDelegate] Cleanup process failed: \(error)")
        }
    }
    
    func createStatusItem() {
        print("[AppDelegate] Creating status item...")
        
        // Create new status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("[AppDelegate] ❌ Failed to create status item or button")
            return
        }
        
        // Configure the button with fallback options
        if let micImage = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Avra") {
            button.image = micImage
            print("[AppDelegate] ✅ Set microphone icon successfully")
        } else {
            // Fallback to text if icon fails
            button.title = "🎤"
            print("[AppDelegate] Using emoji fallback")
        }
        
        button.action = #selector(togglePopover)
        button.target = self
        
        print("[AppDelegate] ✅ Status item configured successfully")
    }
    
    // Old hotkey system removed - now using HotkeyManager
    
    func cleanupGlobalEventMonitors() {
        // Stop hotkey manager
        hotkeyManager?.cleanup()
        
        // Legacy cleanup for old system (if any monitors remain)
        for monitor in globalEventMonitors {
            NSEvent.removeMonitor(monitor)
        }
        globalEventMonitors.removeAll()
        
        // Reset key states
        isFnPressed = false
        isShiftPressed = false
        
        print("[AppDelegate] Cleaned up event monitors and reset Fn key state")
    }
    
    @objc func toastStateChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let viewModel = self.viewModel else { return }
            
            if viewModel.showToast {
                self.toastWindow?.showToast()
            } else {
                self.toastWindow?.hideToast()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("[AppDelegate] Application terminating - cleaning up...")
        
        // Clean up global event monitors
        cleanupGlobalEventMonitors()
        
        // Clean up popover event monitor
        eventMonitor?.stop()
        eventMonitor = nil
        
        // Stop any ongoing recording
        viewModel?.stopRecording()
        
        // Close recording window
        recordingWindow?.close()
        recordingWindow = nil
        
        // Close toast window
        toastWindow?.close()
        toastWindow = nil
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Remove status item
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        // Clean up view model
        viewModel = nil
        
        print("[AppDelegate] ✅ Cleanup completed")
    }
    
    func checkForUpdates() {
        NSLog("[AppDelegate] ===== CHECK FOR UPDATES CALLED =====")
        print("[AppDelegate] ===== Using Simple Update Manager with AppUpdater =====")
        
        // Use the simple update manager with AppUpdater
        updateManager.checkForUpdates(showUI: true)
        NSLog("[AppDelegate] ===== Simple Update Manager called =====")
    }
    
    func restartApplication() {
        print("[AppDelegate] Restarting application...")
        
        // Clean up current instance
        cleanupGlobalEventMonitors()
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        recordingWindow?.close()
        recordingWindow = nil
        
        // Get the app bundle path
        let appPath = Bundle.main.bundlePath
        
        // Launch new instance after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = ["-n", appPath]
            
            do {
                try task.run()
                // Quit current instance
                NSApplication.shared.terminate(nil)
            } catch {
                print("[AppDelegate] Failed to restart: \(error)")
            }
        }
    }
    
    func showIdleRecordingWindow() {
        // Create and show the persistent idle recording window
        if recordingWindow == nil {
            recordingWindow = RecordingWindow(viewModel: viewModel)
        }
        recordingWindow?.showWindow()
        
        // Enable floating bar and global hotkey monitoring
        enableFloatingBar()
    }
    
    func enableFloatingBar() {
        if !isFloatingBarEnabled {
            isFloatingBarEnabled = true
            hotkeyManager?.setupGlobalHotkey()
            print("[AppDelegate] ✅ Floating bar enabled - global hotkey monitoring active")
        }
    }
    
    func disableFloatingBar() {
        if isFloatingBarEnabled {
            isFloatingBarEnabled = false
            hotkeyManager?.cleanup()
            print("[AppDelegate] ✅ Floating bar disabled - global hotkey monitoring inactive")
        }
    }
    
    func showRecordingWindow() {
        NSLog("[AppDelegate] showRecordingWindow called")
        
        // Check if viewModel exists
        guard let viewModel = self.viewModel else {
            NSLog("[AppDelegate] ❌ ERROR: viewModel is nil!")
            return
        }
        
        // If already recording, don't start again
        if viewModel.isRecording {
            NSLog("[AppDelegate] Already recording, skipping duplicate start")
            return
        }
        
        // Make sure window is visible and start recording
        showIdleRecordingWindow()
        
        // Force window to front
        recordingWindow?.orderFrontRegardless()
        
        // Start recording with a small delay to ensure window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSLog("[AppDelegate] About to call viewModel.startRecording()")
            viewModel.startRecording()
            NSLog("[AppDelegate] Called viewModel.startRecording()")
        }
    }
    
    func hideRecordingWindow() {
        recordingWindow?.close()
        recordingWindow = nil
        
        // Disable floating bar and global hotkey monitoring
        disableFloatingBar()
    }
    
    func stopRecordingAndTranscribe() {
        NSLog("[AppDelegate] stopRecordingAndTranscribe called")
        
        // Check if viewModel exists
        guard let viewModel = self.viewModel else {
            NSLog("[AppDelegate] ❌ ERROR: viewModel is nil in stopRecordingAndTranscribe!")
            return
        }
        
        // Stop recording but keep window visible in idle state
        NSLog("[AppDelegate] About to call viewModel.stopRecording()")
        viewModel.stopRecording()
        NSLog("[AppDelegate] Called viewModel.stopRecording()")
        // Window stays visible - don't hide it
        
        // Force reset the Fn key state to prevent stuck state
        self.isFnPressed = false
        NSLog("[AppDelegate] Reset isFnPressed to false")
    }
    
    func cancelRecording() {
        NSLog("[AppDelegate] cancelRecording called")
        
        // Check if viewModel exists
        guard let viewModel = self.viewModel else {
            NSLog("[AppDelegate] ❌ ERROR: viewModel is nil in cancelRecording!")
            return
        }
        
        // Cancel recording immediately without transcription
        if viewModel.isRecording {
            NSLog("[AppDelegate] Canceling active recording")
            // Stop the audio engine immediately
            viewModel.stopRecording()
        }
        
        // If transcription is in progress, we can't stop it but reset UI state
        if viewModel.isTranscribing {
            NSLog("[AppDelegate] Transcription in progress, resetting UI state")
            DispatchQueue.main.async {
                viewModel.isTranscribing = false
                viewModel.permissionStatusMessage = "Recording canceled"
            }
        }
        
        // Reset key states
        self.isFnPressed = false
        self.isShiftPressed = false
        
        NSLog("[AppDelegate] Recording canceled successfully")
    }
    
    func pasteText(_ text: String) {
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Check if we have accessibility permissions
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptPrompt: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            print("Accessibility permissions not granted. Text copied to clipboard.")
            // Show improved alert to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = """
                Avra needs accessibility permissions to auto-paste text. 
                
                ✅ Your text has been copied to the clipboard - you can paste it with Cmd+V
                
                To enable auto-paste:
                1. Click "Open Settings" below, or go to System Settings manually
                2. Navigate to Privacy & Security → Accessibility  
                3. Click the + button if Avra isn't listed
                4. Navigate to Applications folder and select Avra
                5. Turn on the toggle for Avra
                
                Note: You may need to quit and restart Avra after granting permission.
                """
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "OK")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // Try multiple methods to open accessibility settings
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Method 1: macOS 13+ System Settings
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            if NSWorkspace.shared.open(url) {
                                return
                            }
                        }
                        
                        // Method 2: Try older format
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                            if NSWorkspace.shared.open(url) {
                                return
                            }
                        }
                        
                        // Method 3: Open System Settings directly
                        NSWorkspace.shared.launchApplication("System Settings")
                    }
                }
            }
            return
        }
        
        // Simulate Cmd+V to paste with a small delay to ensure focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let source = CGEventSource(stateID: .combinedSessionState)
            source?.localEventsSuppressionInterval = 0.0
            
            // Create and post key down event
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
                keyDown.flags = .maskCommand
                keyDown.post(tap: .cghidEventTap)
            }
            
            // Create and post key up event
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                keyUp.flags = .maskCommand
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }
    
    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let strongSelf = self, strongSelf.popover.isShown {
                    strongSelf.closePopover()
                }
            }
            eventMonitor?.start()
        }
    }
    
    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
        eventMonitor = nil
    }
    
    private func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("Microphone access already granted.")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Microphone access granted.")
                } else {
                    print("Microphone access denied.")
                }
            }
        case .denied:
            print("Microphone access previously denied.")
        case .restricted:
            print("Microphone access restricted.")
        @unknown default:
            print("Unknown microphone authorization status.")
        }
    }
    
    private func requestContactsPermission() {
        let store = CNContactStore()
        
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            print("Contacts access already granted.")
            // Trigger contacts fetch in view model if already granted
            DispatchQueue.main.async {
                if let viewModel = self.viewModel {
                    viewModel.checkContactsPermissionAndFetch()
                }
            }
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, error in
                if granted {
                    print("Contacts access granted.")
                    // Trigger contacts fetch in view model
                    DispatchQueue.main.async {
                        if let viewModel = self.viewModel {
                            viewModel.checkContactsPermissionAndFetch()
                        }
                    }
                } else {
                    print("Contacts access denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        case .denied:
            print("Contacts access previously denied.")
        case .restricted:
            print("Contacts access restricted.")
        @unknown default:
            print("Unknown contacts authorization status.")
        }
    }
}

// MenuBarView is now in Views/MenuBarView.swift

// Settings view is now in Views/SettingsView.swift

// Toast window is now in Views/ToastView.swift

// Recording window
class RecordingWindow: NSWindow {
    let viewModel: ContentViewModel
    private var hoverTimer: Timer?
    private var isDragging = false
    var isExpanded = false
    private var isHovering = false
    private var dragStartLocation: NSPoint = .zero
    private var windowStartLocation: NSPoint = .zero
    private var trackingArea: NSTrackingArea?
    private var originalCenterPosition: NSPoint = .zero
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 70),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        
        // Allow window to receive mouse events
        self.acceptsMouseMovedEvents = true
        
        // Show on all desktops/fullscreen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Position at bottom center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 300
            let windowHeight: CGFloat = 70
            let bottomMargin: CGFloat = 40
            
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.minY + bottomMargin
            
            self.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }
        
        // Set content view
        let hostingView = DraggableHostingView(rootView: RecordingView(viewModel: viewModel))
        hostingView.recordingWindow = self
        self.contentView = hostingView
        
        // Set up mouse tracking
        setupMouseTracking()
        
        // Observe recording state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordingStateChanged),
            name: .init("RecordingStateChanged"),
            object: nil
        )
    }
    
    func setupMouseTracking() {
        if let trackingArea = trackingArea {
            self.contentView?.removeTrackingArea(trackingArea)
        }
        
        trackingArea = NSTrackingArea(
            rect: self.contentView?.bounds ?? .zero,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        
        if let trackingArea = trackingArea {
            self.contentView?.addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHovering = true
        if !isExpanded {
            startHoverExpansion()
        }
        updateCursor()
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovering = false
        if !isExpanded {
            cancelHoverExpansion()
        }
        updateCursor()
    }
    
    override func mouseMoved(with event: NSEvent) {
        updateCursor()
    }
    
    func updateCursor() {
        if isExpanded {
            // When expanded as chat input, use normal cursor to allow text editing
            NSCursor.arrow.set()
        } else if isDragging {
            NSCursor.closedHand.set()
        } else if isHovering {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }
    
    func startHoverExpansion() {
        hoverTimer?.invalidate()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            self?.enableHoverExpansion()
        }
    }
    
    func cancelHoverExpansion() {
        hoverTimer?.invalidate()
        hoverTimer = nil
        disableHoverExpansion()
    }
    
    func enableHoverExpansion() {
        guard !isDragging else { return }
        
        let currentFrame = self.frame
        let scaleFactor: CGFloat = 1.05
        let newSize = NSSize(
            width: currentFrame.width * scaleFactor,
            height: currentFrame.height * scaleFactor
        )
        let newOrigin = NSPoint(
            x: currentFrame.origin.x - (newSize.width - currentFrame.width) / 2,
            y: currentFrame.origin.y - (newSize.height - currentFrame.height) / 2
        )
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(newFrame, display: true)
        }
    }
    
    func disableHoverExpansion() {
        guard !isDragging else { return }
        
        let currentFrame = self.frame
        let scaleFactor: CGFloat = 1.0 / 1.05
        let newSize = NSSize(
            width: currentFrame.width * scaleFactor,
            height: currentFrame.height * scaleFactor
        )
        let newOrigin = NSPoint(
            x: currentFrame.origin.x + (currentFrame.width - newSize.width) / 2,
            y: currentFrame.origin.y + (currentFrame.height - newSize.height) / 2
        )
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().setFrame(newFrame, display: true)
        }
    }
    
    @objc private func recordingStateChanged() {
        // Could adjust window size here if needed for different states
    }
    
    override var canBecomeKey: Bool {
        return isExpanded // Only allow becoming key window when expanded for text input
    }
    
    override var acceptsFirstResponder: Bool {
        return isExpanded
    }
    
    func showWindow() {
        self.makeKeyAndOrderFront(nil)
        self.orderFrontRegardless()
        setupMouseTracking()
    }
    
    func startDragging(at location: NSPoint) {
        isDragging = true
        dragStartLocation = location
        windowStartLocation = self.frame.origin
        
        // Visual feedback for dragging
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            self.animator().alphaValue = 0.9
        }
        updateCursor()
    }
    
    func stopDragging() {
        isDragging = false
        
        // Restore normal appearance
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1.0
        }
        updateCursor()
    }
    
    func handleMouseDrag(to location: NSPoint) {
        guard isDragging else { return }
        
        let deltaX = location.x - dragStartLocation.x
        let deltaY = location.y - dragStartLocation.y
        
        let newOrigin = NSPoint(
            x: windowStartLocation.x + deltaX,
            y: windowStartLocation.y + deltaY
        )
        
        self.setFrameOrigin(newOrigin)
    }
    
    func handleQuickClick() {
        toggleExpanded()
    }
    
    func toggleExpanded() {
        let wasExpanded = isExpanded
        isExpanded.toggle()
        
        // Store or use the original center position
        if !wasExpanded {
            // When expanding, store the current center as the original position
            let currentFrame = self.frame
            originalCenterPosition = NSPoint(x: currentFrame.midX, y: currentFrame.midY)
        }
        
        // Use the original center position for both expand and collapse
        let centerX = originalCenterPosition.x
        let centerY = originalCenterPosition.y
        
        // Animate the expansion/collapse
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            if isExpanded {
                // Expand to larger size for chat interface, keeping original center position
                let newWidth: CGFloat = 400
                let newHeight: CGFloat = 130
                let newFrame = NSRect(
                    x: centerX - newWidth / 2,
                    y: centerY - newHeight / 2,
                    width: newWidth,
                    height: newHeight
                )
                self.animator().setFrame(newFrame, display: true)
                self.animator().alphaValue = 0.95
            } else {
                // Collapse back to original size, using original center position
                let newWidth: CGFloat = 300
                let newHeight: CGFloat = 70
                let newFrame = NSRect(
                    x: centerX - newWidth / 2,
                    y: centerY - newHeight / 2,
                    width: newWidth,
                    height: newHeight
                )
                self.animator().setFrame(newFrame, display: true)
                self.animator().alphaValue = 1.0
            }
        }
        
        // Update content with a slight delay to ensure smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateContentForExpanded()
            
            // Make window key and focus text field when expanded
            if self.isExpanded {
                self.makeKeyAndOrderFront(nil)
                // Additional delay to ensure the view is ready for focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.makeFirstResponder(self.contentView)
                }
            }
        }
        
        // Set up global click monitoring when expanded
        if isExpanded {
            setupGlobalClickMonitoring()
        } else {
            removeGlobalClickMonitoring()
        }
    }
    
    private var globalClickMonitor: Any?
    
    private func setupGlobalClickMonitoring() {
        removeGlobalClickMonitoring()
        
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Get the click location in screen coordinates
            let clickLocation = NSEvent.mouseLocation
            
            // Check if click is outside our window
            if !self.frame.contains(clickLocation) {
                // Collapse the expanded view
                DispatchQueue.main.async {
                    if self.isExpanded {
                        self.toggleExpanded()
                    }
                }
            }
        }
    }
    
    private func removeGlobalClickMonitoring() {
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }
    
    func updateContentForExpanded() {
        if let hostingView = self.contentView as? DraggableHostingView {
            if isExpanded {
                hostingView.rootView = AnyView(CompactChatView(viewModel: viewModel, recordingWindow: self))
            } else {
                hostingView.rootView = AnyView(RecordingView(viewModel: viewModel))
            }
        }
    }
    
    deinit {
        hoverTimer?.invalidate()
        removeGlobalClickMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
}

// Custom hosting view to handle drag interactions
class DraggableHostingView: NSHostingView<AnyView> {
    weak var recordingWindow: RecordingWindow?
    private var mouseDownTime: Date?
    private var mouseDownLocation: NSPoint = .zero
    
    override var acceptsFirstResponder: Bool {
        return recordingWindow?.isExpanded ?? false
    }
    
    init(rootView: some View) {
        super.init(rootView: AnyView(rootView))
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor required init(rootView: AnyView) {
        super.init(rootView: rootView)
    }
    
    override func mouseDown(with event: NSEvent) {
        mouseDownTime = Date()
        mouseDownLocation = event.locationInWindow
        
        // Only enable dragging if window is not expanded (not in chat input mode)
        if let window = recordingWindow, !window.isExpanded {
            // Convert to screen coordinates for dragging
            let screenLocation = self.window?.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin ?? .zero
            recordingWindow?.startDragging(at: screenLocation)
        }
        
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Only allow dragging if window is not expanded
        if let window = recordingWindow, !window.isExpanded {
            // Convert to screen coordinates
            let screenLocation = self.window?.convertToScreen(NSRect(origin: event.locationInWindow, size: .zero)).origin ?? .zero
            recordingWindow?.handleMouseDrag(to: screenLocation)
        }
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        defer {
            recordingWindow?.stopDragging()
            mouseDownTime = nil
        }
        
        // Check if this was a quick click (less than 0.3 seconds and minimal movement)
        if let downTime = mouseDownTime {
            let clickDuration = Date().timeIntervalSince(downTime)
            let currentLocation = event.locationInWindow
            let dragDistance = sqrt(pow(currentLocation.x - mouseDownLocation.x, 2) + pow(currentLocation.y - mouseDownLocation.y, 2))
            
            // Only handle quick clicks for toggling when not already expanded
            // or when expanded and clicking outside the input area
            if clickDuration < 0.3 && dragDistance < 10 {
                if let window = recordingWindow {
                    if !window.isExpanded {
                        // Not expanded, so expand it
                        recordingWindow?.handleQuickClick()
                    }
                    // If expanded, let the global click monitor handle collapsing
                }
            }
        }
        
        super.mouseUp(with: event)
    }
}

// backgroundColorForMode function is now in Views/RecordingViews.swift

// Recording view
// Recording views are now in Views/RecordingViews.swift

// Toast view is now in Views/ToastView.swift

// Toast container is now in Views/ToastView.swift

// Event monitor is now in Managers/WindowManager.swift

// FunctionCallRow is now in Views/MenuBarView.swift

