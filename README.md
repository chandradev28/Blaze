# Blaze

Blaze is an Android-first internet speed tester built with Flutter. Its defining feature is **Blaze Garage**: a customizable speedometer dashboard system with original vehicle-inspired presets.

## Current MVP

- Android-only Flutter app
- Pure-black stage with fixed dashboard palettes
- Blaze home speedometer
- Motorcycle-style physical dial with live decimal MBps readout
- One minimal Ookla-style test page
- Six swipeable profiles using the same reference motorcycle dial
- SVG peak-detail overlays and continuous scan/pulse motion
- Horizontal hand-swipe profile selection on the main page
- Multi-sample ping, concurrent download, and concurrent upload measurements
- Instantaneous transfer-rate needle with a data-driven dial ceiling (no forced 1000 MBps sweep)
- Incomplete-response validation and confidence/data-usage reporting
- Inline results and shareable result text on the main page
- Manual-only GitHub Actions build workflow

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The app currently uses Cloudflare's public speed-test endpoints. The measurement service ramps through multiple request sizes and concurrent streams, rejects incomplete responses instead of saving a number, and reports the amount of data sampled. It is isolated in `lib/services/speed_test_service.dart` so it can be replaced with Blaze-owned regional test servers later.

## GitHub Actions

The workflow in `.github/workflows/android-build.yml` is intentionally configured with `workflow_dispatch` only. A normal push does not start a build. Run it manually from the GitHub Actions tab when you are ready.

## Rendering approach

The reference motorcycle dial is drawn with Flutter's `CustomPainter` instead of a fixed image. Swipe profiles change the instrument treatment while keeping the same physical dial renderer, so the test screen stays focused and minimal.
