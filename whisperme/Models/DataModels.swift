import Foundation
import SwiftUI

// MARK: - Recording Mode
enum RecordingMode {
    case transcription  // Normal transcription mode (Fn key)
    case chatCompletion // Chat completion mode (Fn + Shift)
    
    var displayName: String {
        switch self {
        case .transcription:
            return "Transcription"
        case .chatCompletion:
            return "Chat"
        }
    }
    
    var description: String {
        switch self {
        case .transcription:
            return "Audio transcription using gpt-4o-transcribe"
        case .chatCompletion:
            return "Chat completion using GPT-4o"
        }
    }
}

// MARK: - Toast Type
enum ToastType {
    case info
    case success
    case warning
    case error
    case functionCall
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .functionCall:
            return "gear.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .functionCall:
            return .purple
        }
    }
}

// MARK: - Contact Model
struct ContactInfo: Identifiable, Hashable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let phoneNumber: String
    
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    var formattedPhoneNumber: String {
        // Format phone number for display
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if cleaned.count == 10 {
            let areaCode = String(cleaned.prefix(3))
            let firstThree = String(cleaned.dropFirst(3).prefix(3))
            let lastFour = String(cleaned.suffix(4))
            return "(\(areaCode)) \(firstThree)-\(lastFour)"
        } else if cleaned.count == 11 && cleaned.hasPrefix("1") {
            let areaCode = String(cleaned.dropFirst().prefix(3))
            let firstThree = String(cleaned.dropFirst(4).prefix(3))
            let lastFour = String(cleaned.suffix(4))
            return "+1 (\(areaCode)) \(firstThree)-\(lastFour)"
        } else {
            return phoneNumber
        }
    }
}

// MARK: - Function Call Model
struct FunctionCall: Identifiable, Codable {
    let id = UUID()
    let name: String
    let arguments: [String: Any]
    var result: String?
    var status: String = "pending" // pending, executing, completed, failed
    
    var displayName: String {
        switch name {
        case "get_current_weather":
            return "🌤️ Weather"
        case "search_web":
            return "🔍 Web Search"
        case "get_current_time":
            return "🕐 Time"
        case "calculate":
            return "🧮 Calculate"
        case "call_phone_number":
            return "📞 Call"
        default:
            return "⚙️ \(name)"
        }
    }
    
    var argumentsDisplay: String {
        var parts: [String] = []
        for (key, value) in arguments {
            parts.append("\(key): \(value)")
        }
        return parts.joined(separator: ", ")
    }
    
    enum CodingKeys: String, CodingKey {
        case name, arguments, result, status
    }
    
    init(name: String, arguments: [String: Any], result: String? = nil, status: String = "pending") {
        self.name = name
        self.arguments = arguments
        self.result = result
        self.status = status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        status = try container.decode(String.self, forKey: .status)
        
        // Decode arguments as [String: Any]
        let argumentsContainer = try container.nestedContainer(keyedBy: DynamicKey.self, forKey: .arguments)
        var decodedArguments: [String: Any] = [:]
        
        for key in argumentsContainer.allKeys {
            if let stringValue = try? argumentsContainer.decode(String.self, forKey: key) {
                decodedArguments[key.stringValue] = stringValue
            } else if let intValue = try? argumentsContainer.decode(Int.self, forKey: key) {
                decodedArguments[key.stringValue] = intValue
            } else if let doubleValue = try? argumentsContainer.decode(Double.self, forKey: key) {
                decodedArguments[key.stringValue] = doubleValue
            } else if let boolValue = try? argumentsContainer.decode(Bool.self, forKey: key) {
                decodedArguments[key.stringValue] = boolValue
            }
        }
        arguments = decodedArguments
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encode(status, forKey: .status)
        
        // Encode arguments as [String: Any]
        var argumentsContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .arguments)
        for (key, value) in arguments {
            let codingKey = DynamicKey(stringValue: key)!
            if let stringValue = value as? String {
                try argumentsContainer.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try argumentsContainer.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try argumentsContainer.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try argumentsContainer.encode(boolValue, forKey: codingKey)
            }
        }
    }
}

// Helper for dynamic coding keys
struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case role, content, timestamp
    }
}