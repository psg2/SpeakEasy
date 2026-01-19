import AppKit
import Foundation

class AudioStorageManager {
    static let shared = AudioStorageManager()

    private let fileManager = FileManager.default
    private let audioDirectoryName = "Recordings"

    private init() {}

    var appSupportDirectory: URL {
        let appSupport = self.fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SpeakEasy", isDirectory: true)
    }

    var recordingsDirectory: URL {
        self.appSupportDirectory.appendingPathComponent(self.audioDirectoryName, isDirectory: true)
    }

    func ensureDirectoryExists() throws {
        if !self.fileManager.fileExists(atPath: self.recordingsDirectory.path) {
            try self.fileManager.createDirectory(
                at: self.recordingsDirectory,
                withIntermediateDirectories: true)
        }
    }

    func generateFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())
        let shortUUID = UUID().uuidString.prefix(8)
        return "recording_\(dateString)_\(shortUUID).wav"
    }

    func saveAudio(from temporaryURL: URL) throws -> String {
        try self.ensureDirectoryExists()

        let fileName = self.generateFileName()
        let destinationURL = self.recordingsDirectory.appendingPathComponent(fileName)

        try self.fileManager.copyItem(at: temporaryURL, to: destinationURL)

        return fileName
    }

    func audioURL(for fileName: String) -> URL {
        self.recordingsDirectory.appendingPathComponent(fileName)
    }

    func deleteAudio(fileName: String) throws {
        let url = self.audioURL(for: fileName)
        if self.fileManager.fileExists(atPath: url.path) {
            try self.fileManager.removeItem(at: url)
        }
    }

    func revealInFinder(fileName: String) {
        let url = self.audioURL(for: fileName)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func audioFileExists(fileName: String) -> Bool {
        let url = self.audioURL(for: fileName)
        return self.fileManager.fileExists(atPath: url.path)
    }

    func cleanupOrphanedFiles(validFileNames: Set<String>) throws {
        try self.ensureDirectoryExists()

        let contents = try fileManager.contentsOfDirectory(
            at: self.recordingsDirectory,
            includingPropertiesForKeys: nil)

        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            if !validFileNames.contains(fileName) {
                try self.fileManager.removeItem(at: fileURL)
            }
        }
    }

    func totalStorageUsed() throws -> Int64 {
        try self.ensureDirectoryExists()

        let contents = try fileManager.contentsOfDirectory(
            at: self.recordingsDirectory,
            includingPropertiesForKeys: [.fileSizeKey])

        var totalSize: Int64 = 0
        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues.fileSize ?? 0)
        }

        return totalSize
    }
}
