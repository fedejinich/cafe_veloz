import Foundation

@MainActor
final class CaffeinateController: ObservableObject {
    static let shared = CaffeinateController()

    @Published private(set) var isRunning = false

    private let processLauncher: any CaffeinateProcessLaunching
    private let soundPlayer: any SoundPlaying
    let autoOffTimer: AutoOffTimer
    private var activeProcess: (any CaffeinateProcessControlling)?

    init(
        processLauncher: any CaffeinateProcessLaunching = SystemProcessLauncher(),
        soundPlayer: any SoundPlaying = SystemSoundPlayer(),
        autoOffTimer: AutoOffTimer = AutoOffTimer()
    ) {
        self.processLauncher = processLauncher
        self.soundPlayer = soundPlayer
        self.autoOffTimer = autoOffTimer
    }

    func start(autoOffHours: Int = 0) {
        guard activeProcess == nil else { return }

        let process = processLauncher.makeProcess()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-di"]
        process.terminationHandler = { [weak self] finishedProcess in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard self.isSameProcess(self.activeProcess, finishedProcess) else { return }
                self.activeProcess = nil
                self.isRunning = false
                self.autoOffTimer.stop()
            }
        }

        do {
            try process.run()
            activeProcess = process
            isRunning = true
            soundPlayer.playToggleOn()

            if autoOffHours > 0 {
                autoOffTimer.start(hours: autoOffHours) { [weak self] in
                    self?.stop()
                }
            }
        } catch {
            activeProcess = nil
            isRunning = false
            process.terminationHandler = nil
            NSLog("CafeVeloz: failed to run caffeinate: \(error.localizedDescription)")
        }
    }

    func stop() {
        killProcess()
        soundPlayer.playToggleOff()
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    func stopOnAppTerminate() {
        killProcess()
    }

    private func killProcess() {
        guard let process = activeProcess else {
            isRunning = false
            return
        }
        activeProcess = nil
        isRunning = false
        autoOffTimer.stop()
        process.terminationHandler = nil
        if process.isRunning { process.terminate() }
    }

    func startAutoOff(hours: Int) {
        guard isRunning, hours > 0 else {
            autoOffTimer.stop()
            return
        }
        autoOffTimer.start(hours: hours) { [weak self] in
            self?.stop()
        }
    }

    private func isSameProcess(
        _ lhs: (any CaffeinateProcessControlling)?,
        _ rhs: any CaffeinateProcessControlling
    ) -> Bool {
        guard let lhs else { return false }
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
