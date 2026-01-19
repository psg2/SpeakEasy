import AppKit
import Combine
import Foundation

private let log = FileLogger.shared

/// Manages LLM model downloads and status (GGUF format)
@MainActor
class LLMModelManager: ObservableObject {
    static let shared = LLMModelManager()

    private let fileManager = FileManager.default

    // Download status for each model
    @Published var downloadStatus: [LLMModel: LLMStatus] = [:]
    @Published private(set) var isDownloading = false
    @Published private(set) var currentlyDownloadingModel: LLMModel?
    @Published var downloadProgress: Double = 0.0

    private var downloadTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?

    // Models directory
    var modelsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("SpeakEasy/LLMModels", isDirectory: true)
    }

    private init() {
        // Ensure models directory exists
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        refreshAllDownloadStatus()
    }

    // MARK: - Model Paths

    /// Get the local file path for a model
    func modelPath(for model: LLMModel) -> URL {
        modelsDirectory.appendingPathComponent(model.fileName)
    }

    // MARK: - Model Status

    /// Get the download status for a model
    func getStatus(for model: LLMModel) -> LLMStatus {
        downloadStatus[model] ?? .notDownloaded
    }

    /// Check if a model is downloaded
    func isModelDownloaded(_ model: LLMModel) -> Bool {
        fileManager.fileExists(atPath: modelPath(for: model).path)
    }

    /// Synchronous check for model download status (for use in computed properties)
    nonisolated static func isModelDownloadedSync(_ model: LLMModel) -> Bool {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let modelsDirectory = appSupport.appendingPathComponent("SpeakEasy/LLMModels", isDirectory: true)
        let modelPath = modelsDirectory.appendingPathComponent(model.fileName)
        return fileManager.fileExists(atPath: modelPath.path)
    }

    /// Refresh download status for all models
    func refreshAllDownloadStatus() {
        for model in LLMModel.allCases {
            downloadStatus[model] = isModelDownloaded(model) ? .downloaded : .notDownloaded
        }
    }

    // MARK: - Model Download

    /// Download a model from HuggingFace
    func downloadModel(_ model: LLMModel) {
        // Cancel any existing download
        cancelDownload()

        isDownloading = true
        currentlyDownloadingModel = model
        downloadStatus[model] = .downloading(progress: 0.0)
        downloadProgress = 0.0

        log.info("Starting download of LLM model: \(model.displayName)")
        log.info("URL: \(model.downloadURL)")

        let destinationURL = modelPath(for: model)

        // Create download task
        let session = URLSession(configuration: .default)
        downloadTask = session.downloadTask(with: model.downloadURL) { [weak self] tempURL, response, error in
            Task { @MainActor [weak self] in
                guard let self else { return }

                if let error {
                    self.downloadStatus[model] = .error(error.localizedDescription)
                    self.isDownloading = false
                    self.currentlyDownloadingModel = nil
                    log.error("Failed to download model: \(error.localizedDescription)")
                    return
                }

                guard let tempURL else {
                    self.downloadStatus[model] = .error("No file downloaded")
                    self.isDownloading = false
                    self.currentlyDownloadingModel = nil
                    return
                }

                do {
                    // Remove existing file if present
                    if self.fileManager.fileExists(atPath: destinationURL.path) {
                        try self.fileManager.removeItem(at: destinationURL)
                    }

                    // Move downloaded file to destination
                    try self.fileManager.moveItem(at: tempURL, to: destinationURL)

                    self.downloadStatus[model] = .downloaded
                    self.isDownloading = false
                    self.currentlyDownloadingModel = nil
                    self.downloadProgress = 1.0
                    log.info("Successfully downloaded model: \(model.displayName)")
                } catch {
                    self.downloadStatus[model] = .error(error.localizedDescription)
                    self.isDownloading = false
                    self.currentlyDownloadingModel = nil
                    log.error("Failed to save model: \(error.localizedDescription)")
                }
            }
        }

        // Observe download progress
        observation = downloadTask?.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.downloadProgress = progress.fractionCompleted
                self.downloadStatus[model] = .downloading(progress: progress.fractionCompleted)
            }
        }

        downloadTask?.resume()
    }

    /// Cancel the current download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        observation?.invalidate()
        observation = nil

        if let model = currentlyDownloadingModel {
            downloadStatus[model] = .notDownloaded
        }

        isDownloading = false
        currentlyDownloadingModel = nil
        downloadProgress = 0.0
    }

    // MARK: - Model Management

    /// Delete a downloaded model
    func deleteModel(_ model: LLMModel) throws {
        let path = modelPath(for: model)

        guard fileManager.fileExists(atPath: path.path) else {
            log.warning("Cannot delete model \(model.displayName): not found")
            return
        }

        try fileManager.removeItem(at: path)
        downloadStatus[model] = .notDownloaded
        log.info("Deleted LLM model: \(model.displayName)")
    }

    /// Open the models folder in Finder
    func openModelsFolder() {
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: modelsDirectory.path)
    }
}
