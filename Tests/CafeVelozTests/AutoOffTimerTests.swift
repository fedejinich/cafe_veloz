import XCTest
@testable import CafeVeloz

@MainActor
final class AutoOffTimerTests: XCTestCase {
    func testStartSetsRemainingSecondsAndActive() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)

        timer.start(hours: 2) {}

        XCTAssertTrue(timer.isActive)
        XCTAssertEqual(timer.remainingSeconds, 7200)
        XCTAssertEqual(timer.selectedHours, 2)
    }

    func testTickCountsDown() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)

        timer.start(hours: 1) {}
        timer.tick()

        XCTAssertEqual(timer.remainingSeconds, 3599)
    }

    func testExpiryCallsCallback() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)
        var expired = false

        timer.start(hours: 1) { expired = true }

        // Simulate countdown to 1 second remaining
        for _ in 0..<3599 {
            timer.tick()
        }
        XCTAssertFalse(expired)
        XCTAssertEqual(timer.remainingSeconds, 1)

        // Final tick
        timer.tick()
        XCTAssertTrue(expired)
        XCTAssertFalse(timer.isActive)
    }

    func testStopBeforeExpiry() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)
        var expired = false

        timer.start(hours: 1) { expired = true }
        timer.tick()
        timer.stop()

        XCTAssertFalse(timer.isActive)
        XCTAssertEqual(timer.remainingSeconds, 0)
        XCTAssertFalse(expired)
    }

    func testNewTimerCancelsPrevious() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)

        timer.start(hours: 4) {}
        XCTAssertEqual(timer.remainingSeconds, 14400)

        timer.start(hours: 1) {}
        XCTAssertEqual(timer.remainingSeconds, 3600)
        XCTAssertEqual(timer.selectedHours, 1)
    }

    func testZeroHoursDoesNothing() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)

        timer.start(hours: 0) {}

        XCTAssertFalse(timer.isActive)
        XCTAssertEqual(timer.remainingSeconds, 0)
    }

    func testFormattedRemaining() {
        let provider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: provider)

        timer.start(hours: 2) {}
        // 2h = 7200s, tick 2700 times -> 4500s remaining = 1:15:00
        for _ in 0..<2700 {
            timer.tick()
        }

        XCTAssertEqual(timer.formattedRemaining, "1:15:00")
    }
}
