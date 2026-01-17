import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    init() {
        engine.attach(player)
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(player, to: engine.outputNode, format: format)
        do {
            try engine.start()
        } catch {
            print("Audio engine start error: \(error)")
        }
    }
    
    func playStartSound() {
        playTone(frequency: 600, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 800, duration: 0.1)
        }
    }
    
    func playStopSound() {
        playTone(frequency: 800, duration: 0.08)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.playTone(frequency: 600, duration: 0.1)
        }
    }
    
    private func playTone(frequency: Double, duration: Double) {
        // Use the format of the engine's output node to match channel count and sample rate
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let frameCount = Int(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Generate audio data
        if let floatChannelData = buffer.floatChannelData {
            for channel in 0..<channelCount {
                let data = floatChannelData[channel]
                for i in 0..<frameCount {
                    let t = Double(i) / sampleRate
                    let value = Float(sin(2.0 * .pi * frequency * t))
                    
                    // Apply volume
                    var sample = value * 0.3
                    
                    // Fade in/out to avoid clicks
                    let fadeFrames = Int(0.01 * sampleRate)
                    if i < fadeFrames {
                        sample *= Float(i) / Float(fadeFrames)
                    } else if i > frameCount - fadeFrames {
                        sample *= Float(frameCount - i) / Float(fadeFrames)
                    }
                    
                    data[i] = sample
                }
            }
        }
        
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying { player.play() }
    }
}