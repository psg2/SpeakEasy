import AVFoundation
import Foundation

class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    init() {
        self.engine.attach(self.player)
        let format = self.engine.outputNode.inputFormat(forBus: 0)
        self.engine.connect(self.player, to: self.engine.outputNode, format: format)
        do {
            try self.engine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }

    func playStartSound() {
        self.playTone(frequency: 600, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 800, duration: 0.1)
        }
    }

    func playStopSound() {
        self.playTone(frequency: 800, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 600, duration: 0.1)
        }
    }

    private func playTone(frequency: Double, duration: Double) {
        // Use the format of the engine's output node to match channel count and sample rate
        let format = self.engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = Int(duration * sampleRate)

        let capacity = AVAudioFrameCount(frameCount)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Generate audio data
        if let floatChannelData = buffer.floatChannelData {
            for channel in 0..<channelCount {
                let data = floatChannelData[channel]
                for index in 0..<frameCount {
                    let time = Double(index) / sampleRate
                    let value = Float(sin(2.0 * .pi * frequency * time))

                    // Apply volume
                    var sample = value * 0.3

                    // Fade in/out to avoid clicks
                    let fadeFrames = Int(0.01 * sampleRate)
                    if index < fadeFrames {
                        sample *= Float(index) / Float(fadeFrames)
                    } else if index > frameCount - fadeFrames {
                        sample *= Float(frameCount - index) / Float(fadeFrames)
                    }

                    data[index] = sample
                }
            }
        }

        self.player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !self.player.isPlaying { self.player.play() }
    }
}
