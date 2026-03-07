import Foundation

protocol CaffeinateProcessControlling: AnyObject {
    var executableURL: URL? { get set }
    var arguments: [String]? { get set }
    var terminationHandler: ((any CaffeinateProcessControlling) -> Void)? { get set }
    var isRunning: Bool { get }

    func run() throws
    func terminate()
}

protocol CaffeinateProcessLaunching {
    func makeProcess() -> any CaffeinateProcessControlling
}

final class SystemProcessLauncher: CaffeinateProcessLaunching {
    func makeProcess() -> any CaffeinateProcessControlling {
        SystemProcessAdapter()
    }
}

final class SystemProcessAdapter: @unchecked Sendable, CaffeinateProcessControlling {
    private let process = Process()
    private var onTerminate: ((any CaffeinateProcessControlling) -> Void)?

    var executableURL: URL? {
        get { process.executableURL }
        set { process.executableURL = newValue }
    }

    var arguments: [String]? {
        get { process.arguments }
        set { process.arguments = newValue }
    }

    var terminationHandler: ((any CaffeinateProcessControlling) -> Void)? {
        get { onTerminate }
        set {
            onTerminate = newValue
            process.terminationHandler = { [weak self] _ in
                guard let self else { return }
                self.onTerminate?(self)
            }
        }
    }

    var isRunning: Bool {
        process.isRunning
    }

    func run() throws {
        try process.run()
    }

    func terminate() {
        process.terminate()
    }
}
