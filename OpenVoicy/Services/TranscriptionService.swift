import Foundation

enum TranscriptionError: Error {
    case invalidApiKey
    case fileTooLarge
    case fileTooShort
    case networkError(String)
    case apiError(String)
    case invalidResponse
    case encodingError
}

struct TranscriptionResponse: Decodable {
    let text: String
}

class TranscriptionService {
    static let shared = TranscriptionService()

    private let apiUrl = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    func transcribe(audioFileURL: URL, language: String? = nil) async throws -> String {
        guard let apiKey = SettingsManager.shared.apiKey as String?, !apiKey.isEmpty else {
            throw TranscriptionError.invalidApiKey
        }

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            throw TranscriptionError.encodingError
        }

        // 25MB limit
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

        // Model
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8))
        body.append(Data("whisper-1\r\n".utf8))

        // Language
        if let language = language, !language.isEmpty {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"language\"\r\n\r\n".utf8))
            body.append(Data("\(language)\r\n".utf8))
        }

        // File
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
