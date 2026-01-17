import AppKit
import Foundation

class AudioStorageManager {
    static let shared = AudioStorageManager()

    private let fileManager = FileManager.default
    private let audioDirectoryName = "Recordings"

    private init() {}

    var appSupportDirectory: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appendingPathComponent("OpenVoicy", isDirectory: true)
    }

    var recordingsDirectory: URL {
        appSupportDirectory.appendingPathComponent(audioDirectoryName, isDirectory: true)
    }

    func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: recordingsDirectory.path) {
            try fileManager.createDirectory(
                at: recordingsDirectory,
                withIntermediateDirectories: true
            )
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
        try ensureDirectoryExists()

        let fileName = generateFileName()
        let destinationURL = recordingsDirectory.appendingPathComponent(fileName)

        try fileManager.copyItem(at: temporaryURL, to: destinationURL)

        return fileName
    }

    func audioURL(for fileName: String) -> URL {
        recordingsDirectory.appendingPathComponent(fileName)
    }

    func deleteAudio(fileName: String) throws {
        let url = audioURL(for: fileName)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func revealInFinder(fileName: String) {
        let url = audioURL(for: fileName)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func audioFileExists(fileName: String) -> Bool {
        let url = audioURL(for: fileName)
        return fileManager.fileExists(atPath: url.path)
    }

    func cleanupOrphanedFiles(validFileNames: Set<String>) throws {
        try ensureDirectoryExists()

        let contents = try fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: nil
        )

        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            if !validFileNames.contains(fileName) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }

    func totalStorageUsed() throws -> Int64 {
        try ensureDirectoryExists()

        let contents = try fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )

        var totalSize: Int64 = 0
        for fileURL in contents {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            totalSize += Int64(resourceValues.fileSize ?? 0)
        }

        return totalSize
    }
}
