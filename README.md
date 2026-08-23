# Blaze

Blaze is an Android-first internet speed tester built with Flutter. Its defining feature is **Blaze Garage**: a customizable speedometer dashboard system with original vehicle-inspired presets.

## Current MVP

- Android-only Flutter app
- Blaze home speedometer
- Blaze Garage customization flow
- Six original dashboard presets
- Gauge style, accent color, speed scale, motion, grid, and glow controls
- Saved custom dashboards using local storage
- Real ping, download, and upload measurements
- Local test history
- Shareable result text
- Manual-only GitHub Actions build workflow

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The app uses Cloudflare's public speed-test endpoints for the first working MVP. The speed-test service is isolated in `lib/services/speed_test_service.dart` so it can be replaced with Blaze-owned regional test servers later.

## GitHub Actions

The workflow in `.github/workflows/android-build.yml` is intentionally configured with `workflow_dispatch` only. A normal push does not start a build. Run it manually from the GitHub Actions tab when you are ready.

## Rendering approach

The main dial is drawn with Flutter's `CustomPainter` instead of a fixed image. Dashboard properties are modeled as data, so new dashboard styles can be added without rewriting the test screen.
