<h1 align="center">
  <img src="Sources/CafeVeloz/Resources/coffee_cup@2x.png" width="120" alt="Cafe Veloz">
  <br>Cafe Veloz
</h1>

<p align="center">macOS menu bar app that keeps your Mac awake using <code>caffeinate -di</code>.<br>A floating widget with the Cafe Veloz cup as visual indicator.</p>

## Features

- **Floating widget** — Draggable coffee cup that can be moved anywhere on screen. No borders, no window chrome, just the cup.
- **Click to toggle** — A single click toggles between on (opaque, saturated colors) and off (translucent, desaturated).
- **Double click** — Hides/shows the widget.
- **Menu bar** — Status bar icon with menu to control caffeinate, widget visibility, auto-off timer, and login item.
- **Auto-off** — Presets of 1h, 2h, 4h, 8h with countdown visible in the widget and menu bar.
- **Launch at login** — Registered as login item via `SMAppService`.
- **Sounds** — Audible feedback on toggle (system Purr/Tink sounds).
- **Persistent position** — Widget position is saved to `UserDefaults` and restored on relaunch.

## Requirements

- macOS 14+
- Swift 6.0+ / Xcode 16.2+

## Build

```bash
swift build                   # Debug
swift build -c release        # Release
```

## Tests

```bash
swift test                    # 22 tests
```

Tests use dependency injection with fakes (`FakeProcess`, `MuteSoundPlayer`, `FakeTimerProvider`). No UI or special permissions required.

## Install

```bash
bash install.sh
```

Generates `CafeVeloz.app` in `~/Applications/` with icon, `Info.plist`, and ad-hoc signature. Also copies to `/Applications/` if a previous version existed.

## Pipeline

```bash
bash scripts/pipeline.sh      # Test + release build + package into dist/
```

CI with GitHub Actions: [`.github/workflows/ci.yml`](.github/workflows/ci.yml)

## Architecture

```
Sources/CafeVeloz/
  App/
    CafeVelozApp.swift               Entry point (@main)
    AppDelegate.swift                 Menu bar, window config, login item
  Core/
    CaffeinateController.swift        Main controller (start/stop/toggle)
    CaffeinateProcessLaunching.swift  Protocol for process injection
    SoundPlayer.swift                 Protocol + impl for toggle sounds
    AutoOffTimer.swift                Auto-off timer with presets
  UI/
    CoffeeWidgetView.swift            Floating draggable widget (SwiftUI)
    WindowAccessor.swift              NSViewRepresentable for NSWindow access
  Resources/
    coffee_cup.png                    Widget 1x (180x180)
    coffee_cup@2x.png                 Widget 2x (360x360)
    Assets.xcassets/                  App icon (16-1024px)

Tests/CafeVelozTests/
  CaffeinateControllerTests.swift     11 tests — start, stop, toggle, sounds, timer
  AutoOffTimerTests.swift             7 tests  — countdown, expiry, formatting
  SoundPlayerTests.swift              4 tests  — sound call counting
```

## Technical decisions

- **Pure SPM** — No Xcode project. The `.app` bundle is assembled manually in `install.sh`.
- **Swift 6 strict concurrency** — `@MainActor` on classes touching UI/state, `Sendable` protocols for DI.
- **PNGs directly in Resources/** — SPM doesn't compile `.car` (Asset Catalogs) correctly; PNGs are loaded via `Bundle.module`.
- **Drag via `NSEvent.mouseLocation`** — Absolute screen coordinates for smooth drag without SwiftUI feedback loop.
- **`caffeinate -di`** — `-d` flag prevents display sleep, `-i` prevents idle sleep.
- **`LSUIElement = true`** — App doesn't appear in the Dock, only in the menu bar.

## Regenerate assets

To regenerate widget PNGs and app icon from the source image:

```bash
python3 scripts/remove_bg_floodfill.py    # Requires Pillow
```

This script uses flood fill from edges (not global threshold) to remove the black background while preserving dark interior pixels (coffee, shadows, text). It automatically detects and removes the handle gap.
