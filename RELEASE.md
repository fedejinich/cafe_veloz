# Releasing CafeVeloz

## 1. Validate locally

```bash
bash scripts/pipeline.sh
```

This validates assets, runs the test suite, and produces release artifacts under `dist/`.

## 2. Set the release version

Update [`VERSION`](VERSION) before creating a public release tag.

Optional overrides:

- `APP_VERSION`: overrides `CFBundleShortVersionString`
- `APP_BUILD`: overrides `CFBundleVersion`
- `BUNDLE_IDENTIFIER`: overrides the app bundle identifier
- `CODESIGN_IDENTITY`: uses a real signing identity instead of ad-hoc signing

Example:

```bash
APP_BUILD=7 \
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
bash scripts/build_desktop_app.sh
```

## 3. Smoke-test the installed app

```bash
bash install.sh
open ~/Applications/CafeVeloz.app
```

Verify:

- menu bar icon reflects on/off state
- coffee widget toggles on click and hides on double-click
- auto-off presets update the countdown
- launch-at-login can be enabled without errors

## 4. Publish artifacts

The release build produces:

- `dist/CafeVeloz.app`
- `dist/CafeVeloz-<version>.zip`
- `dist/CafeVeloz-<version>.zip.sha256`

If the app will be downloaded outside your own machine, notarize the signed zip before attaching it to a GitHub release.
