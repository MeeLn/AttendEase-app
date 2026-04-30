#!/bin/bash

set -e

echo "Building AttendEase APK..."
flutter clean
flutter pub get
flutter doctor
flutter --version
flutter build apk --release

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
  echo "Build successful"
else
  echo "Build failed"
fi
