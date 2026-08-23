# Blaze

Blaze is an Android-first internet speed tester built with Flutter. Its defining feature is **Blaze Garage**: a customizable speedometer dashboard system with original vehicle-inspired presets.

## Current MVP

- Android-only Flutter app
- Blaze home speedometer
- Blaze Garage customization flow
- Six original dashboard presets
- Dedicated F1 telemetry and MotoGP dashboard layouts
- Gauge style, accent color, speed scale, motion, grid, and glow controls
- Saved custom dashboards using local storage
- Multi-sample ping, concurrent download, and concurrent upload measurements
- Incomplete-response validation and confidence/data-usage reporting
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

The app currently uses Cloudflare's public speed-test endpoints. The measurement service ramps through multiple request sizes and concurrent streams, rejects incomplete responses instead of saving a number, and reports the amount of data sampled. It is isolated in `lib/services/speed_test_service.dart` so it can be replaced with Blaze-owned regional test servers later.

## GitHub Actions

The workflow in `.github/workflows/android-build.yml` is intentionally configured with `workflow_dispatch` only. A normal push does not start a build. Run it manually from the GitHub Actions tab when you are ready.

## Rendering approach

The main dashboards are drawn with Flutter's `CustomPainter` instead of a fixed image. F1 uses a rectangular telemetry panel with shift LEDs, speed screen, DL/UL bars, and telemetry blocks. MotoGP uses a race-display cluster with arc indicators, gear/lean fields, and side data rails. Dashboard properties are modeled as data, so new styles can be added without rewriting the test screen.
