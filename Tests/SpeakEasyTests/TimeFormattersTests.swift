import Foundation
import Testing
@testable import SpeakEasyLib

@Suite("TimeFormatters Tests")
struct TimeFormattersTests {

    // MARK: - Milliseconds (< 1 second)

    @Test("Format 0 seconds as milliseconds")
    func testZeroSecondsAsMilliseconds() {
        let result = 0.0.formatAsTranscriptionTime()
        #expect(result == "0ms")
    }

    @Test("Format 0.25 seconds as milliseconds")
    func testQuarterSecondAsMilliseconds() {
        let result = 0.25.formatAsTranscriptionTime()
        #expect(result == "250ms")
    }

    @Test("Format 0.5 seconds as milliseconds")
    func testHalfSecondAsMilliseconds() {
        let result = 0.5.formatAsTranscriptionTime()
        #expect(result == "500ms")
    }

    @Test("Format 0.999 seconds as milliseconds")
    func testAlmostOneSecondAsMilliseconds() {
        let result = 0.999.formatAsTranscriptionTime()
        #expect(result == "999ms")
    }

    @Test("Format 0.1 seconds as milliseconds")
    func testOneHundredMilliseconds() {
        let result = 0.1.formatAsTranscriptionTime()
        #expect(result == "100ms")
    }

    // MARK: - Seconds (1 to 59.9 seconds)

    @Test("Format exactly 1 second")
    func testExactlyOneSecond() {
        let result = 1.0.formatAsTranscriptionTime()
        #expect(result == "1.0s")
    }

    @Test("Format 2.5 seconds")
    func testTwoAndHalfSeconds() {
        let result = 2.5.formatAsTranscriptionTime()
        #expect(result == "2.5s")
    }

    @Test("Format 10.0 seconds")
    func testTenSeconds() {
        let result = 10.0.formatAsTranscriptionTime()
        #expect(result == "10.0s")
    }

    @Test("Format 30.7 seconds")
    func testThirtyPointSevenSeconds() {
        let result = 30.7.formatAsTranscriptionTime()
        #expect(result == "30.7s")
    }

    @Test("Format 59.9 seconds")
    func testAlmostOneMinute() {
        let result = 59.9.formatAsTranscriptionTime()
        #expect(result == "59.9s")
    }

    // MARK: - Minutes (≥ 60 seconds)

    @Test("Format exactly 1 minute (60 seconds)")
    func testExactlyOneMinute() {
        let result = 60.0.formatAsTranscriptionTime()
        #expect(result == "1m 0s")
    }

    @Test("Format 1 minute 30 seconds (90 seconds)")
    func testOneMinuteThirtySeconds() {
        let result = 90.0.formatAsTranscriptionTime()
        #expect(result == "1m 30s")
    }

    @Test("Format 2 minutes 15 seconds (135 seconds)")
    func testTwoMinutesFifteenSeconds() {
        let result = 135.0.formatAsTranscriptionTime()
        #expect(result == "2m 15s")
    }

    @Test("Format 5 minutes (300 seconds)")
    func testFiveMinutes() {
        let result = 300.0.formatAsTranscriptionTime()
        #expect(result == "5m 0s")
    }

    @Test("Format 10 minutes 45 seconds (645 seconds)")
    func testTenMinutesFortyFiveSeconds() {
        let result = 645.0.formatAsTranscriptionTime()
        #expect(result == "10m 45s")
    }

    @Test("Format 60 minutes (3600 seconds)")
    func testSixtyMinutes() {
        let result = 3600.0.formatAsTranscriptionTime()
        #expect(result == "60m 0s")
    }

    // MARK: - Edge Cases

    @Test("Format very small duration (1 millisecond)")
    func testOneMillisecond() {
        let result = 0.001.formatAsTranscriptionTime()
        #expect(result == "1ms")
    }

    @Test("Format edge case at boundary (exactly 1.0 second)")
    func testExactlyOneSecondBoundary() {
        let result = 1.0.formatAsTranscriptionTime()
        #expect(result == "1.0s")
    }

    @Test("Format edge case at boundary (exactly 60.0 seconds)")
    func testExactlySixtySecondsBoundary() {
        let result = 60.0.formatAsTranscriptionTime()
        #expect(result == "1m 0s")
    }

    @Test("Format fractional minutes (90.5 seconds)")
    func testFractionalMinutes() {
        let result = 90.5.formatAsTranscriptionTime()
        #expect(result == "1m 30s")
    }

    @Test("Format large duration (2 hours)")
    func testTwoHours() {
        let result = 7200.0.formatAsTranscriptionTime()
        #expect(result == "120m 0s")
    }

    // MARK: - Practical Real-World Examples

    @Test("Format typical short transcription (3.7 seconds)")
    func testTypicalShortTranscription() {
        let result = 3.7.formatAsTranscriptionTime()
        #expect(result == "3.7s")
    }

    @Test("Format typical medium transcription (45.2 seconds)")
    func testTypicalMediumTranscription() {
        let result = 45.2.formatAsTranscriptionTime()
        #expect(result == "45.2s")
    }

    @Test("Format typical long transcription (2m 23s)")
    func testTypicalLongTranscription() {
        let result = 143.0.formatAsTranscriptionTime()
        #expect(result == "2m 23s")
    }
}
