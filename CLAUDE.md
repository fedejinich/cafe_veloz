# CafeVeloz

macOS menu bar app that keeps your Mac awake using `caffeinate -di`. Floating coffee cup widget as visual indicator.

## Language

All code, comments, and UI in English.

## Architecture

```
Sources/CafeVeloz/
  Core/       — Business logic (protocols + DI)
    CaffeinateController.swift   — Main controller (start/stop/toggle)
    CaffeinateProcessLaunching.swift — Protocol for process injection
    SoundPlayer.swift            — Protocol + impl for toggle sounds
    AutoOffTimer.swift           — Auto-off timer with presets
  UI/         — View layer (SwiftUI + AppKit)
    CoffeeWidgetView.swift       — Floating draggable widget
    WindowAccessor.swift         — Helper to access NSWindow from SwiftUI
  App/        — Lifecycle
    AppDelegate.swift            — Menu bar, window config, login item
    CafeVelozApp.swift           — Entry point
  Resources/  — PNG assets + xcassets for app icon
```

## Build and test

```bash
swift test                    # 22 tests
swift build                   # Debug build
swift build -c release        # Release build
bash scripts/pipeline.sh      # Test + build + package into dist/CafeVeloz.app
bash install.sh               # Install to ~/Applications
```

## Tests

- Fakes in test files: `FakeProcess`, `MuteSoundPlayer`, `FakeTimerProvider`
- Tests are `@MainActor` because `CaffeinateController` is
- No UI or special permissions required

## Conventions

- `@MainActor` on classes that touch UI or shared state
- `Sendable` protocols for dependency injection
- PNG assets directly in Resources/ with @2x variants (SPM can't compile .car)
- xcassets only for app icon (converted to .icns in install.sh)
- Widget position persisted via UserDefaults (`widgetX`, `widgetY`)
- Login item via `SMAppService.mainApp` (macOS 13+)
- Drag uses `NSEvent.mouseLocation` (screen coords) to avoid SwiftUI feedback loop

## Platform

- macOS 14+ (`.macOS(.v14)` in Package.swift)
- Swift 6.0 (strict concurrency)
- SPM (no Xcode project)
