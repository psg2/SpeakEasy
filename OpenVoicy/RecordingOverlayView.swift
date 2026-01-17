import SwiftUI

struct RecordingOverlayView: View {
    @ObservedObject var appState: AppState

    // Constants matching React implementation
    let numBars = 10
    let minHeight: CGFloat = 2
    let maxHeight: CGFloat = 18
    let barWidth: CGFloat = 4
    let spacing: CGFloat = 4

    @State private var barOffsets: [Double] = (0..<10).map { _ in Double.random(in: 0.5...1.0) }

    var body: some View {
        ZStack {
            TimelineView(.periodic(from: .now, by: 0.03)) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                HStack(spacing: self.spacing) {
                    ForEach(0..<self.numBars, id: \.self) { index in
                        self.barView(index: index, time: time)
                    }
                }
                .opacity(self.appState.state == .processing ? 0.3 : 1.0) // Dim bars when processing
            }

            if self.appState.state == .processing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1))
        .onAppear {
            self.barOffsets = (0..<self.numBars).map { _ in Double.random(in: 0.5...1.0) }
        }
    }

    func barView(index: Int, time: TimeInterval) -> some View {
        let isRecording = self.appState.state == .recording
        let isProcessing = self.appState.state == .processing
        let level = Double(appState.audioLevel)

        var height: CGFloat = self.minHeight

        if isProcessing {
            height = self.minHeight + 1
        } else if isRecording {
            let centerDist = abs(Double(index) - Double(self.numBars - 1) / 2.0) / (Double(self.numBars - 1) / 2.0)
            let centerFactor = 1.0 - centerDist * 0.5
            let variation = self.barOffsets[index] * 0.4 + 0.6
            let wave = sin(time * 5 + Double(index) * 0.7) * 0.1
            let boost = pow(level, 0.5) * 2.0

            height = self.minHeight +
                CGFloat(boost * variation * centerFactor) * (self.maxHeight - self.minHeight) +
                CGFloat(wave * (self.maxHeight - self.minHeight) * 0.5)
        } else {
            let offset = sin(time * 3 + Double(index) * 0.3) * 1.0
            height = self.minHeight + CGFloat(abs(offset))
        }

        return RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.cyan, .purple]),
                    startPoint: .top,
                    endPoint: .bottom))
            .frame(width: self.barWidth, height: max(self.minHeight, min(self.maxHeight, height)))
            .animation(.linear(duration: 0.05), value: height)
    }
}
