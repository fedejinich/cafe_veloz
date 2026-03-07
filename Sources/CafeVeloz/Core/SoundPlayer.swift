import AppKit

protocol SoundPlaying: Sendable {
    func playToggleOn()
    func playToggleOff()
}

final class SystemSoundPlayer: SoundPlaying {
    func playToggleOn() {
        play(named: "Purr", volume: 0.35)
    }

    func playToggleOff() {
        play(named: "Tink", volume: 0.3)
    }

    private func play(named name: String, volume: Float) {
        guard let sound = NSSound(named: NSSound.Name(name)) else { return }
        sound.volume = volume
        sound.play()
    }
}

final class MuteSoundPlayer: SoundPlaying {
    private let _onCount = MuteSoundCounter()
    private let _offCount = MuteSoundCounter()

    var onCallCount: Int { _onCount.value }
    var offCallCount: Int { _offCount.value }

    func playToggleOn() {
        _onCount.increment()
    }

    func playToggleOff() {
        _offCount.increment()
    }
}

private final class MuteSoundCounter: @unchecked Sendable {
    private var _value = 0
    var value: Int { _value }
    func increment() { _value += 1 }
}
