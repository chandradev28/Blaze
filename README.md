# Blaze

Blaze is an Android-first internet speed tester built with Flutter. Its defining feature is **Blaze Garage**: a customizable speedometer dashboard system with original vehicle-inspired presets.

## Current MVP

- Android-only Flutter app
- Custom Blaze flame-speedometer branding across the launcher, splash screen, and in-app header
- Pure-black stage with fixed dashboard palettes
- Profile-matched garage materials: saddle leather, forged carbon, perforated leather, Alcantara, brushed chrome, hex trim, and neon vinyl
- Persistent settings toggle for dashboard texture backgrounds
- Pressable accelerator-pedal test control with active throttle feedback
- Blaze home speedometer
- Motorcycle-style physical dial with live decimal Mbps readout
- One minimal Ookla-style test page
- Eight swipeable dial profiles: one code-native classic and seven photographic dashboards
- Original dial faces with their fixed needles removed and live Flutter needles overlaid
- SVG peak-detail overlays and continuous scan/pulse motion
- Horizontal hand-swipe profile selection on the main page
- Active-route support and labeling for cellular, Wi-Fi/hotspot, VPN, Ethernet, and Bluetooth networks
- Offline preflight protection before data-intensive measurements begin
- Multi-sample ping and adaptive, continuously replenished multi-stream transfers
- Instantaneous transfer-rate needle with a data-driven dial ceiling (no forced 1000 Mbps sweep)
- Incomplete-response validation and confidence/data-usage reporting
- Inline results and shareable result text on the main page
- Optional persistent Blaze Mode: animated full-screen fire, embers, glow, and haptics at 800+ Mbps
- Manual-only GitHub Actions workflow that publishes a clearly named release APK

## Run locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The app currently uses Cloudflare's public speed-test endpoints. The measurement service performs an unscored warm-up probe, chooses two to eight parallel streams from the observed connection, continuously replenishes transfers for a timed test window, reports decimal Mbps, rejects incomplete responses instead of saving a number, and caps data use. It is isolated in `lib/services/speed_test_service.dart` so it can be replaced with Blaze-owned regional test servers later.

## GitHub Actions

The workflow in `.github/workflows/android-build.yml` is intentionally configured with `workflow_dispatch` only. A normal push does not start a build. Run it manually from the GitHub Actions tab when you are ready.
It cleans stale outputs and uploads only `Blaze-release.apk`; do not install an older `app-debug.apk`.

## Rendering approach

The reference motorcycle dial is drawn with Flutter's `CustomPainter`. The seven supplied dashboard photos are stored as cleaned, needle-free faces in `assets/dials/`; each has its own pivot, sweep, hub, needle treatment, and live Mbps overlay. The photo and needle are transformed together so they remain aligned while the dial is cropped for the one-screen layout.

The supplied dashboard imagery may contain vehicle branding or third-party photography. Confirm distribution rights before publishing those assets in an app store build.
