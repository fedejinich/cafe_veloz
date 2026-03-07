import XCTest
@testable import CafeVeloz

@MainActor
final class CaffeinateControllerTests: XCTestCase {
    func testStartLaunchesCaffeinateAndSetsRunningState() {
        let process = FakeProcess()
        let controller = makeController(processes: [process])

        controller.start()

        XCTAssertTrue(controller.isRunning)
        XCTAssertEqual(process.runCallCount, 1)
        XCTAssertEqual(process.executableURL?.path, "/usr/bin/caffeinate")
        XCTAssertEqual(process.arguments ?? [], ["-di"])
    }

    func testStartWhileRunningDoesNotLaunchSecondProcess() {
        let process = FakeProcess()
        let controller = makeController(processes: [process, FakeProcess()])

        controller.start()
        controller.start()

        XCTAssertTrue(controller.isRunning)
        XCTAssertEqual(process.runCallCount, 1)
    }

    func testStopTerminatesRunningProcess() {
        let process = FakeProcess()
        let controller = makeController(processes: [process])

        controller.start()
        controller.stop()

        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(process.terminateCallCount, 1)
    }

    func testToggleAlternatesState() {
        let process = FakeProcess()
        let controller = makeController(processes: [process])

        controller.toggle()
        XCTAssertTrue(controller.isRunning)

        controller.toggle()
        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(process.terminateCallCount, 1)
    }

    func testUnexpectedProcessExitResetsState() async {
        let process = FakeProcess()
        let controller = makeController(processes: [process])

        controller.start()
        XCTAssertTrue(controller.isRunning)

        process.simulateUnexpectedExit()
        await waitUntil { !controller.isRunning }

        XCTAssertFalse(controller.isRunning)
    }

    func testStopOnTerminateTurnsOffRunningProcess() {
        let process = FakeProcess()
        let controller = makeController(processes: [process])

        controller.start()
        controller.stopOnAppTerminate()

        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(process.terminateCallCount, 1)
    }

    func testStartFailureKeepsControllerOff() {
        let process = FakeProcess(shouldThrowOnRun: true)
        let controller = makeController(processes: [process])

        controller.start()

        XCTAssertFalse(controller.isRunning)
        XCTAssertEqual(process.runCallCount, 1)
    }

    // MARK: - Sound Tests

    func testToggleOnPlaysOnSound() {
        let sound = MuteSoundPlayer()
        let controller = makeController(processes: [FakeProcess()], sound: sound)

        controller.toggle()

        XCTAssertEqual(sound.onCallCount, 1)
        XCTAssertEqual(sound.offCallCount, 0)
    }

    func testToggleOffPlaysOffSound() {
        let sound = MuteSoundPlayer()
        let controller = makeController(processes: [FakeProcess()], sound: sound)

        controller.toggle()
        controller.toggle()

        XCTAssertEqual(sound.onCallCount, 1)
        XCTAssertEqual(sound.offCallCount, 1)
    }

    // MARK: - Auto-off Timer Tests

    func testStartWithAutoOffHoursInitiatesTimer() {
        let timerProvider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: timerProvider)
        let controller = makeController(processes: [FakeProcess()], timer: timer)

        controller.start(autoOffHours: 2)

        XCTAssertTrue(timer.isActive)
        XCTAssertEqual(timer.remainingSeconds, 7200)
    }

    func testStartWithZeroHoursDoesNotInitiateTimer() {
        let timerProvider = FakeTimerProvider()
        let timer = AutoOffTimer(timerProvider: timerProvider)
        let controller = makeController(processes: [FakeProcess()], timer: timer)

        controller.start(autoOffHours: 0)

        XCTAssertFalse(timer.isActive)
    }

    // MARK: - Helpers

    private func makeController(
        processes: [FakeProcess],
        sound: MuteSoundPlayer = MuteSoundPlayer(),
        timer: AutoOffTimer = AutoOffTimer()
    ) -> CaffeinateController {
        CaffeinateController(
            processLauncher: FakeProcessLauncher(processes: processes),
            soundPlayer: sound,
            autoOffTimer: timer
        )
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        checkEveryNanoseconds: UInt64 = 20_000_000,
        _ condition: @escaping () -> Bool
    ) async {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds

        while !condition() {
            if DispatchTime.now().uptimeNanoseconds >= deadline {
                XCTFail("Condition not met before timeout")
                return
            }
            try? await Task.sleep(nanoseconds: checkEveryNanoseconds)
        }
    }
}

// MARK: - Test Doubles

final class FakeProcessLauncher: CaffeinateProcessLaunching {
    private var processes: [FakeProcess]

    init(processes: [FakeProcess]) {
        self.processes = processes
    }

    func makeProcess() -> any CaffeinateProcessControlling {
        guard !processes.isEmpty else {
            return FakeProcess()
        }
        return processes.removeFirst()
    }
}

final class FakeProcess: CaffeinateProcessControlling {
    var executableURL: URL?
    var arguments: [String]?
    var terminationHandler: ((any CaffeinateProcessControlling) -> Void)?

    private(set) var isRunning = false
    private(set) var runCallCount = 0
    private(set) var terminateCallCount = 0

    private let shouldThrowOnRun: Bool

    init(shouldThrowOnRun: Bool = false) {
        self.shouldThrowOnRun = shouldThrowOnRun
    }

    func run() throws {
        runCallCount += 1
        if shouldThrowOnRun {
            throw FakeError.launchFailed
        }
        isRunning = true
    }

    func terminate() {
        terminateCallCount += 1
        isRunning = false
    }

    func simulateUnexpectedExit() {
        isRunning = false
        terminationHandler?(self)
    }

    private enum FakeError: Error {
        case launchFailed
    }
}

final class FakeTimerProvider: @unchecked Sendable, TimerProviding {
    private(set) var scheduledBlocks: [@Sendable () -> Void] = []

    func schedule(interval: TimeInterval, block: @escaping @Sendable () -> Void) -> any TimerCancelling {
        scheduledBlocks.append(block)
        return FakeTimerHandle()
    }

    func fireTick() {
        scheduledBlocks.last?()
    }
}

private final class FakeTimerHandle: TimerCancelling {
    func cancel() {}
}
