import Combine
import Foundation

class WhisperModelManager: NSObject, ObservableObject {
    static let shared = WhisperModelManager()

    private let fileManager = FileManager.default

    @Published var downloadStatus: [WhisperModel: ModelDownloadStatus] = [:]
    @Published private(set) var isDownloading = false
    @Published private(set) var currentlyDownloadingModel: WhisperModel?

    private var downloadTask: URLSessionDownloadTask?
    private var downloadSession: URLSession?
    private var downloadingModel: WhisperModel?

    private override init() {
        super.init()
        for model in WhisperModel.allCases {
            downloadStatus[model] = isModelDownloaded(model) ? .downloaded : .notDownloaded
        }
    }

    // MARK: - Directory Management

    var modelsDirectory: URL {
        let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("OpenVoicy", isDirectory: true)
            .appendingPathComponent("Models", isDirectory: true)
    }

    func ensureModelsDirectoryExists() throws {
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            try fileManager.createDirectory(
                at: modelsDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    func modelPath(for model: WhisperModel) -> URL {
        modelsDirectory.appendingPathComponent(model.fileName)
    }

    func isModelDownloaded(_ model: WhisperModel) -> Bool {
        fileManager.fileExists(atPath: modelPath(for: model).path)
    }

    // MARK: - Download Management

    func downloadModel(_ model: WhisperModel) {
        guard !isDownloading else { return }

        do {
            try ensureModelsDirectoryExists()
        } catch {
            DispatchQueue.main.async {
                self.downloadStatus[model] = .error("Failed to create directory: \(error.localizedDescription)")
            }
            return
        }

        isDownloading = true
        currentlyDownloadingModel = model
        downloadingModel = model
        downloadStatus[model] = .downloading(progress: 0)

        let config = URLSessionConfiguration.default
        downloadSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        downloadTask = downloadSession?.downloadTask(with: model.downloadURL)
        downloadTask?.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadSession?.invalidateAndCancel()
        downloadSession = nil

        if let model = downloadingModel {
            downloadStatus[model] = .notDownloaded
        }
        downloadingModel = nil
        currentlyDownloadingModel = nil
        isDownloading = false
    }

    func deleteModel(_ model: WhisperModel) throws {
        let path = modelPath(for: model)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
        downloadStatus[model] = .notDownloaded
    }

    func totalDownloadedSize() -> Int64 {
        var total: Int64 = 0
        for model in WhisperModel.allCases {
            if isModelDownloaded(model) {
                total += model.sizeBytes
            }
        }
        return total
    }

    func refreshDownloadStatus() {
        for model in WhisperModel.allCases {
            if case .downloading = downloadStatus[model] {
                continue
            }
            downloadStatus[model] = isModelDownloaded(model) ? .downloaded : .notDownloaded
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension WhisperModelManager: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let model = downloadingModel else { return }

        do {
            let destinationURL = modelPath(for: model)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)

            downloadStatus[model] = .downloaded
        } catch {
            downloadStatus[model] = .error("Failed to save: \(error.localizedDescription)")
        }

        cleanupDownload()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let model = downloadingModel else { return }

        let progress: Double
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            // Fallback to estimated size if server doesn't provide content length
            progress = Double(totalBytesWritten) / Double(model.sizeBytes)
        }

        downloadStatus[model] = .downloading(progress: min(progress, 1.0))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let model = downloadingModel else { return }

        if let error = error as? URLError, error.code == .cancelled {
            downloadStatus[model] = .notDownloaded
        } else if let error = error {
            downloadStatus[model] = .error(error.localizedDescription)
        }

        cleanupDownload()
    }

    private func cleanupDownload() {
        downloadTask = nil
        downloadSession?.finishTasksAndInvalidate()
        downloadSession = nil
        downloadingModel = nil
        currentlyDownloadingModel = nil
        isDownloading = false
    }
}

enum WhisperModelError: LocalizedError {
    case downloadInProgress
    case downloadFailed(String)
    case modelNotFound

    var errorDescription: String? {
        switch self {
        case .downloadInProgress:
            return "A download is already in progress"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .modelNotFound:
            return "Model file not found"
        }
    }
}
