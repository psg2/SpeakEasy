import Foundation
import Testing
@testable import SpeakEasyLib

@Suite("TimeFormatters Tests")
struct TimeFormattersTests {
    // MARK: - Milliseconds (< 1 second)

    @Test("Format 0 seconds as milliseconds")
    func zeroSecondsAsMilliseconds() {
        let result = 0.0.formatAsTranscriptionTime()
        #expect(result == "0ms")
    }

    @Test("Format 0.25 seconds as milliseconds")
    func quarterSecondAsMilliseconds() {
        let result = 0.25.formatAsTranscriptionTime()
        #expect(result == "250ms")
    }

    @Test("Format 0.5 seconds as milliseconds")
    func halfSecondAsMilliseconds() {
        let result = 0.5.formatAsTranscriptionTime()
        #expect(result == "500ms")
    }

    @Test("Format 0.999 seconds as milliseconds")
    func almostOneSecondAsMilliseconds() {
        let result = 0.999.formatAsTranscriptionTime()
        #expect(result == "999ms")
    }

    @Test("Format 0.1 seconds as milliseconds")
    func oneHundredMilliseconds() {
        let result = 0.1.formatAsTranscriptionTime()
        #expect(result == "100ms")
    }

    // MARK: - Seconds (1 to 59.9 seconds)

    @Test("Format exactly 1 second")
    func exactlyOneSecond() {
        let result = 1.0.formatAsTranscriptionTime()
        #expect(result == "1.0s")
    }

    @Test("Format 2.5 seconds")
    func twoAndHalfSeconds() {
        let result = 2.5.formatAsTranscriptionTime()
        #expect(result == "2.5s")
    }

    @Test("Format 10.0 seconds")
    func tenSeconds() {
        let result = 10.0.formatAsTranscriptionTime()
        #expect(result == "10.0s")
    }

    @Test("Format 30.7 seconds")
    func thirtyPointSevenSeconds() {
        let result = 30.7.formatAsTranscriptionTime()
        #expect(result == "30.7s")
    }

    @Test("Format 59.9 seconds")
    func almostOneMinute() {
        let result = 59.9.formatAsTranscriptionTime()
        #expect(result == "59.9s")
    }

    // MARK: - Minutes (≥ 60 seconds)

    @Test("Format exactly 1 minute (60 seconds)")
    func exactlyOneMinute() {
        let result = 60.0.formatAsTranscriptionTime()
        #expect(result == "1m 0s")
    }

    @Test("Format 1 minute 30 seconds (90 seconds)")
    func oneMinuteThirtySeconds() {
        let result = 90.0.formatAsTranscriptionTime()
        #expect(result == "1m 30s")
    }

    @Test("Format 2 minutes 15 seconds (135 seconds)")
    func twoMinutesFifteenSeconds() {
        let result = 135.0.formatAsTranscriptionTime()
        #expect(result == "2m 15s")
    }

    @Test("Format 5 minutes (300 seconds)")
    func fiveMinutes() {
        let result = 300.0.formatAsTranscriptionTime()
        #expect(result == "5m 0s")
    }

    @Test("Format 10 minutes 45 seconds (645 seconds)")
    func tenMinutesFortyFiveSeconds() {
        let result = 645.0.formatAsTranscriptionTime()
        #expect(result == "10m 45s")
    }

    @Test("Format 60 minutes (3600 seconds)")
    func sixtyMinutes() {
        let result = 3600.0.formatAsTranscriptionTime()
        #expect(result == "60m 0s")
    }

    // MARK: - Edge Cases

    @Test("Format very small duration (1 millisecond)")
    func oneMillisecond() {
        let result = 0.001.formatAsTranscriptionTime()
        #expect(result == "1ms")
    }

    @Test("Format edge case at boundary (exactly 1.0 second)")
    func exactlyOneSecondBoundary() {
        let result = 1.0.formatAsTranscriptionTime()
        #expect(result == "1.0s")
    }

    @Test("Format edge case at boundary (exactly 60.0 seconds)")
    func exactlySixtySecondsBoundary() {
        let result = 60.0.formatAsTranscriptionTime()
        #expect(result == "1m 0s")
    }

    @Test("Format fractional minutes (90.5 seconds)")
    func fractionalMinutes() {
        let result = 90.5.formatAsTranscriptionTime()
        #expect(result == "1m 30s")
    }

    @Test("Format large duration (2 hours)")
    func twoHours() {
        let result = 7200.0.formatAsTranscriptionTime()
        #expect(result == "120m 0s")
    }

    // MARK: - Practical Real-World Examples

    @Test("Format typical short transcription (3.7 seconds)")
    func typicalShortTranscription() {
        let result = 3.7.formatAsTranscriptionTime()
        #expect(result == "3.7s")
    }

    @Test("Format typical medium transcription (45.2 seconds)")
    func typicalMediumTranscription() {
        let result = 45.2.formatAsTranscriptionTime()
        #expect(result == "45.2s")
    }

    @Test("Format typical long transcription (2m 23s)")
    func typicalLongTranscription() {
        let result = 143.0.formatAsTranscriptionTime()
        #expect(result == "2m 23s")
    }
}
