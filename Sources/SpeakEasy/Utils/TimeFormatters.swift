import Foundation

extension Double {
    /// Formats a duration in seconds as a human-readable transcription time.
    /// - Returns: Formatted string like "250ms", "2.5s", or "1m 30.0s"
    func formatAsTranscriptionTime() -> String {
        if self < 1 {
            return String(format: "%.0fms", self * 1000)
        } else if self < 60 {
            return String(format: "%.1fs", self)
        } else {
            let minutes = Int(self) / 60
            let secs = self.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm %.0fs", minutes, secs)
        }
    }
}
