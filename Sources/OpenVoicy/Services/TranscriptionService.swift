import Foundation

enum TranscriptionError: LocalizedError {
    case invalidApiKey
    case fileTooLarge
    case fileTooShort
    case networkError(String)
    case apiError(String)
    case invalidResponse
    case encodingError
    case modelNotReady
    case localWhisperError(String)

    var errorDescription: String? {
        switch self {
        case .invalidApiKey:
            "Invalid or missing API key"
        case .fileTooLarge:
            "Audio file too large (max 25MB for OpenAI)"
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
        case .modelNotReady:
            "Whisper model not downloaded"
        case let .localWhisperError(msg):
            "Local Whisper error: \(msg)"
        }
    }
}

struct TranscriptionResponse: Decodable {
    let text: String
}

class TranscriptionService {
    static let shared = TranscriptionService()

    private let apiUrl = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let settings = SettingsManager.shared

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        switch self.settings.transcriptionProvider {
        case .openAI:
            try await self.transcribeWithOpenAI(audioFileURL: audioFileURL, language: language)
        case .localWhisper:
            try await self.transcribeWithLocalWhisper(audioFileURL: audioFileURL, language: language)
        }
    }

    // MARK: - Local Whisper Transcription

    private func transcribeWithLocalWhisper(audioFileURL: URL, language: String?) async throws -> String {
        guard self.settings.isLocalWhisperReady else {
            throw TranscriptionError.modelNotReady
        }

        do {
            return try await LocalWhisperService.shared.transcribe(
                audioFileURL: audioFileURL,
                language: language)
        } catch let error as LocalWhisperError {
            throw TranscriptionError.localWhisperError(error.localizedDescription)
        } catch {
            throw TranscriptionError.localWhisperError(error.localizedDescription)
        }
    }

    // MARK: - OpenAI API Transcription

    private func transcribeWithOpenAI(audioFileURL: URL, language: String?) async throws -> String {
        guard let apiKey = settings.apiKey as String?, !apiKey.isEmpty else {
            throw TranscriptionError.invalidApiKey
        }

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            throw TranscriptionError.encodingError
        }

        if audioData.count > 25 * 1024 * 1024 {
            throw TranscriptionError.fileTooLarge
        }

        if audioData.count < 100 {
            throw TranscriptionError.fileTooShort
        }

        var request = URLRequest(url: apiUrl)
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
            throw TranscriptionError.networkError("Invalid response type")
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            if httpResponse.statusCode == 401 {
                throw TranscriptionError.invalidApiKey
            }
            throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        do {
            let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            return result.text
        } catch {
            throw TranscriptionError.invalidResponse
        }
    }
}
