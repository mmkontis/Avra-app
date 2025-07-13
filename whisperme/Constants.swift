import Foundation

// MARK: - Language Constants
struct LanguageConstants {
    static let supportedLanguages: [(code: String, name: String)] = [
        ("auto", "Auto-detect"),
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("zh", "Chinese"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("nl", "Dutch"),
        ("sv", "Swedish"),
        ("da", "Danish"),
        ("no", "Norwegian"),
        ("fi", "Finnish"),
        ("pl", "Polish"),
        ("tr", "Turkish"),
        ("cs", "Czech"),
        ("hu", "Hungarian"),
        ("ro", "Romanian"),
        ("bg", "Bulgarian"),
        ("hr", "Croatian"),
        ("sk", "Slovak"),
        ("sl", "Slovenian"),
        ("et", "Estonian"),
        ("lv", "Latvian"),
        ("lt", "Lithuanian"),
        ("uk", "Ukrainian"),
        ("el", "Greek"),
        ("he", "Hebrew"),
        ("th", "Thai"),
        ("vi", "Vietnamese"),
        ("id", "Indonesian"),
        ("ms", "Malay"),
        ("tl", "Filipino"),
        ("fa", "Persian"),
        ("bn", "Bengali"),
        ("ur", "Urdu"),
        ("ta", "Tamil"),
        ("te", "Telugu"),
        ("ml", "Malayalam"),
        ("kn", "Kannada"),
        ("gu", "Gujarati"),
        ("pa", "Punjabi"),
        ("mr", "Marathi"),
        ("ne", "Nepali"),
        ("si", "Sinhala"),
        ("my", "Myanmar"),
        ("km", "Khmer"),
        ("lo", "Lao"),
        ("ka", "Georgian"),
        ("am", "Amharic"),
        ("sw", "Swahili"),
        ("yo", "Yoruba"),
        ("zu", "Zulu"),
        ("af", "Afrikaans"),
        ("sq", "Albanian"),
        ("az", "Azerbaijani"),
        ("be", "Belarusian"),
        ("bs", "Bosnian"),
        ("eu", "Basque"),
        ("gl", "Galician"),
        ("is", "Icelandic"),
        ("ga", "Irish"),
        ("mk", "Macedonian"),
        ("mt", "Maltese"),
        ("cy", "Welsh"),
        ("hy", "Armenian"),
        ("lb", "Luxembourgish"),
        ("fo", "Faroese"),
        ("br", "Breton")
    ]
    
    static let translationLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("zh", "Chinese"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("nl", "Dutch"),
        ("sv", "Swedish"),
        ("da", "Danish"),
        ("no", "Norwegian"),
        ("fi", "Finnish"),
        ("pl", "Polish"),
        ("tr", "Turkish"),
        ("cs", "Czech"),
        ("hu", "Hungarian"),
        ("ro", "Romanian"),
        ("bg", "Bulgarian"),
        ("hr", "Croatian"),
        ("sk", "Slovak"),
        ("sl", "Slovenian"),
        ("et", "Estonian"),
        ("lv", "Latvian"),
        ("lt", "Lithuanian"),
        ("uk", "Ukrainian"),
        ("el", "Greek"),
        ("he", "Hebrew"),
        ("th", "Thai"),
        ("vi", "Vietnamese"),
        ("id", "Indonesian"),
        ("ms", "Malay"),
        ("tl", "Filipino"),
        ("fa", "Persian"),
        ("bn", "Bengali"),
        ("ur", "Urdu"),
        ("ta", "Tamil"),
        ("te", "Telugu"),
        ("ml", "Malayalam"),
        ("kn", "Kannada"),
        ("gu", "Gujarati"),
        ("pa", "Punjabi"),
        ("mr", "Marathi"),
        ("ne", "Nepali"),
        ("si", "Sinhala"),
        ("my", "Myanmar"),
        ("km", "Khmer"),
        ("lo", "Lao"),
        ("ka", "Georgian"),
        ("am", "Amharic"),
        ("sw", "Swahili"),
        ("yo", "Yoruba"),
        ("zu", "Zulu"),
        ("af", "Afrikaans"),
        ("sq", "Albanian"),
        ("az", "Azerbaijani"),
        ("be", "Belarusian"),
        ("bs", "Bosnian"),
        ("eu", "Basque"),
        ("gl", "Galician"),
        ("is", "Icelandic"),
        ("ga", "Irish"),
        ("mk", "Macedonian"),
        ("mt", "Maltese"),
        ("cy", "Welsh"),
        ("hy", "Armenian")
    ]
}

// MARK: - Model Constants
struct ModelConstants {
    static let availableModels: [(code: String, name: String, description: String)] = [
        ("gpt-4o-transcribe", "GPT-4o Transcribe", "Latest, highest quality"),
        ("gpt-4o-mini-transcribe", "GPT-4o Mini Transcribe", "Faster, more cost-effective")
    ]
    
    static let transcriptionModels = [
        "gpt-4o-transcribe",
        "gpt-4o-mini-transcribe"
    ]
    
    static let chatModels = [
        "gpt-4o",
        "gpt-4o-mini"
    ]
}

// MARK: - API Constants
struct APIConstants {
    static let baseURL = "https://whisperme-piih0.sevalla.app"
    static let webAppURL = "https://hireavra.com"
    static let endpoints = [
        "transcribe": "/transcribe",
        "chat": "/chat",
        "functions": "/functions",
        "register": "/register",
        "login": "/login",
        "profile": "/user/profile",
        "upgrade": "/upgrade"
    ]
}

// MARK: - UI Constants
struct UIConstants {
    static let windowSizes = [
        "popover": (width: 340.0, height: 500.0),
        "recording": (width: 300.0, height: 70.0),
        "toast": (width: 400.0, height: 100.0)
    ]
    
    static let margins = [
        "popover": 20.0,
        "recording": 40.0,
        "toast": 20.0
    ]
    
    static let animationDurations = [
        "toast": 3.0,
        "fade": 0.3,
        "spring": 0.5
    ]
}

// MARK: - Default Values
struct DefaultValues {
    static let selectedLanguage = "auto"
    static let selectedModel = "gpt-4o-transcribe"
    static let selectedTranslationLanguage = "en"
    static let customPrompt = ""
    static let privacyModeEnabled = true
    static let realTimePreviewEnabled = false
    static let translationEnabled = false
    static let autoStartEnabled = false
    static let enableFunctions = true
    static let chatModeEnabled = false
}

// MARK: - UserDefaults Keys
struct UserDefaultsKeys {
    static let isPremiumUser = "isPremiumUser"
    static let realTimePreviewEnabled = "realTimePreviewEnabled"
    static let privacyModeEnabled = "privacyModeEnabled"
    static let selectedLanguage = "selectedLanguage"
    static let selectedModel = "selectedModel"
    static let customPrompt = "customPrompt"
    static let translationEnabled = "translationEnabled"
    static let selectedTranslationLanguage = "selectedTranslationLanguage"
    static let autoStartEnabled = "autoStartEnabled"
    static let enableFunctions = "enableFunctions"
    static let chatModeEnabled = "chatModeEnabled"
}

// MARK: - Notification Names
struct NotificationNames {
    static let recordingStateChanged = "RecordingStateChanged"
    static let toastStateChanged = "ToastStateChanged"
}

// MARK: - System Constants
struct SystemConstants {
    static let appBundleIdentifier = "humanlike.whisperme"
    static let urlScheme = "whisperme"
    static let audioFormat = [
        "sampleRate": 44100.0,
        "channels": 1,
        "bitDepth": 16
    ]
} 