# CafeVeloz

App de menu bar para macOS que mantiene la Mac despierta usando `caffeinate -di`. Widget flotante con taza de cafe como indicador visual.

## Idioma

UI en español. Codigo y comentarios en ingles.

## Arquitectura

```
Sources/CafeVeloz/
  Core/       — Logica de negocio (protocolos + DI)
    CaffeinateController.swift   — Controlador principal (start/stop/toggle)
    CaffeinateProcessLaunching.swift — Protocolo para inyeccion de proceso
    SoundPlayer.swift            — Protocolo + impl para sonidos toggle
    AutoOffTimer.swift           — Timer auto-apagado con presets
  UI/         — Vista (SwiftUI + AppKit)
    CoffeeWidgetView.swift       — Widget flotante draggable
    WindowAccessor.swift         — Helper para acceder al NSWindow desde SwiftUI
  App/        — Ciclo de vida
    AppDelegate.swift            — Menu bar, window config, login item
    CafeVelozApp.swift           — Entry point
  Resources/  — PNG assets + xcassets para icono
```

## Build y test

```bash
swift test                    # 22 tests
swift build                   # Debug build
swift build -c release        # Release build
bash scripts/pipeline.sh      # Test + build + empaquetado en dist/CafeVeloz.app
bash install.sh               # Instalar en ~/Applications
```

## Tests

- Fakes en test files: `FakeProcess`, `MuteSoundPlayer`, `FakeTimerProvider`
- Tests son `@MainActor` porque `CaffeinateController` lo es
- No requieren UI ni permisos especiales

## Convenciones

- `@MainActor` en clases que tocan UI o estado compartido
- Protocolos `Sendable` para inyeccion de dependencias
- PNG assets directos en Resources/ con variantes @2x (SPM no compila .car)
- xcassets solo para app icon (se convierte a .icns en install.sh)
- Widget position persisted via UserDefaults (`widgetX`, `widgetY`)
- Login item via `SMAppService.mainApp` (macOS 13+)
- Drag usa `NSEvent.mouseLocation` (screen coords) para evitar feedback loop de SwiftUI

## Plataforma

- macOS 14+ (`.macOS(.v14)` en Package.swift)
- Swift 6.0 (strict concurrency)
- SPM (no Xcode project)
