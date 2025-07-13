import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://whisperme-piih0.sevalla.app"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Transcription API
    func transcribeAudio(
        audioURL: URL,
        language: String = "auto",
        model: String = "gpt-4o-transcribe",
        customPrompt: String = "",
        translationEnabled: Bool = false,
        translationLanguage: String = "en"
    ) async throws -> TranscriptionResponse {
        
        let url = URL(string: "\(baseURL)/transcribe")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = try createMultipartBody(
            audioURL: audioURL,
            language: language,
            model: model,
            customPrompt: customPrompt,
            translationEnabled: translationEnabled,
            translationLanguage: translationLanguage,
            boundary: boundary
        )
        
        request.httpBody = httpBody
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcriptionResponse
    }
    
    // MARK: - Chat Completion API
    func chatCompletion(
        message: String,
        model: String = "gpt-4o",
        enableFunctions: Bool = false
    ) async throws -> ChatResponse {
        
        let url = URL(string: "\(baseURL)/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(
            message: message,
            model: model,
            enable_functions: enableFunctions
        )
        
        let requestData = try JSONEncoder().encode(chatRequest)
        request.httpBody = requestData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        return chatResponse
    }
    
    // MARK: - Functions API
    func getAvailableFunctions() async throws -> [FunctionDefinition] {
        let url = URL(string: "\(baseURL)/functions")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let functionsResponse = try JSONDecoder().decode(FunctionsResponse.self, from: data)
        return functionsResponse.functions
    }
    
    // MARK: - Database Operations
    func createTranscriptionRecord(
        transcription: String,
        translation: String? = nil,
        language: String,
        model: String,
        customPrompt: String? = nil,
        screenContext: String? = nil,
        screenContextParam: String? = nil
    ) async throws {
        
        let url = URL(string: "\(baseURL)/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let transcriptionRecord = TranscriptionRecord(
            transcription: transcription,
            translation: translation,
            language: language,
            model: model,
            custom_prompt: customPrompt,
            screen_context: screenContext,
            screen_context_param: screenContextParam
        )
        
        let requestData = try JSONEncoder().encode(transcriptionRecord)
        request.httpBody = requestData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Helper Methods
    private func createMultipartBody(
        audioURL: URL,
        language: String,
        model: String,
        customPrompt: String,
        translationEnabled: Bool,
        translationLanguage: String,
        boundary: String
    ) throws -> Data {
        
        var body = Data()
        
        // Add audio file
        let audioData = try Data(contentsOf: audioURL)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add form fields
        let fields = [
            "language": language,
            "model": model,
            "custom_prompt": customPrompt,
            "translation_enabled": String(translationEnabled),
            "translation_language": translationLanguage
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

// MARK: - API Models
struct ChatRequest: Codable {
    let message: String
    let model: String
    let enable_functions: Bool
}

struct ChatResponse: Codable {
    let response: String
    let function_calls: [FunctionCall]?
}

struct TranscriptionResponse: Codable {
    let transcription: String
    let translation: String?
    let language: String
}

struct TranscriptionRecord: Codable {
    let transcription: String
    let translation: String?
    let language: String
    let model: String
    let custom_prompt: String?
    let screen_context: String?
    let screen_context_param: String?
}

struct FunctionDefinition: Codable {
    let name: String
    let description: String
    let parameters: [String: Any]
    
    private enum CodingKeys: String, CodingKey {
        case name, description, parameters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        
        // Handle parameters as a generic dictionary
        if let parametersData = try? container.decode(Data.self, forKey: .parameters) {
            parameters = try JSONSerialization.jsonObject(with: parametersData) as? [String: Any] ?? [:]
        } else {
            parameters = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        
        let parametersData = try JSONSerialization.data(withJSONObject: parameters)
        try container.encode(parametersData, forKey: .parameters)
    }
}

struct FunctionsResponse: Codable {
    let functions: [FunctionDefinition]
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
} 