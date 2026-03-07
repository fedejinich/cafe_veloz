import XCTest
@testable import CafeVeloz

@MainActor
final class SoundPlayerTests: XCTestCase {
    func testToggleOnIncrementsOnCount() {
        let sound = MuteSoundPlayer()
        let controller = CaffeinateController(
            processLauncher: FakeProcessLauncher(processes: [FakeProcess()]),
            soundPlayer: sound,
            autoOffTimer: AutoOffTimer()
        )

        controller.toggle()

        XCTAssertEqual(sound.onCallCount, 1)
        XCTAssertEqual(sound.offCallCount, 0)
    }

    func testToggleOffIncrementsOffCount() {
        let sound = MuteSoundPlayer()
        let controller = CaffeinateController(
            processLauncher: FakeProcessLauncher(processes: [FakeProcess()]),
            soundPlayer: sound,
            autoOffTimer: AutoOffTimer()
        )

        controller.toggle() // on
        controller.toggle() // off

        XCTAssertEqual(sound.onCallCount, 1)
        XCTAssertEqual(sound.offCallCount, 1)
    }

    func testMultipleTogglesAccumulateCounts() {
        let sound = MuteSoundPlayer()
        let controller = CaffeinateController(
            processLauncher: FakeProcessLauncher(processes: [FakeProcess(), FakeProcess(), FakeProcess()]),
            soundPlayer: sound,
            autoOffTimer: AutoOffTimer()
        )

        controller.toggle() // on
        controller.toggle() // off
        controller.toggle() // on

        XCTAssertEqual(sound.onCallCount, 2)
        XCTAssertEqual(sound.offCallCount, 1)
    }

    func testFailedStartDoesNotPlaySound() {
        let sound = MuteSoundPlayer()
        let controller = CaffeinateController(
            processLauncher: FakeProcessLauncher(processes: [FakeProcess(shouldThrowOnRun: true)]),
            soundPlayer: sound,
            autoOffTimer: AutoOffTimer()
        )

        controller.start()

        XCTAssertEqual(sound.onCallCount, 0)
        XCTAssertEqual(sound.offCallCount, 0)
    }
}
