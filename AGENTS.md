# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter app for Google Weather Frog animations. Dart source lives in `lib/`: `main.dart` owns the app shell, scene picker, keyboard input, HUD, and export flow; `animation.dart` wraps Flare playback; `weather_overlay.dart` maps weather categories to Lottie overlays; `video_exporter.dart` captures frames and calls FFmpeg. Tests live in `test/`. Platform scaffolding is under `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/`. Animation, overlay, and background assets are declared explicitly in `pubspec.yaml` and stored in `assets/`; keep new asset filenames consistent with the existing pattern, for example `fields_day_sunny_bg.webp` and `fields_day_sunny_frog.flr`.

## Build, Test, and Development Commands

Use FVM for Flutter commands; `flutter` is not assumed to be on `PATH`.

- `fvm flutter pub get`: install Dart and Flutter dependencies.
- `fvm flutter run -d linux`: run the desktop app locally.
- `fvm flutter analyze`: run static analysis using `analysis_options.yaml`.
- `fvm flutter test`: run Flutter widget tests.
- `fvm flutter build linux --debug`: compile a Linux debug bundle.
- `fvm flutter build web`: produce a web build in `build/web`.
- `fvm flutter build apk --debug`: build an Android debug APK.
- `bash -n install-depends.sh && shellcheck install-depends.sh`: validate the Android SDK helper script.

## Coding Style & Naming Conventions

Follow `package:flutter_lints/flutter.yaml`. Use two-space Dart indentation, `UpperCamelCase` for classes/widgets, `lowerCamelCase` for methods and fields, and `const` constructors where possible. Keep scene metadata synchronized between the `FilePair` list in `lib/main.dart` and the asset declarations in `pubspec.yaml`. Prefer platform-aware paths and APIs when touching export code.

## Testing Guidelines

Use `flutter_test`; add `WidgetTester` tests for UI behavior and plain tests for catalog or mapping rules. Name tests by behavior, not implementation, for example `testWidgets('scene controls advance to next animation', ...)`. Add or update tests when changing navigation, scene selection, animation state, overlay mapping, asset declarations, or export error handling.

## Commit & Pull Request Guidelines

Recent history uses short imperative summaries, with occasional Conventional Commit scope such as `feat(android): Upgrade Gradle and add Android TV support`. Prefer that style. PRs should include a concise behavior summary, affected platforms, verification commands run, linked issues if any, and screenshots or screen recordings for visible UI changes.

## Asset & Licensing Notes

The README states that included frog assets are copyrighted by Google and used for demonstration. Do not add external assets without documenting origin, license, and intended use.
