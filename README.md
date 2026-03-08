<h1 align="center">
  <img src="Sources/CafeVeloz/Resources/coffee_cup@2x.png" width="120" alt="Cafe Veloz">
  <br>Cafe Veloz
</h1>

<p align="center">macOS menu bar app that keeps your Mac awake using <code>caffeinate -di</code>.<br>A floating coffee cup widget as visual indicator.</p>

## Features

- **Floating widget** — Draggable coffee cup, click to toggle on/off, double-click to hide.
- **Menu bar** — Control caffeinate, widget visibility, auto-off timer (1h/2h/4h/8h), and launch at login.
- **Sound feedback** — System Purr/Tink sounds on toggle.
- **Persistent position** — Widget position saved across relaunches.

## Requirements

- macOS 14+ / Swift 6.0+

## Quick start

```bash
swift test                    # 22 tests
swift build                   # Debug build
bash install.sh               # Build + install to ~/Applications
bash scripts/pipeline.sh      # Full pipeline: validate assets + test + release build
```

## Architecture

```
Sources/CafeVeloz/
  App/        — Entry point, menu bar, window config, login item
  Core/       — CaffeinateController, process protocol, sound player, auto-off timer
  UI/         — Floating draggable widget (SwiftUI + AppKit)
  Resources/  — Coffee cup PNGs + app icon xcassets
```

Pure SPM, no Xcode project. Swift 6 strict concurrency. `LSUIElement` (menu bar only, no Dock).
