import AppKit
import Foundation
import os.log

/// A file-based logger that writes logs to a file for easier debugging.
/// Also forwards logs to os.log for Console.app viewing.
class FileLogger {
    static let shared = FileLogger()

    private let systemLogger: Logger
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.openvoicy.filelogger", qos: .utility)
    private let dateFormatter: DateFormatter
    private let maxFileSize: Int64 = 5_000_000 // 5 MB

    static var logsDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("OpenVoicy", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
    }

    private init() {
        self.systemLogger = Logger(subsystem: "com.openvoicy", category: "App")

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Create logs directory
        let logsDir = FileLogger.logsDirectory
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        // Use a dated log file
        let logDateFormatter = DateFormatter()
        logDateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = logDateFormatter.string(from: Date())
        fileURL = logsDir.appendingPathComponent("openvoicy-\(dateString).log")

        // Clean up old log files (keep last 7 days)
        cleanupOldLogs()

        // Write startup marker
        writeToFile("═══════════════════════════════════════════════════════════════")
        writeToFile("  OpenVoicy Started - \(dateFormatter.string(from: Date()))")
        writeToFile("═══════════════════════════════════════════════════════════════")
    }

    private func cleanupOldLogs() {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: FileLogger.logsDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        let logFiles = files.filter { $0.pathExtension == "log" }
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        for file in logFiles {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[FileAttributeKey.creationDate] as? Date,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    private func writeToFile(_ message: String) {
        queue.async { [weak self] in
            guard let self else { return }

            let line = message + "\n"

            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: fileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        try? handle.close()
                    }
                } else {
                    try? data.write(to: fileURL, options: .atomic)
                }
            }
        }
    }

    private func log(_ level: String, category: String, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let formattedMessage = "[\(timestamp)] [\(level)] [\(category)] \(message)"
        writeToFile(formattedMessage)
    }

    // MARK: - Public Logging Methods

    func info(_ message: String, category: String = "App") {
        log("INFO", category: category, message: message)
        systemLogger.info("\(message)")
    }

    func debug(_ message: String, category: String = "App") {
        log("DEBUG", category: category, message: message)
        systemLogger.debug("\(message)")
    }

    func warning(_ message: String, category: String = "App") {
        log("WARN", category: category, message: message)
        systemLogger.warning("\(message)")
    }

    func error(_ message: String, category: String = "App") {
        log("ERROR", category: category, message: message)
        systemLogger.error("\(message)")
    }

    // MARK: - Category-specific loggers

    func whisper(_ message: String) {
        log("INFO", category: "Whisper", message: message)
        systemLogger.info("[\("Whisper")] \(message)")
    }

    func transcription(_ message: String) {
        log("INFO", category: "Transcription", message: message)
        systemLogger.info("[\("Transcription")] \(message)")
    }

    func audio(_ message: String) {
        log("INFO", category: "Audio", message: message)
        systemLogger.info("[\("Audio")] \(message)")
    }

    // MARK: - File Access

    func openLogFile() {
        NSWorkspace.shared.open(fileURL)
    }

    func revealLogsInFinder() {
        NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: Self.logsDirectory.path)
    }
}
