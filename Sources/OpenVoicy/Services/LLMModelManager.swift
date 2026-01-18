import AppKit
import Combine
import Foundation
import Hub

private let log = FileLogger.shared

/// Manages MLX LLM model downloads and status
@MainActor
class LLMModelManager: ObservableObject {
    static let shared = LLMModelManager()

    private let fileManager = FileManager.default

    // Download status for each model (by model ID)
    @Published var downloadStatus: [String: LLMStatus] = [:]
    @Published private(set) var isDownloading = false
    @Published private(set) var currentlyDownloadingModelId: String?
    @Published var downloadProgress: Double = 0.0

    private var downloadTask: Task<Void, Never>?

    // Default model directory (similar to HuggingFace cache)
    private var modelsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/hub/models--mlx-community")
    }

    private init() {
        refreshAllDownloadStatus()
    }

    // MARK: - Model Status

    /// Get the download status for a model
    func getStatus(for model: LLMModel) -> LLMStatus {
        getStatus(for: model.modelId)
    }

    /// Get the download status for a model ID
    func getStatus(for modelId: String) -> LLMStatus {
        downloadStatus[modelId] ?? .notDownloaded
    }

    /// Check if a model is downloaded
    func isModelDownloaded(_ model: LLMModel) -> Bool {
        isModelDownloaded(model.modelId)
    }

    /// Check if a model ID is downloaded
    func isModelDownloaded(_ modelId: String) -> Bool {
        guard case .downloaded = getStatus(for: modelId) else {
            return false
        }
        return true
    }

    /// Synchronous check for model download status (for use in computed properties)
    nonisolated static func isModelDownloadedSync(_ modelId: String) -> Bool {
        let fileManager = FileManager.default
        let modelsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/hub/models--mlx-community")
        let modelPath = modelsDirectory.appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "--"))
        return fileManager.fileExists(atPath: modelPath.path)
    }

    /// Refresh download status for all recommended models
    func refreshAllDownloadStatus() {
        for model in LLMModel.allCases {
            let isDownloaded = checkModelExists(model.modelId)
            downloadStatus[model.modelId] = isDownloaded ? .downloaded : .notDownloaded
        }
    }

    /// Check if model files exist locally
    private func checkModelExists(_ modelId: String) -> Bool {
        // Check if the model directory exists in the HuggingFace cache
        let modelPath = modelsDirectory.appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "--"))
        return fileManager.fileExists(atPath: modelPath.path)
    }

    // MARK: - Model Download

    /// Download a model using HuggingFace Hub API
    func downloadModel(_ model: LLMModel) {
        downloadModel(model.modelId)
    }

    /// Download a model by ID
    func downloadModel(_ modelId: String) {
        // Cancel any existing download
        cancelDownload()

        isDownloading = true
        currentlyDownloadingModelId = modelId
        downloadStatus[modelId] = .downloading(progress: 0.0)

        downloadTask = Task {
            do {
                log.info("Starting download of LLM model: \(modelId)")

                let hub = HubApi()

                // Download model files with progress tracking
                _ = try await hub.snapshot(
                    from: modelId,
                    matching: ["*.safetensors", "config.json", "tokenizer*", "*.json"]
                ) { [weak self] progress in
                    guard let self else { return }
                    Task { @MainActor in
                        self.downloadProgress = progress.fractionCompleted
                        self.downloadStatus[modelId] = .downloading(progress: progress.fractionCompleted)
                    }
                }

                await MainActor.run {
                    self.downloadStatus[modelId] = .downloaded
                    self.isDownloading = false
                    self.currentlyDownloadingModelId = nil
                    log.info("Successfully downloaded LLM model: \(modelId)")
                }
            } catch {
                await MainActor.run {
                    self.downloadStatus[modelId] = .error(error.localizedDescription)
                    self.isDownloading = false
                    self.currentlyDownloadingModelId = nil
                    log.error("Failed to download LLM model \(modelId): \(error.localizedDescription)")
                }
            }
        }
    }

    /// Cancel the current download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        if let modelId = currentlyDownloadingModelId {
            downloadStatus[modelId] = .notDownloaded
        }

        isDownloading = false
        currentlyDownloadingModelId = nil
        downloadProgress = 0.0
    }

    // MARK: - Model Management

    /// Delete a downloaded model
    func deleteModel(_ model: LLMModel) throws {
        try deleteModel(model.modelId)
    }

    /// Delete a model by ID
    func deleteModel(_ modelId: String) throws {
        let modelPath = modelsDirectory.appendingPathComponent(modelId.replacingOccurrences(of: "/", with: "--"))

        guard fileManager.fileExists(atPath: modelPath.path) else {
            log.warning("Cannot delete model \(modelId): not found")
            return
        }

        try fileManager.removeItem(at: modelPath)
        downloadStatus[modelId] = .notDownloaded
        log.info("Deleted LLM model: \(modelId)")
    }

    /// Get model size description
    func getModelSizeDescription(_ model: LLMModel) -> String {
        model.sizeDescription
    }

    /// Get model size description by ID
    func getModelSizeDescription(_ modelId: String) -> String {
        // Try to find the model in our enum
        if let model = LLMModel.allCases.first(where: { $0.modelId == modelId }) {
            return model.sizeDescription
        }
        return "Unknown size"
    }

    /// Open the models folder in Finder
    func openModelsFolder() {
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: modelsDirectory.path)
    }
}
