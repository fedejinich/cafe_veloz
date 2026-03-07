import Foundation

protocol TimerProviding: Sendable {
    func schedule(interval: TimeInterval, block: @escaping @Sendable () -> Void) -> any TimerCancelling
}

protocol TimerCancelling: Sendable {
    func cancel()
}

final class SystemTimerProvider: TimerProviding {
    func schedule(interval: TimeInterval, block: @escaping @Sendable () -> Void) -> any TimerCancelling {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            block()
        }
        RunLoop.main.add(timer, forMode: .common)
        return SystemTimerHandle(timer: timer)
    }
}

private final class SystemTimerHandle: @unchecked Sendable, TimerCancelling {
    private let timer: Timer
    init(timer: Timer) { self.timer = timer }
    func cancel() { timer.invalidate() }
}

@MainActor
final class AutoOffTimer: ObservableObject {
    static let presetHours = [0, 1, 2, 4, 8]

    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isActive: Bool = false
    @Published var selectedHours: Int = 0

    private let timerProvider: any TimerProviding
    private var activeTimer: (any TimerCancelling)?
    private var onExpired: (() -> Void)?

    init(timerProvider: any TimerProviding = SystemTimerProvider()) {
        self.timerProvider = timerProvider
    }

    func start(hours: Int, onExpired: @escaping () -> Void) {
        stop()

        guard hours > 0 else { return }

        selectedHours = hours
        remainingSeconds = hours * 3600
        isActive = true
        self.onExpired = onExpired

        activeTimer = timerProvider.schedule(interval: 1.0) { [weak self] in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func stop() {
        activeTimer?.cancel()
        activeTimer = nil
        isActive = false
        remainingSeconds = 0
        onExpired = nil
    }

    var formattedRemaining: String {
        let h = remainingSeconds / 3600
        let m = (remainingSeconds % 3600) / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    func tick() {
        guard isActive else { return }

        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            let callback = onExpired
            stop()
            callback?()
        }
    }
}
