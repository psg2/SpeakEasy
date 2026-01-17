import Foundation
import SwiftData

enum TranscriptionStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

@Model
final class TranscriptionRecord {
    @Attribute(.unique) var id: UUID

    var text: String
    var createdAt: Date
    var updatedAt: Date
    var audioFileName: String?
    var wordCount: Int
    var durationSeconds: Double?
    var language: String?
    var transcriptionStatus: TranscriptionStatus

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        audioFileName: String? = nil,
        durationSeconds: Double? = nil,
        language: String? = nil,
        transcriptionStatus: TranscriptionStatus = .completed
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.audioFileName = audioFileName
        self.wordCount = Self.calculateWordCount(text)
        self.durationSeconds = durationSeconds
        self.language = language
        self.transcriptionStatus = transcriptionStatus
    }

    static func calculateWordCount(_ text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    func updateText(_ newText: String) {
        self.text = newText
        self.wordCount = Self.calculateWordCount(newText)
        self.updatedAt = Date()
    }
}
