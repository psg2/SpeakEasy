import AppKit
import Combine
import Foundation
import WhisperKit

private let log = FileLogger.shared

/// Manages WhisperKit model downloads and status
@MainActor
class WhisperModelManager: ObservableObject {
    static let shared = WhisperModelManager()

    private let fileManager = FileManager.default

    // Dynamic models fetched from HuggingFace
    @Published var availableModels: [WhisperKitModel] = []
    @Published var isLoadingModels = false
    @Published var modelLoadError: String?

    // Download status for each model (by model ID)
    @Published var downloadStatus: [String: ModelDownloadStatus] = [:]
    @Published private(set) var isDownloading = false
    @Published private(set) var currentlyDownloadingModelId: String?

    // Actual model sizes fetched from HuggingFace (by model ID)
    @Published var modelSizes: [String: Int64] = [:]

    private var downloadTask: Task<Void, Never>?

    // Recommended models to show by default (curated list)
    static let recommendedModelIds = [
        "openai_whisper-tiny",
        "openai_whisper-base",
        "openai_whisper-small",
        "openai_whisper-medium",
        "openai_whisper-large-v3_turbo"
    ]

    private init() {
        // Start with recommended models
        availableModels = Self.recommendedModelIds.map { WhisperKitModel(id: $0) }
        refreshAllDownloadStatus()

        // Fetch full list from HuggingFace in background
        Task {
            await fetchAvailableModels()
        }
    }

    // MARK: - Fetch Models from HuggingFace

    func fetchAvailableModels() async {
        isLoadingModels = true
        modelLoadError = nil

        do {
            // Fetch recursive tree to get all files with sizes
            let url = URL(string: "https://huggingface.co/api/models/argmaxinc/whisperkit-coreml/tree/main?recursive=true")!
            let (data, _) = try await URLSession.shared.data(from: url)

            // Parse the JSON response
            if let items = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var modelSet = Set<String>()
                var sizes: [String: Int64] = [:]

                for item in items {
                    guard let path = item["path"] as? String else { continue }

                    // Extract top-level model directory
                    let components = path.split(separator: "/")
                    guard let modelId = components.first.map(String.init),
                          modelId.contains("whisper") else { continue }

                    modelSet.insert(modelId)

                    // Sum file sizes for each model
                    if let type = item["type"] as? String, type == "file" {
                        // Use LFS size if available (for large files), otherwise regular size
                        let fileSize: Int64
                        if let lfs = item["lfs"] as? [String: Any],
                           let lfsSize = lfs["size"] as? Int64 {
                            fileSize = lfsSize
                        } else if let size = item["size"] as? Int64 {
                            fileSize = size
                        } else if let size = item["size"] as? Int {
                            fileSize = Int64(size)
                        } else {
                            continue
                        }
                        sizes[modelId, default: 0] += fileSize
                    }
                }

                // Store actual sizes
                modelSizes = sizes

                // Create model objects
                var models = modelSet.map { WhisperKitModel(id: $0) }

                // Sort models: recommended first, then by size (smaller first)
                models.sort { a, b in
                    let aRecommended = Self.recommendedModelIds.contains(a.id)
                    let bRecommended = Self.recommendedModelIds.contains(b.id)

                    if aRecommended && !bRecommended { return true }
                    if !aRecommended && bRecommended { return false }

                    // Both recommended or both not - sort by actual size
                    let aSize = sizes[a.id] ?? a.estimatedSizeBytes
                    let bSize = sizes[b.id] ?? b.estimatedSizeBytes
                    return aSize < bSize
                }

                availableModels = models
                log.info("Fetched \(models.count) models from HuggingFace with actual sizes")

                // Refresh download status for all models
                refreshAllDownloadStatus()
            }
        } catch {
            log.error("Failed to fetch models: \(error.localizedDescription)")
            modelLoadError = error.localizedDescription
            // Keep using recommended models as fallback
        }

        isLoadingModels = false
    }

    /// Get the actual size for a model (from HuggingFace API) or fall back to estimate
    func getModelSize(_ modelId: String) -> Int64 {
        modelSizes[modelId] ?? WhisperKitModel(id: modelId).estimatedSizeBytes
    }

    /// Get formatted size string for a model
    func getModelSizeDescription(_ modelId: String) -> String {
        let size = getModelSize(modelId)
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - WhisperKit Cache Directory

    var whisperKitCacheDirectory: URL {
        // WhisperKit stores models in ~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml", isDirectory: true)
    }

    var modelsDirectory: URL {
        whisperKitCacheDirectory
    }

    func modelPath(for modelId: String) -> URL {
        whisperKitCacheDirectory.appendingPathComponent(modelId)
    }

    func isModelDownloaded(_ modelId: String) -> Bool {
        let modelDir = modelPath(for: modelId)
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: modelDir.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                let contents = try? fileManager.contentsOfDirectory(atPath: modelDir.path)
                return (contents?.count ?? 0) > 0
            }
        }
        return false
    }

    // MARK: - Status Management

    func refreshAllDownloadStatus() {
        for model in availableModels {
            if case .downloading = downloadStatus[model.id] {
                continue
            }
            downloadStatus[model.id] = isModelDownloaded(model.id) ? .downloaded : .notDownloaded
        }
    }

    func getStatus(for modelId: String) -> ModelDownloadStatus {
        downloadStatus[modelId] ?? (isModelDownloaded(modelId) ? .downloaded : .notDownloaded)
    }

    // MARK: - Download Management

    func downloadModel(_ modelId: String) {
        guard !isDownloading else {
            log.warning("Download already in progress")
            return
        }

        isDownloading = true
        currentlyDownloadingModelId = modelId
        downloadStatus[modelId] = .downloading(progress: 0)

        log.info("Starting download for model: \(modelId)")

        downloadTask = Task {
            do {
                // Animate progress while downloading
                let progressTask = Task {
                    var progress = 0.0
                    while !Task.isCancelled && progress < 0.95 {
                        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s
                        progress = min(0.95, progress + 0.05)
                        await MainActor.run {
                            if case .downloading = self.downloadStatus[modelId] {
                                self.downloadStatus[modelId] = .downloading(progress: progress)
                            }
                        }
                    }
                }

                // Initialize WhisperKit which triggers the download
                log.info("Initializing WhisperKit to trigger download...")
                let _ = try await WhisperKit(
                    model: modelId,
                    verbose: false,
                    logLevel: .none
                )

                progressTask.cancel()

                log.info("Model downloaded successfully: \(modelId)")
                await MainActor.run {
                    self.downloadStatus[modelId] = .downloaded
                    self.isDownloading = false
                    self.currentlyDownloadingModelId = nil
                }
            } catch {
                log.error("Failed to download model: \(error.localizedDescription)")
                await MainActor.run {
                    self.downloadStatus[modelId] = .error(error.localizedDescription)
                    self.isDownloading = false
                    self.currentlyDownloadingModelId = nil
                }
            }
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil

        if let modelId = currentlyDownloadingModelId {
            downloadStatus[modelId] = .notDownloaded
        }

        currentlyDownloadingModelId = nil
        isDownloading = false
    }

    func deleteModel(_ modelId: String) throws {
        let path = modelPath(for: modelId)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
            log.info("Deleted model: \(modelId)")
        }
        downloadStatus[modelId] = .notDownloaded
    }

    func openModelsFolder() {
        let url = whisperKitCacheDirectory
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }

    // MARK: - Legacy Support

    // For compatibility with the existing WhisperModel enum
    func isModelDownloaded(_ model: WhisperModel) -> Bool {
        isModelDownloaded(model.whisperKitName)
    }

    func downloadModel(_ model: WhisperModel) {
        downloadModel(model.whisperKitName)
    }

    func deleteModel(_ model: WhisperModel) throws {
        try deleteModel(model.whisperKitName)
    }

    func getStatus(for model: WhisperModel) -> ModelDownloadStatus {
        getStatus(for: model.whisperKitName)
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
