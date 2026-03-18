<h1 align="center">
  <img src="Sources/CafeVeloz/Resources/coffee_cup@2x.png" width="120" alt="Cafe Veloz">
  <br>Cafe Veloz
</h1>

<p align="center">macOS menu bar app that keeps your Mac awake using <code>caffeinate -di</code>.<br>A floating coffee cup widget as visual indicator.</p>

## Features

- **Floating widget** — Draggable coffee cup, click to toggle on/off, double-click to hide.
- **Menu bar** — Control caffeinate, widget visibility, auto-off timer (1h/2h/4h/8h), and launch at login.
- **Sound feedback** — System Purr/Tink sounds on toggle.
- **Persistent position** — Widget position saved across relaunches and recovered safely if displays change.
- **Release packaging** — Produces a versioned `.app`, `.zip`, and SHA-256 checksum under `dist/`.

## Requirements

- macOS 14+ / Swift 6.0+

## Quick start

```bash
swift test
swift build
bash scripts/build_desktop_app.sh
bash install.sh
bash scripts/pipeline.sh
```

## Release artifacts

`bash scripts/build_desktop_app.sh` creates:

- `dist/CafeVeloz.app`
- `dist/CafeVeloz-<version>.zip`
- `dist/CafeVeloz-<version>.zip.sha256`

Versioning comes from [`VERSION`](VERSION). You can override release metadata at build time:

```bash
APP_VERSION=1.2.0 APP_BUILD=12 \
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
bash scripts/build_desktop_app.sh
```

The bundle is ad-hoc signed by default. For internet distribution, sign with a Developer ID identity and notarize the generated zip before publishing.

## Architecture

```
Sources/CafeVeloz/
  App/        — Entry point, menu bar, window config, login item
  Core/       — CaffeinateController, process protocol, sound player, auto-off timer
  UI/         — Floating draggable widget (SwiftUI + AppKit)
  Resources/  — Coffee cup PNGs + app icon xcassets + AppIcon.icns
```

Pure SPM, no Xcode project. Swift 6 strict concurrency. `LSUIElement` (menu bar only, no Dock).

## CI

GitHub Actions runs asset validation, tests, and release bundle packaging on every pull request and on pushes to `main`.
