import AppKit
import Foundation
import os.log

/// A file-based logger that writes logs to a file for easier debugging.
/// Also forwards logs to os.log for Console.app viewing.
class FileLogger {
    static let shared = FileLogger()

    private let systemLogger: Logger
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.speakeasy.filelogger", qos: .utility)
    private let dateFormatter: DateFormatter
    private let maxFileSize: Int64 = 5_000_000 // 5 MB

    static var logsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SpeakEasy", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
    }

    private init() {
        self.systemLogger = Logger(subsystem: "com.speakeasy", category: "App")

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Create logs directory
        let logsDir = FileLogger.logsDirectory
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        // Use a dated log file
        let logDateFormatter = DateFormatter()
        logDateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = logDateFormatter.string(from: Date())
        self.fileURL = logsDir.appendingPathComponent("speakeasy-\(dateString).log")

        // Clean up old log files (keep last 7 days)
        self.cleanupOldLogs()

        // Write startup marker
        self.writeToFile("═══════════════════════════════════════════════════════════════")
        self.writeToFile("  SpeakEasy Started - \(self.dateFormatter.string(from: Date()))")
        self.writeToFile("═══════════════════════════════════════════════════════════════")
    }

    private func cleanupOldLogs() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: FileLogger.logsDirectory,
            includingPropertiesForKeys: [.creationDateKey])
        else {
            return
        }

        let logFiles = files.filter { $0.pathExtension == "log" }
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        for file in logFiles {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
               creationDate < cutoffDate
            {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    private func writeToFile(_ message: String) {
        self.queue.async { [weak self] in
            guard let self else { return }

            let line = message + "\n"

            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.fileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: fileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        try? handle.close()
                    }
                } else {
                    try? data.write(to: self.fileURL, options: .atomic)
                }
            }
        }
    }

    private func log(_ level: String, category: String, message: String) {
        let timestamp = self.dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(level)] [\(category)] \(message)"
        self.writeToFile(formattedMessage)
    }

    // MARK: - Public Logging Methods

    func info(_ message: String, category: String = "App") {
        self.log("INFO", category: category, message: message)
        self.systemLogger.info("\(message)")
    }

    func debug(_ message: String, category: String = "App") {
        self.log("DEBUG", category: category, message: message)
        self.systemLogger.debug("\(message)")
    }

    func warning(_ message: String, category: String = "App") {
        self.log("WARN", category: category, message: message)
        self.systemLogger.warning("\(message)")
    }

    func error(_ message: String, category: String = "App") {
        self.log("ERROR", category: category, message: message)
        self.systemLogger.error("\(message)")
    }

    // MARK: - Category-specific loggers

    func whisper(_ message: String) {
        self.log("INFO", category: "Whisper", message: message)
        self.systemLogger.info("[\("Whisper")] \(message)")
    }

    func transcription(_ message: String) {
        self.log("INFO", category: "Transcription", message: message)
        self.systemLogger.info("[\("Transcription")] \(message)")
    }

    func audio(_ message: String) {
        self.log("INFO", category: "Audio", message: message)
        self.systemLogger.info("[\("Audio")] \(message)")
    }

    // MARK: - File Access

    func openLogFile() {
        NSWorkspace.shared.open(self.fileURL)
    }

    func revealLogsInFinder() {
        NSWorkspace.shared.selectFile(self.fileURL.path, inFileViewerRootedAtPath: Self.logsDirectory.path)
    }
}
