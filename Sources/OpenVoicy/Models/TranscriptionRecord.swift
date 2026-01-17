import Foundation
import SwiftData

public enum TranscriptionStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

@Model
public final class TranscriptionRecord {
    @Attribute(.unique) public var id: UUID

    public var text: String
    public var createdAt: Date
    public var updatedAt: Date
    public var audioFileName: String?
    public var wordCount: Int
    public var durationSeconds: Double?
    public var language: String?
    public var transcriptionStatus: TranscriptionStatus
    public var providerRawValue: String?
    public var modelName: String?
    public var transcriptionTimeSeconds: Double?

    public var provider: TranscriptionProvider? {
        get { providerRawValue.flatMap { TranscriptionProvider(rawValue: $0) } }
        set { providerRawValue = newValue?.rawValue }
    }

    public init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        audioFileName: String? = nil,
        durationSeconds: Double? = nil,
        language: String? = nil,
        transcriptionStatus: TranscriptionStatus = .completed,
        provider: TranscriptionProvider? = nil,
        modelName: String? = nil,
        transcriptionTimeSeconds: Double? = nil
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
        self.providerRawValue = provider?.rawValue
        self.modelName = modelName
        self.transcriptionTimeSeconds = transcriptionTimeSeconds
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
