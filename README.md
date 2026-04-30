# AttendEase Agent Guide

## Overview

**App name:** AttendEase  
**Framework:** Flutter  
**State management:** Stateful Flutter app with a SQLite-backed controller  
**Primary targets:** Android, Linux, Web

This repo now contains the Flutter version of AttendEase, converted from the original Android Studio project and restructured into a modular Flutter application. The current app keeps the original role-based attendance concept for admins, teachers, and students while modernizing the UI, app structure, and platform support.

The original Android implementation is still preserved under `legacy_android/`.

## What Is Implemented

### App shell

- Material 3 Flutter app with a redesigned login and registration flow
- Role-based navigation for admin, teacher, and student users
- Responsive shell that supports Android, Linux, and Web
- Modular feature pages instead of Android activity-driven navigation

### Authentication and roles

- Admin login with fixed credentials
- Student and teacher registration flows
- Admin approval toggles for new accounts
- Role-aware dashboard and attendance actions

### Attendance workflow

- Admin course and department management
- Teacher attendance marking and attendance record review
- Student attendance history and active-course attendance flow
- Duplicate attendance prevention for the same student, course, and date

### Face recognition

- Real Android face-registration flow launched from Flutter via `MethodChannel`
- Native Android camera integration using CameraX
- Face detection using ML Kit
- Face embedding comparison using MobileFaceNet TensorFlow Lite model
- Android-only face verification before student attendance is marked

### Platform support

- Android build and launcher icon support
- Linux desktop target
- Web target
- Android-only features fail gracefully on unsupported platforms

## Repo Structure

```text
lib/
  app.dart
  main.dart
  core/
    models/
    state/
    theme/
  modules/
    auth/
    dashboard/
    shell/
  services/
android/
linux/
web/
assets/
test/
build.sh
pubspec.yaml
```

## Dependency Set

The current implementation uses:

- `cupertino_icons`
- `flutter_launcher_icons`
- `sqflite`
- `sqflite_common_ffi`
- `sqflite_common_ffi_web`
- `path_provider`

On Android native side, the project also integrates:

- CameraX
- ML Kit Face Detection
- TensorFlow Lite

## Current Delivery Status

- Local SQLite persistence for users, departments, courses, and attendance
- Reworked login and registration UI
- Admin, teacher, and student dashboards
- Course, department, and user approval management
- Student face registration and face verification on Android

## Tech Stack

- Flutter
- Dart
- Android Gradle
- Kotlin
- Java
- CameraX
- ML Kit
- TensorFlow Lite

## Requirements

Install these before building Android:

- Flutter SDK
- Dart SDK bundled with Flutter
- Android SDK with platform tools and build tools
- Android licenses accepted through Flutter
- JDK 17 or newer

Optional for desktop/web work:

- Linux desktop toolchain required by Flutter
- Chrome or another supported browser for web runs

## Install

1. Clone the repository.
2. Make sure Flutter and any target platform toolchains are installed.
3. Verify the toolchain:

```bash
flutter doctor
```

4. Fetch project dependencies:

```bash
flutter pub get
```

## Run

First check available targets:

```bash
flutter devices
```

Run on Android:

```bash
flutter run
```

Run on a specific target:

```bash
flutter run -d <device-id>
```

Run on Linux:

```bash
flutter run -d linux
```

Run on Web:

```bash
flutter run -d chrome
```

## Build

Build a debug APK:

```bash
flutter build apk --debug
```

Build a release APK:

```bash
flutter build apk --release
```

Build Linux desktop:

```bash
flutter build linux
```

Build Web:

```bash
flutter build web
```

The generated Android APK is written to:

```text
build/app/outputs/flutter-apk/
```

There is also a helper script in the repo:

```bash
./build.sh
```

## Validation

These checks have already succeeded in this environment:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

## Notes

- Face recognition currently works only on Android.
- Linux and Web builds are supported, but face-recognition actions return an unsupported-platform message there.

## Constraint:

- `flutter build linux` now fails in this environment because the native sqlite3 toolchain cannot find ld.lld/ld under /usr/lib/llvm-21/bin. That is an environment/toolchain issue, not a Dart analyzer issue.
- Web SQLite support package setup could not download its extra runtime assets here because outbound network to GitHub is blocked, so if you want persistent SQLite-backed web runtime on your machine, run `dart run sqflite_common_ffi_web:setup` once in `AttendEase-app` on a networked setup.
