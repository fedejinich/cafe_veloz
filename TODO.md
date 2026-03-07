# TODO

## MVP Cafe Veloz

- [x] Create native macOS 14+ menu bar app with SwiftUI.
- [x] Implement process controller for `caffeinate -di`.
- [x] Implement floating cup UI (borderless), draggable, with on/off toggle on click.
- [x] Change status bar icon based on running/stopped state.
- [x] Force-stop `caffeinate` on quit.
- [x] Add unit tests for start/stop/toggle/failure/unexpected exit flow.
- [x] Update usage documentation in `README.md`.
- [x] Add local pipeline (`scripts/pipeline.sh`) with test + build + packaging into `dist/CafeVeloz.app`.
- [x] Add show/hide action for the floating cup and improve its visual silhouette.
- [x] Adjust floating cup to icon style (no text in widget, visual on/off state only).

## Beyond MVP

- [x] Launch at login.
- [ ] Configurable `caffeinate` flags.
- [ ] Packaging and signing for distribution.
