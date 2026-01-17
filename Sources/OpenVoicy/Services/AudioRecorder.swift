import AVFoundation
import Combine
import Foundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?

    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0

    var onRecordingFinished: ((URL?) -> Void)?

    override init() {
        super.init()
        self.setupSession()
    }

    private func setupSession() {
        // We don't need to configure a shared session on macOS like iOS,
        // but we might want to check permissions here.
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
        default:
            print("Audio access denied")
        }
    }

    func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("recording.wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0, // Whisper likes 16k
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        do {
            self.audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            self.audioRecorder?.delegate = self
            self.audioRecorder?.isMeteringEnabled = true
            self.audioRecorder?.record()

            self.isRecording = true
            self.startMetering()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() {
        self.audioRecorder?.stop()
        self.stopMetering()
        self.isRecording = false
    }

    private func startMetering() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()

            // Normalize level (0..1)
            // power is usually -160 to 0
            let power = recorder.averagePower(forChannel: 0)
            let minDb: Float = -60.0

            // Linearize
            let level = max(0.0, (power - minDb) / (0 - minDb))
            self.audioLevel = level
        }
    }

    private func stopMetering() {
        self.timer?.invalidate()
        self.timer = nil
        self.audioLevel = 0
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            self.onRecordingFinished?(recorder.url)
        } else {
            self.onRecordingFinished?(nil)
        }
    }
}
