import SwiftUI

struct ProvidersSettingsView: View {
    @ObservedObject var modelManager: WhisperModelManager
    @Binding var selectedProvider: TranscriptionProvider
    @Binding var apiKey: String
    @Binding var selectedModel: WhisperModel
    @Binding var selectedModelId: String
    @Binding var showAllModels: Bool
    @Binding var showApiKey: Bool
    @Binding var isValidatingApiKey: Bool
    @Binding var apiKeyValidationResult: ApiKeyValidationResult?

    var body: some View {
        VStack(spacing: 20) {
            SettingsCard("Transcription Provider") {
                VStack(spacing: 12) {
                    ForEach(TranscriptionProvider.allCases, id: \.self) { provider in
                        self.providerOption(provider)
                    }
                }
            }

            if self.selectedProvider == .openAI {
                self.openAISettings
            } else {
                self.localWhisperSettings
            }
        }
    }

    private func providerOption(_ provider: TranscriptionProvider) -> some View {
        Button(action: { self.selectedProvider = provider }) {
            HStack {
                Image(systemName: self.selectedProvider == provider ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(self.selectedProvider == provider ? .accentColor : .secondary)
                    .font(.title3)

                Image(systemName: provider.icon)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if provider == .openAI, !self.apiKey.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else if provider == .localWhisper, self.modelManager.isModelDownloaded(self.selectedModel) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(self.selectedProvider == provider ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        self.selectedProvider == provider ? Color.accentColor : Color.secondary.opacity(0.2),
                        lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var openAISettings: some View {
        SettingsCard("OpenAI API") {
            SettingsRow(
                title: "API Key",
                description: "Your OpenAI API key for Whisper transcription")
            {
                HStack(spacing: 8) {
                    Group {
                        if self.showApiKey {
                            TextField("sk-...", text: self.$apiKey)
                        } else {
                            SecureField("sk-...", text: self.$apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onChange(of: self.apiKey) {
                        self.apiKeyValidationResult = nil
                    }

                    Button(action: { self.showApiKey.toggle() }) {
                        Image(systemName: self.showApiKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(self.showApiKey ? "Hide API key" : "Show API key")
                }
            }

            if !self.apiKey.isEmpty {
                HStack {
                    if let result = self.apiKeyValidationResult {
                        switch result {
                        case .success:
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connection successful")
                                .font(.caption)
                                .foregroundColor(.green)
                        case let .failure(message):
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("API key not validated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if self.isValidatingApiKey {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Validating...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button(action: self.validateApiKey) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield")
                                Text("Validate")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private func validateApiKey() {
        self.isValidatingApiKey = true
        self.apiKeyValidationResult = nil

        Task {
            do {
                try await OpenAIClient.shared.validateApiKey(self.apiKey)
                await MainActor.run {
                    self.isValidatingApiKey = false
                    self.apiKeyValidationResult = .success
                }
            } catch {
                await MainActor.run {
                    self.isValidatingApiKey = false
                    self.apiKeyValidationResult = .failure(error.localizedDescription)
                }
            }
        }
    }

    private var localWhisperSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Model Selection")
                    .font(.headline)

                Spacer()

                if self.modelManager.isLoadingModels {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button(action: { self.modelManager.openModelsFolder() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                        Text("Show in Finder")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                // Recommended models (always shown)
                VStack(spacing: 8) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        self.modelOption(model)
                    }
                }

                // Toggle to show all models
                Divider()

                Button(action: { withAnimation { self.showAllModels.toggle() } }) {
                    HStack {
                        Text(self
                            .showAllModels ? "Hide additional models" :
                            "Show all \(self.modelManager.availableModels.count) models")
                            .font(.caption)
                        Image(systemName: self.showAllModels ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)

                // Additional models (from HuggingFace)
                if self.showAllModels {
                    VStack(spacing: 8) {
                        ForEach(self.additionalModels) { model in
                            self.dynamicModelOption(model)
                        }
                    }
                }

                if let error = currentModelError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.06))
            .cornerRadius(10)
        }
    }

    /// Models from HuggingFace that aren't in the recommended list
    private var additionalModels: [WhisperKitModel] {
        let recommendedIds = Set(WhisperModel.allCases.map(\.whisperKitName))
        return self.modelManager.availableModels.filter { !recommendedIds.contains($0.id) }
    }

    private var currentModelError: String? {
        if case let .error(message) = modelManager.getStatus(for: selectedModel) {
            return message
        }
        return nil
    }

    private func modelOption(_ model: WhisperModel) -> some View {
        let isSelected = self.selectedModelId == model.whisperKitName
        return Button(action: {
            self.selectedModel = model
            self.selectedModelId = model.whisperKitName
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(self.modelManager.getModelSizeDescription(model.whisperKitName))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(model.qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                self.modelActionButton(for: model.whisperKitName)
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func dynamicModelOption(_ model: WhisperKitModel) -> some View {
        let isSelected = self.selectedModelId == model.id
        return Button(action: {
            self.selectedModelId = model.id
            // Clear enum selection since we're using a dynamic model
            self.selectedModel = .base // Reset to default, but we'll use selectedModelId
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(model.displayName)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(self.modelManager.getModelSizeDescription(model.id))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Text(model.qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                self.modelActionButton(for: model.id)
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    /// Unified action button for model download/delete operations.
    @ViewBuilder
    private func modelActionButton(for modelId: String) -> some View {
        let status = self.modelManager.getStatus(for: modelId)

        switch status {
        case .downloaded:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)

                Button(action: { try? self.modelManager.deleteModel(modelId) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete model")
            }

        case let .downloading(progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 32, alignment: .trailing)

                Button(action: { self.modelManager.cancelDownload() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel download")
            }

        case .notDownloaded:
            Button(action: { self.modelManager.downloadModel(modelId) }) {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .disabled(self.modelManager.isDownloading)
            .opacity(self.modelManager.isDownloading ? 0.5 : 1)
            .help("Download model")

        case .error:
            Button(action: { self.modelManager.downloadModel(modelId) }) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            .disabled(self.modelManager.isDownloading)
            .help("Retry download")
        }
    }
}

enum ApiKeyValidationResult {
    case success
    case failure(String)
}
