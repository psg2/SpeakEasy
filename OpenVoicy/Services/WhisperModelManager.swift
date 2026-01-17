import Combine
import Foundation

class WhisperModelManager: ObservableObject {
    static let shared = WhisperModelManager()

    private let fileManager = FileManager.default

    @Published var downloadStatus: [WhisperModel: ModelDownloadStatus] = [:]
    @Published private(set) var isDownloading = false

    private var currentDownloadTask: Task<Void, Never>?

    private init() {
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

        currentDownloadTask = Task {
            await performDownload(model)
        }
    }

    @MainActor
    private func performDownload(_ model: WhisperModel) async {
        isDownloading = true
        downloadStatus[model] = .downloading(progress: 0)

        do {
            try ensureModelsDirectoryExists()

            let (asyncBytes, response) = try await URLSession.shared.bytes(from: model.downloadURL)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                throw WhisperModelError.downloadFailed("Server returned an error")
            }

            let expectedLength = response.expectedContentLength
            let tempURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".bin")

            fileManager.createFile(atPath: tempURL.path, contents: nil)
            let fileHandle = try FileHandle(forWritingTo: tempURL)

            var downloadedBytes: Int64 = 0
            let bufferSize = 1024 * 1024
            var buffer = Data()
            buffer.reserveCapacity(bufferSize)

            for try await byte in asyncBytes {
                buffer.append(byte)

                if buffer.count >= bufferSize {
                    try fileHandle.write(contentsOf: buffer)
                    downloadedBytes += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)

                    if expectedLength > 0 {
                        let progress = Double(downloadedBytes) / Double(expectedLength)
                        downloadStatus[model] = .downloading(progress: progress)
                    }
                }
            }

            if !buffer.isEmpty {
                try fileHandle.write(contentsOf: buffer)
            }

            try fileHandle.close()

            let destinationURL = modelPath(for: model)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: tempURL, to: destinationURL)

            downloadStatus[model] = .downloaded
            isDownloading = false

        } catch is CancellationError {
            downloadStatus[model] = .notDownloaded
            isDownloading = false
        } catch {
            downloadStatus[model] = .error(error.localizedDescription)
            isDownloading = false
        }
    }

    func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
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
