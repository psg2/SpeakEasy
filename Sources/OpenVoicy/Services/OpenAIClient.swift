import Foundation

enum OpenAIError: LocalizedError {
    case invalidApiKey
    case fileTooLarge
    case fileTooShort
    case networkError(String)
    case apiError(String)
    case invalidResponse
    case encodingError

    var errorDescription: String? {
        switch self {
        case .invalidApiKey:
            "Invalid or missing API key"
        case .fileTooLarge:
            "Audio file too large (max 25MB)"
        case .fileTooShort:
            "Audio recording too short"
        case let .networkError(msg):
            "Network error: \(msg)"
        case let .apiError(msg):
            "API error: \(msg)"
        case .invalidResponse:
            "Invalid response from server"
        case .encodingError:
            "Failed to encode audio"
        }
    }
}

class OpenAIClient {
    static let shared = OpenAIClient()

    private let baseURL = "https://api.openai.com/v1"

    // MARK: - API Key Validation

    func validateApiKey(_ apiKey: String) async throws {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidApiKey
        }

        let url = URL(string: "\(self.baseURL)/models")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError("Invalid response type")
        }

        if httpResponse.statusCode == 401 {
            throw OpenAIError.invalidApiKey
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
        }
    }

    // MARK: - Transcription

    func transcribe(audioData: Data, language: String?, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.invalidApiKey
        }

        if audioData.count > 25 * 1024 * 1024 {
            throw OpenAIError.fileTooLarge
        }

        if audioData.count < 100 {
            throw OpenAIError.fileTooShort
        }

        let url = URL(string: "\(self.baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8))
        body.append(Data("whisper-1\r\n".utf8))

        if let language, !language.isEmpty {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"language\"\r\n\r\n".utf8))
            body.append(Data("\(language)\r\n".utf8))
        }

        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".utf8))
        body.append(Data("Content-Type: audio/wav\r\n\r\n".utf8))
        body.append(audioData)
        body.append(Data("\r\n".utf8))

        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.networkError("Invalid response type")
        }

        if httpResponse.statusCode == 401 {
            throw OpenAIError.invalidApiKey
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        struct TranscriptionResponse: Decodable {
            let text: String
        }

        do {
            let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            return result.text
        } catch {
            throw OpenAIError.invalidResponse
        }
    }
}
